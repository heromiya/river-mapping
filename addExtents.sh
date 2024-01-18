#! /bin/bash

WORKDIR=temp
for SHP in $(find BGD-broad_extent/ndwi_river.extract.shp.d/median/quarterly/ -type f -regex ".*.shp$" | grep 2018); do
    YEAR=$(basename $SHP | sed 's/.*\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/g')
    NDWI_RIVER_SHP=$(find BGD-broad_extent/ndwi_river.shp.d/ -type f -regex ".*$YEAR.*shp$")

    rm -rf $WORKDIR/db.sqlite
    export i=0
#    for SHP in $NDWI_RIVER_SHP AdditionalExtent.kmz; do
#	i=$(expr $i + 1)
#	ogr2ogr -f SQLite -append -t_srs EPSG:3857 $WORKDIR/db.sqlite $SHP -nln layer$i
    #done
    
    spatialite $WORKDIR/db.sqlite <<EOF 
.loadshp $(echo $NDWI_RIVER_SHP | sed 's/.shp$//g') layer1 UTF-8 3857 geom pid AUTO 2d
.loadshp AdditionalExtent  layer2 UTF-8 3857 geom pid AUTO 2d
SELECT CreateSpatialIndex('layer1', 'geom');
SELECT CreateSpatialIndex('layer2', 'geom');
CREATE TABLE out (fid PRIMARY KEY);
SELECT AddGeometryColumn('out', 'geom', 3857, 'POLYGON', 'XY');
INSERT INTO out (geom) 
       SELECT DISTINCT layer1.geom 
       FROM layer1 left join layer2 on ST_Intersects(layer1.geom, layer2.geom) where layer2.geom is not null;
EOF

ogr2ogr -append $SHP temp/db.sqlite out
done

#.dumpshp out GEOMETRY $WORKDIR/intersect.shp UTF-8 POLYGON
#INSERT INTO geometry_columns (f_table_name, f_geometry_column, geometry_type, coord_dimension, srid, geometry_format) VALUES ('out','GEOMETRY',3,2,3857,'WKB'); 


	   
