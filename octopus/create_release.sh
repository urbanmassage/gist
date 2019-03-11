set -f

BASE_DIR=$(dirname $0)

RELEASE_DIR="${BASE_DIR}/deploy"
OCTOPUS_FULL_BASE="https://${OCTOPUS_BASE}/api"
OCTOPUS_PROJECTS_URL="${OCTOPUS_FULL_BASE}/projects/all"

CURRENT_BUILD_NO=$1
CURRENT_PROJECT_NAME=$2
CURRENT_BRANCH_NAME="${3//_/-}"
CHANNEL=$4

DEFAULT_PACKAGE_STEP_NAME="Unpack Deployment Assets"

PROJECT_NAME="${CURRENT_PROJECT_NAME}.${CURRENT_BUILD_NO}"
ZIP_FILE="${PROJECT_NAME}.zip"

names=$(curl --silent ${OCTOPUS_PROJECTS_URL} -H "X-Octopus-ApiKey:${OCTO_API_KEY}" | jq '.[] | .Name')
ids=$(curl --silent ${OCTOPUS_PROJECTS_URL} -H "X-Octopus-ApiKey:${OCTO_API_KEY}" | jq '.[] | .Id')

names="${names//\"}"
ids="${ids//\"}"

namelist=(${names//,/ })
idslist=(${ids//,/ })

for i in ${!namelist[@]}; do
    if [[ ${namelist[$i]} == "${CURRENT_PROJECT_NAME}" ]];
    then
        project_id=${idslist[$i]}
        if [ -z "$CHANNEL" ]; 
        then
            channel_id=$(curl -s ${OCTOPUS_FULL_BASE}/projects/${project_id}/channels?take=1 -H "X-Octopus-ApiKey:${OCTO_API_KEY}" | jq '.Items[0].Id')
            channel_id="${channel_id//\"}"
        else
            channel_id="$CHANNEL"
        fi
        post_json="{\"ProjectId\":\"${project_id}\", \"ReleaseNotes\":\"Branch: ${CURRENT_BRANCH_NAME}\", \"Version\":\"${CURRENT_BUILD_NO}\", \"ChannelId\":\"${channel_id}\",\"SelectedPackages\": [{\"StepName\": \"${DEFAULT_PACKAGE_STEP_NAME}\",\"ActionName\": \"${DEFAULT_PACKAGE_STEP_NAME}\",\"Version\": \"${CURRENT_BUILD_NO}\"}]}"       
        status_code=$(curl --silent --output /dev/stderr --write-out "%{http_code}" -X POST ${OCTOPUS_FULL_BASE}/releases -H "X-Octopus-ApiKey:${OCTO_API_KEY}" -H "content-type:application/json" -d "${post_json}")
        if [ ${status_code} -ge 300 ];
        then
            exit ${status_code}
        fi
        break
    fi
done
