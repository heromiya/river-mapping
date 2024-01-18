export TARGET_EXTENT=Jamuna-Padoma_River_Extent.kmz
export OUTPUT_BASEDIR=Jamuna-Padoma_River_Extent.d

export NDWI_ONLY=FALSE
export CENTERLINE_THRESHOLD=10
export MODE_FILTER_SIZE=9

export N_JOBS=10
export GRASS_OPT="--overwrite --quiet"
export CUDA_VISIBLE_DEVICES=0

#export INPUTS="$(find monthly_mosaic/ -type f -regex '.*median.*tif$' | grep $(for i in {1..12}; do printf ' -e -%02d-%02d-' $i $i; done) | sort)"
export INPUTS_LIST=$(mktemp)
#find monthly_mosaic/ -type f -regex '.*median.*tif$' | grep $(for i in {1..12}; do printf ' -e -%02d-%02d-' $i $i; done) | sort > $INPUTS_LIST
find monthly_mosaic/ -type f -regex '.*median.*tif$' | grep quarterly | grep 2022-01-03 | sort > $INPUTS_LIST
#find monthly_mosaic/ -type f -regex '.*median.*tif$' | grep monthly | sort > $INPUTS_LIST
