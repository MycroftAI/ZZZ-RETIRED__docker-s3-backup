#!/usr/bin/env bash

# you will need these environment vars

#s3fs
#access_key=""
#secret_key=""
#s3_bucket=""
#s3_bucket_path="

# backup
backup_dir="/volume-mount"
#backup_name

function create_s3fs_password_file () {
	echo "${access_key}:${secret_key}" > ~/.passwd-s3fs
	chmod 600 ~/.passwd-s3fs
}

function mount_s3_bucket {
	s3fs -ouid=0,gid=0,noatime,allow_other,mp_umask=022 ${s3_bucket}:/ /s3-mount
	mkdir -p /s3-mount/${s3_bucket_path}
}

function unmount_s3_bucket {
	fusermount --unmount /s3-mount
}

function backup_operation {
        export timestamp=$(date +%s)
	export date_today=$(date +%m_%d_%y)
        mkdir -p /s3-mount/${s3_bucket_path}/tar-incremental/${date_today}/
	tar_command='tar
        --no-check-device
        --owner=0
        --group=0	
	--exclude='"${backup_dir}"'/sys 
	--exclude='"${backup_dir}"'/proc 
	--exclude='"${backup_dir}"'/dev 
	--exclude='"${backup_dir}"'/media 
	--exclude='"${backup_dir}"'/run 
	--exclude='"${backup_dir}"'/lost+found 
	--exclude='"${backup_dir}"'/boot 
	--exclude='"${backup_dir}"'/lib 
	--exclude='"${backup_dir}"'/bin 
	--exclude='"${backup_dir}"'/sbin 
	--exclude='"${backup_dir}"'/var/lib/docker 
	--exclude='"${backup_dir}"'/usr/ 
	--exclude='"${backup_dir}"'/var/opt/digitalocean/do-agent/tufLocalStore 
	--exclude='"${backup_dir}"'/var/log 
	--exclude='"${backup_dir}"'/var/lib/sss 
	--exclude='"${backup_dir}"'/var/lib/ntp 
	--exclude='"${backup_dir}"'/var/lib/lxcfs 
	--exclude='"${backup_dir}"'/var/log 
	--exclude='"${backup_dir}"'/usr/src
        --exclude='"${backup_dir}"'/var/lib/fail2ban
	--exclude='"${backup_dir}"'/var/lib/lxd
	--exclude='"${backup_dir}"'/var/discourse/shared/standalone/postgres_run
	--listed-incremental=/s3-mount/'${s3_bucket_path}'/tar-incremental/'${date_today}'/usr.snar 
	-I pxz
	-c '"${backup_dir}"' -f /s3-mount/'${s3_bucket_path}'/tar-incremental/'${date_today}'/archive-'${timestamp}'.tar.xz'
	echo $tar_command
	$tar_command 2>&1 | tee > /tmp/tar_log ; exit_state=${PIPESTATUS[0]}
	if [[ (${exit_state} == 0) ]]
	then
		export exit_status=0
		echo "No errors detected, operation succesful"
		export EMAIL_SUBJECT="Backup to s3 succesful for host: '"${s3_bucket_path}"'"
		export EMAIL_BODY=${EMAIL_SUBJECT}
		curl -i -X POST -d 'payload={"text": ":white_check_mark: Backup to s3 succesful for host: '"${s3_bucket_path}"'"}' https://chat.mycroft.ai/hooks/bbutxxwu8fgm8cqa6wh6eaq7ze
		$(python mailer.py)
		 curl -H "Content-Type: application/json" -X POST -d '{"hostname":"'${s3_bucket_path}'", "desc":"description coming soon!", "time": "'${timestamp}'", "success":"0"}' http://138.197.101.122:9898/nodes
	else
		export exit_status=${exit_state}
		echo "Error detected, operation exited: "${exit_state}
		curl -i -X POST -d 'payload={"text": "@here :x: Backup to s3 failed for host: '"${s3_bucket_path}"' with exit status '"${exit_state}"'" }' https://chat.mycroft.ai/hooks/bbutxxwu8fgm8cqa6wh6eaq7ze
		curl -H "Content-Type: application/json" -X POST -d '{"hostname":"'${s3_bucket_path}'", "desc":"description coming soon!", "time": "'${timestamp}'", "success":"1"}' http://138.197.101.122:9898/nodes
	fi
	echo ${s3_bucket_path}" " ${date_today}" " ${timestamp}" "${exit_status} >> /s3-mount/${s3_bucket_path}/tar-incremental/${date_today}/${date_today}-${s3_bucket_path}.log

}

function log_add_self_to_host_list {
	# something went wrong here
	#cat /s3-mount/backup-hosts > temp-hosts
	#sed -i '/'${s3_bucket_path}'/d' temp-hosts
	#echo ${s3_bucket_path} >> temp-hosts
	#cat temp-hosts > s3-mount/backup-hosts
	mkdir -p /s3-mount/backup-hosts
	if [ ! -f /s3-mount/backup-hosts/${s3_bucket_path} ]; then
		touch /s3-mount/backup-hosts/${s3_bucket_path}
	fi
}

echo ${s3_bucket_path}
echo ${backup_dir}
source ./sendgrid.env
create_s3fs_password_file
mount_s3_bucket
log_add_self_to_host_list
backup_operation

if [[ !(${exit_status} == 0) ]];
then
	cat /tmp/tar_log  > /s3-mount/${s3_bucket_path}/tar-incremental/${date_today}/archive-${timestamp}.error.log
	export EMAIL_SUBJECT="Backup to s3 failed for host: '"${s3_bucket_path}"' with exit status '"${exit_state}"'"
	export EMAIL_BODY=$(cat /s3-mount/${s3_bucket_path}/tar-incremental/${date_today}/archive-${timestamp}.error.log )
	$(python mailer.py)
fi


echo "sleeping for 10s" && sleep 10
unmount_s3_bucket
