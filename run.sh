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
    ID=windows
    VERSION_ID=1995.5
    ;;
  * )
    echo "Non cygwin system!"
    source /etc/os-release
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

# filter is optional
FILTER_ARG="${2}"

# all underlying maven/ant projects are honring JAVA_HOME as main source of truth
export JAVA_HOME="$JAVA"

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
export OS_NAME=$ID
export OS_VERSION_MAJOR=`echo $VERSION_ID | sed "s/\..*//" `
export OS_ARCH=`uname -m`
echo "treating jdk as: $JDK_MAJOR on $OS_NAME $OS_VERSION_MAJOR $OS_ARCH"

echo Running with $JAVA...

jtWork="test.${TIME}/jdk/work"
jtReport="test.${TIME}/jdk/report"
mkdir -p $jtWork
mkdir -p $jtReport
export SCRATCH_DISK="`pwd`/$jtWork"
export WORKSPACE="`pwd`/$jtReport"
if [ "x$PURGE_MVN" == "x" ] ; then
  # some of the maven projects bent `mvn test` pahese so `mvn install` is run rather. As we are changing language level everywhere, installing to shared repos make mayhem if more jdks are run sequentially
  export PURGE_MVN="true"
fi
if [ "x$WHITELIST" == "x" ] ; then
  export WHITELIST="$FILTER_ARG"
fi
bash ${RFAT}/run-folder-as-tests.sh $SCRIPT_DIR/jni $JAVA | tee test.${TIME}/tests.log

toPack="${jtReport}"
if [ "x$JNI_PACK_WORK" == "xtrue" ] ; then
toPack="$toPack ${jtWork}";
fi
tar -czf test.${TIME}.tar.gz  $toPack || echo "Packing of results tarball failed"
if ! [ -f test.${TIME}/tests.log ] ; then
	echo "Missing tests.log!" 1>&2
	exit 1
fi

# results should be in log, if not, it means suite was not run
grep -Eqi -e '^passed' -e '^(failed|error)' -e '^Ignored' test.${TIME}/tests.log || exit 2

if [ "x$JNI_FAIL" == "xtrue" ] ; then
  if grep -Eq -e '^Failed: [1-9]' ; then
    exit 1
  fi
fi
# unless JNI_FAIL=true, exiting with zero to leave decission on following toolchain
exit 0

