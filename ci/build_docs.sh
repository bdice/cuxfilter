#!/bin/bash

set -euo pipefail

rapids-logger "Downloading artifacts from previous jobs"
PYTHON_CHANNEL=$(rapids-download-conda-from-s3 python)

rapids-logger "Create test conda environment"
. /opt/conda/etc/profile.d/conda.sh

rapids-dependency-file-generator \
    --output conda \
    --file-key docs \
    --matrix "cuda=${RAPIDS_CUDA_VERSION%.*};arch=$(arch);py=${RAPIDS_PY_VERSION}" \
    --prepend-channel "${PYTHON_CHANNEL}" \
    | tee env.yaml

rapids-mamba-retry env create --yes -f env.yaml -n docs
conda activate docs

rapids-print-env

export RAPIDS_DOCS_DIR="$(mktemp -d)"

rapids-logger "Build Python docs"
pushd docs
sphinx-build -b dirhtml ./source _html
mkdir -p "${RAPIDS_DOCS_DIR}/cuxfilter/"html
mv _html/* "${RAPIDS_DOCS_DIR}/cuxfilter/html"
popd

RAPIDS_VERSION_NUMBER="$(rapids-version-major-minor)" rapids-upload-docs
