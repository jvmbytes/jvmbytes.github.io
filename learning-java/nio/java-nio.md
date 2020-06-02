<!---
markmeta_author: wongoo
markmeta_date: 2019-01-16
markmeta_title: java BIO,NIO,AIO
markmeta_categories: java
markmeta_tags: java
-->

# java BIO,NIO,AIO

## BIO (blocking IO) 阻塞IO

- 特点: 同步、阻塞
- 面向流的阻塞操作: socket.accept()、socket.read()、socket.write(), 
- 采用多线程来处理不同的请求
- 阻塞的增加导致系统线程切换增多，开销更多



## NIO（non-blocking IO, 或者 New IO）非阻塞IO

- 特点：同步、非阻塞
- 单socket监听多socket事件
- 面向缓冲区
- 编程模型: Buffer(缓冲区), Channel(通道), Selector(选择器)
- 读取数据不等待，数据准备好再工作
- 无阻塞，线程更高效


## AIO: asynchronous IO, 异步IO

## 参考
- [理解Java NIO](https://yq.aliyun.com/articles/2371)
- [BIO,NIO,AIO 总结](https://github.com/Snailclimb/JavaGuide/blob/master/Java/BIO%2CNIO%2CAIO%20summary.md)
- [高并发Java（8）：NIO和AIO](http://www.importnew.com/21341.html)
