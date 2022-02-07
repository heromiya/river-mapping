$(PRED_RIVER_RAS): $(IN_LANDSAT)
	mkdir -p `dirname $@`
	gdal_translate -q -projwin 9792564.318951 3052509.123221 10202099.960504 2449237.328724 -of VRT -b $(RED) -b $(SWIR) -b $(NIR) -scale $(SCALE) -co COMPRESS=Deflate $< $(WORKDIR)/band_subset.vrt
	parallel -j1 gdal_fillnodata.py -q -b {} $(WORKDIR)/band_subset.vrt $(WORKDIR)/band_subset.filled.{}.tif ::: 1 2 3
	gdal_merge.py -q -separate -o $(WORKDIR)/band_subset.filled.tif -of GTIFF -co COMPRESS=Deflate $(WORKDIR)/band_subset.filled.*.tif
	sleep `echo $$$$ % 120 | bc` && while [ `ps aux | grep predict_auto.py | grep -v grep | wc -l` -gt 1 ]; do sleep 60; done && \
	export LD_LIBRARY_PATH=/home/heromiya/miniconda3/lib && $(PYTHON) predict_auto.py -test_img $(WORKDIR)/band_subset.filled.tif -checkpoint $(MODEL_FILE) -test_pred $@ -batch_size $(BATCH_SIZE) -img_cols $(COLS) -img_rows $(ROWS)

$(PRED_RIVER_RAS_VRT): $(PRED_RIVER_RAS)
	mkdir -p `dirname $@`
	gdalbuildvrt -srcnodata 0 -vrtnodata 0 $@ $<

$(PRED_RIVER_SHP): $(PRED_RIVER_RAS)
	mkdir -p `dirname $@`
	gdalwarp -of VRT -cutline $(TARGET_EXTENT) $< $(WORKDIR)/cut.vrt
	./functions.sh rast2poly $(WORKDIR)/cut.vrt 255 $@

$(NDWI_RIVER): $(IN_LANDSAT)
	mkdir -p `dirname $@`
	gdal_translate -of VRT -b $(GREEN) $< $(WORKDIR)/green.vrt
	gdal_translate -of VRT -b $(NIR) $<  $(WORKDIR)/nir.vrt
	gdal_translate -of VRT -b $(SWIR) $<  $(WORKDIR)/swir.vrt
	./functions.sh ndwi_river  $(WORKDIR)/green.vrt $(WORKDIR)/nir.vrt $(WORKDIR)/swir.vrt $@

$(NDWI_RIVER_SHP): $(NDWI_RIVER) $(TARGET_EXTENT)
	mkdir -p `dirname $@`
	gdalwarp -of VRT -cutline $(TARGET_EXTENT) -co COMPRESS=Deflate $< $(WORKDIR)/ndwi_cut.vrt
	./functions.sh rast2poly $(WORKDIR)/ndwi_cut.vrt 1 $@

ifeq ($(NDWI_ONLY),TRUE)
$(RIVER_LINE): $(NDWI_RIVER)
	mkdir -p `dirname $@`
	./functions.sh centerline $< $@
else
$(RIVER_LINE): $(RIVER_EXTENT)
	mkdir -p `dirname $@`
	if [ `ogrinfo $(RIVER_EXTENT) -al -summary | grep "Feature Count" | cut -f 3 -d " "` -gt 0 ]; then ./functions.sh centerline $(RIVER_EXTENT) $@; fi
endif

$(RIVER_LINE_DIST_RAST): $(RIVER_EXTENT)
	mkdir -p `dirname $@`
	if [ `ogrinfo $(RIVER_EXTENT) -al -summary | grep "Feature Count" | cut -f 3 -d " "` -gt 0 ]; then ./functions.sh riverwidth $(RIVER_EXTENT) $@; fi

$(RIVER_LINE_DIST_VECT): $(RIVER_LINE_DIST_RAST)
	mkdir -p `dirname $@`
	./functions.sh raster2polyline $< $@

$(RIVER_MAJOR_STREAM): $(RIVER_LINE_DIST)
	mkdir -p `dirname $@`
	./functions.sh identify_major_stream $< $@

$(RIVER_EXTENT): $(NDWI_RIVER_SHP) $(PRED_RIVER_SHP)
	mkdir -p `dirname $@`
	./functions.sh extractSHP $+ $@

$(MAP_OUTPUT_RIVER): $(RIVER_EXTENT) $(RIVER_LINE) mapfile.river.template.map
	mkdir -p `dirname $@`
	./functions.sh map_output_river $(word 1,$+) $(word 2,$+) $@

$(MAP_OUTPUT_VEG): $(VEG_RAST) mapfile.vegetation.template.map 
	mkdir -p `dirname $@`
	./functions.sh map_output_vegetation $< $@

$(VEG_VECT): $(VEG_RAST)
	mkdir -p `dirname $@`
	grass -c $(WORKDIR)/temploc --exec $$PWD/grass.polygonize.sh $< $@
