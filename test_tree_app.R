library(shiny)
library(tibble)
library(fs)
library(htmltools)
library(jsonlite)
library(tools)

# Manually add the resource path for the www files
shiny::addResourcePath("sF", "inst/www")

# Source the modified shinyFiles functions directly from local files
source("R/aaa.R")
source("R/filechoose.R")
source("R/dirchoose.R")
source("R/filesave.R")
source("R/filechoose_tree.R")

# Define UI
ui <- fluidPage(
  titlePanel("ShinyFiles Tree Demo"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Original shinyFilesButton + shinyFileChoose"),
      shinyFilesButton("files", "Select Files", "Please select a file", FALSE),
      br(), br(),
      
      h4("Original shinyDirButton + shinyDirChoose"),
      shinyDirButton("dirs", "Select Directory", "Please select a folder"),
      br(), br(),
      
      h4("New Tree Structure (Files + Folders)"),
      shinyFilesButtonTree("tree_files", "Select Files (Tree)", "Please select files using tree structure", TRUE),
      br(), br(),
      
      h4("Selected Files:"),
      verbatimTextOutput("selected_files"),
      
      h4("Selected Directory:"),
      verbatimTextOutput("selected_dir"),
      
      h4("Selected Tree Files:"),
      verbatimTextOutput("selected_tree_files")
    ),
    
    mainPanel(
      h3("Comparison of File Selection Methods"),
      p("This app demonstrates the differences between the three file selection methods:"),
      
      h4("1. shinyFilesButton + shinyFileChoose"),
      p("- Single panel with icon/list/detail views"),
      p("- Direct file selection"),
      p("- Breadcrumb navigation"),
      
      h4("2. shinyDirButton + shinyDirChoose"),
      p("- Two panels: Directories (left) and Content (right)"),
      p("- Tree structure for directories only"),
      p("- Files shown in content panel when directory selected"),
      
      h4("3. shinyFilesButtonTree + shinyFileChooseTree (NEW)"),
      p("- Single panel with tree structure"),
      p("- Shows both files and folders in hierarchical tree"),
      p("- Allows file selection directly from tree"),
      p("- Combines best of both approaches"),
      
      h3("Instructions:"),
      p("1. Click each button to see the different modal interfaces"),
      p("2. Notice how the tree structure shows both files and folders"),
      p("3. Try selecting files directly from the tree structure"),
      p("4. Compare the user experience across all three methods")
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  # Define roots for file system access
  roots <- c(wd = '.', home = Sys.getenv('HOME'))
  
  # Original file chooser
  shinyFileChoose(input, "files", roots = roots, filetypes = c('', 'txt', 'csv', 'R'))
  
  # Original directory chooser
  shinyDirChoose(input, "dirs", roots = roots)
  
  # New tree file chooser
  shinyFileChooseTree(input, "tree_files", roots = roots, filetypes = c('', 'txt', 'csv', 'R'))
  
  # Display selected files from original file chooser
  output$selected_files <- renderPrint({
    if (!is.null(input$files)) {
      parseFilePaths(roots, input$files)
    } else {
      "No files selected"
    }
  })
  
  # Display selected directory from original directory chooser
  output$selected_dir <- renderPrint({
    if (!is.null(input$dirs)) {
      parseDirPath(roots, input$dirs)
    } else {
      "No directory selected"
    }
  })
  
  # Display selected files from tree chooser
  output$selected_tree_files <- renderPrint({
    if (!is.null(input$tree_files)) {
      parseFilePaths(roots, input$tree_files)
    } else {
      "No files selected from tree"
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)
