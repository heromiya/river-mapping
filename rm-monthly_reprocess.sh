#! /bin/bash

IFS='
'
for ARGS in $(cat monthly_reprocess.lst); do
    YEAR=$(echo $ARGS | cut -f 1)
    MONTH=$(printf %02d $(echo $ARGS | cut -f 2))
    #rm monthly_mosaic/cloudfree-median.tif.d/monthly/$YEAR-$MONTH-$MONTH-cloudfree-median.tif*
    rm Jamuna-Padoma_River_Extent.d/ndwi_river.rast.d/$YEAR-$MONTH-$MONTH-cloudfree-median.tif.nwdi_river.*
done
