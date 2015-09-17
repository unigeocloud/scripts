#!/bin/bash

INV_PATH=/tmp/inventory
EXIST_INV_PATH=${HOME}/seiscomp3/etc/inventory
KEY_PATH=${HOME}/seiscomp3/etc/key
STATIONS=/tmp/stations
GIT_REPO='https://github.com/unigeocloud/inventory/trunk'
[[ -d ${INV_PATH} ]] || mkdir -p ${INV_PATH}
[[ -f ${STATIONS} ]] && LINE=$(cat ${STATIONS}) || echo "Station file \"stations\" does not exist!";
yum install svn -y;
add(){
for STATION in ${LINE}; do
	NETWORK_NAME=$(echo ${STATION} | awk -F_ '{print $1}');
	svn export ${GIT_REPO}/${NETWORK_NAME}/${STATION}.StationXML ${INV_PATH}/${STATION}.StationXML;
	seiscomp exec import_inv fdsnxml ${INV_PATH}/${STATION}.StationXML;
	echo '# Binding references
    scautopick:autopick
    seedlink:seedlink' > ${KEY_PATH}/station_${STATION};
done;
seiscomp update-config inventory;
}

del_all(){
	rm ${EXIST_INV_PATH}/* 2>/dev/null
	RETVAL=$?
	echo
	[ $RETVAL = 0 ] && echo "Stations deleted" || echo "There're no stations to be deleted"
	echo
	seiscomp update-config inventory;
}
seiscomp stop;
del_all;
add;
seiscomp update-config;
seiscomp restart;

