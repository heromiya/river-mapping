#! /bin/bash
rm -rf /tmp/*
export LD_LIBRARY_PATH=$HOME/miniconda3/lib/
#python predict_auto.py -checkpoints FPN_epoch_400_Mar01_14_21.pth -data input -georef true
#python predict_auto.py -data input -checkpoints FPN_epoch_400_Mar01_14_21.pth -batch_size 2

export BATCH_SIZE=1
export COLS=1008
export ROWS=1008
#export MODEL_FILE=checkpoint/FPN_epoch_400_Mar01_14_21.pth
export MODEL_FILE=checkpoint/FPN_epoch_200_Dec24_19_15.pth

#for LANDSAT in mosaic_auto/*; do
function riverMapping() {
    
    export IN_LANDSAT=$1
    export WORKDIR=$(mktemp -d)

    export PRED_RIVER_RAS=river_segment.pred.d/$(basename $IN_LANDSAT).$(basename $MODEL_FILE).tif
    export PRED_RIVER_RAS_VRT=river_segment.pred.d/$(basename $IN_LANDSAT).$(basename $MODEL_FILE).vrt
    export PRED_RIVER_SHP=river_segment.shp.d/$(basename $IN_LANDSAT).$(basename $MODEL_FILE)${EIGHT}.shp

    export NDWI_RIVER=ndwi_river.rast.d/$(basename $IN_LANDSAT).nwdi_river.sdat
    export NDWI_RIVER_SHP=ndwi_river.shp.d/$(basename $IN_LANDSAT).nwdi_river.shp

    export YEAR=$(echo $IN_LANDSAT | sed 's/.*\([0-9]\{4\}\)-.*tif/\1/g')

    if [ $YEAR -ge 2014 ]; then
	export GREEN=3
	export RED=4
	export NIR=5
	export SWIR=6
    else
	export GREEN=2
	export RED=3
	export NIR=4
	export SWIR=5
    fi
    mkdir -p $(dirname $PRED_RIVER_RAS) $(dirname $PRED_RIVER_SHP) $(dirname $NDWI_RIVER)
    make $PRED_RIVER_SHP $NDWI_RIVER_SHP
    rm -rf $WORKDIR
}
export -f riverMapping

export EIGHT=
parallel -j1 --bar riverMapping ::: monthly_mosaic/*.tif
#for IN in monthly_mosaic/*.tif; do riverMapping $IN; done


#done
