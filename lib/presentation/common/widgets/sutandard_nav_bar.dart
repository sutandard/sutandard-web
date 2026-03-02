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
  final Widget? leading;
  final bool showProfile;
  final bool hideAuthButton;
  final String? userName;

  const SutandardNavBar({
    super.key,
    this.onLoginTap,
    this.onLogoutTap,
    this.onMenuTap,
    this.onDeleteAccountTap,
    this.navItems = const [],
    this.trailing,
    this.leading,
    this.showProfile = false,
    this.hideAuthButton = false,
    this.userName,
  });

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(maxWidth: 640),
      showDragHandle: true,
      builder: (ctx) => _MobileMenuSheet(
        navItems: navItems,
        showProfile: showProfile,
        onLoginTap: onLoginTap,
        onLogoutTap: onLogoutTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final hPad = responsive.value(mobile: 16.0, tablet: 32.0, desktop: 48.0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 4),
          ],
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
          if (!hideAuthButton) ...[
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
          ],
          if (responsive.isMobile && navItems.isNotEmpty) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
              onPressed: () {
                if (onMenuTap != null) {
                  onMenuTap!.call();
                } else {
                  _showMobileMenu(context);
                }
              },
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}

class _MobileMenuSheet extends StatelessWidget {
  final List<NavItem> navItems;
  final bool showProfile;
  final VoidCallback? onLoginTap;
  final VoidCallback? onLogoutTap;

  const _MobileMenuSheet({
    required this.navItems,
    required this.showProfile,
    this.onLoginTap,
    this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...navItems.map((item) => ListTile(
                leading: Icon(
                  _iconForLabel(item.label),
                  color: item.isActive
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 22,
                ),
                title: Text(
                  item.label,
                  style: AppTextStyles.body.copyWith(
                    color: item.isActive ? AppColors.primary : null,
                    fontWeight:
                        item.isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  item.onTap?.call();
                },
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24),
              )),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 16),
          ),
          ListTile(
            leading: const Icon(Icons.auto_fix_high_rounded,
                color: AppColors.textSecondary, size: 22),
            title: Text('시간표 마법사', style: AppTextStyles.body),
            onTap: () {
              Navigator.pop(context);
              context.go('/wizard');
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          ListTile(
            leading: const Icon(Icons.person_search_outlined,
                color: AppColors.textSecondary, size: 22),
            title: Text('교수 시간표 엿보기', style: AppTextStyles.body),
            onTap: () {
              Navigator.pop(context);
              context.go('/professor-schedule');
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 16),
          ),
          if (showProfile)
            ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: AppColors.error, size: 22),
              title: Text('로그아웃',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                onLogoutTap?.call();
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            )
          else
            ListTile(
              leading: const Icon(Icons.login_rounded,
                  color: AppColors.textSecondary, size: 22),
              title: Text('로그인', style: AppTextStyles.body),
              onTap: () {
                Navigator.pop(context);
                onLoginTap?.call();
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  IconData _iconForLabel(String label) {
    return switch (label) {
      '나의 시간표' => Icons.calendar_today_outlined,
      '강의 탐색' => Icons.menu_book_outlined,
      '강의 목록' => Icons.menu_book_outlined,
      '빈 강의실' => Icons.meeting_room_outlined,
      _ => Icons.circle_outlined,
    };
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
            color: AppColors.primary,
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
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.error, size: 24),
                    const SizedBox(width: 10),
                    Text('회원 탈퇴', style: AppTextStyles.subtitle),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '탈퇴하면 모든 데이터가 삭제되며 복구할 수 없습니다.\n정말로 탈퇴하시겠습니까?',
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('취소'),
                    ),
                    const SizedBox(width: 8),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 260),
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
