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
#    rm -rf $WORKDIR
}
export -f riverMapping

for YEAR in {1988..2020}; do
    INPUTS="$INPUTS monthly_mosaic/$YEAR*.tif"
done

#parallel -j1 --bar riverMapping ::: $INPUTS
#for IN in monthly_mosaic/*.tif; do riverMapping $IN; done

function extractSHP() {
    YEAR=$1
    COMPOSITE=$2
    NDWI_RIVER_SHP=ndwi_river.shp.d/$YEAR-01-03-cloudfree-${COMPOSITE}.tif.nwdi_river

    if [ $YEAR -ge 1988 ]; then
	export MODEL_NAME=FPN_epoch_200_Dec24_19_15.pth
    else
	export MODEL_NAME=FPN_epoch_400_Nov23_16_05.pth
    fi

    SEG_RIVER_SHP=river_segment.shp.d/$YEAR-01-03-cloudfree-${COMPOSITE}.tif.${MODEL_NAME}
    OUTSHP=ndwi_river.extract.shp.d/$COMPOSITE/$YEAR-01-03-cloudfree-${COMPOSITE}.tif.ndwi_river.extract
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

parallel -j75% extractSHP ::: {1988..2020} ::: mean median
#extractSHP 1973 mean
#done
