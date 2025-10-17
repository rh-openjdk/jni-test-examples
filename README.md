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

# Fedora 41/ubuntu 24 x86_64
| suite/jdk              | jdk8       | jdk11      | jdk17      | jdk21      | jdk25      |
| -----------------------| ---------- |----------- | -----------| ---------- | ---------- |
|jnr-a64asm              | ok         | ok         | ok         | ok         | ok         |
|jnr-constants           | ok         | ok         | ok         | ok         | ok         |
|jnr-enxio               | s[2]       | ok         | ok         | ok[1]      | ok[1]      |
|jnr-ffi                 | ok         | ok         | ok         | ok         | ok         |
|jnr-jffi                | ok         | ok         | ok         | ok         | ok         |
|jnr-posix               | ok         | ok         | ok         | ok         | ok         |
|jnr-process             | ok         | ok         | ok         | ok         | ok         |
|jnr-unixsocket          | ok         | ok         | ok         | ok         | ok         |
|jnr-x86asm              | ok         | ok         | ok         | ok         | ok         |
|lmdbjava                | ok[3]      | ok[3]      | ok         | ok         | ok         |
|scala_partest_natives   | ok[3]      | ok[3]      | ok[3]      | ok[3]      | ok[3]      |
|tomcat-native           | ok         | ok         | ok         | ok         | ok         |
|wildfly-openssl         | s[4]       | ok         | ok         | ok         | ok         |
|wildfly8-openssl        | s[6]       | s[5]       | s[5]       | s[5]       | s[5]       |

[1] --add-opens to fix NativeTest.setBlocking:35 » InaccessibleObject Unable to make field private fi...</br>
	   -> todo fix in upstream. Similar issue also for 17 on el7

[2] !skipped!  java.lang.NoSuchMethodError: java.nio.ByteBuffer.flip()Ljava/nio/ByteBuffer;</br>
   -> no longer fixable

[3] from forks (lmbdjava unmergable, scala hopes)

[4] !skipped!  older wildfly needed for jdk8</br>
   -> todo, fix here hopefully
[5] !skipped!  newer wildfly needed for jdk newer then 8</br>
   -> intyetnionally jdk8 onlyu
[6] this test currently fails everywhere - the goal is to investigate if there is any environemnt where it can pass</br>
   -> s!skipped! klnown to fail on newer ubuntu/fedora

# On top of that:
## el9 and up
 * Excluded wildfly8-openssl

## el7
 * Excluded jnr-posix SpawnTest.inputFile 
 * Excluded wildfly-openssl and lmdbjava

## ppc64le
Excluded jnr-posix LinuxPOSIXTest.testMessageHdrMultipleControl
 * https://github.com/jnr/jnr-posix/issues/178

# window x86_64/aarch64
Unluckily I do not have windows arround
