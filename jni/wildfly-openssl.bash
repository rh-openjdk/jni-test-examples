#!/bin/bash
set -exo pipefail

if [ -z "$VERSION"   ]; then
  echo "This is shared runner for newer wildfly openssl. VERSION must be set"
  exit 1
fi

if [ -z "$NATIVES_VERSION"   ]; then
  echo "This is shared runner for newer wildfly openssl. NATIVES_VERSION must be set"
  exit 1
fi


MVOPTS="--batch-mode"
if [ "x$EX_MVN" == "x" ] ; then
 EX_MVN=mvn
fi

DISABLE_testNoExplicitEnabledProtocols="true"
DISABLE_testMultipleEnabledProtocolsWithClientProtocolWithinEnabledRange="true"
DISABLE_testCipherSuiteConverter="true"
DISABLE_testAvailableProtocolsWithTLS13CipherSuites="true"

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
#GIT=git
GIT=echo

rm -rf wildfly-openssl
mkdir  wildfly-openssl
pushd  wildfly-openssl
  wget https://github.com/wildfly-security/wildfly-openssl-natives/archive/refs/tags/${NATIVES_VERSION}.tar.gz
  tar -xf ${NATIVES_VERSION}.tar.gz
  pushd wildfly-openssl-natives-${NATIVES_VERSION}
    $EX_MVN $MVOPTS clean install
  popd
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
    if [ "$DISABLE_testNoExplicitEnabledProtocols" = "true" ] ; then
      # this test fails with different crypto policies
      ignoreMethod "public void testNoExplicitEnabledProtocols" "BasicOpenSSLEngineTest"
    fi
    if [  "$DISABLE_testMultipleEnabledProtocolsWithClientProtocolWithinEnabledRange" = "true"  ] ; then
      # tls v 1.0 is being  removed
      ignoreMethod "public void testMultipleEnabledProtocolsWithClientProtocolWithinEnabledRange" "BasicOpenSSLEngineLegacyProtocolsTest"
    fi
    if [  "$DISABLE_testCipherSuiteConverter" = "true"  ] ; then
      # this test fails with different crypto policies and there is no JNI at all. However to find wy it fials is interesting TODO.
      ignoreMethod "public void testCipherSuiteConverter" "SslCiphersTest"
    fi
    if [  "$DISABLE_testAvailableProtocolsWithTLS13CipherSuites" = "true"  ] ; then
    # tls 1.3
      ignoreMethod  "public void testAvailableProtocolsWithTLS13CipherSuites"  "SslCiphersTest"
    fi
    if [ $ignoredTests -gt 0 ] ; then
      $GIT  commit . -m "disbaled $ignoredTests tests"
    else
      echo "No test ignored"
    fi
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
