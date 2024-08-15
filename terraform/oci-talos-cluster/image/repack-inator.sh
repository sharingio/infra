#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

IMAGE_FILE="$1"
if [ -z "$IMAGE_FILE" ] || [ ! -f "$IMAGE_FILE" ]; then
    echo "error: missing file '${IMAGE_FILE}'" >/dev/stderr
    exit 1
fi
NAME="$(basename ${IMAGE_FILE#.*})"
EXTENSION="${IMAGE_FILE#*.}"
case "$EXTENSION" in
    *raw.xz)

        ;;
    *)
        echo "error: unexpected format: ${EXTENSION}" >/dev/stderr
        exit 1
        ;;
esac

DATE="$(date | sed 's/ /-/g')"
BUILD_DIR="tmp-$DATE"
mkdir -p "$BUILD_DIR"

LOCAL_FILE="oracle-arm64.raw.xz"
cp "$IMAGE_FILE" "$BUILD_DIR/$LOCAL_FILE"
cp image_metadata_arm64.json "$BUILD_DIR"/image_metadata.json
pushd "$BUILD_DIR/" || exit 1
xz --decompress "$LOCAL_FILE"
qemu-img convert -f raw -O qcow2 oracle-arm64.raw oracle-arm64.qcow2
tar zcf oracle-arm64.oci oracle-arm64.qcow2 image_metadata.json
popd || exit 1
