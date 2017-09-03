#!/usr/bin/env bash

# you will need these vars
#export access_key=""
#export secret_key=""
#export s3_bucket=""
#export docker_image=""

# test for docker engine
if [ -f /usr/bin/docker ];then
	echo "docker exists"
else curl -sSL https://get.docker.com/ | sh

fi

# create docker-s3-tar-incremental.sh script to kick off the backup container
touch /docker-s3-tar-incremental.sh
echo """#!/usr/bin/env bash
docker pull '${docker_image}'
docker stop docker-s3-backup && docker rm docker-s3-backup
docker run -d --name=docker-s3-backup -e access_key='${access_key}' --memory 256m  --cpus=1 -e secret_key='${secret_key}' -e s3_bucket='${s3_bucket}' -e s3_bucket_path=${HOSTNAME} --privileged -v /:/volume-mount/ '${docker_image}' """ > /docker-s3-tar-incremental.sh

# make the script executable
chmod +x /docker-s3-tar-incremental.sh

# do an inital run
if [ -f /docker-s3-first-run ];then 
	echo "we have already run once"
else
	pushd /
	./docker-s3-tar-incremental.sh; touch /docker-s3-first-run
	popd
fi
#write out current crontab
crontab -l > mycron
#echo new cron into cron file
sed -i '/docker-s3-tar-incremental/d' mycron
echo "0 */12 * * * /docker-s3-tar-incremental.sh" >> mycron
#install new cron file
crontab mycron
rm mycron
