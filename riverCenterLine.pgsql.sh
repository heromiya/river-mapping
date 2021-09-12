#! /bin/bash

mkdir -p ndwi_river.extract.line.shp.d
WORKDIR=$(mktemp -d)

INPUT_SHP=$1
OUTPUT_SHP=ndwi_river.extract.line.shp.d/$(basename $INPUT_SHP).line.shp

TABLE_NAME=t$(basename $INPUT_SHP | sed 's/\./_/g; s/-/_/g')
#TABLE_NAME=$(echo $INPUT_SHP | md5sum | cut -f 1 -d " ")

YEAR=$(basename $INPUT_SHP | sed 's/^\([0-9]\{4\}\).*/\1/g')

if [ $YEAR -ge 1984 ]; then
    tolerance=29
    tres=30
else
    tolerance=59
    tres=60
fi

gdal_rasterize -burn 1 -tr $tres $tres $INPUT_SHP $WORKDIR/rast.tif
gdal_sieve.py -st 1000 $WORKDIR/rast.tif
gdal_translate -a_nodata 0 -of VRT $WORKDIR/rast.tif $WORKDIR/rast.vrt
gdal_polygonize.py $WORKDIR/rast.vrt -f gpkg $WORKDIR/sieve.poly.gpkg

ogr2ogr -overwrite  PG:"dbname=heromiya" $WORKDIR/sieve.poly.gpkg -lco OVERWRITE=YES -nln $TABLE_NAME -nlt PROMOTE_TO_MULTI
ogr2ogr -sql "select ST_ApproximateMedialAxis(ST_MakeValid(ST_Simplify(geom,$tolerance,false))) from $TABLE_NAME" $OUTPUT_SHP PG:"dbname=heromiya"


# ogr2ogr -f gpkg -sql "select  from d41d8cd98f00b204e9800998ecf8427e" test.valid.gpkg PG:"dbname=heromiya"
