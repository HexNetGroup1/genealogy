import 'package:flutter/material.dart';
import '../../auth/login_screen.dart';
import '../../admin/admin_dashboard_screen.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/liquid_glass.dart';

class UnifiedHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool isGlass;

  const UnifiedHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.actions,
    this.isGlass = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    Widget content = Container(
      padding: EdgeInsets.only(
        top: topPadding + 8,
        bottom: 8,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          if (showBackButton)
            Container(
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                color: Colors.black87,
              ),
            )
          else
            const SizedBox(width: 8),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: showBackButton ? 8.0 : 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1E1E),
                      fontSize: 17,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (actions != null)
            ...actions!
          else if (showBackButton)
            const SizedBox(width: 48) // To balance the back button
          else
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBC02D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFBC02D).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () {
                    final user = AuthService().currentUser;
                    if (user == null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                      );
                    }
                  },
                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                  color: const Color(0xFFF57F17),
                  tooltip: 'Панель управления',
                ),
              ),
            ),
        ],
      ),
    );

    if (isGlass) {
      // Liquid Glass: full-width bar with hairline bottom border.
      // BorderRadius.zero — no capsule clip, the bar spans the full width.
      // The specular rim is suppressed in favour of the explicit bottom border.
      return LiquidGlass(
        borderRadius: BorderRadius.zero,
        blurSigma: 40,
        saturation: 1.5,
        tintOpacity: 0.60,
        addSpecularEdge: false,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withValues(alpha: 0.08),
            width: 1.0,
          ),
        ),
      ),
      child: content,
    );
  }
}
