#! /home/heromiya/miniconda3/bin/python

import rasterio
from skimage.morphology import medial_axis, skeletonize
import sys

infile = sys.argv[1]
outfile = sys.argv[2]

img = rasterio.open(infile)
array = img.read(1)
skeleton = skeletonize(array, method='lee')
#skeleton = medial_axis(array)

new_dataset = rasterio.open(
    outfile,
    'w',
    driver='GTiff',
    height=array.shape[0],
    width=array.shape[1],
    count=1,
    dtype=rasterio.uint8,
    crs=img.read_crs(),
    compression='Deflate',
    transform=img.transform,
)

new_dataset.write(skeleton, 1)
new_dataset.close()
