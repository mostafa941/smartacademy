import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class OneSignalService {
  static const String appId = "YOUR_ONESIGNAL_APP_ID"; // ضع الآي دي هنا
  static const String restApiKey = "YOUR_REST_API_KEY"; // ضع المفتاح هنا

  static Future<void> sendNotification({
    required String title,
    required String body,
    List<String>? targetPlayerIds, // معرفات أجهزة الطلاب إن وجدت
  }) async {
    if (appId == "YOUR_ONESIGNAL_APP_ID") {
      debugPrint("OneSignal is not configured yet. Push notification skipped.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $restApiKey',
        },
        body: jsonEncode({
          'app_id': appId,
          'headings': {'en': title, 'ar': title},
          'contents': {'en': body, 'ar': body},
          'included_segments': targetPlayerIds == null ? ['All'] : null,
          'include_player_ids': targetPlayerIds,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("Push notification sent successfully!");
      } else {
        debugPrint("Failed to send push notification: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error sending push notification: $e");
    }
  }
}
