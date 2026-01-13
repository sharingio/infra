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

LOCAL_FILE="oracle-amd64.raw.xz"
cp "$IMAGE_FILE" "$BUILD_DIR/$LOCAL_FILE"
cp image_metadata.json "$BUILD_DIR"/image_metadata.json
pushd "$BUILD_DIR/" || exit 1
xz --decompress "$LOCAL_FILE"
qemu-img convert -f raw -O qcow2 oracle-amd64.raw oracle-amd64.qcow2
tar zcf oracle-amd64.oci oracle-amd64.qcow2 image_metadata.json
popd || exit 1
