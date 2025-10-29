# build this repo into a package
library("pkgbuild")

dest <- dirname(getwd())
build(getwd(), dest_path = dest)

