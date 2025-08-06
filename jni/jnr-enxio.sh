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
sub=jnr-enxio
rm -rf $sub
mkdir  $sub
pushd  $sub

if [ "x$OTOOL_JDK_VERSION" == "x" -o "0$OTOOL_JDK_VERSION" -ge 21 ] ; then
  JNR_LIVE_PROJECTS="jnr-enxio:0.32.18"
  patch="true"
elif [ "0$OTOOL_JDK_VERSION" -ge 16 ] ; then
  JNR_LIVE_PROJECTS="jnr-enxio:0.32.6"
  patch="true"
else
  JNR_LIVE_PROJECTS="jnr-enxio:0.28"
  patch="false"
fi

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
    if [ "x$patch" = "xtrue" ] ; then
patch -p0 << EOF
--- pom.xml
+++ pom.xml
@@ -64,6 +64,13 @@
 
   <build>
     <plugins>
+      <plugin>
+        <artifactId>maven-surefire-plugin</artifactId>
+        <version>3.0.0-M5</version>
+        <configuration>
+        <argLine>--add-opens java.base/java.io=ALL-UNNAMED</argLine>
+        </configuration>
+      </plugin>
       <plugin>
         <groupId>org.apache.felix</groupId>
         <artifactId>maven-bundle-plugin</artifactId>
EOF
    set +x
      jdkMajor=8
	  for x in `seq 30 -1 11` ; do
        if $java --version 2>&1 | grep "[- ]$x[.][0-9]\+[.][0-9]\+" ; then jdkMajor=$x ; break ; fi
      done
    set -x
    sed "s;<maven.compiler.source>.*;<maven.compiler.source>$jdkMajor</maven.compiler.source>;" -i pom.xml
    sed "s;<maven.compiler.target>.*;<maven.compiler.target>$jdkMajor</maven.compiler.target>;" -i pom.xml
    fi
    $EX_MVN $MVOPTS -Dmaven.javadoc.skip=true clean install
  popd
done

