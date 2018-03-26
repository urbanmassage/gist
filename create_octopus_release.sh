set -f

BASE_DIR=$(dirname $0)
RELEASE_DIR="${BASE_DIR}/deploy"
OCTOPUS_PROJECTS_URL="${OCTOPUS_BASE}/api/projects/all"

PROJECT_NAME="${CIRCLE_PROJECT_REPONAME}.${BUILD_NO}"
ZIP_FILE="${PROJECT_NAME}.zip"

zip -r "${BASE_DIR}/${ZIP_FILE}" "${RELEASE_DIR}/deploy.yml"
mv "${BASE_DIR}/${ZIP_FILE}" "${RELEASE_DIR}/${ZIP_FILE}"

post_status_code=$(curl -s --output /dev/stderr --write-out "%{http_code}" -X POST ${OCTOPUS_BASE}/api/packages/raw -H "X-Octopus-ApiKey:${OCTO_API_KEY}" -F "data=@${RELEASE_DIR}/${ZIP_FILE}")

if [ ${post_status_code} -ge 300 ];
then
    exit ${post_status_code};
fi

names=$(curl -s ${OCTOPUS_PROJECTS_URL} -H "X-Octopus-ApiKey:${OCTO_API_KEY}" | jq '.[] | .Name')
ids=$(curl -s ${OCTOPUS_PROJECTS_URL} -H "X-Octopus-ApiKey:${OCTO_API_KEY}" | jq '.[] | .Id')

names="${names//\"}"
ids="${ids//\"}"

namelist=(${names//,/ })
idslist=(${ids//,/ })

for i in ${!namelist[@]}; do
    if [[ ${namelist[$i]} == "${CIRCLE_PROJECT_REPONAME}" ]];
    then
        project_id=${idslist[$i]}
        channel_id=$(curl -s ${OCTOPUS_BASE}/api/projects/${project_id}/channels?take=1 -H "X-Octopus-ApiKey:${OCTO_API_KEY}" | jq '.Items[0].Id')
        channel_id="${channel_id//\"}"
        branch_name="${CIRCLE_BRANCH//_/\_}"
        status_code=$(curl --silent --output /dev/stderr --write-out "%{http_code}" -X POST ${OCTOPUS_BASE}/api/releases -H "X-Octopus-ApiKey:${OCTO_API_KEY}" -H "content-type:application/json" -d "{\"ProjectId\":\"${project_id}\", \"ReleaseNotes\":\"Branch: ${branch_name}\", \"Version\":\"${BUILD_NO}\", \"ChannelId\":\"${channel_id}\",\"SelectedPackages\": [{\"StepName\": \"Unpack Deployment Assets\",\"ActionName\": \"Unpack Deployment Assets\",\"Version\": \"${BUILD_NO}\"}]}")
        if [ ${status_code} -ge 300 ];
        then
            exit ${status_code}
        fi
        break
    fi
done
