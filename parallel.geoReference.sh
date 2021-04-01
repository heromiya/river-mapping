#! /bin/bash

#$ -cwd
#$ -o qsub_paralell.geoReference.log
#$ -l q_core=2
#$ -l h_rt=00:30:00
#$ -N river-mapping
#$ -j y
#$ -m abe
#$ -M heromiya@hotmail.com


. /etc/profile.d/modules.sh
module load intel/19.0.0.117 cuda/10.1.105 nccl/2.4.2 cudnn/7.6
#tensorflow/1.12.0
#module load intel cuda/9.0.176 nccl/2.2.13 cudnn/7.1 tensorflow/1.9.0
#. /home/7/17IA0902/anaconda3/etc/profile.d/conda.sh

export PATH=$PATH:/home/7/17IA0902/miniconda3/bin
export LD_LIBRARY_PATH=/home/7/17IA0902/miniconda3/lib:/home/7/17IA0902/miniconda3/lib64:/apps/t3/sles12sp2/cuda/10.1.105/lib64:/apps/t3/sles12sp2/free/cudnn/7.6/cuda/10.1/lib64:$LD_LIBRARY_PATH 

function geoRef {
    INPUT=$1
    REF=src/mosaic_auto/$(basename $INPUT | sed 's/\([0-9-]\{7\}\).*/\1-auto/g').tif
    OUTVRT=vrt/$(basename $REF).vrt
    OUTSHP=river.shp.d/$(basename $REF).shp
    #./geoReference.sh $INPUT $REF $OUTVRT $OUTSHP
    UL=($(gdalinfo $REF -json | jq .cornerCoordinates.upperLeft | tr -d '[],'))
    LR=($(gdalinfo $REF -json | jq .cornerCoordinates.lowerRight| tr -d '[],'))

    gdal_translate -of VRT -a_srs "EPSG:32646" -a_nodata 0 -a_ullr ${UL[0]} ${UL[1]} ${LR[0]} ${LR[1]} $INPUT $OUTVRT
    gdal_polygonize.py -f "ESRI Shapefile" $OUTVRT $OUTSHP

}
export -f geoRef

parallel geoRef ::: $(find result_mosaic_auto_pri_1_river/area-binary/ -type f -regex ".*tif")
#for INPUT in $(find result_mosaic_auto_pri_1_river/ -type f -regex ".*tif"); do geoRef $INPUT; done
