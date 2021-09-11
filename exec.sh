#! /bin/bash

export PYTHON=$(which python)

export BATCH_SIZE=1
export COLS=224
export ROWS=224

export TARGET_EXTENT=Jamuna-Padoma_River_Extent.kmz

source ./functions.sh

function exec() {

    export IN_LANDSAT=$1
    export WORKDIR=$(mktemp -d)

    export YEAR=$(echo $IN_LANDSAT | sed 's/.*\([0-9]\{4\}\)-.*tif/\1/g')

    if [ $YEAR -ge 2014 ]; then
	export GREEN=3
	export RED=4
	export NIR=5
	export SWIR=6
	export SCALE="3000 30000"
	export MODEL_FILE=checkpoint/FPN_epoch_200_Dec24_19_15.pth
	export NDWI_THRESHOLD=0
    elif [ $YEAR -ge 1988 ]; then
	export GREEN=2
	export RED=3
	export NIR=4
	export SWIR=5
	export SCALE="3000 30000"
	export MODEL_FILE=checkpoint/FPN_epoch_200_Dec24_19_15.pth
	export NDWI_THRESHOLD=0
    else
	export GREEN=1
	export RED=2
	export NIR=3
	export SWIR=4
	export SCALE="30 90"	
	export MODEL_FILE=checkpoint/FPN_epoch_400_Nov23_16_05.pth
	export NDWI_THRESHOLD=0.2
    fi

    export PRED_RIVER_RAS=river_segment.pred.d/$(basename $IN_LANDSAT).$(basename $MODEL_FILE).tif
    export PRED_RIVER_RAS_VRT=river_segment.pred.d/$(basename $IN_LANDSAT).$(basename $MODEL_FILE).vrt
    export PRED_RIVER_SHP=river_segment.shp.d/$(basename $IN_LANDSAT).$(basename $MODEL_FILE)${EIGHT}.shp

    export NDWI_RIVER=ndwi_river.rast.d/$(basename $IN_LANDSAT).nwdi_river.sdat
    export NDWI_RIVER_SHP=ndwi_river.shp.d/$(basename $IN_LANDSAT).nwdi_river.shp

    BASENAME=$(basename $NDWI_RIVER_SHP | sed 's/\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-cloudfree-median.tif\).*/\1/g')

    export PRED_RIVER_SHP=river_segment.shp.d/$BASENAME.$(basename $MODEL_FILE).shp
    export RIVER_EXTENT=ndwi_river.extract.shp.d/median/$BASENAME.ndwi_river.extract.shp
    export RIVER_LINE=ndwi_river.extract.line.shp.d/$(basename $RIVER_EXTENT).line.shp
    make -r $RIVER_LINE
}
export -f exec
#exec monthly_mosaic/2011-01-03-cloudfree-median.tif
parallel exec ::: $(find monthly_mosaic/ -type f -regex ".*median.*tif$")
