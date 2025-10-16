# build this repo into a package
library("pkgbuild")

dest <- dirname(getwd())
build(getwd(), dest_path = dest)


# if(!require(shinyFiles)) {
#   install.packages("../shinyFiles_0.9.3.9000.tar.gz", repos = NULL, type = "source")
# }
