#!/usr/bin/env bash

_IMAGE=""
_BUILD="latest"
_WORKDIR=""

_EVENTSTORE_CONTAINER="eventstore"
_ELASTICSEARCH_CONTAINER="elasticsearch"
_NGINX_CONTAINER="nginx"
_PHP_CONTAINER="php"

_STORAGE_DIR="/mnt/sda1/storage"

while [ $# -gt 1 ]
do
key="$1"

case $key in
	-i|--image)
	_IMAGE="$2"
	shift
	;;
	-b|--build)
	_BUILD="$2"
 	shift
	;;
	-w|--workdir)
	_WORKDIR="$2/"
 	shift
	;;
esac
shift # past argument or value
done

checkContainers () {
	RUNNING=$(docker inspect --format="{{ .State.Running }}" $1 2> /dev/null)

	if [ "$RUNNING" != 'true' ]; then
		return 0
	else
		return 1
	fi
}

checkContainers ${_EVENTSTORE_CONTAINER}
if [ $? -eq 0 ]; then 
	echo "Starting ${_EVENTSTORE_CONTAINER} container"
	mkdir -p ${_STORAGE_DIR}/eventstore-data
	mkdir -p ${_STORAGE_DIR}/eventstore-logs
	docker run -d --name ${_EVENTSTORE_CONTAINER} -v ${_STORAGE_DIR}/eventstore-data:/data/db -v ${_STORAGE_DIR}/eventstore-logs:/data/logs tetsuobe/geteventstore:release-v3.5.0
fi
checkContainers ${_EVENTSTORE_CONTAINER}
if [ $? -eq 0 ]; then 
	echo "Container ${_EVENTSTORE_CONTAINER} not running!"
	exit 0
fi

checkContainers ${_ELASTICSEARCH_CONTAINER}
if [ $? -eq 0 ]; then 
	echo "Starting ${_ELASTICSEARCH_CONTAINER} container"
	mkdir -p ${_STORAGE_DIR}/elasticsearch-data
	docker run -d --name ${_ELASTICSEARCH_CONTAINER} -v ${_STORAGE_DIR}/elasticsearch-data:/usr/share/elasticsearch/data elasticsearch
fi
checkContainers ${_ELASTICSEARCH_CONTAINER}
if [ $? -eq 0 ]; then 
	echo "Container ${_ELASTICSEARCH_CONTAINER} not running!"
	exit 0
fi

echo "Deploying build: ${_BUILD}"

if [ "${_IMAGE}" != "" ]; then

	mkdir -p /root/service/docker/

	checkContainers ${_NGINX_CONTAINER}
	if [ $? -eq 1 ]; then
		echo "Cleaning previous NGINEX container"
		docker stop ${_NGINX_CONTAINER} && docker rm ${_NGINX_CONTAINER}
	fi

	checkContainers ${_PHP_CONTAINER}
	if [ $? -eq 1 ]; then
		echo "Cleaning previous PHP container"
		docker stop ${_PHP_CONTAINER} && docker rm ${_PHP_CONTAINER}
	fi

	echo "Creating PHP container"
	docker run -d --link ${_ELASTICSEARCH_CONTAINER} --link ${_EVENTSTORE_CONTAINER} --name ${_PHP_CONTAINER} -v /var/www ${_IMAGE}:${_BUILD}-php-qa

	echo "Creating NGINX container"
	docker cp ${_PHP_CONTAINER}:/var/www/docker/vhost-remote.conf /root/service/docker
	docker run -d -p 80:80 --name ${_NGINX_CONTAINER} --link ${_PHP_CONTAINER} -v /root/service/docker/vhost-remote.conf:/etc/nginx/conf.d/default.conf --volumes-from ${_PHP_CONTAINER} nginx:1.9.12

	echo "Setup environment"
	docker exec ${_PHP_CONTAINER} bash -c "sh ${_WORKDIR}bin/startup.sh --workdir ${_WORKDIR} > /dev/null 2>&1"

	exit 0
else
	echo "Please provide image name"
	break
fi