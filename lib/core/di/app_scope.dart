import 'package:flutter/widgets.dart';

import 'app_dependencies.dart';

/// Exposes the composition root to widgets that need a repository.
class AppScope extends InheritedWidget {
  const AppScope({
    required this.dependencies,
    required super.child,
    super.key,
  });

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final AppDependencies? dependencies = maybeOf(context);
    assert(dependencies != null, 'No AppScope found in the widget tree.');
    return dependencies!;
  }

  static AppDependencies? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AppScope>()
          ?.dependencies;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.dependencies != dependencies;
}
