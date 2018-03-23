set -f

BASE_DIR=$(dirname $0)
RELEASE_DIR=$BASE_DIR/deploy

zip -r $CIRCLE_PROJECT_REPONAME.${BUILD_NO}.zip $RELEASE_DIR/deploy.yml
mv $BASE_DIR/$CIRCLE_PROJECT_REPONAME.${BUILD_NO}.zip $RELEASE_DIR/$CIRCLE_PROJECT_REPONAME.${BUILD_NO}.zip

curl -X POST $OCTOPUS_BASE/api/packages/raw -H "X-Octopus-ApiKey:$OCTO_API_KEY" -F "data=@${RELEASE_DIR}/$CIRCLE_PROJECT_REPONAME.$BUILD_NO.zip"

names=$(curl -s '$OCTOPUS_BASE/api/projects/all' -H "X-Octopus-ApiKey:$OCTO_API_KEY" | jq '.[] | .Name')
ids=$(curl -s '$OCTOPUS_BASE/api/projects/all' -H "X-Octopus-ApiKey:$OCTO_API_KEY" | jq '.[] | .Id')

names="${names//\"}"
ids="${ids//\"}"

namelist=(${names//,/ })
idslist=(${ids//,/ })

for i in ${!namelist[@]}; do
    echo ${namelist[$i]}
    echo ${idslist[$i]}
    if [[ ${namelist[$i]} == "$CIRCLE_PROJECT_REPONAME" ]];
    then
        project_id=${idslist[$i]}

        status_code=$(curl --silent --output /dev/stderr --write-out "%{http_code}" -X POST $OCTOPUS_BASE/api/releases -H "X-Octopus-ApiKey:${OCTO_API_KEY}" -H "content-type:application/json" -d "{\"ProjectId\":\"${project_id}\", \"Version\":\"${BUILD_NO}\", \"ChannelId\":\"Channels-1\",\"SelectedPackages\": [{\"StepName\": \"Unpack Deployment Assets\",\"ActionName\": \"Unpack Deployment Assets\",\"Version\": \"${BUILD_NO}\"}]}")

        if [ $status_code -ge 300 ];
        then
            exit $status_code
        fi
        break
    fi
done
