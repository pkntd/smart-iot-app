```dart
Map userData = {
    "userId" : "",
    "role" : "",
    "approved" : "",
    "userDevice" : {
        "device1" : {
            "actuator" : {
                "actuatorID" : ["actuator1","actuatorN"],
                "type" : {
                    "actuator1" : "type1",
                    "actuatorN" : "typeN"
                },
                // Move state and value to server-side
            },
            "userSensor" : {
                "sensorName" : ["sensor1","sensorN"],
                "sensorType" : {
                    "sensor1" : "type1",
                    "sensorN" : "typeN"
                },
                "sensorThresh" : {
                    "sensor1" : 90.0 // Will be encrypted while creating report
                    "sensorN" : 123.4
                },
                "sensorTiming" : {
                    "sensor1" : "Auto",
                    "sensorN" : "Manual"
                },
                "calibrateValue" : {
                    "sensor1" : "+1.1",
                    "sensorN" : "-0.5"
                }
                // Move state and value to server-side
            },
        },
        "device2" : {
            "actuator" : {},
            "userSensor" : {}
        },
    },
    "encryption" : ""
};
```

## Node-RED
```json
{
    "timestamp-in-ISO-8601-format" : 
    {
        "id" : "type := String, format:=device.sensor_name", // send by device
        "value" : "type := double",
        "flag" : "type := String, default => flag{threshNotSet}",
        "message" : "type := String, generate based on flag",
        "state" : "type := String || bool, "
    }
}
```
#### localized json version
> length of this JSON version is fixed length.  
> `payload_timestamp.length = 5;`
```json
{
    "timestamp.id":"type:=String",
    "timestamp.value":"type:=double",
    "timestamp.flag":"type:=String",
    "timestamp.message":"type:=String",
    "timestamp.state":"type:=String||bool"
}
```
## Real-time database
```json
{
    "userId" : "type:=String",
    "approved": "type:=bool",
    "role": "type:=String",
    "userDevice": 
    {
        "device_name":
        {
            "actuator" : 
            {
                "id":["actuator_name"],
                "type":
                {
                    "actuator_name":"actuator_type"
                },
                "notifyUser?":["type:=bool"]
            },
            "sensor" :
            {
                "id":["sensor_name"],
                "type":
                {
                    "sensor_name":"sensor_type"
                },
                "threshold":
                {
                    "sensor_name":"type:=double"
                },
                "timing":
                {
                    "sensor_name":"type:=String, Auto/Manual/Custom"
                },
                "calibrate":
                {
                    "sensor_name":"type:=double, increase-decrease sensor value"
                },
                "notifyUser?":["type:=bool"]
            }
        },
    },
    "encryption":"type:=String"
}
```
#### localized json version
> Length of this JSON version depends on the number of actuators and sensors  
> `actuator_section.length = 3*act` where `act` is the number of actuators  
> `sensor_section.length = 6*sen` where `sen` is the number of sensors  
> `device_name.length` = `3*act + 6*sen`  
> `data_payload.length = 3 + (3*act + 6*sen)*N;` where N is the number of devices
```json
{
    "userId" : "type:=String",
    "approved": "type:=bool",
    "role": "type:=String",
    "userDevice.device_name.actuator.id.0":"type:=String, actuator_name",
    "userDevice.device_name.actuator.type.actuator_name":"type:=String",
    "userDevice.device_name.actuator.notifyUser?.0":"type:=bool",
    "userDevice.device_name.sensor.id.0":"type:=String, sensor_name",
    "userDevice.device_name.sensor.type.sensor_name":"type:=String",
    "userDevice.device_name.sensor.threshold.sensor_name":"type:=double",
    "userDevice.device_name.sensor.timing.sensor_name":"type:=String",
    "userDevice.device_name.sensor.calibrate.sensor_name":"type:=double",
    "userDevice.device_name.sensor.notifyUser?.0":"type:=bool"
}
```
