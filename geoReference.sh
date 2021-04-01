#! /bin/bash

INPUT=$1
REF=$2
OUTVRT=$3
OUTSHP=$4

#PROJ=$(gdalinfo -proj4 $REF | grep 'proj=')
UL=($(gdalinfo $REF -json | jq .cornerCoordinates.upperLeft))
LR=($(gdalinfo $REF -json | jq .cornerCoordinates.lowerRight))

gdal_translate -of VRT -a_srs "EPSG:32646" -a_ullr ${UL[0]} ${UL[1]} ${LR[0]} ${LR[1]} $INPUT $OUTVRT
gdal_polygonize.py -f "ESRI Shapefile" $OUTVRT $OUTSHP
