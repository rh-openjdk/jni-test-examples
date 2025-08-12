# jni-test-examples
Set of god, java projects using native code, used to exercise JDK's JNI.
Each run is tuned to serve as QA.
It is useing ancient [run-folder-as-tests](https://github.com/rh-openjdk/run-folder-as-tests).
Running to long? Reduce default reruns (5) to 1: `export RFAT_RERUNS=1`
Want to run just subset? Set second parameter as regex, or export WHITELIST/BLACKLIST.
If you would run individual test manually, `export JDK_MAJOR=` to numerical version of jdk. Eg 8 or 21...
Such variables may multiply.

# deps
lmdbjava for jdk21 and up needs `zig`. 

# Fedora 41 x86_64/aarch64/ppc64/s390
| suite/jdk              | jdk8          | jdk11         | jdk17         | jdk21         | jdk25         |
| -----------------------| ------------- | ------------- | ------------- | ------------- | ------------- |
|jnr-a64asm              | ok///         | ok///         | ok///         | ok///         | ok///         |
|jnr-constants           | ok///         | ok///         | ok///         | ok///         | ok///         |
|jnr-enxio               |   s[2]        | ok///         | ok///         |  s[1]         |  s[1]         |
|jnr-ffi                 | ok///         | ok///         | ok///         | ok///         | ok///         |
|jnr-jffi                | ok///         | ok///         | ok///         | ok///         | ok///         |
|jnr-posix               | ok///         | ok///         | ok///         | ok///         | ok///         |
|jnr-process             | ok///         | ok///         | ok///         | ok///         | ok///         |
|jnr-unixsocket          | ok///         | ok///         | ok///         | ok///         | ok///         |
|jnr-x86asm              | ok///         | ok///         | ok///         | ok///         | ok///         |
|lmdbjava                | ok[3]///      | ok[3]///      | ok///         | ok///         | ok///         |
|scala_partest_natives   | ok[3]///      | ok[3]///      | ok[3]///      | ok[3]///      | ok[3]///      |
|tomcat-native           | ok////        | ok///         | ok///         | ok///         | ok///         |
|wildfly-openssl         |   s[4]        | ok///         | ok///         | ok///         | ok///         |

[1] !skipped!  NativeTest.setBlocking:35 » InaccessibleObject Unable to make field private fi...</br>
	   -> todo fix in upstream

[2] !skipped!  java.lang.NoSuchMethodError: java.nio.ByteBuffer.flip()Ljava/nio/ByteBuffer;</br>
   -> no longer fixable

[3] from forks (lmbdjava unmergable, scala hopes)

[4] !skipped!  older wildfly needed for jdk8</br>
   -> todo, fix here hopefully

# window x86_64/aarch64
Unluckily I do not have windows arround
