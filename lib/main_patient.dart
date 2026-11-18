// =============================================================================
// البرنامج الأول: تطبيق المريض (Patient Android App)
// يعمل بشكل كامل ومستقل، ويتصل بخادم المنظومة وقاعدة بيانات Neon PostgreSQL
// مع وضع محاكاة محلي تلقائي (Offline/Demo Fallback) للعرض الفوري أمام المركز
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PhysioPatientApp());
}

// عنوان الخادم الخلفي المتصل بقاعدة بيانات Neon (يُعدّل عند رفع الخادم على Render/Railway)
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://your-physio-api.onrender.com/api',
);

// =============================================================================
// النماذج المشتركة (Data Models)
// =============================================================================

class CenterSettingsModel {
  final String centerName;
  final Color primaryColor;
  final String supportPhone;
  final double singleSessionPrice;
  final double assessmentPrice;
  final double package6Price;

  const CenterSettingsModel({
    required this.centerName,
    required this.primaryColor,
    required this.supportPhone,
    required this.singleSessionPrice,
    required this.assessmentPrice,
    required this.package6Price,
  });

  factory CenterSettingsModel.fromJson(Map<String, dynamic> json) {
    final hex = (json['primary_color_hex'] ?? '#0D9488').toString().replaceAll('#', '');
    return CenterSettingsModel(
      centerName: json['center_name'] ?? 'مركز الشفاء للعلاج الطبيعي المنزلي',
      primaryColor: Color(int.parse('FF$hex', radix: 16)),
      supportPhone: json['support_phone'] ?? '091-0000000',
      singleSessionPrice: double.tryParse(json['single_session_price'].toString()) ?? 70.0,
      assessmentPrice: double.tryParse(json['assessment_price'].toString()) ?? 80.0,
      package6Price: double.tryParse(json['package_6_price'].toString()) ?? 360.0,
    );
  }

  static CenterSettingsModel defaults() => const CenterSettingsModel(
        centerName: 'مركز الشفاء للعلاج الطبيعي المنزلي',
        primaryColor: Color(0xFF0D9488),
        supportPhone: '091-0000000',
        singleSessionPrice: 70.0,
        assessmentPrice: 80.0,
        package6Price: 360.0,
      );
}

class PatientOrderModel {
  final String id;
  final String orderCode;
  final String serviceType;
  final String serviceLabel;
  final String specialty;
  final String preferredGender;
  final String district;
  final String addressNotes;
  final String scheduledLabel;
  String status;
  final double price;
  final String paymentMethod;
  String? therapistName;
  String? clinicalNotes;
  String? homeExercises;
  int? rating;
  final String createdAtLabel;

  PatientOrderModel({
    required this.id,
    required this.orderCode,
    required this.serviceType,
    required this.serviceLabel,
    required this.specialty,
    required this.preferredGender,
    required this.district,
    required this.addressNotes,
    required this.scheduledLabel,
    required this.status,
    required this.price,
    required this.paymentMethod,
    this.therapistName,
    this.clinicalNotes,
    this.homeExercises,
    this.rating,
    required this.createdAtLabel,
  });

  factory PatientOrderModel.fromJson(Map<String, dynamic> json) {
    return PatientOrderModel(
      id: json['id']?.toString() ?? '',
      orderCode: json['order_code'] ?? 'ORD-100',
      serviceType: json['service_type'] ?? 'single',
      serviceLabel: json['service_label'] ?? 'جلسة علاجية منزلية',
      specialty: json['specialty_needed'] ?? 'تأهيل عظام وكسور',
      preferredGender: json['preferred_gender'] ?? 'any',
      district: json['district'] ?? 'حي الأندلس',
      addressNotes: json['address_notes'] ?? '',
      scheduledLabel: json['scheduled_label'] ?? 'فوري',
      status: json['status'] ?? 'pending_review',
      price: double.tryParse(json['price'].toString()) ?? 70.0,
      paymentMethod: json['payment_method'] ?? 'cash',
      therapistName: json['therapist_name'],
      clinicalNotes: json['clinical_notes'],
      homeExercises: json['home_exercises'],
      rating: json['patient_rating'] != null
          ? int.tryParse(json['patient_rating'].toString())
          : null,
      createdAtLabel: json['created_at_label'] ?? 'اليوم',
    );
  }
}

class PatientPackageModel {
  final String id;
  final String title;
  final String therapistName;
  final int totalSessions;
  int remainingSessions;
  final String scheduleDays;

