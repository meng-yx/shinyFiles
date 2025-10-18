# build this repo into a package
library("pkgbuild")

dest <- dirname(getwd())
build(getwd(), dest_path = dest)

# rename the package to shinyFiles_MultiDirChoose_0.9.3.9001.tar.gz
file.rename(
    file.path(dest, "shinyFiles_0.9.3.9001.tar.gz"), 
    file.path(dest, "shinyFiles_MultiDirChoose_0.9.3.9001.tar.gz")
    )

# uninstall the previously installed shinyFiles package
# library(utils)
# remove.packages("shinyFiles")

# if(!require(shinyFiles)) {
#   install.packages("../shinyFiles_0.9.3.9000.tar.gz", repos = NULL, type = "source")
# }