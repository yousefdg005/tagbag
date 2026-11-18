// =============================================================================
// خادم منظومة الرعاية المنزلية للعلاج الطبيعي (Physio Home Care Server)
// يدعم الوضعين:
// 1. الوضع التجريبي المحلي الفوري (In-Memory Demo Mode) بدون الحاجة لقاعدة بيانات خارجية
// 2. وضع الإنتاج السحابي (Neon PostgreSQL Production Mode) عند توفر DATABASE_URL
// =============================================================================

const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

// تحميل متغيرات البيئة من ملف .env تلقائياً
if (!process.env.DATABASE_URL) {
  try {
    const envPath = path.join(__dirname, '.env');
    if (fs.existsSync(envPath)) {
      const envContent = fs.readFileSync(envPath, 'utf8');
      const match = envContent.match(/DATABASE_URL=["']?([^"'\r\n]+)/);
      if (match) process.env.DATABASE_URL = match[1];
    }
  } catch (_) {}
}

let pgPool = null;
if (process.env.DATABASE_URL) {
  try {
    const { Pool } = require('@neondatabase/serverless');
    pgPool = new Pool({ connectionString: process.env.DATABASE_URL });
    console.log('⚡ Connected to Neon PostgreSQL database.');
  } catch (err) {
    console.warn('⚠️ Could not connect to Neon, falling back to In-Memory Demo Store.', err.message);
  }
} else {
  console.log('💡 Running in In-Memory Demo Mode (Perfect for live demo & presentations).');
}

// -----------------------------------------------------------------------------
// قاعدة البيانات المحلية التجريبية (In-Memory Store for Live Demo)
// -----------------------------------------------------------------------------
function getInitialDemoState() {
  return {
    settings: {
      id: 1,
      center_name: 'مركز الشفاء للعلاج الطبيعي المنزلي',
      primary_color_hex: '#0D9488',
      support_phone: '091-0000000',
      allow_therapist_reject: true,
      auto_dispatch: false,
      show_patient_phone: false,
      center_commission_pct: 40.0,
      single_session_price: 70.0,
      assessment_price: 80.0,
      package_6_price: 360.0,
      max_cash_custody_limit: 1000.0,
      accept_timeout_seconds: 180,
    },
    therapists: [
      {
        id: '33333333-3333-3333-3333-333333333331',
        name: 'د. أحمد السنوسي',
        gender: 'male',
        phone: '092-5112030',
        specialty: 'تأهيل عظام وكسور وإصابات ملاعب',
        district: 'حي الأندلس / قرقارش',
        is_online: true,
        rating: 4.90,
        completed_sessions_count: 42,
        cash_custody_balance: 280.0,
        total_earned: 1680.0,
      },
      {
        id: '33333333-3333-3333-3333-333333333332',
        name: 'د. سارة الفيتوري',
        gender: 'female',
        phone: '091-6093312',
        specialty: 'تأهيل أعصاب وجلطات ومسنين',
        district: 'النوفليين / زاوية الدهماني',
        is_online: true,
        rating: 4.95,
        completed_sessions_count: 58,
        cash_custody_balance: 420.0,
        total_earned: 2310.0,
      },
      {
        id: '33333333-3333-3333-3333-333333333333',
        name: 'د. محمد الورفلي',
        gender: 'male',
        phone: '094-3901122',
        specialty: 'تأهيل عمود فقري وأطفال',
        district: 'سوق الجمعة / عين زارة',
        is_online: false,
        rating: 4.80,
        completed_sessions_count: 31,
        cash_custody_balance: 140.0,
        total_earned: 1120.0,
      },
    ],
    visits: [
      {
        id: '104',
        order_code: 'ORD-104',
        patient_id: '11111111-1111-1111-1111-111111111111',
        patient_name: 'خالد المبروك',
        patient_phone: '091-4829104',
        therapist_id: '33333333-3333-3333-3333-333333333331',
        therapist_name: 'د. أحمد السنوسي',
        service_type: 'single',
        service_label: 'جلسة علاجية منزلية مفردة',
        specialty_needed: 'تأهيل عظام وكسور وإصابات ملاعب',
        preferred_gender: 'male',
        district: 'حي الأندلس',
        address_notes: 'قرب جزيرة حي الأندلس، شارع الصيدلية، الدور الثاني',
        scheduled_label: 'اليوم 15:00 مساءً',
        status: 'accepted',
        price: 70.0,
        payment_method: 'cash',
        rejection_reason: null,
        clinical_notes: null,
        home_exercises: null,
        patient_rating: null,
        created_at: new Date(Date.now() - 1000 * 60 * 15).toISOString(),
      },
      {
        id: '101',
        order_code: 'ORD-101',
        patient_id: '11111111-1111-1111-1111-111111111111',
        patient_name: 'خالد المبروك',
        patient_phone: '091-4829104',
        therapist_id: '33333333-3333-3333-3333-333333333331',
        therapist_name: 'د. أحمد السنوسي',
        service_type: 'package_use',
        service_label: 'جلسة من باقة (2/6)',
        specialty_needed: 'تأهيل عظام وكسور وإصابات ملاعب',
        preferred_gender: 'male',
        district: 'حي الأندلس',
        address_notes: 'قرب جزيرة حي الأندلس، شارع الصيدلية، الدور الثاني',
        scheduled_label: 'أمس 17:00 مساءً',
        status: 'completed',
        price: 60.0,
        payment_method: 'package',
        rejection_reason: null,
        clinical_notes: 'تحسن ممتاز في زاوية ثني الركبة إلى 105 درجات وانخفاض التورم حول المفصل.',
        home_exercises: 'تمرين رفع الساق المستقيمة 15 عدة × 3 مجموعات يومياً + كمادات باردة 10 دقائق.',
        patient_rating: 5,
        created_at: new Date(Date.now() - 1000 * 60 * 60 * 24).toISOString(),
      },
      {
        id: '105',
        order_code: 'ORD-105',
        patient_id: '44444444-4444-4444-4444-444444444444',
        patient_name: 'فاطمة الترهوني',
        patient_phone: '092-7741900',
        therapist_id: null,
        therapist_name: null,
        service_type: 'assessment',
        service_label: 'زيارة تقييم وكشف أولي',
        specialty_needed: 'تأهيل أعصاب وجلطات ومسنين',
        preferred_gender: 'female',
        district: 'النوفليين',
        address_notes: 'بجوار مسجد القدس، عمارة 3، شقة 8',
        scheduled_label: 'اليوم 17:30 مساءً',
        status: 'pending_review',
        price: 80.0,
        payment_method: 'cash',
        rejection_reason: null,
        clinical_notes: null,
        home_exercises: null,
        patient_rating: null,
        created_at: new Date(Date.now() - 1000 * 60 * 5).toISOString(),
      },
    ],
  };
}

let demoState = getInitialDemoState();

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// -----------------------------------------------------------------------------
// واجهات برمجة التطبيقات (REST Endpoints)
// -----------------------------------------------------------------------------

// 1. جلب إعدادات وطلبات المريض
app.get('/api/patient/bootstrap', async (req, res) => {
  try {
    const patientId = req.query.patientId || '11111111-1111-1111-1111-111111111111';
    if (pgPool) {
      const s = await pgPool.query('SELECT * FROM center_settings WHERE id = 1');
      const o = await pgPool.query(
        `SELECT v.*, u.full_name AS therapist_name
         FROM home_visits v
         LEFT JOIN users u ON v.therapist_id = u.id
         WHERE v.patient_id = $1
         ORDER BY v.created_at DESC`,
        [patientId]
      );
      return res.json({ settings: s.rows[0], orders: o.rows });
    }

    const patientOrders = demoState.visits
      .filter((v) => v.patient_id === patientId)
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

    res.json({
      settings: demoState.settings,
      orders: patientOrders,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 2. إنشاء طلب زيارة جديدة
app.post('/api/visits', async (req, res) => {
  try {
    const body = req.body;
    const order_code = body.order_code || `ORD-${100 + demoState.visits.length + 1}`;
    const newVisit = {
      id: String(Date.now()),
      order_code,
      patient_id: body.patient_id || '11111111-1111-1111-1111-111111111111',
      patient_name: body.patient_name || 'خالد المبروك',
      patient_phone: body.patient_phone || '091-4829104',
      service_type: body.service_type || 'single',
      service_label: body.service_label || 'جلسة علاجية منزلية',
      specialty_needed: body.specialty_needed || 'تأهيل عام',
      preferred_gender: body.preferred_gender || 'any',
      district: body.district || 'طرابلس',
      address_notes: body.address_notes || '',
      scheduled_label: body.scheduled_label || 'في أقرب موعد متاح',
      price: Number(body.price) || 70.0,
      payment_method: body.payment_method || 'cash',
      status: 'pending_review',
      therapist_id: null,
      therapist_name: null,
      rejection_reason: null,
      clinical_notes: null,
      home_exercises: null,
      patient_rating: null,
      created_at: new Date().toISOString(),
    };

    // فحص التوجيه التلقائي
    if (demoState.settings.auto_dispatch) {
      const match = demoState.therapists.find(
        (t) =>
          t.is_online &&
          t.cash_custody_balance < demoState.settings.max_cash_custody_limit &&
          (newVisit.preferred_gender === 'any' || t.gender === newVisit.preferred_gender)
      );
      if (match) {
        newVisit.status = 'dispatched';
        newVisit.therapist_id = match.id;
        newVisit.therapist_name = match.name;
      }
    }

    demoState.visits.unshift(newVisit);
    res.status(201).json(newVisit);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 3. تقييم الزيارة من المريض
app.post('/api/visits/:id/rate', async (req, res) => {
  try {
    const { id } = req.params;
    const { rating } = req.body;
    const v = demoState.visits.find((item) => item.id === id);
    if (v) {
      v.patient_rating = Number(rating);
    }
    res.json({ success: true, visit: v });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 4. جلب بيانات الأدمن
app.get('/api/admin/bootstrap', (req, res) => {
  res.json({
    settings: demoState.settings,
    therapists: demoState.therapists,
    visits: demoState.visits,
  });
});

// 5. توجيه الطلب من الأدمن لأخصائي
app.post('/api/admin/dispatch', (req, res) => {
  try {
    const { order_id, therapist_id } = req.body;
    const v = demoState.visits.find((item) => item.id === String(order_id));
    const t = demoState.therapists.find((item) => item.id === String(therapist_id));
    if (!v) return res.status(404).json({ error: 'Order not found' });

    v.status = 'dispatched';
    v.therapist_id = therapist_id;
    v.therapist_name = t ? t.name : 'أخصائي معتمد';
    v.rejection_reason = null;

    res.json(v);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 6. تصفية العهدة النقدية للأخصائي
app.post('/api/admin/settle-custody', (req, res) => {
  try {
    const { therapist_id } = req.body;
    const t = demoState.therapists.find((item) => item.id === String(therapist_id));
    if (t) {
      t.cash_custody_balance = 0.0;
    }
    res.json({ settled: true, therapist: t });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 7. تحديث إعدادات المركز
app.put('/api/admin/settings', (req, res) => {
  try {
    Object.assign(demoState.settings, req.body);
    res.json(demoState.settings);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 8. جلب بيانات الأخصائي
app.get('/api/therapist/bootstrap', (req, res) => {
  const therapistId = req.query.therapistId || '33333333-3333-3333-3333-333333333331';
  const t = demoState.therapists.find((item) => item.id === therapistId) || demoState.therapists[0];
  const assignedVisits = demoState.visits.filter((v) => v.therapist_id === t.id);
  res.json({
    therapist: t,
    settings: demoState.settings,
    visits: assignedVisits,
  });
});

// 9. تغيير حالة الأخصائي (متصل / غير متصل)
app.patch('/api/therapists/:id/status', (req, res) => {
  try {
    const { id } = req.params;
    const { is_online } = req.body;
    const t = demoState.therapists.find((item) => item.id === id);
    if (t) {
      t.is_online = Boolean(is_online);
    }
    res.json({ success: true, therapist: t });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 10. تحديث حالة الزيارة (قبول / تحرك / وصول)
app.patch('/api/visits/:id/status', (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const v = demoState.visits.find((item) => item.id === String(id));
    if (!v) return res.status(404).json({ error: 'Visit not found' });
    v.status = status;
    res.json(v);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 11. اعتذار الأخصائي عن المهمة
app.post('/api/visits/:id/reject', (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const v = demoState.visits.find((item) => item.id === String(id));
    if (!v) return res.status(404).json({ error: 'Visit not found' });
    v.status = 'pending_review';
    v.therapist_id = null;
    v.therapist_name = null;
    v.rejection_reason = reason || 'اعتذر الأخصائي عن المهمة لظرف طارئ';
    res.json(v);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 12. إنهاء الجلسة وإدخال التقرير الطبي وتحديث العهدة النقدية
app.post('/api/visits/:id/complete', (req, res) => {
  try {
    const { id } = req.params;
    const { therapist_id, clinical_notes, home_exercises } = req.body;
    const v = demoState.visits.find((item) => item.id === String(id));
    if (!v) return res.status(404).json({ error: 'Visit not found' });

    v.status = 'completed';
    v.clinical_notes = clinical_notes || 'جلسة علاجية اعتيادية ومتابعة التمارين';
    v.home_exercises = home_exercises || 'الالتزام بتمارين الإطالة والتقوية يومياً';
    v.completed_at = new Date().toISOString();

    const t = demoState.therapists.find((item) => item.id === (therapist_id || v.therapist_id));
    if (t && v.payment_method === 'cash') {
      t.cash_custody_balance += Number(v.price) || 70.0;
      t.total_earned += Number(v.price) || 70.0;
      t.completed_sessions_count += 1;
    }

    res.json(v);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 13. جلب الحالة الكاملة للمحاكي التفاعلي المباشر (Multi-App Live Sync)
app.get('/api/all-state', (req, res) => {
  res.json(demoState);
});

// 14. إعادة ضبط المحاكي للحالة الافتراضية
app.post('/api/reset-demo', (req, res) => {
  demoState = getInitialDemoState();
  res.json({ message: 'Demo state reset successfully', state: demoState });
});

// تشغيل الخادم
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`=============================================================`);
  console.log(`🏥 Physio Home Care Suite Server is RUNNING on port ${PORT}`);
  console.log(`📱 Live Interactive Demo: http://localhost:${PORT}`);
  console.log(`📡 REST API Endpoint:    http://localhost:${PORT}/api`);
  console.log(`=============================================================`);
});
