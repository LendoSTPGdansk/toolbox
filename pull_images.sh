#!/bin/bash

if [ "$1" != "" ]; then
    	docker pull quay.io/lendo/sms-service-php-dist:$1-php-qa
else
    echo "no input argument"
    break
fi

