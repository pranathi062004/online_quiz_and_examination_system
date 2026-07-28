import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../state/auth_provider.dart';
import '../dashboard/dashboard_view.dart';
import '../widgets/animated_background.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLogin = true;
  final String _selectedRole = 'student'; // 'student' or 'admin'
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (_isLogin) {
      success = await auth.login(
        _emailController.text,
        _passwordController.text,
      );
      
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardView()),
        );
      }
    } else {
      success = await auth.register(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text,
        role: _selectedRole,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please sign in to continue.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
        setState(() {
          _isLogin = true;
          _passwordController.clear();
          _nameController.clear();
        });
      }
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Authentication failed'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final auth = Provider.of<AuthProvider>(context);
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Reset Password',
                        style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Enter your registered email address and we will send you a password reset link.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          auth.error!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              auth.clearError();
                              Navigator.pop(dialogContext);
                            },
                            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: auth.isLoading
                                ? null
                                : () async {
                                    if (formKey.currentState?.validate() ?? false) {
                                      final messenger = ScaffoldMessenger.of(context);
                                      final navigator = Navigator.of(dialogContext);
                                      final success = await auth.sendPasswordReset(emailController.text);
                                      if (success) {
                                        navigator.pop();
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Password reset email sent! Check your inbox.'),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Send Link'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: AnimatedBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 40 * (1.0 - value)),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Logo/Icon & Brand Title
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Welcome To ExamiQ',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isLogin ? 'Sign in to your account' : 'Create a new account',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Form Fields
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                              hintText: 'e.g. John Doe',
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Enter your name' : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                            hintText: 'e.g. student@test.com or admin@test.com',
                          ),
                          validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            hintText: 'e.g. student123 or admin123',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                        ),
                        if (_isLogin) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(color: AppColors.secondary, fontSize: 13),
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 24),
                        ],
                        // Action Button
                        ElevatedButton(
                          onPressed: auth.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(_isLogin ? 'Sign In' : 'Sign Up'),
                        ),
                        const SizedBox(height: 20),

                        // Switch mode button
                        TextButton(
                          onPressed: () => setState(() {
                            _isLogin = !_isLogin;
                            auth.clearError();
                          }),
                          child: Text(
                            _isLogin ? "Don't have an account? Create one" : "Already have an account? Sign In",
                            style: const TextStyle(color: AppColors.secondary),
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
      ),
    );
  }
}
