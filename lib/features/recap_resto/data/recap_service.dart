import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../presentation/widgets/trend_card.dart';
import '../presentation/widgets/menu_terlaris_card.dart';
import '../presentation/widgets/transaksi_terakhir_card.dart';

class RecapService {
  static final _db = FirebaseFirestore.instance;

  static Future<String?> getCurrentRestoId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snapshot = await _db
        .collection('restaurants')
        .where('owner_id', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.id;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamOrdersToday(String restoId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _db
        .collection('orders')
        .where('resto_id', isEqualTo: restoId)
        .where('orderDate', isGreaterThanOrEqualTo: startOfDay)
        .where('orderDate', isLessThanOrEqualTo: endOfDay)
        .snapshots();
  }

  static Future<Map<String, dynamic>> getRekapHarian(String restoId) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));
    final endOfYesterday = endOfToday.subtract(const Duration(days: 1));

    final todaySnapshot = await _db
        .collection('orders')
        .where('resto_id', isEqualTo: restoId)
        .where('orderDate', isGreaterThanOrEqualTo: startOfToday)
        .where('orderDate', isLessThanOrEqualTo: endOfToday)
        .get();

    final yesterdaySnapshot = await _db
        .collection('orders')
        .where('resto_id', isEqualTo: restoId)
        .where('orderDate', isGreaterThanOrEqualTo: startOfYesterday)
        .where('orderDate', isLessThanOrEqualTo: endOfYesterday)
        .get();

    double incomeToday = 0;
    int ordersToday = todaySnapshot.docs.length;

    for (var doc in todaySnapshot.docs) {
      incomeToday += (doc.data()['totalPrice'] as num?)?.toDouble() ?? 0;
    }

    double incomeYesterday = 0;
    for (var doc in yesterdaySnapshot.docs) {
      incomeYesterday += (doc.data()['totalPrice'] as num?)?.toDouble() ?? 0;
    }

    double percentage = 0;
    if (incomeYesterday > 0) {
      percentage = ((incomeToday - incomeYesterday) / incomeYesterday) * 100;
    } else if (incomeToday > 0) {
      percentage = 100; // from 0 to something is 100% increase (or infinity, but 100% is fine for display)
    }

    return {
      'incomeToday': incomeToday,
      'ordersToday': ordersToday,
      'percentage': percentage,
    };
  }

  static Future<Map<String, dynamic>> getRecapData(String restoId, int periodIndex) async {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (periodIndex == 0) {
      // Hari Ini
      startDate = DateTime(now.year, now.month, now.day);
    } else if (periodIndex == 1) {
      // Minggu Ini
      int currentWeekday = now.weekday;
      startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: currentWeekday - 1));
    } else {
      // Bulan Ini
      startDate = DateTime(now.year, now.month, 1);
    }

    final snapshot = await _db
        .collection('orders')
        .where('resto_id', isEqualTo: restoId)
        .where('orderDate', isGreaterThanOrEqualTo: startDate)
        .where('orderDate', isLessThanOrEqualTo: endDate)
        .get();

    double totalPendapatan = 0;
    int totalTransaksi = snapshot.docs.length;
    double dineIn = 0;
    double takeAway = 0;

    Map<String, int> menuPorsi = {};
    Map<String, double> menuPendapatan = {};
    
    // For Trends
    Map<String, double> trendMap = {};
    if (periodIndex == 0) {
      for (int i = 8; i <= 20; i += 2) {
        trendMap[i.toString().padLeft(2, '0')] = 0;
      }
    } else if (periodIndex == 1) {
      trendMap = {'Sen': 0, 'Sel': 0, 'Rab': 0, 'Kam': 0, 'Jum': 0, 'Sab': 0, 'Min': 0};
    } else {
      trendMap = {'Minggu 1': 0, 'Minggu 2': 0, 'Minggu 3': 0, 'Minggu 4': 0, 'Minggu 5': 0};
    }

    List<TransaksiItem> recentTransactions = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final totalPrice = (data['totalPrice'] as num?)?.toDouble() ?? 0;
      final type = data['type']?.toString().toLowerCase() ?? '';
      
      totalPendapatan += totalPrice;
      if (type.contains('dine')) {
        dineIn += totalPrice;
      } else {
        takeAway += totalPrice;
      }

      // Aggregate Menu Items
      if (data['items'] != null) {
        List<dynamic> items = data['items'];
        for (var item in items) {
          final menuName = item['menuName'] ?? 'Unknown Menu';
          final qty = (item['quantity'] as num?)?.toInt() ?? 1;
          final itemTotal = (item['unitTotalPrice'] as num?)?.toDouble() ?? 0;

          menuPorsi[menuName] = (menuPorsi[menuName] ?? 0) + qty;
          menuPendapatan[menuName] = (menuPendapatan[menuName] ?? 0) + itemTotal;
        }
      }

      // Aggregate Trends
      if (data['orderDate'] != null) {
        DateTime orderDate = (data['orderDate'] as Timestamp).toDate();
        if (periodIndex == 0) {
          int hour = orderDate.hour;
          String key = (hour % 2 == 0 ? hour : hour - 1).toString().padLeft(2, '0');
          if (trendMap.containsKey(key)) {
            trendMap[key] = (trendMap[key] ?? 0) + totalPrice;
          }
        } else if (periodIndex == 1) {
          List<String> days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
          String key = days[orderDate.weekday - 1];
          trendMap[key] = (trendMap[key] ?? 0) + totalPrice;
        } else {
          int week = ((orderDate.day - 1) / 7).floor() + 1;
          String key = 'Minggu $week';
          if (trendMap.containsKey(key)) {
            trendMap[key] = (trendMap[key] ?? 0) + totalPrice;
          }
        }
      }
    }

    // Sort Menu Terlaris
    var sortedMenu = menuPorsi.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    List<MenuTerlarisItem> menuTerlaris = sortedMenu.take(5).map((e) {
      return MenuTerlarisItem(
        name: e.key,
        porsi: e.value,
        totalPendapatan: menuPendapatan[e.key] ?? 0,
      );
    }).toList();

    // Prepare Trend DataPoints
    List<TrendDataPoint> trendData = trendMap.entries.map((e) => TrendDataPoint(label: e.key, value: e.value)).toList();

    // Get 5 recent transactions
    var sortedDocs = snapshot.docs.toList()
      ..sort((a, b) {
        Timestamp ta = a.data()['orderDate'] ?? Timestamp.now();
        Timestamp tb = b.data()['orderDate'] ?? Timestamp.now();
        return tb.compareTo(ta);
      });

    recentTransactions = sortedDocs.take(5).map((doc) {
      final data = doc.data();
      final typeStr = data['type']?.toString().toLowerCase() ?? '';
      TipeTransaksi tipe = typeStr.contains('dine') ? TipeTransaksi.dineIn : TipeTransaksi.takeAway;
      
      String timeStr = '--:--';
      if (data['orderDate'] != null) {
        timeStr = DateFormat('HH:mm').format((data['orderDate'] as Timestamp).toDate());
      }
      
      String queueStr = data['queueNumber']?.toString() ?? doc.id.substring(0, 4);
      queueStr = queueStr.replaceAll('#', '');

      return TransaksiItem(
        noTransaksi: queueStr,
        tipe: tipe,
        waktu: timeStr,
        total: (data['totalPrice'] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    return {
      'totalPendapatan': totalPendapatan,
      'totalTransaksi': totalTransaksi,
      'dineIn': dineIn,
      'takeAway': takeAway,
      'menuTerlaris': menuTerlaris,
      'trendData': trendData,
      'transaksiTerakhir': recentTransactions,
    };
  }
}
