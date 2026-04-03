import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading    = false;
  bool _sent       = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final err = await ref.read(authNotifierProvider.notifier).forgotPassword(email);

    if (!mounted) return;
    setState(() { _loading = false; _sent = err == null; _error = err; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent ? _successView() : _formView(),
        ),
      ),
    );
  }

  Widget _successView() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.mark_email_read_outlined, size: 64, color: AppTheme.green),
      const SizedBox(height: 16),
      const Text('Check your inbox', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(
        'A password reset link has been sent to ${_emailCtrl.text.trim()}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: () => context.pop(), child: const Text('Back to Sign In')),
    ],
  );

  Widget _formView() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 24),
      const Text('Enter your email address and we\'ll send you a link to reset your password.',
        style: TextStyle(color: AppTheme.textSecondary)),
      const SizedBox(height: 24),
      if (_error != null) ...[
        Text(_error!, style: const TextStyle(color: AppTheme.error)),
        const SizedBox(height: 12),
      ],
      TextFormField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Email address',
          prefixIcon: Icon(Icons.email_outlined),
        ),
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _loading ? null : _submit,
        child: _loading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Text('Send Reset Link'),
      ),
    ],
  );
}
