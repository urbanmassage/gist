set -f

BASE_DIR=$(dirname $0)
RELEASE_DIR="${BASE_DIR}/deploy"
OCTOPUS_FULL_BASE="https://${OCTOPUS_BASE}/api"
OCTOPUS_PROJECTS_URL="${OCTOPUS_FULL_BASE}/projects/all"

CURRENT_BUILD_NO=$1
CURRENT_PROJECT_NAME=$2

PROJECT_NAME="${CURRENT_PROJECT_NAME}.${CURRENT_BUILD_NO}"
ZIP_FILE="${PROJECT_NAME}.zip"

zip -r "${BASE_DIR}/${ZIP_FILE}" "${RELEASE_DIR}"
mv "${BASE_DIR}/${ZIP_FILE}" "${RELEASE_DIR}/${ZIP_FILE}"

post_status_code=$(curl --silent --output /dev/stderr --write-out "%{http_code}" -X POST ${OCTOPUS_FULL_BASE}/packages/raw -H "X-Octopus-ApiKey:${OCTO_API_KEY}" -F "data=@${RELEASE_DIR}/${ZIP_FILE}")

if [ ${post_status_code} -ge 300 ];
then
    exit ${post_status_code};
fi
