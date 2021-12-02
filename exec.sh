#! /bin/bash

source ./vars.sh
source ./functions.sh

export PYTHON=$(which python)

export BATCH_SIZE=1
export COLS=224
export ROWS=224

function exec() {
    export IN_LANDSAT=$1
    export YEAR=$(echo $IN_LANDSAT | sed 's/.*\([0-9]\{4\}\)-.*tif/\1/g')

    M1=$(echo $IN_LANDSAT | sed 's/.*[0-9]\{4\}-\([0-9]\{2\}\)-\([0-9]\{2\}\).*/\1/g')
    M2=$(echo $IN_LANDSAT | sed 's/.*[0-9]\{4\}-\([0-9]\{2\}\)-\([0-9]\{2\}\).*/\2/g')
    if [ M1 = M2 ]; then
	MQ=monthly
    else
	MQ=quarterly
    fi
    
    export WORKDIR=$(mktemp -d)
    if [ $YEAR -ge 2014 ]; then
	export GREEN=3
	export RED=4
	export NIR=5
	export SWIR=6
	export SCALE="3000 30000"
	export MODEL_FILE=checkpoint/FPN_epoch_200_Dec24_19_15.pth
	export NDWI_THRESHOLD_1=0
	export NDWI_THRESHOLD_2=-0.05
    elif [ $YEAR -ge 1988 ]; then
	export GREEN=2
	export RED=3
	export NIR=4
	export SWIR=5
	export SCALE="3000 30000"
	export MODEL_FILE=checkpoint/FPN_epoch_200_Dec24_19_15.pth
	export NDWI_THRESHOLD_1=0
	export NDWI_THRESHOLD_2=-0.05

    else
	export GREEN=1
	export RED=2
	export NIR=3
	export SWIR=4
	export SCALE="30 90"	
	export MODEL_FILE=checkpoint/FPN_epoch_400_Nov23_16_05.pth
	#export NDWI_THRESHOLD=0.2
	export NDWI_THRESHOLD_1=0.2
	export NDWI_THRESHOLD_2=0.2
    fi

    export PRED_RIVER_RAS=$OUTPUT_BASEDIR/river_segment.pred.d/$(basename $IN_LANDSAT).$(basename $MODEL_FILE).tif
    export PRED_RIVER_RAS_VRT=$OUTPUT_BASEDIR/river_segment.pred.d/$(basename $IN_LANDSAT).$(basename $MODEL_FILE).vrt
    export PRED_RIVER_SHP=$OUTPUT_BASEDIR/river_segment.shp.d/$(basename $IN_LANDSAT).$(basename $MODEL_FILE)${EIGHT}.shp

    export NDWI_RIVER=$OUTPUT_BASEDIR/ndwi_river.rast.d/$(basename $IN_LANDSAT).nwdi_river.tif
    export NDWI_RIVER_SHP=$OUTPUT_BASEDIR/ndwi_river.shp.d/$(basename $IN_LANDSAT).nwdi_river.shp

    BASENAME=$(basename $NDWI_RIVER_SHP | sed 's/\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-cloudfree-median.tif\).*/\1/g')

    export PRED_RIVER_SHP=$OUTPUT_BASEDIR/river_segment.shp.d/$BASENAME.$(basename $MODEL_FILE).shp
    export RIVER_EXTENT=$OUTPUT_BASEDIR/ndwi_river.extract.shp.d/median/$MQ/$YEAR/$BASENAME.ndwi_river.extract.shp
    export RIVER_LINE=$OUTPUT_BASEDIR/ndwi_river.extract.line.shp.mode${MODE_FILTER_SIZE}.d/$MQ/$YEAR/$(basename $RIVER_EXTENT).line.shp
    export RIVER_LINE_DIST=$OUTPUT_BASEDIR/ndwi_river.extract.line.dist.d/$MQ/$YEAR/$(basename $RIVER_EXTENT).line.dist.tif
    export RIVER_MAJOR_STREAM=$OUTPUT_BASEDIR/ndwi_river.major_stream.d/$MQ/$YEAR/$(basename $RIVER_EXTENT).major_stream.shp

    export MAP_OUTPUT_RIVER=$OUTPUT_BASEDIR/map_output.d/$MQ/$YEAR/$YEAR-$M1-$M2-map_output.png
    
    make -r $NDWI_RIVER_SHP $RIVER_LINE $MAP_OUTPUT_RIVER #$NDWI_RIVER_SHP #$RIVER_EXTENT #$RIVER_MAJOR_STREAM
    rm -rf $WORKDIR
}
export -f exec
#exec monthly_mosaic/1994-01-03-cloudfree-median.tif
#parallel exec ::: $(find monthly_mosaic/ -type f -regex ".*median.*tif$")
#./copyProductsForDelivery.sh
parallel --results logs/$0.$(date +%F_%T)parallel.log.d --bar -j$N_JOBS exec ::: $INPUTS
