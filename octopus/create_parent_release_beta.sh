#!/bin/bash 
set -f

BASE_DIR=$(dirname $0)
RELEASE_DIR="${BASE_DIR}/deploy"
OCTOPUS_FULL_BASE="https://${OCTOPUS_BASE}/api"
OCTOPUS_PROJECTS_URL="${OCTOPUS_FULL_BASE}/projects/all"

CURRENT_PROJECT_NAME=$1
BUILD_NO=$2
BUILT_PACKAGE_STRING=$3
BUILT_PACKAGES=(${BUILT_PACKAGE_STRING//,/ })
CURRENT_BRANCH=${4//_/-}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'

GetChannelId(){
    project_id=$(curl --silent ${OCTOPUS_PROJECTS_URL} -H "X-Octopus-ApiKey:${OCTO_API_KEY}" | jq -r --arg PROJECT_NAME "$CURRENT_PROJECT_NAME" '.[1] | select(.Name==$PROJECT_NAME) | .Id' )
    channel_id=$(curl -s ${OCTOPUS_FULL_BASE}/projects/${project_id}/channels?take=1 -H "X-Octopus-ApiKey:${OCTO_API_KEY}" | jq -r '.Items[0].Id')
}

GetProjectLastPackages(){
    packages=$(curl -s ${OCTOPUS_FULL_BASE}/deploymentprocesses/deploymentprocess-${project_id}/template?channel=${channel_id} -H "X-Octopus-ApiKey:${OCTO_API_KEY}" | jq '[.Packages[] | { ProjectName: .ProjectName,  LastRelease: .VersionSelectedLastRelease, StepName: .StepName, ActionName: .ActionName }]')
}

GenerateDeploySteps(){
    for row in $(echo "${packages}" | jq -r '.[] | @base64'); do
        _jq() {
            echo ${row} | base64 --decode | jq -r ${1}
        }

        if in_array $(echo $(_jq '.ProjectName')) "${BUILT_PACKAGES[*]}"
        then
            DEPLOY_STEPS+=( "{\"StepName\": \"$(_jq '.StepName')\",\"ActionName\": \"$(_jq '.ProjectName')\",\"Version\": \"${BUILD_NO}\"}" )
        else    
            DEPLOY_STEPS+=( "{\"StepName\": \"$(_jq '.StepName')\",\"ActionName\": \"$(_jq '.ProjectName')\",\"Version\": \"$(echo $(_jq '.LastRelease'))\"}" )
        fi
    done

    DEPLOY_STEPS=$(IFS=, ; echo "${DEPLOY_STEPS[*]}")
}

CreateRelease(){
    post_json="{\"ProjectId\":\"${project_id}\", \"ReleaseNotes\":\"Branch: ${CURRENT_BRANCH_NAME}\", \"Version\":\"${BUILD_NO}\", \"ChannelId\":\"${channel_id}\",\"SelectedPackages\": [$DEPLOY_STEPS]}" 
    status_code=$(curl --silent --output /dev/null -w "%{http_code}" -X POST ${OCTOPUS_FULL_BASE}/releases -H "X-Octopus-ApiKey:${OCTO_API_KEY}" -H "content-type:application/json" -d "${post_json}")
    if [ ${status_code} -ge 300 ];
    then
        printf "${RED}Upload to Octopus was not successful"
        exit ${status_code}
    fi
}

in_array() {
  ARRAY=$2
  for e in ${ARRAY[*]}
  do
    if [[ "$e" == "${PREPEND_STRING}$1" ]]
    then
      return 0
    fi
  done
  return 1
}

if [[ -z ${BUILT_PACKAGES[@]} ]]; then
    printf "${YELLOW}No packages updated, nothing to do"
    exit 0
fi

GetChannelId
GetProjectLastPackages
GenerateDeploySteps
CreateRelease

printf "${GREEN}Octopus release successful"
exit $?
