<!---
markmeta_author: 望哥
markmeta_date: 2018-08-30
markmeta_title: JVM架构
markmeta_categories: java
markmeta_tags: java,jvm

-->

版本:
- 2018-08-30: 初始版本

# 1. JVM架构
![](http://blog.sisopipo.com/media/files/jvm/jvm_arch_en.png)

## 1.1 类加载器（ClassLoader）
- 在JVM启动时或者在类运行时将需要的class加载到JVM中。

## 1.2 执行引擎
- JVM模拟运行的运算引擎；
- 翻译执行class文件中包含的字节码指令；

有两种翻译的方式：
- 一句话一句话翻译。也就是解释执行。将程序计算器中指向的待执行的java字节码翻译为cpu可以运行的机器指令。
- 一次性翻译。即编译执行。通过JIT(just in time)一次性将所有的字节码翻译完成。

## 1.3 内存区（也叫运行时数据区）

在JVM运行的时候操作所分配的内存区。分为6个部分: `Method Area、Run-Time Constant Pool、Heap、VM Stack、PC Register、Native Method Stack`

## 1.4 本地库接口，本地方法库

操作系统所有，用于处理jvm的native code和通过jit编译后的本地代码。


# 2. JVM内存
  
## 2.1 方法区(Method Area)

- 多线程共享；
- 存储class结构信息(版本、字段、方法、接口、class文件常量池、静态变量、JIT处理后的数据等)。
- class文件常量池存放两大类常量：字面量(Literal)和符号引用量(Symbolic References)

## 2.2 运行时常量池（Run-Time Constant Pool）

- 多线程共享；
- Hotspot JVM 运行时常量池是方法区的一部分；
- 类加载后会将class文件常量池中的字面量和符号引用量加入运行时常量池；
- String.intern() 检查运行时常量池中是否存在String并返回池里的字符串引用；若池中不存在，则将其加入池中，并返回其引用。

## 2.3 堆(Heap)

- 多线程共享；
- 存储java实例；
- GC的主要区域;

## 2.4 虚拟机栈(VM Stack)
- 栈是线程私有的；
- 一个线程一个栈；
- 栈中包含多个栈帧(Frame)，每运行一个方法就创建一个栈帧，用于存储局部变量表、操作栈、方法返回值等；
- 方法从调用直至执行完成，对应栈帧在栈中入栈到出栈；
- 栈帧(Frame)可以在Heap中分配内存；
- 栈的内存可以不连续的；
- 栈溢出错误`StackOverflowError`
- 设置可动态扩展栈空间但内存不足报错`OutOfMemoryError`


## 2.5 程序计数器(PC Register)

- 线程私有的；
- 保存当前线程正在执行的字节码指令地址；
- 保证中断线程切换回来后还能恢复到原先状态；

## 2.6 本地方法栈(Native Method Stack)
- 线程私有的；
- JNI native方法;

# 3. 参考:
- [The Java® Virtual Machine Specification Java SE 10 Edition](https://docs.oracle.com/javase/specs/jvms/se10/html/index.html)



