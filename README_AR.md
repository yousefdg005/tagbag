# الدليل الكامل لتشغيل وبناء منظومة العلاج الطبيعي المنزلي (3 تطبيقات أندرويد + Neon)

يحتوي هذا المشروع على الأكواد الكاملة الجاهزة للتشغيل والاستخراج (APK) للبرامج الثلاثة:
1. **`lib/main_patient.dart`**: تطبيق المريض (طلب زيارة، متابعة المراحل الـ 6، الباقات والتمارين المنزلية).
2. **`lib/main_admin.dart`**: تطبيق الأدمن - موظف المركز (استلام الطلبات، التوجيه للأخصائيين المتاحين، تصفية العهدة المالية، وتخصيص النظام الفوري).
3. **`lib/main_therapist.dart`**: تطبيق الأخصائي (تفعيل حالة Online/Offline، قبول/رفض الطلبات، تسجيل الوصول الجغرافي، كتابة التقرير الطبي، ومتابعة المحفظة).

---

## الخطوة 1: إعداد قاعدة البيانات المجانية على Neon
1. افتح حسابك المجاني في [Neon](https://neon.com) وأنشئ مشروعاً جديداً باسم `physio-center-db`.
2. من القائمة الجانبية افتح **SQL Editor**.
3. انسخ محتويات ملف `database/neon_schema.sql` بالكامل والصقه في المحرر واضغط **Run**.
4. انسخ رابط الاتصال (`Connection String`) من لوحة تحكم Neon.

## الخطوة 2: تشغيل الخادم الخلفي (Node.js API)
داخل مجلد `backend_nodejs`:
```bash
cd backend_nodejs
npm install
export DATABASE_URL="postgresql://user:pass@ep-xyz.neon.tech/neondb?sslmode=require"
npm start
```

## الخطوة 3: استخراج ملفات الأندرويد الثلاثة (APK) عبر Flutter
في المجلد الرئيسي للمشروع:
```bash
flutter pub get

# 1. استخراج ملف APK لتطبيق المريض:
flutter build apk -t lib/main_patient.dart --dart-define=API_BASE_URL=https://your-api-url.com/api

# 2. استخراج ملف APK لتطبيق الأدمن (موظف المركز):
flutter build apk -t lib/main_admin.dart --dart-define=API_BASE_URL=https://your-api-url.com/api

# 3. استخراج ملف APK لتطبيق الأخصائي:
flutter build apk -t lib/main_therapist.dart --dart-define=API_BASE_URL=https://your-api-url.com/api

# 4. (اختياري) استخراج نسخة ويب لكمبيوتر موظف الاستقبال في المركز:
flutter build web -t lib/main_admin.dart --dart-define=API_BASE_URL=https://your-api-url.com/api
```
