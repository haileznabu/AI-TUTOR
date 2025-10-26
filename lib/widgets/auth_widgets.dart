import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../screens/home_screen.dart';
import '../services/firebase_auth_service.dart';

class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1.2),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white60),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kAnimationFast,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: scale,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [kPrimaryColor, kAccentColor],
            ),
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SocialRow extends StatelessWidget {
  const SocialRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        SocialButton(
          icon: Icons.g_mobiledata,
          label: 'Google',
          isDisabled: true,
          onPressed: null,
        ),
        SocialButton(
          icon: Icons.apple_rounded,
          label: 'Apple',
          isDisabled: true,
          onPressed: null,
        ),
        SocialButton(
          icon: Icons.arrow_forward_rounded,
          label: 'Skip',
          isSkip: true,
          onPressed: () async {
            if (!context.mounted) return;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              ),
            );
            try {
              final authService = FirebaseAuthService();
              await authService.signInAnonymously();
              if (!context.mounted) return;
              Navigator.of(context, rootNavigator: true).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            } catch (_) {
              if (!context.mounted) return;
              Navigator.of(context, rootNavigator: true).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error while skipping sign-in')),
              );
            }
          },
        ),
      ],
    );
  }
}

class SocialButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isSkip;
  final bool isDisabled;

  const SocialButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.isSkip = false,
    this.isDisabled = false,
  });

  @override
  State<SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<SocialButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kAnimationFast,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSkip) {
      final scale = Tween<double>(
        begin: 1,
        end: 0.92,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            widget.onPressed?.call();
          },
          onTapCancel: () => _controller.reverse(),
          child: ScaleTransition(
            scale: scale,
            child: AnimatedContainer(
              duration: kAnimationFast,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isHovered ? Colors.white : Colors.white38,
                  width: 1.5,
                ),
                gradient: _isHovered
                    ? LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: _isHovered ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: _isHovered
                          ? FontWeight.w600
                          : FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    widget.icon,
                    color: _isHovered ? Colors.white : Colors.white70,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (widget.isDisabled) {
      return Opacity(
        opacity: 0.5,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white24,
                  width: 1.2,
                ),
                color: Colors.transparent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: Colors.white54, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 0.5),
                ),
                child: const Text(
                  'Disabled',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: kAnimationFast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? kPrimaryColor : Colors.white24,
              width: 1.2,
            ),
            color: _isHovered
                ? kPrimaryColor.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DividerWithText extends StatelessWidget {
  final String label;

  const DividerWithText({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white24)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white24)),
      ],
    );
  }
}

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [kPrimaryColor, kAccentColor]),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.school_rounded, color: Colors.white, size: 40),
      ),
    );
  }
}
