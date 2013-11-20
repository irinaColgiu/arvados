#!/bin/sh


echo "Starting documentation server: http://localhost:9898"
docker run -d -i -t -p 9898:80 arvados/docserver

echo "Starting sso server:     https://localhost:9901"
docker run -d -i -t -p 9901:443 -name sso_server arvados/sso

echo "Starting api server:     https://localhost:9900"
docker run -d -i -t -p 9900:443 -name api_server -link sso_server:sso arvados/api

echo "Starting workbench server:     http://localhost:9899"
docker run -d -i -t -p 9899:80 -link api_server:api arvados/workbench

echo "Starting keep server:        http://localhost:25107"

# Mount a keep volume if we don't already have one
keepvolume=""
for mountpoint in $(cut -d ' ' -f 2 /proc/mounts)
do
    if [ -d "$mountpoint/keep" ]
    then
	keepvolume=$mountpoint
    fi
done

if [ ! "$keepvolume" ]
then
    keepvolume=$(mktemp -d)
    echo "mounting 512M tmpfs keep volume in $keepvolume"
    sudo mount -t tmpfs -o size=512M tmpfs $keepvolume
    mkdir $keepvolume/keep
fi

docker run -d -i -t -p 25107:25107 -v $keepvolume:/dev/keep-0 arvados/warehouse