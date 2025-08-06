set -exo pipefail
MVOPTS="--batch-mode"
if [ "x$EX_MVN" == "x" ] ; then
 EX_MVN=mvn
fi
if [ -e "$JAVA_HOME/bin/java" ] ; then
  java=$JAVA_HOME/bin/java
else
  java=java
fi

sub=jnr-constants
rm -rf $sub
mkdir  $sub
pushd  $sub

JNR_LIVE_PROJECTS="jnr-constants:0.9.15"

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
    if [ $jdkMajor -ge 17 ] ; then
      sed "s/2.3.7/6.0.0/g" -i pom.xml #fixme, upstream, javadoc fix
    fi
    if [ $jdkMajor -eq 11 ] ; then
      sed "s/2.3.7/5.1.9/g" -i pom.xml #fixme, upstream, javadoc fix
    fi
    sed "s/1.7/$jdkMajor/g" -i pom.xml #fixme, upstream
    $EX_MVN $MVOPTS -Dmaven.javadoc.skip=true clean install
  popd
done

