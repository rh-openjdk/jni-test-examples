set -exo pipefail
MVOPTS="--batch-mode"
if [ "x$EX_MVN" == "x" ] ; then
 EX_MVN=mvn
fi

rm -rf lmdbjava

if [ "x$OTOOL_OS_NAME" = "xel" -a "x$OTOOL_OS_VERSION" = "x7" ] ; then
  MVN="scl enable rh-maven36 -- mvn $MVOPTS"
else
  MVN="$EX_MVN $MVOPTS"
fi

mkdir  lmdbjava
pushd  lmdbjava
if [ "0$JDK_MAJOR" -le 12 ] ; then
  git clone https://github.com/Karm/native.git # karm's fork, for karm's lmdb
  pushd native
    git checkout  secondaryArches
    git clone https://github.com/LMDB/lmdb.git
    pushd lmdb
      git checkout LMDB_0.9.24
    popd
    if [ "x$PURGE_MVN" == "xtrue" ] ; then  $EX_MVN $MVOPTS dependency:purge-local-repository -DreResolve=false ; fi
    $MVN clean install
  popd
  git clone https://github.com/Karm/lmdbjava.git # karm's fork; much more tuning on non-default pages
  pushd lmdbjava
    git checkout  secondaryArches
    if [ "$OS_ARCH" == "x86_64"  -a `uname -o` = "GNU/Linux" ] ; then
      # use the freshly built one from above, fro aarch and ppc it is hardoced in poms, for other we use upstream
      patch -p1 <<EOF
--- a/pom.xml
+++ b/pom.xml
@@ -85,7 +85,7 @@
     <dependency>
       <groupId>org.lmdbjava</groupId>
       <artifactId>lmdbjava-native-linux-x86_64</artifactId>
-      <version>0.9.24-1</version>
+      <version>0.9.24-2-SNAPSHOT</version>
       <optional>true</optional>
     </dependency>
     <dependency>
EOF
    fi
    export PAGE_SIZE=$(getconf PAGESIZE)
    #this should also: if [ "x$PURGE_MVN" == "xtrue" ] ; then  $EX_MVN $MVOPTS dependency:purge-local-repository -DreResolve=false ; fi
    # but we would delete 0.9.24-2-SNAPSHOT. The clean is fixing a cornercase anyway, so keeping as it is.
    $MVN clean install
  popd
else
  git clone https://github.com/lmdbjava/lmdbjava.git
  if ! which zig ; then 
    sudo dnf install -y zig;
  fi
  pushd lmdbjava
    sh cross-compile.sh
    git checkout lmdbjava-0.9.1
    $MVN clean install
  popd
fi
popd

