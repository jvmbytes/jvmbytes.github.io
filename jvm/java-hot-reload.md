<!---
markmeta_author: wongoo
markmeta_date: 2020-04-08
markmeta_title: java jrebel hot reload
markmeta_categories: 编程语言
markmeta_tags: java
-->

# java hot reload

## jrebel

1. Create GUIDs online: https://www.guidgen.com/
2. 构造jrebel官方激活地址: https://jrebel.qekang.com/0577a3a6-fb6c-4657-8943-faac8d3dca9e
3. install idea jrebel plugin
4. 填入激活地址和任意email激活
5. 激活后改为 offline 模式


自己安装 license server

```bash

git clone --depth=1 https://gitee.com/gsls200808/JrebelLicenseServerforJava.git
cd JrebelLicenseServerforJava
mvn compile

nohup mvn exec:java -Dexec.mainClass="com.vvvtimes.server.MainServer" -Dexec.args="-p 19181" &

echo "ok"


# JRebel 2018.1 and later version Activation address was: 
# http://localhost:8081/{guid}, with any email.
# eg: http://localhost:19181/15bb233a-59ba-4365-8b14-12895e33f665 
```

## spring-load

```bash
wget https://repo.spring.io/release/org/springframework/springloaded/1.2.5.RELEASE/springloaded-1.2.5.RELEASE.jar


# 添加java 启动参数: -javaagent:/Users/gelnyang/soft/springloaded-1.2.5.RELEASE.jar -noverify 
```

