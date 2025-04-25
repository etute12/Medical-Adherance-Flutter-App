import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';

/// A grid that adapts its column count based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? forcedColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.forcedColumns,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columnCount = forcedColumns ?? _getColumnCount(context, constraints.maxWidth);
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: (constraints.maxWidth - (spacing * (columnCount - 1))) / columnCount,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }

  int _getColumnCount(BuildContext context, double width) {
    if (ResponsiveHelper.isDesktop(context)) {
      return width > 1400 ? 3 : 2;
    } else if (ResponsiveHelper.isTablet(context)) {
      return 2;
    }
    return 1;
  }
}
