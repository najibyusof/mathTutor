import 'package:flutter/widgets.dart';

import 'auth_controller.dart';

/// Makes the [AuthController] available to the widget tree and rebuilds
/// dependents whenever the auth state changes.
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    required AuthController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final AuthController? controller = maybeOf(context);
    assert(controller != null, 'No AuthScope found in the widget tree.');
    return controller!;
  }

  /// Returns `null` when the widget tree has no [AuthScope] above [context].
  static AuthController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;
  }

  /// Reads the controller without subscribing to updates.
  static AuthController read(BuildContext context) {
    final AuthScope? scope = context
        .getInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No AuthScope found in the widget tree.');
    return scope!.notifier!;
  }
}
