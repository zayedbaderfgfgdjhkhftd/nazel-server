import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import 'icon_data.g.dart';

/// Icons whose meaning depends on reading direction; mirrored in RTL.
const _directional = {'chevronStart', 'chevronEnd', 'arrowBack', 'undo', 'externalOpen'};

/// A Lucide line icon (stroke 1.75) drawn in the current icon colour.
class SatrIcon extends StatelessWidget {
  const SatrIcon(this.name, {super.key, this.size = 24, this.color, this.semanticLabel});

  final String name;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final svg = kIconSvgs[name];
    assert(svg != null, 'Unknown icon $name');
    final c = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    Widget icon = SvgPicture.string(
      svg ?? kIconSvgs['file']!,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: c),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
    if (_directional.contains(name) && Directionality.of(context) == TextDirection.rtl) {
      icon = Transform.flip(flipX: true, child: icon);
    }
    return icon;
  }
}
