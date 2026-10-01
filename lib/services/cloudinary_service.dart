import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String _cloudName = 'rozlvidv';
  static const String _apiKey = '419829162757871';
  static const String _apiSecret = 'zXk2xFW-YOYyzLPuE48soAFH_6Y';

  /// يرفع صورة ويعيد رابطها (Secure URL)، أو [null] في حالة الفشل.
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      
      // التوقيع = sha1(timestamp=123123123 + api_secret)
      final strToSign = 'timestamp=$timestamp$_apiSecret';
      final bytes = utf8.encode(strToSign);
      final digest = sha1.convert(bytes);
      final signature = digest.toString();

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final imageBytes = await imageFile.readAsBytes();
      final request = http.MultipartRequest('POST', uri)
        ..fields['api_key'] = _apiKey
        ..fields['timestamp'] = timestamp
        ..fields['signature'] = signature
        ..files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: imageFile.name.isNotEmpty ? imageFile.name : 'upload.jpg'));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        return json['secure_url'] as String?;
      } else {
        debugPrint('Cloudinary Upload Failed: ${response.statusCode} - $responseBody');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary Upload Exception: $e');
      return null;
    }
  }
}
