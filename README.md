# Makaan Flutter Project — Phase 9

مشروع Flutter محدث حتى المرحلة التاسعة، ويشمل جميع مزايا المراحل السابقة: الطلبات، الإعلانات، البحث، التصنيفات، المفضلة، ولوحة الإدارة، مع طبقة Backend Integration قابلة للتفعيل عبر Supabase.

## التشغيل المحلي
يعمل التطبيق بدون مفاتيح Backend باستخدام التخزين المحلي، وذلك للحفاظ على قابلية الاختبار وعدم كسر المراحل السابقة.

```bash
flutter pub get
flutter run
```

## التشغيل مع Supabase
نفّذ أولًا ملف قاعدة البيانات:

```text
../database/backend_phase9_schema.sql
```

ثم شغّل التطبيق بالمفاتيح:

```bash
flutter run \
  --dart-define=MAKAAN_SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=MAKAAN_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY \
  --dart-define=MAKAAN_SUPABASE_STORAGE_BUCKET=makaan-media
```

## ملفات الربط السحابي
- `lib/shared/backend/backend_config.dart`
- `lib/shared/backend/supabase_backend_client.dart`
- `lib/shared/backend/cloud_storage_service.dart`
- `lib/shared/backend/push_notification_service.dart`

## ملاحظات
لا يتم تضمين مفاتيح Supabase/FCM داخل المشروع. ضع القيم الحقيقية أثناء التشغيل فقط.


## Phase 11 QA notes

Run the following before release:

```bash
flutter pub get
flutter analyze
flutter test
```

For remote admin access, pass `--dart-define=MAKAAN_SUPER_ADMIN_PHONE=+9677XXXXXXXX` together with Supabase runtime defines.

## Phase 12 - Production Release

تم تجهيز المشروع للإطلاق الإنتاجي عبر Firebase باستخدام ملف `google-services.json` المرفق. راجع:

- `docs/24_phase12_production_release.md`
- `flutter_project/RELEASE.md`
- `database/firebase_phase12_firestore_rules.rules`
- `database/firebase_phase12_storage_rules.rules`

الإصدار الحالي: `1.0.0+1`.

