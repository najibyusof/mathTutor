import 'package:flutter/material.dart';

import '../../../../models/question_input_method.dart';

/// Segmented control for switching between the three input methods.
class InputMethodSelector extends StatelessWidget {
  const InputMethodSelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final QuestionInputMethod selected;
  final ValueChanged<QuestionInputMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<QuestionInputMethod>(
      showSelectedIcon: false,
      segments: QuestionInputMethod.values
          .map(
            (QuestionInputMethod method) =>
                ButtonSegment<QuestionInputMethod>(
                  value: method,
                  icon: Icon(method.icon),
                  tooltip: method.label,
                ),
          )
          .toList(growable: false),
      selected: <QuestionInputMethod>{selected},
      onSelectionChanged: (Set<QuestionInputMethod> selection) =>
          onSelected(selection.first),
    );
  }
}
