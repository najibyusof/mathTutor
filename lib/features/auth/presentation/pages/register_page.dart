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

/// Account creation screen.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AuthController auth = AuthScope.read(context);
    if (auth.isBusy || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final bool succeeded = await auth.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      passwordConfirmation: _confirmPassword.text,
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
      title: AppStrings.registerTitle,
      subtitle: AppStrings.registerSubtitle,
      children: <Widget>[
        if (auth.errorMessage != null)
          AuthMessageBanner(message: auth.errorMessage!),
        Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              AuthTextField(
                controller: _name,
                label: AppStrings.nameLabel,
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                autofillHints: const <String>[AutofillHints.name],
                validator: (String? value) =>
                    Validators.required(value, field: AppStrings.nameLabel),
                errorText: auth.fieldError('name'),
              ),
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
                autofillHints: const <String>[AutofillHints.newPassword],
                validator: Validators.password,
                errorText: auth.fieldError('password'),
              ),
              AuthTextField(
                controller: _confirmPassword,
                label: AppStrings.confirmPasswordLabel,
                icon: Icons.lock_outline,
                obscure: true,
                textInputAction: TextInputAction.done,
                validator: (String? value) => value == _password.text
                    ? null
                    : AppStrings.passwordMismatch,
                onSubmitted: _submit,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: AppStrings.signUp,
          isLoading: auth.isBusy,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            const Text(AppStrings.hasAccountPrompt),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed(AppRoutes.login),
              child: const Text(AppStrings.signIn),
            ),
          ],
        ),
      ],
    );
  }
}
