import 'dart:io';

import 'package:flutter/material.dart';

class CustomerAvatar extends StatelessWidget {
  final String url;
  final String initials;
  final double size;
  final TextStyle fallbackStyle;

  const CustomerAvatar({
    super.key,
    required this.url,
    required this.initials,
    required this.size,
    required this.fallbackStyle,
  });

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Center(child: Text(initials, style: fallbackStyle));
    if (url.isEmpty) return fallback();
    return ClipOval(
      child: url.startsWith('http')
          ? Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback(),
            )
          : Image.file(
              File(url),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback(),
            ),
    );
  }
}
