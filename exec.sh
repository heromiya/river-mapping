#! /bin/bash
rm -rf /tmp/*
export LD_LIBRARY_PATH=$HOME/miniconda3/lib/
export PYTHON=$(which python)
#python predict_auto.py -checkpoints FPN_epoch_400_Mar01_14_21.pth -data input -georef true
#python predict_auto.py -data input -checkpoints FPN_epoch_400_Mar01_14_21.pth -batch_size 2

export BATCH_SIZE=1
export COLS=224
export ROWS=224

export RIVER_EXTENT=Jamuna-Padoma_River_Extent.kmz

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

#for YEAR in {1972..2020}; do
#    for MONTH in {6..8}; do
#	export MONTH=$(printf %02d $MONTH)
#	if [ -e monthly_mosaic/${YEAR}-${MONTH}-${MONTH}-cloudfree-median.tif ]; then
#	    INPUTS="$INPUTS monthly_mosaic/${YEAR}-${MONTH}-${MONTH}-cloudfree-median.tif"
#	fi
#    done
#done

#parallel -j2 --bar riverMapping ::: $INPUTS
riverMapping monthly_mosaic/2021-01-03-cloudfree-median.tif

function extractSHP() {
    YEAR=$1
    MONTH_BEGIN=$(printf %02d $(echo $2 | cut -f 1 -d ,))
    MONTH_END=$(printf %02d $(echo $2 | cut -f 2 -d ,))
    COMPOSITE=$3
    
    NDWI_RIVER_SHP=ndwi_river.shp.d/$YEAR-${MONTH_BEGIN}-${MONTH_END}-cloudfree-${COMPOSITE}.tif.nwdi_river

    if [ $YEAR -ge 1988 ]; then
	export MODEL_NAME=FPN_epoch_200_Dec24_19_15.pth
    else
	export MODEL_NAME=FPN_epoch_400_Nov23_16_05.pth
    fi

    SEG_RIVER_SHP=river_segment.shp.d/$YEAR-${MONTH_BEGIN}-${MONTH_END}-cloudfree-${COMPOSITE}.tif.${MODEL_NAME}
    OUTSHP=ndwi_river.extract.shp.d/$COMPOSITE/$YEAR-${MONTH_BEGIN}-${MONTH_END}-cloudfree-${COMPOSITE}.tif.ndwi_river.extract
    mkdir -p $(dirname $OUTSHP)

    #ogr2ogr -f SQLite -append $SQLITE $NDWI_RIVER_SHP -nln layer1 
    #ogr2ogr -f SQLite -append $SQLITE $SEG_RIVER_SHP -nln layer2

    #ogr2ogr -sql "SELECT DISTINCT layer1.geometry,0 FROM layer1 LEFT JOIN layer2 ON ST_Intersects(layer1.geometry,layer2.geometry) WHERE layer2.geometry IS NOT NULL" test.shp $SQLITE

    spatialite <<EOF
.loadshp $NDWI_RIVER_SHP layer1 UTF-8 3857 geom pid AUTO 2d
.loadshp $SEG_RIVER_SHP  layer2 UTF-8 3857 geom pid AUTO 2d
SELECT CreateSpatialIndex('layer1', 'geom');
SELECT CreateSpatialIndex('layer2', 'geom');
CREATE TABLE out (fid PRIMARY KEY);
SELECT AddGeometryColumn('out', 'geom', 3857, 'MULTIPOLYGON', 'XY');
INSERT INTO out (geom) SELECT DISTINCT layer1.geom from layer1 left join layer2 on ST_Intersects(layer1.geom, layer2.geom) where layer2.geom is not null;
.dumpshp out geom $OUTSHP UTF-8 POLYGON
EOF
}

export -f extractSHP

#parallel extractSHP ::: {1988..2020} ::: 6 7 8 ::: median
extractSHP 2021 1,3 median
