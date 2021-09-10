#! /bin/bash

r.in.gdal -oe input=$1 output=rast --overwrite #skeleton-lee.tif
#r.region map=name [region=name] [raster=name] [vector=name] [n=value] [s=value] [e=value] [w=value] [align=name] [--help] [--verbose] [--quiet] [--ui]
g.region raster=rast
g.region -p
r.null map=rast setnull=0
r.thin input=rast output=rast.thin --overwrite
r.to.vect -s input=rast.thin output=vect type=line --overwrite
v.out.ogr input=vect type=line output=$2 --overwrite #vect.gpkg
