import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import '../util/KMPUtil.dart';

class SocketClient {
  static const _timeOutValue = 5;

  static const headerTag = [255, 4, 16, 2];

  Queue<int> rawDataQueen = Queue();

  Function? _success;

  Function? _error;

  SocketClient._privateConstructor();

  static final SocketClient instance = SocketClient._privateConstructor();

  Socket? clientSocket;

  Timer? _spaceCheckTimer;
  static const int _spaceDurationLength = 15000;
  static const int _heartBeatDurationLength = 5000;

  static const Duration _spaceDuration =
      Duration(milliseconds: _spaceDurationLength);
  static const Duration _heartBeatDuration =
      Duration(milliseconds: _heartBeatDurationLength);

  int _lastUpdate = 0;

  Timer? _heartBeatTimer;

  static const _heartBeatPacket = {"key": 10001};

  connect(String targetUrlOrIP, int port, Function _success,
      Function _error) async {
    if (clientSocket == null) {
      this._success = _success;
      this._error = _error;
      await Socket.connect(targetUrlOrIP, port,
              timeout: Duration(seconds: _timeOutValue))
          .then(_onConnected)
          .onError(_onError);
    }
  }

  FutureOr _onConnected(Socket value) async {
    _lastUpdate = DateTime.now().millisecond;
    _spaceCheckTimer = Timer.periodic(_spaceDuration, _checkSpace);
    _heartBeatTimer = Timer.periodic(_heartBeatDuration, _sendHeartBeat);

    clientSocket = value;
    _success!();
    clientSocket!.listen((event) {
      //每次收到数据都更新这个
      _lastUpdate = DateTime.now().millisecond;
      //先加数据
      rawDataQueen.addAll(event);
      List<int> rawDataList = rawDataQueen.toList();
      //超过帧头长度视为开始解析
      if (rawDataList.length > 16) {
        int kmpResult = KMPUtil.instance.useKMP(rawDataList, headerTag);
        while (kmpResult != -1) {
          //说明找到了第一个头的位置
          if (rawDataList.length >= kmpResult + 8) {
            //这里说明大小信息是完整的
            List<int> sizeInfo =
                rawDataList.sublist(kmpResult + 4, kmpResult + 8);
            //计算出真实大小
            int realSize = _computeRealSize(sizeInfo);
            if (rawDataList.length >= 16 + realSize + kmpResult) {
              //说明数据完整 可以拿到数据去做解析
              List<int> realData = rawDataList.sublist(
                  kmpResult + 16, kmpResult + 16 + realSize);
              print(utf8.decode(realData));
              //剩余的数据
              List<int> remainList =
                  rawDataList.sublist(kmpResult + 16 + realSize);
              rawDataQueen = Queue.from(remainList);
              kmpResult = KMPUtil.instance.useKMP(remainList, headerTag);
            }
          }
        }
      }
    }, onError: (e) {
      dispose();
    });
    await clientSocket!.done.catchError((e) {
      _error!(e);
    });
  }

  FutureOr _onError(Object error, StackTrace stackTrace) {
    _error!(error);
  }

  List<int> _computeDataSizePacket(int size) {
    int shang = size;
    List<int> sizeInfo = List.filled(4, 0);
    for (int i = 0; i < sizeInfo.length; i++) {
      int yu = shang % 256;
      sizeInfo[i] = yu;
      shang = (shang ~/ 256);
    }
    return sizeInfo;
  }

  int _computeRealSize(List<int> sizeInfo) {
    int length = 0;
    for (int i = 0; i < sizeInfo.length; i++) {
      if (i == 0) {
        length = sizeInfo[i] % 256;
      } else {
        length = (sizeInfo[i] % 256) * 256 * i + length;
      }
    }

    return length;
  }

  void sendData(Socket client, Map data) {
    String resultStr = jsonEncode(data);
    List<int> dataPacket = utf8.encode(resultStr);
    List<int> sizeInfo = _computeDataSizePacket(dataPacket.length);
    List<int> fullPacket = [
      255,
      4,
      16,
      2,
      ...sizeInfo,
      0,
      0,
      0,
      0,
      0,
      0,
      255,
      5,
      ...dataPacket
    ];
    try {
      client.add(fullPacket);
    } catch (o) {
      print(o);
    }
  }

  void _checkSpace(Timer timer) {
    //空闲检测生效
    if (DateTime.now().millisecond - _lastUpdate > _spaceDurationLength) {
      print("触发空闲检测");
      dispose();
    }
  }

  void dispose() {
    if (_heartBeatTimer != null) {
      if (_heartBeatTimer!.isActive) {
        _heartBeatTimer!.cancel();
      }
      _heartBeatTimer = null;
    }

    if (_spaceCheckTimer != null) {
      if (_spaceCheckTimer!.isActive) {
        _spaceCheckTimer!.cancel();
      }
      _spaceCheckTimer = null;
    }

    if (clientSocket != null) {
      clientSocket!.destroy();
    }
  }

  void _sendHeartBeat(Timer timer) {
    if (clientSocket != null) {
      sendData(clientSocket!, _heartBeatPacket);
    }
  }
}
