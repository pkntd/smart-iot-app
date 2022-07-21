import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';

extension MapTrySet<K, V> on Map<K, V> {
  Map transformAndLocalize(
      [Map<dynamic, dynamic>? json, String nestedKey = ""]) {
    final Map<dynamic, dynamic> translations = {};
    if (json != null) {
      json.forEach((dynamic key, dynamic value) {
        if (value is Map) {
          translations.addAll(transformAndLocalize(value, "$nestedKey$key."));
        } else {
          translations["$nestedKey${key.toString()}"] = value;
        }
      });
    } else {
      forEach((dynamic key, dynamic value) {
        if (value is Map) {
          translations.addAll(transformAndLocalize(value, "$nestedKey$key."));
        } else {
          translations["$nestedKey${key.toString()}"] = value;
        }
      });
    }
    return translations;
  }

  // A function to set a value in a nested map
  // return a map that has localized path as a key and its value
  Map localizedTrySet(String target,
      [V? valueToSet, Map<dynamic, dynamic>? json, String nestedKey = '']) {
    final Map<dynamic, dynamic> translations = {};
    if (json != null) {
      json.forEach((dynamic key, dynamic value) {
        if ("$nestedKey$key" == target) {
          json[key] = valueToSet;
          translations["$nestedKey$key"] = valueToSet;
        }
        if (value is Map) {
          translations.addAll(
              localizedTrySet(target, valueToSet, value, "$nestedKey$key."));
        }
      });
    } else {
      forEach((dynamic key, dynamic value) {
        if ("$nestedKey$key" == target) {
          this[key] = valueToSet as V;
          translations["$nestedKey$key"] = valueToSet;
        }
        if (value is Map) {
          translations.addAll(
              localizedTrySet(target, valueToSet, value, "$nestedKey$key."));
        }
      });
    }

    return translations;
  }

  Map localizedTrySetFromMap(Map<dynamic, dynamic> pathAndValueMap,
      [Map<dynamic, dynamic>? json, String prefix = ""]) {
    final Map<dynamic, dynamic> translations = {};
    if (json != null) {
      json.forEach((dynamic key, dynamic value) {
        print("In json: \t$key $prefix$key ${pathAndValueMap["$prefix$key"]}");
        if (pathAndValueMap.containsKey("$prefix$key") == true) {
          print("Json with key: ${json[key]}");
          json[key] = pathAndValueMap["$prefix$key"];
          translations["$prefix$key"] = pathAndValueMap["$prefix$key"];
        }
        if (value is Map) {
          translations.addAll(
              localizedTrySetFromMap(pathAndValueMap, value, "$prefix$key."));
        }
      });
    } else {
      forEach((dynamic key, dynamic value) {
        print("$key $prefix$key");
        if (pathAndValueMap.containsKey("$prefix$key") == true) {
          print("This with key: ${this[key]}");
          this[key] = pathAndValueMap["$prefix$key"];
          translations["$prefix$key"] = pathAndValueMap["$prefix$key"];
        }
        if (value is Map) {
          translations.addAll(
              localizedTrySetFromMap(pathAndValueMap, value, "$prefix$key."));
        }
      });
    }
    print("Return translation $translations");
    return translations;
  }
}

abstract class SmIOTDatabaseMethod {
  Future<Map<String, dynamic>> getData(String userId);
  Future<void> sendData(String? userId, Map<String, dynamic> sensorStatus);
  Future<void> testSendData(String? userId, Map<String, dynamic> data);
}

class DataPayload {
  late String userId;
  late String role;
  late bool approved;
  Map<String, dynamic>? userDevice;
  late String encryption;

  DataPayload(
      {required this.userId,
      required this.role,
      required this.approved,
      this.userDevice,
      required this.encryption});

  DataPayload.createEmpty() {
    userId = "";
    role = "Unknown";
    approved = false;
    userDevice = {};
    encryption = "";
  }

  DataPayload.createForSending(Map<String, dynamic> dev) {
    userDevice = dev;
  }

  Map<String, dynamic>? loadUserDevices() {
    if (userDevice == null) {
      throw "[ERROR] Devices are not loaded. There were no devices";
    }

    return userDevice;
  }

  MapEntry<String, dynamic> displayDevice(String deviceName) {
    final devices = loadUserDevices();
    final MapEntry<String, dynamic> targetDevice;
    try {
      targetDevice =
          devices!.entries.firstWhere((element) => element.key == deviceName);
    } catch (e) {
      throw "[ERROR] Searched and found 0 device";
    }
    return targetDevice;
  }

