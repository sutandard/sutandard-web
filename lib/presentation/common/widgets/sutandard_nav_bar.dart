import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import 'sutandard_logo.dart';

class SutandardNavBar extends StatelessWidget {
  final VoidCallback? onLoginTap;
  final VoidCallback? onLogoutTap;
  final VoidCallback? onMenuTap;
  final VoidCallback? onDeleteAccountTap;
  final List<NavItem> navItems;
  final Widget? trailing;
  final bool showProfile;
  final String? userName;

  const SutandardNavBar({
    super.key,
    this.onLoginTap,
    this.onLogoutTap,
    this.onMenuTap,
    this.onDeleteAccountTap,
    this.navItems = const [],
    this.trailing,
    this.showProfile = false,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final hPad = responsive.value(mobile: 16.0, tablet: 32.0, desktop: 48.0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: const SutandardLogo(
                variant: SutandardLogoVariant.textOnly,
                height: 26,
              ),
            ),
          ),
          if (!responsive.isMobile && navItems.isNotEmpty) ...[
            const SizedBox(width: 40),
            ...navItems.map((item) => _NavLink(item: item)),
          ],
          const Spacer(),
          if (trailing != null)
            trailing!
          else if (showProfile)
            _ProfileButton(
              userName: userName,
              onLogoutTap: onLogoutTap,
              onDeleteAccountTap: onDeleteAccountTap,
            )
          else
            _LoginButton(onTap: onLoginTap),
          if (responsive.isMobile) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
              onPressed: onMenuTap,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final NavItem item;
  const _NavLink({required this.item});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.item.isActive;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.item.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : _hovering
                      ? AppColors.cardBackground
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.item.label,
              style: AppTextStyles.nav.copyWith(
                color: isActive ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatefulWidget {
  final VoidCallback? onTap;
  const _LoginButton({this.onTap});

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.primary : AppColors.primary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            '로그인',
            style: AppTextStyles.button.copyWith(
              fontSize: 14,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final String? userName;
  final VoidCallback? onLogoutTap;
  final VoidCallback? onDeleteAccountTap;

  const _ProfileButton({
    this.userName,
    this.onLogoutTap,
    this.onDeleteAccountTap,
  });

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 10),
            const Text('회원 탈퇴'),
          ],
        ),
        content: const Text(
          '탈퇴하면 모든 데이터가 삭제되며 복구할 수 없습니다.\n정말로 탈퇴하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDeleteAccountTap?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('탈퇴하기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        switch (value) {
          case 'timetable':
            context.go('/timetable');
          case 'home':
            context.go('/');
          case 'logout':
            onLogoutTap?.call();
          case 'delete_account':
            _showDeleteAccountDialog(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName ?? '사용자',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 2),
                Text(
                  '수원대학교',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'home',
          child: Row(
            children: [
              Icon(Icons.home_outlined, size: 18, color: AppColors.textSecondary),
              SizedBox(width: 10),
              Text('홈'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'timetable',
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
              SizedBox(width: 10),
              Text('나의 시간표'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete_account',
          child: Row(
            children: [
              Icon(Icons.person_remove_outlined, size: 18,
                  color: AppColors.textTertiary),
              const SizedBox(width: 10),
              Text('회원 탈퇴',
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
              const SizedBox(width: 10),
              Text('로그아웃', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: AppColors.onPrimary, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              userName ?? '마이',
              style: AppTextStyles.nav.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class NavItem {
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  const NavItem({required this.label, this.onTap, this.isActive = false});
}
