import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum SutandardLogoVariant { full, textOnly }

/// Sutandard SVG 로고 컴포넌트.
///
/// - [SutandardLogoVariant.full]: 아이콘 + 텍스트 + 보라 도트 (Sutandard.svg)
/// - [SutandardLogoVariant.textOnly]: 텍스트 + 보라 도트만 (Logo.svg)
class SutandardLogo extends StatelessWidget {
  final SutandardLogoVariant variant;
  final double? height;
  final VoidCallback? onTap;

  const SutandardLogo({
    super.key,
    this.variant = SutandardLogoVariant.full,
    this.height,
    this.onTap,
  });

  String get _assetPath => switch (variant) {
        SutandardLogoVariant.full => 'assets/images/Sutandard.svg',
        SutandardLogoVariant.textOnly => 'assets/images/Logo.svg',
      };

  double get _defaultHeight => switch (variant) {
        SutandardLogoVariant.full => 60,
        SutandardLogoVariant.textOnly => 50,
      };

  @override
  Widget build(BuildContext context) {
    final widget = SvgPicture.asset(
      _assetPath,
      height: height ?? _defaultHeight,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: widget);
    }
    return widget;
  }
}
