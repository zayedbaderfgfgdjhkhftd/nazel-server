// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navTools => 'الأدوات';

  @override
  String get navFiles => 'ملفاتي';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingAfternoon => 'نهارك سعيد';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String get homePickTitle => 'اختر ملفًا';

  @override
  String get homePickSubtitle => 'ملف PDF أو صورة من جهازك';

  @override
  String get homeQuickActions => 'اختصارات سريعة';

  @override
  String get homeRecent => 'آخر الملفات';

  @override
  String get homeSeeAll => 'عرض الكل';

  @override
  String get homeEmptyRecent => 'ستظهر هنا الملفات التي تنشئها.';

  @override
  String get privacyLine => 'ملفاتك تبقى على جهازك';

  @override
  String get toolsTitle => 'الأدوات';

  @override
  String get groupOrganize => 'تنظيم';

  @override
  String get groupConvert => 'تحويل';

  @override
  String get groupEdit => 'تعديل';

  @override
  String get groupText => 'نصوص';

  @override
  String get groupOptimize => 'تحسين';

  @override
  String get toolMerge => 'دمج ملفات PDF';

  @override
  String get toolMergeDesc => 'اجمع عدة ملفات في ملف واحد';

  @override
  String get toolSplit => 'تقسيم ملف PDF';

  @override
  String get toolSplitDesc => 'قسّم الملف حسب نطاق الصفحات أو كل عدد منها';

  @override
  String get toolExtract => 'استخراج صفحات';

  @override
  String get toolExtractDesc => 'اختر صفحات واحفظها في ملف جديد';

  @override
  String get toolOrganize => 'ترتيب الصفحات';

  @override
  String get toolOrganizeDesc => 'رتّب الصفحات ودوّرها واحذفها أو كرّرها';

  @override
  String get toolCompress => 'ضغط ملف PDF';

  @override
  String get toolCompressDesc => 'صغّر حجم الملف';

  @override
  String get toolPdfToImages => 'PDF إلى صور';

  @override
  String get toolPdfToImagesDesc => 'احفظ الصفحات صورًا بصيغة JPG أو PNG';

  @override
  String get toolImagesToPdf => 'صور إلى PDF';

  @override
  String get toolImagesToPdfDesc =>
      'حوّل الصور والمستندات المصوّرة إلى ملف PDF';

  @override
  String get toolWatermark => 'علامة مائية';

  @override
  String get toolWatermarkDesc => 'أضف نصًا أو صورة فوق الصفحات';

  @override
  String get toolPageNumbers => 'أرقام الصفحات';

  @override
  String get toolPageNumbersDesc => 'رقّم صفحات الملف';

  @override
  String get toolSignature => 'توقيع مرسوم';

  @override
  String get toolSignatureDesc => 'ارسم توقيعك أو ارفع صورته وضعه على الصفحة';

  @override
  String get toolTextExtract => 'استخراج النص';

  @override
  String get toolTextExtractDesc => 'انسخ النص الموجود داخل ملف PDF';

  @override
  String get toolOcr => 'النص من الصورة (OCR)';

  @override
  String get toolOcrDesc => 'اقرأ النص العربي والإنجليزي من الصور';

  @override
  String get toolFileInfo => 'معلومات الملف';

  @override
  String get toolFileInfoDesc => 'عدد الصفحات والحجم والبيانات الوصفية';

  @override
  String get toolImported => 'مستورد';

  @override
  String get toolShared => 'تمت مشاركته مع التطبيق';

  @override
  String get pickPdf => 'اختر ملف PDF';

  @override
  String get pickPdfs => 'اختر ملفات PDF';

  @override
  String get pickImages => 'اختر صورًا';

  @override
  String get pickImageOrPdf => 'اختر صورة أو ملف PDF';

  @override
  String get pickImage => 'اختر صورة';

  @override
  String get fromDevice => 'من الجهاز';

  @override
  String get fromMyFiles => 'من ملفاتي';

  @override
  String get addMore => 'أضف المزيد';

  @override
  String get remove => 'إزالة';

  @override
  String get change => 'تغيير';

  @override
  String get cancel => 'إلغاء';

  @override
  String get ok => 'حسنًا';

  @override
  String get close => 'إغلاق';

  @override
  String get back => 'رجوع';

  @override
  String get done => 'تم';

  @override
  String get retry => 'حاول مجددًا';

  @override
  String get continueAnyway => 'متابعة';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get none => '—';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get working => 'جارٍ العمل…';

  @override
  String progressPage(int current, int total) {
    return 'صفحة $current من $total';
  }

  @override
  String progressFile(int current, int total) {
    return 'ملف $current من $total';
  }

  @override
  String get progressVerifying => 'جارٍ التحقق من النتيجة…';

  @override
  String get progressPreparingOcr => 'جارٍ تجهيز بيانات اللغة…';

  @override
  String get progressReadingText => 'جارٍ قراءة النص…';

  @override
  String get cancelled => 'أُلغيت العملية، ولم يُنشأ أي ملف.';

  @override
  String get resultTitle => 'تم بنجاح';

  @override
  String get resultSaved => 'حُفظ في ملفاتي';

  @override
  String get open => 'فتح';

  @override
  String get share => 'مشاركة';

  @override
  String get save => 'حفظ';

  @override
  String get saveToDevice => 'حفظ على الجهاز';

  @override
  String get savedToDevice => 'تم الحفظ';

  @override
  String get useAnotherTool => 'استخدم أداة أخرى';

  @override
  String pagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صفحة',
      many: '$count صفحة',
      few: '$count صفحات',
      two: 'صفحتان',
      one: 'صفحة واحدة',
      zero: 'لا توجد صفحات',
    );
    return '$_temp0';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملف',
      many: '$count ملفًا',
      few: '$count ملفات',
      two: 'ملفان',
      one: 'ملف واحد',
      zero: 'لا توجد ملفات',
    );
    return '$_temp0';
  }

  @override
  String imagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صورة',
      many: '$count صورة',
      few: '$count صور',
      two: 'صورتان',
      one: 'صورة واحدة',
      zero: 'لا توجد صور',
    );
    return '$_temp0';
  }

  @override
  String get sizeLabel => 'الحجم';

  @override
  String get errCorrupt => 'الملف تالف أو غير مدعوم.';

  @override
  String get errEncrypted =>
      'هذا الملف محمي بكلمة مرور. يمكنك عرضه، لكن أدوات التعديل لا تعالج الملفات المحمية في هذا الإصدار.';

  @override
  String get errUnsupportedType => 'نوع هذا الملف غير مدعوم هنا.';

  @override
  String get errNotPdf => 'اختر ملف PDF من فضلك.';

  @override
  String get errNotImage => 'اختر صورة بصيغة JPG أو PNG أو WebP أو HEIC.';

  @override
  String get errHeic =>
      'لا يستطيع هذا الجهاز قراءة صور HEIC، ويلزم Android 9 أو أحدث.';

  @override
  String get errEmptyFile => 'الملف فارغ.';

  @override
  String get errOutputInvalid =>
      'حدث خطأ: لم يجتز الملف الناتج التحقق، لذلك لم يُحفظ.';

  @override
  String get errOcr => 'تعذّرت قراءة النص من هذه الصورة.';

  @override
  String get errNothingSelected => 'اختر ما تريد العمل عليه أولًا.';

  @override
  String get errGeneric => 'حدث خطأ. حاول مرة أخرى.';

  @override
  String get largeFileTitle => 'ملف كبير';

  @override
  String largeFileBody(String size) {
    return 'حجم هذا الملف $size. قد تكون معالجة الملفات الكبيرة بطيئة أو تفشل على هذا الجهاز. هل تريد المتابعة؟';
  }

  @override
  String get mergeHint => 'اسحب الملفات لترتيبها، والملف الأعلى يأتي أولًا.';

  @override
  String get mergeNeedTwo => 'أضف ملفين على الأقل.';

  @override
  String get mergeAction => 'ادمج الملفات';

  @override
  String get splitModeRanges => 'حسب نطاق الصفحات';

  @override
  String get splitModeEvery => 'كل عدد من الصفحات';

  @override
  String get splitModeEach => 'كل صفحة في ملف';

  @override
  String get splitRangesLabel => 'نطاق الصفحات';

  @override
  String get splitRangesHint => 'مثال: 1-3، 5، 8-10';

  @override
  String get splitRangesHelp => 'كل نطاق يصبح ملفًا مستقلًا.';

  @override
  String get splitEveryLabel => 'عدد الصفحات في كل ملف';

  @override
  String get splitZipNote =>
      'إذا نتج أكثر من ملف فستُجمع كلها في ملف ZIP واحد.';

  @override
  String get splitAction => 'قسّم الملف';

  @override
  String get rangeErrSyntax => 'تحقق من الصيغة، مثل: 1-3، 5';

  @override
  String rangeErrOutOfBounds(int max) {
    return 'يجب أن تكون الصفحات بين 1 و$max.';
  }

  @override
  String get rangeErrEmpty => 'أدخل صفحة واحدة على الأقل.';

  @override
  String get rangeErrReversed => 'ابدأ النطاق بالصفحة الأصغر ثم الأكبر.';

  @override
  String get extractHint => 'اضغط على الصفحات لتحديدها.';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get selectNone => 'إلغاء التحديد';

  @override
  String selectedCount(int count) {
    return 'المحدد: $count';
  }

  @override
  String get extractNeedOne => 'حدّد صفحة واحدة على الأقل.';

  @override
  String get extractAction => 'استخرج الصفحات';

  @override
  String get organizeHint => 'اضغط مطولًا على الصفحة واسحبها لتغيير مكانها.';

  @override
  String get rotateLeft => 'تدوير لليسار';

  @override
  String get rotateRight => 'تدوير لليمين';

  @override
  String get duplicate => 'تكرار';

  @override
  String get delete => 'حذف';

  @override
  String get insertBlank => 'أضف صفحة فارغة';

  @override
  String get blankA4 => 'A4';

  @override
  String get blankLetter => 'Letter';

  @override
  String get blankSameSize => 'بمقاس هذه الصفحة';

  @override
  String get blankPage => 'صفحة فارغة';

  @override
  String pageN(int n) {
    return 'صفحة $n';
  }

  @override
  String get organizeNeedOne => 'أبقِ صفحة واحدة على الأقل.';

  @override
  String get organizeAction => 'احفظ التعديلات';

  @override
  String get reset => 'إعادة ضبط';

  @override
  String get compressLight => 'خفيف';

  @override
  String get compressLightDesc =>
      'تنظيف بلا فقدان في الجودة، ويبقى النص قابلًا للتحديد.';

  @override
  String get compressRecommended => 'مُوصى به';

  @override
  String get compressRecommendedDesc =>
      'يعيد حفظ الصور الكبيرة بجودة أقل، ويبقى النص قابلًا للتحديد.';

  @override
  String get compressStrong => 'قوي';

  @override
  String get compressStrongDesc => 'يحوّل كل صفحة إلى صورة، وهو الأصغر حجمًا.';

  @override
  String get compressStrongWarning =>
      'بعد الضغط القوي لن تستطيع تحديد النص أو نسخه أو البحث فيه.';

  @override
  String get compressDpi => 'دقة صور الصفحات';

  @override
  String dpiValue(int dpi) {
    return '$dpi نقطة/بوصة';
  }

  @override
  String get compressAction => 'اضغط الملف';

  @override
  String compressResult(String before, String after) {
    return 'من $before إلى $after';
  }

  @override
  String compressSaved(String percent) {
    return 'وفّرت $percent٪';
  }

  @override
  String compressNotSmaller(String before, String after) {
    return 'لم يكن الناتج أصغر من الأصل ($after مقابل $before)، لذلك احتفظنا بملفك الأصلي ولم نحفظ نسخة جديدة.';
  }

  @override
  String get compressFellBack =>
      'لا يحتوي الملف على صور يمكن تصغيرها بأمان، لذلك استخدمنا الضغط الخفيف.';

  @override
  String compressImagesRecoded(int count) {
    return 'عدد الصور المعاد حفظها: $count';
  }

  @override
  String get originalSize => 'الأصلي';

  @override
  String get newSize => 'الجديد';

  @override
  String get formatLabel => 'الصيغة';

  @override
  String get resolutionLabel => 'الدقة';

  @override
  String get pagesLabel => 'الصفحات';

  @override
  String get allPages => 'كل الصفحات';

  @override
  String get onePage => 'صفحة واحدة';

  @override
  String get pageNumberLabel => 'رقم الصفحة';

  @override
  String get dpiScreen => '72 · للشاشة';

  @override
  String get dpiStandard => '150 · عادية';

  @override
  String get dpiPrint => '300 · للطباعة';

  @override
  String get convertAction => 'حوّل الملف';

  @override
  String get pageSizeLabel => 'مقاس الصفحة';

  @override
  String get pageSizeA4 => 'A4';

  @override
  String get pageSizeLetter => 'Letter';

  @override
  String get pageSizeFit => 'بحجم الصورة';

  @override
  String get orientationLabel => 'الاتجاه';

  @override
  String get orientationAuto => 'تلقائي';

  @override
  String get orientationPortrait => 'طولي';

  @override
  String get orientationLandscape => 'عرضي';

  @override
  String get marginsLabel => 'الهوامش';

  @override
  String get marginNone => 'بدون';

  @override
  String get marginSmall => 'صغيرة';

  @override
  String get marginLarge => 'كبيرة';

  @override
  String get fitLabel => 'ملاءمة الصورة';

  @override
  String get fitContain => 'احتواء كامل';

  @override
  String get fitCover => 'ملء الصفحة';

  @override
  String get imagesHint => 'اسحب لإعادة الترتيب، وكل صورة في صفحة.';

  @override
  String get imagesNeedOne => 'أضف صورة واحدة على الأقل.';

  @override
  String get createPdfAction => 'أنشئ ملف PDF';

  @override
  String get wmTypeText => 'نص';

  @override
  String get wmTypeImage => 'صورة';

  @override
  String get wmTextLabel => 'نص العلامة';

  @override
  String get wmTextDefault => 'سري';

  @override
  String get wmChooseImage => 'اختر صورة';

  @override
  String get positionLabel => 'الموضع';

  @override
  String get opacityLabel => 'التعتيم';

  @override
  String get rotationLabel => 'الدوران';

  @override
  String get fontSizeLabel => 'حجم النص';

  @override
  String get imageSizeLabel => 'عرض الصورة';

  @override
  String get applyToLabel => 'التطبيق على';

  @override
  String get selectedPages => 'صفحات محددة';

  @override
  String get wmTextAsImageNote =>
      'يُضاف النص كصورة ليظهر العربي بشكل صحيح، لذلك لا يمكن تحديده أو البحث فيه في الملف الناتج.';

  @override
  String get wmAction => 'أضف العلامة';

  @override
  String get posTopLeft => 'أعلى اليسار';

  @override
  String get posTopCenter => 'أعلى الوسط';

  @override
  String get posTopRight => 'أعلى اليمين';

  @override
  String get posCenterLeft => 'وسط اليسار';

  @override
  String get posCenter => 'الوسط';

  @override
  String get posCenterRight => 'وسط اليمين';

  @override
  String get posBottomLeft => 'أسفل اليسار';

  @override
  String get posBottomCenter => 'أسفل الوسط';

  @override
  String get posBottomRight => 'أسفل اليمين';

  @override
  String get pnStart => 'ابدأ الترقيم من';

  @override
  String get pnFormat => 'التنسيق';

  @override
  String get pnEastern => 'أرقام عربية مشرقية (١٢٣)';

  @override
  String get pnSkipFirst => 'لا ترقّم الصفحة الأولى';

  @override
  String get pnSkipFirstHelp => 'تُحتسب صفحة الغلاف ضمن العدّ.';

  @override
  String get pnAction => 'أضف الأرقام';

  @override
  String pnPreview(String label) {
    return 'معاينة: $label';
  }

  @override
  String get sigNotice =>
      'هذا توقيع مرسوم، أي صورة لتوقيعك، وليس توقيعًا رقميًا أو معتمدًا.';

  @override
  String get sigDraw => 'ارسم';

  @override
  String get sigUpload => 'ارفع صورة';

  @override
  String get sigClear => 'مسح';

  @override
  String get sigUndo => 'تراجع';

  @override
  String get sigInk => 'الحبر';

  @override
  String get sigThickness => 'السُّمك';

  @override
  String get sigRemoveBg => 'إزالة الخلفية البيضاء';

  @override
  String get sigDrawHere => 'ارسم توقيعك هنا';

  @override
  String get sigNext => 'ضعه على الصفحة';

  @override
  String get sigPlaceHint => 'اسحبه لتحريكه، واسحب الزاوية لتغيير حجمه.';

  @override
  String get sigPage => 'الصفحة';

  @override
  String get sigAllPages => 'ضعه على كل الصفحات';

  @override
  String get sigEmpty => 'ارسم توقيعًا أو ارفع صورته أولًا.';

  @override
  String get sigAction => 'احفظ نسخة موقّعة';

  @override
  String get colorBlack => 'أسود';

  @override
  String get colorBlue => 'أزرق';

  @override
  String get teNoText => 'لا يوجد نص في هذه الصفحة.';

  @override
  String get teOcrSuggest =>
      'بعض الصفحات تبدو ممسوحة ضوئيًا، ويمكنك قراءتها باستخراج النص من الصورة.';

  @override
  String get teAllEmpty =>
      'لا يحتوي هذا الملف على نص، وغالبًا هو مستند ممسوح ضوئيًا.';

  @override
  String get teOpenOcr => 'اقرأها بالـ OCR';

  @override
  String get copyAll => 'نسخ الكل';

  @override
  String get copied => 'تم النسخ';

  @override
  String get exportTxt => 'حفظ كملف TXT';

  @override
  String get exportDocx => 'حفظ كملف Word (DOCX)';

  @override
  String get teAction => 'استخرج النص';

  @override
  String get ocrLanguage => 'اللغة';

  @override
  String get ocrLangAr => 'العربية';

  @override
  String get ocrLangEn => 'الإنجليزية';

  @override
  String get ocrLangBoth => 'العربية والإنجليزية';

  @override
  String get ocrPreprocess => 'تحسين الصورة';

  @override
  String get ocrGrayscale => 'تدرّج رمادي';

  @override
  String get ocrContrast => 'زيادة التباين';

  @override
  String get ocrBinarize => 'أبيض وأسود';

  @override
  String get ocrSource => 'المصدر';

  @override
  String get ocrPdfPage => 'صفحة من ملف PDF';

  @override
  String get ocrLowConfidence => 'الكلمات المظللة غير مؤكدة، راجعها من فضلك.';

  @override
  String ocrUncertainCount(int count) {
    return 'كلمات غير مؤكدة: $count';
  }

  @override
  String get ocrNoText => 'لم نجد نصًا في هذه الصورة.';

  @override
  String get ocrEditable => 'يمكنك تعديل النص قبل حفظه.';

  @override
  String get ocrAccuracyNote =>
      'قد يخطئ استخراج النص، خاصة مع خط اليد أو الصور غير الواضحة.';

  @override
  String get ocrAction => 'اقرأ النص';

  @override
  String get fiPages => 'عدد الصفحات';

  @override
  String get fiPageSizes => 'مقاسات الصفحات';

  @override
  String get fiFileSize => 'حجم الملف';

  @override
  String get fiVersion => 'إصدار PDF';

  @override
  String get fiTitle => 'العنوان';

  @override
  String get fiAuthor => 'المؤلف';

  @override
  String get fiSubject => 'الموضوع';

  @override
  String get fiKeywords => 'الكلمات المفتاحية';

  @override
  String get fiCreator => 'البرنامج المنشئ';

  @override
  String get fiProducer => 'المنتِج';

  @override
  String get fiCreated => 'تاريخ الإنشاء';

  @override
  String get fiModified => 'تاريخ التعديل';

  @override
  String get fiEncrypted => 'محمي بكلمة مرور';

  @override
  String get fiClearMeta => 'مسح البيانات الوصفية';

  @override
  String get fiClearMetaNote =>
      'يُنشئ نسخة بدون العنوان والمؤلف والتواريخ وغيرها. لا تُنقل الإشارات المرجعية وحقول النماذج إلى النسخة.';

  @override
  String get fiEncryptedNote => 'التفاصيل مخفية لأن الملف محمي.';

  @override
  String get viewerSearch => 'ابحث في الملف';

  @override
  String get viewerNoResults => 'لا توجد نتائج';

  @override
  String viewerMatchCount(int current, int total) {
    return '$current من $total';
  }

  @override
  String get viewerGoTo => 'انتقل إلى صفحة';

  @override
  String get viewerGo => 'انتقل';

  @override
  String get viewerNight => 'الوضع الليلي';

  @override
  String get viewerThumbs => 'الصفحات';

  @override
  String get viewerPrev => 'النتيجة السابقة';

  @override
  String get viewerNext => 'النتيجة التالية';

  @override
  String get passwordTitle => 'كلمة المرور مطلوبة';

  @override
  String get passwordBody => 'هذا الملف محمي. أدخل كلمة المرور لعرضه.';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get passwordWrong => 'كلمة المرور غير صحيحة، حاول مرة أخرى.';

  @override
  String get viewerEncryptedNote =>
      'للعرض فقط؛ أدوات التعديل لا تعالج الملفات المحمية.';

  @override
  String get filesTitle => 'ملفاتي';

  @override
  String get tabRecent => 'الأحدث';

  @override
  String get tabAll => 'الكل';

  @override
  String get tabFavorites => 'المفضّلة';

  @override
  String get searchFiles => 'ابحث بالاسم';

  @override
  String get filterAll => 'كل الأنواع';

  @override
  String get filterPdf => 'PDF';

  @override
  String get filterImage => 'صور';

  @override
  String get filterText => 'نصوص';

  @override
  String get filterZip => 'ZIP';

  @override
  String get sortBy => 'الترتيب';

  @override
  String get sortDate => 'التاريخ';

  @override
  String get sortName => 'الاسم';

  @override
  String get sortSize => 'الحجم';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get renameTitle => 'إعادة تسمية الملف';

  @override
  String get nameLabel => 'الاسم';

  @override
  String get favorite => 'إضافة إلى المفضّلة';

  @override
  String get unfavorite => 'إزالة من المفضّلة';

  @override
  String get moveToTrash => 'نقل إلى المحذوفات';

  @override
  String get movedToTrash => 'نُقل إلى المحذوفات';

  @override
  String get undo => 'تراجع';

  @override
  String get trash => 'سلة المحذوفات';

  @override
  String get restore => 'استرجاع';

  @override
  String get deleteForever => 'حذف نهائي';

  @override
  String get emptyTrash => 'إفراغ السلة';

  @override
  String get trashNote => 'تُحذف العناصر من السلة نهائيًا بعد 30 يومًا.';

  @override
  String get confirmDeleteForever =>
      'هل تريد الحذف نهائيًا؟ لا يمكن التراجع عن ذلك.';

  @override
  String get selectMode => 'تحديد';

  @override
  String selectedN(int count) {
    return 'المحدد: $count';
  }

  @override
  String get importFiles => 'استيراد';

  @override
  String get imported => 'تم الاستيراد';

  @override
  String get filesEmpty =>
      'لا توجد ملفات بعد. أنشئ ملفًا بإحدى الأدوات أو استورد ملفًا.';

  @override
  String get favoritesEmpty => 'ضع نجمة على ملفاتك لتجدها هنا بسرعة.';

  @override
  String get trashEmpty => 'سلة المحذوفات فارغة.';

  @override
  String get searchEmpty => 'لا توجد ملفات مطابقة لبحثك.';

  @override
  String storageUsed(String appName, String size) {
    return 'يستخدم $appName مساحة $size';
  }

  @override
  String storageFree(String size) {
    return 'المساحة المتاحة على الجهاز: $size';
  }

  @override
  String get useInTool => 'استخدمه في أداة';

  @override
  String get kindPdf => 'PDF';

  @override
  String get kindImage => 'صورة';

  @override
  String get kindText => 'نص';

  @override
  String get kindZip => 'ZIP';

  @override
  String get kindDocx => 'Word';

  @override
  String get kindOther => 'ملف';

  @override
  String get sharedInTitle => 'ماذا تريد أن تفعل؟';

  @override
  String get saveToMyFiles => 'حفظ في ملفاتي';

  @override
  String get goToTools => 'تصفّح الأدوات';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get langArabic => 'العربية';

  @override
  String get langEnglish => 'English';

  @override
  String get theme => 'المظهر';

  @override
  String get themeSystem => 'حسب الجهاز';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get ocrData => 'بيانات لغات استخراج النص';

  @override
  String get ocrDataDesc =>
      'مدمجة في التطبيق ولا يُنزَّل أي شيء. نحتفظ بنسخة جاهزة لتسريع القراءة، ويمكنك حذفها لتوفير المساحة وستُجهَّز من جديد عند الحاجة.';

  @override
  String ocrReady(String size) {
    return 'جاهزة · $size';
  }

  @override
  String ocrNotReady(String size) {
    return 'غير مجهّزة · $size داخل التطبيق';
  }

  @override
  String get prepare => 'تجهيز';

  @override
  String get storage => 'التخزين';

  @override
  String get clearAllData => 'حذف كل البيانات';

  @override
  String clearAllConfirm(String appName) {
    return 'سيحذف هذا كل ملفاتك وسلة المحذوفات وإعداداتك في $appName. هل تريد المتابعة؟';
  }

  @override
  String get dataCleared => 'حُذفت كل البيانات';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get licenses => 'تراخيص المصادر المفتوحة';

  @override
  String get about => 'عن التطبيق';

  @override
  String versionLabel(String version) {
    return 'الإصدار $version';
  }

  @override
  String aboutBody(String appName) {
    return '$appName مجموعة أدوات لملفات PDF والصور، مبنية للعربية أولًا، وتعمل بالكامل على جهازك. بدون حساب، وبدون رفع للملفات، وتعمل بدون إنترنت.';
  }

  @override
  String get privacyTitle => 'سياسة الخصوصية';

  @override
  String privacyIntro(String appName) {
    return 'يعالج $appName ملفاتك على جهازك فقط. توضح هذه الصفحة ما يعنيه ذلك بالتفصيل.';
  }

  @override
  String get privacyStoredTitle => 'ما الذي يُخزَّن';

  @override
  String get privacyStoredBody =>
      'الملفات التي تنشئها أو تستوردها، وسلة المحذوفات، وإعداداتك (اللغة والمظهر). تُحفظ كلها في مساحة التطبيق الخاصة على هذا الجهاز فقط.';

  @override
  String get privacyNeverTitle => 'ما الذي لا يُجمع أبدًا';

  @override
  String get privacyNeverBody =>
      'لا نجمع ملفاتك أو محتواها، ولا نرفعها ولا نشاركها. لا يوجد حساب ولا تحليلات ولا تتبّع ولا إعلانات في هذا الإصدار. لا يرسل التطبيق أي طلب عبر الإنترنت أثناء استخدامه، فالخطوط وبيانات لغات استخراج النص ومحرّك PDF كلها داخل التطبيق.';

  @override
  String get privacyDeleteTitle => 'كيف تحذف كل شيء';

  @override
  String get privacyDeleteBody =>
      'من الإعدادات ← حذف كل البيانات تُحذف كل الملفات وسلة المحذوفات والإعدادات. كما يحذف إلغاء تثبيت التطبيق كل بياناته.';

  @override
  String get privacyChangesTitle => 'التغييرات';

  @override
  String get privacyChangesBody =>
      'إذا أضاف إصدار قادم إعلانات أو أي ميزة تتصل بالإنترنت، فسنحدّث هذه السياسة قبل إطلاق ذلك الإصدار، وستعرف ما الذي تغيّر.';

  @override
  String licensesIntro(String appName) {
    return 'بُني $appName ببرمجيات حرة ومفتوحة المصدر. شكرًا لهذه المشاريع:';
  }

  @override
  String get licensesAll => 'عرض نصوص كل التراخيص';

  @override
  String get more => 'المزيد';
}
