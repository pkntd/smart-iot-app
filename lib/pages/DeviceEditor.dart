import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_iot_app/db/threshold_settings.dart';

class DeviceEditor extends StatefulWidget {
  final String deviceName;

  const DeviceEditor({Key? key, required this.deviceName}) : super(key: key);

  @override
  State createState() => _DeviceEditor();
}

class _DeviceEditor extends State<DeviceEditor> {
  TextEditingController thresholdController = TextEditingController();

  // Threshold setting
  // Return 1 if single value and >1 if multiple
  // ignore: long-method
  thresholdConfig() {
    // Input: deviceName

    ThresholdDatabase thd = ThresholdDatabase.instance;
    String id = sha1.convert(utf8.encode(widget.deviceName)).toString();

    threshTextField(topicName, controller) => Row(
          children: [
            Text(topicName.toString()),
            Expanded(
              child: TextFormField(
                maxLines: 1,
                keyboardType: TextInputType.number,
                enabled: true,
                controller: controller,
              ),
            ),
          ],
        );

    combineForSave(nSlot, pSlot, kSlot) => [nSlot, pSlot, kSlot];

    saveButton(texts) => TextButton(
          onPressed: () async {
            bool isMulti = texts.runtimeType == List;
            // print("[Press&Save] ${texts[2].text}");
            String val = isMulti
                ? "${texts[0].text}/${texts[1].text}/${texts[2].text}"
                : texts.text;

            thd.add({
              "_id": id,
              "_threshVal": isMulti ? val : texts.text,
            });
          },
          child: const Text("Save"),
        );

    placeTextInForm() => FutureBuilder(
          future: thd.getThresh(id),
          builder: (context, snapshot) {
            // check
            if (snapshot.hasData) {
              List<Widget> widgetList = [];
              if (widget.deviceName.contains("NPK")) {
                // multi
                dynamic data = snapshot.data.runtimeType == double
                    ? snapshot.data
                    : snapshot.data as Map;

                Map value = data == Map
                    ? data
                    : {
                        "N": 0.0,
                        "P": 0.0,
                        "K": 0.0,
                      };
                TextEditingController nSlot =
                    TextEditingController(text: value["N"].toString());
                TextEditingController pSlot =
                    TextEditingController(text: value["P"].toString());
                TextEditingController kSlot =
                    TextEditingController(text: value["K"].toString());

                widgetList.addAll([
                  threshTextField("N", nSlot),
                  threshTextField("P", pSlot),
                  threshTextField("K", kSlot),
                  saveButton(combineForSave(
                    nSlot,
                    pSlot,
                    kSlot,
                  )),
                ]);
              } else {
                // single
                TextEditingController defaultController =
                    TextEditingController(text: snapshot.data.toString());
                widgetList.addAll([
                  threshTextField("Threshold", defaultController),
                  saveButton(defaultController),
                ]);
              }

              return ListView(
                shrinkWrap: true,
                children: [...widgetList],
              );
            }

            return Container();
          },
        );

    return placeTextInForm();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text("Settings"),
      initiallyExpanded: false,
      children: [
        thresholdConfig(),
      ],
    );
  }
}
