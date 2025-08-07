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
    if [ "x$PURGE_MVN" == "xtrue" ] ; then  $EX_MVN $MVOPTS dependency:purge-local-repository -DreResolve=false ; fi
    if [ $JDK_MAJOR -ge 17 ] ; then
      sed "s/2.3.7/6.0.0/g" -i pom.xml #fixme, upstream, javadoc fix
    fi
    if [ $JDK_MAJOR -eq 11 ] ; then
      sed "s/2.3.7/5.1.9/g" -i pom.xml #fixme, upstream, javadoc fix
    fi
    sed "s/1.7/$JDK_MAJOR/g" -i pom.xml #fixme, upstream
    $EX_MVN $MVOPTS -Dmaven.javadoc.skip=true clean install
  popd
done

