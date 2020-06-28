
VERSION="${VERSION}"
BRANCH_NAME="${BRANCH_NAME}"
BRANCH="${BRANCH}"
BUCKET="${BUCKET}"
if [[ "$VERSION" == "" ]]; then
  echo "VERSION env var must be provided"
  exit 1
fi

if [[ "$BRANCH_NAME" == "" ]]; then
  echo "BRANCH_NAME env var must be provided"
  exit 1
fi

if [[ "$BRANCH" == "" ]]; then
  echo "BRANCH env var must be provided"
  exit 1
fi

if [[ "$BUCKET" == "" ]]; then
  echo "BUCKET env var must be provided"
  exit 1
fi

EXTRA_ARGS=""
S3_OBJECT_PREFIX=""

if [[ "${BRANCH_NAME}" == "master" ]]; then
  echo "detected master build"
  S3_OBJECT_PREFIX="osx/edge"
  EXTRA_ARGS="--expires $(date -d '+21 days' --iso-8601=seconds)"
elif [[ "${BRANCH}" == *"staging/"* ]]; then
  echo "detected staging build"
  S3_OBJECT_PREFIX="osx/staging"
  EXTRA_ARGS="--expires $(date -d '+14 days' --iso-8601=seconds)"
elif [[ "${BRANCH}" == *"release/"* ]]; then
  echo "detected release build"
  S3_OBJECT_PREFIX="osx/stable"
else
  echo "detected PR build"
  S3_OBJECT_PREFIX="osx/internal"
  EXTRA_ARGS="--expires $(date -d '+2 days' --iso-8601=seconds)"
fi

set -e
set -x

S3_OBJECT_NAME="${S3_OBJECT_PREFIX}/Morphic-v${VERSION}.dmg"

LOCAL_DMG="./Morphic/Morphic.dmg"

aws s3 cp $EXTRA_ARGS "${LOCAL_DMG}" "s3://${BUCKET}/${S3_OBJECT_NAME}"