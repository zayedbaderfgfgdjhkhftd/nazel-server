import 'package:material_ui/material_ui.dart';

/// Ad backend. The default does nothing and pulls in no ad SDK.
///
/// `tool/admob/enable_admob.sh` replaces this file with an AdMob
/// implementation (google_mobile_ads + Google UMP consent). See ADS.md.
abstract class AdBackend {
  /// Called once at startup when ads are enabled (consent, SDK init).
  Future<void> initialize(BuildContext context);

  Widget buildBanner(BuildContext context, String placement);
}

class NoAdBackend implements AdBackend {
  const NoAdBackend();

  @override
  Future<void> initialize(BuildContext context) async {}

  @override
  Widget buildBanner(BuildContext context, String placement) => const SizedBox.shrink();
}

const AdBackend adBackend = NoAdBackend();
