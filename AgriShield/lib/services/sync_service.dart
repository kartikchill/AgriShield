import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../database/db_helper.dart';
import '../localization/app_translations.dart';
import 'api_service.dart';

/// Store-and-forward sync service.
/// Polls the backend every 5 seconds, draining the sync_queue table.
class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  Timer? _timer;
  bool _isOnline = false;
  int _pendingCount = 0;

  bool get isOnline => _isOnline;
  int get pendingCount => _pendingCount;

  // Listeners that get called when online status changes
  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);
  void _notify() { for (final cb in _listeners) {
    cb();
  } }

  /// Call once from main() to start the background sync loop
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _syncCycle());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _syncCycle() async {
    await ApiService.loadLanguage();

    // 1. Check connectivity
    final online = await ApiService.instance.isOnline();
    if (online != _isOnline) {
      _isOnline = online;
      _notify();
    }

    if (!_isOnline) {
      _pendingCount = await DatabaseHelper.instance.getSyncQueueCount();
      _notify();
      return;
    }

    // 2. Drain sync queue
    final items = await DatabaseHelper.instance.getPendingSyncItems();
    for (final item in items) {
      final id = item['id'] as int;
      final endpoint = item['endpoint'] as String;
      final method = item['method'] as String;
      final payload = item['payload'] as String;

      try {
        final uri = Uri.parse('${ApiService.baseUrl}$endpoint');
        http.Response response;

        if (method == 'POST') {
          response = await http.post(uri,
            headers: {'Content-Type': 'application/json', 'Accept-Language': ApiService.currentLanguageCode},
            body: payload,
          ).timeout(const Duration(seconds: 8));
        } else {
          response = await http.get(uri, headers: {'Accept-Language': ApiService.currentLanguageCode}).timeout(const Duration(seconds: 8));
        }

        if (response.statusCode < 400) {
          await DatabaseHelper.instance.deleteSyncItem(id);
        } else {
          await DatabaseHelper.instance.incrementSyncRetry(id);
        }
      } on SocketException {
        _isOnline = false;
        break;
      } catch (_) {
        await DatabaseHelper.instance.incrementSyncRetry(id);
      }
    }

    // 3. Drain active learning queue
    final alItems = await DatabaseHelper.instance.getPendingActiveLearningItems();
    for (final item in alItems) {
      final id = item['id'] as int;
      try {
        final uri = Uri.parse('${ApiService.baseUrl}/api/v1/active-learning/submit');
        

        // wait, the payload map has values, we should jsonEncode it for http.post
        
        // I will use dart:convert in a second if not imported, wait, I will import it if needed.
        // Actually, let's just make weather_vector a valid JSON string inside the DB, and pass it around.
        final jsonPayload = '{"ticket_id":"${item['ticket_id']}","crop":"${item['crop']}","disease":"${item['disease']}","image_path":"${item['image_path'] ?? ''}","weather_vector":${item['weather_vector']},"farmer_feedback":"${item['farmer_feedback']}"}';

        final response = await http.post(uri,
          headers: {'Content-Type': 'application/json', 'Accept-Language': ApiService.currentLanguageCode},
          body: jsonPayload,
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode < 400) {
          await DatabaseHelper.instance.deleteActiveLearningItem(id);
        }
      } on SocketException {
        _isOnline = false;
        break;
      } catch (e) {
        print("Active Learning Sync Error: $e");
      }
    }

    // 4. Fetch notifications and ticket updates
    if (_isOnline) {
      try {
        final uri = Uri.parse('${ApiService.baseUrl}/api/v1/sync?phone_number=9876543210');
        final response = await http.get(uri, headers: {'Accept-Language': ApiService.currentLanguageCode}).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final tickets = data['tickets'] as List;
          
          for (final t in tickets) {
            final code = t['ticket_code'];
            final status = t['status'];
            final diagnosis = t['expert_diagnosis'];
            final advisory = t['expert_advisory'];
            
            final localTicket = await DatabaseHelper.instance.getTicketByCode(code);
            if (localTicket != null && localTicket['status'] != status) {
              // State changed! Update local DB
              await DatabaseHelper.instance.updateTicketStatus(code, status, diagnosis: diagnosis, advisory: advisory);
              
              // Trigger local notification
              _showLocalNotification(status, diagnosis);
            }
          }
        }
      } catch (e) {
        print("Sync Notifications Error: $e");
      }
    }

    _pendingCount = await DatabaseHelper.instance.getSyncQueueCount();
    _notify();
  }

  /// Manually trigger a sync cycle (e.g. when user taps Retry)
  Future<void> forceSyncNow() async => await _syncCycle();

  void _showLocalNotification(String status, String? message) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final title = AppTranslations.t('Ticket Update', ApiService.currentLanguageCode);
    final statusText = status == 'APPROVED' ? AppTranslations.t('Ticket Approved', ApiService.currentLanguageCode) : AppTranslations.t(status, ApiService.currentLanguageCode);
    final body = message != null ? AppTranslations.translateCompound(message, ApiService.currentLanguageCode) : AppTranslations.t('You have a new notification.', ApiService.currentLanguageCode);
    
    flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, 
      '$title: $statusText', 
      body, 
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'agrishield_notifications', 
          'AgriShield Alerts',
          channelDescription: 'Important alerts and ticket updates from AgriShield.',
          importance: Importance.max,
          priority: Priority.high,
        )
      ),
    );
  }
}

// Workaround – flutter doesn't export VoidCallback from dart:ui in all contexts
typedef VoidCallback = void Function();
