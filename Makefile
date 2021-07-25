$(PRED_RIVER_RAS): $(IN_LANDSAT)
# 210627	gdal_translate -of GTIFF -b $(RED) -b $(SWIR) -b $(NIR) -scale_1 7750 15000 -scale_2 8000 20000 -scale_3 9000 17500 -co COMPRESS=Deflate $< $(WORKDIR)/band_subset.tif
	gdal_translate -of GTIFF -b $(RED) -b $(SWIR) -b $(NIR) -scale $(SCALE) -co COMPRESS=Deflate $< $(WORKDIR)/band_subset.tif
	parallel gdal_fillnodata.py -b {} $(WORKDIR)/band_subset.tif $(WORKDIR)/band_subset.filled.{}.tif ::: 1 2 3
	gdal_merge.py -separate -o $(WORKDIR)/band_subset.filled.tif -of GTIFF -co COMPRESS=Deflate $(WORKDIR)/band_subset.filled.*.tif 
	$(PYTHON) predict_auto.py -test_img $(WORKDIR)/band_subset.filled.tif -checkpoint $(MODEL_FILE) -test_pred $@ -batch_size $(BATCH_SIZE) -img_cols $(COLS) -img_rows $(ROWS)

#	gdal_fillnodata.py -b 2 $(WORKDIR)/band_subset.tif $(WORKDIR)/band_subset.filled.2.tif 
#	gdal_fillnodata.py -b 3 $(WORKDIR)/band_subset.tif $(WORKDIR)/band_subset.filled.3.tif

#MEAN=(`gdalinfo $IN_LANDSAT | awk 'BEGIN {FS="="}/STATISTICS_MEAN/{printf("%s ", \$2)}'`)
#SD=(`gdalinfo $IN_LANDSAT | awk 'BEGIN {FS="="}/STATISTICS_STDDEV/{printf("%s ", \$2)}'`)

$(PRED_RIVER_RAS_VRT): $(PRED_RIVER_RAS)
	gdalbuildvrt -srcnodata 0 -vrtnodata 0 $@ $<
# -b $(RED) -b $(SWIR) -b $(NIR)

$(PRED_RIVER_SHP): $(PRED_RIVER_RAS)
	saga_cmd shapes_grid 6 -GRID $< -POLYGONS $@ -CLASS_ALL 0 -CLASS_ID 255 -SPLIT 1

$(NDWI_RIVER): $(IN_LANDSAT)
	gdal_translate -of VRT -b $(GREEN) $< $(WORKDIR)/green.vrt
	gdal_translate -of VRT -b $(NIR) $<  $(WORKDIR)/nir.vrt
	saga_cmd grid_calculus 1 -GRIDS $(WORKDIR)/green.vrt\;$(WORKDIR)/nir.vrt -RESULT $@ -FORMULA "gt((g1-g2+0.001)/(g1+g2+0.001),$(NDWI_THRESHOLD))" -TYPE 1

$(NDWI_RIVER_SHP): $(NDWI_RIVER) $(RIVER_EXTENT)
	mkdir -p `dirname $@`
	gdalwarp -of VRT -cutline $(RIVER_EXTENT) -co COMPRESS=Deflate $< $(WORKDIR)/ndwi_cut.vrt
	saga_cmd shapes_grid 6 -GRID $(WORKDIR)/ndwi_cut.vrt -POLYGONS $@ -CLASS_ALL 0 -CLASS_ID 1 -SPLIT 1
