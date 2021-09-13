#! /bin/bash

function polygonize() {
    export WORKDIR=$(mktemp -d)
    export VEG_RAST=$1
    export VEG_VECT=vegetation/Shapefile/$(basename $VEG_RAST | sed 's/\.tif/\.shp/g')
    make $VEG_VECT
}
export -f polygonize

parallel polygonize ::: $(find vegetation/Raster -type f -regex ".*\.tif")
./copyProductsForDelivery.sh
