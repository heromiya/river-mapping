#! /bin/bash

for DIR in ndwi_river.extract.shp.d/median ndwi_river.extract.line.shp.mode9.d map_output.d; do
    for FILE in $(find Jamuna-Padoma_River_Extent.d/$DIR/quarterly/ -type f | grep $(for i in {1..12}; do printf ' -e -%02d-%02d-' $i $i; done));do
	YEAR=$(echo $FILE | sed 's/.*\([0-9]\{4\}\)-.*/\1/g')
	mv $FILE Jamuna-Padoma_River_Extent.d/$DIR/monthly/$YEAR
    done
done
