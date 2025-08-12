#!/bin/bash
set -exo pipefail

if [ "0$JDK_MAJOR" -gt 8   ]; then
  echo "!skipped!  newer wildfly needed for jdk newer then 8"
  exit
fi

MVOPTS="--batch-mode"
if [ "x$EX_MVN" == "x" ] ; then
 EX_MVN=mvn
fi


function addIgnoreImport() {
  if ! grep -e "import org.junit.Ignore" "${1}" ; then #do not create duplicated imports
    sed "s/import org.junit.Test;/import org.junit.Test;import org.junit.Ignore;/" -i "${1}"
  fi
}

ignoredTests=0
function ignoreMethod() {
  local file=$(find -type f | grep "${2}.java$")
  grep    -e "${1}[(]" "${file}" #check
  # do not inject ignore import if nothing will be sed
  addIgnoreImport "${file}"
  sed "s/${1}[(]/@Ignore ${1}(/g" -i "${file}"
  grep -e "@Ignore ${1}[(]" "${file}" #check
  let ignoredTests=$ignoredTests+1
}

# for generating patches
GIT=git
#GIT=echo

# both seesm to be failing in same way
#VERSION=1.0.12.Final # last 1.0 on Oct 26, 2020
VERSION=1.1.3.Final  # last 1.1 on Sep 30, 2020
rm -rf wildfly8-openssl
mkdir  wildfly8-openssl
pushd  wildfly8-openssl
  wget https://github.com/wildfly-security/wildfly-openssl/archive/refs/tags/${VERSION}.tar.gz
  tar -xf ${VERSION}.tar.gz
  # generally the testsuite is poorly designed. see SSLTestUtils.java
  # it reuses still same port, and do not release it in finally clausule,
  # so although it uses setReuseAddress, any first fail will kill all subsequent tests
  # as the port seems to survive junit's vm
  pushd wildfly-openssl-${VERSION}
  $GIT init
  $GIT add *
  $GIT commit . -m "initial commit"
    # this test fails with different crypto policies
    ignoreMethod "public void testNoExplicitEnabledProtocols" "BasicOpenSSLEngineTest"
    if [ "x$OTOOL_OS_VERSION" = "x7" -a "x$OTOOL_OS_NAME" = "xel" ] ; then
        # tls v 1.0 is being  removed
       ignoreMethod "public void testMultipleEnabledProtocolsWithClientProtocolWithinEnabledRange" "BasicOpenSSLEngineTest"
    fi
      # this test fails with different crypto policies and there is no JNI at all. However to find wy it fials is interesting TODO.
      ignoreMethod "public void testCipherSuiteConverter" "SslCiphersTest"
    patch -p1 <<EOF
