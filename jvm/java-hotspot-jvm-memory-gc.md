<!---
markmeta_author: 望哥
markmeta_date: 2018-08-30
markmeta_title: Hotspot内存结构及垃圾回收
markmeta_categories: 编程语言
markmeta_tags: java,hostspot,gc

-->

摘要：基于Java SE10 版本整理Hotspot的内存结构及垃圾回收基础知识点。

版本:
- 2018/08/31: 第一版本

# 1. Heap 内存

`Heap = { Old + NEW = {Eden, from, to} }` 
- Old 即年老代（Old Generation）
- New 即年轻代（Young Generation）

堆内存大小: 
- `-Xms` 默认为物理内存的1/64但小于1GB;
- `-Xmx` 为JVM可申请的最大Heap内存，默认为物理内存的1/4但小于1GB,
- 当剩余堆空间小于40%时，JVM会增大Heap到`-Xmx`大小, 可通过`-XX:MinHeapFreeRadio`来控制这个比例；
- 当空余堆内存大于70%时，JVM会减小Heap到`-Xms`大小，可通过`-XX:MaxHeapFreeRatio`来指定这个比例。
- 可使用`-XX:+UseAdaptiveSizePolicy`开关来控制是否采用`动态控制策略`，如果动态控制，则动态调整Java堆中各个区域的大小以及进入老年代的年龄。


## 1.1 年轻代（Young Generation）
- 新生成对象首先放在年轻代;
- `-XX:NewRatio` : 设置Old:Young的比例，默认值2，即Old是Young的2倍，Young占1/3, 增大新生代能减少minor GC的频率;
- `-XX:NewSize = Eden + From + To` , 设置Young初始值大小
- `-XX:Maxnewsize`：设置Young最大值大小
- `-Xmn` 直接赋值(等于-XX:NewSize and -XX:MaxNewSize同值的缩写)
- `-XX:SurvivorRatio`: Eden和单个Survior的比例，默认8，即一个Survior为1/10的新生代 1/(SurvivorRatio+2)。
- 如果一次回收中`Survivor+Eden`中存活下来的内存超过单个survior容量，则需要将一部分对象分配到老年代。


## 1.2 年老代（Old Generation）
- `-XX:PretenureSizeThreshold` 控制直接升入老年代的对象大小，大于这个值的对象会直接分配在老年代上。
- `-XX:MaxTenuringThreshold`: 设置年龄阈值（默认15），超过该值，对象被移到老年代

# 2. Metaspace 内存
- 独立于Heap空间
- Java 8开始，永久代被彻底移除，`元空间(Metaspace)`取而代之。
- `-XX:MetaspaceSize` 
- `-XX:MaxMetaspaceSize`
- Hibernate/Spring AOP之后类都比较多，可以一开始就把初始值设到128M，并设一个更大的Max值以求保险。

## 2.1. Metaspace GC 

触发条件：
- 永久代的回收并不是必须的, `-Xnoclassgc`控制
- 达到`-XX:MaxMetaspaceSize`指定大小

条件：
- 类的所有实例都已经被回收
- 加载类的ClassLoader已经被回收
- 类对象的Class对象没有被引用（即没有通过反射引用该类的地方）

回收两类： 常量池中的常量，无用的类（dead classes）和类加载器(dead classloaders)

溢出表现为：`java.lang.OutOfMemoryError: Metaspace`

使用`-verbose，-XX:+TraceClassLoading、-XX:+TraceClassUnLoading`查看类加载和卸载信息


# 3. 垃圾收集算法

## 3.1 标记算法

用于判断对象是否可以被回收。

### 3.1.1 引用计数算法

给对象中添加一个引用计数器，每当有一个地方引用它时，计数器值就加一；当引用失败时，计数器就减一；任何时候计数器为零的对象就是不可能再被使用的。

优点：实现简单，判定效率高

缺点：难以解决对象之间相互循环引用的问题


### 3.1.2 可达性算法

通过一系列称为“GC Roots”的对象作为起始点，从这些节点开始向下搜索，搜索所走过的路径称为引用链，当一个对象到GC Roots没有任何引用链相连时，则证明此对象不可用。

主流商用程序语言（Java、C#）的主要实现中都是通过可达性分析来判定对象是否存活。

可作为GC Roots的对象包括下面几种：
- 虚拟机栈（栈帧中的本地变量表）中引用的对象
- 方法区中类静态属性引用的对象
- 方法区中常量引用的对象
- 本地方法栈中JNI（即一般说的Native方法）引用的对象

