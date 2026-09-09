import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../routes/app_routes.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_scope.dart';
import '../widgets/auth_message_banner.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

/// Email + password sign-in screen.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AuthController auth = AuthScope.read(context);
    if (auth.isBusy || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final bool succeeded = await auth.login(
      email: _email.text,
      password: _password.text,
    );
    if (succeeded && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController auth = AuthScope.of(context);

    return AuthScaffold(
      title: AppStrings.loginTitle,
      subtitle: AppStrings.loginSubtitle,
      showBackButton: false,
      children: <Widget>[
        if (auth.errorMessage != null)
          AuthMessageBanner(message: auth.errorMessage!),
        Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              AuthTextField(
                controller: _email,
                label: AppStrings.emailLabel,
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                validator: Validators.email,
                errorText: auth.fieldError('email'),
              ),
              AuthTextField(
                controller: _password,
                label: AppStrings.passwordLabel,
                icon: Icons.lock_outline,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.password],
                validator: (String? value) => Validators.required(
                  value,
                  field: AppStrings.passwordLabel,
                ),
                errorText: auth.fieldError('password'),
                onSubmitted: _submit,
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
            child: const Text(AppStrings.forgotPasswordLink),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: AppStrings.signIn,
          isLoading: auth.isBusy,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            const Text(AppStrings.noAccountPrompt),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.register),
              child: const Text(AppStrings.signUp),
            ),
          ],
        ),
      ],
    );
  }
}
