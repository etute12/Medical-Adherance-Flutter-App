import 'package:flutter/material.dart';

/// A utility class to help with responsive design in the app
class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  /// Returns the appropriate value based on screen size
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  /// Returns appropriate content width constraints based on screen size
  static BoxConstraints getContentConstraints(BuildContext context) {
    double maxWidth = 800.0;
    
    if (isTablet(context)) {
      maxWidth = 650.0;
    } else if (isMobile(context)) {
      maxWidth = double.infinity;
    }

    return BoxConstraints(maxWidth: maxWidth);
  }

  /// Returns appropriate horizontal padding based on screen size
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 32.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16.0);
    }
  }
}
