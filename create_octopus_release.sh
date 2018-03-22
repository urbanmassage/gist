set -f

BASE_DIR=$(dirname $0)

zip -r $CIRCLE_PROJECT_REPONAME.${BUILD_NO}.zip $BASE_DIR/deploy.yml
mv $CIRCLE_PROJECT_REPONAME.${BUILD_NO}.zip $BASE_DIR/$CIRCLE_PROJECT_REPONAME.${BUILD_NO}.zip

curl -X POST http://$OCTOPUS_BASE/api/packages/raw -H "X-Octopus-ApiKey:$OCTO_API_KEY" -F "data=@${BASE_DIR}/$CIRCLE_PROJECT_REPONAME.$BUILD_NO.zip"

names=$(curl -s 'http://$OCTOPUS_BASE/api/projects/all' -H "X-Octopus-ApiKey:$OCTO_API_KEY" | jq '.[] | .Name')
ids=$(curl -s 'http://$OCTOPUS_BASE/api/projects/all' -H "X-Octopus-ApiKey:$OCTO_API_KEY" | jq '.[] | .Id')

names="${names//\"}"
ids="${ids//\"}"

namelist=(${names//,/ })
idslist=(${ids//,/ })

for i in ${!namelist[@]}; do
    if [[ ${namelist[$i]} == "$CIRCLE_PROJECT_REPONAME" ]];
    then
        project_id=${idslist[$i]}

        status_code=$(curl --silent --output /dev/stderr --write-out "%{http_code}" -X POST http://$OCTOPUS_BASE/api/releases -H "X-Octopus-ApiKey:${OCTO_API_KEY}" -H "content-type:application/json" -d "{\"ProjectId\":\"${project_id}\", \"Version\":\"${BUILD_NO}\", \"ChannelId\":\"Channels-1\",\"SelectedPackages\": [{\"StepName\": \"Unpack Deployment Assets\",\"ActionName\": \"Unpack Deployment Assets\",\"Version\": \"${BUILD_NO}\"}]}")

        if [ $status_code -ge 300 ];
        then
            exit $status_code
        fi
    fi
done
