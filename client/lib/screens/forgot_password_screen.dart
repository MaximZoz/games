import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_redirect.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/gamepad/gamepad_auth.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/utils/user_error.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _emailFocus = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  String? get _redirect =>
      safeAuthRedirect(GoRouterState.of(context).uri.queryParameters['redirect']);

  @override
  void initState() {
    super.initState();
    _emailFocus.skipTraversal = true;
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }
    final login = _emailController.text.trim();
    try {
      final email =
          await ref.read(authRepositoryProvider).forgotPassword(login: login);
      if (!mounted) return;
      context.go(
        appendAuthQuery(
          '/reset-password',
          redirect: _redirect,
          email: email,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is AuthException ? e.message : formatUserError(e);
          _isLoading = false;
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final media = MediaQuery.of(context);
    final formMaxWidth = isNarrow(context) ? media.size.width : 420.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: formMaxWidth),
              child: GradientCard(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.forgotPasswordTitle,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.forgotPasswordSubtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      GamepadFieldBlock(
                        autofocus: true,
                        inputFocus: _emailFocus,
                        child: TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: l10n.loginEmailLabel,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return l10n.loginEmailRequired;
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        MessageBanner(message: _errorMessage!, type: BannerType.error),
                      ],
                      const SizedBox(height: 24),
                      GamepadActionBlock(
                        outlined: true,
                        radius: AppRadius.button,
                        onActivate: _submit,
                        child: AppButton(
                          onPressed: _submit,
                          label: l10n.forgotPasswordSubmit,
                          isLoading: _isLoading,
                          expanded: true,
                        ),
                      ),
                      GamepadActionBlock(
                        outlined: true,
                        radius: AppRadius.button,
                        onActivate: () => context.go(
                          appendAuthQuery('/login', redirect: _redirect),
                        ),
                        child: TextButton(
                          onPressed: () => context.go(
                            appendAuthQuery('/login', redirect: _redirect),
                          ),
                          child: Text(l10n.resetPasswordBackToLogin),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
