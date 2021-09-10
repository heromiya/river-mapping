#! /bin/bash

rsync -avP ndwi_river.extract.shp.d/median/* 21910_delivery/Extent/
rsync -avP ndwi_river.extract.line.shp.d/*   21910_delivery/Line/
