import 'package:flutter/material.dart';

/// The three supported ways of entering a math question.
///
/// The enum names double as the API/analytics values for
/// `MathQuestion.inputMethod`.
enum QuestionInputMethod {
  keyboard(
    label: 'Type Question',
    description: 'Use the math keyboard',
    icon: Icons.keyboard_alt_outlined,
  ),
  handwriting(
    label: 'Write Question',
    description: 'Write it with your finger or stylus',
    icon: Icons.edit_outlined,
  ),
  camera(
    label: 'Scan Question',
    description: 'Take a photo of the problem',
    icon: Icons.photo_camera_outlined,
  );

  const QuestionInputMethod({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;
  final String description;
  final IconData icon;

  /// Whether a recognition engine produced the expression.
  bool get isRecognized => this != QuestionInputMethod.keyboard;
}
