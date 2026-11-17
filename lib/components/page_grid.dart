import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';

import '../design/icons.dart';
import '../design/tokens.dart';

/// One page thumbnail with a selection state and an optional overlay.
class PageThumb extends StatelessWidget {
  const PageThumb({
    super.key,
    required this.document,
    required this.pageNumber,
    required this.label,
    this.selected = false,
    this.quarterTurns = 0,
    this.onTap,
    this.blank = false,
    this.footer,
  });

  final PdfDocument? document;
  final int pageNumber;
  final String label;
  final bool selected;
  final int quarterTurns;
  final VoidCallback? onTap;
  final bool blank;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = SatrColors.of(context);
    Widget page = blank || document == null
        ? Container(color: Colors.white)
        : PdfPageView(document: document, pageNumber: pageNumber);
    if (quarterTurns % 4 != 0) page = RotatedBox(quarterTurns: quarterTurns, child: page);
    return Semantics(
      selected: selected,
      button: onTap != null,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.control),
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.fast),
          curve: Motion.curve,
          padding: const EdgeInsets.all(Space.xs),
          decoration: BoxDecoration(
            color: selected ? c.accent.withValues(alpha: 0.35) : c.surface,
            borderRadius: BorderRadius.circular(Radii.control),
            border: Border.all(color: selected ? c.text : c.line, width: selected ? 2 : 1),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)],
                        ),
                        child: Center(child: page),
                      ),
                    ),
                    if (selected)
                      PositionedDirectional(
                        top: 4,
                        end: 4,
                        child: Container(
                          decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                          padding: const EdgeInsets.all(2),
                          child: SatrIcon('check', size: 16, color: c.onAccent),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Space.xs),
              footer ?? Text(label, style: Theme.of(context).textTheme.bodySmall, maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }
}

const SliverGridDelegate kPageGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 150,
  mainAxisSpacing: Space.m,
  crossAxisSpacing: Space.m,
  childAspectRatio: 0.66,
);
