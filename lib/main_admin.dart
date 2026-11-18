// =============================================================================
// البرنامج الثاني: تطبيق الأدمن - موظف المركز (Admin Dispatch Android & Web App)
// يدير استلام الطلبات، التوجيه للأخصائيين المتاحين، العهدة المالية، وإعدادات المركز
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PhysioAdminApp());
}

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://your-physio-api.onrender.com/api',
);

// =============================================================================
// النماذج والبيانات (Admin Models)
// =============================================================================

class AdminSettingsModel {
  String centerName;
  String primaryColorHex;
  bool allowTherapistReject;
  bool autoDispatch;
  bool showPatientPhone;
  double centerCommissionPct;
  double singleSessionPrice;
  double assessmentPrice;
  double package6Price;
  double maxCashCustodyLimit;

  AdminSettingsModel({
    required this.centerName,
    required this.primaryColorHex,
    required this.allowTherapistReject,
    required this.autoDispatch,
    required this.showPatientPhone,
    required this.centerCommissionPct,
    required this.singleSessionPrice,
    required this.assessmentPrice,
    required this.package6Price,
    required this.maxCashCustodyLimit,
  });

  Map<String, dynamic> toJson() => {
        'center_name': centerName,
        'primary_color_hex': primaryColorHex,
        'allow_therapist_reject': allowTherapistReject,
        'auto_dispatch': autoDispatch,
        'show_patient_phone': showPatientPhone,
        'center_commission_pct': centerCommissionPct,
        'single_session_price': singleSessionPrice,
        'assessment_price': assessmentPrice,
        'package_6_price': package6Price,
        'max_cash_custody_limit': maxCashCustodyLimit,
      };
}

class TherapistStaffModel {
  final String id;
  final String name;
  final String gender;
  final String phone;
  final String specialty;
  final String district;
  final double distanceKm;
  bool isOnline;
  final double rating;
  int completedSessions;
  double cashCustody;

  TherapistStaffModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.phone,
    required this.specialty,
    required this.district,
    required this.distanceKm,
    required this.isOnline,
    required this.rating,
    required this.completedSessions,
    required this.cashCustody,
  });
}

class DispatchOrderModel {
  final String id;
  final String orderCode;
  final String patientName;
  final String patientPhone;
  final String serviceLabel;
  final String specialty;
  final String preferredGender;
  final String district;
  final String addressNotes;
  final String scheduledLabel;
  final double price;
  String status;
  String? assignedTherapistId;
  String? rejectionNote;

  DispatchOrderModel({
    required this.id,
    required this.orderCode,
    required this.patientName,
    required this.patientPhone,
    required this.serviceLabel,
    required this.specialty,
    required this.preferredGender,
    required this.district,
    required this.addressNotes,
    required this.scheduledLabel,
    required this.price,
    required this.status,
    this.assignedTherapistId,
    this.rejectionNote,
  });
}

class AdminRepository {
  AdminSettingsModel settings = AdminSettingsModel(
    centerName: 'مركز الشفاء للعلاج الطبيعي المنزلي',
    primaryColorHex: '#0D9488',
    allowTherapistReject: true,
    autoDispatch: false,
    showPatientPhone: false,
    centerCommissionPct: 40.0,
    singleSessionPrice: 70.0,
    assessmentPrice: 80.0,
    package6Price: 360.0,
    maxCashCustodyLimit: 1000.0,
  );

  List<TherapistStaffModel> therapists = [
    TherapistStaffModel(
      id: 'th_1',
      name: 'د. أحمد السنوسي',
      gender: 'male',
      phone: '092-5112030',
      specialty: 'تأهيل عظام وكسور وإصابات ملاعب',
      district: 'حي الأندلس / قرقارش',
      distanceKm: 1.8,
      isOnline: true,
      rating: 4.90,
      completedSessions: 42,
      cashCustody: 280.0,
    ),
    TherapistStaffModel(
      id: 'th_2',
      name: 'د. سارة الفيتوري',
      gender: 'female',
      phone: '091-6093312',
      specialty: 'تأهيل أعصاب وجلطات ومسنين',
      district: 'النوفليين / زاوية الدهماني',
      distanceKm: 3.1,
      isOnline: true,
      rating: 4.95,
      completedSessions: 58,
      cashCustody: 420.0,
    ),
    TherapistStaffModel(
      id: 'th_3',
      name: 'د. محمد الورفلي',
      gender: 'male',
      phone: '094-3901122',
      specialty: 'تأهيل عمود فقري وأطفال',
      district: 'سوق الجمعة / عين زارة',
      distanceKm: 5.4,
      isOnline: false,
      rating: 4.80,
      completedSessions: 31,
      cashCustody: 140.0,
    ),
  ];

