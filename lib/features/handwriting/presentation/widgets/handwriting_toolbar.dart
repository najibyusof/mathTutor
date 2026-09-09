import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../controllers/handwriting_controller.dart';

/// Pen/eraser selection plus the undo, redo, clear and export actions.
class HandwritingToolbar extends StatelessWidget {
  const HandwritingToolbar({
    required this.controller,
    required this.onExport,
    super.key,
  });

  final HandwritingController controller;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            SegmentedButton<HandwritingTool>(
              showSelectedIcon: false,
              segments: const <ButtonSegment<HandwritingTool>>[
                ButtonSegment<HandwritingTool>(
                  value: HandwritingTool.pen,
                  icon: Icon(Icons.edit_outlined),
                  tooltip: 'Pen',
                ),
                ButtonSegment<HandwritingTool>(
                  value: HandwritingTool.eraser,
                  icon: Icon(Icons.cleaning_services_outlined),
                  tooltip: 'Eraser',
                ),
              ],
              selected: <HandwritingTool>{controller.tool},
              onSelectionChanged: (Set<HandwritingTool> selection) =>
                  controller.tool = selection.first,
            ),
            IconButton.filledTonal(
              tooltip: 'Undo',
              icon: const Icon(Icons.undo),
              onPressed: controller.canUndo ? controller.undo : null,
            ),
            IconButton.filledTonal(
              tooltip: 'Redo',
              icon: const Icon(Icons.redo),
              onPressed: controller.canRedo ? controller.redo : null,
            ),
            IconButton.filledTonal(
              tooltip: 'Clear',
              icon: const Icon(Icons.delete_outline),
              onPressed: controller.strokes.isEmpty ? null : controller.clear,
            ),
            IconButton.filledTonal(
              tooltip: 'Save as image',
              icon: const Icon(Icons.image_outlined),
              onPressed: controller.strokes.isEmpty ? null : onExport,
            ),
          ],
        );
      },
    );
  }
}
