function octo(){
    OCTOPUS_FULL_BASE="https://${OCTOPUS_BASE}"
    OCTOPUS_API_KEY="${OCTO_API_KEY}"

    BUILD_NUMBER=${BUILD_NO}
    APPLICATION_NAME=${CIRCLE_PROJECT_REPONAME}
    BASE_PATH="./deploy"

    PUBLISH=false
    CREATE_RELEASE=false

    for i in "$@"; do
        case $1 in
            --publish) PUBLISH=true ;;
            --release) CREATE_RELEASE=true ;;
            --buildno) BUILD_NUMBER="$2"; shift ;;
            --appname) APPLICATION_NAME="$2"; shift ;;
            --basepath) BASE_PATH="$2"; shift ;;
        esac
        shift
    done

    CREDENTIALS="--server=${OCTOPUS_FULL_BASE} --apiKey=${OCTOPUS_API_KEY}"

    # PACKAGE
    PACKAGE_COMMAND="--id=${APPLICATION_NAME} --format=zip --version=${BUILD_NUMBER} --basePath=${BASE_PATH} --overwrite"
    PUSH_COMMAND="--package=${APPLICATION_NAME}.${BUILD_NUMBER}.zip --replace-existing ${CREDENTIALS}"
    CREATE_RELEASE_COMMAND="--project=${APPLICATION_NAME} --version=${BUILD_NUMBER} --packageversion=${BUILD_NUMBER} ${CREDENTIALS}"

    if $PUBLISH; then
        docker run --rm -v $(pwd):/src octopusdeploy/octo pack ${PACKAGE_COMMAND}
        docker run --rm -v $(pwd):/src octopusdeploy/octo push ${PUSH_COMMAND}
    else
        docker run --rm -v $(pwd):/src octopusdeploy/octo create-release ${CREATE_RELEASE_COMMAND}
    fi
}