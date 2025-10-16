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

if [ "0$JDK_MAJOR" -ge 21   ]; then
 export JAVA_TOOL_OPTIONS="$JAVA_TOOL_OPTIONS --add-opens=java.base/sun.nio.ch=ALL-UNNAMED"
fi
if [ "0$JDK_MAJOR" -eq 8   ]; then
  echo "!skipped!  java.lang.NoSuchMethodError: java.nio.ByteBuffer.flip()Ljava/nio/ByteBuffer;"
  exit
fi
JNR_LIVE_PROJECTS="jnr-enxio:0.32.18"
patch=true
if [ "0$JDK_MAJOR" -eq 17 ] ; then
  JNR_LIVE_PROJECTS="jnr-enxio:0.32.6"
  patch="true"
elif [ "0$JDK_MAJOR" -eq 11 ] ; then
  JNR_LIVE_PROJECTS="jnr-enxio:0.24"
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
    if [ "x$PURGE_MVN" == "xtrue" ] ; then  $EX_MVN $MVOPTS dependency:purge-local-repository -DreResolve=false ; fi
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
    fi
#    sed "s;<maven.compiler.source>.*;<maven.compiler.source>$JDK_MAJOR</maven.compiler.source>;" -i pom.xml
#    sed "s;<maven.compiler.target>.*;<maven.compiler.target>$JDK_MAJOR</maven.compiler.target>;" -i pom.xml
    $EX_MVN $MVOPTS -Dmaven.javadoc.skip=true clean install
  popd
done

