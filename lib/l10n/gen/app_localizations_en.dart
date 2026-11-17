// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navTools => 'Tools';

  @override
  String get navFiles => 'My files';

  @override
  String get navSettings => 'Settings';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get homePickTitle => 'Choose a file';

  @override
  String get homePickSubtitle => 'A PDF or an image from your device';

  @override
  String get homeQuickActions => 'Quick actions';

  @override
  String get homeRecent => 'Recent files';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeEmptyRecent => 'Files you create will appear here.';

  @override
  String get privacyLine => 'Your files stay on your device';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get groupOrganize => 'Organize';

  @override
  String get groupConvert => 'Convert';

  @override
  String get groupEdit => 'Edit';

  @override
  String get groupText => 'Text';

  @override
  String get groupOptimize => 'Optimize';

  @override
  String get toolMerge => 'Merge PDF';

  @override
  String get toolMergeDesc => 'Combine several PDFs into one';

  @override
  String get toolSplit => 'Split PDF';

  @override
  String get toolSplitDesc => 'Split by page ranges or every few pages';

  @override
  String get toolExtract => 'Extract pages';

  @override
  String get toolExtractDesc => 'Pick pages and save them as a new PDF';

  @override
  String get toolOrganize => 'Organize pages';

  @override
  String get toolOrganizeDesc =>
      'Reorder, rotate, delete, duplicate or add pages';

  @override
  String get toolCompress => 'Compress PDF';

  @override
  String get toolCompressDesc => 'Make the file smaller';

  @override
  String get toolPdfToImages => 'PDF to images';

  @override
  String get toolPdfToImagesDesc => 'Save pages as JPG or PNG';

  @override
  String get toolImagesToPdf => 'Images to PDF';

  @override
  String get toolImagesToPdfDesc => 'Turn photos and scans into a PDF';

  @override
  String get toolWatermark => 'Watermark';

  @override
  String get toolWatermarkDesc => 'Add text or an image over the pages';

  @override
  String get toolPageNumbers => 'Page numbers';

  @override
  String get toolPageNumbersDesc => 'Number the pages of a PDF';

  @override
  String get toolSignature => 'Drawn signature';

  @override
  String get toolSignatureDesc => 'Draw or upload your signature and place it';

  @override
  String get toolTextExtract => 'Extract text';

  @override
  String get toolTextExtractDesc => 'Copy the text layer of a PDF';

  @override
  String get toolOcr => 'Text from image (OCR)';

  @override
  String get toolOcrDesc => 'Read Arabic and English text from images';

  @override
  String get toolFileInfo => 'File info';

  @override
  String get toolFileInfoDesc => 'Pages, size and metadata';

  @override
  String get toolImported => 'Imported';

  @override
  String get toolShared => 'Shared to the app';

  @override
  String get pickPdf => 'Choose a PDF';

  @override
  String get pickPdfs => 'Choose PDFs';

  @override
  String get pickImages => 'Choose images';

  @override
  String get pickImageOrPdf => 'Choose an image or a PDF';

  @override
  String get pickImage => 'Choose an image';

  @override
  String get fromDevice => 'From device';

  @override
  String get fromMyFiles => 'From My files';

  @override
  String get addMore => 'Add more';

  @override
  String get remove => 'Remove';

  @override
  String get change => 'Change';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Try again';

  @override
  String get continueAnyway => 'Continue';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get none => '—';

  @override
  String get loading => 'Loading…';

  @override
  String get working => 'Working…';

  @override
  String progressPage(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String progressFile(int current, int total) {
    return 'File $current of $total';
  }

  @override
  String get progressVerifying => 'Checking the result…';

  @override
  String get progressPreparingOcr => 'Preparing language data…';

  @override
  String get progressReadingText => 'Reading text…';

  @override
  String get cancelled => 'Cancelled. No file was created.';

  @override
  String get resultTitle => 'Done';

  @override
  String get resultSaved => 'Saved to My files';

  @override
  String get open => 'Open';

  @override
  String get share => 'Share';

  @override
  String get save => 'Save';

  @override
  String get saveToDevice => 'Save to device';

  @override
  String get savedToDevice => 'Saved';

  @override
  String get useAnotherTool => 'Use another tool';

  @override
  String pagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String imagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images',
      one: '1 image',
    );
    return '$_temp0';
  }

  @override
  String get sizeLabel => 'Size';

  @override
  String get errCorrupt => 'The file is damaged or not supported.';

  @override
  String get errEncrypted =>
      'This PDF is password-protected. You can view it, but editing tools can\'t process protected files in this version.';

  @override
  String get errUnsupportedType => 'This file type isn\'t supported here.';

  @override
  String get errNotPdf => 'Please choose a PDF file.';

  @override
  String get errNotImage => 'Please choose an image (JPG, PNG, WebP or HEIC).';

  @override
  String get errHeic =>
      'This device can\'t read HEIC images. Android 9 or newer is needed.';

  @override
  String get errEmptyFile => 'The file is empty.';

  @override
  String get errOutputInvalid =>
      'Something went wrong: the result failed verification, so it wasn\'t saved.';

  @override
  String get errOcr => 'Couldn\'t read text from this image.';

  @override
  String get errNothingSelected => 'Choose what to work on first.';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String get largeFileTitle => 'Large file';

  @override
  String largeFileBody(String size) {
    return 'This file is $size. Large files may be slow or fail on this device. Continue anyway?';
  }

  @override
  String get mergeHint => 'Drag to set the order. The top file comes first.';

  @override
  String get mergeNeedTwo => 'Add at least two PDFs.';

  @override
  String get mergeAction => 'Merge files';

  @override
  String get splitModeRanges => 'By page ranges';

  @override
  String get splitModeEvery => 'Every few pages';

  @override
  String get splitModeEach => 'Each page separately';

  @override
  String get splitRangesLabel => 'Page ranges';

  @override
  String get splitRangesHint => 'e.g. 1-3, 5, 8-10';

  @override
  String get splitRangesHelp => 'Each range becomes its own file.';

  @override
  String get splitEveryLabel => 'Pages per file';

  @override
  String get splitZipNote =>
      'If there is more than one file, they are packed into one ZIP.';

  @override
  String get splitAction => 'Split';

  @override
  String get rangeErrSyntax => 'Check the format, e.g. 1-3, 5';

  @override
  String rangeErrOutOfBounds(int max) {
    return 'Pages must be between 1 and $max.';
  }

  @override
  String get rangeErrEmpty => 'Enter at least one page.';

  @override
  String get rangeErrReversed =>
      'A range must go from the smaller page to the larger one.';

  @override
  String get extractHint => 'Tap pages to select them.';

  @override
  String get selectAll => 'Select all';

  @override
  String get selectNone => 'Clear selection';

  @override
  String selectedCount(int count) {
    return 'Selected: $count';
  }

  @override
  String get extractNeedOne => 'Select at least one page.';

  @override
  String get extractAction => 'Extract pages';

  @override
  String get organizeHint => 'Long-press and drag a page to move it.';

  @override
  String get rotateLeft => 'Rotate left';

  @override
  String get rotateRight => 'Rotate right';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get delete => 'Delete';

  @override
  String get insertBlank => 'Add a blank page';

  @override
  String get blankA4 => 'A4';

  @override
  String get blankLetter => 'Letter';

  @override
  String get blankSameSize => 'Same size as this page';

  @override
  String get blankPage => 'Blank page';

  @override
  String pageN(int n) {
    return 'Page $n';
  }

  @override
  String get organizeNeedOne => 'Keep at least one page.';

  @override
  String get organizeAction => 'Save changes';

  @override
  String get reset => 'Reset';

  @override
  String get compressLight => 'Light';

  @override
  String get compressLightDesc => 'Lossless clean-up. Text stays selectable.';

  @override
  String get compressRecommended => 'Recommended';

  @override
  String get compressRecommendedDesc =>
      'Re-saves large photos at lower quality. Text stays selectable.';

  @override
  String get compressStrong => 'Strong';

  @override
  String get compressStrongDesc =>
      'Turns every page into an image. Smallest size.';

  @override
  String get compressStrongWarning =>
      'After strong compression, text can no longer be selected, copied or searched.';

  @override
  String get compressDpi => 'Page image resolution';

  @override
  String dpiValue(int dpi) {
    return '$dpi DPI';
  }

  @override
  String get compressAction => 'Compress';

  @override
  String compressResult(String before, String after) {
    return 'From $before to $after';
  }

  @override
  String compressSaved(String percent) {
    return 'You saved $percent%';
  }

  @override
  String compressNotSmaller(String before, String after) {
    return 'The result was not smaller than the original ($after vs $before), so your original is kept and nothing new was saved.';
  }

  @override
  String get compressFellBack =>
      'This file has no photos that can be shrunk safely, so light compression was used.';

  @override
  String compressImagesRecoded(int count) {
    return 'Photos re-saved: $count';
  }

  @override
  String get originalSize => 'Original';

  @override
  String get newSize => 'New';

  @override
  String get formatLabel => 'Format';

  @override
  String get resolutionLabel => 'Resolution';

  @override
  String get pagesLabel => 'Pages';

  @override
  String get allPages => 'All pages';

  @override
  String get onePage => 'One page';

  @override
  String get pageNumberLabel => 'Page number';

  @override
  String get dpiScreen => '72 · screen';

  @override
  String get dpiStandard => '150 · standard';

  @override
  String get dpiPrint => '300 · print';

  @override
  String get convertAction => 'Convert';

  @override
  String get pageSizeLabel => 'Page size';

  @override
  String get pageSizeA4 => 'A4';

  @override
  String get pageSizeLetter => 'Letter';

  @override
  String get pageSizeFit => 'Same as image';

  @override
  String get orientationLabel => 'Orientation';

  @override
  String get orientationAuto => 'Auto';

  @override
  String get orientationPortrait => 'Portrait';

  @override
  String get orientationLandscape => 'Landscape';

  @override
  String get marginsLabel => 'Margins';

  @override
  String get marginNone => 'None';

  @override
  String get marginSmall => 'Small';

  @override
  String get marginLarge => 'Large';

  @override
  String get fitLabel => 'Image fit';

  @override
  String get fitContain => 'Fit inside';

  @override
  String get fitCover => 'Fill page';

  @override
  String get imagesHint => 'Drag to reorder. One image per page.';

  @override
  String get imagesNeedOne => 'Add at least one image.';

  @override
  String get createPdfAction => 'Create PDF';

  @override
  String get wmTypeText => 'Text';

  @override
  String get wmTypeImage => 'Image';

  @override
  String get wmTextLabel => 'Watermark text';

  @override
  String get wmTextDefault => 'Confidential';

  @override
  String get wmChooseImage => 'Choose image';

  @override
  String get positionLabel => 'Position';

  @override
  String get opacityLabel => 'Opacity';

  @override
  String get rotationLabel => 'Rotation';

  @override
  String get fontSizeLabel => 'Text size';

  @override
  String get imageSizeLabel => 'Image width';

  @override
  String get applyToLabel => 'Apply to';

  @override
  String get selectedPages => 'Selected pages';

  @override
  String get wmTextAsImageNote =>
      'Text is added as an image so Arabic shows correctly. It can\'t be selected or searched in the result.';

  @override
  String get wmAction => 'Add watermark';

  @override
  String get posTopLeft => 'Top left';

  @override
  String get posTopCenter => 'Top center';

  @override
  String get posTopRight => 'Top right';

  @override
  String get posCenterLeft => 'Middle left';

  @override
  String get posCenter => 'Center';

  @override
  String get posCenterRight => 'Middle right';

  @override
  String get posBottomLeft => 'Bottom left';

  @override
  String get posBottomCenter => 'Bottom center';

  @override
  String get posBottomRight => 'Bottom right';

  @override
  String get pnStart => 'Start at';

  @override
  String get pnFormat => 'Format';

  @override
  String get pnEastern => 'Eastern Arabic digits (١٢٣)';

  @override
  String get pnSkipFirst => 'Don\'t number the first page';

  @override
  String get pnSkipFirstHelp => 'The cover still counts.';

  @override
  String get pnAction => 'Add numbers';

  @override
  String pnPreview(String label) {
    return 'Preview: $label';
  }

  @override
  String get sigNotice =>
      'This is a drawn signature: an image of your signature. It is not a digital or certified signature.';

  @override
  String get sigDraw => 'Draw';

  @override
  String get sigUpload => 'Upload image';

  @override
  String get sigClear => 'Clear';

  @override
  String get sigUndo => 'Undo';

  @override
  String get sigInk => 'Ink';

  @override
  String get sigThickness => 'Thickness';

  @override
  String get sigRemoveBg => 'Remove white background';

  @override
  String get sigDrawHere => 'Draw your signature here';

  @override
  String get sigNext => 'Place on page';

  @override
  String get sigPlaceHint => 'Drag to move. Drag the corner to resize.';

  @override
  String get sigPage => 'Page';

  @override
  String get sigAllPages => 'Put it on every page';

  @override
  String get sigEmpty => 'Draw or upload a signature first.';

  @override
  String get sigAction => 'Save signed copy';

  @override
  String get colorBlack => 'Black';

  @override
  String get colorBlue => 'Blue';

  @override
  String get teNoText => 'This page has no text layer.';

  @override
  String get teOcrSuggest =>
      'Some pages look scanned. You can read them with OCR.';

  @override
  String get teAllEmpty => 'This PDF has no text layer. It is probably a scan.';

  @override
  String get teOpenOcr => 'Read with OCR';

  @override
  String get copyAll => 'Copy all';

  @override
  String get copied => 'Copied';

  @override
  String get exportTxt => 'Save as TXT';

  @override
  String get exportDocx => 'Save as Word (DOCX)';

  @override
  String get teAction => 'Extract text';

  @override
  String get ocrLanguage => 'Language';

  @override
  String get ocrLangAr => 'Arabic';

  @override
  String get ocrLangEn => 'English';

  @override
  String get ocrLangBoth => 'Arabic + English';

  @override
  String get ocrPreprocess => 'Image clean-up';

  @override
  String get ocrGrayscale => 'Grayscale';

  @override
  String get ocrContrast => 'Boost contrast';

  @override
  String get ocrBinarize => 'Black & white';

  @override
  String get ocrSource => 'Source';

  @override
  String get ocrPdfPage => 'PDF page';

  @override
  String get ocrLowConfidence =>
      'Highlighted words are uncertain. Please check them.';

  @override
  String ocrUncertainCount(int count) {
    return 'Uncertain words: $count';
  }

  @override
  String get ocrNoText => 'No text was found in this image.';

  @override
  String get ocrEditable => 'You can edit the text before saving.';

  @override
  String get ocrAccuracyNote =>
      'OCR can make mistakes, especially with handwriting or blurry photos.';

  @override
  String get ocrAction => 'Read text';

  @override
  String get fiPages => 'Pages';

  @override
  String get fiPageSizes => 'Page sizes';

  @override
  String get fiFileSize => 'File size';

  @override
  String get fiVersion => 'PDF version';

  @override
  String get fiTitle => 'Title';

  @override
  String get fiAuthor => 'Author';

  @override
  String get fiSubject => 'Subject';

  @override
  String get fiKeywords => 'Keywords';

  @override
  String get fiCreator => 'Created with';

  @override
  String get fiProducer => 'Producer';

  @override
  String get fiCreated => 'Created';

  @override
  String get fiModified => 'Modified';

  @override
  String get fiEncrypted => 'Password-protected';

  @override
  String get fiClearMeta => 'Remove metadata';

  @override
  String get fiClearMetaNote =>
      'Creates a copy without the title, author, dates and other metadata. Bookmarks and form fields are not kept in the copy.';

  @override
  String get fiEncryptedNote =>
      'Details are hidden because the file is protected.';

  @override
  String get viewerSearch => 'Search in document';

  @override
  String get viewerNoResults => 'No matches';

  @override
  String viewerMatchCount(int current, int total) {
    return '$current of $total';
  }

  @override
  String get viewerGoTo => 'Go to page';

  @override
  String get viewerGo => 'Go';

  @override
  String get viewerNight => 'Night mode';

  @override
  String get viewerThumbs => 'Pages';

  @override
  String get viewerPrev => 'Previous match';

  @override
  String get viewerNext => 'Next match';

  @override
  String get passwordTitle => 'Password required';

  @override
  String get passwordBody =>
      'This PDF is protected. Enter its password to view it.';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordWrong => 'Wrong password. Try again.';

  @override
  String get viewerEncryptedNote =>
      'View only: editing tools can\'t process protected files.';

  @override
  String get filesTitle => 'My files';

  @override
  String get tabRecent => 'Recent';

  @override
  String get tabAll => 'All';

  @override
  String get tabFavorites => 'Favorites';

  @override
  String get searchFiles => 'Search by name';

  @override
  String get filterAll => 'All types';

  @override
  String get filterPdf => 'PDF';

  @override
  String get filterImage => 'Images';

  @override
  String get filterText => 'Text';

  @override
  String get filterZip => 'ZIP';

  @override
  String get sortBy => 'Sort';

  @override
  String get sortDate => 'Date';

  @override
  String get sortName => 'Name';

  @override
  String get sortSize => 'Size';

  @override
  String get rename => 'Rename';

  @override
  String get renameTitle => 'Rename file';

  @override
  String get nameLabel => 'Name';

  @override
  String get favorite => 'Add to favorites';

  @override
  String get unfavorite => 'Remove from favorites';

  @override
  String get moveToTrash => 'Move to trash';

  @override
  String get movedToTrash => 'Moved to trash';

  @override
  String get undo => 'Undo';

  @override
  String get trash => 'Trash';

  @override
  String get restore => 'Restore';

  @override
  String get deleteForever => 'Delete forever';

  @override
  String get emptyTrash => 'Empty trash';

  @override
  String get trashNote =>
      'Items in the trash are deleted for good after 30 days.';

  @override
  String get confirmDeleteForever =>
      'Delete permanently? This can\'t be undone.';

  @override
  String get selectMode => 'Select';

  @override
  String selectedN(int count) {
    return '$count selected';
  }

  @override
  String get importFiles => 'Import';

  @override
  String get imported => 'Imported';

  @override
  String get filesEmpty =>
      'No files yet. Create one with a tool or import a file.';

  @override
  String get favoritesEmpty => 'Star files to find them quickly here.';

  @override
  String get trashEmpty => 'The trash is empty.';

  @override
  String get searchEmpty => 'No files match your search.';

  @override
  String storageUsed(String appName, String size) {
    return '$appName is using $size';
  }

  @override
  String storageFree(String size) {
    return '$size free on this device';
  }

  @override
  String get useInTool => 'Use in a tool';

  @override
  String get kindPdf => 'PDF';

  @override
  String get kindImage => 'Image';

  @override
  String get kindText => 'Text';

  @override
  String get kindZip => 'ZIP';

  @override
  String get kindDocx => 'Word';

  @override
  String get kindOther => 'File';

  @override
  String get sharedInTitle => 'What would you like to do?';

  @override
  String get saveToMyFiles => 'Save to My files';

  @override
  String get goToTools => 'Browse tools';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get langArabic => 'العربية';

  @override
  String get langEnglish => 'English';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'Same as device';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get ocrData => 'OCR language data';

  @override
  String get ocrDataDesc =>
      'Built into the app, nothing is downloaded. A ready copy is kept for fast OCR; you can remove it to free space and it will be prepared again when needed.';

  @override
  String ocrReady(String size) {
    return 'Ready · $size';
  }

  @override
  String ocrNotReady(String size) {
    return 'Not prepared · $size in the app';
  }

  @override
  String get prepare => 'Prepare';

  @override
  String get storage => 'Storage';

  @override
  String get clearAllData => 'Delete all data';

  @override
  String clearAllConfirm(String appName) {
    return 'This deletes all your files, the trash and your settings in $appName. Continue?';
  }

  @override
  String get dataCleared => 'All data deleted';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get licenses => 'Open-source licenses';

  @override
  String get about => 'About';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String aboutBody(String appName) {
    return '$appName is a set of Arabic-first PDF and image tools that work entirely on your device. No account, no uploads, and it works offline.';
  }

  @override
  String get privacyTitle => 'Privacy policy';

  @override
  String privacyIntro(String appName) {
    return '$appName processes your files only on your device. This page explains exactly what that means.';
  }

  @override
  String get privacyStoredTitle => 'What is stored';

  @override
  String get privacyStoredBody =>
      'Files you create or import, your trash, and your settings (language and theme). They are kept in the app\'s private storage on this device only.';

  @override
  String get privacyNeverTitle => 'What is never collected';

  @override
  String get privacyNeverBody =>
      'We don\'t collect, upload or share your files or their contents. The app has no account, no analytics, no tracking and no ads in this version. It makes no network requests while you use it: fonts, OCR language data and the PDF engine are all inside the app.';

  @override
  String get privacyDeleteTitle => 'How to delete everything';

  @override
  String get privacyDeleteBody =>
      'Settings → Delete all data removes every file, the trash and your settings. Uninstalling the app also removes all of its data.';

  @override
  String get privacyChangesTitle => 'Changes';

  @override
  String get privacyChangesBody =>
      'If a future version adds ads or any online feature, this policy will be updated before that version is released, and you will see what changes.';

  @override
  String licensesIntro(String appName) {
    return '$appName is built with free, open-source software. Thank you to these projects:';
  }

  @override
  String get licensesAll => 'Show all license texts';

  @override
  String get more => 'More options';

  @override
  String get openFile => 'Open file';

  @override
  String get viewerTools => 'Tools for this file';
}
