import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _setMode(bool isLogin) {
    setState(() {
      _isLogin = isLogin;
      _error = null;
      _notice = null;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _notice = null;
    });
    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password');
      return;
    }

    bool ok;
    if (_isLogin) {
      ok = await auth.login(email: email, password: password);
    } else {
      if (password != _confirmPasswordController.text) {
        setState(() => _error = 'Passwords do not match');
        return;
      }
      if (_usernameController.text.trim().isEmpty) {
        setState(() => _error = 'Username is required');
        return;
      }
      final age = int.tryParse(_ageController.text);
      if (age == null || age <= 0 || age > 120) {
        setState(() => _error = 'Please enter a valid age');
        return;
      }
      ok = await auth.signup(
        email: email,
        username: _usernameController.text.trim(),
        password: password,
        age: age,
      );
    }

    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      setState(() => _error = auth.error ?? (_isLogin ? 'Login failed' : 'Signup failed'));
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _notice = null;
        _error = 'Enter your email above, then tap "Forgot password?" again';
      });
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _error = ok ? null : auth.error;
      _notice = ok ? 'We sent a password reset link to $email' : null;
    });
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(label, style: const TextStyle(fontSize: 16, color: Tw.gray700)),
          ),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, size: 20),
              suffixIcon: onToggleObscure == null
                  ? null
                  : IconButton(
                      icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                      onPressed: onToggleObscure,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 3, offset: const Offset(0, 1))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: active ? Tw.gray900 : Tw.muted),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Tw.blue50, Tw.indigo50],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Tw.blue600, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.biotech, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text('SmartLAB', style: TextStyle(fontSize: 30, color: Tw.gray900)),
                    const SizedBox(height: 8),
                    const Text(
                      'Understand your lab results with AI-powered analysis',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Tw.muted),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Tw.gray100, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                _tab('Login', _isLogin, () => _setMode(true)),
                                _tab('Sign Up', !_isLogin, () => _setMode(false)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!_isLogin)
                            _field(
                              label: 'Username',
                              controller: _usernameController,
                              icon: Icons.person_outline,
                              hint: 'johndoe',
                            ),
                          _field(
                            label: 'Email',
                            controller: _emailController,
                            icon: Icons.mail_outline,
                            hint: 'your@email.com',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _field(
                            label: 'Password',
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            hint: '••••••••',
                            obscure: !_showPassword,
                            onToggleObscure: () => setState(() => _showPassword = !_showPassword),
                          ),
                          if (!_isLogin) ...[
                            _field(
                              label: 'Confirm Password',
                              controller: _confirmPasswordController,
                              icon: Icons.lock_outline,
                              hint: '••••••••',
                              obscure: !_showConfirmPassword,
                              onToggleObscure: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                            ),
                            _field(
                              label: 'Age',
                              controller: _ageController,
                              icon: Icons.person_outline,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                          ],
                          if (_error != null) _Message(text: _error!, error: true),
                          if (_notice != null) _Message(text: _notice!, error: false),
                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: loading ? null : _forgotPassword,
                                child: const Text('Forgot password?', style: TextStyle(fontSize: 14, color: Tw.blue600)),
                              ),
                            ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: loading ? null : _submit,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: Text(
                              loading ? 'Please wait...' : (_isLogin ? 'Login' : 'Create Account'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'By continuing, you agree to our Terms & Privacy Policy',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Tw.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final bool error;

  const _Message({required this.text, required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error ? Tw.red50 : Tw.green50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 14, color: error ? Tw.red600 : Tw.green700)),
    );
  }
}