> OopMap: 记录栈上本地变量到堆上对象的引用关系;

> RememberedSet: 每个内存区域独立创建，记录自家的对象被外面对象引用的情况;

> 安全点(Safepoint): 代码执行过程中的一些特殊位置，当线程执行到这些位置的时候，说明虚拟机当前的状态是安全的; 
一般是以程序“是否具有让程序长时间执行的特征”为标准进行选定的，所以一般选定为方法调用、循环跳转、异常跳转处为安全点;
当开始GC时，线程都跑到最近的安全点上停下来。 这里分为`抢先式中断`和`主动式中断`。

> 安全区域(Safe Region): 一段代码中引用关系不会变化，这一段代码称为安全区域（扩展的安全点）;


## 3.2 复制算法
- 将可用内存按容量划分为大小相等的两块，每次只使用其中的一块
- 当这一块的内存用完了，就将还存活着的对象复制到另外一块上面，再把已经使用过的内存空间一次清理掉

优点：实现简单，运行高效

不足：内存缩小为原来的一半

## 3.3 标记-复制算法
- 首先标记出所有存活对象
- 在标记完成后使用复制算法复制存活对象到另外一块内存空间

## 3.4 标记-清除算法
- 首先标记出所有存活对象
- 在标记完成后统一回收所有未被引用对象

不足：标记清除之后会产生大量不连续的内存碎片，导致以后需要分配较大对象时，无法找到足够大的连续内存而不得不提前触发另一次垃圾收集动作

## 3.5 标记-整理算法
 - 标记与”标记-清除”算法一样
 - 但后续步骤不是直接对可回收对象进行清理，而是让所有存活的对象向一端移动，然后直接清理掉端边界以外的内存

## 3.6 分代收集算法
- 新生代使用复制算法
- 老年代使用标记-整理算法


# 4. 垃圾回收器

## 4.1 Serial收集器
- 标记－复制算法;
- 新生代收集器，单线程。
- 收集时须暂停其他所有工作线程，直到收集结束；
- 收集阶段：标记 -> 清除 -> 复制
- 对于运行在Client模式下的虚拟机来说是一个很好的选择；

优点：简单高效。 它没有线程交互的开销，获得最高的单线程收集效率

## 4.2 Serial Old收集器
- 标记－整理算法;
- Serial收集器的老年代版本。
- 主要意义也是在于给Client模式下的虚拟机使用。
- CMS发生Concurrent Mode Failure时使用。
- G1 old gen填满无法继续进行mixed GC，就会切换到serial old GC来收集整个GC heap(注意包括young、old、perm),这才是真正的full GC。

## 4.3 【废弃】ParNew收集器
- 年轻代垃圾收集器，采用复制算法
- Serial收集器的多线程版本；
- JDK 9开始被废弃；

## 4.4 Parallel Scavenge收集器
- 标记－复制算法;
- 新生代收集器，并行多线程。 
- 目的是达到一个可控制的吞吐量， `吞吐量 = 运行用户代码时间/（运行用户代码时间+垃圾收集时间）`
- `-XX:MaxGCPauseMillis` 设置停顿时间 
- `-XX:GCTimeRatio` 设置吞吐量大小（吞吐量的倒数）
- `-XX:+UseAdaptiveSizePolicy` GC自适应的调节策略（GC Ergonomics）, 当这个参数打开之后，就不需要手工指定新生代的大小、Eden与Survivor区的比例、晋升老年代对象年龄等细节参数了，虚拟机会根据当前系统的运行情况收集性能监控信息，动态调整这些参数以提供最合适的停顿时间或者最大的吞吐量

## 4.5 Parallel Old收集器
- 标记－整理算法;
- Parallel Scavenge收集器的老年代版本。
- 在注重吞吐量以及CPU资源敏感的场合，都可以优先考虑PS加PS Old收集器。

## 4.5 【废弃】CMS（Concurrent Mark Sweep）收集器

- “标记—清除”算法
- 老年代收集器
- JDK 9开始被废弃。CMS以获取最短回收停顿时间为目标的收集器。

整个过程分为4个步骤：
- 初始标记: 初始标记仅仅只是标记一下GC Roots能直接关联到的对象，速度很快，需要STW。
- 并发标记: 并发标记阶段就是进行GC Roots Tracing的过程.
- 重新标记: 重新标记阶段是为了修正并发标记期间因用户程序继续运作而导致标记产生变动的那一部分对象的标记记录，这个阶段的停顿时间一般会比初始标记阶段稍长一些，但远比并发标记的时间短，仍然需要STW。
- 并发清除: 并发清除阶段会清除对象。

