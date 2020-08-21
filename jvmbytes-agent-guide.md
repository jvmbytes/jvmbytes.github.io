<!---
markmeta_author: wongoo
markmeta_date: 2020-08-13
markmeta_title: java字节码编织的基础 —— 获取Instrumentation对象
markmeta_categories: guide
markmeta_tags: javaagent
-->

# java字节码编织的基础 —— 获取Instrumentation对象

许多java字节码库都要依赖java 字节码编织的入口 Instrumentation 类，
该类可以通过 javaagent 的 premain/agentmain 两种方式获得，
这要求每个库在java启动的时候添加 `-javaagent` 参数引入或通过动态attach的方式添加，
这两种方式都要求有对应用环境有一定的控制权限，需要能够改变启动参数或改变环境信息，
但很多公司应用启动按照标准化方案执行，对应用的启动和环境管控很严，就比较难以改变。
特别是对于容器化环境，就更难实现了。
这就导致很多依赖字节码编织的架构项目很难以推动。

[jvmbytes agent](https://github.com/jvmbytes/agent) 库的目的降低架构运维复杂度，只要添加一次 `-javaagent`，
将获得到的 Instrumentation 暴露出来给其他字节码库引用。
运维不再经常进行环境变更，架构不在担心获取不到必要的权限。

![](proposal/images/spy-agent.png)

## 使用范例

1. 添加 `inst-loader` 引用:
```xml
<dependency>
    <groupId>com.jvmbytes.agent</groupId>
    <artifactId>inst-loader</artifactId>
    <version>1.0.1</version>
</dependency>
```

2. 代码中通过 `com.jvmbytes.agent.inst.InstLoader.loadInst()`方法获得 **Instrumentation** 对象.

3. 下载agent代理 inst-agent-1.0.1.jar 
```shell script
wget https://search.maven.org/remotecontent?filepath=com/jvmbytes/agent/inst-agent/1.0.1/inst-agent-1.0.1.jar
```

4. 应用启动添加 `-javaagent:inst-agent-1.0.1.jar`
```shell script
java -javaagent:inst-agent-1.0.1.jar -jar app.jar
```

## 参考
- [jvmbytes agent](https://github.com/jvmbytes/agent)