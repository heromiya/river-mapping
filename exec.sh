#! /bin/bash

export LD_LIBRARY_PATH=$HOME/miniconda3/lib/
export PYTHON=$(which python)
#python predict_auto.py -checkpoints FPN_epoch_400_Mar01_14_21.pth -data input -georef true
#python predict_auto.py -data input -checkpoints FPN_epoch_400_Mar01_14_21.pth -batch_size 2

export BATCH_SIZE=1
export COLS=224
export ROWS=224

export TARGET_EXTENT=Jamuna-Padoma_River_Extent.kmz

source ./functions.sh

#for LANDSAT in mosaic_auto/*; do
function riverMapping() {
    
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

    mkdir -p $(dirname $PRED_RIVER_RAS) $(dirname $PRED_RIVER_SHP) $(dirname $NDWI_RIVER)
    make $PRED_RIVER_SHP $NDWI_RIVER_SHP
    rm -rf $WORKDIR
}
export -f riverMapping



INPUTS=

#for YEAR in 2021; do #{1988..2020}
#    INPUTS="$INPUTS monthly_mosaic/$YEAR*.tif"
#done
:<<'#EOF'

for YEAR in {1972..2008}; do
    for MONTH in 4,4 5,5 6,6 7,7 8,8 9,9 10,10 11,11 12,12 ; do
	MONTH_BEGIN=$(printf %02d $(echo $MONTH | cut -f 1 -d ,))
	MONTH_END=$(printf %02d $(echo $MONTH | cut -f 2 -d ,))
	INPUT=monthly_mosaic/${YEAR}-${MONTH_BEGIN}-${MONTH_END}-cloudfree-median.tif
	if [ -e $INPUT ]; then
	    INPUTS="$INPUTS $INPUT"
	fi
    done
done
#EOF

#parallel -j2 --bar riverMapping ::: $INPUTS
#riverMapping monthly_mosaic/2021-01-03-cloudfree-median.tif

#parallel extractSHP ::: {1972..2015} ::: 4,6 7,9 10,12 ::: median
#extractSHP 2021 1,3 median



function exec() {
    export NDWI_RIVER_SHP=$1 # ndwi_river.shp.d/1993-05-05-cloudfree-median.tif.nwdi_river.shp

    YEAR=$(basename $NDWI_RIVER_SHP | sed 's/\([0-9]\{4\}\).*/\1/g')
    BASENAME=$(basename $NDWI_RIVER_SHP | sed 's/\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-cloudfree-median.tif\).*/\1/g')

    if [ $YEAR -ge 2014 ]; then
	export MODEL_FILE=checkpoint/FPN_epoch_200_Dec24_19_15.pth
    elif [ $YEAR -ge 1988 ]; then
	export MODEL_FILE=checkpoint/FPN_epoch_200_Dec24_19_15.pth
    else
	export MODEL_FILE=checkpoint/FPN_epoch_400_Nov23_16_05.pth
    fi

    export PRED_RIVER_SHP=river_segment.shp.d/$BASENAME.$(basename $MODEL_FILE).shp
    export RIVER_EXTENT=ndwi_river.extract.shp.d/median/$BASENAME.ndwi_river.extract.shp
    export RIVER_LINE=ndwi_river.extract.line.shp.d/$(basename $RIVER_EXTENT).line.shp
    make $RIVER_LINE
}
export -f exec

parallel exec ::: $(find ndwi_river.shp.d/ -type f -regex ".*\.shp$")
