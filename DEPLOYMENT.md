# النشر — من GitHub إلى Google Play

> هذا التطبيق أندرويد أصلي مبني بـ Flutter، لذلك لا يحتاج استضافة ويب ولا Bubblewrap/TWA (تلك كانت لنسخة PWA في البرومبت الأصلي). كل شيء مجاني ما عدا رسوم حساب مطوّر Google Play لمرة واحدة.

## 1) البناء السحابي على GitHub (بدون أي تثبيت على جهازك)
عند كل رفع (push) إلى المستودع يعمل ملف `.github/workflows/build.yml` تلقائيًا:
1. `flutter analyze` و `flutter test` (كل الاختبارات).
2. بناء `app-release.apk` (لكل المعالجات) وملفات APK منفصلة (arm64 / armv7) وملف `app-release.aab` لـ Google Play.

**لتنزيل ملف APK للتجربة:** افتح المستودع على GitHub ← تبويب **Actions** ← آخر تشغيل ناجح ← في أسفل الصفحة قسم **Artifacts** ← `satr-pdf-apk`. فكّ الضغط وثبّت `app-arm64-v8a-release.apk` على أغلب الهواتف الحديثة (فعّل «التثبيت من مصادر غير معروفة»).

> بدون مفتاح توقيع (الخطوة 2) تُوقَّع الملفات بمفتاح تجريبي: صالحة للتجربة على هاتفك، **وغير مقبولة** في Google Play.

## 2) مفتاح التوقيع (Upload key) — مهم جدًا
أنشئه مرة واحدة على جهاز تثق به (يحتاج Java):
```bash
keytool -genkeypair -v -keystore satr-upload.jks -keyalg RSA -keysize 4096 -validity 10000 -alias upload
```
**النسخ الاحتياطي إلزامي:** احفظ `satr-upload.jks` وكلمتي المرور في مكانين آمنين على الأقل (مثل مدير كلمات مرور + وحدة تخزين خارجية مشفّرة). ضياع المفتاح يعني أنك تحتاج طلب «إعادة تعيين مفتاح الرفع» من Google، وبدون «App signing by Google Play» قد لا تستطيع تحديث التطبيق أبدًا. **لا ترفع المفتاح إلى GitHub أبدًا** (ملفات `*.jks` و `key.properties` مستثناة في `.gitignore`).

### للبناء السحابي الموقّع
في المستودع: **Settings ← Secrets and variables ← Actions ← New repository secret** وأضف:
| الاسم | القيمة |
|---|---|
| `SATR_KEYSTORE_BASE64` | محتوى `base64 -w0 satr-upload.jks` |
| `SATR_KEYSTORE_PASSWORD` | كلمة مرور المخزن |
| `SATR_KEY_ALIAS` | `upload` |
| `SATR_KEY_PASSWORD` | كلمة مرور المفتاح |

### للبناء المحلي الموقّع (اختياري)
أنشئ `android/key.properties`:
```
storeFile=/المسار/الكامل/satr-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```
ثم:
```bash
flutter build appbundle --release
```

## 3) Google Play Console
1. أنشئ حساب مطوّر (رسوم لمرة واحدة) على https://play.google.com/console
2. **Create app**: الاسم «سطر - أدوات PDF» (أو Satr PDF)، اللغة الافتراضية العربية، تطبيق، مجاني.
3. **App signing**: اختر «Use Google Play app signing» (موصى به) وارفع ملف `app-release.aab` الموقّع بمفتاح الرفع.
4. **App content**:
   - Privacy policy: رابط صفحة الخصوصية (الخطوة 4).
   - Ads: **No** (الإعلانات مطفأة).
   - Data safety: «لا يجمع ولا يشارك أي بيانات»؛ البيانات تبقى على الجهاز. (التطبيق لا يملك صلاحية الإنترنت.)
   - Content rating: استبيان IARC (أداة إنتاجية، لا محتوى حساس).
   - Target audience: 18+ أو 13+ حسب رغبتك (ليس موجّهًا للأطفال).
5. **صفحة المتجر**: النصوص جاهزة في `store/listing_ar.md` و `store/listing_en.md`، وصورة العرض 1024×500 في `store/feature_graphic.png`، والأيقونة 512×512 في `assets/brand/play-store-512.png`، ولقطات الشاشة في `store/screenshots/`.
6. **اختبار مغلق إلزامي للحسابات الشخصية الجديدة:** Google تشترط اختبارًا مغلقًا (Closed testing) مع **12 مختبِرًا على الأقل** مشتركين **لمدة 14 يومًا متواصلة** قبل السماح بطلب النشر للإنتاج. أنشئ مسار Closed testing، أضف قائمة بريد المختبرين، شارك رابط الانضمام، وانتظر 14 يومًا ثم قدّم طلب «Apply for production».
7. بعد الموافقة: Production ← Create release ← ارفع الـ AAB ← Review ← Rollout.

## 4) صفحة سياسة الخصوصية (مجانًا عبر GitHub Pages)
الملف `docs/index.html` يحتوي سياسة الخصوصية بالعربي والإنجليزي.
في المستودع: **Settings ← Pages ← Source: Deploy from a branch ← Branch: `main` / folder `/docs`**. سيصبح الرابط:
`https://<اسم-المستخدم>.github.io/<اسم-المستودع>/`

## 5) تحديث الإصدار
ارفع رقم الإصدار في `pubspec.yaml` (`version: 1.0.1+2`، الرقم بعد + يجب أن يزيد دائمًا) وفي `lib/config/app_config.dart`، ثم ابنِ AAB جديدًا وارفعه.

## 6) البناء على جهازك (اختياري)
يلزم Flutter 3.50 و Android SDK و JDK 17:
```bash
flutter pub get
flutter test
flutter build apk --release
```
