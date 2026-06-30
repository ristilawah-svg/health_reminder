import 'package:flutter/material.dart';
import '../data/local_store.dart';

class MainScreen extends StatefulWidget {
  final String username;
  final int userId;

  const MainScreen({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const Color _primaryColor = Color(0xFFFF8A9B);
  static const Color _softColor = Color(0xFFFFF0F2);

  final List<String> _categories = const [
    'Semua',
    'Minum Obat',
    'Cek Tekanan Darah',
    'Cek Gula Darah',
    'Olahraga',
    'Makan Sehat',
    'Konsultasi Dokter',
    'Lainnya',
  ];

  final List<String> _moods = const [
    'Semua',
    '😊 Baik',
    '😐 Biasa',
    '😔 Sedih',
    '😠 Marah',
    '😩 Capek',
  ];

  int _selectedIndex = 0;
  String _searchQuery = '';
  String _filterCategory = 'Semua';
  String _filterMood = 'Semua';

  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _healthLogs = [];
  Map<String, int> _stats = {'total': 0, 'completed': 0, 'pending': 0};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _reminders = LocalStore.getReminders(widget.userId);
      _healthLogs = LocalStore.getHealthLogs(widget.userId);
      _stats = LocalStore.getReminderStats(widget.userId);
    });
  }

  List<Map<String, dynamic>> get _filteredReminders {
    return _reminders.where((reminder) {
      final title = '${reminder['title'] ?? ''}'.toLowerCase();
      final desc = '${reminder['description'] ?? ''}'.toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchSearch = query.isEmpty || title.contains(query) || desc.contains(query);
      final matchCategory = _filterCategory == 'Semua' || reminder['category'] == _filterCategory;
      return matchSearch && matchCategory;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredHealthLogs {
    return _healthLogs.where((log) {
      final date = '${log['log_date'] ?? ''}'.toLowerCase();
      final notes = '${log['notes'] ?? ''}'.toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchSearch = query.isEmpty || date.contains(query) || notes.contains(query);
      final matchMood = _filterMood == 'Semua' || log['mood'] == _filterMood;
      return matchSearch && matchMood;
    }).toList();
  }

  String _formatTime(dynamic value) {
    final time = '$value';
    if (time.length >= 5 && time[2] == ':') return time.substring(0, 5);
    return time;
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _showMessage(String message, {Color color = Colors.green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<String?> _pickDate(String currentDate) async {
    final initialDate = DateTime.tryParse(currentDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return null;
    return '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  Future<String?> _pickTime(String currentTime) async {
    final parts = currentTime.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? TimeOfDay.now().hour : TimeOfDay.now().hour;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? TimeOfDay.now().minute : TimeOfDay.now().minute;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: hour.clamp(0, 23).toInt(),
        minute: minute.clamp(0, 59).toInt(),
      ),
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  void _showAddReminderDialog() {
    _showReminderForm();
  }

  void _showEditReminderDialog(Map<String, dynamic> reminder) {
    _showReminderForm(reminder: reminder);
  }

  void _showReminderForm({Map<String, dynamic>? reminder}) {
    final titleController = TextEditingController(text: '${reminder?['title'] ?? ''}');
    final descController = TextEditingController(text: '${reminder?['description'] ?? ''}');
    final dateController = TextEditingController(text: '${reminder?['reminder_date'] ?? _today()}');
    final timeController = TextEditingController(text: _formatTime(reminder?['reminder_time'] ?? '08:00'));
    String selectedCategory = '${reminder?['category'] ?? 'Minum Obat'}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _BottomSheetContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 14),
                  Text(
                    reminder == null ? 'Tambah Reminder' : 'Edit Reminder',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Tanggal',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          onTap: () async {
                            final value = await _pickDate(dateController.text);
                            if (value != null) setSheetState(() => dateController.text = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: timeController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Waktu',
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          onTap: () async {
                            final value = await _pickTime(timeController.text);
                            if (value != null) setSheetState(() => timeController.text = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _categories.where((item) => item != 'Semua').map((category) {
                      return DropdownMenuItem(value: category, child: Text(category));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setSheetState(() => selectedCategory = value);
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            if (titleController.text.trim().isEmpty) {
                              _showMessage('Judul reminder wajib diisi.', color: Colors.orange);
                              return;
                            }

                            if (reminder == null) {
                              LocalStore.addReminder(
                                userId: widget.userId,
                                title: titleController.text.trim(),
                                description: descController.text.trim(),
                                date: dateController.text,
                                time: timeController.text,
                                category: selectedCategory,
                              );
                              _showMessage('Reminder berhasil ditambahkan.');
                            } else {
                              LocalStore.updateReminder(
                                id: reminder['id'] as int,
                                title: titleController.text.trim(),
                                description: descController.text.trim(),
                                date: dateController.text,
                                time: timeController.text,
                                category: selectedCategory,
                              );
                              _showMessage('Reminder berhasil diubah.');
                            }

                            _loadData();
                            Navigator.pop(context);
                          },
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddHealthLogDialog() {
    final weightController = TextEditingController();
    final bloodPressureController = TextEditingController();
    final bloodSugarController = TextEditingController();
    final heartRateController = TextEditingController();
    final sleepController = TextEditingController();
    final notesController = TextEditingController();
    String selectedMood = _moods[1];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _BottomSheetContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 14),
                  const Text(
                    'Catat Kesehatan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Berat Badan (kg)',
                      prefixIcon: Icon(Icons.fitness_center),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bloodPressureController,
                    decoration: const InputDecoration(
                      labelText: 'Tekanan Darah',
                      hintText: 'Contoh: 120/80',
                      prefixIcon: Icon(Icons.bloodtype_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: bloodSugarController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Gula Darah',
                            prefixIcon: Icon(Icons.science_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: heartRateController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Detak Jantung',
                            prefixIcon: Icon(Icons.favorite_outline),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: sleepController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Jam Tidur',
                            prefixIcon: Icon(Icons.bedtime_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedMood,
                          decoration: const InputDecoration(
                            labelText: 'Mood',
                            prefixIcon: Icon(Icons.emoji_emotions_outlined),
                          ),
                          items: _moods.where((item) => item != 'Semua').map((mood) {
                            return DropdownMenuItem(value: mood, child: Text(mood));
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) setSheetState(() => selectedMood = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            if (weightController.text.trim().isEmpty) {
                              _showMessage('Berat badan wajib diisi.', color: Colors.orange);
                              return;
                            }

                            LocalStore.addHealthLog(
                              userId: widget.userId,
                              weight: weightController.text.trim(),
                              bloodPressure: bloodPressureController.text.trim().isEmpty
                                  ? '-'
                                  : bloodPressureController.text.trim(),
                              bloodSugar: bloodSugarController.text.trim().isEmpty
                                  ? '-'
                                  : bloodSugarController.text.trim(),
                              heartRate: heartRateController.text.trim().isEmpty
                                  ? '-'
                                  : heartRateController.text.trim(),
                              sleepHours: sleepController.text.trim().isEmpty
                                  ? '-'
                                  : sleepController.text.trim(),
                              mood: selectedMood,
                              notes: notesController.text.trim(),
                            );

                            _loadData();
                            Navigator.pop(context);
                            _showMessage('Data kesehatan berhasil dicatat.');
                          },
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetHandle() {
    return Container(
      width: 48,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  void _showReminderDetail(Map<String, dynamic> reminder) {
    final isCompleted = reminder['is_completed'] == 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _BottomSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle()),
              const SizedBox(height: 18),
              Row(
                children: [
                  _circleIcon(Icons.notifications_active_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${reminder['title']}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _detailItem('Deskripsi', '${reminder['description'] ?? '-'}'),
              _detailItem('Tanggal', '${reminder['reminder_date'] ?? '-'}'),
              _detailItem('Waktu', _formatTime(reminder['reminder_time'])),
              _detailItem('Kategori', '${reminder['category'] ?? '-'}'),
              _detailItem('Status', isCompleted ? 'Selesai' : 'Pending'),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditReminderDialog(reminder);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDeleteReminder(reminder['id'] as int);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHealthLogDetail(Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _BottomSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle()),
              const SizedBox(height: 18),
              Row(
                children: [
                  _circleIcon(Icons.monitor_heart_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Riwayat ${log['log_date'] ?? '-'}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _detailItem('Berat Badan', '${log['weight'] ?? '-'} kg'),
              _detailItem('Tekanan Darah', '${log['blood_pressure'] ?? '-'}'),
              _detailItem('Gula Darah', '${log['blood_sugar'] ?? '-'} mg/dL'),
              _detailItem('Detak Jantung', '${log['heart_rate'] ?? '-'} bpm'),
              _detailItem('Jam Tidur', '${log['sleep_hours'] ?? '-'} jam'),
              _detailItem('Mood', '${log['mood'] ?? '-'}'),
              _detailItem('Catatan', '${log['notes'] ?? '-'}'),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDeleteHealthLog(log['id'] as int);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus Data'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: _primaryColor, size: 28),
    );
  }

  Future<void> _confirmDeleteReminder(int id) async {
    final result = await _confirmDialog('Hapus Reminder?', 'Yakin mau hapus reminder ini?');
    if (result != true) return;
    LocalStore.deleteReminder(id);
    _loadData();
    _showMessage('Reminder berhasil dihapus.');
  }

  Future<void> _confirmDeleteHealthLog(int id) async {
    final result = await _confirmDialog('Hapus Data?', 'Yakin mau hapus data kesehatan ini?');
    if (result != true) return;
    LocalStore.deleteHealthLog(id);
    _loadData();
    _showMessage('Data kesehatan berhasil dihapus.');
  }

  Future<bool?> _confirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, Color(0xFFFFB0BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Halo, ${widget.username}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Semoga sehat selalu hari ini.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _statItem('Total', '${_stats['total'] ?? 0}', Icons.list_alt),
              _statItem('Selesai', '${_stats['completed'] ?? 0}', Icons.check_circle_outline),
              _statItem('Pending', '${_stats['pending'] ?? 0}', Icons.timelapse),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final filters = _selectedIndex == 0 ? _categories : _moods;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: _selectedIndex == 0 ? 'Cari reminder...' : 'Cari riwayat...',
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((filter) {
                final isSelected = _selectedIndex == 0
                    ? _filterCategory == filter
                    : _filterMood == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: _primaryColor,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() {
                        if (_selectedIndex == 0) {
                          _filterCategory = filter;
                        } else {
                          _filterMood = filter;
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderList() {
    final data = _filteredReminders;
    if (data.isEmpty) {
      return _emptyState(
        icon: Icons.notifications_off_outlined,
        title: _reminders.isEmpty ? 'Belum ada reminder' : 'Data tidak ditemukan',
        subtitle: 'Tekan tombol + untuk menambahkan reminder.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final isCompleted = item['is_completed'] == 1;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showReminderDetail(item),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      LocalStore.toggleReminder(item['id'] as int);
                      _loadData();
                    },
                    borderRadius: BorderRadius.circular(99),
                    child: Icon(
                      isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isCompleted ? Colors.green : _primaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['title']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${item['reminder_date']} • ${_formatTime(item['reminder_time'])}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _miniChip('${item['category']}'),
                            _miniChip(isCompleted ? 'Selesai' : 'Pending'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHealthLogList() {
    final data = _filteredHealthLogs;
    if (data.isEmpty) {
      return _emptyState(
        icon: Icons.monitor_heart_outlined,
        title: _healthLogs.isEmpty ? 'Belum ada riwayat kesehatan' : 'Data tidak ditemukan',
        subtitle: 'Tekan tombol + untuk mencatat kesehatan.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showHealthLogDetail(item),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _circleIcon(Icons.health_and_safety_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Riwayat ${item['log_date']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _miniChip('⚖️ ${item['weight']} kg'),
                      _miniChip('🩸 ${item['blood_pressure']}'),
                      _miniChip('❤️ ${item['heart_rate']} bpm'),
                      _miniChip('${item['mood']}'),
                    ],
                  ),
                  if ('${item['notes'] ?? ''}'.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '${item['notes']}',
                      style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _miniChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _softColor,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 78, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Reminder Kesehatan' : 'Riwayat Kesehatan'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                widget.username,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(),
          _buildSearchBar(),
          const SizedBox(height: 4),
          Expanded(
            child: _selectedIndex == 0 ? _buildReminderList() : _buildHealthLogList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedIndex == 0 ? _showAddReminderDialog : _showAddHealthLogDialog,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(_selectedIndex == 0 ? 'Reminder' : 'Catatan'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        indicatorColor: _softColor,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            _searchQuery = '';
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications_active),
            label: 'Reminder',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Riwayat',
          ),
        ],
      ),
    );
  }
}

class _BottomSheetContainer extends StatelessWidget {
  final Widget child;

  const _BottomSheetContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 22,
        ),
        child: child,
      ),
    );
  }
}
