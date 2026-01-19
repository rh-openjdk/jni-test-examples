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

if [ "0$JDK_MAJOR" -lt 11   ]; then
  echo "!skipped!  older wildfly needed for jdk8"
  exit
fi
if [ "0$JDK_MAJOR" -ge 21   ]; then
  echo "!skipped!  newer wildfly needed for jdk21"
  exit
fi
if [ "x$OS_NAME" == "xrhel" -a "0$OS_VERSION_MAJOR" -le "7" ]; then
  echo "!skipped!  rhel7 and older are to old "
  exit
fi


export NATIVES_VERSION=2.2.2.Final
export VERSION=2.2.5.Final
export DISABLE_testAvailableProtocols=true
bash "$SCRIPT_DIR/wildfly-openssl.bash"