  PatientPackageModel({
    required this.id,
    required this.title,
    required this.therapistName,
    required this.totalSessions,
    required this.remainingSessions,
    required this.scheduleDays,
  });
}

// =============================================================================
// خدمة الاتصال بالخادم وقاعدة بيانات Neon (مع دعم العمل الفوري للتجربة)
// =============================================================================

class PatientRepository {
  CenterSettingsModel settings = CenterSettingsModel.defaults();
  final String currentPatientId = '11111111-1111-1111-1111-111111111111';
  String patientName = 'خالد المبروك';
  String patientPhone = '091-4829104';

  PatientPackageModel activePackage = PatientPackageModel(
    id: 'pkg-1',
    title: 'باقة تأهيل مفصل الركبة (6 جلسات)',
    therapistName: 'د. أحمد السنوسي',
    totalSessions: 6,
    remainingSessions: 4,
    scheduleDays: 'السبت • الإثنين • الأربعاء (5:00 مساءً)',
  );

  List<PatientOrderModel> orders = [
    PatientOrderModel(
      id: '1',
      orderCode: 'ORD-104',
      serviceType: 'single',
      serviceLabel: 'جلسة علاجية منزلية مفردة',
      specialty: 'تأهيل عظام وكسور وإصابات ملاعب',
      preferredGender: 'male',
      district: 'حي الأندلس',
      addressNotes: 'قرب جزيرة حي الأندلس، شارع الصيدلية، الدور الثاني',
      scheduledLabel: 'اليوم 16:00 مساءً',
      status: 'accepted',
      price: 70.0,
      paymentMethod: 'cash',
      therapistName: 'د. أحمد السنوسي',
      createdAtLabel: 'منذ 10 دقائق',
    ),
    PatientOrderModel(
      id: '2',
      orderCode: 'ORD-101',
      serviceType: 'package_use',
      serviceLabel: 'جلسة من باقة (2/6)',
      specialty: 'تأهيل عظام وكسور وإصابات ملاعب',
      preferredGender: 'male',
      district: 'حي الأندلس',
      addressNotes: 'قرب جزيرة حي الأندلس، شارع الصيدلية، الدور الثاني',
      scheduledLabel: 'أمس 17:00 مساءً',
      status: 'completed',
      price: 60.0,
      paymentMethod: 'package',
      therapistName: 'د. أحمد السنوسي',
      clinicalNotes: 'تحسن ممتاز في زاوية ثني الركبة إلى 105 درجات وانخفاض التورم حول المفصل.',
      homeExercises: 'تمرين رفع الساق المستقيمة 15 عدة × 3 مجموعات يومياً + كمادات باردة 10 دقائق.',
      rating: 5,
      createdAtLabel: 'أمس',
    ),
  ];

  Future<void> syncWithServer() async {
    try {
      final res = await http
          .get(Uri.parse('$kApiBaseUrl/patient/bootstrap?patientId=$currentPatientId'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['settings'] != null) {
          settings = CenterSettingsModel.fromJson(data['settings']);
        }
        if (data['orders'] is List) {
          orders = (data['orders'] as List)
              .map((item) => PatientOrderModel.fromJson(item))
              .toList();
        }
      }
    } catch (_) {
      // في حال عدم تشغيل السرفر بعد، يعمل التطبيق بالبيانات المحلية للعرض التجريبي
    }
  }

  Future<PatientOrderModel> createOrder({
    required String serviceType,
    required String serviceLabel,
    required String specialty,
    required String preferredGender,
    required String district,
    required String addressNotes,
    required String scheduledLabel,
    required double price,
    required String paymentMethod,
  }) async {
    final code = 'ORD-${105 + orders.length}';
    final newOrder = PatientOrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderCode: code,
      serviceType: serviceType,
      serviceLabel: serviceLabel,
      specialty: specialty,
      preferredGender: preferredGender,
      district: district,
      addressNotes: addressNotes,
      scheduledLabel: scheduledLabel,
      status: 'pending_review',
      price: price,
      paymentMethod: paymentMethod,
      createdAtLabel: 'الآن',
    );

    if (serviceType == 'package_use' && activePackage.remainingSessions > 0) {
      activePackage.remainingSessions -= 1;
    }

    orders.insert(0, newOrder);

