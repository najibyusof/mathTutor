import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_scope.dart';
import '../widgets/auth_message_banner.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

/// Password reset request screen.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AuthController auth = AuthScope.read(context);
    if (auth.isBusy || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await auth.forgotPassword(email: _email.text);
  }

  @override
  Widget build(BuildContext context) {
    final AuthController auth = AuthScope.of(context);

    return AuthScaffold(
      title: AppStrings.forgotPasswordTitle,
      subtitle: AppStrings.forgotPasswordSubtitle,
      children: <Widget>[
        if (auth.errorMessage != null)
          AuthMessageBanner(message: auth.errorMessage!),
        if (auth.statusMessage != null)
          AuthMessageBanner(message: auth.statusMessage!, isError: false),
        Form(
          key: _formKey,
          child: AuthTextField(
            controller: _email,
            label: AppStrings.emailLabel,
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.email],
            validator: Validators.email,
            errorText: auth.fieldError('email'),
            onSubmitted: _submit,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: AppStrings.sendResetLink,
          isLoading: auth.isBusy,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.lg),
        SecondaryButton(
          label: AppStrings.signIn,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
