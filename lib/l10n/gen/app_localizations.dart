import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get navTools;

  /// No description provided for @navFiles.
  ///
  /// In en, this message translates to:
  /// **'My files'**
  String get navFiles;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @homePickTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get homePickTitle;

  /// No description provided for @homePickSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A PDF or an image from your device'**
  String get homePickSubtitle;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeQuickActions;

  /// No description provided for @homeRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent files'**
  String get homeRecent;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeEmptyRecent.
  ///
  /// In en, this message translates to:
  /// **'Files you create will appear here.'**
  String get homeEmptyRecent;

  /// No description provided for @privacyLine.
  ///
  /// In en, this message translates to:
  /// **'Your files stay on your device'**
  String get privacyLine;

  /// No description provided for @toolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsTitle;

  /// No description provided for @groupOrganize.
  ///
  /// In en, this message translates to:
  /// **'Organize'**
  String get groupOrganize;

  /// No description provided for @groupConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get groupConvert;

  /// No description provided for @groupEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get groupEdit;

  /// No description provided for @groupText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get groupText;

  /// No description provided for @groupOptimize.
  ///
  /// In en, this message translates to:
  /// **'Optimize'**
  String get groupOptimize;

  /// No description provided for @toolMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge PDF'**
  String get toolMerge;

  /// No description provided for @toolMergeDesc.
  ///
  /// In en, this message translates to:
  /// **'Combine several PDFs into one'**
  String get toolMergeDesc;

  /// No description provided for @toolSplit.
  ///
  /// In en, this message translates to:
  /// **'Split PDF'**
  String get toolSplit;

  /// No description provided for @toolSplitDesc.
  ///
  /// In en, this message translates to:
  /// **'Split by page ranges or every few pages'**
  String get toolSplitDesc;

  /// No description provided for @toolExtract.
  ///
  /// In en, this message translates to:
  /// **'Extract pages'**
  String get toolExtract;

  /// No description provided for @toolExtractDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick pages and save them as a new PDF'**
  String get toolExtractDesc;

  /// No description provided for @toolOrganize.
  ///
  /// In en, this message translates to:
  /// **'Organize pages'**
  String get toolOrganize;

  /// No description provided for @toolOrganizeDesc.
  ///
  /// In en, this message translates to:
  /// **'Reorder, rotate, delete, duplicate or add pages'**
  String get toolOrganizeDesc;

  /// No description provided for @toolCompress.
  ///
  /// In en, this message translates to:
  /// **'Compress PDF'**
  String get toolCompress;

  /// No description provided for @toolCompressDesc.
  ///
  /// In en, this message translates to:
  /// **'Make the file smaller'**
  String get toolCompressDesc;

  /// No description provided for @toolPdfToImages.
  ///
  /// In en, this message translates to:
  /// **'PDF to images'**
  String get toolPdfToImages;

  /// No description provided for @toolPdfToImagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Save pages as JPG or PNG'**
  String get toolPdfToImagesDesc;

  /// No description provided for @toolImagesToPdf.
  ///
  /// In en, this message translates to:
  /// **'Images to PDF'**
  String get toolImagesToPdf;

  /// No description provided for @toolImagesToPdfDesc.
  ///
  /// In en, this message translates to:
  /// **'Turn photos and scans into a PDF'**
  String get toolImagesToPdfDesc;

  /// No description provided for @toolWatermark.
  ///
  /// In en, this message translates to:
  /// **'Watermark'**
  String get toolWatermark;

  /// No description provided for @toolWatermarkDesc.
  ///
  /// In en, this message translates to:
  /// **'Add text or an image over the pages'**
  String get toolWatermarkDesc;

  /// No description provided for @toolPageNumbers.
  ///
  /// In en, this message translates to:
  /// **'Page numbers'**
  String get toolPageNumbers;

  /// No description provided for @toolPageNumbersDesc.
  ///
  /// In en, this message translates to:
  /// **'Number the pages of a PDF'**
  String get toolPageNumbersDesc;

  /// No description provided for @toolSignature.
  ///
  /// In en, this message translates to:
  /// **'Drawn signature'**
  String get toolSignature;

  /// No description provided for @toolSignatureDesc.
  ///
  /// In en, this message translates to:
  /// **'Draw or upload your signature and place it'**
  String get toolSignatureDesc;

  /// No description provided for @toolTextExtract.
  ///
  /// In en, this message translates to:
  /// **'Extract text'**
  String get toolTextExtract;

  /// No description provided for @toolTextExtractDesc.
  ///
  /// In en, this message translates to:
  /// **'Copy the text layer of a PDF'**
  String get toolTextExtractDesc;

  /// No description provided for @toolOcr.
  ///
  /// In en, this message translates to:
  /// **'Text from image (OCR)'**
  String get toolOcr;

  /// No description provided for @toolOcrDesc.
  ///
  /// In en, this message translates to:
  /// **'Read Arabic and English text from images'**
  String get toolOcrDesc;

  /// No description provided for @toolFileInfo.
  ///
  /// In en, this message translates to:
  /// **'File info'**
  String get toolFileInfo;

  /// No description provided for @toolFileInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'Pages, size and metadata'**
  String get toolFileInfoDesc;

  /// No description provided for @toolImported.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get toolImported;

  /// No description provided for @toolShared.
  ///
  /// In en, this message translates to:
  /// **'Shared to the app'**
  String get toolShared;

  /// No description provided for @pickPdf.
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF'**
  String get pickPdf;

  /// No description provided for @pickPdfs.
  ///
  /// In en, this message translates to:
  /// **'Choose PDFs'**
  String get pickPdfs;

  /// No description provided for @pickImages.
  ///
  /// In en, this message translates to:
  /// **'Choose images'**
  String get pickImages;

  /// No description provided for @pickImageOrPdf.
  ///
  /// In en, this message translates to:
  /// **'Choose an image or a PDF'**
  String get pickImageOrPdf;

  /// No description provided for @pickImage.
  ///
  /// In en, this message translates to:
  /// **'Choose an image'**
  String get pickImage;

  /// No description provided for @fromDevice.
  ///
  /// In en, this message translates to:
  /// **'From device'**
  String get fromDevice;

  /// No description provided for @fromMyFiles.
  ///
  /// In en, this message translates to:
  /// **'From My files'**
  String get fromMyFiles;

  /// No description provided for @addMore.
  ///
  /// In en, this message translates to:
  /// **'Add more'**
  String get addMore;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @continueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAnyway;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get none;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @working.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get working;

  /// No description provided for @progressPage.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String progressPage(int current, int total);

  /// No description provided for @progressFile.
  ///
  /// In en, this message translates to:
  /// **'File {current} of {total}'**
  String progressFile(int current, int total);

  /// No description provided for @progressVerifying.
  ///
  /// In en, this message translates to:
  /// **'Checking the result…'**
  String get progressVerifying;

  /// No description provided for @progressPreparingOcr.
  ///
  /// In en, this message translates to:
  /// **'Preparing language data…'**
  String get progressPreparingOcr;

  /// No description provided for @progressReadingText.
  ///
  /// In en, this message translates to:
  /// **'Reading text…'**
  String get progressReadingText;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled. No file was created.'**
  String get cancelled;

  /// No description provided for @resultTitle.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get resultTitle;

  /// No description provided for @resultSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to My files'**
  String get resultSaved;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveToDevice.
  ///
  /// In en, this message translates to:
  /// **'Save to device'**
  String get saveToDevice;

  /// No description provided for @savedToDevice.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedToDevice;

  /// No description provided for @useAnotherTool.
  ///
  /// In en, this message translates to:
  /// **'Use another tool'**
  String get useAnotherTool;

  /// No description provided for @pagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String pagesCount(int count);

  /// No description provided for @filesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String filesCount(int count);

  /// No description provided for @imagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 image} other{{count} images}}'**
  String imagesCount(int count);

  /// No description provided for @sizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sizeLabel;

  /// No description provided for @errCorrupt.
  ///
  /// In en, this message translates to:
  /// **'The file is damaged or not supported.'**
  String get errCorrupt;

  /// No description provided for @errEncrypted.
  ///
  /// In en, this message translates to:
  /// **'This PDF is password-protected. You can view it, but editing tools can\'t process protected files in this version.'**
  String get errEncrypted;

  /// No description provided for @errUnsupportedType.
  ///
  /// In en, this message translates to:
  /// **'This file type isn\'t supported here.'**
  String get errUnsupportedType;

  /// No description provided for @errNotPdf.
  ///
  /// In en, this message translates to:
  /// **'Please choose a PDF file.'**
  String get errNotPdf;

  /// No description provided for @errNotImage.
  ///
  /// In en, this message translates to:
  /// **'Please choose an image (JPG, PNG, WebP or HEIC).'**
  String get errNotImage;

  /// No description provided for @errHeic.
  ///
  /// In en, this message translates to:
  /// **'This device can\'t read HEIC images. Android 9 or newer is needed.'**
  String get errHeic;

  /// No description provided for @errEmptyFile.
  ///
  /// In en, this message translates to:
  /// **'The file is empty.'**
  String get errEmptyFile;

  /// No description provided for @errOutputInvalid.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: the result failed verification, so it wasn\'t saved.'**
  String get errOutputInvalid;

  /// No description provided for @errOcr.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read text from this image.'**
  String get errOcr;

  /// No description provided for @errNothingSelected.
  ///
  /// In en, this message translates to:
  /// **'Choose what to work on first.'**
  String get errNothingSelected;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errGeneric;

  /// No description provided for @largeFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Large file'**
  String get largeFileTitle;

  /// No description provided for @largeFileBody.
  ///
  /// In en, this message translates to:
  /// **'This file is {size}. Large files may be slow or fail on this device. Continue anyway?'**
  String largeFileBody(String size);

  /// No description provided for @mergeHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to set the order. The top file comes first.'**
  String get mergeHint;

  /// No description provided for @mergeNeedTwo.
  ///
  /// In en, this message translates to:
  /// **'Add at least two PDFs.'**
  String get mergeNeedTwo;

  /// No description provided for @mergeAction.
  ///
  /// In en, this message translates to:
  /// **'Merge files'**
  String get mergeAction;

  /// No description provided for @splitModeRanges.
  ///
  /// In en, this message translates to:
  /// **'By page ranges'**
  String get splitModeRanges;

  /// No description provided for @splitModeEvery.
  ///
  /// In en, this message translates to:
  /// **'Every few pages'**
  String get splitModeEvery;

  /// No description provided for @splitModeEach.
  ///
  /// In en, this message translates to:
  /// **'Each page separately'**
  String get splitModeEach;

  /// No description provided for @splitRangesLabel.
  ///
  /// In en, this message translates to:
  /// **'Page ranges'**
  String get splitRangesLabel;

  /// No description provided for @splitRangesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1-3, 5, 8-10'**
  String get splitRangesHint;

  /// No description provided for @splitRangesHelp.
  ///
  /// In en, this message translates to:
  /// **'Each range becomes its own file.'**
  String get splitRangesHelp;

  /// No description provided for @splitEveryLabel.
  ///
  /// In en, this message translates to:
  /// **'Pages per file'**
  String get splitEveryLabel;

  /// No description provided for @splitZipNote.
  ///
  /// In en, this message translates to:
  /// **'If there is more than one file, they are packed into one ZIP.'**
  String get splitZipNote;

  /// No description provided for @splitAction.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get splitAction;

  /// No description provided for @rangeErrSyntax.
  ///
  /// In en, this message translates to:
  /// **'Check the format, e.g. 1-3, 5'**
  String get rangeErrSyntax;

  /// No description provided for @rangeErrOutOfBounds.
  ///
  /// In en, this message translates to:
  /// **'Pages must be between 1 and {max}.'**
  String rangeErrOutOfBounds(int max);

  /// No description provided for @rangeErrEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one page.'**
  String get rangeErrEmpty;

  /// No description provided for @rangeErrReversed.
  ///
  /// In en, this message translates to:
  /// **'A range must go from the smaller page to the larger one.'**
  String get rangeErrReversed;

  /// No description provided for @extractHint.
  ///
  /// In en, this message translates to:
  /// **'Tap pages to select them.'**
  String get extractHint;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @selectNone.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get selectNone;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected: {count}'**
  String selectedCount(int count);

  /// No description provided for @extractNeedOne.
  ///
  /// In en, this message translates to:
  /// **'Select at least one page.'**
  String get extractNeedOne;

  /// No description provided for @extractAction.
  ///
  /// In en, this message translates to:
  /// **'Extract pages'**
  String get extractAction;

  /// No description provided for @organizeHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press and drag a page to move it.'**
  String get organizeHint;

  /// No description provided for @rotateLeft.
  ///
  /// In en, this message translates to:
  /// **'Rotate left'**
  String get rotateLeft;

  /// No description provided for @rotateRight.
  ///
  /// In en, this message translates to:
  /// **'Rotate right'**
  String get rotateRight;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @insertBlank.
  ///
  /// In en, this message translates to:
  /// **'Add a blank page'**
  String get insertBlank;

  /// No description provided for @blankA4.
  ///
  /// In en, this message translates to:
  /// **'A4'**
  String get blankA4;

  /// No description provided for @blankLetter.
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get blankLetter;

  /// No description provided for @blankSameSize.
  ///
  /// In en, this message translates to:
  /// **'Same size as this page'**
  String get blankSameSize;

  /// No description provided for @blankPage.
  ///
  /// In en, this message translates to:
  /// **'Blank page'**
  String get blankPage;

  /// No description provided for @pageN.
  ///
  /// In en, this message translates to:
  /// **'Page {n}'**
  String pageN(int n);

  /// No description provided for @organizeNeedOne.
  ///
  /// In en, this message translates to:
  /// **'Keep at least one page.'**
  String get organizeNeedOne;

  /// No description provided for @organizeAction.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get organizeAction;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @compressLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get compressLight;

  /// No description provided for @compressLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Lossless clean-up. Text stays selectable.'**
  String get compressLightDesc;

  /// No description provided for @compressRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get compressRecommended;

  /// No description provided for @compressRecommendedDesc.
  ///
  /// In en, this message translates to:
  /// **'Re-saves large photos at lower quality. Text stays selectable.'**
  String get compressRecommendedDesc;

  /// No description provided for @compressStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get compressStrong;

  /// No description provided for @compressStrongDesc.
  ///
  /// In en, this message translates to:
  /// **'Turns every page into an image. Smallest size.'**
  String get compressStrongDesc;

  /// No description provided for @compressStrongWarning.
  ///
  /// In en, this message translates to:
  /// **'After strong compression, text can no longer be selected, copied or searched.'**
  String get compressStrongWarning;

  /// No description provided for @compressDpi.
  ///
  /// In en, this message translates to:
  /// **'Page image resolution'**
  String get compressDpi;

  /// No description provided for @dpiValue.
  ///
  /// In en, this message translates to:
  /// **'{dpi} DPI'**
  String dpiValue(int dpi);

  /// No description provided for @compressAction.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get compressAction;

  /// No description provided for @compressResult.
  ///
  /// In en, this message translates to:
  /// **'From {before} to {after}'**
  String compressResult(String before, String after);

  /// No description provided for @compressSaved.
  ///
  /// In en, this message translates to:
  /// **'You saved {percent}%'**
  String compressSaved(String percent);

  /// No description provided for @compressNotSmaller.
  ///
  /// In en, this message translates to:
  /// **'The result was not smaller than the original ({after} vs {before}), so your original is kept and nothing new was saved.'**
  String compressNotSmaller(String before, String after);

  /// No description provided for @compressFellBack.
  ///
  /// In en, this message translates to:
  /// **'This file has no photos that can be shrunk safely, so light compression was used.'**
  String get compressFellBack;

  /// No description provided for @compressImagesRecoded.
  ///
  /// In en, this message translates to:
  /// **'Photos re-saved: {count}'**
  String compressImagesRecoded(int count);

  /// No description provided for @originalSize.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get originalSize;

  /// No description provided for @newSize.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newSize;

  /// No description provided for @formatLabel.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get formatLabel;

  /// No description provided for @resolutionLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get resolutionLabel;

  /// No description provided for @pagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pagesLabel;

  /// No description provided for @allPages.
  ///
  /// In en, this message translates to:
  /// **'All pages'**
  String get allPages;

  /// No description provided for @onePage.
  ///
  /// In en, this message translates to:
  /// **'One page'**
  String get onePage;

  /// No description provided for @pageNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Page number'**
  String get pageNumberLabel;

  /// No description provided for @dpiScreen.
  ///
  /// In en, this message translates to:
  /// **'72 · screen'**
  String get dpiScreen;

  /// No description provided for @dpiStandard.
  ///
  /// In en, this message translates to:
  /// **'150 · standard'**
  String get dpiStandard;

  /// No description provided for @dpiPrint.
  ///
  /// In en, this message translates to:
  /// **'300 · print'**
  String get dpiPrint;

  /// No description provided for @convertAction.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get convertAction;

  /// No description provided for @pageSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Page size'**
  String get pageSizeLabel;

  /// No description provided for @pageSizeA4.
  ///
  /// In en, this message translates to:
  /// **'A4'**
  String get pageSizeA4;

  /// No description provided for @pageSizeLetter.
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get pageSizeLetter;

  /// No description provided for @pageSizeFit.
  ///
  /// In en, this message translates to:
  /// **'Same as image'**
  String get pageSizeFit;

  /// No description provided for @orientationLabel.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get orientationLabel;

  /// No description provided for @orientationAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get orientationAuto;

  /// No description provided for @orientationPortrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get orientationPortrait;

  /// No description provided for @orientationLandscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get orientationLandscape;

  /// No description provided for @marginsLabel.
  ///
  /// In en, this message translates to:
  /// **'Margins'**
  String get marginsLabel;

  /// No description provided for @marginNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get marginNone;

  /// No description provided for @marginSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get marginSmall;

  /// No description provided for @marginLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get marginLarge;

  /// No description provided for @fitLabel.
  ///
  /// In en, this message translates to:
  /// **'Image fit'**
  String get fitLabel;

  /// No description provided for @fitContain.
  ///
  /// In en, this message translates to:
  /// **'Fit inside'**
  String get fitContain;

  /// No description provided for @fitCover.
  ///
  /// In en, this message translates to:
  /// **'Fill page'**
  String get fitCover;

  /// No description provided for @imagesHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder. One image per page.'**
  String get imagesHint;

  /// No description provided for @imagesNeedOne.
  ///
  /// In en, this message translates to:
  /// **'Add at least one image.'**
  String get imagesNeedOne;

  /// No description provided for @createPdfAction.
  ///
  /// In en, this message translates to:
  /// **'Create PDF'**
  String get createPdfAction;

  /// No description provided for @wmTypeText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get wmTypeText;

  /// No description provided for @wmTypeImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get wmTypeImage;

  /// No description provided for @wmTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Watermark text'**
  String get wmTextLabel;

  /// No description provided for @wmTextDefault.
  ///
  /// In en, this message translates to:
  /// **'Confidential'**
  String get wmTextDefault;

  /// No description provided for @wmChooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get wmChooseImage;

  /// No description provided for @positionLabel.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get positionLabel;

  /// No description provided for @opacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get opacityLabel;

  /// No description provided for @rotationLabel.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get rotationLabel;

  /// No description provided for @fontSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get fontSizeLabel;

  /// No description provided for @imageSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Image width'**
  String get imageSizeLabel;

  /// No description provided for @applyToLabel.
  ///
  /// In en, this message translates to:
  /// **'Apply to'**
  String get applyToLabel;

  /// No description provided for @selectedPages.
  ///
  /// In en, this message translates to:
  /// **'Selected pages'**
  String get selectedPages;

  /// No description provided for @wmTextAsImageNote.
  ///
  /// In en, this message translates to:
  /// **'Text is added as an image so Arabic shows correctly. It can\'t be selected or searched in the result.'**
  String get wmTextAsImageNote;

  /// No description provided for @wmAction.
  ///
  /// In en, this message translates to:
  /// **'Add watermark'**
  String get wmAction;

  /// No description provided for @posTopLeft.
  ///
  /// In en, this message translates to:
  /// **'Top left'**
  String get posTopLeft;

  /// No description provided for @posTopCenter.
  ///
  /// In en, this message translates to:
  /// **'Top center'**
  String get posTopCenter;

  /// No description provided for @posTopRight.
  ///
  /// In en, this message translates to:
  /// **'Top right'**
  String get posTopRight;

  /// No description provided for @posCenterLeft.
  ///
  /// In en, this message translates to:
  /// **'Middle left'**
  String get posCenterLeft;

  /// No description provided for @posCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get posCenter;

  /// No description provided for @posCenterRight.
  ///
  /// In en, this message translates to:
  /// **'Middle right'**
  String get posCenterRight;

  /// No description provided for @posBottomLeft.
  ///
  /// In en, this message translates to:
  /// **'Bottom left'**
  String get posBottomLeft;

  /// No description provided for @posBottomCenter.
  ///
  /// In en, this message translates to:
  /// **'Bottom center'**
  String get posBottomCenter;

  /// No description provided for @posBottomRight.
  ///
  /// In en, this message translates to:
  /// **'Bottom right'**
  String get posBottomRight;

  /// No description provided for @pnStart.
  ///
  /// In en, this message translates to:
  /// **'Start at'**
  String get pnStart;

  /// No description provided for @pnFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get pnFormat;

  /// No description provided for @pnEastern.
  ///
  /// In en, this message translates to:
  /// **'Eastern Arabic digits (١٢٣)'**
  String get pnEastern;

  /// No description provided for @pnSkipFirst.
  ///
  /// In en, this message translates to:
  /// **'Don\'t number the first page'**
  String get pnSkipFirst;

  /// No description provided for @pnSkipFirstHelp.
  ///
  /// In en, this message translates to:
  /// **'The cover still counts.'**
  String get pnSkipFirstHelp;

  /// No description provided for @pnAction.
  ///
  /// In en, this message translates to:
  /// **'Add numbers'**
  String get pnAction;

  /// No description provided for @pnPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview: {label}'**
  String pnPreview(String label);

  /// No description provided for @sigNotice.
  ///
  /// In en, this message translates to:
  /// **'This is a drawn signature: an image of your signature. It is not a digital or certified signature.'**
  String get sigNotice;

  /// No description provided for @sigDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get sigDraw;

  /// No description provided for @sigUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload image'**
  String get sigUpload;

  /// No description provided for @sigClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get sigClear;

  /// No description provided for @sigUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get sigUndo;

  /// No description provided for @sigInk.
  ///
  /// In en, this message translates to:
  /// **'Ink'**
  String get sigInk;

  /// No description provided for @sigThickness.
  ///
  /// In en, this message translates to:
  /// **'Thickness'**
  String get sigThickness;

  /// No description provided for @sigRemoveBg.
  ///
  /// In en, this message translates to:
  /// **'Remove white background'**
  String get sigRemoveBg;

  /// No description provided for @sigDrawHere.
  ///
  /// In en, this message translates to:
  /// **'Draw your signature here'**
  String get sigDrawHere;

  /// No description provided for @sigNext.
  ///
  /// In en, this message translates to:
  /// **'Place on page'**
  String get sigNext;

  /// No description provided for @sigPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to move. Drag the corner to resize.'**
  String get sigPlaceHint;

  /// No description provided for @sigPage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get sigPage;

  /// No description provided for @sigAllPages.
  ///
  /// In en, this message translates to:
  /// **'Put it on every page'**
  String get sigAllPages;

  /// No description provided for @sigEmpty.
  ///
  /// In en, this message translates to:
  /// **'Draw or upload a signature first.'**
  String get sigEmpty;

  /// No description provided for @sigAction.
  ///
  /// In en, this message translates to:
  /// **'Save signed copy'**
  String get sigAction;

  /// No description provided for @colorBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get colorBlack;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @teNoText.
  ///
  /// In en, this message translates to:
  /// **'This page has no text layer.'**
  String get teNoText;

  /// No description provided for @teOcrSuggest.
  ///
  /// In en, this message translates to:
  /// **'Some pages look scanned. You can read them with OCR.'**
  String get teOcrSuggest;

  /// No description provided for @teAllEmpty.
  ///
  /// In en, this message translates to:
  /// **'This PDF has no text layer. It is probably a scan.'**
  String get teAllEmpty;

  /// No description provided for @teOpenOcr.
  ///
  /// In en, this message translates to:
  /// **'Read with OCR'**
  String get teOpenOcr;

  /// No description provided for @copyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get copyAll;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @exportTxt.
  ///
  /// In en, this message translates to:
  /// **'Save as TXT'**
  String get exportTxt;

  /// No description provided for @exportDocx.
  ///
  /// In en, this message translates to:
  /// **'Save as Word (DOCX)'**
  String get exportDocx;

  /// No description provided for @teAction.
  ///
  /// In en, this message translates to:
  /// **'Extract text'**
  String get teAction;

  /// No description provided for @ocrLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get ocrLanguage;

  /// No description provided for @ocrLangAr.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get ocrLangAr;

  /// No description provided for @ocrLangEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get ocrLangEn;

  /// No description provided for @ocrLangBoth.
  ///
  /// In en, this message translates to:
  /// **'Arabic + English'**
  String get ocrLangBoth;

  /// No description provided for @ocrPreprocess.
  ///
  /// In en, this message translates to:
  /// **'Image clean-up'**
  String get ocrPreprocess;

  /// No description provided for @ocrGrayscale.
  ///
  /// In en, this message translates to:
  /// **'Grayscale'**
  String get ocrGrayscale;

  /// No description provided for @ocrContrast.
  ///
  /// In en, this message translates to:
  /// **'Boost contrast'**
  String get ocrContrast;

  /// No description provided for @ocrBinarize.
  ///
  /// In en, this message translates to:
  /// **'Black & white'**
  String get ocrBinarize;

  /// No description provided for @ocrSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get ocrSource;

  /// No description provided for @ocrPdfPage.
  ///
  /// In en, this message translates to:
  /// **'PDF page'**
  String get ocrPdfPage;

  /// No description provided for @ocrLowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Highlighted words are uncertain. Please check them.'**
  String get ocrLowConfidence;

  /// No description provided for @ocrUncertainCount.
  ///
  /// In en, this message translates to:
  /// **'Uncertain words: {count}'**
  String ocrUncertainCount(int count);

  /// No description provided for @ocrNoText.
  ///
  /// In en, this message translates to:
  /// **'No text was found in this image.'**
  String get ocrNoText;

  /// No description provided for @ocrEditable.
  ///
  /// In en, this message translates to:
  /// **'You can edit the text before saving.'**
  String get ocrEditable;

  /// No description provided for @ocrAccuracyNote.
  ///
  /// In en, this message translates to:
  /// **'OCR can make mistakes, especially with handwriting or blurry photos.'**
  String get ocrAccuracyNote;

  /// No description provided for @ocrAction.
  ///
  /// In en, this message translates to:
  /// **'Read text'**
  String get ocrAction;

  /// No description provided for @fiPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get fiPages;

  /// No description provided for @fiPageSizes.
  ///
  /// In en, this message translates to:
  /// **'Page sizes'**
  String get fiPageSizes;

  /// No description provided for @fiFileSize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get fiFileSize;

  /// No description provided for @fiVersion.
  ///
  /// In en, this message translates to:
  /// **'PDF version'**
  String get fiVersion;

  /// No description provided for @fiTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fiTitle;

  /// No description provided for @fiAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get fiAuthor;

  /// No description provided for @fiSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get fiSubject;

  /// No description provided for @fiKeywords.
  ///
  /// In en, this message translates to:
  /// **'Keywords'**
  String get fiKeywords;

  /// No description provided for @fiCreator.
  ///
  /// In en, this message translates to:
  /// **'Created with'**
  String get fiCreator;

  /// No description provided for @fiProducer.
  ///
  /// In en, this message translates to:
  /// **'Producer'**
  String get fiProducer;

  /// No description provided for @fiCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get fiCreated;

  /// No description provided for @fiModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get fiModified;

  /// No description provided for @fiEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Password-protected'**
  String get fiEncrypted;

  /// No description provided for @fiClearMeta.
  ///
  /// In en, this message translates to:
  /// **'Remove metadata'**
  String get fiClearMeta;

  /// No description provided for @fiClearMetaNote.
  ///
  /// In en, this message translates to:
  /// **'Creates a copy without the title, author, dates and other metadata. Bookmarks and form fields are not kept in the copy.'**
  String get fiClearMetaNote;

  /// No description provided for @fiEncryptedNote.
  ///
  /// In en, this message translates to:
  /// **'Details are hidden because the file is protected.'**
  String get fiEncryptedNote;

  /// No description provided for @viewerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search in document'**
  String get viewerSearch;

  /// No description provided for @viewerNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get viewerNoResults;

  /// No description provided for @viewerMatchCount.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String viewerMatchCount(int current, int total);

  /// No description provided for @viewerGoTo.
  ///
  /// In en, this message translates to:
  /// **'Go to page'**
  String get viewerGoTo;

  /// No description provided for @viewerGo.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get viewerGo;

  /// No description provided for @viewerNight.
  ///
  /// In en, this message translates to:
  /// **'Night mode'**
  String get viewerNight;

  /// No description provided for @viewerThumbs.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get viewerThumbs;

  /// No description provided for @viewerPrev.
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get viewerPrev;

  /// No description provided for @viewerNext.
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get viewerNext;

  /// No description provided for @passwordTitle.
  ///
  /// In en, this message translates to:
  /// **'Password required'**
  String get passwordTitle;

  /// No description provided for @passwordBody.
  ///
  /// In en, this message translates to:
  /// **'This PDF is protected. Enter its password to view it.'**
  String get passwordBody;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong password. Try again.'**
  String get passwordWrong;

  /// No description provided for @viewerEncryptedNote.
  ///
  /// In en, this message translates to:
  /// **'View only: editing tools can\'t process protected files.'**
  String get viewerEncryptedNote;

  /// No description provided for @filesTitle.
  ///
  /// In en, this message translates to:
  /// **'My files'**
  String get filesTitle;

  /// No description provided for @tabRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get tabRecent;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @tabFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get tabFavorites;

  /// No description provided for @searchFiles.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get searchFiles;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get filterAll;

  /// No description provided for @filterPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get filterPdf;

  /// No description provided for @filterImage.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get filterImage;

  /// No description provided for @filterText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get filterText;

  /// No description provided for @filterZip.
  ///
  /// In en, this message translates to:
  /// **'ZIP'**
  String get filterZip;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortBy;

  /// No description provided for @sortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sortDate;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @sortSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sortSize;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @renameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename file'**
  String get renameTitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get favorite;

  /// No description provided for @unfavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get unfavorite;

  /// No description provided for @moveToTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get moveToTrash;

  /// No description provided for @movedToTrash.
  ///
  /// In en, this message translates to:
  /// **'Moved to trash'**
  String get movedToTrash;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @trash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trash;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get deleteForever;

  /// No description provided for @emptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get emptyTrash;

  /// No description provided for @trashNote.
  ///
  /// In en, this message translates to:
  /// **'Items in the trash are deleted for good after 30 days.'**
  String get trashNote;

  /// No description provided for @confirmDeleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently? This can\'t be undone.'**
  String get confirmDeleteForever;

  /// No description provided for @selectMode.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectMode;

  /// No description provided for @selectedN.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedN(int count);

  /// No description provided for @importFiles.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importFiles;

  /// No description provided for @imported.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get imported;

  /// No description provided for @filesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No files yet. Create one with a tool or import a file.'**
  String get filesEmpty;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Star files to find them quickly here.'**
  String get favoritesEmpty;

  /// No description provided for @trashEmpty.
  ///
  /// In en, this message translates to:
  /// **'The trash is empty.'**
  String get trashEmpty;

  /// No description provided for @searchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No files match your search.'**
  String get searchEmpty;

  /// No description provided for @storageUsed.
  ///
  /// In en, this message translates to:
  /// **'{appName} is using {size}'**
  String storageUsed(String appName, String size);

  /// No description provided for @storageFree.
  ///
  /// In en, this message translates to:
  /// **'{size} free on this device'**
  String storageFree(String size);

  /// No description provided for @useInTool.
  ///
  /// In en, this message translates to:
  /// **'Use in a tool'**
  String get useInTool;

  /// No description provided for @kindPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get kindPdf;

  /// No description provided for @kindImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get kindImage;

  /// No description provided for @kindText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get kindText;

  /// No description provided for @kindZip.
  ///
  /// In en, this message translates to:
  /// **'ZIP'**
  String get kindZip;

  /// No description provided for @kindDocx.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get kindDocx;

  /// No description provided for @kindOther.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get kindOther;

  /// No description provided for @sharedInTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get sharedInTitle;

  /// No description provided for @saveToMyFiles.
  ///
  /// In en, this message translates to:
  /// **'Save to My files'**
  String get saveToMyFiles;

  /// No description provided for @goToTools.
  ///
  /// In en, this message translates to:
  /// **'Browse tools'**
  String get goToTools;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @langArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get langArabic;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as device'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @ocrData.
  ///
  /// In en, this message translates to:
  /// **'OCR language data'**
  String get ocrData;

  /// No description provided for @ocrDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Built into the app, nothing is downloaded. A ready copy is kept for fast OCR; you can remove it to free space and it will be prepared again when needed.'**
  String get ocrDataDesc;

  /// No description provided for @ocrReady.
  ///
  /// In en, this message translates to:
  /// **'Ready · {size}'**
  String ocrReady(String size);

  /// No description provided for @ocrNotReady.
  ///
  /// In en, this message translates to:
  /// **'Not prepared · {size} in the app'**
  String ocrNotReady(String size);

  /// No description provided for @prepare.
  ///
  /// In en, this message translates to:
  /// **'Prepare'**
  String get prepare;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get clearAllData;

  /// No description provided for @clearAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'This deletes all your files, the trash and your settings in {appName}. Continue?'**
  String clearAllConfirm(String appName);

  /// No description provided for @dataCleared.
  ///
  /// In en, this message translates to:
  /// **'All data deleted'**
  String get dataCleared;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get licenses;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'{appName} is a set of Arabic-first PDF and image tools that work entirely on your device. No account, no uploads, and it works offline.'**
  String aboutBody(String appName);

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyTitle;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'{appName} processes your files only on your device. This page explains exactly what that means.'**
  String privacyIntro(String appName);

  /// No description provided for @privacyStoredTitle.
  ///
  /// In en, this message translates to:
  /// **'What is stored'**
  String get privacyStoredTitle;

  /// No description provided for @privacyStoredBody.
  ///
  /// In en, this message translates to:
  /// **'Files you create or import, your trash, and your settings (language and theme). They are kept in the app\'s private storage on this device only.'**
  String get privacyStoredBody;

  /// No description provided for @privacyNeverTitle.
  ///
  /// In en, this message translates to:
  /// **'What is never collected'**
  String get privacyNeverTitle;

  /// No description provided for @privacyNeverBody.
  ///
  /// In en, this message translates to:
  /// **'We don\'t collect, upload or share your files or their contents. The app has no account, no analytics, no tracking and no ads in this version. It makes no network requests while you use it: fonts, OCR language data and the PDF engine are all inside the app.'**
  String get privacyNeverBody;

  /// No description provided for @privacyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'How to delete everything'**
  String get privacyDeleteTitle;

  /// No description provided for @privacyDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Settings → Delete all data removes every file, the trash and your settings. Uninstalling the app also removes all of its data.'**
  String get privacyDeleteBody;

  /// No description provided for @privacyChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get privacyChangesTitle;

  /// No description provided for @privacyChangesBody.
  ///
  /// In en, this message translates to:
  /// **'If a future version adds ads or any online feature, this policy will be updated before that version is released, and you will see what changes.'**
  String get privacyChangesBody;

  /// No description provided for @licensesIntro.
  ///
  /// In en, this message translates to:
  /// **'{appName} is built with free, open-source software. Thank you to these projects:'**
  String licensesIntro(String appName);

  /// No description provided for @licensesAll.
  ///
  /// In en, this message translates to:
  /// **'Show all license texts'**
  String get licensesAll;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get more;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get openFile;

  /// No description provided for @viewerTools.
  ///
  /// In en, this message translates to:
  /// **'Tools for this file'**
  String get viewerTools;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
