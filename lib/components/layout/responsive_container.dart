import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';

/// A container that implements responsive behavior for different screen sizes
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final bool enableMaxWidth;
  final bool centerContent;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final BoxDecoration? decoration;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.enableMaxWidth = true,
    this.centerContent = true,
    this.padding,
    this.backgroundColor,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      decoration: decoration,
      padding: padding ?? ResponsiveHelper.getHorizontalPadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: enableMaxWidth 
              ? ResponsiveHelper.getContentConstraints(context)
              : const BoxConstraints(),
          child: child,
        ),
      ),
    );
  }
}
