$(PRED_RIVER_RAS): $(IN_LANDSAT)
	gdal_translate -q -of GTIFF -b $(RED) -b $(SWIR) -b $(NIR) -scale $(SCALE) -co COMPRESS=Deflate $< $(WORKDIR)/band_subset.tif
	parallel gdal_fillnodata.py -q -b {} $(WORKDIR)/band_subset.tif $(WORKDIR)/band_subset.filled.{}.tif ::: 1 2 3
	gdal_merge.py -q -separate -o $(WORKDIR)/band_subset.filled.tif -of GTIFF -co COMPRESS=Deflate $(WORKDIR)/band_subset.filled.*.tif 
	export LD_LIBRARY_PATH=/home/heromiya/miniconda3/lib && $(PYTHON) predict_auto.py -test_img $(WORKDIR)/band_subset.filled.tif -checkpoint $(MODEL_FILE) -test_pred $@ -batch_size $(BATCH_SIZE) -img_cols $(COLS) -img_rows $(ROWS)

$(PRED_RIVER_RAS_VRT): $(PRED_RIVER_RAS)
	gdalbuildvrt -srcnodata 0 -vrtnodata 0 $@ $<

$(PRED_RIVER_SHP): $(PRED_RIVER_RAS)
	saga_cmd --flags=s shapes_grid 6 -GRID $< -POLYGONS $@ -CLASS_ALL 0 -CLASS_ID 255 -SPLIT 1

$(NDWI_RIVER): $(IN_LANDSAT)
	gdal_translate -of VRT -b $(GREEN) $< $(WORKDIR)/green.vrt
	gdal_translate -of VRT -b $(NIR) $<  $(WORKDIR)/nir.vrt
	saga_cmd --flags=s grid_calculus 1 -GRIDS $(WORKDIR)/green.vrt\;$(WORKDIR)/nir.vrt -RESULT $@ -FORMULA "gt((g1-g2+0.001)/(g1+g2+0.001),$(NDWI_THRESHOLD))" -TYPE 1

$(NDWI_RIVER_SHP): $(NDWI_RIVER) $(TARGET_EXTENT)
	mkdir -p `dirname $@`
	gdalwarp -of VRT -cutline $(TARGET_EXTENT) -co COMPRESS=Deflate $< $(WORKDIR)/ndwi_cut.vrt
	saga_cmd --flags=s shapes_grid 6 -GRID $(WORKDIR)/ndwi_cut.vrt -POLYGONS $@ -CLASS_ALL 0 -CLASS_ID 1 -SPLIT 1

$(RIVER_LINE): $(RIVER_EXTENT)
	./functions.sh centerline $+ $@

$(RIVER_EXTENT): $(NDWI_RIVER_SHP) $(PRED_RIVER_SHP)
	./functions.sh extractSHP $+ $@
