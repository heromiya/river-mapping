#! /bin/bash

#MAP_OUTPUT=map_output.d
#mkdir -p $MAP_OUTPUT

function createmap_river(){
    PERIOD=$1
    export RIVER_EXTENT=$PWD/ndwi_river.extract.shp.d/median/${PERIOD}-cloudfree-median.tif.ndwi_river.extract.shp
    export RIVER_LINE=$PWD/ndwi_river.extract.line.shp.d/${PERIOD}-cloudfree-median.tif.ndwi_river.extract.shp.line.shp
    export MAP_OUTPUT_RIVER=map_output.d/$PERIOD-map_output.png

    make $MAP_OUTPUT_RIVER
}
export -f createmap_river

function createmap_veg(){
    YEAR=$1
    export VEG_RAST=$PWD/vegetation/Raster/${YEAR}_clusters.tif
    export MAP_OUTPUT_VEG=$PWD/vegetation/Map/${YEAR}.png
    make $MAP_OUTPUT_VEG

}
export -f createmap_veg
#parallel createmap_river ::: $(find ndwi_river.extract.line.shp.d/ -type f -regex ".*\.shp" | sed 's/.*\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/g')
parallel createmap_veg ::: {1973..1980} {1988..2021}
./copyProductsForDelivery.sh
