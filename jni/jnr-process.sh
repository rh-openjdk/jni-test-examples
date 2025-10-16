set -exo pipefail
MVOPTS="--batch-mode"
if [ "x$EX_MVN" == "x" ] ; then
 EX_MVN=mvn
fi

sub=jnr-process
rm -rf $sub
mkdir  $sub
pushd  $sub

JNR_LIVE_PROJECTS="jnr-process:0.3"
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
    sed "s;<source>.*;<source>$JDK_MAJOR</source>;" -i pom.xml
    sed "s;<target>.*;<target>$JDK_MAJOR</target>;" -i pom.xml
    if [ "x$PURGE_MVN" == "xtrue" ] ; then  $EX_MVN $MVOPTS dependency:purge-local-repository -DreResolve=false ; fi
    $EX_MVN $MVOPTS -Dmaven.javadoc.skip=true clean test
  popd
done

