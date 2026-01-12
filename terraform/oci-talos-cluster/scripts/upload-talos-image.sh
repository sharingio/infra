#!/bin/bash
# Script to download Talos image from Image Factory and upload to OCI Object Storage
# Usage: ./upload-talos-image.sh <schematic_id> <talos_version> <bucket_name> <namespace> <region>

set -euo pipefail

SCHEMATIC_ID="${1}"
TALOS_VERSION="${2}"
BUCKET_NAME="${3}"
NAMESPACE="${4}"
REGION="${5}"
OBJECT_NAME="talos-${TALOS_VERSION}-oracle-amd64.qcow2"

FACTORY_URL="https://factory.talos.dev/image/${SCHEMATIC_ID}/${TALOS_VERSION}/oracle-amd64.raw.xz"
TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT

echo "Checking if image already exists in bucket..."
if oci os object head \
    --bucket-name "${BUCKET_NAME}" \
    --namespace "${NAMESPACE}" \
    --name "${OBJECT_NAME}" 2>/dev/null; then
    echo "Image ${OBJECT_NAME} already exists in bucket, skipping upload"
    exit 0
fi

echo "Downloading Talos image from factory..."
curl -L -o "${TEMP_DIR}/oracle-amd64.raw.xz" "${FACTORY_URL}"

echo "Decompressing image..."
xz -d "${TEMP_DIR}/oracle-amd64.raw.xz"

echo "Converting to QCOW2 format..."
qemu-img convert -O qcow2 "${TEMP_DIR}/oracle-amd64.raw" "${TEMP_DIR}/${OBJECT_NAME}"

echo "Uploading to OCI Object Storage..."
oci os object put \
    --bucket-name "${BUCKET_NAME}" \
    --namespace "${NAMESPACE}" \
    --file "${TEMP_DIR}/${OBJECT_NAME}" \
    --name "${OBJECT_NAME}" \
    --force

echo "Image uploaded successfully: ${OBJECT_NAME}"
echo "Image URL: https://${NAMESPACE}.objectstorage.${REGION}.oci.customer-oci.com/n/${NAMESPACE}/b/${BUCKET_NAME}/o/${OBJECT_NAME}"
