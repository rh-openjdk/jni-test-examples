#!/bin/bash
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SCRIPT_SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  SCRIPT_DIR="$( cd -P "$( dirname "$SCRIPT_SOURCE" )" && pwd )"
  SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  [[ $SCRIPT_SOURCE != /* ]] && SCRIPT_SOURCE="$SCRIPT_DIR/$SCRIPT_SOURCE"
done
readonly SCRIPT_DIR="$( cd -P "$( dirname "$SCRIPT_SOURCE" )" && pwd )"

set -exo pipefail

if [ "0$JDK_MAJOR" -lt 21   ]; then
  echo "!skipped!  older wildfly needed for jdk21 and up"
  exit
fi
if [ "x$OS_NAME" == "xrhel" -a "0$OS_VERSION_MAJOR" -le "7" ]; then
  echo "!skipped!  rhel7 and older are to old "
  exit
fi


export NATIVES_VERSION=2.3.0.Alpha3
export VERSION=2.3.0.Alpha2
export DISABLE_testAvailableProtocols=false
bash "$SCRIPT_DIR/wildfly-openssl.bash"

