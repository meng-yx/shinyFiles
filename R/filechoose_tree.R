#' @include aaa.R
NULL

#' Create a function that returns fileinfo according to the given restrictions
#' with tree structure support for both files and directories
#'
#' This functions returns a new function that can generate file information to
#' be send to a shiny app based on a path relative to the given root. The
#' function is secure in the sense that it prevents access to files outside of
#' the given root directory as well as to subdirectories matching the ones given
#' in restrictions. Furthermore can the output be filtered to only contain
#' certain filetypes using the filter parameter and hidden files can be toggled
#' with the hidden parameter.
#'
#' @param roots A named vector of absolute filepaths or a function returning a
#' named vector of absolute filepaths (the latter is useful if the volumes
#' should adapt to changes in the filesystem).
#'
#' @param restrictions A vector of directories within the root that should be
#' filtered out of the results
#'
#' @param filetypes A character vector of file extensions (without dot in front
#' i.e. 'txt' not '.txt') to include in the output. Use the empty string to
#' include files with no extension. If not set all file types will be included
#'
#' @param pattern A regular expression used to select files to show. See
#' \code{\link[base:grep]{base::grepl()}} for additional discussion on how to 
#' construct a regular expression (e.g., "log.*\\\\.txt")
#' 
#' @param hidden A logical value specifying whether hidden files should be
#' returned or not
#'
#' @return A function taking a single path relative to the specified root, and
#' returns a list of files to be passed on to shiny
#'
#' @importFrom tools file_ext
#' @importFrom fs path file_access file_exists dir_ls file_info path_file 
#'   path_ext path_join path_norm path_has_parent
#' @importFrom tibble as_tibble
#'
fileGetterTree <- function(roots, restrictions, filetypes, pattern, hidden = FALSE) {
  if (missing(filetypes)) {
    filetypes <- NULL
  } else if (is.function(filetypes)) {
    filetypes <- filetypes()
  }
  if (missing(restrictions)) restrictions <- NULL
  if (missing(pattern)) {
    pattern <- ""
  } else if (is.function(pattern)) {
    pattern <- pattern()
  }

  function(dir, root) {
    currentRoots <- if (inherits(roots, "function")) roots() else roots

    if (all(is.null(names(currentRoots)))) stop("Roots must be a named vector or a function returning one")
    if (all(is.null(root))) root <- names(currentRoots)[1]
    
    fulldir <- path_join(c(currentRoots[root], dir))
    testdir <- try(path_norm(fulldir), silent = TRUE) 

    if (inherits(testdir, "try-error")) {
      fulldir <- path(currentRoots[root])
      dir <- ""
    } else {
      if (Sys.info()["sysname"] != "Windows") {
        testdir <- gsub("/{2,}", "/", testdir)
      }
      if (path_has_parent(testdir, currentRoots[root])) {
        fulldir <- testdir
      } else {
        fulldir <- path(currentRoots[root])
        dir <- ""
      }
    }
    
    selectedFile <- ""
    if(file.exists(fulldir) && !dir.exists(fulldir)){
      # dir is a normal file, not a directory
      # get the filename, and use it as the selectedFile
      selectedFile = sub(".*/(.*)$", "\\1", fulldir)
      # shorten the directory
      fulldir = sub("(.*)/.*$", "\\1", fulldir)
      # dir also needs shortened for breadcrumbs
      dir = sub("(.*)/.*$", "\\1", dir)
    }
    
    writable <- as.logical(file_access(fulldir, "write"))
    files <- suppressWarnings(dir_ls(fulldir, all = hidden, fail = FALSE))
  
    if (!is.null(restrictions) && length(files) != 0) {
      if (length(files) == 1) {
        keep <- !any(sapply(restrictions, function(x) {
          grepl(x, files, fixed = T)
        }))
      } else {
        keep <- !apply(sapply(restrictions, function(x) {
          grepl(x, files, fixed = T)
        }), 1, any)
      }
      files <- files[keep]
    }
    fileInfo <- suppressWarnings(file_info(files, fail = FALSE))
    fileInfo$filename <- path_file(files)
    fileInfo$extension <- tolower(path_ext(files))
    fileInfo$isdir <- dir.exists(files)
    fileInfo$mtime <- as.integer(fileInfo$modification_time) * 1000
    fileInfo$ctime <- as.integer(fileInfo$birth_time) * 1000
    fileInfo$atime <- as.integer(fileInfo$access_time) * 1000
    
    if (!is.null(filetypes)) {
      matchedFiles <- tolower(fileInfo$extension) %in% tolower(filetypes) & fileInfo$extension != ""
      fileInfo$isdir[matchedFiles] <- FALSE
      fileInfo <- fileInfo[matchedFiles | fileInfo$isdir, ]
    }
    
    if (nchar(pattern) > 0) {
      matchedFiles <- try(grepl(pattern, fileInfo$filename), silent = TRUE)
      if (!inherits(matchedFiles, "try-error")) {
        fileInfo <- fileInfo[matchedFiles | fileInfo$isdir, ]
      }
    }
    
    breadcrumps <- strsplit(dir, .Platform$file.sep)[[1]]
    
    list(
      files = as_tibble(fileInfo[, c("filename", "extension", "isdir", "size", "mtime", "ctime", "atime")]),
      writable = writable,
      exist = as.logical(file_exists(fulldir)),
      breadcrumps = I(c("", breadcrumps[breadcrumps != ""])),
      roots = I(names(currentRoots)),
      root = root,
      selectedFile = selectedFile
    )
  }
}