  // Reduction here!
  // Must change to Node-RED
  List<dynamic> checkDeviceStatus(String deviceName, [Map? source]) {
    Map<String, dynamic>? target = loadUserDevices();
    List<dynamic> whereErr = [];

    // Get MQTT client and subscribe to "flag_checker"
    // require: accessId in localized map from Node-RED
    // accessId := device.sensor_name
    //

    var localizedSource =
        Map<String, dynamic>.from(source!).transformAndLocalize();
    bool isMatched = false;
    String state = "";
    localizedSource.forEach((key, value) {
      if (key.toString().endsWith("id")) {
        isMatched = (deviceName == value);
      }
      if (key.toString().endsWith("state") && isMatched) {
        state = value;
      }
    });
    // return state;

    for (dynamic device in target!.keys) {
      if (device == deviceName) {
        for (dynamic part in target[device].keys) {
          // actuator and userSensor
          for (dynamic att in target[device][part].keys) {
            // attribute of actuator and userSensor
            if (att == "sensorStatus") {
              for (dynamic sensor in target[device][part][att].keys) {
                if (target[device][part][att][sensor] == false) {
                  whereErr.add(sensor);
                }
              }
            }
            if (att == "state") {
              for (dynamic act in target[device][part][att].keys) {
                if (target[device][part][att][act] != "normal" ||
                    target[device][part][att][act] == false) {
                  whereErr.add(act);
                }
              }
            }
          }
        }
      }
    }
    return whereErr;
  }

  DataPayload decode(DataPayload payload) {
    switch (payload.encryption) {
      case "base64":
        payload.userDevice?.forEach(
          (key, value) {
            if (payload.userDevice?[key]["userSensor"] != null) {
              List? sensorList =
                  payload.userDevice?[key]["userSensor"]["sensorName"];
              for (int i = 0; i < sensorList!.length; i++) {
                for (dynamic name in payload
                    .userDevice?[key]["userSensor"]["sensorValue"]
                        [sensorList[i]]
                    .keys) {
                  for (dynamic att in payload
                      .userDevice?[key]["userSensor"]["sensorValue"]
                          [sensorList[i]][name]
                      .keys) {
                    payload.userDevice?[key]["userSensor"]["sensorValue"]
                            [sensorList[i]][name][att] =
                        utf8.decode(base64.decode(payload.userDevice?[key]
                                ["userSensor"]["sensorValue"][sensorList[i]]
                            [name][att]));
                  }
                }
              }
            }
            if (payload.userDevice?[key]["actuator"] != null) {
              Map? actuatorValue =
                  payload.userDevice?[key]["actuator"]["value"];
              for (dynamic i in actuatorValue!.keys) {
                actuatorValue[i] = utf8.decode(base64.decode(actuatorValue[i]));
              }
            }
          },
        );
        break;
      default:
        throw "[ERROR] Decoding error. Unable to decode or unsupported";
    }
    return payload;
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'role': role,
        'approved': approved,
        'userDevice': userDevice,
        'encryption': encryption,
      };

  Map<String, dynamic> toJsonForSending() => {'userDevice': userDevice};

  factory DataPayload.fromJson(Map<dynamic, dynamic> json) {
    final List<String> keyList = [
      "userId",
      "role",
      "approved",
      "userDevice",
      "encryption"
    ];
    int count = 0;
    for (String key in keyList) {
      if (!json.containsKey(key)) {
        if (key == "userId" || key == "role" || key == "encryption") {
          json[key] = "Unknown";
        } else if (key == "userDevice") {
          json[key] = {"mapID": json["userDeviceMapId"] ?? ""};
        } else if (key == "approved") {
          json[key] = false;
        }
        count += 1;
      }
    }
    if (count == 6) {
      count = 0;
      return DataPayload.createEmpty();
    }
    return DataPayload(
        userId: json['userId'],
        role: json['role'],
        approved: json['approved'],
        userDevice: json['userDevice'],
        encryption: json['encryption']);
  }
}

class DeviceBlock {
  SensorDataBlock? sensor;
  ActuatorDataBlock? actuator;

  DeviceBlock(this.sensor, this.actuator);

  DeviceBlock.createEncryptedModel(SensorDataBlock us, ActuatorDataBlock act) {
    print("\n..Filling sensor and actuator into block..\n");
    sensor = SensorDataBlock.createEncryptedModel(us);
    actuator = ActuatorDataBlock.createEncryptedModel(act);
    print(
        "[Process{DeviceModel}] \tCreated device block with size ${this.toJson().length} B");
  }

  // Require user to manually encrypted data
  DeviceBlock.createPartialEncryptedModel(
      SensorDataBlock sen, ActuatorDataBlock act) {
    sensor = sen;
    actuator = act;
  }

  Map<String, dynamic> toJson() =>
      {'userSensor': sensor?.toJson(), 'actuator': actuator?.toJson()};
  /*
  Map<String, dynamic> toJsonForSending() => {
        'userSensor': sensor?.toJsonForSending(),
        'actuator': actuator?.toJsonWithOnlyValue()
      };
  */
  factory DeviceBlock.fromJson(Map<dynamic, dynamic> json) {
    return DeviceBlock(json["userSensor"], json["actuator"]);
  }
}

class SensorDataBlock {
  dynamic id;
  Map<String, String>? type;
  Map<String, dynamic>? threshold;
  Map<String, dynamic>? timing;
  Map<String, dynamic>? calibrate;

  SensorDataBlock(
      this.id, this.type, this.threshold, this.timing, this.calibrate);

