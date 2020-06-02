<!---
markmeta_author: wongoo
markmeta_date: 2020-05-29
markmeta_title: expose the Instrumentation through java agent
markmeta_categories: proposal
markmeta_tags: javaagent
-->

# expose the Instrumentation through java agent[RESOLVED]

许多java字节码库都要依赖java 字节码编织的入口 Instrumentation 类，
该类可以通过 javaagent 的 premain/agentmain 两种方式获得，
这要求每个库在java启动的时候添加 `-javaagent` 参数引入或通过动态attach的方式添加，
这两种方式都要求有对应用环境有一定的控制，可以去改变启动参数或改变环境信息，
但很多公司对应用的启动和环境管控很严，应用启动按照标准化方案执行，就比较难以改变。

这个提案的目的是只要添加一次 `-javaagent`，将获得到的 Instrumentation 暴露出来，以便其他字节码库可以引用到它。
其他字节码库通过应用启动加载，在需要编织代码的时候再通过反射获得Instrumentation。

参考如下方案：

![](images/spy-agent.png)

# solution

see [jvmbytes agent](https://github.com/jvmbytes/agent).
