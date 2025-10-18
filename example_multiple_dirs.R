library(shiny)
library(fs)

# Set up the resource path for the local shinyFiles www files
shiny::addResourcePath("sF", file.path(getwd(), "inst", "www"))

# Source the modified shinyFiles functions from the local repository
source("R/aaa.R")
source("R/filechoose.R")
source("R/dirchoose.R")
source("R/filesave.R")

# Example app demonstrating multiple directory selection
ui <- fluidPage(
  titlePanel("Multiple Directory Selection Example"),
  
  fluidRow(
    column(6,
      h3("Single Directory Selection (Original)"),
      shinyDirButton("single_dir", "Choose Single Directory", "Please select a directory"),
      verbatimTextOutput("single_dir_path")
    ),
    column(6,
      h3("Multiple Directory Selection (New)"),
      shinyDirButton("multiple_dirs", "Choose Multiple Directories", "Please select directories", multiple = TRUE),
      verbatimTextOutput("multiple_dir_paths")
    )
  ),
  
  fluidRow(
    column(12,
      h3("Instructions"),
      p("For multiple directory selection:"),
      tags$ul(
        tags$li("Regular click: Select only this directory"),
        tags$li("Ctrl+Click (Cmd+Click on Mac): Toggle this directory selection"),
        tags$li("Shift+Click: Select range of directories from last selected to this one")
      )
    )
  )
)

server <- function(input, output, session) {
  volumes <- c(Home = fs::path_home(), "R Installation" = R.home(), getVolumes()())
  
  # Single directory selection (original behavior)
  shinyDirChoose(input, "single_dir", roots = volumes, session = session)
  
  # Multiple directory selection (new behavior)
  shinyDirChoose(input, "multiple_dirs", roots = volumes, session = session)
  
  # Display single directory path
  output$single_dir_path <- renderPrint({
    if (is.integer(input$single_dir)) {
      cat("No directory selected")
    } else {
      parseDirPath(volumes, input$single_dir)
    }
  })
  
  # Display multiple directory paths
  output$multiple_dir_paths <- renderPrint({
    if (is.integer(input$multiple_dirs)) {
      cat("No directories selected")
    } else {
      paths <- parseDirPath(volumes, input$multiple_dirs)
      if (length(paths) == 0) {
        cat("No directories selected")
      } else {
        cat("Selected directories:\n")
        for (i in seq_along(paths)) {
          cat(sprintf("%d. %s\n", i, paths[i]))
        }
      }
    }
  })
}

shinyApp(ui, server)
