#! /bin/bash

#MAP_OUTPUT=map_output.d
#mkdir -p $MAP_OUTPUT

function createmap(){
    PERIOD=$1
    export RIVER_EXTENT=$PWD/ndwi_river.extract.shp.d/median/${PERIOD}-cloudfree-median.tif.ndwi_river.extract.shp
    export RIVER_LINE=$PWD/ndwi_river.extract.line.shp.d/${PERIOD}-cloudfree-median.tif.ndwi_river.extract.shp.line.shp
    export MAP_OUTPUT=map_output.d/$PERIOD-map_output.png

    make $MAP_OUTPUT
}
export -f createmap
parallel createmap ::: $(find ndwi_river.extract.line.shp.d/ -type f -regex ".*\.shp" | sed 's/.*\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/g')
./copyProductsForDelivery.sh
