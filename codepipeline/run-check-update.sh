#!/bin/bash
shopt -s nullglob
echo `pwd`

DATE=$(git log -p -1 --date=relative | grep '^Date:')
UDATE=$(echo ${DATE} | awk '{print $3}')
echo "DATE: ${DATE}, UDATE: ${UDATE}"

if [[ $UDATE == "seconds"  || $UDATE == "minutes" ]]
then
    # Update to only .json|.yaml|.yml files are verified as part of this step
    # git log -p -1 lists all the checkins in the last git push.
    updated_list=$(git log -p -1 | grep '^diff --git' |awk -F" b/" '{print $NF}' | egrep '.json|.yml|.yaml'$ | egrep -v 'buildspec|cfnnag')
    echo "UPDATED LIST: ${updated_list}"
    for f in ${updated_list}; do
        echo "WORKING ON: $f"
        if [[ $f == templates/ec2* || $f == templates/rds* ]]
        then
            prod_src=$(python codepipeline/get_product_source.py -f ${f})
            echo "Product Source Found: ${prod_src}"
            if [[ $prod_src != "None" ]]
            then
                python codepipeline/update_product_files.py -p $prod_src
            else
                echo "SKIPPING: No source file found for ${f}"
            fi
        elif [[ $f == templates/dev-portfolio* || $f == templates/prod-portfolio* ]]
        then
            echo "${f} is SC Product file, not need of update. Continue to deploy"
        else
            echo "SKIPPING: ${f} is not a supported sc product."
        fi
    done
else
    echo "SKIPPING: Last checkin happened ${DATE}"
fi