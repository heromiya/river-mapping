#! /bin/bash
export LD_LIBRARY_PATH=$HOME/miniconda3/lib/
#python predict_auto.py -checkpoints FPN_epoch_400_Mar01_14_21.pth -data input -georef true
#python predict_auto.py -data input -checkpoints FPN_epoch_400_Mar01_14_21.pth -batch_size 2

export BATCH_SIZE=4
export MODEL_FILE=checkpoint/FPN_epoch_400_Mar01_14_21.pth

#for LANDSAT in mosaic_auto/*; do
function riverMapping() {
    
    export IN_LANDSAT=$1
    export PRED_RIVER_RAS=river_segment.pred.d/$(basename $IN_LANDSAT).$(basename $MODEL_FILE).tif
    export PRED_RIVER_RAS_VRT=river_segment.pred.d/$(basename $IN_LANDSAT).$(basename $MODEL_FILE).vrt
    export PRED_RIVER_SHP=river_segment.shp.d/$(basename $IN_LANDSAT).$(basename $MODEL_FILE).shp

    mkdir -p $(dirname PRED_RIVER_RAS) $(dirname PRED_RIVER_SHP)
    make $PRED_RIVER_SHP
}
export -f riverMapping

parallel -j1 --bar riverMapping ::: monthly_mosaic/*.tif

#done
