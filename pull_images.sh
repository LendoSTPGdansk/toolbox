#!/usr/bin/env bash

_IMAGE=""
_BUILD="latest"

while [ $# -gt 1 ]
do
key="$1"

case $key in
	-i|--image)
	_IMAGE="$2"
	shift
	;;
	-b|--build)
	_BUILD="$2-php-qa"
 	shift
	;;
esac
shift # past argument or value
done

if [ "${_IMAGE}" != "" ]; then
    	docker pull ${_IMAGE}:${_BUILD}
else
    echo "no input argument"
    break
fi