#' Traverse and update a tree representing the file system with both files and directories
#'
#' This function takes a tree representing a part of the file system and updates
#' it to reflect the current state of the file system as well as the settings
#' for each node. Children (contained folders and files) are recursed into if the parents
#' expanded element is set to TRUE, no matter if children are currently present.
#'
#' @param tree A list representing the tree structure of the file system to
#' traverse. Each element should at least contain the elements 'name' and
#' 'expanded'. The elements 'empty' and 'children' will be created or updates if
#' they exist.
#'
#' @param root A string with the location of the root folder for the tree
#'
#' @param restrictions A vector of directories within the root that should be
#' filtered out of the results
#'
#' @param filetypes A character vector of file extensions to include
#'
#' @param pattern A regular expression used to select files to show
#'
#' @param hidden A logical value specifying whether hidden files should be
#' returned or not
#'
#' @return A list of the same format as 'tree', but with updated values to
#' reflect the current file system state.
#'
#' @importFrom fs path dir_ls file_info path_file path_ext
#'
traverseFilesAndDirs <- function(tree, root, restrictions, filetypes, pattern, hidden) {
  location <- path(root, tree$name)
  if (!dir.exists(location)) return(NULL)

  files <- suppressWarnings(dir_ls(location, all = hidden, fail = FALSE))

  if (!is.null(restrictions) && length(files) != 0) {
    if (length(files) == 1) {
      keep <- !any(sapply(restrictions, function(x) {
        grepl(x, files, fixed = T)
      }))
    } else {
      keep <- !apply(sapply(restrictions, function(x) {
        grepl(x, files, fixed = T)
      }), 1, any)
    }
    files <- files[keep]
  }

  # Get file info for all items
  fileInfo <- suppressWarnings(file_info(files, fail = FALSE))
  fileInfo$filename <- path_file(files)
  fileInfo$extension <- tolower(path_ext(files))
  fileInfo$isdir <- dir.exists(files)
  fileInfo$mtime <- as.integer(fileInfo$modification_time) * 1000
  fileInfo$ctime <- as.integer(fileInfo$birth_time) * 1000
  fileInfo$atime <- as.integer(fileInfo$access_time) * 1000

  # Apply filetype filter
  if (!is.null(filetypes)) {
    matchedFiles <- tolower(fileInfo$extension) %in% tolower(filetypes) & fileInfo$extension != ""
    fileInfo <- fileInfo[matchedFiles | fileInfo$isdir, ]
  }
  
  # Apply pattern filter
  if (nchar(pattern) > 0) {
    matchedFiles <- try(grepl(pattern, fileInfo$filename), silent = TRUE)
    if (!inherits(matchedFiles, "try-error")) {
      fileInfo <- fileInfo[matchedFiles | fileInfo$isdir, ]
    }
  }

  # Separate directories and files
  dirs <- fileInfo[fileInfo$isdir, ]
  files <- fileInfo[!fileInfo$isdir, ]

  if (nrow(dirs) == 0 && nrow(files) == 0) {
    tree$empty <- TRUE
    tree$children <- list()
    tree$files <- list()
    tree$expanded <- FALSE
  } else {
    tree$empty <- FALSE
    # Convert files data frame to list of lists (each row becomes a list)
    if (nrow(files) > 0) {
      tree$files <- lapply(1:nrow(files), function(i) {
        as.list(files[i, ])
      })
    } else {
      tree$files <- list()
    }
    
    if (tree$expanded) {
      children <- updateChildren(tree$children, dirs$filename)
      tree$children <- lapply(children, traverseFilesAndDirs, root = location, 
                             restrictions = restrictions, filetypes = filetypes, 
                             pattern = pattern, hidden = hidden)
    } else {
      tree$children <- list()
    }
  }
  tree
}

