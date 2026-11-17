import 'package:material_ui/material_ui.dart';

import '../../ads/ad_slot.dart';
import '../../components/common.dart';
import '../../components/l10n_ext.dart';
import '../../design/tokens.dart';
import 'tool_registry.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.toolsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xl),
        children: [
          MaxWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final g in ToolGroup.values) ...[
                  const SizedBox(height: Space.m),
                  HighlightTitle(groupName(context, g), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: Space.m),
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      mainAxisSpacing: Space.m,
                      crossAxisSpacing: Space.m,
                      mainAxisExtent: 132,
                    ),
                    children: [
                      for (final t in kTools.where((t) => t.group == g)) ToolCard(def: t),
                    ],
                  ),
                ],
                const SizedBox(height: Space.xl),
                const AdSlot(AdPlacement.toolsBottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ToolCard extends StatelessWidget {
  const ToolCard({super.key, required this.def});
  final ToolDef def;

  @override
  Widget build(BuildContext context) {
    final c = SatrColors.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openTool(context, def.id),
        child: Padding(
          padding: const EdgeInsets.all(Space.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(def.icon, size: 40),
              const SizedBox(height: Space.s),
              Text(toolName(context, def.id),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
              Expanded(
                child: Text(
                  toolDescription(context, def.id),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: c.textMuted, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
