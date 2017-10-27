#!/bin/bash

REG=/backup/report_files/regular
IRREG=/backup/report_files/irregular
LOGREG=/backup/logs/regular
LOGIRREG=/backup/logs/irregular

# compress reports and logs created for the last 30 days
function regular {
	cd $REG
	find final_report*.csv -mmin +60 | xargs tar -czf $REG/final_report_`date +"%Y%m"`.csv.tgz
	find final_report*.csv -mmin +60 -exec rm {} \;
	cd $LOGREG
	find report*.log -mmin +60 | xargs tar -czf $LOGREG/report_`date +"%Y%m"`.log.tgz
	find report*.log -mmin +60 -exec rm {} \;
}

function irregular {
	cd $IRREG
	find final_report_irreg*.csv -mmin +60 | xargs tar -czf $IRREG/final_report_irreg_`date +"%Y%m"`.csv.tgz
	find final_report_irreg*.csv -mmin +60 -exec rm {} \;
	cd $LOGIRREG
	find report*.log -mmin +60 | xargs tar -czf $LOGIRREG/report_irreg_`date +"%Y%m"`.log.tgz
	find report*.log -mmin +60 -exec rm {} \;
}

# deletes 2 months old compressed files
function delete {
	cd $REG
	find final_report*.csv.tgz -mtime +60 -exec rm {} \;

	cd $IRREG
	find final_report_irreg*.csv.tgz -mtime +60 -exec rm {} \;

	cd $LOGREG
	find report*.log.tgz -mtime +60 -exec rm {} \;

	cd $LOGIRREG 
	find report*.log.tgz -mtime +60 -exec rm {} \;
}

regular
irregular
delete

