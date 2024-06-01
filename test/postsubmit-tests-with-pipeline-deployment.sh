#!/bin/bash
set -ex

usage() {
    echo "usage: deploy.sh
    [--platform             the deployment platform. Valid values are: [kind, minikube]. Default is kind.]
    [--kfp_deployment       the deployment method of kfp. Valid values are: [standalone, mkp]. Default is standalone.]
    [--workflow_file        the file name of the argo workflow to run]
    [--test_result_bucket   the gcs bucket that argo workflow store the result to. Default is ml-pipeline-test
    [--test_result_folder   the gcs folder that argo workflow store the result to. Always a relative directory to gs://<gs_bucket>/[PULL_SHA]]
    [--timeout              timeout of the tests in seconds. Default is 1800 seconds. ]
    [-h help]"
}

PLATFORM=kind
PROJECT=ml-pipeline-test
KFP_DEPLOYMENT=standalone
TEST_RESULT_BUCKET=ml-pipeline-test
CLOUDBUILD_PROJECT=ml-pipeline-test
GCR_IMAGE_BASE_DIR=gcr.io/ml-pipeline-test
TARGET_IMAGE_BASE_DIR=gcr.io/ml-pipeline-test/${PULL_BASE_SHA}
TIMEOUT_SECONDS=1800
NAMESPACE=kubeflow
IS_INTEGRATION_TEST=false
ENABLE_WORKLOAD_IDENTITY=false
COMMIT_SHA="$PULL_BASE_SHA"

while [ "$1" != "" ]; do
    case $1 in
             --platform )             shift
                                      PLATFORM=$1
                                      ;;
             --kfp_deployment )       shift
                                      KFP_DEPLOYMENT=$1
                                      ;;
             --workflow_file )        shift
                                      WORKFLOW_FILE=$1
                                      ;;
             --test_result_bucket )   shift
                                      TEST_RESULT_BUCKET=$1
                                      ;;
             --test_result_folder )   shift
                                      TEST_RESULT_FOLDER=$1
                                      ;;
             --is_integration_test )  shift
                                      IS_INTEGRATION_TEST=$1
                                      ;;
             --timeout )              shift
                                      TIMEOUT_SECONDS=$1
                                      ;;
             -h | --help )            usage
                                      exit
                                      ;;
             * )                      usage
                                      exit 1
    esac
    shift
done

# Variables
TEST_RESULTS_GCS_DIR=gs://${TEST_RESULT_BUCKET}/${PULL_BASE_SHA}/${TEST_RESULT_FOLDER}
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd)"

if [ ${KFP_DEPLOYMENT} != standalone ]; then
  ENABLE_WORKLOAD_IDENTITY=false
fi

echo "postsubmit test starts"

source "${DIR}/test-prep.sh"

source "${DIR}/deploy-cluster.sh"
echo "cluster deployed"

# Install Argo
source "${DIR}/install-argo.sh"
echo "argo installed"

# Deploy the pipeline
GCR_IMAGE_TAG=${PULL_BASE_SHA}
if [ ${KFP_DEPLOYMENT} == standalone ]; then
  time source "${DIR}/deploy-pipeline-lite.sh"
  echo "KFP standalone deployed"
  # Submit the argo job and check the results
  echo "submitting argo workflow for commit ${PULL_BASE_SHA}..."
  ARGO_WORKFLOW=`argo submit ${DIR}/${WORKFLOW_FILE} \
  -p image-build-context-gcs-uri="$remote_code_archive_uri" \
  -p commit-sha="${PULL_BASE_SHA}" \
  -p component-image-prefix="${GCR_IMAGE_BASE_DIR}/" \
  -p target-image-prefix="${TARGET_IMAGE_BASE_DIR}/" \
  -p test-results-gcs-dir="${TEST_RESULTS_GCS_DIR}" \
  -p is-integration-test="${IS_INTEGRATION_TEST}" \
  -n ${NAMESPACE} \
  --serviceaccount test-runner \
  -o name
  `
  echo "argo workflow submitted successfully"
  source "${DIR}/check-argo-status.sh"
  echo "test workflow completed"
else
  SEM_VERSION="$(cat ${DIR}/../VERSION)"
  source "${DIR}/deploy-pipeline-mkp-cli.sh" $SEM_VERSION $COMMIT_SHA ${DIR}
  exit $?
fi
