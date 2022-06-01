import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'socketmodule/core/SocketClient.dart';

void main() async {
  // var dataPacket={"key":40001,"userId":"460988679","userId":"460988679","userType":6,"appType":1,"userName":"这里","connectType":1,"socketGroupId":"7162"};
  // var dataPacket={"key":10001};
  // Future.delayed(Duration(seconds: 20),(){
  //   SocketClient.instance.dispose();
  // });
  await SocketClient.instance.connect("192.168.4.119", 6996, () => {print("连接成功")},_errorFunction);

}

_errorFunction(Object exception) {
  print(exception.toString());
  print("连接错误");
}
