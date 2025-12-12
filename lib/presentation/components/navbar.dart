import 'package:flutter/material.dart';

/// A simple top navigation bar used on web/desktop.
///
/// Usage: place in a `Scaffold` as `appBar: NavBar(currentRoute: 'home')`.
class NavBar extends StatelessWidget implements PreferredSizeWidget {
  final String currentRoute;

  const NavBar({super.key, required this.currentRoute});

  void _navigate(BuildContext context, String route) {
    if (route == currentRoute) return;
    // Use pushReplacementNamed so that browser back behaves intuitively for top-level navs
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text('SE Project'),
      centerTitle: true,
      elevation: 2,
      backgroundColor: theme.colorScheme.primary,
      actions: [
        // Use a row of text buttons for primary navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              _NavButton(
                label: 'Home',
                routeName: 'home',
                isActive: currentRoute == 'home',
                onTap: () => _navigate(context, 'home'),
              ),
              const SizedBox(width: 8),
              _NavButton(
                label: 'Charts',
                routeName: 'charts',
                isActive: currentRoute == 'charts',
                onTap: () => _navigate(context, 'charts'),
              ),

              const SizedBox(width: 8),
              _NavButton(
                label: 'Pixel Wise Map',
                routeName: 'pixelWise',
                isActive: currentRoute == 'pixelWise',
                onTap: () => _navigate(context, 'pixelWise'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _NavButton extends StatelessWidget {
  final String label;
  final String routeName;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.routeName,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = isActive
        ? TextStyle(color: Colors.white, fontWeight: FontWeight.w700)
        : TextStyle(color: Colors.white70);

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: Colors.white),
      child: Text(label, style: style),
    );
  }
}
