#!/bin/sh

mkdir -p /tmp/code.$$
cd /tmp/code.$$

echo "Downloading code $WRL_CODE_ARTIFACT_URL ..."
curl -sL "$WRL_CODE_ARTIFACT_URL" -o 'code.zip'
if [ $? -ne 0 ]; then
  echo "Download failed."
  exit 1
fi

echo "Verifying hash..."
CODE_HASH=`sha256sum code.zip | awk '{ print $1 }'`
if [ "$CODE_HASH" != "$WRL_CODE_CONTENT_HASH" ]; then
  echo "Hash does not match the expected value."
  exit 2
fi

echo "Unzipping code..."
unzip code.zip -d /home/app
if [ $? -ne 0 ]; then
  echo "Error unzipping package."
  exit 3
fi

# TODO(telackey): assets too...

cd /home/app

echo "Cleaning up temp dir..."
rm -rf /tmp/code.$$

echo "Starting OpenFaaS watchdog..."
fwatchdog
