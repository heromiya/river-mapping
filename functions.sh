#! /bin/bash

function extractSHP() {
    #YEAR=$1
    #MONTH_BEGIN=$(printf %02d $(echo $2 | cut -f 1 -d ,))
    #MONTH_END=$(printf %02d $(echo $2 | cut -f 2 -d ,))

    NDWI_RIVER_SHP=$(echo $1 | sed 's/\.shp$//') #ndwi_river.shp.d/$YEAR-${MONTH_BEGIN}-${MONTH_END}-cloudfree-${COMPOSITE}.tif.nwdi_rive
    SEG_RIVER_SHP=$(echo $2  | sed 's/\.shp$//') #river_segment.shp.d/$YEAR-${MONTH_BEGIN}-${MONTH_END}-cloudfree-${COMPOSITE}.tif.${MODEL_NAME}
    OUTSHP=$3 #ndwi_river.extract.shp.d/$COMPOSITE/$YEAR-${MONTH_BEGIN}-${MONTH_END}-cloudfree-${COMPOSITE}.tif.ndwi_river.extract

    #COMPOSITE=$3
    
    YEAR=$(basename $NDWI_RIVER_SHP | sed 's/\([0-9]\{4\}\).*/\1/g')
    if [ $YEAR -ge 1988 ]; then
	export MODEL_NAME=FPN_epoch_200_Dec24_19_15.pth
    else
	export MODEL_NAME=FPN_epoch_400_Nov23_16_05.pth
    fi

    mkdir -p $(dirname $OUTSHP)

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

function centerline(){

    IN=$1
    OUT=$2


    WORKDIR=$(mktemp -d)

    YEAR=$(basename $IN | sed 's/^\([0-9]\{4\}\).*/\1/g')

    if [ $YEAR -ge 1984 ]; then
	tres=30
    else
	tres=60
    fi

    gdal_rasterize -burn 1 -tr $tres $tres $IN $WORKDIR/rast.tif
    gdal_sieve.py -st 1000 $WORKDIR/rast.tif

    python skeleton.py  $WORKDIR/rast.tif $WORKDIR/skeleton.tif
    grass -c $WORKDIR/temploc --exec $PWD/raster2polyline.sh $WORKDIR/skeleton.tif  $WORKDIR/vect.gpkg
    ogr2ogr -a_srs EPSG:3857 -f "ESRI Shapefile" $OUT $WORKDIR/vect.gpkg
    rm -rf $WORKDIR

}
export -f centerline

$($1 $2 $3 $4 $5 $6 $7 $8 $9)
