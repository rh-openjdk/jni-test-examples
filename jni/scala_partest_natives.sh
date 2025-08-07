set -exo pipefail
sub=scala-partest
rm -rf $sub
mkdir $sub
pushd $sub
  sbtv=1.11.4
  scalav=2.13.16
  wget https://github.com/sbt/sbt/releases/download/v$sbtv/sbt-$sbtv.tgz
  wget https://github.com/scala/scala/archive/v$scalav.tar.gz
  tar -xf sbt-$sbtv.tgz
  tar -xf v$scalav.tar.gz
  pushd scala-$scalav
    ../sbt/bin/sbt --no-colors "partest --debug  test/files/jvm/natives.scala" || echo "generated classes should be ok even in case of (most likely) failure" 
    pushd test/files/jvm
        rm -v  libnatives*.so
        OSTYPE=linux  sh -x  mkLibNatives.sh 
        sed 's/System.loadLibrary.*/System.loadLibrary("natives")/' -i natives.scala
    popd
    bash ../sbt/bin/sbt --no-colors "partest test/files/jvm/natives.scala" # now real test against freshly built library
  popd
popd

