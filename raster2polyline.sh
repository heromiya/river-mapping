#! /bin/bash

GRASS_OPT="--overwrite --quiet"
r.in.gdal -oe input=$1 output=rast $GRASS_OPT #skeleton-lee.tif
g.region raster=rast $GRASS_OPT
r.null map=rast setnull=0 $GRASS_OPT
r.thin input=rast output=rast.thin $GRASS_OPT
r.to.vect -s input=rast.thin output=vect type=line $GRASS_OPT
v.out.ogr input=vect type=line output=$2 $GRASS_OPT