  List<DispatchOrderModel> orders = [
    DispatchOrderModel(
      id: '104',
      orderCode: 'ORD-104',
      patientName: 'خالد المبروك',
      patientPhone: '091-4829104',
      serviceLabel: 'جلسة علاجية منزلية مفردة',
      specialty: 'تأهيل عظام وكسور وإصابات ملاعب',
      preferredGender: 'male',
      district: 'حي الأندلس',
      addressNotes: 'قرب جزيرة حي الأندلس، شارع الصيدلية، الدور الثاني',
      scheduledLabel: 'فوري (اليوم 15:00)',
      price: 70.0,
      status: 'pending_review',
    ),
    DispatchOrderModel(
      id: '103',
      orderCode: 'ORD-103',
      patientName: 'الحاجة فاطمة الزروق',
      patientPhone: '092-7741900',
      serviceLabel: 'زيارة تقييم وكشف أولي',
      specialty: 'تأهيل أعصاب وجلطات ومسنين',
      preferredGender: 'female',
      district: 'النوفليين',
      addressNotes: 'بجوار مسجد القدس، منزل رقم 14',
      scheduledLabel: 'اليوم 16:30 مساءً',
      price: 80.0,
      status: 'dispatched',
      assignedTherapistId: 'th_2',
    ),
  ];

