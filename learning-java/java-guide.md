<!---
markmeta_author: wongoo
markmeta_date: 2019-01-16
markmeta_title: java 学习资料
markmeta_categories: java
markmeta_tags: java
-->

# java 学习资料

## 面试
- [java学习手册（面试通关指南）](https://github.com/Snailclimb/JavaGuide)

## JVM:
- [Java 虚拟机规范（第11版）](https://github.com/waylau/java-virtual-machine-specification), 中文版
- [认识 .class 文件的字节码结构](https://www.jianshu.com/p/e5062d62a3d1), class类文件结构，魔数，文件版本，常量池，访问标志，类索引，父类索引，接口索引，字段表集合，方法表集合，属性表集合
- [理解 JVM 中的类加载机制](https://www.jianshu.com/p/0cf9aa251921), 类生命周期，主动引用，被动引用；加载-验证-准备-解析-初始化； 类加载器； 双亲委派模型；
- [虚拟机字节码执行引擎](https://www.jianshu.com/p/58f876f2e8b8), 运行时栈帧，方法调用，
基于栈的字节码解释执行引擎；
- [java 字节码指令列表](https://en.wikipedia.org/wiki/Java_bytecode_instruction_listings)

## ASM:
- [访问者模式和 ASM](https://www.jianshu.com/p/e4b8cb0b3204), 访问者模式说明； ASM的vistor模式API
- [ASM 库的介绍和使用](https://www.jianshu.com/p/905be2a9a700), ASM API及使用范例

## 并发
- [Java内存模型和线程安全](http://www.importnew.com/21245.html)


## 查看java版本

```bash
java -version

# 查看支持的选项
java -XX:+AggressiveOpts -XX:+UnlockDiagnosticVMOptions -XX:+UnlockExperimentalVMOptions -XX:+PrintFlagsFinal -version

# 查看类加载卸载
-verbose:clas -XX:+TraceClassLoading -XX:+TraceClassUnloading
```