#!/bin/sh

mkdir -p /tmp/code.$$
cd /tmp/code.$$

function cleanup() {
  echo "Cleaning up temp dir..."
  shred /tmp/code.$$/private.*
  rm -rf /tmp/code.$$

  unset PLAIN_KEY WRL_CODE_ARTIFACT_ENC_KEY WRL_CODE_ARTIFACT_ENC_IV WRL_CODE_ARTIFACT_ENC_ALG WRL_CODE_ARTIFACT_ENC_KTY WRL_CODE_ARTIFACT_ENC_P WRL_CODE_ARTIFACT_PRIVATE_KEY
}

ARTIFACT_NAME=code.artifact

echo "Downloading code $WRL_CODE_ARTIFACT_URL ..."
curl -sL "$WRL_CODE_ARTIFACT_URL" -o "$ARTIFACT_NAME"
if [ $? -ne 0 ]; then
  echo "Download failed."
  cleanup
  exit 1
fi

echo "Verifying hash..."
CODE_HASH=`sha256sum $ARTIFACT_NAME | awk '{ print $1 }'`
if [ "$CODE_HASH" != "$WRL_CODE_CONTENT_HASH" ]; then
  echo "Hash does not match the expected value."
  cleanup
  exit 2
fi

echo -n "Checking artifact type ... "
ARTIFACT_TYPE=`file -b --mime-type $ARTIFACT_NAME`
echo $ARTIFACT_TYPE

if [ "$ARTIFACT_TYPE" == "application/octet-stream" ]; then
  if [ ! -z "$WRL_CODE_ARTIFACT_ENC_KEY" ]; then
    echo "Descrypting artifact ..."
    cat <<EOF >private.pem.$$
$WRL_CODE_ARTIFACT_PRIVATE_KEY
EOF
    PLAIN_KEY=`echo -n "$WRL_CODE_ARTIFACT_ENC_KEY" | base64 -d | openssl rsautl -decrypt -inkey private.pem.$$ | xxd -p -c 32`
    cat $ARTIFACT_NAME | openssl enc -nosalt -$WRL_CODE_ARTIFACT_ENC_ALG -d -K $PLAIN_KEY -iv $WRL_CODE_ARTIFACT_ENC_IV > $ARTIFACT_NAME.dec
    ARTIFACT_NAME=${ARTIFACT_NAME}.dec
    ARTIFACT_TYPE=`file -b --mime-type $ARTIFACT_NAME`
  fi
fi

# TODO(telackey) support more archive types here...
#   switch $ARTIFACT_TYPE ...

echo "Unzipping code..."
unzip $ARTIFACT_NAME -d /home/app
if [ $? -ne 0 ]; then
  echo "Error unzipping package."
  cleanup
  exit 3
fi

cd /home/app

cleanup

echo "Starting OpenFaaS watchdog..."
fwatchdog
