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
    set +x
      jdkMajor=8
	  for x in `seq 30 -1 11` ; do
        if $java --version 2>&1 | grep "[- ]$x[.][0-9]\+[.][0-9]\+" ; then jdkMajor=$x ; break ; fi
      done
    set -x
    sed "s;<source>.*;<source>$jdkMajor</source>;" -i pom.xml
    sed "s;<target>.*;<target>$jdkMajor</target>;" -i pom.xml
    $EX_MVN $MVOPTS -Dmaven.javadoc.skip=true clean install
  popd
done

