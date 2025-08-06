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
# really mvn assemble coul fail on default values
export MAVEN_OPTS="-Xmx1500m"

sub=jnr-unixsocket
rm -rf $sub
mkdir  $sub
pushd  $sub

JNR_LIVE_PROJECTS="jnr-unixsocket:0.33"

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

if [ "x$OTOOL_ARCH" = "xppc64le" ] ; then
    # https://github.com/jnr/jnr-unixsocket/issues/88 issue in java ffi, ffi or unixsocket itself on ppc64le
    f=`find -type f | grep CredentialsFunctionalTest.java$`
    sed "s/import org.junit.Test;/import org.junit.Test;import org.junit.Ignore;/" -i $f
    sed "s/public void credentials/@Ignore public void credentials/g" -i $f
fi

patch -p1 <<EOF
--- a/pom.xml
+++ b/pom.xml
@@ -110,35 +110,7 @@
       </plugin>
 
       <!-- run spotbugs check -->
-      <plugin>
-        <groupId>com.github.spotbugs</groupId>
-        <artifactId>spotbugs-maven-plugin</artifactId>
-        <version>3.1.12.2</version>
-        <dependencies>
-          <!-- overwrite dependency on spotbugs if you want to specify the version of spotbugs -->
-          <dependency>
-            <groupId>com.github.spotbugs</groupId>
-            <artifactId>spotbugs</artifactId>
-            <version>4.0.0-beta4</version>
-          </dependency>
-        </dependencies>
-         <executions>
-          <execution>
-            <phase>process-test-classes</phase>
-            <goals>
-              <goal>check</goal>
-            </goals>
-          </execution>
-        </executions>
-        <configuration>
-          <effort>Max</effort>
-          <includeTests>false</includeTests>
-          <relaxed>true</relaxed>
-          <spotbugsXmlOutput>true</spotbugsXmlOutput>
-          <failOnError>false</failOnError>
-        </configuration>
-      </plugin>
-
+<!-- removed, el7 have to old maven -->
       <!-- run PMD check -->
       <plugin>
         <artifactId>maven-pmd-plugin</artifactId>
EOF
    set +x
      jdkMajor=8
	  for x in `seq 30 -1 11` ; do
        if $java --version 2>&1 | grep "[- ]$x[.][0-9]\+[.][0-9]\+" ; then jdkMajor=$x ; break ; fi
      done
    set -x
    if [ $jdkMajor -ge 17 ] ; then
      sed "s/2.3.7/6.0.0/g" -i pom.xml #fixme, upstream, javadoc fix
    fi
    if [ $jdkMajor -eq 11 ] ; then
      sed "s/2.3.7/5.1.9/g" -i pom.xml #fixme, upstream, javadoc fix
    fi
    sed "s/1.7/$jdkMajor/g" -i pom.xml #fixme, upstream
    # on ppc64le, mvn assembly sometimes fails on eom. If it will persists,  mvn isntall failureless without tests , and mvn tests later
    echo "mvn install"
    $EX_MVN $MVOPTS -Dmaven.javadoc.skip=true clean install || true
    echo "mvn test"
    $EX_MVN $MVOPTS test
  popd
done

