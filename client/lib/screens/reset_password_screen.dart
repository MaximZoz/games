import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_redirect.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/utils/user_error.dart';

const _resendCooldown = Duration(seconds: 60);

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _resending = false;
  bool _obscure = true;
  String? _errorMessage;
  String? _infoMessage;
  int _resendSecondsLeft = 0;
  Timer? _resendTimer;

  String? get _redirect =>
      safeAuthRedirect(GoRouterState.of(context).uri.queryParameters['redirect']);

  bool get _canResend => !_resending && _resendSecondsLeft <= 0;

  @override
  void initState() {
    super.initState();
    if (widget.email.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final redirect = safeAuthRedirect(
          GoRouterState.of(context).uri.queryParameters['redirect'],
        );
        context.go(appendAuthQuery('/forgot-password', redirect: redirect));
      });
      return;
    }
    _startResendCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _startResendCooldown([Duration duration = _resendCooldown]) {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = duration.inSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsLeft <= 1) {
        timer.cancel();
        setState(() => _resendSecondsLeft = 0);
        return;
      }
      setState(() => _resendSecondsLeft -= 1);
    });
  }

  String _formatCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _infoMessage = null;
      _isLoading = true;
    });
    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      await ref.read(authStateProvider.notifier).resetPassword(
            email: widget.email,
            code: _codeController.text.trim(),
            newPassword: _passwordController.text,
          );
      if (mounted) context.go(_redirect ?? '/games');
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

  Future<void> _resend() async {
    if (!_canResend) return;
    setState(() {
      _errorMessage = null;
      _infoMessage = null;
      _resending = true;
    });
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email: widget.email);
      if (mounted) {
        setState(() => _infoMessage = context.l10n.resetPasswordResent);
        _startResendCooldown();
      }
    } catch (e) {
      if (mounted) {
        if (e is AuthException && e.statusCode == 429) {
          setState(() => _errorMessage = null);
          _startResendCooldown();
        } else {
          setState(() {
            _errorMessage = e is AuthException ? e.message : formatUserError(e);
          });
        }
      }
    }
    if (mounted) setState(() => _resending = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final media = MediaQuery.of(context);
    final formMaxWidth = isNarrow(context) ? media.size.width : 420.0;
    final resendLabel = _resendSecondsLeft > 0
        ? l10n.resetPasswordResendIn(_formatCountdown(_resendSecondsLeft))
        : l10n.resetPasswordResend;

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
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.resetPasswordTitle,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.resetPasswordSubtitle(widget.email),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          enableSuggestions: false,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: InputDecoration(
                            labelText: l10n.resetPasswordCodeLabel,
                            prefixIcon: const Icon(Icons.mark_email_read_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty || v.trim().length != 6) {
                              return l10n.resetPasswordCodeRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: l10n.resetPasswordNewLabel,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return l10n.resetPasswordNewRequired;
                            }
                            if (v.length < 6) {
                              return l10n.resetPasswordNewShort;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmController,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: l10n.resetPasswordConfirmLabel,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                          ),
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return l10n.resetPasswordConfirmMismatch;
                            }
                            return null;
                          },
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          MessageBanner(message: _errorMessage!, type: BannerType.error),
                        ],
                        if (_infoMessage != null) ...[
                          const SizedBox(height: 16),
                          MessageBanner(message: _infoMessage!, type: BannerType.success),
                        ],
                        const SizedBox(height: 24),
                        AppButton(
                          onPressed: _submit,
                          label: l10n.resetPasswordSubmit,
                          isLoading: _isLoading,
                          expanded: true,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _canResend ? _resend : null,
                          child: Text(
                            _resending ? '…' : resendLabel,
                            style: TextStyle(
                              color: _canResend
                                  ? null
                                  : AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(
                            appendAuthQuery('/login', redirect: _redirect),
                          ),
                          child: Text(l10n.resetPasswordBackToLogin),
                        ),
                      ],
                    ),
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
