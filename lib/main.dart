import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:juvis/Subject.dart';

import 'package:permission_handler/permission_handler.dart';

class DeviceInfo extends ConnectionStateUpdate {
  String name;
  DeviceInfo(
      {required this.name,
      required super.connectionState,
      required super.deviceId,
      super.failure});
}

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
  List<DeviceInfo> _connectList = List.empty(growable: true);
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
            child: Text('??? ?????? ??????'),
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
                            '??? ?????? ??????',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'LED ?????? ????????? ??? ?????? ?????? ??? ????????? ???????????????',
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
                                    child: Text('??????'))
                                : ElevatedButton(
                                    style: ButtonStyle(
                                        fixedSize: MaterialStateProperty.all(
                                            Size.fromWidth(1000))),
                                    onPressed: () {
                                      _startScan(_bottomRepaint);
                                    },
                                    child: Text('??????'),
                                  ),
                          ),
                          Subject(text: '????????? ??????'),
                          if (_connectList.length > 0)
                            Expanded(
                                child: ListView.builder(
                              itemCount: _connectList.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: Icon(Icons.device_hub),
                                  title: Text(_connectList[index].name),
                                  subtitle: Column(
                                    children: <Widget>[
                                      Text(_connectList[index].deviceId),
                                      Text(_connectList[index]
                                          .connectionState
                                          .name),
                                      ElevatedButton(
                                          onPressed: () {
                                            _clearGATTCash(
                                                _connectList[index].deviceId);
                                          },
                                          child: Text('GATT ?????? ??????')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getState(
                                                _connectList[index].deviceId);
                                          },
                                          child: Text('State ????????????')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getFrequencyMode(
                                                _connectList[index].deviceId);
                                          },
                                          child: Text('???????????? ????????????')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getFrequencyModeNoti(
                                                _connectList[index].deviceId);
                                          },
                                          child: Text('???????????? ????????????(notify)')),
                                      Text(
                                        "???????????? ??????",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: <Widget>[
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyMode(
                                                      _connectList[index]
                                                          .deviceId,
                                                      1);
                                                },
                                                child: Text("1")),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyMode(
                                                      _connectList[index]
                                                          .deviceId,
                                                      2);
                                                },
                                                child: Text('2')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyMode(
                                                      _connectList[index]
                                                          .deviceId,
                                                      3);
                                                },
                                                child: Text('3')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyMode(
                                                      _connectList[index]
                                                          .deviceId,
                                                      4);
                                                },
                                                child: Text('4')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyMode(
                                                      _connectList[index]
                                                          .deviceId,
                                                      5);
                                                },
                                                child: Text('5')),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getFrequencyIntensity(
                                                _connectList[index].deviceId);
                                          },
                                          child: Text('???????????? ????????????')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getFrequencyIntensityNoti(
                                                _connectList[index].deviceId);
                                          },
                                          child: Text('???????????? ????????????(notify)')),
                                      Text(
                                        "???????????? ??????",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: <Widget>[
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyIntensity(
                                                      _connectList[index]
                                                          .deviceId,
                                                      0);
                                                },
                                                child: Text('0')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyIntensity(
                                                      _connectList[index]
                                                          .deviceId,
                                                      1);
                                                },
                                                child: Text('1')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyIntensity(
                                                      _connectList[index]
                                                          .deviceId,
                                                      2);
                                                },
                                                child: Text('2')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyIntensity(
                                                      _connectList[index]
                                                          .deviceId,
                                                      3);
                                                },
                                                child: Text('3')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyIntensity(
                                                      _connectList[index]
                                                          .deviceId,
                                                      4);
                                                },
                                                child: Text('4')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyIntensity(
                                                      _connectList[index]
                                                          .deviceId,
                                                      5);
                                                },
                                                child: Text('5')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyIntensity(
                                                      _connectList[index]
                                                          .deviceId,
                                                      6);
                                                },
                                                child: Text('6')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyIntensity(
                                                      _connectList[index]
                                                          .deviceId,
                                                      7);
                                                },
                                                child: Text('7')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyIntensity(
                                                      _connectList[index]
                                                          .deviceId,
                                                      8);
                                                },
                                                child: Text('8')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyIntensity(
                                                      _connectList[index]
                                                          .deviceId,
                                                      9);
                                                },
                                                child: Text('9')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyIntensity(
                                                      _connectList[index]
                                                          .deviceId,
                                                      10);
                                                },
                                                child: Text('10')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyIntensity(
                                                      _connectList[index]
                                                          .deviceId,
                                                      11);
                                                },
                                                child: Text('11')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyIntensity(
                                                      _connectList[index]
                                                          .deviceId,
                                                      12);
                                                },
                                                child: Text('12')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyIntensity(
                                                      _connectList[index]
                                                          .deviceId,
                                                      13);
                                                },
                                                child: Text('13')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyIntensity(
                                                      _connectList[index]
                                                          .deviceId,
                                                      14);
                                                },
                                                child: Text('14')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setFrequencyIntensity(
                                                      _connectList[index]
                                                          .deviceId,
                                                      15);
                                                },
                                                child: Text('15')),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getSensor(
                                                _connectList[index].deviceId);
                                          },
                                          child: Text('?????? On/Off ????????????')),
                                      Text(
                                        "??????On/Off??????",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: <Widget>[
                                            ElevatedButton(
                                                onPressed: () {
                                                  _sensorOn(
                                                      _connectList[index]
                                                          .deviceId,
                                                      true,
                                                      true);
                                                },
                                                child: Text('??????On/??????On')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _sensorOn(
                                                      _connectList[index]
                                                          .deviceId,
                                                      true,
                                                      false);
                                                },
                                                child: Text('??????ON/??????Off')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _sensorOn(
                                                      _connectList[index]
                                                          .deviceId,
                                                      false,
                                                      true);
                                                },
                                                child: Text('??????Off/??????On')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _sensorOff(_connectList[index]
                                                      .deviceId);
                                                },
                                                child: Text('??????Off/??????Off')),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getSensorMode(
                                                _connectList[index].deviceId);
                                          },
                                          child: Text('???????????? ????????????(notify)')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getBattery(
                                                _connectList[index].deviceId);
                                          },
                                          child: Text('????????? ????????????')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getBatteryNoti(
                                                _connectList[index].deviceId);
                                          },
                                          child: Text('????????? ????????????(notify)')),
                                      ElevatedButton(
                                          onPressed: () {
                                            _getMotionError(
                                                _connectList[index].deviceId);
                                          },
                                          child: Text('???????????? ????????????')),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: <Widget>[
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setMotionError(
                                                      _connectList[index]
                                                          .deviceId,
                                                      true);
                                                },
                                                child: Text('???????????? ?????? On')),
                                            ElevatedButton(
                                                onPressed: () {
                                                  _setMotionError(
                                                      _connectList[index]
                                                          .deviceId,
                                                      false);
                                                },
                                                child: Text('???????????? ?????? Off')),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                  trailing: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () {
                                      try {
                                        _disconnectDevice(
                                            index, _bottomRepaint);
                                      } catch (e) {
                                        print('????????????????????????????$e');
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
                          Subject(text: '?????? ????????? ??????'),
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
    _scanList = []; //??????????????? ?????????
    // PermissionStatus permission =
    // await LocationPermissions().requestPermissions();
    PermissionStatus bleScanPermit = await Permission.bluetoothScan.request();
    PermissionStatus bleConnectPermit =
        await Permission.bluetoothConnect.request();

    if (bleScanPermit.isGranted && bleConnectPermit.isGranted) {
      print('??????');
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
      print('??????');
    }
  }

  void _stopScan(Function repaint) async {
    _isScanning = false;
    _scanStream.cancel();
    repaint();
  }

  void _connectDevice(DiscoveredDevice device, Function repaint) async {
    if (_isConnecting) return print('??????????????? ?????? ??????????????????.');

    _connectStream.add(flutterReactiveBle
        .connectToAdvertisingDevice(
            id: device.id,
            withServices: [_serviceId], //????????? uuid
            prescanDuration: const Duration(seconds: 5), //????????????
            connectionTimeout: Duration(seconds: 5)) //?????? ????????????
        .listen((ConnectionStateUpdate event) {
      if (_connectList.every((element) => element.deviceId != device.id)) {
        _connectList.add(DeviceInfo(
            name: device.name,
            connectionState: event.connectionState,
            deviceId: event.deviceId,
            failure: event.failure));
      } else {
        _connectList = _connectList
            .map((element) => element.deviceId == device.id
                ? DeviceInfo(
                    name: device.name,
                    connectionState: event.connectionState,
                    deviceId: event.deviceId,
                    failure: event.failure)
                : element)
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

            //???????????? state ??????
            final characteristicSub = QualifiedCharacteristic(
                serviceId: _serviceId,
                characteristicId: _stateCharId,
                deviceId: device.id);
            flutterReactiveBle
                .subscribeToCharacteristic(characteristicSub)
                .listen((data) {
              print('???????????? state ????????????(notify) ::: ${data}');
            }, onError: (dynamic error) {
              print('???????????? state ????????????(notify)-error ::: ${error}');
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
      print('???????????????????????????????');
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
    print("???????????? state ????????????::: ${response}");
  }

  // void _getStateNoti(deviceId) async {
  //   final characteristic = QualifiedCharacteristic(
  //       serviceId: _serviceId,
  //       characteristicId: _frequencyModeCharId,
  //       deviceId: deviceId);
  //   final response = await flutterReactiveBle
  //       .subscribeToCharacteristic(characteristic)
  //       .listen((event) {
  //     print("???????????? state ????????????(notify)::: ${event}");
  //   }, onError: (error) {
  //     print("???????????? state ????????????(notify)-error::: ${error}");
  //   });
  // }

  void _getFrequencyMode(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _frequencyModeCharId,
        deviceId: deviceId);
    final response =
        await flutterReactiveBle.readCharacteristic(characteristic);
    print("???????????? ????????????????????????::: ${response}");
  }

  void _getFrequencyModeNoti(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _frequencyModeCharId,
        deviceId: deviceId);
    final response = await flutterReactiveBle
        .subscribeToCharacteristic(characteristic)
        .listen((event) {
      print("???????????? ????????????????????????(notify)::: ${event}");
    }, onError: (error) {
      print("???????????? ????????????????????????(notify)-error::: ${error}");
    });
  }

  void _setFrequencyMode(deviceId, int mode) async {
    int binary = 0x00;

    switch (mode) {
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
        binary = 0x00;
    }

    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _frequencyModeCharId,
        deviceId: deviceId);
    final response = await flutterReactiveBle.writeCharacteristicWithResponse(
        characteristic,
        value: [binary, 0x3D]); //60?????????
    print('???????????? ???????????? ??????:::');
  }

  void _getFrequencyIntensity(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _frequencyIntensityCharId,
        deviceId: deviceId);
    final response =
        await flutterReactiveBle.readCharacteristic(characteristic);
    print("???????????? ???????????? ????????????::: ${response}");
  }

  void _getFrequencyIntensityNoti(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _frequencyIntensityCharId,
        deviceId: deviceId);
    final response = await flutterReactiveBle
        .subscribeToCharacteristic(characteristic)
        .listen((event) {
      print("???????????? ???????????? ????????????(notify)::: ${event}");
    }, onError: (error) {
      print("???????????? ???????????? ????????????(notify)-error::: ${error}");
    });
  }

  void _setFrequencyIntensity(deviceId, int intensity) async {
    int value = 0x00;
    switch (intensity) {
      case 0:
        value = 0x00;
        break;
      case 1:
        value = 0x01;
        break;
      case 2:
        value = 0x02;
        break;
      case 3:
        value = 0x03;
        break;
      case 4:
        value = 0x04;
        break;
      case 5:
        value = 0x05;
        break;
      case 6:
        value = 0x06;
        break;
      case 7:
        value = 0x07;
        break;
      case 8:
        value = 0x08;
        break;
      case 9:
        value = 0x09;
        break;
      case 10:
        value = 0x0A;
        break;
      case 11:
        value = 0x0B;
        break;
      case 12:
        value = 0x0C;
        break;
      case 13:
        value = 0x0D;
        break;
      case 14:
        value = 0x0E;
        break;
      case 15:
        value = 0x0F;
        break;
      default:
        value = 0x00;
    }

    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _frequencyIntensityCharId,
        deviceId: deviceId);
    final response = await flutterReactiveBle
        .writeCharacteristicWithResponse(characteristic, value: [value]);
    print("???????????? ???????????? ??????:::");
  }

  void _getSensor(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _sensorCharId,
        deviceId: deviceId);
    final response =
        await flutterReactiveBle.readCharacteristic(characteristic);
    print("???????????? ?????? on/off ????????????::: ${response}");
  }

  void _sensorOn(deviceId, bool frequency, bool sensor) async {
    var value = 0x00;
    if (frequency == true && sensor == true) {
      value = 17;
    } else if (frequency == false && sensor == true) {
      value = 0x01;
    } else if (frequency == true && sensor == false) {
      value = 16;
    }

    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _sensorCharId,
        deviceId: deviceId);

    final response = await flutterReactiveBle
        .writeCharacteristicWithoutResponse(characteristic, value: [value]);
    print("???????????? sensor On::: ");
    print(_connectList);
    print(deviceId);
  }

  void _sensorOff(deviceId) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _sensorCharId,
        deviceId: deviceId);
    final response = await flutterReactiveBle
        .writeCharacteristicWithoutResponse(characteristic, value: [0x00]);
    print("???????????? Sensor Off::: ");
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

  void _setMotionError(deviceId, bool value) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: _serviceId,
        characteristicId: _motionErrorCharId,
        deviceId: deviceId);
    final response = await flutterReactiveBle.writeCharacteristicWithResponse(
        characteristic,
        value: [value ? 0x01 : 0x00]);
    print("_setMotionError:::");
  }

  void _clearGATTCash(deviceId) async {
    await flutterReactiveBle.clearGattCache(deviceId);
  }
}
