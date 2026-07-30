import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/auth_redirect.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/ui_kit.dart';
import 'package:multigames_client/widgets/oauth_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _inputFocused = false;
  String? _errorMessage;

  String? get _redirect =>
      safeAuthRedirect(GoRouterState.of(context).uri.queryParameters['redirect']);

  String? get _ref {
    final raw = GoRouterState.of(context).uri.queryParameters['ref']?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onInputFocusChanged);
    _passwordFocus.addListener(_onInputFocusChanged);
  }

  void _onInputFocusChanged() {
    final focused = _emailFocus.hasFocus || _passwordFocus.hasFocus;
    if (focused == _inputFocused || !mounted) return;
    setState(() => _inputFocused = focused);
  }

  @override
  void dispose() {
    _emailFocus.removeListener(_onInputFocusChanged);
    _passwordFocus.removeListener(_onInputFocusChanged);
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
    try {
      await ref.read(authStateProvider.notifier).login(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (mounted) context.go(_redirect ?? '/games');
    } on EmailVerificationRequiredException catch (e) {
      if (mounted) {
        final email = e.email.isNotEmpty
            ? e.email
            : _emailController.text.trim().toLowerCase();
        context.go(
          appendAuthQuery(
            '/verify-email',
            redirect: _redirect,
            ref: _ref,
            email: email,
            devCode: e.devCode,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is AuthException) {
            _errorMessage = e.message;
          } else if (e is http.ClientException) {
            _errorMessage = context.l10n.connectionError;
          } else {
            _errorMessage = e.toString();
          }
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
    // Как «О себе»: при фокусе (клавиатура) прижимаем форму вверх.
    final liftToTop = _inputFocused;
    final loginCardKey = ref.watch(bootLoginCardKeyProvider);
    final loginBorderOpacity = ref.watch(bootLoginCardBorderOpacityProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      // iOS Safari: resize + viewInsets дают пустой «блок» над клавиатурой.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Align(
          alignment: liftToTop ? Alignment.topCenter : Alignment.center,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(24, liftToTop ? 8 : 24, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: formMaxWidth),
              child: GradientCard(
                key: loginCardKey,
                borderOpacity: loginBorderOpacity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.loginTitle,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.loginSubtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        textInputAction: TextInputAction.next,
                        scrollPadding: const EdgeInsets.only(bottom: 120),
                        decoration: InputDecoration(
                          labelText: l10n.loginEmailLabel,
                          hintText: l10n.loginEmailLabel,
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l10n.loginEmailRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        scrollPadding: const EdgeInsets.only(bottom: 120),
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: l10n.loginPasswordLabel,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return l10n.loginPasswordRequired;
                          }
                          return null;
                        },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        MessageBanner(
                          message: _errorMessage!,
                          type: BannerType.error,
                        ),
                      ],
                      const SizedBox(height: 24),
                      AppButton(
                        onPressed: _submit,
                        label: l10n.loginSubmit,
                        isLoading: _isLoading,
                        expanded: true,
                      ),
                      OAuthButtons(redirect: _redirect, refCode: _ref),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.push(
                          appendAuthQuery(
                            '/register',
                            redirect: _redirect,
                            ref: _ref,
                          ),
                        ),
                        child: Text(l10n.loginNoAccount),
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
