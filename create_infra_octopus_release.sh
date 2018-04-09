set -f

BASE_DIR=$(dirname $0)

MODULES_DIR="${BASE_DIR}/modules"
INFRA_DIR="${BASE_DIR}/${INFRA_TYPE}"
RELEASE_DIR="${BASE_DIR}/deploy"

OCTOPUS_FULL_BASE="https://${OCTOPUS_BASE}/api"
OCTOPUS_PROJECTS_URL="${OCTOPUS_FULL_BASE}/projects/all"

ZIP_FILE="${INFRA_TYPE}.zip"

zip -r "${BASE_DIR}/${ZIP_FILE}" "${MODULES_DIR}" "${INFRA_DIR}"
mv "${BASE_DIR}/${ZIP_FILE}" "${RELEASE_DIR}/${ZIP_FILE}"

post_status_code=$(curl --silent --output /dev/stderr --write-out "%{http_code}" -X POST ${OCTOPUS_FULL_BASE}/packages/raw -H "X-Octopus-ApiKey:${OCTO_API_KEY}" -F "data=@${RELEASE_DIR}/${ZIP_FILE}")

if [ ${post_status_code} -ge 300 ];
then
    exit ${post_status_code};
fi

names=$(curl --silent ${OCTOPUS_PROJECTS_URL} -H "X-Octopus-ApiKey:${OCTO_API_KEY}" | jq '.[] | .Name')
ids=$(curl --silent ${OCTOPUS_PROJECTS_URL} -H "X-Octopus-ApiKey:${OCTO_API_KEY}" | jq '.[] | .Id')

names="${names//\"}"
ids="${ids//\"}"

namelist=(${names//,/ })
idslist=(${ids//,/ })

for i in ${!namelist[@]}; do
    if [[ ${namelist[$i]} == "${INFRA_TYPE}" ]];
    then
        project_id=${idslist[$i]}
        channel_id=$(curl -s ${OCTOPUS_FULL_BASE}/projects/${project_id}/channels?take=1 -H "X-Octopus-ApiKey:${OCTO_API_KEY}" | jq '.Items[0].Id')
        channel_id="${channel_id//\"}"
        
        branch_name="${CIRCLE_BRANCH//_/-}"

        post_json="{\"ProjectId\":\"${project_id}\", \"ReleaseNotes\":\"Branch: ${branch_name}\", \"Version\":\"${BUILD_NO}\", \"ChannelId\":\"${channel_id}\",\"SelectedPackages\": [{\"StepName\": \"Unpack Deployment Assets\",\"ActionName\": \"Unpack Deployment Assets\",\"Version\": \"${BUILD_NO}\"}]}"       
        status_code=$(curl --silent --output /dev/stderr --write-out "%{http_code}" -X POST ${OCTOPUS_FULL_BASE}/releases -H "X-Octopus-ApiKey:${OCTO_API_KEY}" -H "content-type:application/json" -d "${post_json}")
        if [ ${status_code} -ge 300 ];
        then
            exit ${status_code}
        fi
        break
    fi
done