#' Update the children element to reflect current state
#'
#' This function create new entries for new folders and remove entries for no
#' longer existing folders, while keeping the state of transient folders in the
#' children element of the tree structure. The function does not recurse into
#' the folders, but merely creates a shell that traverseFilesAndDirs can take as input.
#'
#' @param oldChildren A list of children folders from the parent$children
#' element of tree in [traverseFilesAndDirs()]
#'
#' @param currentChildren A vector of names of the folders that are currently
#' present in the parent of oldChildren
#'
#' @return An updated list equal in format to oldChildren
#'
updateChildren <- function(oldChildren, currentChildren) {
  oldNames <- sapply(oldChildren, `[[`, "name")
  newChildren <- currentChildren[!currentChildren %in% oldNames]
  children <- oldChildren[oldNames %in% currentChildren]
  children <- append(children, lapply(newChildren, function(x) {
    list(name = x, expanded = FALSE, children = list(), files = list())
  }))
  childrenNames <- sapply(children, `[[`, "name")
  children[order(childrenNames)]
}

#' Create a function that updates a file and folder tree based on the given restrictions
#'
#' This functions returns a new function that will handle updating the file and folder
#' tree. It combines the functionality of [fileGetter()] and [dirGetter()] to
#' create a tree structure that includes both files and directories.
#'
#' @param roots A named vector of absolute filepaths or a function returning a
#' named vector of absolute filepaths (the latter is useful if the volumes
#' should adapt to changes in the filesystem).
#'
#' @param restrictions A vector of directories within the root that should be
#' filtered out of the results
#'
#' @param filetypes A character vector of file extensions to include in the output
#'
#' @param pattern A regular expression used to select files to show
#'
#' @param hidden A logical value specifying whether hidden files should be
#' returned or not
#'
#' @return A function taking a list representation of a folder hierarchy along
#' with the name of the root where it starts.
#'
fileAndDirGetter <- function(roots, restrictions, filetypes, pattern, hidden=FALSE) {
  if (missing(filetypes)) filetypes <- NULL
  if (missing(restrictions)) restrictions <- NULL
  if (missing(pattern)) pattern <- ""

  function(tree, root) {
    currentRoots <- if (inherits(roots, "function")) roots() else roots

    if (is.null(names(currentRoots))) stop("Roots must be a named vector or a function returning one")
    if (is.null(root)) root <- names(currentRoots)[1]

    tree <- traverseFilesAndDirs(tree, currentRoots[root], restrictions, filetypes, pattern, hidden)
    
    list(
      tree = tree,
      rootNames = I(names(currentRoots)),
      selectedRoot = root
    )
  }
}

