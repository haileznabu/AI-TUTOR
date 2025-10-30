import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../widgets/auth_widgets.dart';
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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;
    final isTablet = size.width >= 600 && size.width < 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDesktop || isTablet) {
      return Scaffold(
        body: Row(
          children: [
            // Left panel - Hero section (only on desktop/tablet)
            Expanded(
              flex: isDesktop ? 5 : 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: kDarkGradient,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 64 : 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AuthLogo(),
                        SizedBox(height: isDesktop ? 48 : 32),
                        Text(
                          'Welcome to AI Tutor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 48 : 36,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Personalized learning powered by AI. Master concepts faster with step-by-step explanations, interactive quizzes, and real-time feedback.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: isDesktop ? 18 : 16,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildFeatureItem(
                          icon: Icons.psychology_alt,
                          title: 'AI-Powered Learning',
                          description: 'Adaptive content tailored to your pace',
                          isDesktop: isDesktop,
                        ),
                        const SizedBox(height: 20),
                        _buildFeatureItem(
                          icon: Icons.quiz,
                          title: 'Interactive Quizzes',
                          description: 'Test your knowledge with instant feedback',
                          isDesktop: isDesktop,
                        ),
                        const SizedBox(height: 20),
                        _buildFeatureItem(
                          icon: Icons.trending_up,
                          title: 'Track Your Progress',
                          description: 'Monitor your learning journey',
                          isDesktop: isDesktop,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Right panel - Auth form
            Expanded(
              flex: isDesktop ? 4 : 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: isDark ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: kDarkGradient,
                  ) : null,
                  color: isDark ? null : Colors.white,
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 80 : 40,
                              vertical: 20,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isSignIn ? 'Welcome Back' : 'Create Account',
                                        style: TextStyle(
                                          fontSize: isDesktop ? 36 : 28,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isSignIn
                                            ? 'Sign in to your account to continue your learning journey'
                                            : 'Join us and start your personalized learning experience',
                                        style: TextStyle(
                                          color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey,
                                          fontSize: isDesktop ? 16 : 14,
                                        ),
                                      ),
                                      const SizedBox(height: 48),
                                      AnimatedSwitcher(
                                        duration: kAnimationNormal,
                                        child: isSignIn
                                            ? const SignInForm(key: ValueKey('SignIn'))
                                            : const SignUpForm(key: ValueKey('SignUp')),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: _handleSkip,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: isDark ? Colors.white70 : Colors.black87,
                                            side: BorderSide(color: isDark ? Colors.white.withOpacity(0.3) : Colors.grey.shade300),
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text('Continue as Guest'),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            isSignIn
                                                ? "Don't have an account? "
                                                : "Already have an account? ",
                                            style: TextStyle(
                                              color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey,
                                              fontSize: 15,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: _toggleAuthMode,
                                            child: Text(
                                              isSignIn ? 'Sign Up' : 'Sign In',
                                              style: const TextStyle(
                                                color: kPrimaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: kDarkGradient,
          ) : null,
          color: isDark ? null : Colors.white,
        ),
        child: SafeArea(
          child: Column(
            children: [
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
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isSignIn
                                  ? 'Sign in to your account to continue'
                                  : 'Join us and start your journey',
                              style: textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white70 : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 40),
                            AnimatedSwitcher(
                              duration: kAnimationNormal,
                              child: isSignIn
                                  ? const SignInForm(key: ValueKey('SignIn'))
                                  : const SignUpForm(key: ValueKey('SignUp')),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _handleSkip,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? Colors.white70 : Colors.black87,
                                  side: BorderSide(color: isDark ? Colors.white.withOpacity(0.3) : Colors.grey.shade300),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Continue as Guest'),
                              ),
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
                                    color: isDark ? Colors.white70 : Colors.grey,
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
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDesktop,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kPrimaryColor, kAccentColor],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: isDesktop ? 24 : 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: isDesktop ? 14 : 13,
                ),
              ),
            ],
          ),
        ),
      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: isDark ? Colors.white54 : Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        GradientButton(
          label: 'Sign In',
          isLoading: _isLoading,
          onPressed: () async {
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
              await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: email,
                password: password,
              );

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: isDark ? Colors.white54 : Colors.grey,
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
                style: TextStyle(color: isDark ? Colors.white70 : Colors.grey, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        GradientButton(
          label: 'Create Account',
          isLoading: _isLoading,
          onPressed: () async {
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
      ],
    );
  }
}
