#! /bin/bash
while [ 1 = 1 ]; do
    owncloudcmd -u heromiya -p K@shiwa454 --exclude sync.sh . "http://hawaii.csis.u-tokyo.ac.jp:8081/owncloud/remote.php/webdav/BGD%20River%20Mapping/mapping-codes-results"
    sleep 60
done
