import 'package:flutter/material.dart';

enum SnackbarType { error, success, warning, info }

void showSnackBar(
  BuildContext context,
  Widget content,
  SnackbarType snackbarType, {
  Duration duration = const Duration(seconds: 2),
  IconData? icon,
}) {
  if (!context.mounted) return;

  final theme = Theme.of(context);
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData defaultIcon;

  switch (snackbarType) {
    case SnackbarType.error:
      backgroundColor = theme.colorScheme.errorContainer;
      foregroundColor = theme.colorScheme.onErrorContainer;
      defaultIcon = Icons.error_outlined;
      break;
    case SnackbarType.warning:
      backgroundColor = _getWarningColor(theme);
      foregroundColor = _getOnWarningColor(theme);
      defaultIcon = Icons.warning_amber_rounded;
      break;
    case SnackbarType.success:
      backgroundColor = _getSuccessColor(theme);
      foregroundColor = _getOnSuccessColor(theme);
      defaultIcon = Icons.check_circle_outlined;
      break;
    case SnackbarType.info:
      backgroundColor = theme.colorScheme.secondaryContainer;
      foregroundColor = theme.colorScheme.onSecondaryContainer;
      defaultIcon = Icons.info_outlined;
      break;
  }

  ScaffoldMessenger.of(context).clearSnackBars();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: _M3AnimatedSnackbarContent(
        icon: icon ?? defaultIcon,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        content: content,
        snackbarType: snackbarType,
      ),
      duration: duration,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
      clipBehavior: Clip.none,
    ),
  );
}

Color _getWarningColor(ThemeData theme) {
  final tertiary = theme.colorScheme.tertiaryContainer;

  if (_isColorInHueRange(tertiary, 30, 80)) {
    return tertiary;
  }

  return Color.lerp(theme.colorScheme.primaryContainer, Colors.amber, 0.6)!;
}

Color _getOnWarningColor(ThemeData theme) {
  final warningColor = _getWarningColor(theme);

  return warningColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
}

Color _getSuccessColor(ThemeData theme) {
  final tertiary = theme.colorScheme.tertiaryContainer;
  final primary = theme.colorScheme.primaryContainer;

  if (_isColorInHueRange(tertiary, 80, 160)) {
    return tertiary;
  }

  if (_isColorInHueRange(primary, 80, 160)) {
    return primary;
  }

  return HSLColor.fromColor(
    primary,
  ).withHue(120).withSaturation(0.7).withLightness(0.8).toColor();
}

Color _getOnSuccessColor(ThemeData theme) {
  final successColor = _getSuccessColor(theme);

  return successColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
}

bool _isColorInHueRange(Color color, double minHue, double maxHue) {
  final hsl = HSLColor.fromColor(color);
  return hsl.hue >= minHue && hsl.hue <= maxHue;
}

class _M3AnimatedSnackbarContent extends StatefulWidget {
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final Widget content;
  final SnackbarType snackbarType;

  const _M3AnimatedSnackbarContent({
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.content,
    required this.snackbarType,
  });

  @override
  _M3AnimatedSnackbarContentState createState() =>
      _M3AnimatedSnackbarContentState();
}

class _M3AnimatedSnackbarContentState extends State<_M3AnimatedSnackbarContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _borderRadiusAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.fastEaseInToSlowEaseOut,
          ),
        );

    _borderRadiusAnimation = Tween<double>(begin: 28.0, end: 12.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeSnackbar() {
    _controller.reverse().then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _borderRadiusAnimation,
          builder: (context, child) {
            return Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(_borderRadiusAnimation.value),
              color: widget.backgroundColor,
              surfaceTintColor: widget.foregroundColor.withValues(alpha: 0.1),
              shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.3),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.foregroundColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.foregroundColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: widget.foregroundColor,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                        child: widget.content,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: widget.foregroundColor,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: widget.foregroundColor.withValues(
                            alpha: 0.12,
                          ),
                          padding: const EdgeInsets.all(4),
                          minimumSize: const Size(32, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _closeSnackbar,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
