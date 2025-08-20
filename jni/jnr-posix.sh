set -exo pipefail
MVOPTS="--batch-mode"
if [ "x$EX_MVN" == "x" ] ; then
 EX_MVN=mvn
fi

sub=jnr-posix
rm -rf $sub
mkdir  $sub
pushd  $sub
PATCH1=false
PATCH2=false
if [ "x$OS_NAME" == "xrhel" -a "0$OS_VERSION_MAJOR" -le "7" -a "0$JDK_MAJOR" -ge 11  ] ; then
  PATCH2=true
fi
if [ "x$JDK_MAJOR" == "x" -o "0$JDK_MAJOR" -ge 17 ] ; then
  JNR_LIVE_PROJECTS="jnr-posix:3.1.20"
   export JAVA_TOOL_OPTIONS="$JAVA_TOOL_OPTIONS --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED"
  if [ "x$OS_ARCH" == "xppc64le" ] ; then
    PATCH1=true
  fi
elif [ "0$JDK_MAJOR" -ge 11 ] ; then
  JNR_LIVE_PROJECTS="jnr-posix:3.1.7"
  if [ "x$OS_ARCH" == "xppc64le" ] ; then
    PATCH1=true
  fi
else
  JNR_LIVE_PROJECTS="jnr-posix:3.0.58"
fi
for x in $JNR_LIVE_PROJECTS ; do
  project=`echo $x | sed "s/:.*//"`
  version=`echo $x | sed "s/.*://"`
  wget https://github.com/jnr/$project/archive/$project-$version.tar.gz
  tar -xf $project-$version.tar.gz
  pushd $project-$project-$version
    if [ "x$PATCH1" == "xtrue" ] ; then
      # Ignore testMessageHdrMultipleControl on ppc64le
      # https://github.com/jnr/jnr-posix/issues/178
      sed -e '/testMessageHdrMultipleControl/i @Ignore'  -e '/import org.junit.Test/a import org.junit.Ignore;' -i src/test/java/jnr/posix/LinuxPOSIXTest.java
    fi
    if [ "x$PATCH2" == "xtrue" ] ; then
      # Ignore SpawnTest. on el7
      sed -e '/public void inputFile/i @Ignore'  -e '/import org.junit.Test/a import org.junit.Ignore;' -i src/test/java/jnr/posix/SpawnTest.java
    fi
    if [ "x$PURGE_MVN" == "xtrue" ] ; then  $EX_MVN $MVOPTS dependency:purge-local-repository -DreResolve=false ; fi
    $EX_MVN $MVOPTS -Dmaven.javadoc.skip=true clean install
  popd
done

