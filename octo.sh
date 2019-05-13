OCTOPUS_FULL_BASE="https://${OCTOPUS_BASE}"
OCTOPUS_API_KEY="${OCTO_API_KEY}"

BUILD_NUMBER=${BUILD_NO}
APPLICATION_NAME=${CIRCLE_PROJECT_REPONAME}
BASE_PATH="./deploy"
BRANCH="${CIRCLE_BRANCH}"

PUBLISH=false
CREATE_RELEASE=false

for i in "$@"; do
    case $1 in
        --publish) PUBLISH=true ;;
        --release) CREATE_RELEASE=true ;;
        --buildno) BUILD_NUMBER="$2"; shift ;;
        --appname) APPLICATION_NAME="$2"; shift ;;
        --basepath) BASE_PATH="$2"; shift ;;
        --branch) BRANCH="$2"; shift;; 
    esac
    shift
done

BRANCH="${BRANCH//_/\_}" #Escaping _ because they mean italic in markdown

CREDENTIALS="--server=${OCTOPUS_FULL_BASE} --apiKey=${OCTOPUS_API_KEY}"

# PACKAGE
PACKAGE_COMMAND="--id=${APPLICATION_NAME} --format=zip --version=${BUILD_NUMBER} --overwrite"
PUSH_COMMAND="--package=${APPLICATION_NAME}.${BUILD_NUMBER}.zip --replace-existing ${CREDENTIALS}"
CREATE_RELEASE_COMMAND="--project=${APPLICATION_NAME} --version=${BUILD_NUMBER} --packageversion=${BUILD_NUMBER} --releasenotes=Branch:${BRANCH} ${CREDENTIALS}"

if $PUBLISH; then
    docker create -v /src --name data alpine:3.4 /bin/true
    docker cp ${BASE_PATH} data:/src

    docker run --rm --volumes-from data octopusdeploy/octo pack ${PACKAGE_COMMAND}
    docker run --rm --volumes-from data octopusdeploy/octo push ${PUSH_COMMAND}
fi

if $CREATE_RELEASE; then
    docker run --rm octopusdeploy/octo create-release ${CREATE_RELEASE_COMMAND}
fi
