import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../widgets/auth_widgets.dart';
import '../services/supabase_service.dart';
import 'home_screen.dart';

// 🔒 AUTH SCREEN: Sign in / Sign up with animations
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool isSignIn = true;
  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: kAnimationSlow,
  )..forward();

  late final AnimationController _slideController = AnimationController(
    vsync: this,
    duration: kAnimationNormal,
  )..forward();

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _fadeController,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slideAnimation = Tween<Offset>(
    begin: const Offset(0.3, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

  void _toggleAuthMode() async {
    await _fadeController.reverse();
    setState(() => isSignIn = !isSignIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleSkip() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        await supabaseService.createOrUpdateUserProfile(
          user.uid,
          email: null,
          displayName: 'Anonymous User',
          isAnonymous: true,
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Stack(
        children: [
          // Main gradient background with auth content
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: kDarkGradient,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _handleSkip,
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const AuthLogo(),
                                const SizedBox(height: 32),
                                Text(
                                  isSignIn ? 'Welcome Back' : 'Create Account',
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isSignIn
                                      ? 'Sign in to your account to continue'
                                      : 'Join us and start your journey',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                AnimatedSwitcher(
                                  duration: kAnimationNormal,
                                  child: isSignIn
                                      ? const SignInForm(key: ValueKey('SignIn'))
                                      : const SignUpForm(key: ValueKey('SignUp')),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isSignIn
                                          ? "Don't have an account? "
                                          : "Already have an account? ",
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _toggleAuthMode,
                                      child: Text(
                                        isSignIn ? 'Sign Up' : 'Sign In',
                                        style: const TextStyle(
                                          color: kPrimaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✉️ SIGN IN FORM
class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassTextField(
          controller: _emailController,
          hintText: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        GlassTextField(
          controller: _passwordController,
          hintText: 'Password',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white54,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Forgot Password?',
            style: const TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 28),
        GradientButton(
          label: 'Sign In',
          onPressed: _isLoading
              ? () {}
              : () async {
            final String email = _emailController.text.trim();
            final String password = _passwordController.text.trim();
            if (email.isEmpty || password.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email and password required')),
              );
              return;
            }
            setState(() => _isLoading = true);
            try {
              final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: email,
                password: password,
              );

              if (userCredential.user != null) {
                await supabaseService.createOrUpdateUserProfile(
                  userCredential.user!.uid,
                  email: userCredential.user!.email,
                  displayName: userCredential.user!.displayName,
                  isAnonymous: false,
                );
              }

              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
              );
            } on FirebaseAuthException catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.message ?? 'Sign-in failed')),
              );
            } catch (_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unexpected error')),
              );
            } finally {
              if (mounted) setState(() => _isLoading = false);
            }
          },
        ),
        const SizedBox(height: 16),
        const DividerWithText(label: 'Or continue with'),
        const SizedBox(height: 24),
        const SocialRow(),
      ],
    );
  }
}

// ✉️ SIGN UP FORM
class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassTextField(
          controller: _nameController,
          hintText: 'Full Name',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        GlassTextField(
          controller: _emailController,
          hintText: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        GlassTextField(
          controller: _passwordController,
          hintText: 'Password',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white54,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Checkbox(
              value: _agreeToTerms,
              onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
              fillColor: MaterialStateProperty.all(kPrimaryColor),
            ),
            Expanded(
              child: Text(
                'I agree to the Terms of Service and Privacy Policy',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        GradientButton(
          label: 'Create Account',
          onPressed: _isLoading
              ? () {}
              : () async {
            final String name = _nameController.text.trim();
            final String email = _emailController.text.trim();
            final String password = _passwordController.text.trim();
            if (!_agreeToTerms) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please agree to the terms')),
              );
              return;
            }
            if (email.isEmpty || password.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email and password required')),
              );
              return;
            }
            setState(() => _isLoading = true);
            try {
              final credential = await FirebaseAuth.instance
                  .createUserWithEmailAndPassword(
                email: email,
                password: password,
              );
              if (credential.user != null && name.isNotEmpty) {
                await credential.user!.updateDisplayName(name);
              }

              if (credential.user != null) {
                await supabaseService.createOrUpdateUserProfile(
                  credential.user!.uid,
                  email: credential.user!.email,
                  displayName: name.isNotEmpty ? name : null,
                  isAnonymous: false,
                );
              }

              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
              );
            } on FirebaseAuthException catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.message ?? 'Sign-up failed')),
              );
            } catch (_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unexpected error')),
              );
            } finally {
              if (mounted) setState(() => _isLoading = false);
            }
          },
        ),
        const SizedBox(height: 16),
        const DividerWithText(label: 'Or continue with'),
        const SizedBox(height: 24),
        const SocialRow(),
        const SizedBox(height: 20),
      ],
    );
  }
}
