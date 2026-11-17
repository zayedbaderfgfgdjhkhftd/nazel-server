<p align="center"><img src="assets/brand/play-store-512.png" width="96" alt=""></p>

# سَطر — Satr PDF

أدوات PDF وصور **عربية أولًا**، تعمل **بالكامل على جهازك**: بدون حساب، بدون رفع ملفات، وبدون إنترنت.
تطبيق أندرويد مبني بـ **Flutter و Dart**، وجاهز لإعلانات **AdMob** مستقبلًا (مطفأة الآن).

Arabic-first PDF & image tools that run **entirely on the device** — no account, no uploads, no internet.
Native Android app built with **Flutter/Dart**; AdMob-ready (ads are off).

---

## الأدوات
دمج · تقسيم · استخراج صفحات · ترتيب الصفحات · ضغط (3 مستويات) · PDF إلى صور · صور إلى PDF (مع HEIC) · علامة مائية · أرقام الصفحات · توقيع مرسوم · استخراج النص · النص من الصورة OCR (عربي/إنجليزي → TXT/DOCX) · معلومات الملف · عارض PDF · ملفاتي وسلة المحذوفات · استقبال الملفات من التطبيقات الأخرى.

التفاصيل والقيود بصدق: [`FEATURES.md`](FEATURES.md) · نتائج الاختبارات الحقيقية: [`TESTING.md`](TESTING.md)

## تنزيل APK للتجربة
- **رابط مباشر (أحدث نسخة):** فرع `satr-pdf-download` ← `Satr-PDF-arm64.apk` (لأغلب الهواتف) أو `Satr-PDF-armv7.apk` (للهواتف القديمة).
- أو: كل رفع للمستودع يبني التطبيق على GitHub تلقائيًا: **Actions ← آخر تشغيل ← Artifacts ← `satr-pdf-apk`**. التفاصيل في [`DEPLOYMENT.md`](DEPLOYMENT.md).

## التشغيل والبناء (للمطوّرين)
المتطلبات: Flutter 3.50 (Dart 3.14)، Android SDK (platform 36، NDK 28.2)، JDK 21.
```bash
flutter pub get
flutter run                      # على هاتف أو محاكي أندرويد
flutter test                     # كل الاختبارات (تحتاج tesseract-ocr لاختبار OCR)
flutter build apk --release      # APK للتجربة
flutter build appbundle --release   # AAB لـ Google Play
```
تغيير اسم التطبيق: `lib/config/app_config.dart` و `android/app/src/main/res/values*/strings.xml`.

## هيكل المشروع
```
lib/
  app/ config/ design/ components/ ads/ l10n/
  core/   pdf · image · arabic · render · ocr · docx · jobs · storage · share · platform
  features/<tool>/  <tool>_tool.dart (منطق نقي قابل للاختبار) + <tool>_screen.dart (الواجهة)
android/            إعدادات أندرويد + MainActivity.kt (المشاركة، الذاكرة، المساحة)
assets/             الخط Readex Pro، نماذج OCR، الأيقونات
test/               اختبارات الوحدات والواجهة + ملفات الاختبار (fixtures)
tool/               سكربتات توليد الملفات والأيقونات، تدقيق التراخيص، تفعيل AdMob
store/  docs/       نصوص المتجر وصفحة الخصوصية (GitHub Pages)
```
المعمارية: [`ARCHITECTURE.md`](ARCHITECTURE.md) · الخطة: [`PLAN.md`](PLAN.md)

## الخصوصية والتراخيص والإعلانات
- [`PRIVACY.md`](PRIVACY.md) — الملفات لا تغادر الجهاز، ونسخة الإصدار بلا صلاحية إنترنت.
- [`LICENSES.md`](LICENSES.md) — كل المكتبات برخص متساهلة (MIT / Apache-2.0 / BSD / ISC / OFL)، بلا GPL/AGPL.
- [`ADS.md`](ADS.md) — تفعيل AdMob بسكربت واحد عند الحاجة.
- [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) — قبل كل إصدار.
