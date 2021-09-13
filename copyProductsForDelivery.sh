#! /bin/bash
HOST=192.168.0.3

owncloudcmd -u heromiya -p K@shiwa454 vegetation "http://$HOST:8081/owncloud/remote.php/webdav/BGD River Mapping/Clustering for Vegetation Mapping"
owncloudcmd -u heromiya -p K@shiwa454 ndwi_river.extract.shp.d/median "http://$HOST:8081/owncloud/remote.php/webdav/BGD River Mapping/210910 River mapping results for delivery/Extent"
owncloudcmd -u heromiya -p K@shiwa454 ndwi_river.extract.line.shp.d   "http://$HOST:8081/owncloud/remote.php/webdav/BGD River Mapping/210910 River mapping results for delivery/Line"
owncloudcmd -u heromiya -p K@shiwa454 map_output.d   "http://$HOST:8081/owncloud/remote.php/webdav/BGD River Mapping/210910 River mapping results for delivery/Map"
owncloudcmd -u heromiya -p K@shiwa454 /mnt/btrfs/Landsat-C2/tar "http://$HOST:8081/owncloud/remote.php/webdav/BGD River Mapping/Landsat-C2"

#owncloudcmd -u heromiya -p K@shiwa454 --davpath "remote.php/dav/files/heromiya/BGD River Mapping/210910 River mapping results for delivery/Extent" ndwi_river.extract.shp.d/median  "http://192.168.0.3:8081/owncloud/"
#http://192.168.0.3:8081/owncloud/remote.php/dav//
#--davpath "http://$HOST:8081/owncloud/remote.php/dav/files/heromiya/BGD River Mapping/210910 River mapping results for delivery/Extent"
#rsync -avLP --inplace ndwi_river.extract.shp.d/median/* 21910_delivery/Extent/
#rsync -avLP --inplace ndwi_river.extract.line.shp.d/*   21910_delivery/Line/

#owncloudcmd -u heromiya -p K@shiwa454  ndwi_river.extract.shp.d/median "http://192.168.0.3:8081/owncloud/index.php/apps/files/?dir=/BGD%20River%20Mapping/210910%20River%20mapping%20results%20for%20delivery/Extent&fileid=549398"
#owncloudcmd -u heromiya -p K@shiwa454  ndwi_river.extract.shp.d/median "http://192.168.0.3:8081/owncloud/index.php/f/549398"
