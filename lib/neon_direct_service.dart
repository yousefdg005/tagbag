import 'dart:convert';
import 'package:http/http.dart' as http;

/// ============================================================================
/// خدمة الاتصال المباشر بقاعدة بيانات Neon PostgreSQL عبر HTTPS
/// تعمل مباشرة من الهواتف عبر أي شبكة (4G / 5G / Wi-Fi) دون الحاجة لأي سيرفر وسيط!
/// ============================================================================
class NeonDirectService {
  // رابط اتصال Neon المباشر
  static const String defaultConnectionString = String.fromEnvironment(
    'NEON_URL',
    defaultValue:
        'postgresql://neondb_owner:npg_frNAe0Tb8wEs@ep-dark-wave-bdz7xhnb-pooler.c-8.us-east-2.aws.neon.tech/neondb?sslmode=require',
  );

  static const String endpointHost =
      'ep-dark-wave-bdz7xhnb-pooler.c-8.us-east-2.aws.neon.tech';

  /// تنفيذ استعلام SQL مباشرة على نيون
  static Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<dynamic>? params,
  ]) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://$endpointHost/sql'),
            headers: {
              'Neon-Connection-String': defaultConnectionString,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'query': sql,
              if (params != null && params.isNotEmpty) 'params': params,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
            'فشل استعلام Neon [${response.statusCode}]: ${response.body}');
      }

      final data = jsonDecode(response.body);
      if (data['rows'] is List) {
        return List<Map<String, dynamic>>.from(data['rows']);
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('خطأ في الاتصال المباشر بقاعدة بيانات نيون: $e');
      rethrow;
    }
  }

  // --- دوال مساعدة جاهزة لمنظومة العلاج الطبيعي ---

  /// جلب إعدادات المركز
  static Future<Map<String, dynamic>?> getCenterSettings() async {
    final rows = await query('SELECT * FROM center_settings WHERE id = 1');
    return rows.isNotEmpty ? rows.first : null;
  }

  /// جلب جميع الأخصائيين المعتمدين مع حالتهم اللحظية
  static Future<List<Map<String, dynamic>>> getTherapists() async {
    return await query('''
      SELECT u.id, u.full_name, u.phone, u.gender, tp.specialty, 
             tp.coverage_district, tp.is_online, tp.rating,
             tp.cash_custody_balance, tp.completed_sessions_count
      FROM users u
      JOIN therapist_profiles tp ON u.id = tp.user_id
      WHERE u.role = 'therapist'
      ORDER BY tp.rating DESC
    ''');
  }

  /// إنشاء طلب زيارة جديدة من المريض مباشرة إلى نيون
  static Future<void> createVisit({
    required String orderCode,
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String serviceType,
    required String serviceLabel,
    required String specialtyNeeded,
    required String preferredGender,
    required String district,
    required String addressNotes,
    required String scheduledLabel,
    required double price,
    required String paymentMethod,
  }) async {
    await query(
      '''
      INSERT INTO home_visits (
        order_code, patient_id, patient_name_snapshot, patient_phone_snapshot,
        service_type, service_label, specialty_needed, preferred_gender,
        district, address_notes, scheduled_label, price, payment_method, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, 'pending_review')
      ''',
      [
        orderCode,
        patientId,
        patientName,
        patientPhone,
        serviceType,
        serviceLabel,
        specialtyNeeded,
        preferredGender,
        district,
        addressNotes,
        scheduledLabel,
        price,
        paymentMethod,
      ],
    );
  }

  /// تحديث حالة الزيارة (قبول / تحرك / وصول / إتمام)
  static Future<void> updateVisitStatus(String visitId, String newStatus) async {
    await query(
      'UPDATE home_visits SET status = $1 WHERE id = $2',
      [newStatus, visitId],
    );
  }

  /// إنهاء الزيارة وكتابة التقرير الطبي وتحديث العهدة النقدية
  static Future<void> completeVisit({
    required String visitId,
    required String therapistId,
    required String clinicalNotes,
    required String homeExercises,
    required double price,
    required bool isCash,
  }) async {
    await query(
      '''
      UPDATE home_visits 
      SET status = 'completed', clinical_notes = $1, home_exercises = $2, completed_at = NOW()
      WHERE id = $3
      ''',
      [clinicalNotes, homeExercises, visitId],
    );

    if (isCash) {
      await query(
        '''
        UPDATE therapist_profiles
        SET cash_custody_balance = cash_custody_balance + $1,
            total_earned = total_earned + $1,
            completed_sessions_count = completed_sessions_count + 1
        WHERE user_id = $2
        ''',
        [price, therapistId],
      );
    }
  }
}
