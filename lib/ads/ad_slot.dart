import 'package:material_ui/material_ui.dart';

import '../config/app_config.dart';
import 'ad_backend.dart';

/// Where an ad may appear (at most one small banner per screen, never during
/// processing, never inside the viewer, never full-screen).
enum AdPlacement { toolsBottom, resultBottom }

/// Reserved space for a banner. While `AppConfig.ads.enabled` is false this
/// renders nothing and no ad code runs. See ADS.md.
class AdSlot extends StatelessWidget {
  const AdSlot(this.placement, {super.key});
  final AdPlacement placement;

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.ads.enabled) return const SizedBox.shrink();
    return adBackend.buildBanner(context, placement.name);
  }
}
