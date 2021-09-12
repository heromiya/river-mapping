#! /bin/bash

#function centerline(){

IN=$1
#OUT=$(basename $IN)
OUT=ndwi_river.extract.line.shp.d/$(basename $IN).line.shp


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

#}
#export -f centerline
#parallel centerline ::: $(find ndwi_river.extract.shp.d/median/ -type f -regex ".*2021.*.shp")
#centerline ndwi_river.extract.shp.d/median/2021-01-03-cloudfree-median.tif.ndwi_river.extract.shp
exit 0
