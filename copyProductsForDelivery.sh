#! /bin/bash
#HOST=glodal.dynns.com
HOST=192.168.0.64
BASEDIR=Jamuna-Padoma_River_Extent.d

#owncloudcmd -n monthly_mosaic/ "http://$HOST:8081/owncloud/remote.php/webdav/BGD River Mapping/211129 monthly mosaic"
#owncloudcmd -n /mnt/btrfs/Landsat-C2/tar       "http://$HOST/owncloud/remote.php/webdav/BGD River Mapping/Landsat-C2"

#owncloudcmd -n vegetation                      "http://$HOST/owncloud/remote.php/webdav/BGD River Mapping/Clustering for Vegetation Mapping"
owncloudcmd -n $BASEDIR/ndwi_river.extract.shp.d/median     "http://$HOST/owncloud/remote.php/webdav/BGD River Mapping/210910 River mapping results for delivery/Extent"
#owncloudcmd -n $BASEDIR/ndwi_river.extract.line.shp.mode9.d "http://$HOST/owncloud/remote.php/webdav/BGD River Mapping/210910 River mapping results for delivery/Line"
#owncloudcmd -n $BASEDIR/map_output.d                        "http://$HOST/owncloud/remote.php/webdav/BGD River Mapping/210910 River mapping results for delivery/Map"
#owncloudcmd -n $BASEDIR/ndwi_river.extract.line.dist.vect.d "http://$HOST/owncloud/remote.php/webdav/BGD River Mapping/220208 River widths analysis"

#owncloudcmd -n $BASEDIR/ndwi_river.major_stream.d       "http://$HOST/owncloud/remote.php/webdav/BGD River Mapping/211103 Major stream mapping"


#owncloudcmd -n BGD-broad_extent/ndwi_river.extract.shp.d/median/quarterly/      "http://$HOST/owncloud/remote.php/webdav/BGD River Mapping/211121 Broad extent river mapping"
#owncloudcmd -n BGD-broad_extent/ndwi_river.shp.d/                               "http://$HOST/owncloud/remote.php/webdav/BGD River Mapping/211130 Broad extent river mapping deliverables/Extent"
#owncloudcmd -n BGD-broad_extent/ndwi_river.extract.line.shp.mode9.d/            "http://$HOST/owncloud/remote.php/webdav/BGD River Mapping/211130 Broad extent river mapping deliverables/Line"
