#! /bin/bash

SELECTED="1976-01-auto_area_segmap_FPN_epoch_400_Mar01_14_21
1978-12-auto_area_segmap_FPN_epoch_400_Mar01_14_21
1972-11-auto_area_segmap_FPN_epoch_400_Mar01_14_21
1973-02-auto_area_segmap_FPN_epoch_400_Mar01_14_21
1979-03-auto_area_segmap_FPN_epoch_400_Mar01_14_21
1975-12-auto_area_segmap_FPN_epoch_400_Mar01_14_21
1978-02-auto_area_segmap_FPN_epoch_400_Mar01_14_21
1976-12-auto_area_segmap_FPN_epoch_400_Mar01_14_21
1975-11-auto_area_segmap_FPN_epoch_400_Mar01_14_21
1979-02-auto_area_segmap_FPN_epoch_400_Mar01_14_21
1977-02-auto_area_segmap_FPN_epoch_400_Mar01_14_21"

mkdir -p area-binary.shp.d/

for INPUT in $SELECTED; do
    gdalbuildvrt -q -overwrite -srcnodata 0 result_mosaic_auto_pri_1_river/area-binary/$INPUT.vrt result_mosaic_auto_pri_1_river/area-binary/$INPUT.tif 
    gdal_polygonize.py -q result_mosaic_auto_pri_1_river/area-binary/$INPUT.vrt -f "ESRI Shapefile" area-binary.shp.d/$INPUT.shp
done

exit 0
