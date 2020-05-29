<!---
markmeta_author: wongoo
markmeta_date: 2019-04-02
markmeta_title: JVM Agent 机制
markmeta_categories: 编程语言
markmeta_tags: java,jvm
-->

# JVM Agent

Java Agent（Java 代理）是 JDK 1.5 之后引入的技术。

Java Agent 有两种方式，
1. premain : 在 JVM 启动的时候, 在main之前被调用加载, 
2. agentmain: 在 JVM 启动之后被调用加载

java agent 被同一个jvm的SystemClassLoader(AppClassLoader)加载.

# JVM attach 机制

- **Attach机制是jvm提供一种jvm进程间通信的能力，能让一个进程传命令给另外一个进程，并让它执行内部的一些操作。**
- JVM接收到attach请求后，通过建立本地sock的方式，接收外部进程请求，完成通信。
- Attach机制是Sun私有实现（即不是Jvm标准规范，其他虚拟机不一定有这个能力）

## 1. attach 实现

### 1.1 外部进程
在Linux下，attach时，外部进程会在目标进程的cwd目录下创建文件：`/proc/$PID/cwd/.attach_pid$PID`。 
然后等待给JVM下的所有线程发送SIGQUIT信号，再作轮询等待看目标进程是否创建了某个文件，attachTimeout默认超时时间是5000ms，可通过设置系统变量sun.tools.attach.attachTimeout来指定。

