#!/bin/bash
shopt -s nullglob
echo `pwd`
ls -ltra *
#mkdir templates
#echo $?
#ls -ltrd
#cp {ec2,vpc}/*.{json,yml} templates/
#cp codepipeline/*.json templates/
# sleep 60

DATE=$(git log -p -1 --date=relative | grep '^Date:')
UDATE=$(echo ${DATE} | awk '{print $3}')
echo "DATE: ${DATE}, UDATE: ${UDATE}"
UDATE=hours

if [[ $UDATE == "seconds"  || $UDATE == "minutes" ]]
then
    updated_list=$(git log -p -1 | grep '^diff --git' |awk -F" b/" '{print $NF}' | egrep '.json|.yml|.yaml'$)
    echo "UPDATED LIST: ${updated_list}"
    for f in ${updated_list}; do
        echo "WORKING ON: $f"
        if cfn_nag_scan --input-path "$f" --blacklist-path ./codepipeline/blacklist-cfnnag.yml; then
            echo "$f PASSED"
        else
            echo "$f FAILED"
            touch FAILED
        fi
    done

    if [ -e FAILED ]; then
      echo cfn-nag FAILED at least once!
      exit 1
    else
      echo cfn-nag PASSED on all files!
      exit 0
    fi

else
    echo "SKIPPING: Last checkin happend ${DATE} ago"
fi