--- a/java/src/test/java/org/wildfly/openssl/SSLTestUtils.java
+++ a/java/src/test/java/org/wildfly/openssl/SSLTestUtils.java
@@ -41,8 +41,8 @@
 public class SSLTestUtils {
 
     public static final String HOST = System.getProperty("org.wildfly.openssl.test.host", "localhost");
-    public static final int PORT = Integer.parseInt(System.getProperty("org.wildfly.openssl.test.port", "7677"));
-    public static final int SECONDARY_PORT = Integer.parseInt(System.getProperty("org.wildfly.openssl.test.secondary.port", "7687"));
+    public static final int PORT = Integer.parseInt(System.getProperty("org.wildfly.openssl.test.port", ""+findFreePort()));
+    public static final int SECONDARY_PORT = Integer.parseInt(System.getProperty("org.wildfly.openssl.test.secondary.port", ""+findFreePort()));
 
     private static KeyStore loadKeyStore(final String name) throws IOException {
         final InputStream stream = BasicOpenSSLEngineTest.class.getClassLoader().getResourceAsStream(name);
@@ -165,6 +165,17 @@
         return out.toByteArray();
     }
 
+    public static int findFreePort() {
+        try (ServerSocket socket = new ServerSocket(0)) {
+            int i = socket.getLocalPort();
+            socket.close();
+            Thread.sleep(1000);
+            return i;
+        } catch (Exception e) {
+        }
+        return -1;
+    }
+
     public static ServerSocket createServerSocket() throws IOException {
         return createServerSocket(PORT);
     }
EOF
    $GIT commit . -m "excluded some tests"
    patch -p1 <<EOF
diff --git a/java/src/test/java/org/wildfly/openssl/AbstractOpenSSLTest.java b/java/src/test/java/org/wildfly/openssl/AbstractOpenSSLTest.java
index 56d2357..f67442a 100644
--- a/java/src/test/java/org/wildfly/openssl/AbstractOpenSSLTest.java
+++ b/java/src/test/java/org/wildfly/openssl/AbstractOpenSSLTest.java
@@ -18,6 +18,7 @@
 package org.wildfly.openssl;
 
 import org.junit.BeforeClass;
+import org.junit.Before;
 
 /**
  * @author Stuart Douglas
@@ -26,6 +27,12 @@ public class AbstractOpenSSLTest {
 
     private static boolean first = true;
 
+    @Before
+    public void reinitPorts(){
+        SSLTestUtils.resetPort();
+        SSLTestUtils.resetSecondaryPort();
+    }
+
     @BeforeClass
     public static void setup() {
         if(first) {
diff --git a/java/src/test/java/org/wildfly/openssl/SSLTestUtils.java b/java/src/test/java/org/wildfly/openssl/SSLTestUtils.java
index f7a4261..8c4aa3d 100644
--- a/java/src/test/java/org/wildfly/openssl/SSLTestUtils.java
+++ b/java/src/test/java/org/wildfly/openssl/SSLTestUtils.java
@@ -41,8 +41,24 @@ import javax.net.ssl.TrustManagerFactory;
 public class SSLTestUtils {
 
     public static final String HOST = System.getProperty("org.wildfly.openssl.test.host", "localhost");
-    public static final int PORT = Integer.parseInt(System.getProperty("org.wildfly.openssl.test.port", ""+findFreePort()));
-    public static final int SECONDARY_PORT = Integer.parseInt(System.getProperty("org.wildfly.openssl.test.secondary.port", ""+findFreePort()));
+    public static int PORT = initPort();
+    public static int SECONDARY_PORT = initSecondaryPort();
+
+    private static int initPort() {
+        return Integer.parseInt(System.getProperty("org.wildfly.openssl.test.port", ""+findFreePort()));
+    }
+
+    private static int initSecondaryPort() {
+        return Integer.parseInt(System.getProperty("org.wildfly.openssl.test.secondary.port", ""+findFreePort()));
+    }
+
+    public static void resetPort(){
+        PORT=initPort();
+    }
+
+    public static void resetSecondaryPort(){
+        SECONDARY_PORT=initSecondaryPort();
+    }
 
     private static KeyStore loadKeyStore(final String name) throws IOException {
         final InputStream stream = BasicOpenSSLEngineTest.class.getClassLoader().getResourceAsStream(name);
EOF
    $GIT commit . -m "make port random/free for each method"
    # it is better to set the libssl and libcrypto on our own
    # the wildfly-openssl search is just tragic, and the excception throwns out of it are very missleading
    # eg "not found ssl library" may be thrown from findCryptoLibray (where findSSL have passed fine)
    libssl=$( ls  $(find /usr/lib /usr/lib64 -type l  | grep libssl | grep -v -e .hmac -e .pc ) | head -n 1) ;
    libcrypt=$( ls  $(find /usr/lib /usr/lib64 -type l  | grep libcrypto | grep -v -e .hmac -e .pc ) | head -n 1) ;

    allEnabledSecurity=`mktemp`
    echo 'jdk.tls.disabledAlgorithms='> "$allEnabledSecurity"
    useAllEnabledSecurity="-Djava.security.properties=$allEnabledSecurity"

    #if problems with not freed port persists, run in loop of 2-3 mvn test, and return nonzero only if all fails
    if [ "x$OTOOL_OS_NAME" = "xel" -a "x$OTOOL_OS_VERSION" = "x7" ] ; then
      scl enable rh-maven36 -- mvn $MVOPTS $clean install $useAllEnabledSecurity -Dorg.wildfly.openssl.path.ssl=$libssl -Dorg.wildfly.openssl.path.crypto=$libcrypt
    else
      $EX_MVN $MVOPTS clean install $useAllEnabledSecurity -Dorg.wildfly.openssl.path.ssl=$libssl -Dorg.wildfly.openssl.path.crypto=$libcrypt
    fi
    if which update-crypto-policies 2>/dev/null 1>/dev/null ; then
      update-crypto-policies --show
    fi
  popd
popd
