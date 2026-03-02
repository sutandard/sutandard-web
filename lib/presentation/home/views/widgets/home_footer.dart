import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.cardSolid,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: responsive.value(mobile: 24.0, tablet: 40.0, desktop: 48.0),
        vertical: 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: responsive.isMobile
              ? _mobileFooter()
              : _desktopFooter(),
        ),
      ),
    );
  }

  Widget _desktopFooter() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: _brandSection(),
        ),
        const SizedBox(width: 40),
        Expanded(
          flex: 3,
          child: _linksSection(),
        ),
        Expanded(
          flex: 3,
          child: _contactSection(),
        ),
      ],
    );
  }

  Widget _mobileFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _brandSection(),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _linksSection()),
            Expanded(child: _contactSection()),
          ],
        ),
      ],
    );
  }

  Widget _brandSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sutandard', style: AppTextStyles.logo),
        const SizedBox(height: 8),
        Text(
          '수원대학교 학우들을 위한\n시간표 관리 시스템',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '\u00A9 2026 Sutandard. All Rights Reserved.',
          style: AppTextStyles.caption.copyWith(
            fontFamily: 'InstrumentSerif',
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _linksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('서비스', style: AppTextStyles.subtitle.copyWith(fontSize: 13)),
        const SizedBox(height: 10),
        _footerLink('이용약관', onTap: () {}),
        const SizedBox(height: 6),
        _footerLink('개인정보 처리방침', onTap: () {}),
        const SizedBox(height: 6),
        _footerLink('크레딧', onTap: () {}),
      ],
    );
  }

  Widget _contactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('문의', style: AppTextStyles.subtitle.copyWith(fontSize: 13)),
        const SizedBox(height: 10),
        _footerLink(
          'support@sutandard.kr',
          onTap: () => _launchMail('support@sutandard.kr'),
        ),
        const SizedBox(height: 6),
        _footerLink(
          '수원대학교 포털',
          onTap: () => _launchUrl('https://portal.suwon.ac.kr'),
        ),
      ],
    );
  }

  Widget _footerLink(String text, {VoidCallback? onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _launchMail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
