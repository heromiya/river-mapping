#! /bin/bash

GRASS_OPT="--overwrite --quiet"
r.in.gdal -oe input=$1 output=rast $GRASS_OPT
g.region raster=rast $GRASS_OPT
r.to.vect input=rast output=vect type=area $GRASS_OPT
v.out.ogr input=vect output=$2 format="ESRI Shapefile" $GRASS_OPT
