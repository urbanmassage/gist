#!/bin/bash

OCTOPUS_FULL_BASE="https://${OCTOPUS_BASE}"
OCTOPUS_API_KEY="${OCTO_API_KEY}"

BUILD_NUMBER=${BUILD_NO}
APPLICATION_NAME=${REPO_NAME}
BASE_PATH="./deploy"

PUBLISH=false
CREATE_RELEASE=false
RELEASE_NOTES=""

declare -a deploy_targets=()

for i in "$@"; do
    case $1 in
        --publish) PUBLISH=true ;;
        --release) CREATE_RELEASE=true ;;
        --buildno) BUILD_NUMBER="$2"; shift ;;
        --appname) APPLICATION_NAME="$2"; shift ;;
        --basepath) BASE_PATH="$2"; shift ;;
        --branch) BRANCH="$2"; shift;; 
        --deployto) deploy_targets+=("$2"); shift;; 
        --releasenotes) RELEASE_NOTES="$2"; shift ;;
    esac
    shift
done

BRANCH="${BRANCH//_/\_}" #Escaping _ because they mean italic in markdown

CREDENTIALS="--server=${OCTOPUS_FULL_BASE} --apiKey=${OCTOPUS_API_KEY}"

DEPLOY_TO=""
for deploy_target in "${deploy_targets[@]}"
   do
     DEPLOY_TO+="--deployTo=$deploy_target "
   done

# PACKAGE
PACKAGE_COMMAND="--id=${APPLICATION_NAME} --format=zip --version=${BUILD_NUMBER} --overwrite"
PUSH_COMMAND="--package=${APPLICATION_NAME}.${BUILD_NUMBER}.zip --replace-existing ${CREDENTIALS}"
CREATE_RELEASE_COMMAND="--project=${APPLICATION_NAME} --version=${BUILD_NUMBER} --packageversion=${BUILD_NUMBER} --releasenotes=${RELEASE_NOTES} ${DEPLOY_TO}${CREDENTIALS}"

if $PUBLISH; then
    docker create -v /src --name octopus-data alpine:3.4 /bin/true
    docker cp ${BASE_PATH} octopus-data:/src

    docker run --rm --volumes-from octopus-data octopusdeploy/octo pack ${PACKAGE_COMMAND}
    docker run --rm --volumes-from octopus-data octopusdeploy/octo push ${PUSH_COMMAND}
fi

if $CREATE_RELEASE; then
  docker run --rm octopusdeploy/octo create-release ${CREATE_RELEASE_COMMAND}
fi
