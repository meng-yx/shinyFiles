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

# Example app demonstrating multiple directory selection
ui <- page_fillable(
  theme = bs_theme(version = 5),  # Minimal theme without bootswatch
  
  # Custom CSS to fix modal styling issues
  tags$head(
    tags$style(HTML("
      /* Fix modal button sizing */
      .sF-remove-dir {
        padding: 1px 4px !important;
        font-size: 10px !important;
        line-height: 1.2 !important;
        height: auto !important;
      }
      
       /* Fix dropdown menu layout - make toolbar more compact */
       .sF-navigation {
         display: flex !important;
         flex-wrap: nowrap !important;
         align-items: center !important;
         gap: 5px !important;
       }
       
       .sF-navigation .btn-group {
         flex-shrink: 0 !important;
         margin-right: 0 !important;
       }
       
       .sF-breadcrumps {
         flex: 1 1 auto !important;
         min-width: 120px !important;
         max-width: 200px !important;
         margin-right: 0 !important;
       }
       
       .sF-navigation .sF-refresh {
         flex-shrink: 0 !important;
         margin-left: auto !important;
       }
      
      /* Ensure modal elements don't get oversized */
      .sF-modal .btn-xs {
        padding: 1px 4px !important;
        font-size: 10px !important;
        line-height: 1.2 !important;
      }
      
      /* Fix modal content spacing */
      .sF-selected-directories {
        font-size: 12px !important;
      }
      
      .sF-selected-directories ul {
        margin-bottom: 0 !important;
      }
      
      .sF-selected-directories li {
        margin-bottom: 2px !important;
      }

    "))
  ),
  
  title = "Multiple Directory Selection Example",
  
  layout_columns(
    col_widths = c(6, 6),
    
    # Single Directory Selection Card
    card(
      card_header("Single Directory Selection (Original)", class = "bg-primary text-white"),
      card_body(
        p("Traditional single directory selection behavior - modal closes immediately after selection."),
        shinyDirButton("single_dir", "Choose Single Directory", "Please select a directory", 
                      buttonType = "primary", class = "mb-3"),
        verbatimTextOutput("single_dir_path", placeholder = TRUE)
      )
    ),
    
    # Multiple Directory Selection Card
    card(
      card_header("Multiple Directory Selection (New)", class = "bg-success text-white"),
      card_body(
        p("Enhanced multiple directory selection - modal stays open to build a list of selections."),
        shinyDirButton("multiple_dirs", "Choose Multiple Directories", "Please select directories", 
                      multiple = TRUE, buttonType = "success", class = "mb-3"),
        verbatimTextOutput("multiple_dir_paths", placeholder = TRUE)
      )
    )
  ),
  
  br(),
  
  # Instructions Card
  card(
    card_header("How to Use Multiple Directory Selection", class = "bg-info text-white"),
    card_body(
      tags$ul(
        tags$li("Click on a directory to select it"),
        tags$li("Click 'Add Directory' to add it to your selection list"),
        tags$li("Repeat to add more directories"),
        tags$li("Click 'Done' when you're finished selecting"),
        tags$li("Use 'Remove' buttons to remove individual directories from the list"),
        tags$li("Duplicate directories are automatically prevented")
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