  // For using in report, not for sending data in normal process.
  SensorDataBlock.createEncryptedModel(SensorDataBlock? sensor) {
    id = sensor?.id;
    type = sensor?.type;
    threshold = sensor?.threshold;
    timing = sensor?.timing;
    calibrate = sensor?.calibrate;
    /*
    for (int i = 0; i < id?.length; i++) {
      for (dynamic name in sensorValue![id[i.toString()]].keys) {
        for (dynamic att in sensorValue![sensorName[i.toString()]][name].keys) {
          sensorValue![sensorName[i.toString()]][name][att] = base64.encode(
              utf8.encode(sensorValue![sensorName[i.toString()]][name][att]
                  .toString()));
        }
      }
    }*/
    SensorDataBlock(id, type, threshold, timing, calibrate);
    print(
        "[Process{SensorModel}] \tCreated sensor block with size ${this.toJson().length} B");
  }

  //SensorDataBlock.createForSending(this.sensorStatus, this.sensorTiming,
  //    this.calibrateValue, this.sensorThresh);
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'threshold': threshold,
        'timing': timing,
        'calibrate': calibrate
      };
  /*
  Map<String, dynamic> toJsonForSending() => {
        'sensorStatus': sensorStatus,
        'sensorThresh': sensorThresh,
        'sensorTiming': sensorTiming,
        'calibrateValue': calibrateValue
      };
  */
  factory SensorDataBlock.fromJson(Map<dynamic, dynamic> json) {
    return SensorDataBlock(json['id'], json['type'], json['threshold'],
        json['timing'], json['calibrate']);
  }
}

class ActuatorDataBlock {
  Map<String, String>? actuatorId;
  Map<String, String>? type;

  ActuatorDataBlock(this.actuatorId, this.type);

  ActuatorDataBlock.createEncryptedModel(ActuatorDataBlock? act) {
    actuatorId = act?.actuatorId;
    type = act?.type;
/*
    for (dynamic type in value!.keys) {
      value![type.toString()] =
          base64.encode(utf8.encode(value![type.toString()].toString()));
    }*/

    ActuatorDataBlock(actuatorId, type);
    print(
        "[Process{ActuatorModel}] \tCreated actuator block with size ${this.toJson().length} B");
  }
/*
  ActuatorDataBlock.createEncryptedModelWithOnlyValue(ActuatorDataBlock? act) {
    value = act?.value;
    for (dynamic type in value!.keys) {
      value![type.toString()] =
          base64.encode(utf8.encode(value![type.toString()].toString()));
    }
  }*/

  Map<String, dynamic> toJson() => {'actuatorId': actuatorId, 'type': type};

  factory ActuatorDataBlock.fromJson(Map<dynamic, dynamic> json) {
    return ActuatorDataBlock(json["actuatorId"], json["type"]);
  }
}

class SmIOTDatabase implements SmIOTDatabaseMethod {
  final ref = FirebaseDatabase.instance.ref();

  @override
  Future<Map<String, dynamic>> getData(String userId) async {
    final snapshot = await ref.child(userId).get();
    final event = await ref.child(userId).once(DatabaseEventType.value);
    // create empty model of DataPayload;
    DataPayload data = DataPayload.createEmpty();
    if (snapshot.exists) {
      final Map? userInfo = event.snapshot.value as Map?;
      // get user's data from snapshot
      final role = userInfo?.entries
          .firstWhere((element) => element.key == "role")
          .value;
      final approved = userInfo?.entries
          .firstWhere((element) => element.key == "approved")
          .value;
      var userDevices = userInfo?.entries
          .firstWhere((element) => element.key == "userDevice")
          .value;
      var widgetList = userInfo?.entries
          .firstWhere((element) => element.key == "widgetList")
          .value;
      final encryption = userInfo?.entries
          .firstWhere((element) => element.key == "encryption")
          .value;
      userDevices = Map<String, dynamic>.from(userDevices);
      widgetList = Map<String, dynamic>.from(widgetList);
      // assign value to empty model;
      data = DataPayload(
        userId: userId,
        role: role,
        approved: approved,
        encryption: encryption,
        userDevice: userDevices,
      );
      final jsons = jsonEncode(data.toJson());
      Map<String, dynamic> jsonDecoded = jsonDecode(jsons);
      return jsonDecoded;
    } else {
      data = DataPayload.createEmpty();
      return data.toJson();
    }
  }

  @override
  Future<void> sendData(String? userId, Map<String, dynamic> data) async {
    TransactionResult result =
        await ref.child('$userId').runTransaction((Object? object) {
      if (object == null) {
        return Transaction.abort();
      }
      Map<String, dynamic> _obj = Map<String, dynamic>.from(object as Map);
      print("Data : $data");
      _obj.localizedTrySetFromMap(data);
      //print("Sent! $_obj");
      return Transaction.success(_obj);
    }, applyLocally: true);
  }

  @override
  Future<void> testSendData(String? userId, Map<String, dynamic> data) async {
    await ref.child('$userId').update(data);
  }
}
