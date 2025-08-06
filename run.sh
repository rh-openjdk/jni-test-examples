#!/bin/bash

SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SCRIPT_SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  SCRIPT_DIR="$( cd -P "$( dirname "$SCRIPT_SOURCE" )" && pwd )"
  SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  [[ $SCRIPT_SOURCE != /* ]] && SCRIPT_SOURCE="$SCRIPT_DIR/$SCRIPT_SOURCE"
done
readonly SCRIPT_DIR="$( cd -P "$( dirname "$SCRIPT_SOURCE" )" && pwd )"


OS=`uname -s`
CYGWIN="false"
case "$OS" in
  Windows_* | CYGWIN_NT* )
    PS=";"
    FS="\\"
    CYGWIN="true"
    ;;
  * )
    echo "Non cygwin system!"
    ;;
esac

READLINK_F="-f"
readlink $READLINK_F "." || READLINK_F=""

set -e
set -o pipefail

JAVA="${1}"
if [ "x$JAVA" == "x" ] ; then
  echo "Jdk is mandatory param"
  exit 1
fi

if [ "x$CYGWIN" == "xtrue" ] ; then
  JAVA="$(cygpath -aw "${JAVA}")"
fi

# all underlying maven/ant projects are honring JAVA_HOME as main source of truth
export JAVA_HOME="$JAVA"
# do not set unless you know what you are doing
if [ "x$FORCE_INSTALL_JAVA" == "xtrue" ] ; then
  # run folder as tests will now do the mayhem
  JAVA=""
fi

if [ "x$RFAT" = "x" ] ; then
  if [ ! -e run-folder-as-tests ] ; then
    git clone https://github.com/rh-openjdk/run-folder-as-tests.git ${rft} 1>&2
  fi
  RFAT=`pwd`/run-folder-as-tests
fi

TIME=$(date +%s)

if [ "x$JDK_MAJOR" == "x" ] ; then 
  JDK_MAJOR=8
  if [[ -e "$JAVA/bin/jshell" || -e "$JAVA/bin/jshell.exe" ]] ; then
    jshellScript="$(mktemp)"
    printf "System.out.print(Runtime.version().major())\n/exit" > "${jshellScript}"
    if [ "x$CYGWIN" == "xtrue" ] ; then
       jshellScript="$(cygpath -aw "${jshellScript}")"
    fi
    JDK_MAJOR=$( "$JAVA/bin/jshell" "${jshellScript}" 2> /dev/null  | grep -v -e "Started recording"  -e "copy recording data to file"  -e "^$"  -e "\[" )
    rm "${jshellScript}"
  fi
fi
export JDK_MAJOR
echo "treating jdk as: $JDK_MAJOR"

echo Running with $JAVA...

jtWork="test.${TIME}/jdk/work"
jtReport="test.${TIME}/jdk/report"
mkdir -p $jtWork
mkdir -p $jtReport
export SCRATCH_DISK="`pwd`/$jtWork"
export WORKSPACE="`pwd`/$jtReport"

bash ${RFAT}/run-folder-as-tests.sh $SCRIPT_DIR/jni $JAVA | tee test.${TIME}/tests.log

tar -czf test.${TIME}.tar.gz "${jtWork}" "${jtReport}" || echo "Packing of results tarball failed"
if ! [ -f test.${TIME}/tests.log ] ; then
	echo "Missing tests.log!" 1>&2
	exit 1
fi

# passes should be present in tests.log
grep -Eqi '^passed:' test.${TIME}/tests.log || exit 1
# check for failures/errors in tests.log 
! grep -Eqi '^(failed|error):' test.${TIME}/tests.log || exit 1

# returning 0 to allow unstable state
exit 0