#' Create a connection to the server side filesystem with tree structure
#'
#' This function sets up the required connection to the client in order for the
#' user to navigate the filesystem using a tree structure that displays both
#' files and directories. This combines the functionality of shinyFileChoose
#' and shinyDirChoose to provide a unified tree-based file browser.
#'
#' @param input The input object of the `shinyServer()` call (usually
#' `input`)
#'
#' @param id The same ID as used in the matching call to
#' `shinyFilesButton` or as the id attribute of the button, in case of a
#' manually defined html. This id will also define the id of the file choice in
#' the input variable
#'
#' @param updateFreq The time in milliseconds between file system lookups. This
#' determines the responsiveness to changes in the filesystem (e.g. addition of
#' files or drives). For the default value (0) changes in the filesystem are
#' shown only when a shinyFiles button is clicked again
#'
#' @param session The session object of the shinyServer call (usually
#' `session`).
#'
#' @param defaultRoot The default root to use. For instance if
#' `roots = c('wd' = '.', 'home' = '/home')` then `defaultRoot`
#' can be either `'wd'` or `'home'`.
#'
#' @param defaultPath The default relative path specified given the `defaultRoot`.
#' 
#' @param allowDirCreate Logical that indicates if creating new directories by the user is allowed.
#'
#' @param ... Arguments to be passed on to [fileAndDirGetter()].
#'
#' @return A reactive observer that takes care of the server side logic of the
#' filesystem connection.
#'
#' @importFrom shiny observe invalidateLater req observeEvent
#' @importFrom fs path 
#'
#' @export
#'
shinyFileChooseTree <- function(input, id, updateFreq = 0, session = getSession(),
                            defaultRoot=NULL, defaultPath="", allowDirCreate = TRUE, ...) {
  fileAndDirGet <- do.call(fileAndDirGetter, list(...))
  clientId <- session$ns(id)
  
  sendDirectoryData <- function(message) {
    req(input[[id]])
    tree <- input[[paste0(id, "-modal")]]
    
    if (.is_not(tree)) {
      dir <- list(tree = list(name = defaultPath, expanded = TRUE), root = defaultRoot)
    } else {
      dir <- list(tree = tree$tree, root = tree$selectedRoot)
    }
    
    newDir <- do.call(fileAndDirGet, dir)
    session$sendCustomMessage(message, list(id = clientId, dir = newDir))
    if (updateFreq > 0) invalidateLater(updateFreq, session)
  }

  observe({
    sendDirectoryData("shinyFilesTree")
  })

  observeEvent(input[[paste0(id, "-refresh")]], {
    if (!is.null(input[[paste0(id, "-refresh")]])) {
      sendDirectoryData("shinyFilesTree-refresh")
    }
  })
}

#' Create a button to summon a shinyFiles tree dialog
#'
#' This function adds the required html markup for the client to access the file
#' system using a tree structure that displays both files and directories.
#'
#' @param id The id matching the [shinyFileChooseTree()]
#'
#' @param label The text that should appear on the button
#'
#' @param title The heading of the dialog box that appears when the button is
#' pressed
#'
#' @param multiple A logical indicating whether or not it should be possible to
#' select multiple files
#'
#' @param buttonType The Bootstrap button markup used to colour the button.
#' Defaults to 'default' for a neutral appearance but can be changed for another
#' look. The value will be pasted with 'btn-' and added as class.
#'
#' @param class Additional classes added to the button
#'
#' @param icon An optional \href{https://shiny.rstudio.com/reference/shiny/latest/icon.html}{icon} to appear on the button.
#' 
#' @param style Additional styling added to the button (e.g., "margin-top: 25px;")
#' 
#' @param ... Named attributes to be applied to the button or link (e.g., 'onclick')
#'
#' @return This function is called for its side effects
#'
#' @importFrom htmltools tagList singleton tags
#' @importFrom shiny restoreInput
#'
#' @export
#'
shinyFilesButtonTree <- function(
  id, label, title, multiple, buttonType="default", 
  class=NULL, icon=NULL, style=NULL, ...
) {
  value <- restoreInput(id = id, default = NULL)
  tagList(
    singleton(tags$head(
      tags$script(src = "sF/shinyFiles.js"),
      tags$link(
        rel = "stylesheet",
        type = "text/css",
        href = "sF/styles.css"
      ),
      tags$link(
        rel = "stylesheet",
        type = "text/css",
        href = "sF/fileIcons.css"
      )
    )),
    tags$button(
      id = id,
      type = "button",
      class = paste(c("shinyFilesTree btn", paste0("btn-", buttonType), class, "action-button"), collapse = " "),
      style = style,
      "data-title" = title,
      "data-selecttype" = ifelse(multiple, "multiple", "single"),
      "data-val" = value,
      list(icon, label),
      ...
    )
  )
}
