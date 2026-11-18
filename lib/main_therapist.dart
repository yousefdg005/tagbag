// =============================================================================
// البرنامج الثالث: تطبيق أخصائي العلاج الطبيعي (Therapist Android App)
// يدير حالة الاتصال (Online/Offline)، استلام الطلبات المحولة، الملاحة،
// تسجيل الوصول الجغرافي (GPS Check-in)، كتابة التقرير الطبي، ومتابعة العهدة النقدية
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PhysioTherapistApp());
}

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://your-physio-api.onrender.com/api',
);

// =============================================================================
// النماذج والبيانات (Therapist Models)
// =============================================================================

class AssignedVisitModel {
  final String id;
  final String orderCode;
  final String patientName;
  final String patientPhone;
  final String serviceLabel;
  final String district;
  final String addressNotes;
  final String scheduledLabel;
  final double price;
  final String paymentMethod;
  String status; // dispatched, accepted, en_route, in_session, completed
  String clinicalNotes;
  String homeExercises;

  AssignedVisitModel({
    required this.id,
    required this.orderCode,
    required this.patientName,
    required this.patientPhone,
    required this.serviceLabel,
    required this.district,
    required this.addressNotes,
    required this.scheduledLabel,
    required this.price,
    required this.paymentMethod,
    required this.status,
    this.clinicalNotes = '',
    this.homeExercises = '',
  });
}

class TherapistRepository {
  final String therapistId = '33333333-3333-3333-3333-333333333331';
  String therapistName = 'د. أحمد السنوسي';
  String specialty = 'تأهيل عظام وكسور وإصابات ملاعب';
  bool isOnline = true;
  bool allowRejectFromCenter = true;
  bool showPatientPhoneFromCenter = false;
  double centerCommissionPct = 40.0;
  double maxCashCustodyLimit = 1000.0;
  double cashCustodyBalance = 280.0;
  int completedCount = 42;

  List<AssignedVisitModel> visits = [
    AssignedVisitModel(
      id: '104',
      orderCode: 'ORD-104',
      patientName: 'خالد المبروك',
      patientPhone: '091-4829104',
      serviceLabel: 'جلسة علاجية منزلية مفردة',
      district: 'حي الأندلس',
      addressNotes: 'قرب جزيرة حي الأندلس، شارع الصيدلية، الدور الثاني',
      scheduledLabel: 'اليوم 15:00 مساءً',
      price: 70.0,
      paymentMethod: 'cash',
      status: 'dispatched',
    ),
  ];

  String maskedPhone(String phone) {
    if (showPatientPhoneFromCenter) return phone;
    if (phone.length < 6) return phone;
    return '${phone.substring(0, 4)}•••••${phone.substring(phone.length - 2)} (محمي)';
  }

