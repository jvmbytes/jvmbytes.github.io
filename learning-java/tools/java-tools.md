<!---
markmeta_author: wongoo
markmeta_date: 2019-08-21
markmeta_title: java 分析工具
markmeta_categories: java
markmeta_tags: java
-->

# java 分析工具

## jmap 内存分析

查看整个JVM内存状态: jmap -heap [pid]

要注意的是在使用CMS GC 情况下，jmap -heap的执行有可能会导致JAVA 进程挂起

查看JVM堆中对象详细占用情况: jmap -histo [pid]

导出整个JVM 中内存信息: jmap -dump:format=b,file=文件名 [pid]

java自带内存分析工具: jhat -J-Xmx1024M [file]

eclipse Memory Analyzer, Eclipse 提供的一个用于分析JVM 堆Dump文件的插件。借助这个插件可查看对象的内存占用状况，引用关系，分析内存泄露等。
http://www.eclipse.org/mat/

## jstack 线程分析

导出线程信息:
jstack [pid] > jstack.log 


## jstat 性能分析

观察到classloader，compiler，gc相关信息.

jstat [options] [pid]

options:
* -class：统计class loader行为信息 
* -compile：统计编译行为信息 
* -gc：统计jdk gc时heap信息 
* -gccapacity：统计不同的generations（不知道怎么翻译好，包括新生区，老年区，permanent区）相应的heap容量情况 
* -gccause：统计gc的情况，（同-gcutil）和引起gc的事件 
* -gcnew：统计gc时，新生代的情况 
* -gcnewcapacity：统计gc时，新生代heap容量 
* -gcold：统计gc时，老年区的情况 
* -gcoldcapacity：统计gc时，老年区heap容量 
* -gcpermcapacity：统计gc时，permanent区heap容量 
* -gcutil：统计gc时，heap情况 

输出参数内容 
* S0  — Heap上的 Survivor space 0 区已使用空间的百分比 
* S0C：S0当前容量的大小 
* S0U：S0已经使用的大小 
* S1  — Heap上的 Survivor space 1 区已使用空间的百分比 
* S1C：S1当前容量的大小 
* S1U：S1已经使用的大小 
* E   — Heap上的 Eden space 区已使用空间的百分比 
* EC：Eden space当前容量的大小 
* EU：Eden space已经使用的大小 
* O   — Heap上的 Old space 区已使用空间的百分比 
* OC：Old space当前容量的大小 
* OU：Old space已经使用的大小 
* P   — Perm space 区已使用空间的百分比 
* OC：Perm space当前容量的大小 
* OU：Perm space已经使用的大小 
* YGC — 从应用程序启动到采样时发生 Young GC 的次数 
* YGCT– 从应用程序启动到采样时 Young GC 所用的时间(单位秒) 
* FGC — 从应用程序启动到采样时发生 Full GC 的次数 
* FGCT– 从应用程序启动到采样时 Full GC 所用的时间(单位秒) 
* GCT — 从应用程序启动到采样时用于垃圾回收的总时间(单位秒)，它的值等于YGC+FGC 

