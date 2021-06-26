$(PRED_RIVER_RAS): $(IN_LANDSAT)
	gdal_translate -of GTIFF -b $(RED) -b $(SWIR) -b $(NIR) -co COMPRESS=Deflate $< $(WORKDIR)/band_subset.tif 
	python predict_auto.py -test_img $(WORKDIR)/band_subset.tif -checkpoint $(MODEL_FILE) -test_pred $@ -batch_size $(BATCH_SIZE)
#gdalwarp -of GTIFF -b $(RED) -b $(SWIR) -b $(NIR) -cutline 'Jamuna-Padoma River Extent.kmz' -co COMPRESS=Deflate $< $(WORKDIR)/band_subset.tif
#MEAN=(`gdalinfo $IN_LANDSAT | awk 'BEGIN {FS="="}/STATISTICS_MEAN/{printf("%s ", \$2)}'`)
#SD=(`gdalinfo $IN_LANDSAT | awk 'BEGIN {FS="="}/STATISTICS_STDDEV/{printf("%s ", \$2)}'`)

$(PRED_RIVER_RAS_VRT): $(PRED_RIVER_RAS)
	gdalbuildvrt -srcnodata 0 -vrtnodata 0 $@ $<

$(PRED_RIVER_SHP): $(PRED_RIVER_RAS_VRT)
	gdal_polygonize.py -f "ESRI Shapefile" $< $@

$(NDWI_RIVER): $(IN_LANDSAT)
	gdal_translate -of VRT -b $(GREEN) $< $(WORKDIR)/green.vrt
	gdal_translate -of VRT -b $(SWIR) $<  $(WORKDIR)/swir.vrt
	saga_cmd grid_calculus 1 -GRIDS $(WORKDIR)/green.vrt\;$(WORKDIR)/swir.vrt -RESULT $@ -FORMULA "gt((g1-g2)/(g1+g2),0)" -TYPE 1

$(NDWI_RIVER_SHP): $(NDWI_RIVER)
	mkdir -p `dirname $@`
	gdalbuildvrt -srcnodata 0 -vrtnodata 0 $(WORKDIR)/river.vrt $<
	gdal_polygonize.py -f "ESRI Shapefile" $(WORKDIR)/river.vrt $@

#	gdal_calc.py --calc="(A - B) / (A + B + 1)" --type=Float32 --outfile=$@ -A $< --A_band $(GREEN) -B $< --B_band $(SWIR) 

