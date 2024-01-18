#! /bin/bash

#MAP_OUTPUT=map_output.d
#mkdir -p $MAP_OUTPUT

function createmap_river(){
    PERIOD=$1
    YEAR=$(echo $PERIOD | sed 's/\([0-9]\{4\}\)-\([0-9]\{2\}\)-\([0-9]\{2\}\)/\1/g')
    M1=$(echo $PERIOD | sed 's/[0-9]\{4\}-\([0-9]\{2\}\)-\([0-9]\{2\}\)/\1/g')
    M2=$(echo $PERIOD | sed 's/[0-9]\{4\}-\([0-9]\{2\}\)-\([0-9]\{2\}\)/\2/g')
    if [ M1 = M2 ]; then
	MQ=monthly
    else
	MQ=quarterly
    fi
    
    export RIVER_EXTENT=$PWD/ndwi_river.extract.shp.d/median/$MQ/$YEAR/${PERIOD}-cloudfree-median.tif.ndwi_river.extract.shp
    export RIVER_LINE=$PWD/ndwi_river.extract.line.shp.d/$MQ/$YEAR/${PERIOD}-cloudfree-median.tif.ndwi_river.extract.shp.line.shp
    export MAP_OUTPUT_RIVER=map_output.d/$MQ/$YEAR/$PERIOD-map_output.png

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
parallel createmap_river ::: $(find ndwi_river.extract.line.shp.d/ -type f -regex ".*\.shp" | sed 's/.*\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/g')

#for P in $(find ndwi_river.extract.line.shp.d/ -type f -regex ".*\.shp" | sed 's/.*\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/g'); do createmap_river $P; done


parallel createmap_veg ::: {1973..1980} {1988..2021}


#mkdir -p map_output.d/monthly map_output.d/quarterly 

