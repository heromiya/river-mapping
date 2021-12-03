#! /bin/bash

function extractSHP() {

    NDWI_RIVER_SHP=$(echo $1 | sed 's/\.shp$//') #ndwi_river.shp.d/$YEAR-${MONTH_BEGIN}-${MONTH_END}-cloudfree-${COMPOSITE}.tif.nwdi_rive
    SEG_RIVER_SHP=$(echo $2  | sed 's/\.shp$//') #river_segment.shp.d/$YEAR-${MONTH_BEGIN}-${MONTH_END}-cloudfree-${COMPOSITE}.tif.${MODEL_NAME}
    OUTSHP=$(echo $3 | sed 's/\.shp$//') #ndwi_river.extract.shp.d/$COMPOSITE/$YEAR-${MONTH_BEGIN}-${MONTH_END}-cloudfree-${COMPOSITE}.tif.ndwi_river.extract

    #COMPOSITE=$3
    
    YEAR=$(basename $NDWI_RIVER_SHP | sed 's/\([0-9]\{4\}\).*/\1/g')
    if [ $YEAR -ge 1988 ]; then
	export MODEL_NAME=FPN_epoch_200_Dec24_19_15.pth
    else
	export MODEL_NAME=FPN_epoch_400_Nov23_16_05.pth
    fi

    mkdir -p $(dirname $OUTSHP)

    spatialite $WORKDIR/spatialite.sqlite <<EOF
.loadshp $NDWI_RIVER_SHP layer1 UTF-8 3857 geom pid AUTO 2d
.loadshp $SEG_RIVER_SHP  layer2 UTF-8 3857 geom pid AUTO 2d
SELECT CreateSpatialIndex('layer1', 'geom');
SELECT CreateSpatialIndex('layer2', 'geom');
CREATE TABLE out (fid PRIMARY KEY);
SELECT AddGeometryColumn('out', 'geom', 3857, 'POLYGON', 'XY');
INSERT INTO out (geom) SELECT DISTINCT layer1.geom from layer1 left join layer2 on ST_Intersects(layer1.geom, layer2.geom) where layer2.geom is not null;
.dumpshp out geom $OUTSHP UTF-8 POLYGON
EOF
}
export -f extractSHP

function centerline(){
    IN=$1
    OUT_LINE=$2
    WORKDIR=$(mktemp -d)
    GRASS_SCRIPT=$WORKDIR/grass.sh

    YEAR=$(basename $IN | sed 's/^\([0-9]\{4\}\).*/\1/g')

    if [ $NDWI_ONLY = 'TRUE' ]; then
	#cp $IN  $WORKDIR/rast.tif
	gdalwarp -multi -cutline $TARGET_EXTENT -dstnodata 0 $IN $WORKDIR/rast.tif
	#gdal_sieve.py -q -8 -st $CENTERLINE_THRESHOLD $WORKDIR/rast.tif $WORKDIR/sieved.tif
	
    else
	if [ $YEAR -ge 1984 ]; then
	    tres=30
	else
	    tres=60
	fi

	gdal_rasterize -q -burn 1 -tr $tres $tres $IN $WORKDIR/rast.tif
	#gdal_sieve.py -q -8 -st $CENTERLINE_THRESHOLD $WORKDIR/rast.tif
    fi
    
    cat > $GRASS_SCRIPT <<EOF
    r.external input=$WORKDIR/rast.tif output=rast $GRASS_OPT
    g.region raster=rast $GRASS_OPT
    r.null map=rast null=0 $GRASS_OPT
    r.neighbors -c input=rast output=out method=mode size=$MODE_FILTER_SIZE $GRASS_OPT
    r.out.gdal -f input=out output=$WORKDIR/rast.tif type=Byte createopt=COMPRESS=Deflate nodata=0 $GRASS_OPT
EOF
    chmod u+x $GRASS_SCRIPT
    export PROJ_LIB=/usr/share/proj/
    grass78 -c EPSG:3857 --tmp-location --exec sh $GRASS_SCRIPT

    python skeleton.py $WORKDIR/rast.tif skel $WORKDIR/skeleton.tif
    export PROJ_LIB=/usr/share/proj/
    grass -c $WORKDIR/temploc --exec $PWD/raster2polyline.sh $WORKDIR/skeleton.tif  $WORKDIR/vect.gpkg
    /usr/bin/ogr2ogr -a_srs EPSG:3857 -f "ESRI Shapefile" $OUT_LINE $WORKDIR/vect.gpkg
    rm -rf $WORKDIR

}
export -f centerline

function riverwidth(){
    IN=$1
    OUT_DIST=$2
    WORKDIR=$(mktemp -d)

    YEAR=$(basename $IN | sed 's/^\([0-9]\{4\}\).*/\1/g')

    if [ $YEAR -ge 1984 ]; then
	tres=30
    else
	tres=60
    fi

    gdal_rasterize -q -burn 1 -tr $tres $tres $IN $WORKDIR/rast.tif
    gdal_sieve.py -q -st 1000 $WORKDIR/rast.tif

    python skeleton.py $WORKDIR/rast.tif dist $OUT_DIST
    rm -rf $WORKDIR

}
export -f riverwidth