### 1.2 目标VM
- JVM在启动时，会创建“Signal Dispatcher”线程。当外部进程给所有子进程发送SIGQUIT信号，而JVM将信号就传给了“Signal Dispatcher”（其他线程对该信号进行了屏蔽）。
- Signal Dispatcher 线程： 当信号是SIGBREAK(在jvm里做了#define，其实就是SIGQUIT)的时候，就会触发`AttachListener::is_init_trigger()`的执行，创建出AttachListener线程。
- AttachListener 线程：AttachListener线程创建了一个监听套接字，并创建了一个文件/tmp/.java_pid$PID，这个文件就是外部进程之前一直在轮询等待的文件，随着这个文件的生成，意味着attach的过程圆满结束了。
- AttachListener接收请求: 该线程不断从队列中取AttachOperation，然后找到请求命令对应的方法进行执行。比如jstack的 thread dump命令命令，attach listener找到 { “threaddump”, thread_dump }的映射关系，然后执行thread_dump方法.

```
title JVM Attach Machanism
LinuxVirtualMachine->LinuxVirtualMachine: create handshak file /proc/1234/cwd/.attach.pid1234
LinuxVirtualMachine->JVM:send signal SIGQUIT
JVM->Signal Dispatcher: catch signal
Signal Dispatcher->AttachListener: is_init_trigger: check handshak file exists
AttachListener->AttachListener: init: create socket /tmp/.java.pid1234 and listen
LinuxVirtualMachine->LinuxVirtualMachine: loop check /tmp/.java.pid1234
LinuxVirtualMachine->AttachListener: connect
LinuxVirtualMachine->AttachListener: commad request, like loadAgent
```

![](static/java_attach_machanism.png)

## 2.主要接口与类
### 2.1 class VirtualMachine

```java
public abstract class VirtualMachine extends Object
```

该类表示将要被“附着的”Java虚拟机，也被称为目标虚拟机（target virtual machine,target vm）。 

外部进程（通常来说是外部的监控工具、或是管理控制台，如jconsole,jprofile） 使用该类实例来 将agent 加载到目标虚拟机中。 
例如，使用Java编写的profiler工具就会使用VirtaulMachine类实例来加载profiler agent到被监控的jvm中。

通过VirtualMachine的类静态方法attach（string id）来获取代表target vm的VirtaulMachine实例。该方法 id参数一般是arget vm的进程Pid。

另外，也可以 通过 类静态方法 attach(VirtualMachineDescriptor vmd) 来获取一个VirtaulMachine实例（ 可以使用静态方法VirtualMachine.list()方法获取一个VirtualMachineDescriptor 列表 ）。

当获取到VirtualMachine对象实例后，就可以调用loadAgent，loadAgentLibrary，loadAgentPath方法操作target VM了。

这几个方法的区别：
- loadAgent方法用于加载 用Java写的、打包成jar的agent;
- loadAgentLibrary 和loadAgentPath 是用于加载基于JVM TI接口的 打包成动态库形式的agent。

范例:
```java
// attach to target VM
VirtualMachine vm = VirtualMachine.attach("2177");

// get system properties in target VM
Properties props = vm.getSystemProperties();

// construct path to management agent
String home = props.getProperty("java.home");
String agent = home + File.separator + "lib" + File.separator  + "management-agent.jar";

// load agent into target VM
vm.loadAgent(agent, "com.sun.management.jmxremote.port=5000");

// detach
vm.detach();
```

### 2.2 Class AttachPermission

```java
public final class AttachPermission extends BasicPermission
```

当设置了 SecurityManager后，在外部程序调用VirtalMachine.attach时，target VM会检查外部程序的权限。

当创建AttachProvider时，会也检查你的权限。

AttachPermission对象包含一个名字（目前不知道操作列表这种细化的权限）。

对象构造：
- `public AttachPermission(String name)`：创建一个AttachPermission 对象，name参数只能是“attachVirtualMachine” 或“createAttachProvider”；
- `public AttachPermission(String name, String actions)`： 创建一个AttachPermission 对象，name参数只能是“attachVirtualMachine” 或“createAttachProvider”；actions未被使用，应该传入null或是空字符串。

## 3. JVMTI

JVMTI(Java Virtual Machine Tool Interface) 是一套由 Java 虚拟机提供的，为 JVM 相关的工具提供的本地编程接口集合。

JVMTI 提供了一套“代理”程序机制，可以支持第三方工具程序以代理的方式连接和访问 JVM，并利用 JVMTI 提供的丰富的编程接口，完成很多跟 JVM 相关的功能。
JVMTI 的功能非常丰富，包括虚拟机中线程、内存 / 堆 / 栈，类 / 方法 / 变量，事件 / 定时器处理等等。
使用 JVMTI 一个基本的方式就是设置回调函数，在某些事件发生的时候触发并作出相应的动作，这些事件包括虚拟机初始化、开始运行、结束，类的加载，方法出入，线程始末等等。
如果想对这些事件进行处理，需要首先为该事件写一个函数，然后在 jvmtiEventCallbacks 这个结构中指定相应的函数指针。

 Instrument 就是一个基于 JVMTI 接口的，以代理方式连接和访问 JVM 的一个 Agent，Instrument 库被加载之后 JVM 会调用其 Agent_OnAttach 方法，如下代码片段：

```c++
// 来源：InvocationAdapter.c  
// 片段 1：创建 Instrument 对象  
success = createInstrumentationImpl(jni_env, agent);  
// 片段 2：监听 ClassFileLoadHook 事件并设置回调函数为 eventHandlerClassFileLoadHook  
callbacks.ClassFileLoadHook = &eventHandlerClassFileLoadHook;  
jvmtierror = (*jvmtienv)->SetEventCallbacks(jvmtienv, &callbacks, sizeof(callbacks));  
// 片段 3：调用 java 类的 agentmain 方法  
success = startJavaAgent(agent, jni_env, agentClass, options, agent->mAgentmainCaller); 
```

Agent_OnAttach 方法被调用的时候主要做了几件事情：
1. 创建 Instrument 对象，这个对象就是 Java Agent 中通过 agentmain 方法拿到的 Instrument 对象；
2. 通过 JVMTI 监听 JVM 的 ClassFileLoadHook 事件并设置回调函数 eventHandlerClassFileLoadHook；
3. 调用 Java Agent 的 agentmain 方法，并将第 1）步创建的 Instrument 对象传入。

通过上面的内容可以知道，在 JVM 进行类加载的都会回调 eventHandlerClassFileLoadHook 方法，
eventHandlerClassFileLoadHook 方法做的事情就是调用 Java Agent 内部传入的 Instrument 的 ClassFileTransformer 的实现：`void addTransformer(ClassFileTransformer transformer)`

> Instrument对象只能通过 java agent的方式获得。

## 4. sandbox

**JVM-SANDBOX（沙箱）实现了一种在不重启、不侵入目标JVM应用的AOP解决方案。**

### 4.1 沙箱容器提供:
- 动态增强类你所指定的类，获取你想要的参数和行信息甚至改变方法执行
- 动态可插拔容器框架

### 4.2 沙箱的特性
- 无侵入：目标应用无需重启也无需感知沙箱的存在
- 类隔离：沙箱以及沙箱的模块不会和目标应用的类相互干扰
- 可插拔：沙箱以及沙箱的模块可以随时加载和卸载，不会在目标应用留下痕迹
- 多租户：目标应用可以同时挂载不同租户下的沙箱并独立控制
- 高兼容：支持JDK[6,11]

### 4.3 沙箱常见应用场景
- 线上故障定位
- 线上系统流控
- 线上故障模拟
- 方法请求录制和结果回放
- 动态日志打印
- 安全信息监测和脱敏

JVM-SANDBOX还能帮助你做很多很多，取决于你的脑洞有多大了。

### 4.4 实时无侵入AOP框架

在常见的AOP框架实现方案中，有静态编织和动态编织两种。

- 静态编织：静态编织发生在字节码生成时根据一定框架的规则提前将AOP字节码插入到目标类和方法中，实现AOP；
- 动态编织：动态编织则允许在JVM运行过程中完成指定方法的AOP字节码增强.常见的动态编织方案大多采用重命名原有方法，再新建一个同签名的方法来做代理的工作模式来完成AOP的功能(常见的实现方案如CgLib)，但这种方式存在一些应用边界：
   - 侵入性：对被代理的目标类需要进行侵入式改造。比如：在Spring中必须是托管于Spring容器中的Bean
   - 固化性：目标代理方法在启动之后即固化，无法重新对一个已有方法进行AOP增强

要解决无侵入的特性需要AOP框架具备**在运行时完成目标方法的增强和替换**。

Sandbox符合JDK的规范，运行期重定义一个类必须准循以下原则:
- 不允许新增、修改和删除成员变量
- 不允许新增和删除方法
- 不允许修改方法签名

**JVM-SANDBOX属于基于Instrumentation的动态编织类的AOP框架，通过精心构造了字节码增强逻辑，使得沙箱的模块能在不违反JDK约束情况下实现对目标应用方法的无侵入运行时AOP拦截。**

### 4.5 事件驱动
在沙箱的世界观中，任何一个Java方法的调用都可以分解为BEFORE、RETURN和THROWS三个环节，由此在三个环节上引申出对应环节的事件探测和流程控制机制。

```java
// BEFORE
try {

   /*
    * do something...
    */

    // RETURN
    return;

} catch (Throwable cause) {
    // THROWS
}
```

基于BEFORE、RETURN和THROWS三个环节事件分离，沙箱的模块可以完成很多类AOP的操作。

1. 可以感知和改变方法调用的入参
2. 可以感知和改变方法调用返回值和抛出的异常
3. 可以改变方法执行的流程
  - 在方法体执行之前直接返回自定义结果对象，原有方法代码将不会被执行
  - 在方法体返回之前重新构造新的结果对象，甚至可以改变为抛出异常
  - 在方法体抛出异常之后重新抛出新的异常，甚至可以改变为正常返回

### 4.6 类隔离策略
沙箱通过自定义的SandboxClassLoader破坏了双亲委派的约定，实现了和目标应用的类隔离。所以不用担心加载沙箱会引起应用的类污染、冲突。各模块之间类通过ModuleJarClassLoader实现了各自的独立，达到模块之间、模块和沙箱之间、模块和应用之间互不干扰.

![](https://github.com/alibaba/jvm-sandbox/wiki/img/jvm-sandbox-classloader.png)

### 4.7 类增强策略
沙箱通过在BootstrapClassLoader中埋藏的Spy类完成目标类和沙箱内核的通讯.
![](https://github.com/alibaba/jvm-sandbox/wiki/img/jvm-sandbox-enhance-class.jpg)

### 4.8 整体架构
![](https://github.com/alibaba/jvm-sandbox/wiki/img/jvm-sandbox-architecture.png)

### 4.9 sandbox attach 范例
alibaba jvm sandbox 执行attach的命令(参考 sandbox.sh):

```bash
java -Xms128M -Xmx128M -Xnoclassgc -ea -Xbootclasspath/a:<JAVA_HOME>/lib/tools.jar \
   -jar <SANDBOX_DIR>/bin/../lib/sandbox-core.jar \
   36789   \
   "<SANDBOX_DIR>/bin/../lib/sandbox-agent.jar"
   "home=<SANDBOX_DIR>/bin/..;token=216136593629;server.ip=0.0.0.0;server.port=0;namespace=default"
```

## 参考
1. [attachListener.cpp](https://github.com/openjdk-mirror/jdk7u-hotspot/blob/master/src/share/vm/services/attachListener.cpp)
2. [attachListener_linux.cpp](https://github.com/openjdk-mirror/jdk7u-hotspot/blob/master/src/os/linux/vm/attachListener_linux.cpp)
3. [LinuxVirtualMachine.java](http://www.docjar.com/html/api/sun/tools/attach/LinuxVirtualMachine.java.html)
4. JVM Attach机制实现, http://lovestblog.cn/blog/2014/06/18/jvm-attach/, 以 jstack dump 命令为例，从JVM 的C++代码分析attach机制的实现
5. JVM沙箱容器(一种JVM的非侵入式运行期AOP解决方案), https://github.com/alibaba/jvm-sandbox, 其也使用了JVM attach技术实现（另外还支持java agent模式）
6. JVM Attach 总结，https://blog.csdn.net/youyou1543724847/article/details/84952218
