for YEAR in {1972..2021}; do
    for MONTH in {1..12}; do
	MONTH=$(printf %02d $MONTH)
	mkdir -p map_output.d/monthly/$YEAR/
	mv -f $(find map_output.d/ -type f -regex ".*$YEAR-$MONTH-$MONTH-.*") map_output.d/monthly/$YEAR/
    done

    for QUARTER in 01-03 04-06 07-09 10-12; do
	mkdir -p map_output.d/quarterly/$YEAR
	mv -f $(find map_output.d/ -type f -regex ".*$YEAR-$QUARTER-.*") map_output.d/quarterly/$YEAR
    done

    for MONTH in {1..12}; do
	MONTH=$(printf %02d $MONTH)
	mkdir -p ndwi_river.extract.shp.d/median/monthly/$YEAR ndwi_river.extract.line.shp.d/monthly/$YEAR
	mv -f $(find ndwi_river.extract.shp.d/median/ -type f -regex ".*$YEAR-$MONTH-$MONTH-.*") ndwi_river.extract.shp.d/median/monthly/$YEAR/
	mv -f $(find ndwi_river.extract.line.shp.d/ -type f -regex ".*$YEAR-$MONTH-$MONTH-.*") ndwi_river.extract.line.shp.d/monthly/$YEAR/
    done

    for QUARTER in 01-03 04-06 07-09 10-12; do
	mkdir -p ndwi_river.extract.shp.d/median/quarterly/$YEAR  ndwi_river.extract.line.shp.d/quarterly/$YEAR
	mv -f $(find ndwi_river.extract.shp.d/median/ -type f -regex ".*$YEAR-$QUARTER-.*") ndwi_river.extract.shp.d/median/quarterly/$YEAR/
	mv -f $(find ndwi_river.extract.line.shp.d/   -type f -regex ".*$YEAR-$QUARTER-.*") ndwi_river.extract.line.shp.d/quarterly/$YEAR/
    done
done

./copyProductsForDelivery.sh
