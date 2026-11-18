-- =============================================================================
-- منظومة الرعاية المنزلية للعلاج الطبيعي - قاعدة بيانات Neon PostgreSQL الكاملة
-- طريقة التشغيل: انسخ هذا الكود بالكامل والصقه في SQL Editor داخل لوحة تحكم Neon
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. جدول إعدادات المركز المرنة (يتحكم في سلوك التطبيقات الثلاثة بدون إعادة برمجة)
CREATE TABLE IF NOT EXISTS center_settings (
    id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    center_name VARCHAR(120) NOT NULL DEFAULT 'مركز الشفاء للعلاج الطبيعي المنزلي',
    primary_color_hex VARCHAR(10) NOT NULL DEFAULT '#0D9488',
    support_phone VARCHAR(30) NOT NULL DEFAULT '091-0000000',
    allow_therapist_reject BOOLEAN NOT NULL DEFAULT TRUE,
    auto_dispatch BOOLEAN NOT NULL DEFAULT FALSE,
    show_patient_phone BOOLEAN NOT NULL DEFAULT FALSE,
    center_commission_pct NUMERIC(5,2) NOT NULL DEFAULT 40.00,
    single_session_price NUMERIC(10,2) NOT NULL DEFAULT 70.00,
    assessment_price NUMERIC(10,2) NOT NULL DEFAULT 80.00,
    package_6_price NUMERIC(10,2) NOT NULL DEFAULT 360.00,
    max_cash_custody_limit NUMERIC(10,2) NOT NULL DEFAULT 1000.00,
    accept_timeout_seconds INT NOT NULL DEFAULT 180,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. جدول المستخدمين الموحد (المرضى، الأدمن، الأخصائيين)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(25) UNIQUE NOT NULL,
    password_hash TEXT,
    role VARCHAR(20) NOT NULL CHECK (role IN ('patient', 'admin', 'therapist')),
    gender VARCHAR(10) NOT NULL DEFAULT 'male' CHECK (gender IN ('male', 'female')),
    age INT,
    fcm_token TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. جدول الملفات المهنية والمالية للأخصائيين
CREATE TABLE IF NOT EXISTS therapist_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    specialty VARCHAR(100) NOT NULL,
    coverage_district VARCHAR(100) NOT NULL,
    is_online BOOLEAN NOT NULL DEFAULT FALSE,
    last_lat DOUBLE PRECISION DEFAULT 32.8872,
    last_lng DOUBLE PRECISION DEFAULT 13.1913,
    cash_custody_balance NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    total_earned NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    completed_sessions_count INT NOT NULL DEFAULT 0,
    rating NUMERIC(3,2) NOT NULL DEFAULT 5.00,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. جدول الباقات العلاجية للمرضى (مثلاً باقة 6 أو 12 جلسة)
CREATE TABLE IF NOT EXISTS patient_packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_therapist_id UUID REFERENCES users(id) ON DELETE SET NULL,
    package_title VARCHAR(120) NOT NULL,
    specialty VARCHAR(100) NOT NULL,
    total_sessions INT NOT NULL DEFAULT 6,
    remaining_sessions INT NOT NULL DEFAULT 6,
    preferred_days VARCHAR(120) NOT NULL DEFAULT 'السبت - الإثنين - الأربعاء (5:00 م)',
    total_price NUMERIC(10,2) NOT NULL DEFAULT 360.00,
    is_paid BOOLEAN NOT NULL DEFAULT TRUE,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. جدول طلبات الزيارات والجلسات المنزلية (الجدول المحوري لدورة العمل)
CREATE TABLE IF NOT EXISTS home_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_code VARCHAR(20) UNIQUE NOT NULL,
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    patient_name_snapshot VARCHAR(100) NOT NULL,
    patient_phone_snapshot VARCHAR(25) NOT NULL,
    therapist_id UUID REFERENCES users(id) ON DELETE SET NULL,
    package_id UUID REFERENCES patient_packages(id) ON DELETE SET NULL,
    service_type VARCHAR(40) NOT NULL CHECK (service_type IN ('single', 'assessment', 'package_new', 'package_use')),
    service_label VARCHAR(100) NOT NULL,
    specialty_needed VARCHAR(100) NOT NULL,
    preferred_gender VARCHAR(15) NOT NULL DEFAULT 'any' CHECK (preferred_gender IN ('male', 'female', 'any')),
    district VARCHAR(80) NOT NULL,
    address_notes TEXT NOT NULL,
    patient_lat DOUBLE PRECISION DEFAULT 32.8750,
    patient_lng DOUBLE PRECISION DEFAULT 13.1500,
    scheduled_label VARCHAR(80) NOT NULL,
    status VARCHAR(25) NOT NULL DEFAULT 'pending_review'
        CHECK (status IN ('pending_review', 'dispatched', 'accepted', 'en_route', 'in_session', 'completed', 'cancelled')),
    price NUMERIC(10,2) NOT NULL DEFAULT 70.00,
    payment_method VARCHAR(20) NOT NULL DEFAULT 'cash' CHECK (payment_method IN ('cash', 'package', 'electronic')),
    rejection_reason TEXT,
    clinical_notes TEXT,
    home_exercises TEXT,
    patient_rating INT CHECK (patient_rating BETWEEN 1 AND 5),
    checkin_lat DOUBLE PRECISION,
    checkin_lng DOUBLE PRECISION,
    dispatched_at TIMESTAMPTZ,
    accepted_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. جدول تسويات العهدة المالية بين الأخصائيين والمركز
CREATE TABLE IF NOT EXISTS cash_settlements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    therapist_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    received_by_admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
    total_custody_settled NUMERIC(10,2) NOT NULL,
    center_share_amount NUMERIC(10,2) NOT NULL,
    therapist_net_amount NUMERIC(10,2) NOT NULL,
    notes TEXT,
    settled_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- فهارس لتسريع الاستعلامات اللحظية
CREATE INDEX IF NOT EXISTS idx_home_visits_status ON home_visits(status);
CREATE INDEX IF NOT EXISTS idx_home_visits_therapist ON home_visits(therapist_id, status);
CREATE INDEX IF NOT EXISTS idx_home_visits_patient ON home_visits(patient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_therapist_online ON therapist_profiles(is_online);

-- إدخال الإعدادات الافتراضية للمركز
INSERT INTO center_settings (
    id, center_name, primary_color_hex, support_phone,
    allow_therapist_reject, auto_dispatch, show_patient_phone,
    center_commission_pct, single_session_price, assessment_price,
    package_6_price, max_cash_custody_limit
) VALUES (
    1, 'مركز الشفاء للعلاج الطبيعي المنزلي', '#0D9488', '091-0000000',
    TRUE, FALSE, FALSE, 40.00, 70.00, 80.00, 360.00, 1000.00
) ON CONFLICT (id) DO NOTHING;

-- بيانات أولية للتجربة الفورية (مريض + أدمن + أخصائيين)
INSERT INTO users (id, full_name, phone, role, gender, age) VALUES
    ('11111111-1111-1111-1111-111111111111', 'خالد المبروك', '091-4829104', 'patient', 'male', 54),
    ('22222222-2222-2222-2222-222222222222', 'موظف استقبال المركز', '091-1112233', 'admin', 'male', 30),
    ('33333333-3333-3333-3333-333333333331', 'د. أحمد السنوسي', '092-5112030', 'therapist', 'male', 34),
    ('33333333-3333-3333-3333-333333333332', 'د. سارة الفيتوري', '091-6093312', 'therapist', 'female', 29),
    ('33333333-3333-3333-3333-333333333333', 'د. محمد الورفلي', '094-3901122', 'therapist', 'male', 37)
ON CONFLICT (phone) DO NOTHING;

INSERT INTO therapist_profiles (
    user_id, specialty, coverage_district, is_online,
    cash_custody_balance, total_earned, completed_sessions_count, rating
) VALUES
    ('33333333-3333-3333-3333-333333333331', 'تأهيل عظام وكسور وإصابات ملاعب', 'حي الأندلس / قرقارش', TRUE, 280.00, 1680.00, 42, 4.90),
    ('33333333-3333-3333-3333-333333333332', 'تأهيل أعصاب وجلطات ومسنين', 'النوفليين / زاوية الدهماني', TRUE, 420.00, 2310.00, 58, 4.95),
    ('33333333-3333-3333-3333-333333333333', 'تأهيل عمود فقري وأطفال', 'سوق الجمعة / عين زارة', FALSE, 140.00, 1120.00, 31, 4.80)
ON CONFLICT (user_id) DO NOTHING;