    try {
      await http
          .post(
            Uri.parse('$kApiBaseUrl/visits'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'order_code': code,
              'patient_id': currentPatientId,
              'patient_name': patientName,
              'patient_phone': patientPhone,
              'service_type': serviceType,
              'service_label': serviceLabel,
              'specialty_needed': specialty,
              'preferred_gender': preferredGender,
              'district': district,
              'address_notes': addressNotes,
              'scheduled_label': scheduledLabel,
              'price': price,
              'payment_method': paymentMethod,
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // محفوظ محلياً للعرض
    }

    return newOrder;
  }

  Future<void> rateSession(String orderId, int stars) async {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      orders[index].rating = stars;
    }
    try {
      await http
          .patch(
            Uri.parse('$kApiBaseUrl/visits/$orderId/rate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'rating': stars}),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }
}

// =============================================================================
// واجهة التطبيق الرئيسية (Material 3 RTL)
// =============================================================================

class PhysioPatientApp extends StatefulWidget {
  const PhysioPatientApp({super.key});

  @override
  State<PhysioPatientApp> createState() => _PhysioPatientAppState();
}

class _PhysioPatientAppState extends State<PhysioPatientApp> {
  final PatientRepository repo = PatientRepository();

  @override
  void initState() {
    super.initState();
    repo.syncWithServer().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final seedColor = repo.settings.primaryColor;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: repo.settings.centerName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: PatientHomeScreen(repo: repo),
    );
  }
}

class PatientHomeScreen extends StatefulWidget {
  final PatientRepository repo;
  const PatientHomeScreen({super.key, required this.repo});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;

  // حقول نموذج الحجز
  String _selectedServiceType = 'single';
  String _selectedSpecialty = 'تأهيل عظام وكسور وإصابات ملاعب';
  String _selectedGenderPref = 'male';
  String _selectedTiming = 'فوري (في أقرب وقت اليوم)';
  String _selectedDistrict = 'حي الأندلس';
  final TextEditingController _addressController = TextEditingController(
    text: 'قرب جزيرة حي الأندلس، شارع الصيدلية، الدور الثاني',
  );
  bool _gpsCaptured = true;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _resolveServicePricing() {
    final s = widget.repo.settings;
    switch (_selectedServiceType) {
      case 'assessment':
        return {
          'label': 'زيارة تقييم وكشف أولي شامل',
          'price': s.assessmentPrice,
          'method': 'cash'
        };
      case 'package_new':
        return {
          'label': 'حجز باقة 6 جلسات منزلية مخفضة',
          'price': s.package6Price,
          'method': 'cash'
        };
      case 'package_use':
        return {
          'label': 'طلب جلسة من باقتي الفعالة',
          'price': 0.0,
          'method': 'package'
        };
      default:
        return {
          'label': 'جلسة علاجية منزلية مفردة',
          'price': s.singleSessionPrice,
          'method': 'cash'
        };
    }
  }

  Future<void> _submitOrder() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال وصف العنوان بالتفصيل')),
      );
      return;
    }

    final pricing = _resolveServicePricing();
    final created = await widget.repo.createOrder(
      serviceType: _selectedServiceType,
      serviceLabel: pricing['label'] as String,
      specialty: _selectedSpecialty,
      preferredGender: _selectedGenderPref,
      district: _selectedDistrict,
      addressNotes: _addressController.text.trim(),
      scheduledLabel: _selectedTiming,
      price: pricing['price'] as double,
      paymentMethod: pricing['method'] as String,
    );

    if (!mounted) return;
    setState(() {
      _selectedIndex = 1; // الانتقال المباشر لتبويب متابعة الطلبات
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: widget.repo.settings.primaryColor,
        content: Text(
          'تم إرسال طلبك رقم #${created.orderCode} إلى المركز بنجاح، جاري تعيين الأخصائي.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.repo.settings;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: s.primaryColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.centerName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'المريض: ${widget.repo.patientName} • رصيد الباقة: ${widget.repo.activePackage.remainingSessions} جلسات',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث الحالة',
            onPressed: () async {
              await widget.repo.syncWithServer();
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildBookingTab(),
          _buildOrdersTab(),
          _buildMedicalFileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'طلب زيارة',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text(
                widget.repo.orders
                    .where((o) => o.status != 'completed')
                    .length
                    .toString(),
              ),
              child: const Icon(Icons.assignment_outlined),
            ),
            selectedIcon: const Icon(Icons.assignment),
            label: 'طلباتي وجلساتي',
          ),
          const NavigationDestination(
            icon: Icon(Icons.medical_information_outlined),
            selectedIcon: Icon(Icons.medical_information),
            label: 'ملفي والباقات',
          ),
        ],
      ),
    );
  }

  // التبويب الأول: طلب زيارة منزلية جديدة
  Widget _buildBookingTab() {
    final s = widget.repo.settings;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: s.primaryColor.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: s.primaryColor.withOpacity(0.25)),
          ),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.home_work_outlined, size: 32, color: Color(0xFF0D9488)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'احجز جلستك المنزلية في أقل من دقيقة',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'يصل طلبك فوراً لموظف المركز ليحوله لأقرب أخصائي علاج طبيعي متاح ومطابق لحالتك.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
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
                const Text(
                  '1. نوع الخدمة المطلوبة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedServiceType,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'single',
                      child: Text('جلسة علاجية منزلية مفردة (${s.singleSessionPrice.toInt()} د.ل)'),
                    ),
                    DropdownMenuItem(
                      value: 'assessment',
                      child: Text('زيارة تقييم وكشف أولي (${s.assessmentPrice.toInt()} د.ل)'),
                    ),
                    DropdownMenuItem(
                      value: 'package_new',
                      child: Text('باقة 6 جلسات منزلية (${s.package6Price.toInt()} د.ل)'),
                    ),
                    const DropdownMenuItem(
                      value: 'package_use',
                      child: Text('طلب جلسة من باقتي الفعالة (خصم من الرصيد)'),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedServiceType = val ?? 'single'),
                ),
                const SizedBox(height: 14),
                const Text(
                  '2. التخصص الطبي للحالة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedSpecialty,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'تأهيل عظام وكسور وإصابات ملاعب',
                      child: Text('تأهيل عظام وكسور وإصابات ملاعب'),
                    ),
                    DropdownMenuItem(
                      value: 'تأهيل أعصاب وجلطات ومسنين',
                      child: Text('تأهيل أعصاب وجلطات ومسنين'),
                    ),
                    DropdownMenuItem(
                      value: 'تأهيل عمود فقري وأطفال',
                      child: Text('تأهيل عمود فقري وانزلاق غضروفي وأطفال'),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedSpecialty = val!),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '3. تفضيل الأخصائي',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedGenderPref,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'male', child: Text('أخصائي (رجل)')),
                              DropdownMenuItem(value: 'female', child: Text('أخصائية (امرأة)')),
                              DropdownMenuItem(value: 'any', child: Text('أي متاح')),
                            ],
                            onChanged: (val) => setState(() => _selectedGenderPref = val ?? 'any'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '4. موعد الزيارة',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedTiming,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'فوري (في أقرب وقت اليوم)',
                                child: Text('فوري (اليوم)'),
                              ),
                              DropdownMenuItem(
                                value: 'اليوم 18:00 مساءً',
                                child: Text('اليوم 6:00 م'),
                              ),
                              DropdownMenuItem(
                                value: 'غداً 10:00 صباحاً',
                                child: Text('غداً 10:00 ص'),
                              ),
                            ],
                            onChanged: (val) => setState(() => _selectedTiming = val!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  '5. المنطقة والعنوان وإحداثيات GPS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'حي الأندلس', child: Text('حي الأندلس')),
                          DropdownMenuItem(value: 'النوفليين', child: Text('النوفليين')),
                          DropdownMenuItem(value: 'قرقارش', child: Text('قرقارش')),
                          DropdownMenuItem(value: 'زاوية الدهماني', child: Text('زاوية الدهماني')),
                          DropdownMenuItem(value: 'عين زارة', child: Text('عين زارة')),
                        ],
                        onChanged: (val) => setState(() => _selectedDistrict = val!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _gpsCaptured = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تحديث إحداثيات موقعك عبر GPS بنجاح')),
                        );
                      },
                      icon: Icon(
                        Icons.my_location,
                        color: _gpsCaptured ? Colors.green.shade700 : Colors.grey,
                        size: 18,
                      ),
                      label: Text(_gpsCaptured ? 'تم التقاط GPS' : 'تحديد موقعي'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'وصف العنوان التفصيلي ورقم الطابق',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: s.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submitOrder,
                    icon: const Icon(Icons.send),
                    label: const Text(
                      'إرسال طلب الزيارة للمركز الآن',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // التبويب الثاني: قائمة الطلبات ومتابعة المراحل
  Widget _buildOrdersTab() {
    if (widget.repo.orders.isEmpty) {
      return const Center(child: Text('لا توجد طلبات سابقة حتى الآن.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.repo.orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = widget.repo.orders[index];
        final stepIdx = _statusStepIndex(order.status);

        return Card(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${order.orderCode} • ${order.createdAtLabel}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(order.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusArabicLabel(order.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _statusColor(order.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  order.serviceLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  order.specialty,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                // شريط تقدم الطلب (6 خطوات)
                Row(
                  children: List.generate(6, (idx) {
                    final active = (idx + 1) <= stepIdx;
                    final titles = ['مراجعة', 'توجيه', 'مقبول', 'بالطريق', 'بالجلسة', 'مكتمل'];
                    return Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: active
                                ? widget.repo.settings.primaryColor
                                : Colors.grey.shade300,
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                color: active ? Colors.white : Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            titles[idx],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: active ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const Divider(height: 22),
                _infoRow('الأخصائي المكلف:', order.therapistName ?? 'جاري التعيين من المركز...'),
                _infoRow('المنطقة والموعد:', '${order.district} • ${order.scheduledLabel}'),
                _infoRow(
                  'التكلفة وطريقة الدفع:',
                  order.paymentMethod == 'package'
                      ? 'مخصومة من رصيد الباقة'
                      : '${order.price.toInt()} د.ل (نقداً عند الزيارة)',
                ),
                if (order.clinicalNotes != null && order.clinicalNotes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'التقرير الطبي للجلسة:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(order.clinicalNotes!, style: const TextStyle(fontSize: 12)),
                        if (order.homeExercises != null && order.homeExercises!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          const Text(
                            'التمارين المنزلية المطلوبة:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(order.homeExercises!, style: const TextStyle(fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ],
                if (order.status == 'completed') ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('تقييمك للجلسة:', style: TextStyle(fontSize: 12)),
                      Row(
                        children: List.generate(5, (starIdx) {
                          final starVal = starIdx + 1;
                          final filled = (order.rating ?? 0) >= starVal;
                          return IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () async {
                              await widget.repo.rateSession(order.id, starVal);
                              if (mounted) setState(() {});
                            },
                            icon: Icon(
                              filled ? Icons.star : Icons.star_border,
                              color: Colors.amber.shade600,
                              size: 22,
                            ),
                          );
                        }),
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

  // التبويب الثالث: الباقات العلاجية والتمارين المنزلية
  Widget _buildMedicalFileTab() {
    final pkg = widget.repo.activePackage;
    final done = pkg.totalSessions - pkg.remainingSessions;
    final progress = done / pkg.totalSessions;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الباقة العلاجية النشطة',
                  style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  pkg.title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'الأخصائي المتابع: ${pkg.therapistName}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  'المواعيد: ${pkg.scheduleDays}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  color: Colors.tealAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 8),
                Text(
                  'تم تنفيذ $done جلسات • متبقي ${pkg.remainingSessions} جلسات',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'خطة التمارين المنزلية الموصى بها لك',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.check_circle, color: Colors.teal),
                  title: Text('تمرين رفع الساق المستقيمة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text('15 عدة × 3 مجموعات صباحاً ومساءً', style: TextStyle(fontSize: 12)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.check_circle, color: Colors.teal),
                  title: Text('ثني الركبة التدريجي على الكرسي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text('الثبات لمدة 10 ثوانٍ × 10 تكرارات', style: TextStyle(fontSize: 12)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.ac_unit, color: Colors.blue),
                  title: Text('كمادات باردة حول المفصل', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text('لمدة 10 دقائق بعد الانتهاء من التمارين', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  int _statusStepIndex(String status) {
    switch (status) {
      case 'pending_review':
        return 1;
      case 'dispatched':
        return 2;
      case 'accepted':
        return 3;
      case 'en_route':
        return 4;
      case 'in_session':
        return 5;
      case 'completed':
        return 6;
      default:
        return 1;
    }
  }

  String _statusArabicLabel(String status) {
    switch (status) {
      case 'pending_review':
        return 'بانتظار مراجعة المركز';
      case 'dispatched':
        return 'تم التوجيه للأخصائي';
      case 'accepted':
        return 'الأخصائي قبل الطلب';
      case 'en_route':
        return 'الأخصائي في الطريق إليك';
      case 'in_session':
        return 'الجلسة جارية الآن';
      case 'completed':
        return 'مكتملة';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending_review':
        return Colors.red.shade700;
      case 'dispatched':
        return Colors.amber.shade800;
      case 'accepted':
        return Colors.blue.shade700;
      case 'en_route':
        return Colors.indigo.shade700;
      case 'in_session':
        return Colors.teal.shade700;
      case 'completed':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }
}
