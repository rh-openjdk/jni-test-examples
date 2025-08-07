set -exo pipefail
MVOPTS="--batch-mode"
if [ "x$EX_MVN" == "x" ] ; then
 EX_MVN=mvn
fi

sub=jnr-x86asm
rm -rf $sub
mkdir  $sub
pushd  $sub

JNR_LIVE_PROJECTS="jnr-x86asm:1.0.2" #warning missing name in tag
if [ "x$PURGE_MVN" == "xtrue" ] ; then  $EX_MVN $MVOPTS dependency:purge-local-repository -DreResolve=false ; fi
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
    sed "s;<maven.compiler.source>.*;<maven.compiler.source>$JDK_MAJOR</maven.compiler.source>;" -i pom.xml
    sed "s;<maven.compiler.target>.*;<maven.compiler.target>$JDK_MAJOR</maven.compiler.target>;" -i pom.xml
    if [ "x$PURGE_MVN" == "xtrue" ] ; then  $EX_MVN $MVOPTS dependency:purge-local-repository -DreResolve=false ; fi
    $EX_MVN $MVOPTS -Dmaven.javadoc.skip=true clean install
  popd
done

