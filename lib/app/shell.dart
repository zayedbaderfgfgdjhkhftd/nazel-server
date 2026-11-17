import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../components/file_pick.dart';
import '../components/l10n_ext.dart';
import '../core/platform/platform_bridge.dart';
import '../design/icons.dart';
import '../features/files/files_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tools/tools_screen.dart';
import 'services.dart';

/// Bottom navigation: Home · Tools · My files · Settings.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  StreamSubscription<List<SharedInFile>>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final services = AppScope.of(context);
      _sub = services.platform.sharedFiles.listen(_handleShared);
      final initial = await services.platform.takeInitialSharedFiles();
      if (initial.isNotEmpty) await _handleShared(initial);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Files shared from other apps (Android share sheet / "Open with").
  Future<void> _handleShared(List<SharedInFile> files) async {
    if (!mounted || files.isEmpty) return;
    final inputs = [for (final f in files) await inputFromPath(f.path, f.name)];
    if (!mounted) return;
    final valid = await validateInputs(context, inputs, PickKind.pdfOrImage);
    if (valid.isEmpty || !mounted) return;
    if (valid.length == 1) {
      await chooseToolFor(context, valid.first, offerSave: true);
    } else {
      final store = AppScope.of(context).files;
      for (final f in valid) {
        await store.addBytes(f.name, f.bytes, tool: 'shared');
      }
      setState(() => _index = 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pages = [
      HomeScreen(onSeeAllFiles: () => setState(() => _index = 2)),
      const ToolsScreen(),
      FilesScreen(onGoToTools: () => setState(() => _index = 1)),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const SatrIcon('home'), label: l.navHome),
          NavigationDestination(icon: const SatrIcon('tools'), label: l.navTools),
          NavigationDestination(icon: const SatrIcon('folder'), label: l.navFiles),
          NavigationDestination(icon: const SatrIcon('settings'), label: l.navSettings),
        ],
      ),
    );
  }
}