由于整个过程中耗时最长的并发标记和并发清除过程收集器线程都可以与用户线程一起工作，所以，从总体上来说，CMS收集器的内存回收过程是与用户线程一起并发执行的。

优点：并发收集，低停顿

缺点：
- 对CPU资源非常敏感
- 无法处理浮动垃圾：由于在垃圾收集阶段用户线程还需要运行，那也就还需要预留有足够的内存空间给用户线程使用，因此CMS收集器不能像其他收集器那样等到老年代几乎完全被填满了再进行收集，需要预留一部分空间提供并发收集时的程序运作使用。要是CMS运行期间预留的内存无法满足程序需要，就会出现一次“Concurrent Mode Failure”失败，这时虚拟机将启动后备预案：临时启用Serial Old收集器来重新进行老年代的垃圾收集，这样停顿时间就很长了。
- 会产生大量空间碎片：基于“标记—清除”算法这意味着收集结束时会有大量空间碎片产生。空间碎片过多时，将会给大对象分配带来很大麻烦，往往会出现老年代还有很大空间剩余，但是无法找到足够大的连续空间来分配当前对象，不得不提前触发一次Full GC。

> 浮动垃圾: 并发清理阶段用户线程还在运行着，自然就还会有新的垃圾不断产生，这一部分垃圾出现在标记过程之后，CMS无法在当次收集中处理掉它们，只好留待下一次GC时再清理掉。这一部分垃圾就称为“浮动垃圾”。

CMS GC 日志范例:
```
2019-11-27T14:04:03.401+0800: 88878.899: [CMS-concurrent-mark-start]
2019-11-27T14:04:03.531+0800: 88879.029: [GC 88879.029: [ParNew: 627196K->55408K(645120K), 0.4159400 secs] 1120912K->1067802K(1687804K), 0.4161460 secs] [Times: user=0.35 sys=1.04, real=0.42 secs]
2019-11-27T14:04:03.979+0800: 88879.477: [CMS-concurrent-mark: 0.162/0.579 secs] [Times: user=0.61 sys=1.04, real=0.58 secs]
2019-11-27T14:04:03.979+0800: 88879.477: [CMS-concurrent-preclean-start]
2019-11-27T14:04:03.994+0800: 88879.492: [CMS-concurrent-preclean: 0.014/0.015 secs] [Times: user=0.03 sys=0.01, real=0.01 secs]
2019-11-27T14:04:03.994+0800: 88879.492: [CMS-concurrent-abortable-preclean-start]
2019-11-27T14:04:04.111+0800: 88879.609: [GC 88879.609: [ParNew2019-11-27T14:04:04.198+0800: 88879.696: [CMS-concurrent-abortable-preclean: 0.004/0.204 secs] [Times: user=0.13 sys=0.16, real=0.21 secs]
2019-11-27T14:04:05.022+0800: 88880.521: [GC[YG occupancy: 103836 K (645120 K)]88880.521: [Rescan (parallel) , 0.0056570 secs]88880.526: [weak refs processing, 0.0005840 secs] [1 CMS-remark: 1524394K(1554724K)] 1628230K(2199844K), 0.0063310 secs] [Times: user=0.02 sys=0.00, real=0.01 secs]
2019-11-27T14:04:05.029+0800: 88880.527: [CMS-concurrent-sweep-start]
2019-11-27T14:04:05.066+0800: 88880.564: [CMS-concurrent-sweep: 0.036/0.036 secs] [Times: user=0.05 sys=0.00, real=0.03 secs]
2019-11-27T14:04:05.068+0800: 88880.566: [CMS-concurrent-reset-start]
2019-11-27T14:04:05.082+0800: 88880.580: [CMS-concurrent-reset: 0.014/0.014 secs] [Times: user=0.02 sys=0.00, real=0.01 secs]
```

## 4.6 G1（Garbage-First）收集器

G1从JDK9开始作为默认垃圾收集器。

