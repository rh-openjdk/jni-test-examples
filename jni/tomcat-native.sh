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
function autoauto() {
  autoupdate 
  autoreconf --install
  autoupdate
  autoconf
}

pushd  tomcat-native
  sudo $III install -y apr apr-devel  || true # usally not preinstalled
  sudo $III install -y openssl openssl-devel || true # usually we should have it preinstalled
  sudo $III install -y autoconf || true # usually we should have it preinstalled
  sudo $III install -y redhat-rpm-config || true # usually we should have it preinstalled
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
  APR=apr-1.7.6
  APR_FILE=${APR}.tar.gz
  if [ ! -e $APR ] ; then
    cp "/mnt/shared/jdk-images/apache/$APR_FILE" . || echo "local copy $APR  not found, will try to download"
  fi
  if [ ! -e $APR_FILE ] ; then
    wget --no-check-certificate https://dlcdn.apache.org//apr/$APR_FILE
  fi
  tar -xf $APR_FILE
  tomcat_native_version=1.2.24
  tomcat_native=${tomcat_native_version}.tar.gz
  wget --no-check-certificate https://github.com/apache/tomcat-native/archive/$tomcat_native
  tar -xf $tomcat_native
  pushd tomcat-native-${tomcat_native_version}
    D="-Dbase.path=`pwd` -Dbase-maven.loc=https://repo.maven.apache.org/maven2"
    $ANT_HOME/bin/ant $D
    pushd native
      autoauto
      sh buildconf --with-apr=`readlink -f ../../$APR`
      autoauto
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
