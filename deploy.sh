#!/usr/bin/env bash

_IMAGE=""
_BUILD="latest"
_WORKDIR=""

_EVENTSTORAGE_ADDRESS="139.59.130.119"

_PROJECTIONSTORAGE_CONTAINER="projectionstorage"
_NGINX_CONTAINER="nginx"
_PHP_CONTAINER="php"

_PROJECTIONSTORAGE_IMAGE="elasticsearch"

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

checkContainers ${_PROJECTIONSTORAGE_CONTAINER}
if [ $? -eq 0 ]; then 
	echo "Starting ${_ELASTICSEARCH_IMAGE} as ProjectionStorage container"
	mkdir -p ${_STORAGE_DIR}/${_PROJECTIONSTORAGE_CONTAINER}
	docker run -d --name ${_PROJECTIONSTORAGE_CONTAINER} -v ${_STORAGE_DIR}/${_PROJECTIONSTORAGE_CONTAINER}:/usr/share/elasticsearch/data ${_PROJECTIONSTORAGE_IMAGE}
fi
checkContainers ${_PROJECTIONSTORAGE_CONTAINER}
if [ $? -eq 0 ]; then 
	echo "ProjecitonStorage not running!"
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
	docker run -d --link ${_PROJECTIONSTORAGE_CONTAINER} --name ${_PHP_CONTAINER} -v /var/www ${_IMAGE}:${_BUILD}-php-qa

	echo "Creating NGINX container"
	docker cp ${_PHP_CONTAINER}:/var/www/docker/vhost-remote.conf /root/service/docker
	docker run -d -p 80:80 --name ${_NGINX_CONTAINER} --link ${_PHP_CONTAINER} -v /root/service/docker/vhost-remote.conf:/etc/nginx/conf.d/default.conf --volumes-from ${_PHP_CONTAINER} nginx:1.9.12

    echo "Add eventstorage to hosts"
    docker exec ${_PHP_CONTAINER} bash -c "echo '${_EVENTSTORAGE_ADDRESS} eventstorage' >> /etc/hosts"

	echo "Setup environment"
	docker exec ${_PHP_CONTAINER} bash -c "sh ${_WORKDIR}bin/startup.sh --workdir ${_WORKDIR} > /dev/null 2>&1"

	exit 0
else
	echo "Please provide image name"
	break
fi