  Future<void> toggleOnlineStatus(bool online) async {
    isOnline = online;
    try {
      await http
          .patch(
            Uri.parse('$kApiBaseUrl/therapists/$therapistId/status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'is_online': online}),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> updateVisitStatus(String visitId, String newStatus) async {
    final idx = visits.indexWhere((v) => v.id == visitId);
    if (idx != -1) {
      visits[idx].status = newStatus;
    }
    try {
      await http
          .patch(
            Uri.parse('$kApiBaseUrl/visits/$visitId/status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': newStatus, 'therapist_id': therapistId}),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> rejectVisit(String visitId) async {
    visits.removeWhere((v) => v.id == visitId);
    try {
      await http
          .post(
            Uri.parse('$kApiBaseUrl/visits/$visitId/reject'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'therapist_id': therapistId,
              'reason': 'اعتذار لارتباط بجلسة أخرى'
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> completeVisit({
    required String visitId,
    required String clinicalNotes,
    required String homeExercises,
  }) async {
    final idx = visits.indexWhere((v) => v.id == visitId);
    if (idx != -1) {
      visits[idx].status = 'completed';
      visits[idx].clinicalNotes = clinicalNotes;
      visits[idx].homeExercises = homeExercises;
      if (visits[idx].paymentMethod == 'cash') {
        cashCustodyBalance += visits[idx].price;
      }
      completedCount += 1;
    }
    try {
      await http
          .post(
            Uri.parse('$kApiBaseUrl/visits/$visitId/complete'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'therapist_id': therapistId,
              'clinical_notes': clinicalNotes,
              'home_exercises': homeExercises,
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }
}

// =============================================================================
// واجهة تطبيق الأخصائي (Material 3 RTL)
// =============================================================================

class PhysioTherapistApp extends StatefulWidget {
  const PhysioTherapistApp({super.key});

  @override
  State<PhysioTherapistApp> createState() => _PhysioTherapistAppState();
}

class _PhysioTherapistAppState extends State<PhysioTherapistApp> {
  final TherapistRepository repo = TherapistRepository();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تطبيق الأخصائي - ${repo.therapistName}',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF065F46)),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: TherapistHomeScreen(repo: repo),
    );
  }
}

class TherapistHomeScreen extends StatefulWidget {
  final TherapistRepository repo;
  const TherapistHomeScreen({super.key, required this.repo});

  @override
  State<TherapistHomeScreen> createState() => _TherapistHomeScreenState();
}

class _TherapistHomeScreenState extends State<TherapistHomeScreen> {
  int _selectedTab = 0;
  final Map<String, TextEditingController> _notesControllers = {};
  final Map<String, TextEditingController> _exercisesControllers = {};

  TextEditingController _getNotesCtrl(AssignedVisitModel v) {
    return _notesControllers.putIfAbsent(
      v.id,
      () => TextEditingController(
        text: v.clinicalNotes.isNotEmpty
            ? v.clinicalNotes
            : 'تحسن ملحوظ في مدى حركة المفصل واستجابة ممتازة للعلاج اليدوي.',
      ),
    );
  }

  TextEditingController _getExercisesCtrl(AssignedVisitModel v) {
    return _exercisesControllers.putIfAbsent(
      v.id,
      () => TextEditingController(
        text: v.homeExercises.isNotEmpty
            ? v.homeExercises
            : 'تمارين إطالة وتقوية لمدة 15 دقيقة مرتين يومياً + كمادات دافئة.',
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _notesControllers.values) {
      c.dispose();
    }
    for (final c in _exercisesControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.repo;
    final activeTasks = r.visits.where((v) => v.status != 'completed').length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF064E3B),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.therapistName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              r.isOnline
                  ? 'متاح الآن لاستقبال طلبات المركز (Online)'
                  : 'غير متاح حالياً (Offline)',
              style: TextStyle(
                fontSize: 12,
                color: r.isOnline ? Colors.greenAccent : Colors.orangeAccent,
              ),
            ),
          ],
        ),
        actions: [
          Switch(
            value: r.isOnline,
            activeColor: Colors.greenAccent,
            onChanged: (val) async {
              await r.toggleOnlineStatus(val);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildTasksTab(),
          _buildScheduleTab(),
          _buildWalletTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (idx) => setState(() => _selectedTab = idx),
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: activeTasks > 0,
              label: Text('$activeTasks'),
              child: const Icon(Icons.medical_services_outlined),
            ),
            selectedIcon: const Icon(Icons.medical_services),
            label: 'المهام والزيارات',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'جدول الباقات',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'حسابي والعهدة',
          ),
        ],
      ),
    );
  }

  // 1. تبويب المهام الميدانية وتنفيذ الجلسة
  Widget _buildTasksTab() {
    if (widget.repo.visits.isEmpty) {
      return const Center(
        child: Text('لا توجد زيارات محولة إليك حالياً. تأكد من تفعيل حالة (Online).'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.repo.visits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final v = widget.repo.visits[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: v.status == 'dispatched'
                  ? Colors.amber.shade600
                  : Colors.grey.shade300,
              width: v.status == 'dispatched' ? 1.5 : 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${v.orderCode} • ${v.scheduledLabel}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    Chip(
                      label: Text(
                        _statusLabel(v.status),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Text(
                  'المريض: ${v.patientName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  v.serviceLabel,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF065F46), fontWeight: FontWeight.bold),
                ),
                const Divider(height: 20),
                Text('المنطقة والعنوان: ${v.district} - ${v.addressNotes}', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Text('هاتف المريض: ${widget.repo.maskedPhone(v.patientPhone)}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  'التحصيل المطلوب: ${v.paymentMethod == 'package' ? 'مدفوع ضمن الباقة' : '${v.price.toInt()} د.ل (نقداً)'}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                const SizedBox(height: 14),
                _buildActionButtonsForStatus(v),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtonsForStatus(AssignedVisitModel v) {
    if (v.status == 'dispatched') {
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
              onPressed: () async {
                await widget.repo.updateVisitStatus(v.id, 'accepted');
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.check),
              label: const Text('قبول الزيارة'),
            ),
          ),
          if (widget.repo.allowRejectFromCenter) ...[
            const SizedBox(width: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
              onPressed: () async {
                await widget.repo.rejectVisit(v.id);
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إرسال الاعتذار وإعادة الطلب لشاشة الأدمن')),
                  );
                }
              },
              icon: const Icon(Icons.close),
              label: const Text('اعتذار'),
            ),
          ],
        ],
      );
    }

    if (v.status == 'accepted') {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.indigo.shade700),
          onPressed: () async {
            await widget.repo.updateVisitStatus(v.id, 'en_route');
            if (mounted) setState(() {});
          },
          icon: const Icon(Icons.directions_car),
          label: const Text('بدء التحرك للمريض (إشعار المريض + فتح الخريطة)'),
        ),
      );
    }

    if (v.status == 'en_route') {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
          onPressed: () async {
            await widget.repo.updateVisitStatus(v.id, 'in_session');
            if (mounted) setState(() {});
          },
          icon: const Icon(Icons.location_on),
          label: const Text('تسجيل الوصول وبدء الجلسة (GPS Check-in)'),
        ),
      );
    }

    if (v.status == 'in_session') {
      final notesCtrl = _getNotesCtrl(v);
      final exCtrl = _getExercisesCtrl(v);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'التقرير الطبي للجلسة (يُحفظ في ملف المريض ولدى المركز):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'تقييم الحالة وملاحظات الجلسة',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: exCtrl,
            decoration: const InputDecoration(
              labelText: 'التمارين المنزلية المطلوبة من المريض',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
              onPressed: () async {
                await widget.repo.completeVisit(
                  visitId: v.id,
                  clinicalNotes: notesCtrl.text.trim(),
                  homeExercises: exCtrl.text.trim(),
                );
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم إغلاق الجلسة بنجاح وتقييد ${v.price.toInt()} د.ل في عهدتك النقدية',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.task_alt),
              label: Text('إنهاء الجلسة وتأكيد استلام (${v.price.toInt()} د.ل)'),
            ),
          ),
        ],
      );
    }

    return const Text(
      'تم إكمال هذه الزيارة وحفظ التقرير الطبي بنجاح ✓',
      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
    );
  }

  // 2. تبويب جدول الباقات الأسبوعي
  Widget _buildScheduleTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: const ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Color(0xFFCCFBF1),
              child: Icon(Icons.event_repeat, color: Color(0xFF0F766E)),
            ),
            title: Text('المريض: خالد المبروك (متبقي 4/6 جلسات)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'باقة تأهيل مفصل الركبة\nالمواعيد: السبت • الإثنين • الأربعاء (5:00 مساءً)\nالعنوان: حي الأندلس، قرب جزيرة حي الأندلس',
            ),
          ),
        ),
      ],
    );
  }

  // 3. تبويب المحفظة والعهدة النقدية للأخصائي
  Widget _buildWalletTab() {
    final r = widget.repo;
    final centerShare = (r.cashCustodyBalance * (r.centerCommissionPct / 100.0)).round();
    final myNet = r.cashCustodyBalance.round() - centerShare;
    final ratio = (r.cashCustodyBalance / r.maxCashCustodyLimit).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF064E3B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الكاش المحصل بيدك حالياً', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  '${r.cashCustodyBalance.toInt()} د.ل',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('صافي نسبتك (${(100 - r.centerCommissionPct).toInt()}%): $myNet د.ل', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    Text('حصة المركز: $centerShare د.ل', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سقف العهدة النقدية المسموح: ${r.cashCustodyBalance.toInt()} / ${r.maxCashCustodyLimit.toInt()} د.ل',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 8),
                const Text(
                  'عند توريد حصة المركز لموظف الاستقبال، سيقوم بتصفير العهدة من تطبيق الأدمن.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _statusLabel(String st) {
    switch (st) {
      case 'dispatched':
        return 'طلب جديد موجه لك';
      case 'accepted':
        return 'تم القبول';
      case 'en_route':
        return 'في الطريق للمريض';
      case 'in_session':
        return 'الجلسة جارية الآن';
      case 'completed':
        return 'مكتملة';
      default:
        return st;
    }
  }
}
