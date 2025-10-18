library(shiny)
library(fs)
library(tibble)
library(htmltools)
library(jsonlite)
library(bslib)

# Set up the resource path for the local shinyFiles www files
shiny::addResourcePath("sF", file.path(getwd(), "inst", "www"))

# Source the modified shinyFiles functions from the local repository
source("R/aaa.R")
source("R/filechoose.R")
source("R/dirchoose.R")
source("R/filesave.R")

# Test app with bslib - NO custom CSS
ui <- page_fillable(
  theme = bs_theme(version = 5),
  title = "bslib Compatibility Test - No Custom CSS",
  
  layout_columns(
    col_widths = c(6, 6),
    
    # Single Directory Selection Card
    card(
      card_header("Single Directory Selection", class = "bg-primary text-white"),
      card_body(
        p("Traditional single directory selection behavior."),
        shinyDirButton("single_dir", "Choose Single Directory", "Please select a directory", 
                      buttonType = "primary", class = "mb-3"),
        verbatimTextOutput("single_dir_path", placeholder = TRUE)
      )
    ),
    
    # Multiple Directory Selection Card
    card(
      card_header("Multiple Directory Selection", class = "bg-success text-white"),
      card_body(
        p("Enhanced multiple directory selection with bslib compatibility."),
        shinyDirButton("multiple_dirs", "Choose Multiple Directories", "Please select directories", 
                      multiple = TRUE, buttonType = "success", class = "mb-3"),
        verbatimTextOutput("multiple_dir_paths", placeholder = TRUE)
      )
    )
  ),
  
  br(),
  
  # Instructions Card
  card(
    card_header("bslib Compatibility Test", class = "bg-info text-white"),
    card_body(
      tags$ul(
        tags$li("This app uses bslib theme with NO custom CSS"),
        tags$li("All styling is now built into the shinyFiles package"),
        tags$li("Toolbar should stay on one row"),
        tags$li("Modal buttons should be properly sized"),
        tags$li("Multiple directory selection should work seamlessly")
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
      path <- parseDirPath(volumes, input$single_dir)
      cat("Selected directory:\n")
      cat(sprintf("📁 %s", path))
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
        cat(sprintf("Selected directories (%d):\n", length(paths)))
        for (i in seq_along(paths)) {
          cat(sprintf("%d. 📁 %s\n", i, paths[i]))
        }
      }
    }
  })
}

shinyApp(ui, server)
