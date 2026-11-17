import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../app/services.dart';
import '../../components/common.dart';
import '../../components/l10n_ext.dart';
import '../../core/arabic/normalize.dart';
import '../../core/pdf/pdf_service.dart';
import '../../core/share/share_service.dart';
import '../../design/icons.dart';
import '../../design/tokens.dart';
import 'file_tools_sheet.dart';

/// PDF viewer: scroll, pinch-zoom, thumbnails, go to page, search, night mode.
/// Protected PDFs can be viewed after entering the password (view only).
class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key, required this.file, required this.title, this.source});
  final File file;
  final String title;

  /// Set when the file is NOT in My files yet (picked, shared or "Open with"):
  /// the menu then offers "Save to My files".
  final InputFile? source;

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  final _controller = PdfViewerController();
  late final PdfTextSearcher _searcher = PdfTextSearcher(_controller)..addListener(_onSearch);
  final _searchField = TextEditingController();
  bool _night = false;
  bool _savedToLibrary = false;
  bool _searching = false;
  bool _encrypted = false;
  int _passwordAttempts = 0;
  int? _page;

  @override
  void dispose() {
    _searcher.removeListener(_onSearch);
    _searcher.dispose();
    _searchField.dispose();
    super.dispose();
  }

  void _onSearch() {
    if (mounted) setState(() {});
  }

  Future<String?> _askPassword() async {
    _passwordAttempts++;
    _encrypted = true;
    if (!mounted) return null;
    final ctrl = TextEditingController();
    final l = context.l10n;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text(l.passwordTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_passwordAttempts > 1 ? l.passwordWrong : l.passwordBody),
            const SizedBox(height: Space.m),
            TextField(
              controller: ctrl,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(labelText: l.passwordLabel),
              onSubmitted: (v) => Navigator.of(c).pop(v),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.of(c).pop(ctrl.text), child: Text(l.open)),
        ],
      ),
    );
    if (result == null && mounted) Navigator.of(context).maybePop();
    return result;
  }

  void _startSearch(String q) {
    final query = q.trim();
    if (query.isEmpty) {
      _searcher.resetTextSearch();
      return;
    }
    // Some PDF writers store Arabic in visual order; also match the reversed
    // letters so those files are searchable too.
    final pattern = isRtlText(query)
        ? RegExp('${RegExp.escape(query)}|${RegExp.escape(String.fromCharCodes(query.runes.toList().reversed))}')
        : query;
    _searcher.startTextSearch(pattern, caseInsensitive: true);
  }

  Future<void> _goTo() async {
    if (!_controller.isReady) return;
    final l = context.l10n;
    final ctrl = TextEditingController();
    final n = await showDialog<int>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.viewerGoTo),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(hintText: '1 – ${_controller.pageCount}'),
          onSubmitted: (v) => Navigator.of(c).pop(int.tryParse(v.trim())),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(c).pop(int.tryParse(ctrl.text.trim())), child: Text(l.viewerGo)),
        ],
      ),
    );
    if (n != null && n >= 1 && n <= _controller.pageCount) {
      await _controller.goToPage(pageNumber: n);
    }
  }

  void _thumbnails() {
    if (!_controller.isReady) return;
    final doc = _controller.document;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SizedBox(
        height: MediaQuery.sizeOf(c).height * 0.75,
        child: GridView.builder(
          padding: const EdgeInsets.all(Space.l),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140, mainAxisSpacing: Space.m, crossAxisSpacing: Space.m, childAspectRatio: 0.72),
          itemCount: doc.pages.length,
          itemBuilder: (c2, i) => InkWell(
            borderRadius: BorderRadius.circular(Radii.control),
            onTap: () {
              Navigator.of(c).pop();
              _controller.goToPage(pageNumber: i + 1);
            },
            child: Column(
              children: [
                Expanded(child: PdfPageView(document: doc, pageNumber: i + 1)),
                Text('${i + 1}', style: Theme.of(c2).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String icon, String label) => PopupMenuItem(
        value: value,
        child: Row(children: [SatrIcon(icon, size: 20), const SizedBox(width: Space.m), Text(label)]),
      );

  Future<void> _saveToLibrary() async {
    final src = widget.source;
    if (src == null) return;
    await AppScope.of(context).files.addBytes(src.name, src.bytes, tool: 'import');
    if (!mounted) return;
    setState(() => _savedToLibrary = true);
    showMessage(context, context.l10n.resultSaved);
  }

  Future<void> _tools() async {
    final bytes = widget.source?.bytes ?? await widget.file.readAsBytes();
    if (!mounted) return;
    await showFileToolsSheet(context, InputFile(widget.title, bytes));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = SatrColors.of(context);
    final matchCount = _searcher.matches.length;
    Widget viewer = PdfViewer.file(
      widget.file.path,
      controller: _controller,
      passwordProvider: _askPassword,
      params: PdfViewerParams(
        backgroundColor: _night ? const Color(0xFF0E0F11) : c.surface,
        pagePaintCallbacks: [_searcher.pageTextMatchPaintCallback],
        onPageChanged: (p) => setState(() => _page = p),
        onViewerReady: (doc, controller) => setState(() => _page = controller.pageNumber),
        loadingBannerBuilder: (context, bytesDownloaded, totalBytes) =>
            const Center(child: CircularProgressIndicator()),
        errorBannerBuilder: (context, error, stack, ref) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Text(error is PdfPasswordException ? l.passwordWrong : l.errCorrupt,
                textAlign: TextAlign.center),
          ),
        ),
      ),
    );
    if (_night) {
      viewer = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -1, 0, 0, 0, 255, //
          0, -1, 0, 0, 255, //
          0, 0, -1, 0, 255, //
          0, 0, 0, 1, 0,
        ]),
        child: viewer,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchField,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l.viewerSearch,
                  isDense: true,
                ),
                onSubmitted: _startSearch,
              )
            : Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (_searching) ...[
            if (_searchField.text.isNotEmpty && !_searcher.isSearching)
              Center(
                child: Text(
                  matchCount == 0
                      ? l.viewerNoResults
                      : l.viewerMatchCount((_searcher.currentIndex ?? 0) + 1, matchCount),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            IconButton(
              tooltip: l.viewerPrev,
              onPressed: matchCount == 0 ? null : _searcher.goToPrevMatch,
              icon: const SatrIcon('chevronStart'),
            ),
            IconButton(
              tooltip: l.viewerNext,
              onPressed: matchCount == 0 ? null : _searcher.goToNextMatch,
              icon: const SatrIcon('chevronEnd'),
            ),
            IconButton(
              tooltip: l.close,
              onPressed: () => setState(() {
                _searching = false;
                _searchField.clear();
                _searcher.resetTextSearch();
              }),
              icon: const SatrIcon('close'),
            ),
          ] else ...[
            IconButton(
                tooltip: l.viewerSearch,
                onPressed: () => setState(() => _searching = true),
                icon: const SatrIcon('search')),
            IconButton(tooltip: l.viewerTools, onPressed: _tools, icon: const SatrIcon('tools')),
            PopupMenuButton<String>(
              tooltip: l.more,
              icon: const SatrIcon('more'),
              onSelected: (v) => switch (v) {
                'save' => _saveToLibrary(),
                'share' => ShareService.shareFile(widget.file, widget.title),
                'thumbs' => _thumbnails(),
                'goto' => _goTo(),
                _ => setState(() => _night = !_night),
              },
              itemBuilder: (_) => [
                if (widget.source != null && !_savedToLibrary)
                  _menuItem('save', 'folder', l.saveToMyFiles),
                _menuItem('share', 'share', l.share),
                _menuItem('thumbs', 'thumbnails', l.viewerThumbs),
                _menuItem('goto', 'gotoPage', l.viewerGoTo),
                _menuItem('night', _night ? 'sun' : 'moon', l.viewerNight),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_encrypted)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.s),
              child: NoticeBox(text: l.viewerEncryptedNote, icon: 'lock'),
            ),
          Expanded(child: viewer),
          if (_page != null && _controller.isReady)
            Container(
              width: double.infinity,
              color: c.bg,
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Text(
                l.progressPage(_page!, _controller.pageCount),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({super.key, required this.file, required this.title, this.source});
  final File file;
  final String title;

  /// Set when the image is not in My files yet.
  final InputFile? source;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              tooltip: context.l10n.viewerTools,
              icon: const SatrIcon('tools'),
              onPressed: () async {
                final bytes = source?.bytes ?? await file.readAsBytes();
                if (context.mounted) await showFileToolsSheet(context, InputFile(title, bytes));
              },
            ),
            IconButton(
              tooltip: context.l10n.share,
              icon: const SatrIcon('share'),
              onPressed: () => ShareService.shareFile(file, title),
            ),
          ],
        ),
        body: InteractiveViewer(
          maxScale: 8,
          child: Center(
            child: Image.file(file,
                errorBuilder: (c, e, s) => Center(child: Text(context.l10n.errCorrupt))),
          ),
        ),
      );
}

class TextViewerScreen extends StatelessWidget {
  const TextViewerScreen({super.key, required this.text, required this.title});
  final String text;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.l),
          child: MaxWidth(
            maxWidth: 800,
            child: SelectableText(
              text,
              textDirection: isRtlText(text) ? TextDirection.rtl : TextDirection.ltr,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
}