  TherapistStaffModel? findTherapist(String? id) {
    if (id == null) return null;
    for (final t in therapists) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> dispatchOrderToTherapist(String orderId, String therapistId) async {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      orders[idx].status = 'dispatched';
      orders[idx].assignedTherapistId = therapistId;
      orders[idx].rejectionNote = null;
    }
    try {
      await http
          .post(
            Uri.parse('$kApiBaseUrl/admin/dispatch'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'order_id': orderId, 'therapist_id': therapistId}),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> settleTherapistCustody(String therapistId) async {
    final th = findTherapist(therapistId);
    if (th != null) {
      th.cashCustody = 0.0;
    }
    try {
      await http
          .post(
            Uri.parse('$kApiBaseUrl/admin/settle-custody'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'therapist_id': therapistId}),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> saveSettings() async {
    try {
      await http
          .put(
            Uri.parse('$kApiBaseUrl/admin/settings'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(settings.toJson()),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }
}

// =============================================================================
// واجهة تطبيق الأدمن (Material 3 RTL)
// =============================================================================

class PhysioAdminApp extends StatefulWidget {
  const PhysioAdminApp({super.key});

  @override
  State<PhysioAdminApp> createState() => _PhysioAdminAppState();
}

class _PhysioAdminAppState extends State<PhysioAdminApp> {
  final AdminRepository repo = AdminRepository();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'لوحة تحكم الأدمن - ${repo.settings.centerName}',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: AdminDashboardScreen(
        repo: repo,
        onSettingsUpdated: () => setState(() {}),
      ),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  final AdminRepository repo;
  final VoidCallback onSettingsUpdated;

  const AdminDashboardScreen({
    super.key,
    required this.repo,
    required this.onSettingsUpdated,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0;
  final Map<String, String> _selectedTherapistPerOrder = {};

  late TextEditingController _centerNameCtrl;
  late TextEditingController _commPctCtrl;
  late TextEditingController _singlePriceCtrl;

  @override
  void initState() {
    super.initState();
    _centerNameCtrl = TextEditingController(text: widget.repo.settings.centerName);
    _commPctCtrl = TextEditingController(
      text: widget.repo.settings.centerCommissionPct.toInt().toString(),
    );
    _singlePriceCtrl = TextEditingController(
      text: widget.repo.settings.singleSessionPrice.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _centerNameCtrl.dispose();
    _commPctCtrl.dispose();
    _singlePriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        widget.repo.orders.where((o) => o.status == 'pending_review').length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إدارة التوجيه - ${widget.repo.settings.centerName}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              'الأخصائيون المتصلون: ${widget.repo.therapists.where((t) => t.isOnline).length} • بانتظار التوجيه: $pendingCount',
              style: const TextStyle(fontSize: 12, color: Colors.amberAccent),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildDispatchQueueTab(),
          _buildTherapistsTab(),
          _buildFinancialCustodyTab(),
          _buildDynamicSettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (idx) => setState(() => _selectedTab = idx),
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.radar_outlined),
            ),
            selectedIcon: const Icon(Icons.radar),
            label: 'التوجيه',
          ),
          const NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services),
            label: 'الأخصائيون',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'العهدة والمالية',
          ),
          const NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'تخصيص النظام',
          ),
        ],
      ),
    );
  }

  // 1. شاشة التوجيه والعمليات
  Widget _buildDispatchQueueTab() {
    final onlineTherapists =
        widget.repo.therapists.where((t) => t.isOnline).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.repo.orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = widget.repo.orders[index];
        final assigned = widget.repo.findTherapist(order.assignedTherapistId);

        final defaultThId = onlineTherapists.isNotEmpty ? onlineTherapists.first.id : '';
        final currentSelectedThId =
            _selectedTherapistPerOrder[order.id] ?? defaultThId;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: order.status == 'pending_review'
                  ? Colors.red.shade300
                  : Colors.grey.shade300,
              width: order.status == 'pending_review' ? 1.5 : 1.0,
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
                      '#${order.orderCode} • ${order.patientName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Chip(
                      label: Text(
                        order.status == 'pending_review'
                            ? 'طلب جديد بانتظار التوجيه'
                            : 'مُوجّه لـ ${assigned?.name ?? ""}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: order.status == 'pending_review'
                          ? Colors.red.shade50
                          : Colors.amber.shade50,
                    ),
                  ],
                ),
                Text(
                  '${order.serviceLabel} (${order.price.toInt()} د.ل) • ${order.specialty}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  'العنوان: ${order.district} - ${order.addressNotes}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                Text(
                  'هاتف المريض: ${order.patientPhone} • الموعد: ${order.scheduledLabel}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                const Divider(height: 20),
                if (order.status == 'pending_review') ...[
                  const Text(
                    'اختر أخصائياً متصلاً (Online) لتحويل الطلب إليه:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  if (onlineTherapists.isEmpty)
                    const Text(
                      'لا يوجد أخصائيون متصلون حالياً! قم بتفعيل أخصائي من تبويب الأخصائيين.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: onlineTherapists.any((t) => t.id == currentSelectedThId)
                                ? currentSelectedThId
                                : onlineTherapists.first.id,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: onlineTherapists.map((th) {
                              return DropdownMenuItem(
                                value: th.id,
                                child: Text(
                                  '${th.name} (${th.distanceKm} كم)',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedTherapistPerOrder[order.id] = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                          onPressed: () async {
                            final chosenId = _selectedTherapistPerOrder[order.id] ??
                                onlineTherapists.first.id;
                            await widget.repo.dispatchOrderToTherapist(order.id, chosenId);
                            if (mounted) {
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم تحويل الطلب للأخصائي وإرسال إشعار فوري لهاتفه!'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.send, size: 16),
                          label: const Text('تحويل الطلب'),
                        ),
                      ],
                    ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الأخصائي المكلف: ${assigned?.name ?? "-"}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            order.status = 'pending_review';
                            order.assignedTherapistId = null;
                          });
                        },
                        icon: const Icon(Icons.replay, size: 16),
                        label: const Text('إعادة توجيه لبديل'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. شاشة إدارة الأخصائيين الميدانيين
  Widget _buildTherapistsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.repo.therapists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final th = widget.repo.therapists[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: CircleAvatar(
              backgroundColor: th.isOnline ? Colors.green.shade100 : Colors.grey.shade200,
              child: Icon(
                Icons.person,
                color: th.isOnline ? Colors.green.shade800 : Colors.grey,
              ),
            ),
            title: Text(th.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(th.specialty, style: const TextStyle(fontSize: 12)),
                Text(
                  'النطاق: ${th.district} • التقييم: ★ ${th.rating} • العهدة: ${th.cashCustody.toInt()} د.ل',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            trailing: Switch(
              value: th.isOnline,
              activeColor: Colors.green,
              onChanged: (val) => setState(() => th.isOnline = val),
            ),
          ),
        );
      },
    );
  }

  // 3. شاشة المحفظة والعهدة المالية
  Widget _buildFinancialCustodyTab() {
    final pct = widget.repo.settings.centerCommissionPct;
    final totalCash =
        widget.repo.therapists.fold<double>(0.0, (sum, t) => sum + t.cashCustody);
    final totalCenterShare = totalCash * (pct / 100.0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('إجمالي كاش الأخصائيين', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '${totalCash.toInt()} د.ل',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('صافي حصة المركز (${pct.toInt()}%)', style: const TextStyle(color: Colors.tealAccent, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '${totalCenterShare.toInt()} د.ل',
                      style: const TextStyle(color: Colors.tealAccent, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...widget.repo.therapists.map((th) {
          final centerShare = (th.cashCustody * (pct / 100.0)).round();
          final thKeep = th.cashCustody.round() - centerShare;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(th.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        'عهدة الكاش: ${th.cashCustody.toInt()} د.ل',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('حصة المركز المطلوبة: $centerShare د.ل • صافي ربح الأخصائي: $thKeep د.ل', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: th.cashCustody <= 0
                          ? null
                          : () async {
                              await widget.repo.settleTherapistCustody(th.id);
                              if (mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('تم استلام $centerShare د.ل وتصفير عهدة ${th.name}')),
                                );
                              }
                            },
                      child: Text(
                        th.cashCustody > 0
                            ? 'استلام حصة المركز ($centerShare د.ل) وتصفية العهدة'
                            : 'العهدة مصفاة بالكامل ✓',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // 4. شاشة تخصيص النظام المرنة (تعديل الـ Workflow والأسعار بدون إعادة برمجة)
  Widget _buildDynamicSettingsTab() {
    final s = widget.repo.settings;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                const Text(
                  'إعدادات المركز وقواعد العمل (Server-Driven Config)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _centerNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم المركز الطبي (White-Label)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('التوجيه التلقائي لأقرب أخصائي متاح'),
                  subtitle: const Text('تحويل طلب المريض مباشرة للأخصائي دون انتظار الأدمن'),
                  value: s.autoDispatch,
                  onChanged: (val) => setState(() => s.autoDispatch = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('السماح للأخصائي بالاعتذار عن الطلب'),
                  subtitle: const Text('عند إلغائه يختفي زر الاعتذار من تطبيق الأخصائي'),
                  value: s.allowTherapistReject,
                  onChanged: (val) => setState(() => s.allowTherapistReject = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('إظهار رقم هاتف المريض للأخصائي'),
                  subtitle: const Text('إخفاء الرقم يحمي المركز من الاتفاقات الجانبية خارج المنظومة'),
                  value: s.showPatientPhone,
                  onChanged: (val) => setState(() => s.showPatientPhone = val),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commPctCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'نسبة المركز (%)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _singlePriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'سعر الجلسة المفردة (د.ل)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () async {
                      s.centerName = _centerNameCtrl.text.trim();
                      s.centerCommissionPct =
                          double.tryParse(_commPctCtrl.text) ?? 40.0;
                      s.singleSessionPrice =
                          double.tryParse(_singlePriceCtrl.text) ?? 70.0;
                      await widget.repo.saveSettings();
                      widget.onSettingsUpdated();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم حفظ الإعدادات وتعميمها على التطبيقات الثلاثة بنجاح!'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('حفظ وتعميم الإعدادات فوراً'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
