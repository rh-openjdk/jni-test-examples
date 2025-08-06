set -exo pipefail
sub=scala-partest
rm -rf $sub
mkdir $sub
pushd $sub
  sbtv=1.5.0
  scalav=2.13.3
  wget https://github.com/sbt/sbt/releases/download/v$sbtv/sbt-$sbtv.tgz
  wget https://github.com/scala/scala/archive/v$scalav.tar.gz
  tar -xf sbt-$sbtv.tgz
  tar -xf v$scalav.tar.gz
  pushd scala-$scalav
    pushd test/files/jvm
        rm -v  libnatives*.so
        OSTYPE=linux  sh -x  mkLibNatives.sh 
        sed 's/System.loadLibrary.*/System.loadLibrary("natives")/' -i natives.scala
    popd
    bash ../sbt/bin/sbt --no-colors "partest test/files/jvm/natives.scala"
  popd
popd

