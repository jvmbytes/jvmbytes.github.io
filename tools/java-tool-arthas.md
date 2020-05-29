<!---
markmeta_author: wongoo
markmeta_date: 2019-01-16
markmeta_title: java arthas 工具
markmeta_categories: 编程语言
markmeta_tags: java
-->

# java arthas 工具

```bash

curl -O https://alibaba.github.io/arthas/arthas-boot.jar

java -jar arthas-boot.jar

# a brief report on the current process will be shown as below,
$ dashboard

# print the stack of the thread with ID 1, which usually the main function thread.
$ thread 1 | grep 'main('

# Decompile Main Class with jad command
$ jad demo.MathGame

# view the return object of demo.MathGame#primeFactors
$ watch demo.MathGame primeFactors returnObj

```


## Basic
- help - display Arthas help
- cls - clear the screen
- cat - Concatenate and print files
- grep - Pattern searcher
- pwd - Return working directory name
- session - display current session information
- reset - reset all the enhanced classes. All enhanced classes will also be reset when Arthas server is closed by stop/shutdown
- version - print the version for the Arthas attached to the current Java process
- history - view command history
- quit/exit - exit the current Arthas session, without effecting other sessions
- stop/shutdown - terminate the Arthas server, all Arthas sessions will be destroyed
- keymap - keymap for Arthas keyboard shortcut


## JVM

- dashboard - dashboard for the system’s real-time data
- thread - show java thread information
- jvm - show JVM information
- sysprop - view/modify system properties
- sysenv — view system environment variables
- vmoption - view/modify the vm diagnostic options.
- logger - print the logger information, update the logger level
- getstatic - examine class’s static properties
- ognl - execute ongl expression
- mbean - show Mbean information
- heapdump - dump java heap in hprof binary format, like jmap


## class/classloader

- sc - check the info for the classes loaded by JVM
- sm - check methods info for the loaded classes
- jad - decompile the specified loaded classes
- mc - Memory compiler, compiles .java files into .class files in memory
- redefine - load external *.class files and re-define it into JVM
- dump - dump the loaded classes in byte code to the specified location
- classloader - check the inheritance structure, urls, class loading info for the specified class; using classloader to get the url of the resource e.g. java/lang/String.class

## monitor/watch/trace - related

- Attention: commands here are taking advantage of byte-code-injection, which means we are injecting some aspects into the current classes for monitoring and statistics purpose. Therefore when use it for online - troubleshooting in your production environment, you’d better explicitly specify classes/methods/criteria, and remember to remove the injected code by stop or reset.
- monitor - monitor method execution statistics
- watch - display the input/output parameter, return object, and thrown exception of specified method invocation
- trace - trace the execution time of specified method invocation
- stack - display the stack trace for the specified class and method
- tt - time tunnel, record the arguments and returned value for the methods and replay

