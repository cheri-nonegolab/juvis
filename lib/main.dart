import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:juvis/Subject.dart';

import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JUVIS',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //bluetooth scan
  bool _isScanning = false;
  bool _isConnecting = false;
  List<DiscoveredDevice> _scanList = List.empty(growable: true);
  final flutterReactiveBle = FlutterReactiveBle();
  late StreamSubscription<DiscoveredDevice> _scanStream;
  List<ConnectionStateUpdate> _connectList = List.empty(growable: true);
  List<StreamSubscription<ConnectionStateUpdate>> _connectStream =
      List.empty(growable: true);

  List<int> foo = List.empty(growable: true);
  final _serviceId = Uuid.parse("00001812-0000-1000-8000-00805f9b34fb");
  final _stateCharId = Uuid.parse("c01c0001-fbd4-4d5d-b3a0-eaec999c320d");
  final _frequencyModeCharId =
      Uuid.parse('c01c0002-fbd4-4d5d-b3a0-eaec999c320d');
  final _frequencyIntensityCharId =
      Uuid.parse('c01c0003-fbd4-4d5d-b3a0-eaec999c320d');
  final _sensorCharId = Uuid.parse('c01c0004-fbd4-4d5d-b3a0-eaec999c320d');
  final _sensorModeCharId = Uuid.parse('c01c0005-fbd4-4d5d-b3a0-eaec999c320d');
  final _batteryCharId = Uuid.parse('c01c0006-fbd4-4d5d-b3a0-eaec999c320d');
  final _motionErrorCharId = Uuid.parse('c01c0007-fbd4-4d5d-b3a0-eaec999c320d');

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _isScanning = false;
    _isConnecting = false;
    _scanList = List.empty(growable: true);
    _connectList = List.empty(growable: true);
    _connectStream = List.empty(growable: true);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _connectStream.forEach((element) {
      element.cancel();
    });

    _connectList.clear();
    _connectStream.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (mounted) {
      print('mount');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('JUVIS'),
      ),
      body: Center(
          child: Column(children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            child: Text('내 기기 찾기'),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                builder: (BuildContext context) {
                  return StatefulBuilder(
                      builder: (BuildContext context, StateSetter bottomState) {
                    void _bottomRepaint() {
                      bottomState(() {
                        setState(() {});
                      });
                    }

                    return Container(
                      height: MediaQuery.of(context).size.height * .9,
                      padding: EdgeInsets.all(15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop(context);
                                },
                                child: Icon(Icons.arrow_back),
                              )
                            ],
                          ),
                          const Text(
                            '내 기기 찾기',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'LED 점멸 여부로 내 기기 확인 후 등록을 진행하세요',
                            textAlign: TextAlign.start,
                            style: TextStyle(fontSize: 12),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: _isScanning
                                ? ElevatedButton(
                                    onPressed: () {
                                      _stopScan(_bottomRepaint);
                                    },
                                    child: Text('중지'))
                                : ElevatedButton(
                                    style: ButtonStyle(
                                        fixedSize: MaterialStateProperty.all(
                                            Size.fromWidth(1000))),
                                    onPressed: () {
                                      _startScan(_bottomRepaint);
                                    },
                                    child: Text('찾기'),
                                  ),
                          ),
                          Subject(text: '연결한 기기'),
                          if (_connectList.length > 0)
                            Expanded(
                                child: ListView.builder(
                              itemCount: _connectList.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: Icon(Icons.device_hub),
                                  title: Text(_connectList[index].deviceId),
                                  subtitle: Column(
                                    children: <Widget>[
                                      Text(_connectList[index]
                                          .connectionState
                                          .name),
                                      ElevatedButton(
                                          onPressed: () {
                                            _clearGATTCash(_scanList[index].id);
                                          },
                                          child: Text('clear GATT cash')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getState(_scanList[index].id);
                                          },
                                          child: Text('state')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getFrequencyMode(
                                                _scanList[index].id);
                                          },
                                          child: Text('frequency mode')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getFrequencyModeNoti(
                                                _scanList[index].id);
                                          },
                                          child: Text('frequency mode-noti')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _setFrequencyMode(
                                                _scanList[index].id, 1);
                                          },
                                          child: Text('setFrequencyMode1')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _setFrequencyMode(
                                                _scanList[index].id, 2);
                                          },
                                          child: Text('setFrequencyMode2')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _setFrequencyMode(
                                                _scanList[index].id, 3);
                                          },
                                          child: Text('setFrequencyMode3')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _setFrequencyMode(
                                                _scanList[index].id, 4);
                                          },
                                          child: Text('setFrequencyMode4')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _setFrequencyMode(
                                                _scanList[index].id, 5);
                                          },
                                          child: Text('setFrequencyMode5')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getFrequencyIntensity(
                                                _scanList[index].id);
                                          },
                                          child: Text('frequency intensity')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getFrequencyIntensityNoti(
                                                _scanList[index].id);
                                          },
                                          child: Text(
                                              '_getFrequencyIntensityNoti')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _setFrequencyIntensity(
                                                _scanList[index].id);
                                          },
                                          child:
                                              Text('_setFrequencyIntensity')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getSensor(_scanList[index].id);
                                          },
                                          child: Text('sensor')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _sensorOn(_scanList[index].id);
                                          },
                                          child: Text('sensor on')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _sensorOff(_scanList[index].id);
                                          },
                                          child: Text('sensor off')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getSensorMode(_scanList[index].id);
                                          },
                                          child: Text('sensor mode')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getBattery(_scanList[index].id);
                                          },
                                          child: Text('battery')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getBatteryNoti(
                                                _scanList[index].id);
                                          },
                                          child: Text('_getBatteryNoti')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getMotionError(
                                                _scanList[index].id);
                                          },
                                          child: Text('motion error')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _setMotionError(
                                                _scanList[index].id);
                                          },
                                          child: Text('_setMotionError')),
                                    ],
                                  ),
                                  trailing: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () {
                                      try {
                                        _disconnectDevice(
                                            index, _bottomRepaint);
                                      } catch (e) {
                                        print('💩💩💩💩💩💩💩$e');
                                        _connectStream.forEach((element) {
                                          element.cancel();
                                        });

                                        _connectList.clear();
                                        _connectStream.clear();
                                        _bottomRepaint();
                                      }
                                    },
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                          Icons.connect_without_contact),
                                    ),
                                  ),
                                );
                              },
                            )),
                          Subject(text: '연결 가능한 기기'),
                          if (_scanList.length > 0)
                            Expanded(
                                child: ListView.builder(
                              itemCount: _scanList.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  enabled: !_isScanning,
                                  leading: Icon(Icons.device_hub),
                                  title: Text(_scanList[index].name),
                                  subtitle: Column(
                                    children: <Widget>[
                                      Text(_scanList[index].id),
                                    ],
                                  ),
                                  trailing: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () {
                                      _connectDevice(
                                          _scanList[index], _bottomRepaint);
                                    },
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.add_link),
                                    ),
                                  ),
                                );
                              },
                            ))
                        ],
                      ),
                    );
                  });
                },
              );
            },
          ),
        )
      ])),
    );
  }

  void _startScan(Function repaint) async {
    _isScanning = true;
    _scanList = []; //스캔리스트 초기화
    // PermissionStatus permission =
    // await LocationPermissions().requestPermissions();
    PermissionStatus bleScanPermit = await Permission.bluetoothScan.request();
    PermissionStatus bleConnectPermit =
        await Permission.bluetoothConnect.request();

    if (bleScanPermit.isGranted && bleConnectPermit.isGranted) {
      print('허가');
      _scanStream = flutterReactiveBle.scanForDevices(
          withServices: [_serviceId],
          scanMode: ScanMode.lowLatency).listen((device) {
        if (_scanList.every((element) => element.id != device.id)) {
          _scanList.add(device);
          repaint();
        }
      }, onError: (Object error) {
        print('error?${error}');
      });
    } else {
      print(bleScanPermit);
      print(bleConnectPermit);
      print('불허');
    }
  }

  void _stopScan(Function repaint) async {
    _isScanning = false;
    _scanStream.cancel();
    repaint();
  }

  void _connectDevice(DiscoveredDevice device, Function repaint) async {
    if (_isConnecting) return print('디바이스와 연결 시도중입니다.');

    _connectStream.add(flutterReactiveBle
        .connectToAdvertisingDevice(
            id: device.id,
            withServices: [_serviceId], //서비스 uuid
            prescanDuration: const Duration(seconds: 5), //스캔시간
            connectionTimeout: Duration(seconds: 5)) //연결 타입아웃
        .listen((ConnectionStateUpdate event) {
      if (_connectList.every((element) => element.deviceId != device.id)) {
        _connectList.add(event);
      } else {
        _connectList = _connectList
            .map((element) => element.deviceId == device.id ? event : element)
            .toList();
      }

      switch (event.connectionState) {
        case DeviceConnectionState.connecting:
          {
            _isConnecting = true;
            print('connecting ${device.id}');
            break;
          }
        case DeviceConnectionState.connected:
          {
            _isConnecting = false;
            print('connected ${device.id}');

            //디바이스 state 구독
            final characteristicSub = QualifiedCharacteristic(
                serviceId: _serviceId,
                characteristicId: _stateCharId,
                deviceId: device.id);
            flutterReactiveBle
                .subscribeToCharacteristic(characteristicSub)
                .listen((data) {
              print('🤚🏻🤚🏻 device-state ::: ${data}');
            }, onError: (dynamic error) {
              print('🤚🏻🤚🏻 device-state-error ::: ${error}');
            });

            break;
          }
        case DeviceConnectionState.disconnecting:
          {
            _isConnecting = false;
            print('disconnecting ${device.id}');
            break;
          }
        case DeviceConnectionState.disconnected:
          {
            _isConnecting = false;
            print('disconnected ${device.id}');
            break;
          }
      }
      repaint();
    }, onError: (error) {
      print('💩💩💩💩커넥션오류');
      _connectList.clear();
      _connectStream.clear();
      repaint();
    }));
  }

  void _disconnectDevice(int index, Function repaint) {
    _connectStream[index].cancel();

    _connectList.removeAt(index);
    _connectStream.removeAt(index);
    repaint();
  }

  void _getState(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _stateCharId,
        deviceId: deviceId);
    final response =
        await flutterReactiveBle.readCharacteristic(characteristic);
    print("_getState::: ${response}");
  }

  void _getFrequencyMode(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _frequencyModeCharId,
        deviceId: deviceId);
    final response =
        await flutterReactiveBle.readCharacteristic(characteristic);
    print("_getFrequencyMode::: ${response}");
  }

  void _getFrequencyModeNoti(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _frequencyModeCharId,
        deviceId: deviceId);
    final response = await flutterReactiveBle
        .subscribeToCharacteristic(characteristic)
        .listen((event) {
      print("_getFrequencyModeNoti::: ${event}");
    }, onError: (error) {
      print("_getFrequencyModeNoti-error::: ${error}");
    });
  }

  void _setFrequencyMode(deviceId, int value) async {
    int binary = 0x01;

    switch (value) {
      case 1:
        binary = 0x01;
        break;
      case 2:
        binary = 0x02;
        break;
      case 3:
        binary = 0x03;
        break;
      case 4:
        binary = 0x04;
        break;
      case 5:
        binary = 0x05;
        break;
      default:
        binary = 0x01;
    }

    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _frequencyModeCharId,
        deviceId: deviceId);
    final response = await flutterReactiveBle
        .writeCharacteristicWithResponse(characteristic, value: [binary, 0x60]);
    print('_setFrequencyMode:::');
  }

  void _getFrequencyIntensity(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _frequencyIntensityCharId,
        deviceId: deviceId);
    final response =
        await flutterReactiveBle.readCharacteristic(characteristic);
    print("_getFrequencyIntensity::: ${response}");
  }

  void _getFrequencyIntensityNoti(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _frequencyIntensityCharId,
        deviceId: deviceId);
    final response = await flutterReactiveBle
        .subscribeToCharacteristic(characteristic)
        .listen((event) {
      print("__getFrequencyIntensityNoti::: ${event}");
    }, onError: (error) {
      print("__getFrequencyIntensityNoti-error::: ${error}");
    });
  }

  void _setFrequencyIntensity(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _frequencyIntensityCharId,
        deviceId: deviceId);
    final response = await flutterReactiveBle
        .writeCharacteristicWithResponse(characteristic, value: [0x15]);
    print("_setFrequencyIntensity:::");
  }

  void _getSensor(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _sensorCharId,
        deviceId: deviceId);
    final response =
        await flutterReactiveBle.readCharacteristic(characteristic);
    print("_getSensor::: ${response}");
  }

  void _sensorOn(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _sensorCharId,
        deviceId: deviceId);
    print(_connectList);
    final response = await flutterReactiveBle
        .writeCharacteristicWithoutResponse(characteristic, value: [17]);
    print("_sensorOn::: ");
  }

  void _sensorOff(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _sensorCharId,
        deviceId: deviceId);
    final response = await flutterReactiveBle
        .writeCharacteristicWithoutResponse(characteristic, value: [0x00]);
    print("_sensorOff::: ");
  }

  void _getSensorMode(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _sensorModeCharId,
        deviceId: deviceId);
    final response = flutterReactiveBle
        .subscribeToCharacteristic(characteristic)
        .listen((data) {
      print('_getSensorMode::: $data');
    }, onError: (dynamic error) {
      print('_getSensorMode Error!! ::: $error');
    });
  }

  void _getBattery(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _batteryCharId,
        deviceId: deviceId);
    final response =
        await flutterReactiveBle.readCharacteristic(characteristic);
    print("_getBattery::: ${response}");
  }

  void _getBatteryNoti(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _batteryCharId,
        deviceId: deviceId);
    final response = await flutterReactiveBle
        .subscribeToCharacteristic(characteristic)
        .listen((data) {
      print('_getBatteryNoti::: $data');
    }, onError: (dynamic error) {
      print('_getBatteryNoti Error!! ::: $error');
    });
  }

  void _getMotionError(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _motionErrorCharId,
        deviceId: deviceId);
    final response =
        await flutterReactiveBle.readCharacteristic(characteristic);
    print("_getMotionError::: ${response}");
  }

  void _setMotionError(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _motionErrorCharId,
        deviceId: deviceId);
    final response = await flutterReactiveBle
        .writeCharacteristicWithResponse(characteristic, value: [0x01]);
    print("_setMotionError:::");
  }

  void _clearGATTCash(deviceId) async {
    await flutterReactiveBle.clearGattCache(deviceId);
  }
}
