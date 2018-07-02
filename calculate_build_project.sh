set -f

PROJECTS=$1
PROJECTS="${PROJECTS//\"}"
PROJECTS_LIST=(${PROJECTS//,/ })
COMPARE_URL=$2
PREFIX=$3
SUFFIX=$4

COMMIT_RANGE=$(echo $COMPARE_URL | sed 's:^.*/compare/::g')

git diff $COMMIT_RANGE --name-status

if [[ $(git diff $COMMIT_RANGE --name-status | grep "common") != "" ]] || [[ $(git diff $COMMIT_RANGE --name-status | grep "contracts") != "" ]] || [[ $(git diff $COMMIT_RANGE --name-status | grep "integration_tests") != "" ]]; then
    echo "$PROJECTS" >> build_projects.txt
    exit 0
else
    for i in ${!PROJECTS_LIST[@]}; do
        project_name=${PROJECTS_LIST[$i]}
        full_project_name="${PREFIX}${project_name}${SUFFIX}"
        if [[ $(git diff $COMMIT_RANGE --name-status | grep "${project_name}") != "" ]]; then
            BUILD_PROJECTS+=($full_project_name)
        else
            echo "No changes for ${project_name}"
        fi
    done

    BUILD_PROJECTS=$(IFS=, ; echo "${BUILD_PROJECTS[*]}")
    echo $BUILD_PROJECTS >> build_projects.txt
fi

