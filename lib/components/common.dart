import 'package:material_ui/material_ui.dart';

import '../design/icons.dart';
import '../design/tokens.dart';

/// Section title with the brand's yellow "highlighted line" behind it.
class HighlightTitle extends StatelessWidget {
  const HighlightTitle(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = SatrColors.of(context);
    final s = style ?? Theme.of(context).textTheme.titleLarge!;
    return Semantics(
      header: true,
      child: Stack(
        children: [
          Positioned.fill(
            top: (s.fontSize ?? 20) * 0.75,
            bottom: (s.fontSize ?? 20) * 0.12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(text, style: s),
          ),
        ],
      ),
    );
  }
}

/// Friendly empty state with an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.action, this.onAction});
  final String icon;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = SatrColors.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
              child: Center(child: SatrIcon(icon, size: 32, color: c.textMuted)),
            ),
            const SizedBox(height: Space.l),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: c.textMuted)),
            if (action != null) ...[
              const SizedBox(height: Space.l),
              OutlinedButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Rounded surface used to group options.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.title, this.padding});
  final Widget child;
  final String? title;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(Space.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(title!, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: Space.s),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Notice box (info / warning).
class NoticeBox extends StatelessWidget {
  const NoticeBox({super.key, required this.text, this.warning = false, this.icon});
  final String text;
  final bool warning;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final c = SatrColors.of(context);
    final color = warning ? c.danger : c.textMuted;
    return Container(
      padding: const EdgeInsets.all(Space.m),
      decoration: BoxDecoration(
        color: warning ? c.danger.withValues(alpha: 0.08) : c.surface,
        borderRadius: BorderRadius.circular(Radii.control),
        border: Border.all(color: warning ? c.danger.withValues(alpha: 0.4) : c.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SatrIcon(icon ?? (warning ? 'warning' : 'info'), size: 20, color: color),
          const SizedBox(width: Space.s),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: warning ? c.danger : c.text)),
          ),
        ],
      ),
    );
  }
}

/// Centers content and limits its width on large screens.
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child, this.maxWidth = kMaxContentWidth});
  final Widget child;
  final double maxWidth;

  @override
  // heightFactor: 1 -> never taller than the child (e.g. in bottom bars).
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

/// A labelled choice between a few options (segmented style).
class ChoiceRow<T> extends StatelessWidget {
  const ChoiceRow({super.key, required this.label, required this.value, required this.options, required this.onChanged});
  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: Space.s),
        Wrap(
          spacing: Space.s,
          runSpacing: Space.s,
          children: [
            for (final e in options.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: e.key == value,
                showCheckmark: false,
                onSelected: (_) => onChanged(e.key),
              ),
          ],
        ),
      ],
    );
  }
}

/// Primary action pinned to the bottom of tool screens.
class BottomAction extends StatelessWidget {
  const BottomAction({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final c = SatrColors.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.bg,
          border: Border(top: BorderSide(color: c.line.withValues(alpha: 0.6))),
        ),
        padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.m),
        child: MaxWidth(
          maxWidth: 640,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    SatrIcon(icon!, size: 20, color: onPressed == null ? c.textMuted : c.onAccent),
                    const SizedBox(width: Space.s),
                  ],
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small rounded icon tile (tool icons).
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.size = 44, this.highlighted = false});
  final String icon;
  final double size;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final c = SatrColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: highlighted ? c.accent : c.bg,
        borderRadius: BorderRadius.circular(Radii.control),
        border: highlighted ? null : Border.all(color: c.line.withValues(alpha: 0.7)),
      ),
      child: Center(
        child: SatrIcon(icon, size: size * 0.5, color: highlighted ? c.onAccent : c.text),
      ),
    );
  }
}

void showMessage(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}
