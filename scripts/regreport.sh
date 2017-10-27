#!/bin/bash

# This will generate csv report and verify all regular backups in s3://xxxx/
# This will run at 5AM (UTC+8) everyday
# Assuming you've already setup your aws key id and secret access key in your server
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
FILE=/backup/overall/overall_report
FINALREPORT=/backup/report_files/regular/final_report_`date +%Y%m%d`.csv
DOWNLOAD=/backup/downloads/regular
LOG=/backup/logs/regular/report_`date +"%Y%m%d"`.log
YESTERDAY=$(date -d "-1 day" +"%Y-%m-%d")
ARN=arn:aws:sns:ap-northeast-1:xxxxxxxxxxxx:backup-report
SWT=(xxxx xxxxx xxxxx xxxxx xxxxx xxxxx)
SWTCB=(xxxx xxxxx xxxxx xxxxx_)

# for verification of backup files; test if file can be untar and if sql file has completed the dump
function verify() {
	var=$(echo $file | rev | cut -f1 -d "." | rev)
	case $var in
		tgz|gz)
			if [[ $file =~ \.sql ]]; then
				zcat $file | grep "Dump completed" > /dev/null 2>&1
				process
			else
				tar -tf $file > /dev/null	
				process
			fi;;
		xz)	
			if [[ $file =~ \.sql ]]; then
				xzgrep "Dump completed" $file > /dev/null 2>&1
				process
			else
				xz -t $file	
				process
			fi;;
		*)
			echo "`date -u` $i No backup found or file extension not included!"
               		echo $i,"`echo -n $report | awk 'BEGIN{OFS=",";} {print $4,$1}'`,NOK" >> $FINALREPORT
			rm -rf $DOWNLOAD/*
			;;
	esac
}

# will be called by verify() function
function process() {
	if [ $? -eq 0 ]; then
		echo "`date -u` $file Backup file is working."
		echo $i,"`echo -n $report | awk 'BEGIN{OFS=",";} {print $4,$1}'`,OK" >> $FINALREPORT
	else
		echo "`date -u` $file Backup file is not working!"
		echo $i,"`echo -n $report | awk 'BEGIN{OFS=",";} {print $4,$1}'`,NOK" >> $FINALREPORT
	fi
	rm -rf $DOWNLOAD/*
}

# the generation of the whole backup report
function reports {
	echo "service,backup,date,state" >> $FINALREPORT
	for i in ${SWT[*]}
	do
		aws s3 ls --recursive s3://xxxx/ | grep "$i" | grep $YESTERDAY > $FILE
		if [ $? -eq 0 ]; then 
			# since there are some services with multiple backups at different time, this portion will enable to do the verification for each backup
			while read -r report
			do
				# will download the backup copy which will be used for the testing on verify() function
				aws s3 cp s3://xxxx/`echo $report | awk '{print $4}'` $DOWNLOAD > /dev/null 2>&1
				cd $DOWNLOAD
				for file in $DOWNLOAD/*
				do
					verify # this will call the the function verify()
				done
				rm -rf $DOWNLOAD/*
			done < "$FILE"
		else
			echo "`date -u` $i No backup found!"
			echo "$i,N/A,N/A,NOK" >> $FINALREPORT
		fi
	done
}

# verification for xxxx backup (in .bak/.trn format) for MSSQL. If file is existing then backup is successful.
function chatbot {
	for i in ${SWTCB[*]}
	do
        	aws s3 ls --recursive s3://xxxx/ | grep "$i" | grep $YESTERDAY > $FILE
		if [ $? -eq 0 ]; then
			while read -r report
        			do
					echo "`date -u` xxxx backup exists."
					echo $i,"`echo -n $report | awk 'BEGIN{OFS=",";} {print $4,$1}'`,OK" >> $FINALREPORT
			done < "$FILE"
		else
		echo "`date -u` $i No backup found!"
        	        echo "$i,N/A,N/A,NOK" >> $FINALREPORT
        	fi
	done	
}

# if backup report contains NOK which means the validation on one or more backup/s has failed, then it will send email notification.
function sns {
	echo "service,backup,date,state" > $FILE
	grep -q "NOK" $FINALREPORT
	if [ $? -eq 0 ];
	then
		grep -r "NOK" $FINALREPORT >> $FILE
		aws sns publish --topic-arn $ARN --message file://$FILE --subject "[xxx-Report] Backup Verification Failed or No Backup Found on Some Services"
	else
		true
	fi
}

# will log validation result of backups.
function log {
	exec &>> $LOG
}

log
reports
chatbot
sns

