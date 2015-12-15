#!

if [ "$1" != "" ]; then
	docker stop nginx && docker rm nginx
	docker stop php && docker rm php
	docker run -d --link db --name php quay.io/lendo/sms-service-php-dist:$1-php-qa
	docker run -d -p 80:80 --name nginx --link php -v /root/git/sms-service/docker/vhost.conf:/etc/nginx/conf.d/default.conf --volumes-from php nginx:1.9.4
else
	echo "give me build number"
	break
fi
