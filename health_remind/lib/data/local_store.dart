import '../models/user_model.dart';

class LocalStore {
  LocalStore._();

  static int _nextUserId = 2;
  static int _nextReminderId = 3;
  static int _nextHealthLogId = 2;

  static final Map<String, String> _passwords = {
    'demo': '1234',
  };

  static final Map<String, AppUser> _users = {
    'demo': const AppUser(id: 1, username: 'demo'),
  };

  static final List<Map<String, dynamic>> _reminders = [
    {
      'id': 1,
      'user_id': 1,
      'title': 'Minum vitamin',
      'description': 'Minum vitamin setelah sarapan.',
      'reminder_date': _today(),
      'reminder_time': '08:00',
      'category': 'Minum Obat',
      'is_completed': 0,
    },
    {
      'id': 2,
      'user_id': 1,
      'title': 'Olahraga ringan',
      'description': 'Jalan kaki atau stretching 15 menit.',
      'reminder_date': _today(),
      'reminder_time': '17:00',
      'category': 'Olahraga',
      'is_completed': 1,
    },
  ];

  static final List<Map<String, dynamic>> _healthLogs = [
    {
      'id': 1,
      'user_id': 1,
      'log_date': _today(),
      'weight': '60',
      'blood_pressure': '120/80',
      'blood_sugar': '90',
      'heart_rate': '78',
      'sleep_hours': '7',
      'mood': '😊 Baik',
      'notes': 'Kondisi badan cukup fit.',
    },
  ];

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static AppUser? login(String username, String password) {
    final key = username.trim().toLowerCase();
    if (_passwords[key] == password) {
      return _users[key];
    }
    return null;
  }

  static String? register(String username, String password) {
    final key = username.trim().toLowerCase();
    if (key.isEmpty || password.isEmpty) {
      return 'Username dan password wajib diisi.';
    }
    if (_users.containsKey(key)) {
      return 'Username sudah terdaftar.';
    }
    final user = AppUser(id: _nextUserId++, username: username.trim());
    _users[key] = user;
    _passwords[key] = password;
    return null;
  }

  static List<Map<String, dynamic>> getReminders(int userId) {
    final data = _reminders.where((item) => item['user_id'] == userId).toList();
    data.sort((a, b) {
      final dateCompare = '${a['reminder_date']}'.compareTo('${b['reminder_date']}');
      if (dateCompare != 0) return dateCompare;
      return '${a['reminder_time']}'.compareTo('${b['reminder_time']}');
    });
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static Map<String, int> getReminderStats(int userId) {
    final data = _reminders.where((item) => item['user_id'] == userId).toList();
    final completed = data.where((item) => item['is_completed'] == 1).length;
    return {
      'total': data.length,
      'completed': completed,
      'pending': data.length - completed,
    };
  }

  static void addReminder({
    required int userId,
    required String title,
    required String description,
    required String date,
    required String time,
    required String category,
  }) {
    _reminders.add({
      'id': _nextReminderId++,
      'user_id': userId,
      'title': title,
      'description': description,
      'reminder_date': date,
      'reminder_time': time,
      'category': category,
      'is_completed': 0,
    });
  }

  static void updateReminder({
    required int id,
    required String title,
    required String description,
    required String date,
    required String time,
    required String category,
  }) {
    final index = _reminders.indexWhere((item) => item['id'] == id);
    if (index == -1) return;

    _reminders[index] = {
      ..._reminders[index],
      'title': title,
      'description': description,
      'reminder_date': date,
      'reminder_time': time,
      'category': category,
    };
  }

  static void toggleReminder(int id) {
    final index = _reminders.indexWhere((item) => item['id'] == id);
    if (index == -1) return;
    _reminders[index]['is_completed'] = _reminders[index]['is_completed'] == 1 ? 0 : 1;
  }

  static void deleteReminder(int id) {
    _reminders.removeWhere((item) => item['id'] == id);
  }

  static List<Map<String, dynamic>> getHealthLogs(int userId) {
    final data = _healthLogs.where((item) => item['user_id'] == userId).toList();
    data.sort((a, b) => '${b['log_date']}'.compareTo('${a['log_date']}'));
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static void addHealthLog({
    required int userId,
    required String weight,
    required String bloodPressure,
    required String bloodSugar,
    required String heartRate,
    required String sleepHours,
    required String mood,
    required String notes,
  }) {
    _healthLogs.add({
      'id': _nextHealthLogId++,
      'user_id': userId,
      'log_date': _today(),
      'weight': weight,
      'blood_pressure': bloodPressure,
      'blood_sugar': bloodSugar,
      'heart_rate': heartRate,
      'sleep_hours': sleepHours,
      'mood': mood,
      'notes': notes,
    });
  }

  static void deleteHealthLog(int id) {
    _healthLogs.removeWhere((item) => item['id'] == id);
  }
}
