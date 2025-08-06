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
    set +x
      jdkMajor=8
	  for x in `seq 30 -1 11` ; do
        if $java --version 2>&1 | grep "[- ]$x[.][0-9]\+[.][0-9]\+" ; then jdkMajor=$x ; break ; fi
      done
    set -x
    sed "s;<maven.compiler.source>.*;<maven.compiler.source>$jdkMajor</maven.compiler.source>;" -i pom.xml
    sed "s;<maven.compiler.target>.*;<maven.compiler.target>$jdkMajor</maven.compiler.target>;" -i pom.xml
    $EX_MVN $MVOPTS -Dmaven.javadoc.skip=true clean install
  popd
done

