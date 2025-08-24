import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/email_validator.dart';
import '../../widgets/login_sync_dialog.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    // Listen for sync conflicts after login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupSyncConflictListener();
      }
    });
  }

  @override
  void dispose() {
    // Remove listener before disposing
    try {
      context.read<AuthProvider>().removeListener(_onAuthProviderChange);
    } catch (e) {
      // Context might already be disposed
    }
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _setupSyncConflictListener() {
    // Listen for sync choice requirement
    if (mounted) {
      context.read<AuthProvider>().addListener(_onAuthProviderChange);
    }
  }

  void _onAuthProviderChange() {
    if (!mounted) return;
    
    try {
      final authProvider = context.read<AuthProvider>();
      
      if (authProvider.needsSyncChoice && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showSyncConflictDialog();
          }
        });
      }
    } catch (e) {
      // Context might be disposed, ignore
    }
  }

  void _showSyncConflictDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoginSyncDialog(
        authProvider: context.read<AuthProvider>(),
        onResolved: () {
          // Sync resolved, can continue to app
          debugPrint('✅ Sync conflict resolved');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Title
                  const Icon(
                    Icons.school,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'FlashCode',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Master algorithms with spaced repetition',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Auth Form
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email),
                              border: const OutlineInputBorder(),
                              errorText: _emailError,
                            ),
                            onChanged: (value) {
                              // Real-time email validation
                              final validation = EmailValidatorUtil.validateEmail(value);
                              setState(() {
                                _emailError = validation.isValid ? null : validation.error;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              final validation = EmailValidatorUtil.validateEmail(value);
                              if (!validation.isValid) {
                                return validation.error;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Name field (only for sign up)
                          if (_isSignUp) ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Display Name',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (_isSignUp && (value == null || value.isEmpty)) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Main action button
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: authProvider.isLoading ? null : _handleAuth,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: authProvider.isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(_isSignUp ? 'Create Account' : 'Sign In'),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Toggle between sign in/sign up
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_isSignUp ? 'Already have an account?' : 'Don\'t have an account?'),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                    _formKey.currentState?.reset();
                                  });
                                },
                                child: Text(_isSignUp ? 'Sign In' : 'Sign Up'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Divider
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR'),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Demo user button
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: authProvider.isLoading ? null : _handleDemoAuth,
                                  child: const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('Try Demo Account'),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          // Error message
                          if (context.watch<AuthProvider>().error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                context.watch<AuthProvider>().error!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    
    try {
      if (_isSignUp) {
        await authProvider.signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
      } else {
        await authProvider.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
    } catch (e) {
      // Error is handled by AuthProvider
    }
  }

  Future<void> _handleDemoAuth() async {
    final authProvider = context.read<AuthProvider>();
    
    try {
      await authProvider.signUp(
        'demo@guerrillamail.com',
        'demo123!',
        'Demo User'
      );
    } catch (e) {
      // If signup fails, try to sign in (user might already exist)
      try {
        await authProvider.signInWithEmail(
          'demo@guerrillamail.com',
          'demo123!'
        );
      } catch (e) {
        // Error is handled by AuthProvider
      }
    }
  }
}
