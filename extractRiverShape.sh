#! /bin/bash

function extractSHP() {
    YEAR=$1
    COMPOSITE=$2
    NDWI_RIVER_SHP=ndwi_river.shp.d/$YEAR-01-03-cloudfree-${COMPOSITE}.tif.nwdi_river
    SEG_RIVER_SHP=river_segment.shp.d/$YEAR-01-03-cloudfree-${COMPOSITE}.tif.FPN_epoch_200_Dec24_19_15.pth
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
CREATE TABLE out AS select distinct layer1.geom from layer1 left join layer2 on ST_Intersects(layer1.geom, layer2.geom) where layer2.geom is not null;
.dumpshp out geom $OUTSHP UTF-8 POLYGON
EOF
}

export -f extractSHP

parallel -j75% extractSHP ::: {1988..2013} ::: mean median
