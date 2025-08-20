set -exo pipefail

if [ "x$OS_NAME" == "xrhel" -a "0$OS_VERSION_MAJOR" -le "7" ]; then
  echo "!skipped!  rhel7 and older are to old "
  exit
fi

MVOPTS="--batch-mode"
if [ "x$EX_MVN" == "x" ] ; then
 EX_MVN=mvn
fi

rm -rf lmdbjava

MVN="$EX_MVN $MVOPTS"

setZig() {
  local larch=`uname -m`
  if [ "x$larch" == "xppc64le" ] ; then
    larch=powerpc64le
  fi
  local ldir=zig-"$larch"-linux-0.15.0-dev.1380+e98aeeb73
  echo "Setting zig from cmdline: $ldir"
  local lname="$ldir.tar.xz"
  curl -k -f -L -O "https://ziglang.org/builds/$lname"
  tar -xf $lname
  export PATH="`pwd`/$ldir:$PATH"
}


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
    sudo dnf install -y zig || setZig
  fi
  pushd lmdbjava
    bash cross-compile.sh
    git checkout lmdbjava-0.9.1
    if [ "0$JDK_MAJOR" -ge 25 ] ; then
      ## jacoco prints a lot of errors,but it seesm to passe same 222 tests as with jdk21
      $MVN clean install -Dfmt.skip
    else
      $MVN clean install
    fi
  popd
fi
popd

