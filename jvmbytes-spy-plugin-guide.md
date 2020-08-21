<!---
markmeta_author: wongoo
markmeta_date: 2020-08-13
markmeta_title: spy 插件开发指南
markmeta_categories: guide
markmeta_tags: spy,plugin
-->

# spy 插件开发指南

设计插件的目的，是希望开发植入功能的团队可以独立开发相关功能，做到对应用代码的无侵入性。

## 插件功能

- 按需加载和卸载字节码植入插件；
- 独立classloader加载；
- 适应不同的打包方式（包括fat-jar）；

## 插件开发范例

1. 创建一个独立的插件项目`spy-plugin-example`，并设置parent为`spy-plugin-dependencies`，如下:

```xml
<parent>
   <groupId>com.jvmbytes.spy.plugin</groupId>
   <artifactId>spy-plugin-dependencies</artifactId>
   <version>1.1.1</version>
</parent>

<modelVersion>4.0.0</modelVersion>
<artifactId>spy-plugin-example</artifactId>
<version>1.0-SNAPSHOT</version>
```

2. 插件类实现`SpyPlugin`接口, 实现相关方法；同时增加`@MetaInfServices(SpyPlugin.class)`注解， 参考如下范例。

```java
@MetaInfServices(SpyPlugin.class)
public class SpyExamplePlugin implements SpyPlugin {
    private static final Logger logger = LoggerFactory.getLogger(SpyExamplePlugin.class);

    /**
    *  返回插件名称
    */
    @Override
    public String getName() {
        return "spy-example-plugin";
    }

    /**
    *  返回插件命名空间
    */
    @Override
    public String getNamespace() {
        return "default";
    }

    /**
    *  因为插件是在类隔离环境运行的，不能访问相关业务类，但可以通过该方法指定可访问的业务类包前缀。
    */
    @Override
    public String[] getParentPackagePrefixes() {
        return new String[]{
                "com.jbytes."
        };
    }

    /**
    *  该方法返回一个匹配器，指定要进行字节码植入的类和方法
    */
    @Override
    public Matcher getMatcher() {
        List<Filter> serviceFilter = new FilterBuilder()
                .onClass("com.jbytes.spy.example.service.*")
                .onAnyBehavior()
                .build();
        Matcher matcher = FilterMatcher.toAndGroupMatcher(serviceFilter);
        return matcher;
    }

    /**
    *  该方法指定字节码植入事件类型，EventType.BEFORE 指定在方法调用之前。
    */
    @Override
    public EventType[] getEventTypes() {
        EventType[] events = new EventType[]{EventType.BEFORE};
        return events;
    }

    /**
    *  该方法返回字节码植入事件监听器，负责执行具体要植入处理的动作。
    */
    @Override
    public EventListener getEventListener() {
        EventListener eventListener = new EventListener() {
            public void onEvent(Event event) throws Throwable {
                BeforeEvent beforeEvent = (BeforeEvent) event;
                System.out.println("---> plugin log calling " + beforeEvent.javaClassName + "." + beforeEvent.javaMethodName);
                // 打日志，记录调用的类及方法名
                logger.info("---> calling {}.{}", beforeEvent.javaClassName, beforeEvent.javaMethodName);
            }
        };
        return eventListener;
    }
}
```

3. 业务项目增加 spy-plugin 基础库依赖:

```xml
<dependency>
    <groupId>com.jvmbytes.spy.plugin</groupId>
    <artifactId>spy-plugin</artifactId>
    <version>1.1.1</version>
</dependency>
```

4. 业务项目增加开放插件 spy-plugin-example 依赖:

```xml
<dependency>
    <groupId>com.jvmbytes.spy.plugin</groupId>
    <artifactId>spy-plugin-example</artifactId>
    <version>1.0-SNAPSHOT</version>
</dependency>
```

5. 加载插件

业务代码增加恰当的入口点，调用以下代码加载插件:

```java
PluginLoader.load("com.jvmbytes.spy.plugin", "spy-plugin-example");
```

6. 卸载插件

业务代码增加恰当的入口点，调用以下代码卸载插件:

```java
PluginLoader.unload("com.jvmbytes.spy.plugin", "spy-plugin-example");
```

## 参考
- [插件范例项目](https://github.com/jvmbytes/examples/tree/master/spy-plugin-example)
- [插件调用范例](https://github.com/jvmbytes/examples/blob/master/spring-boot-example)
