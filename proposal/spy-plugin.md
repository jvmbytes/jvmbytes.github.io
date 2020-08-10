<!---
markmeta_author: wongoo
markmeta_date: 2020-05-29
markmeta_title: spy plugin design
markmeta_categories: proposal
markmeta_tags: plugin
-->

# spy plugin design

设计插件的目的，是希望开发植入功能的团队可以独立开发相关功能，做到对应用代码的无侵入性。

## 设计因素

spy plugin 设计需要考虑几个因素:
- plugin 相关的类或jar需要和应用一起打包；
- plugin 相关的类不能被其他classloader加载到，比如AppClassloader；
- plugin 相关的类只能通过 spy 的 classloader 加载；
- plugin 按需加载和卸载；
- plugin 加载适应不同的打包方式（包括fat-jar）；

## 插件设计

- 其中使用 `${groupId}@${artifactId}` 作为一个独立目录， 目录下再存放相关的plugin类；
- 加载每一个plugin可以单独启动一个 ClassLoader 来加载；
- 加载需提供三个参数: `groupId`, `artifactId`;
- 插件类实现 [SpyPlguin](https://github.com/jvmbytes/spy/blob/master/spy-plugin/src/main/java/com/jvmbytes/spy/plugin/SpyPlugin.java)
  插件接口，实现植入需要的信息；

插件打包范例如下:
```
test-plugin.jar
|-- com.company.spy@test-plugin
|   |- com
|      |- company
|         |- spy
|            |- test
|               |- TestPlugin.class
```

## 插件范例

[插件范例项目](https://github.com/jvmbytes/examples/tree/master/spy-plugin-example)
- pom.xml 设置parent为 `com.jvmbytes.spy.plugin:spy-plugin-dependencies`
- [SpyExamplePlugin.java](https://github.com/jvmbytes/examples/blob/master/spy-plugin-example/src/main/java/com/jvmbytes/plugin/example/SpyExamplePlugin.java) 
  实现 SpyPlugin 接口。
- 插件类增加 `@MetaInfServices(SpyPlugin.class)` 注解，以便能够扫描到该插件类；

[插件调用范例](https://github.com/jvmbytes/examples/blob/master/spring-boot-example)
- [pom.xml](https://github.com/jvmbytes/examples/blob/master/spring-boot-example/src/main/java/com/jbytes/boot/example/BootExample.java) 引入依赖 
    - 插件基础库: `com.jvmbytes.spy.plugin:spy-plugin`
    - 用户开发的插件: `com.jvmbytes.spy.plugin:spy-plugin-example`
- [插件加载卸载](https://github.com/jvmbytes/examples/blob/master/spring-boot-example/src/main/java/com/jbytes/boot/example/BootExample.java)
    - 加载插件: `PluginLoader.load(groupId, artifactId)`
    - 卸载插件: `PluginLoader.unload(groupId, artifactId)`
