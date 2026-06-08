import 'package:flutter/material.dart';

import '../constants/breakpoints.dart';

class ResponsiveUtils {
  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < Breakpoints.compact;
  }

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= Breakpoints.compact && width < Breakpoints.medium;
  }

  static bool isExpanded(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= Breakpoints.medium;
  }
}