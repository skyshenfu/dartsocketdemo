import 'dart:isolate';

void main() async {
  ///1 定义宿主接受结果的port和发送参数的port
  ReceivePort hostReceivePort = ReceivePort();

  ///2 定义子Isolate的SendPort引用
  SendPort subSendPort;
  // subSendPort=hostReceivePort.sendPort;

  ///3 定义监听，监听的部分暂时不会运行
  hostReceivePort.listen((message) {
    if (message is SendPort) {
      /// 7.收到子Isolate的SendPort，此时完成了双向通信的配置阶段
      subSendPort = message;

      /// 8.向子Isolate发送计算任务的初始化数据
      subSendPort.send(2);
      subSendPort.send(10);
      subSendPort.send(20);
      subSendPort.send(30);
      subSendPort.send(40);
      subSendPort.send(48);
    } else if (message is String) {
      /// 11.打印子Isolate中计算的结果。
      print(message);
    } else {
      print("收到的数据不符合规范");
    }
  });

  ///4 定义向hostReceivePort 发送数据的hostSendPort，开始创建
  SendPort hostSendPort = hostReceivePort.sendPort;
  Isolate newIsolate = await Isolate.spawn<SendPort>(task3, hostSendPort);
}


void task3(SendPort hostSendPort) {
  ///5.创建子Isolate自己的ReceivePort，用于接收宿主传过来的初始化参数
  ReceivePort subReceivePort = ReceivePort();
  subReceivePort.listen((start) {
    if (start is int) {
      ///9. 收到宿主中初始化参数后进行计算。
      DateTime startTime = DateTime.now();
      int result = fibonacci(start);
      DateTime endTime = DateTime.now();
      var state =
          "计算耗时：${endTime.difference(startTime)}  结果：${result.toString()}";

      ///10.计算结束后通过宿主的hostSendPort将结果发出去。
      hostSendPort.send(state);
    }
  });

  ///6.将子Isolate自身的sendPort发给宿主，用于宿主向子Isolate传递初始化参数。
  hostSendPort.send(subReceivePort.sendPort);
}

int fibonacci(int n) {
  return n < 2 ? n : fibonacci(n - 2) + fibonacci(n - 1);
}
