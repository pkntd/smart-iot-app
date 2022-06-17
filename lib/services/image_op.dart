import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

abstract class ImageGetter {
  Future<void> getImageFromStorage(String userID, String referPath);
  Future<void> uploadPic(BuildContext context,File? image,String username);
}

class ImageStorageManager implements ImageGetter {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  late var destinationOfProfileImage = 'Profile/';

  @override
  Future<void> getImageFromStorage(String userID, String referPath) async {
    throw Exception();
  }

  @override
  Future<void> uploadPic(BuildContext context,File? image ,String username) async {
    var bytes = utf8.encode(username);
    var digest = sha256.convert(bytes);
    print(digest);

    if (image == null) throw Exception("Image not found.");
    destinationOfProfileImage += digest.toString();

    try{
      final ref = _firebaseStorage.ref(destinationOfProfileImage).child("UserProfile$digest");
      await ref.putFile(image);
    } catch (e) {
      throw "Error Occurred: $e";
    }

  }


}