import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// connection states for easy identification
enum MqttCurrentConnectionState {
  IDLE,
  CONNECTING,
  CONNECTED,
  DISCONNECTED,
  ERROR_WHEN_CONNECTING
}

enum MqttSubscriptionState { IDLE, SUBSCRIBED }

class MQTTClientWrapper {
  late MqttServerClient client;

  MqttCurrentConnectionState connectionState = MqttCurrentConnectionState.IDLE;
  MqttSubscriptionState subscriptionState = MqttSubscriptionState.IDLE;

  late Stream<List<MqttReceivedMessage<MqttMessage>>> subscription;

  // using async tasks, so the connection won't hinder the code flow
  void prepareMqttClient() async {
    _setupMqttClient();
    await _connectClient();
    _subscribeToTopic('Dart/Mqtt_client/testtopic');
    _publishMessage('Hello');
  }

  Future<Stream<String>> subscribeToResponse() async {
    String msgToReturn = "";
    // Subscribe to get response for once from data in Node-RED
    client.subscribe("liveDataResponse", MqttQos.exactlyOnce);
    // Send message to topic "liveData" for requesting data response.
    // response will be sent through topic "liveDataResponse" which was subscribed.
    _publishMessage("requestLiveData", "liveData");
    // Initialize for updates of data
    subscription = client.updates!;

    var stmSubscription =
        subscription.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      var message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    });

    // transform Mqtt message into stream of message
    var data = subscription.map((event) {
      final MqttPublishMessage recMess = event[0].payload as MqttPublishMessage;
      var message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      return message;
    });

    stmSubscription.cancel();
    client.unsubscribe("liveDataResponse");
    return data;
  }

  Future<String> publishSettings(Map msgMap) async {
    var device_name = "";
    var sensor = "";
    String result = "";
    msgMap.forEach((key, value) {
      if (key == "id") {
        device_name = value.toString().split('.')[0];
        sensor = value.toString().split('.')[1];
      }
      bool isActValue = key == "actuator_value";
      bool isTreshValue = key == "threshold";
      _publishMessage(
          isActValue
              ? value
              : isTreshValue
                  ? value
                  : "unknown",
          isActValue
              ? "$device_name/actuator/value/set"
              : isTreshValue
                  ? "$device_name/sensor/threshold/set"
                  : null);
    });
    result = device_name.isNotEmpty ? "success" : "failed";
    return result;
  }

  // waiting for the connection, if an error occurs, print it and disconnect
  Future<void> _connectClient() async {
    try {
      print('client connecting....');
      connectionState = MqttCurrentConnectionState.CONNECTING;
      await client.connect('testSMAR', 'Admin1234');
    } on Exception catch (e) {
      print('client exception - $e');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }

    // when connected, print a confirmation, else print an error
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      connectionState = MqttCurrentConnectionState.CONNECTED;
      print('client connected');
    } else {
      print(
          'ERROR client connection failed - disconnecting, status is ${client.connectionStatus}');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }
  }

  void _setupMqttClient() {
    client = MqttServerClient.withPort(
        '79de4ca025cd4477b9cb4823aca4b3a5.s2.eu.hivemq.cloud', "Pakin", 8883);
    // the next 2 lines are necessary to connect with tls, which is used by HiveMQ Cloud
    client.secure = true;
    client.securityContext = SecurityContext.defaultContext;
    client.keepAlivePeriod = 2;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
  }

  void _subscribeToTopic(String topicName) {
    print('Subscribing to the $topicName topic');
    client.subscribe(topicName, MqttQos.atMostOnce);

    // print the message when it is received
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      var message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      //print('YOU GOT A NEW MESSAGE:');
      //print(message);
    });
  }

  void _publishMessage(String message, [String? topic]) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    topic = topic ?? 'Dart/Mqtt_client/testtopic';
    //print('Publishing message "$message" to topic $topic');
    client.publishMessage(topic!, MqttQos.exactlyOnce, builder.payload!);
  }

  // callbacks for different events
  void _onSubscribed(String topic) {
    print('Subscription confirmed for topic $topic');
    subscriptionState = MqttSubscriptionState.SUBSCRIBED;
  }

  void _onDisconnected() {
    print('OnDisconnected client callback - Client disconnection');
    connectionState = MqttCurrentConnectionState.DISCONNECTED;
  }

  void _onConnected() {
    connectionState = MqttCurrentConnectionState.CONNECTED;
    print('OnConnected client callback - Client connection was successful');
  }
}