特点：
- 并行与并发：G1能充分利用多CPU、多核环境下的硬件优势，使用多个CPU来缩短STW停顿的时间，部分其他收集器原本需要停顿Java线程执行的GC动作，G1收集器仍然可以通过并发的方式让Java程序继续执行。
- 分代收集：与其他收集器一样，分代概念在G1中依然得以保留。虽然G1可以不需要其他收集器配合就能独立管理整个GC堆，但它能够采用不同的方式去处理新创建的对象和已经存活了一段时间、熬过多次GC的旧对象以获取更好的收集效果。
- 空间整合：与CMS的“标记—清理”算法不同，G1从整体来看是基于“标记—整理”算法实现的收集器，从局部（两个Region之间）上来看是基于“复制”算法实现的，但无论如何，这两种算法都意味着G1运作期间不会产生内存空间碎片，收集后能提供规整的可用内存。这种特性有利于程序长时间运行，分配大对象时不会因为无法找到连续内存空间而提前触发下一次GC。
- 可预测的停顿：这是G1相对于CMS的另一大优势，降低停顿时间是G1和CMS共同的关注点，但G1除了追求低停顿外，还能建立可预测的停顿时间模型，能让使用者明确指定在一个长度为M毫秒的时间片段内，消耗在垃圾收集上的时间不得超过N毫秒。


G1将整个Java堆划分为多个大小相等的独立区域（Region），虽然还保留有新生代和老年代的概念，但新生代和老年代不再是物理隔离的了，它们都是一部分Region（不需要连续）的集合。


G1跟踪各个Region里面的垃圾堆积的价值大小（回收所获得的空间大小以及回收所需时间的经验值），在后台维护一个优先列表，每次根据允许的收集时间，优先回收价值最大的Region（这也就是Garbage-First名称的来由）。

Region之间的对象引用使用Remembered Set（RSet）来避免全堆扫描的。每个Region都有一个RSet，虚拟机发现程序在对Reference类型的数据进行写操作时，会产生一个write Barrier暂时中断写操作，检查Reference引用的对象是否处于不同的Region之中，若是则用过Card Table把相关引用信息记录到被引用对象所属的Region的RSet中。

Card Table 将一个region在逻辑上划分为固定大小的连续区域，每个区域称之为卡。卡通常较小，介于 128 到 512 字节之间。Card Table 通常为字节数组，由 Card 的索引（即数组下标）来标识每个分区的空间地址。默认情况下，每个卡都未被引用。当一个地址空间被引用时，这个地址空间对应的数组索引的值被标记为“0”，即标记为脏或被引用，此外 RSet 也将这个数组下标记录下来。一般情况下，这个 RSet 其实是一个 Hash Table，Key 是别的 Region 的起始地址，Value 是一个集合，里面的元素是 Card Table 的 Index。

G1 提供了两种 GC 模式，Young GC 和 Mixed GC，两种都STW。

Young GC 阶段：
- 阶段-1：根扫描 ：扫描静态和本地对象
- 阶段-2：更新 RS  ：处理 dirty card 队列和更新 RS
- 阶段-3：处理 RS  ：检测从年轻代指向年老代的对象
- 阶段-4：对象拷贝  ：拷贝存活的对象到 survivor/old 区域
- 阶段-5：处理引用队列  ：处理软引用、弱引用、虚引用

Mixed GC 阶段：

- 阶段-1：全局并发标记（Global Concurrent Marking）
    - Step-1：初始标记（Initial Mark，STW） ：对根进行标记，与常规的（STW）年轻代垃圾回收密切相关。
    - Step-2：根区域扫描（Root Region Scan） ：在初始标记的存活区扫描对老年代的引用，并标记被引用的对象。该阶段与应用程序（非 STW）同时运行，并且只有完成该阶段后，才能开始下一次 STW 年轻代垃圾回收。
    - Step-3：并发标记（Concurrent Marking） ：在整个堆中查找可访问的（存活的）对象，与应用程序同时运行，可以被 STW 年轻代垃圾回收中断。
    - Step-4：最终标记（Remark，STW） ： 帮助完成标记周期，清空 SATB 缓冲区，跟踪未被访问的存活对象，并执行引用处理。
    - Step-5：清除垃圾（Cleanup，STW） ：执行统计和净化 RSet 的 STW 操作。在统计期间会识别完全空闲的区域和可供进行混合垃圾回收的区域。清理阶段在将空白区域重置并返回到空闲列表时为部分并发。
- 阶段-2：拷贝存活对象（Evacuation）


### 4.6.1  G1 GC 调优
```
-XX:+UseG1GC -Xmx32g -XX:MaxGCPauseMillis=200
```
G1 尽量确保每次 GC 暂停的时间都在设置的 MaxGCPauseMillis 范围内.
我们需要在吞吐量跟暂停时间之间做一个平衡。如果 MaxGCPauseMillis 设置的过小，那么 GC 就会频繁，吞吐量就会下降。如果 MaxGCPauseMillis 设置的过大，应用程序暂停时间就会变长。G1 的默认暂停时间是 200 毫秒，我们可以从这里入手，调整合适的时间。

