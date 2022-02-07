#! /home/heromiya/miniconda3/bin/python

import rasterio
from skimage.morphology import medial_axis, skeletonize
import sys

infile = sys.argv[1]
mode = sys.argv[2]
outfile = sys.argv[3]

img = rasterio.open(infile)
array = img.read(1)
if mode == 'skel':
#    out = skeletonize(array, method='lee')
    out = medial_axis(array, return_distance=False)
if mode == 'dist':
    skel, dist = medial_axis(array, return_distance=True)
    out = dist * skel

outds = rasterio.open(
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

outds.write(out, 1)
outds.close()
