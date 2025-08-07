set -exo pipefail
MVOPTS="--batch-mode"
if [ "x$EX_MVN" == "x" ] ; then
 EX_MVN=mvn
fi

sub=jnr-posix
rm -rf $sub
mkdir  $sub
pushd  $sub
if [ "x$JDK_MAJOR" == "x" -o "0$JDK_MAJOR" -ge 17 ] ; then
  JNR_LIVE_PROJECTS="jnr-posix:3.1.20"
   export JAVA_TOOL_OPTIONS="$JAVA_TOOL_OPTIONS --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED"
elif [ "0$JDK_MAJOR" -ge 11 ] ; then
  JNR_LIVE_PROJECTS="jnr-posix:3.1.7"
else
  JNR_LIVE_PROJECTS="jnr-posix:3.0.58"
fi
for x in $JNR_LIVE_PROJECTS ; do
  project=`echo $x | sed "s/:.*//"`
  version=`echo $x | sed "s/.*://"`
  if [ "$project" == "jnr-x86asm" ] ; then 
    wget https://github.com/jnr/$project/archive/$version.tar.gz
    tar -xf $version.tar.gz
    pushd $project-$version
  else
    wget https://github.com/jnr/$project/archive/$project-$version.tar.gz
    tar -xf $project-$version.tar.gz
    pushd $project-$project-$version
  fi
    if [ "x$PURGE_MVN" == "xtrue" ] ; then  $EX_MVN $MVOPTS dependency:purge-local-repository -DreResolve=false ; fi
    $EX_MVN $MVOPTS -Dmaven.javadoc.skip=true clean install
  popd
done

