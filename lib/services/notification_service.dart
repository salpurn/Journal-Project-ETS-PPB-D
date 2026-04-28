import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> initializeNotification() async {
    await AwesomeNotifications().initialize(
      null, 
      [
        NotificationChannel(
          channelGroupKey: 'collab_channel_group',
          channelKey: 'collab_channel',
          channelName: 'Collaboration Alerts',
          channelDescription: 'Notifikasi untuk aktivitas kolaborasi notes',
          defaultColor: Colors.orange,
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          playSound: true,
          criticalAlerts: true,
        ),
        // Channel tambahan khusus untuk reminder agar user bisa mematikan notif ini saja di setting HP
        NotificationChannel(
          channelGroupKey: 'collab_channel_group',
          channelKey: 'daily_reminder_channel',
          channelName: 'Daily Reminders',
          channelDescription: 'Pengingat harian untuk update catatan',
          defaultColor: Colors.orange,
          importance: NotificationImportance.High,
        )
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'collab_channel_group',
          channelGroupName: 'Collaboration group',
        )
      ],
      debug: true,
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod: _onNotificationCreateMethod,
      onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
    );

    // Panggil ini saat inisialisasi agar jadwal reminder terpasang
    scheduleDailyReminder();
  }

  // FITUR BARU: Daily Reminder
  // Notifikasi akan muncul setiap hari (misal jam 10 pagi)
  static Future<void> scheduleDailyReminder() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 30, // ID unik untuk reminder
        channelKey: 'daily_reminder_channel',
        title: "What's new? 📝",
        body: "Kamu dari 1 hari yang lalu belum update notesnya, nih. Yuk tulis sesuatu!",
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: 22, // Jam 10 pagi
        minute: 30,
        second: 0,
        millisecond: 0,
        repeats: true, // Berulang setiap hari
      ),
    );
  }

  // Notif Baru: Khusus saat membuat notes pribadi
  static Future<void> showNoteCreated() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'collab_channel',
        title: 'Yeay, notes baru!',
        body: 'Catatan kamu telah berhasil disimpan.',
      ),
    );
    
    // Tips: Setiap user update/bikin note, kita reset jadwal reminder 
    // agar durasi "1 hari" dihitung dari aktivitas terakhir.
    scheduleDailyReminder();
  }

  // Notif Host: Undangan berhasil dikirim
  static Future<void> showInvitationSent(String email) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 20,
        channelKey: 'collab_channel',
        title: 'Undangan Terkirim!',
        body: 'Email kolaborasi telah dikirim ke $email',
      ),
    );
  }

  // Notif Penerima: Ada undangan baru masuk ke Inbox
  static Future<void> showNewInvitationReceived(String hostEmail, String noteTitle) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 21,
        channelKey: 'collab_channel',
        title: 'Undangan Kolaborasi Baru 📝',
        body: '$hostEmail mengundang kamu di "$noteTitle"',
        payload: {'type': 'open_inbox'},
      ),
    );
  }

  // Notif Host: Undangan diterima oleh teman
  static Future<void> showInvitationAccepted(String collaboratorEmail) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 22,
        channelKey: 'collab_channel',
        title: 'Undangan Diterima! ✅',
        body: '$collaboratorEmail sekarang bisa mengedit notes kamu.',
      ),
    );
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationCreateMethod(ReceivedNotification receivedNotification) async {
    debugPrint('Notification created');
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    debugPrint('Notification displayed');
  }

  @pragma("vm:entry-point")
  static Future<void> _onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    debugPrint('Notification dismissed');
  }

  @pragma("vm:entry-point")
  static Future<void> _onActionReceivedMethod(ReceivedAction receivedAction) async {
    if (receivedAction.payload?['type'] == 'open_inbox') {
      debugPrint('Arahkan user ke halaman Inbox...');
    }
  }
}