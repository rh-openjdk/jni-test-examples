set -exo pipefail

rm -rf tomcat-native
mkdir  tomcat-native

III=
if which dnf ; then
  readonly III="dnf"
else
  readonly III="yum"
fi

ant_version=1.10.7

pushd  tomcat-native
  sudo $III install -y apr apr-devel  || true # usally not preinstalled
  sudo $III install -y openssl openssl-devel || true # usually we should have it preinstalled
  ANT=apache-ant-$ant_version-bin.tar.xz
  if [ ! -e $ANT ] ; then
    cp "/mnt/shared/jdk-images/apache/$ANT" . || echo "local copy $ANT  not found, will try to download"
  fi
  if [ ! -e $ANT ] ; then
    ant_version=1.10.15
    ANT=apache-ant-$ant_version-bin.tar.xz
    wget --no-check-certificate https://mirror.hosting90.cz/apache/ant/binaries/$ANT
  fi
  tar -xf $ANT
  export ANT_HOME="`pwd`/apache-ant-$ant_version/"
  wget --no-check-certificate https://github.com/apache/tomcat-native/archive/1.2.24.tar.gz
  APR=apr-1.7.0.tar.gz
  if [ ! -e $APR ] ; then
    cp "/mnt/shared/jdk-images/apache/$APR" . || echo "local copy $APR  not found, will try to download"
  fi
  if [ ! -e $APR ] ; then
    wget --no-check-certificate https://mirror.hosting90.cz/apache/apr/$APR
  fi
  tar -xf 1.2.24.tar.gz
  tar -xf $APR
  export JAVA_HOME=/usr/lib/jvm/java
  pushd tomcat-native-1.2.24
    D="-Dbase.path=`pwd` -Dbase-maven.loc=https://repo.maven.apache.org/maven2"
    $ANT_HOME/bin/ant $D
    pushd native
      sh buildconf --with-apr=../../apr-1.7.0
      ./configure
      make 
    popd
    $ANT_HOME/bin/ant download $D
    $ANT_HOME/bin/ant test $D
    $ANT_HOME/bin/ant run-echo $D &
    P=$!
    sleep 5
    kill $P
    #ant run-ssl-server $D
    #ant run-local-server $D
  popd
popd
