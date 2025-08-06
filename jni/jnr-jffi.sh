set -exo pipefail
MVOPTS="--batch-mode"
if [ "x$EX_MVN" == "x" ] ; then
 EX_MVN=mvn
fi

sub=jnr-jffi
rm -rf $sub
mkdir  $sub
pushd  $sub

if [ "x$OTOOL_JDK_VERSION" == "x" -o "0$OTOOL_JDK_VERSION" -ge 16 ] ; then
  JNR_LIVE_PROJECTS="jffi:1.3.4"
else
  JNR_LIVE_PROJECTS="jffi:1.2.23"
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
    $EX_MVN $MVOPTS -Dmaven.javadoc.skip=true clean install
  popd
done