- `-XX:G1HeapRegionSize=n` : region大小。值是 2 的幂，范围是 1 MB 到 32 MB 之间。目标是根据最小的 Java 堆大小划分出不超过 2048 个区域。
- `-XX:ParallelGCThreads=n` : STW 工作线程数的值。将 n 的值设置为逻辑处理器的数量。n 的值与逻辑处理器的数量相同，最多为 8。如果逻辑处理器不止八个，则将 n 的值设置为逻辑处理器数的 5/8 左右，这适用于大多数情况。
- `-XX:ConcGCThreads=n` : 并发标记的线程数。将 n 设置为并行垃圾回收线程数 (ParallelGCThreads) 的 1/4 左右。
- `-XX:InitiatingHeapOccupancyPercent=45` : 触发标记周期的 Java 堆占用率阈值。默认占用率是整个 Java 堆的 45%。
- 避免使用`-Xmn`选项或`-XX:NewRatio`等选项显式设置年轻代大小, 固定年轻代的大小会覆盖暂停时间目标。
- `-XX:G1NewSizePercent=5` : 年轻代大小最小值的堆百分比。默认值是 Java 堆的 5%。
- `-XX:G1MixedGCLiveThresholdPercent=65` : 为混合垃圾回收周期中要包括的旧区域设置占用率阈值。默认占用率为 65%。
- `-XX:G1HeapWastePercent=10` : 浪费堆百分比。如果可回收百分比小于堆废物百分比， HotSpot VM 不会启动混合垃圾回收周期。默认值是 10%。
- `-XX:G1MixedGCCountTarget=8` : 标记周期完成后，对存活数据上限为 G1MixedGCLIveThresholdPercent 的旧区域执行混合垃圾回收的目标次数。默认值是 8 次混合垃圾回收。混合回收的目标是要控制在此目标次数以内.
- `-XX:G1OldCSetRegionThresholdPercent=10` : 混合垃圾回收期间要回收的最大旧区域数。默认值是 Java 堆的 10%
- `-XX:G1ReservePercent=10` : 空闲空间的预留内存百分比，以降低目标空间溢出的风险。默认值是 10%。


### 4.6.2 G1 触发 Full GC

G1 会退化使用Old Serial做Full GC，触发情况包括:

- 并发模式失败 : 在 Mix GC 之前，老年代就被填满。这种情形下需要增加堆大小，或者调整周期（例如，增加线程数-XX:ConcGCThreads等）。
- 晋升失败或者疏散失败 : 没有足够的内存供存活对象或晋升对象使用。在日志中看到“to-space exhausted”或者“to-space overflow”。可增加`-XX:G1ReservePercent`选项的值（并相应增加总的堆大小），为“目标空间”增加预留内存量; 也通过减少`-XX:InitiatingHeapOccupancyPercent`选项的值，提前启动标记周期;也可通过增加`-XX:ConcGCThreads`选项的值，增加并发标记线程的数目。
- 巨型对象分配失败 : 巨型对象找不到合适的空间进行分配时。可增加内存或者增大`-XX:G1HeapRegionSize`选项的值，使巨型对象不再是巨型对象。


## 参考:
- [The Java® Virtual Machine Specification Java SE 10 Edition](https://docs.oracle.com/javase/specs/jvms/se10/html/index.html)
- [Factors Affecting Garbage Collection Performance](https://docs.oracle.com/javase/10/gctuning/factors-affecting-garbage-collection-performance.htm)
- [Java Platform, Standard Edition HotSpot Virtual Machine Garbage Collection Tuning Guide](https://docs.oracle.com/javase/10/gctuning/toc.htm)
- [Java SE 10 HotSpot VM Options](https://docs.oracle.com/javase/10/tools/java.htm)
- [The Java HotSpot Performance Engine Architecture](https://www.oracle.com/technetwork/java/whitepaper-135217.html)
- [Major GC和Full GC的区别是什么？触发条件呢？](https://www.zhihu.com/question/41922036)
- [JVM 之 OopMap 和 RememberedSet](http://dsxwjhf.iteye.com/blog/2201685)
- [深入理解 Java G1 垃圾收集器](http://ghoulich.xninja.org/2018/01/27/understanding-g1-garbage-collector-in-java/)
- [垃圾优先型垃圾回收器调优](https://www.oracle.com/technetwork/cn/articles/java/g1gc-1984535-zhs.html)



