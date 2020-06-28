
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

# OSX's date util is different than linux. You gotta do a bit more legwork to get an expiry date.
expiry()
{
  date -v "${1}" -u +"%Y-%m-%dT%H:%M:%SZ"
}

if [[ "${BRANCH_NAME}" == "master" ]]; then
  echo "detected master build"
  S3_OBJECT_PREFIX="osx/edge"
  EXTRA_ARGS="--expires $(expiry '+21d')"
elif [[ "${BRANCH}" == *"staging/"* ]]; then
  echo "detected staging build"
  S3_OBJECT_PREFIX="osx/staging"
  EXTRA_ARGS="--expires $(expiry '+14d')"
elif [[ "${BRANCH}" == *"release/"* ]]; then
  echo "detected release build"
  S3_OBJECT_PREFIX="osx/stable"
else
  echo "detected PR build"
  S3_OBJECT_PREFIX="osx/internal"
  EXTRA_ARGS="--expires $(expiry '+2d')"
fi

set -e
set -x

S3_OBJECT_NAME="${S3_OBJECT_PREFIX}/Morphic-v${VERSION}.dmg"

LOCAL_DMG="./Morphic/Morphic.dmg"

aws s3 cp $EXTRA_ARGS "${LOCAL_DMG}" "s3://${BUCKET}/${S3_OBJECT_NAME}"