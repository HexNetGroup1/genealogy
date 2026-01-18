import 'dart:ui';
import 'package:flutter/material.dart';
import '../../auth/login_screen.dart';
import '../../admin/admin_dashboard_screen.dart';
import '../../../services/auth_service.dart';

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
        top: topPadding + 12,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: Colors.black87,
            )
          else
            const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: showBackButton ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 20,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (actions != null)
            ...actions!
          else if (showBackButton)
            const SizedBox(width: 48) // To balance the back button
          else
            IconButton(
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
              color: Colors.black54,
            ),
        ],
      ),
    );

    if (isGlass) {
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.white.withValues(alpha: 0.9), // Более плотный фон
            child: content,
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: content,
    );
  }
}