function map_output_river(){
    WORKDIR=$(mktemp -d)
    
    EXTENT_SHP=$(echo $PWD/$1 | sed 's/\//\\\//g')
    LINE_SHP=$(echo $PWD/$2 | sed 's/\//\\\//g')

    PERIOD=$(basename $LINE_SHP | sed 's/\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)-.*/\1/g') #2021-01-03

    sed "s/_EXTENT_SHP_/$EXTENT_SHP/g; s/_LINE_SHP_/$LINE_SHP/g" mapfile.river.template.map > $WORKDIR/mapfile.map

    shp2img -m $WORKDIR/mapfile.map -o $WORKDIR/map_output.png
    convert $WORKDIR/map_output.png -pointsize 96 -gravity northwest -annotate +10+10 "${PERIOD}" $3 # $MAP_OUTPUT/$PERIOD-map_output.png
    rm -rf $WORKDIR
}


function map_output_vegetation(){
    WORKDIR=$(mktemp -d)
    
    VEG_RAST=$(echo $1 | sed 's/\//\\\//g')

    PERIOD=$(basename $VEG_RAST | sed 's/\([0-9]\{4\}\).*/\1/g') #2021-01-03

    sed "s/_VEG_RAST_/$VEG_RAST/g" mapfile.vegetation.template.map > $WORKDIR/mapfile.map

    shp2img -m $WORKDIR/mapfile.map -o $WORKDIR/map_output.png
    convert $WORKDIR/map_output.png -pointsize 96 -gravity northwest -annotate +10+10 "${PERIOD}" $2 # $MAP_OUTPUT/$PERIOD-map_output.png
    rm -rf $WORKDIR
}

function identify_major_stream(){
    WORKDIR=$(mktemp -d)
    GRASS_SCRIPT=$WORKDIR/grass.sh
    
    IN_DIST=$1
    OUT_LINE=$2
    GRASS_OPT="--overwrite"
    cat > $GRASS_SCRIPT <<EOF
    r.external input=$IN_DIST output=dist $GRASS_OPT
    g.region raster=dist $GRASS_OPT
    r.mapcalc expression="cost_sur = 1000000 / (dist + 1)^5" $GRASS_OPT
    r.cost -kb input=cost_sur output=cost start_coordinates=10082459.73,3025052.87 outdir=dir $GRASS_OPT
    r.path input=dir format=auto vector_path=path start_coordinates=10113912.32,2582622.93 $GRASS_OPT
    v.out.ogr input=path type=line output=$OUT_LINE format=ESRI_Shapefile $GRASS_OPT
EOF
    chmod u+x $GRASS_SCRIPT
    export PROJ_LIB=/usr/share/proj/
    grass78 -c EPSG:3857 --tmp-location --exec sh $GRASS_SCRIPT
    rm -rf $WORKDIR
        
}
export -f identify_major_stream

function ndwi_river() {
    WORKDIR=$(mktemp -d)
    GRASS_SCRIPT=$WORKDIR/grass.sh
    
    IN_GREEN=$1
    IN_NIR=$2
    IN_SWIR=$3
    OUT=$4
    NDWI0=NDWI0.gpkg
    ogr2ogr -t_srs EPSG:3857 $WORKDIR/NDWI0.gpkg $NDWI0
    GRASS_OPT="--overwrite"
    cat > $GRASS_SCRIPT <<EOF
    r.external input=$IN_GREEN output=green $GRASS_OPT
    r.external input=$IN_NIR output=nir $GRASS_OPT
    g.region raster=green $GRASS_OPT
    v.in.ogr input=$WORKDIR/NDWI0.gpkg output=ndvi0_vec $GRASS_OPT
    v.to.rast input=ndvi0_vec output=ndvi0 use=val value=1 $GRASS_OPT
    r.null map=ndvi0 null=0 $GRASS_OPT
    r.mapcalc expression="river = if(ndvi0==1, (green-nir+0.001)/(green+nir+0.001) > $NDWI_THRESHOLD_1, (green-nir+0.001)/(green+nir+0.001) > $NDWI_THRESHOLD_2) " $GRASS_OPT
    r.out.gdal input=river output=$OUT type=Byte createopt=COMPRESS=Deflate $GRASS_OPT
EOF
    chmod u+x $GRASS_SCRIPT
    export PROJ_LIB=/usr/share/proj/
    grass78 -c EPSG:3857 --tmp-location --exec sh $GRASS_SCRIPT
    rm -rf $WORKDIR

}

function rast2poly () {
    WORKDIR=$(mktemp -d)
    GRASS_SCRIPT=$WORKDIR/grass.sh
    
    IN=$1
    VALUE=$2
    OUT=$3
    GRASS_OPT="--overwrite"
    cat > $GRASS_SCRIPT <<EOF
    r.external input=$IN output=in $GRASS_OPT
    g.region raster=in $GRASS_OPT
    #r.null map=in setnull=0 $GRASS_OPT
    r.mask raster=in maskcats=$VALUE
    r.to.vect input=in output=out type=area $GRASS_OPT
    v.out.ogr input=out output=$OUT format=ESRI_Shapefile $GRASS_OPT

EOF
    chmod u+x $GRASS_SCRIPT
    export PROJ_LIB=/usr/share/proj/
    grass78 -c EPSG:3857 --tmp-location --exec sh $GRASS_SCRIPT
    rm -rf $WORKDIR
    
}

$1 $2 $3 $4 $5 $6 $7 $8 $9
