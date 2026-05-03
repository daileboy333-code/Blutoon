import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:blutoon/main.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // طلب الإذن
    await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    // حفظ الـ token في Supabase
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);

    // تحديث الـ token عند تغييره
    _messaging.onTokenRefresh.listen(_saveToken);

    // التعامل مع الإشعارات في الخلفية
    FirebaseMessaging.onBackgroundMessage(_handleBackground);

    // الإشعارات أثناء فتح التطبيق
    FirebaseMessaging.onMessage.listen((msg) {
      final notification = msg.notification;
      if (notification != null) {
        debugPrint('إشعار: ${notification.title}');
      }
    });
  }

  static Future<void> _saveToken(String token) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase.from('users').update({'fcm_token': token}).eq('id', userId);
  }

  static Future<void> _handleBackground(RemoteMessage message) async {}
}
