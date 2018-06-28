set -f

PROJECTS=$1
PROJECTS="${PROJECTS//\"}"
PROJECTS_LIST=(${PROJECTS//,/ })
COMPARE_URL=$2
PREPEND_STRING=$3

echo ${PROJECTS_LIST[@]}
echo $PROJECTS_LIST

COMMIT_RANGE=$(echo $COMPARE_URL | sed 's:^.*/compare/::g')

if [[ $(git diff $COMMIT_RANGE --name-status | grep "common") != "" ]] || [[ $(git diff $COMMIT_RANGE --name-status | grep "contracts") != "" ]]; then
    echo "$PROJECTS" >> build_projects.txt
    exit 0
else
    for i in ${!PROJECTS_LIST[@]}; do
        project_name=${PROJECTS_LIST[$i]}
        full_project_name="${PREPEND_STRING}${project_name}"
        echo "Checking $project_name"

        if [[ $(git diff $COMMIT_RANGE --name-status | grep "${project_name}") != "" ]]; then
            BUILD_PROJECTS+=($full_project_name)
        fi
    done

    BUILD_PROJECTS=$(IFS=, ; echo "${BUILD_PROJECTS[*]}")
    echo $BUILD_PROJECTS >> build_projects.txt
fi
