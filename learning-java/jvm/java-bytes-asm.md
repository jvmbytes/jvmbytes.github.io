<!---
markmeta_author: wongoo
markmeta_date: 2019-01-16
markmeta_title: java ASM 字节码操作
markmeta_categories: java
markmeta_tags: java,asm
-->

# java ASM 字节码操作

ASM库的目的是用于生成、转换和分析编译过的Java类，并以字节数组的形式进行表示。

## 模型
ASM库提供了两种用于生成和转换编译过的类的API：
- 基于事件的表达方式，
- 基于对象(Tree API)的表达方式。

基于事件的模型中，一个类表达为一个事件序列，每个事件代表类的一个元素，例如其头部、一个域、一个方法调用、一个指令等。基于事件的API定义了可能的事件集合以及它们发生必须遵循的顺序，并且提供了一个类解析器在每解析到一个元素就生成一个事件，另一个类生成器根据这个事件序列生成编译过的类。

一个类的基于对象的表达方式是一个对象树，树中的每个对象代表类的一部分，例如类自身、一个域、一个方法、一个指令等。并且每个对象都含有用于指向表示其组成成分的对象（objects）的引用。对于代表一个类的事件序列和代表同一个类的一个对象树，基于对象的API提供了一种在两者间进行相互转换的方式。换言之，就是基于对象的API是建立在基于事件的API之上的。

这两种API可以和XML文档的两种API作类比，如SAX和DOM。没有最好的API，只有最适用的API，它们都有其优缺点：
- 基于事件的API更快，需要更少的内存，因为不需要创建对象树。
- 然而适用基于事件的API进行类转换更困难，因为在任意给定时刻，基于事件的API中仅有类的一个元素可用（该元素对应当前事件）。而基于对象的API中，整个类都是可用的。

## 架构（Architecture）
ASM应用有一个较强的架构。事实上，基于事件的API是围绕事件生产者（类解析器）、事件消费者（类写入器）和各种预定义的事件过滤器进行组织的，其中用户可以自定义这些组件。
因此使用其API有两个步骤：
- 组装事件生产者、过滤器和消费者
- 启动事件生产者，开始运行生成或转换过程

基于对象的API也有一个架构：**事实上，在对象树上进行操作的类生成器或转换器可以进行组合，它们间的链接代表了转换的顺序。**


- [Java字节码工程：ASM介绍](https://www.jastrelax.com/java/bytecode/2018-07-17-asm-introduction/), Java字节码操作指令，虚拟机栈，vistor模式，ASM API范例
- [Java字节码工程：ASM开发指南1-概述](https://www.jastrelax.com/java/bytecode/2018-07-21-asm-develop-guide-introduction/), ASM 概述
- [Java字节码工程：ASM开发指南2-核心API](https://www.jastrelax.com/java/bytecode/2018-07-28-asm-develop-guide-core-api/), 详述jvm字节码，以及ASM主要API
- [ASM JavaDoc](https://asm.ow2.io/javadoc/overview-summary.html)







