set -exo pipefail
sub=scala-partest
rm -rf $sub
mkdir $sub
pushd $sub
  sbtv=1.11.4
  scalav=2.13.16
  wget https://github.com/sbt/sbt/releases/download/v$sbtv/sbt-$sbtv.tgz
  tar -xf sbt-$sbtv.tgz
  git clone https://github.com/judovana/scala.git scala-$scalav
  pushd scala-$scalav
    git checkout jdk11AndUpNatives
    mach_file=./test/files/jvm/natives.check
    if $JAVA_HOME/bin/java -version 2>&1 | grep Picked ; then
      orig_mach_file_content=`cat ./test/files/jvm/natives.check`
      $JAVA_HOME/bin/java -version 2>&1 | grep Picked  > $mach_file
      echo $orig_mach_file_content >> $mach_file
      cat ./test/files/jvm/natives.check
    fi
    ../sbt/bin/sbt --java-home $JAVA_HOME --no-colors "partest --debug  test/files/jvm/natives.scala" || echo "generated classes should be ok even in case of (most likely) failure" 
    pushd test/files/jvm
        rm -v  libnatives*.so
        OSTYPE=linux  sh -x  mkLibNatives.sh 
    popd
    scala_test_nativelib="natives" ../sbt/bin/sbt --java-home $JAVA_HOME --no-colors "partest test/files/jvm/natives.scala" # now real test against freshly built library
  popd
popd

