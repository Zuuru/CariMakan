import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot>? _userNotificationSubscription;
  StreamSubscription<QuerySnapshot>? _restoOrderSubscription;
  
  // Cache to track order status changes to prevent duplicated notifications on startup
  final Map<String, String> _orderStatusCache = {};
  // Track already shown notification IDs to prevent duplicates
  final Set<String> _shownNotificationIds = {};

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Request permissions for Android 13+
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'carimakan_channel_id',
      'cariMakan Notifications',
      channelDescription: 'Channel for cariMakan order updates and promos',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _localNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  /// Send a notification to Firestore database
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? restoId,
    Map<String, dynamic>? additionalData,
  }) async {
    final notificationRef = FirebaseFirestore.instance.collection('notifications').doc();
    await notificationRef.set({
      'id': notificationRef.id,
      'userId': userId,
      'restoId': restoId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      if (additionalData != null) 'data': additionalData,
    });
  }

  /// Listen to Customer Notifications from Firestore
  void startListeningForUser(String userId) {
    _userNotificationSubscription?.cancel();
    
    // Set a baseline timestamp to only alert for notifications created after the listener starts
    final DateTime startSessionTime = DateTime.now();

    _userNotificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', whereIn: [userId, 'all'])
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data() as Map<String, dynamic>?;
              if (data == null) continue;

              final String notifId = data['id'] ?? change.doc.id;
              final Timestamp? createdAt = data['createdAt'] as Timestamp?;
              
              bool isNew = createdAt == null || 
                           createdAt.toDate().isAfter(startSessionTime.subtract(const Duration(seconds: 5)));
              
              // Only alert for new notifications created in this session, and prevent duplicates
              if (isNew && !_shownNotificationIds.contains(notifId)) {
                
                _shownNotificationIds.add(notifId);
                
                final title = data['title'] ?? 'Notifikasi Baru';
                final body = data['body'] ?? '';
                final int idHash = notifId.hashCode;

                showNotification(
                  id: idHash,
                  title: title,
                  body: body,
                  payload: data['type'],
                );
              }
            }
          }
        });
  }

  /// Listen to new incoming orders for a restaurant (for employees)
  void startListeningForResto(String restoId) {
    _restoOrderSubscription?.cancel();

    final DateTime startSessionTime = DateTime.now();

    _restoOrderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('resto_id', isEqualTo: restoId)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            final data = change.doc.data() as Map<String, dynamic>?;
            if (data == null) continue;

            final String orderId = change.doc.id;
            final String status = data['status'] ?? 'paid';
            final Timestamp? orderDate = data['orderDate'] as Timestamp?;

            // 1. Alert Karyawan for new incoming orders (status is usually 'paid' or 'pending')
            if (change.type == DocumentChangeType.added) {
              if (orderDate != null &&
                  orderDate.toDate().isAfter(startSessionTime.subtract(const Duration(seconds: 5))) &&
                  (status == 'paid' || status == 'pending' || status == 'Menunggu')) {
                
                final String menuName = data['menuName'] ?? 'Menu Makanan';
                final String type = data['type'] ?? 'Dine In';
                final String queueNumber = data['queueNumber'] ?? '';

                showNotification(
                  id: orderId.hashCode,
                  title: 'Hai haii, ada pesanan masuk 👋',
                  body: 'Order $queueNumber ($type): $menuName',
                  payload: 'incoming_order',
                );

                // Log into restaurant notifications if needed
                sendNotification(
                  userId: 'resto_$restoId',
                  restoId: restoId,
                  title: 'Hai haii, ada pesanan masuk 👋',
                  body: 'Order $queueNumber ($type): $menuName',
                  type: 'incoming_order',
                  additionalData: {'orderId': orderId},
                );
              }
              _orderStatusCache[orderId] = status;
            }

            // 2. Alert Employee if status changes (e.g. payment confirmed by customer/system)
            if (change.type == DocumentChangeType.modified) {
              final prevStatus = _orderStatusCache[orderId];
              if (prevStatus != status) {
                _orderStatusCache[orderId] = status;

                // If payment becomes confirmed/paid
                if ((prevStatus == 'pending' || prevStatus == 'unpaid') && status == 'paid') {
                  final String queueNumber = data['queueNumber'] ?? '';
                  showNotification(
                    id: orderId.hashCode,
                    title: 'Pembayaran Diterima! 💳',
                    body: 'Pesanan $queueNumber telah dibayar dan masuk ke resto.',
                    payload: 'payment_received',
                  );
                }
              }
            }
          }
        });
  }

  void stopListening() {
    _userNotificationSubscription?.cancel();
    _restoOrderSubscription?.cancel();
    _userNotificationSubscription = null;
    _restoOrderSubscription = null;
  }
}
