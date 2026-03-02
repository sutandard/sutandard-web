import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/filter_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/common_model.dart';
import '../../../../data/repositories/course_repository.dart';

class HomeSearchPanel extends ConsumerStatefulWidget {
  final void Function(HomeSearchFilters filters) onSearch;
  final VoidCallback onClose;

  const HomeSearchPanel({
    super.key,
    required this.onSearch,
    required this.onClose,
  });

  @override
  ConsumerState<HomeSearchPanel> createState() => _HomeSearchPanelState();
}

class _HomeSearchPanelState extends ConsumerState<HomeSearchPanel> {
  final _searchController = TextEditingController();
  String? _selectedCourseType;
  int? _selectedYearLevel;
  bool? _isElearning;
  String? _selectedDepartment;
  String? _selectedPeriod;
  List<Department> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final repo = ref.read(courseRepositoryProvider);
      final departments = await repo.getDepartments();
      if (mounted) setState(() => _departments = departments);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _searchController.clear();
      _selectedCourseType = null;
      _selectedYearLevel = null;
      _isElearning = null;
      _selectedDepartment = null;
      _selectedPeriod = null;
    });
  }

  void _doSearch() {
    widget.onSearch(HomeSearchFilters(
      query: _searchController.text.trim(),
      courseType: _selectedCourseType,
      yearLevel: _selectedYearLevel,
      isElearning: _isElearning,
      department: _selectedDepartment,
      period: _selectedPeriod,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: _buildSearchInput(),
          ),
          Container(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: _buildCourseTypeSection(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: _buildYearLevelSection(),
          ),
          if (_departments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: _buildDepartmentSection(),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: _buildElearningSection(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: _buildPeriodSection(),
          ),
          Container(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(label: '닫기', onTap: widget.onClose),
                const SizedBox(width: 8),
                _ActionButton(label: '초기화', onTap: _reset, outlined: true),
                const SizedBox(width: 8),
                _ActionButton(label: '검색', onTap: _doSearch, primary: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.body.copyWith(fontSize: 14),
        decoration: InputDecoration(
          hintText: '과목명, 교수명을 등을 검색해보세요',
          hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          prefixIcon:
              const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onSubmitted: (_) => _doSearch(),
      ),
    );
  }

  Widget _buildCourseTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('분류 (이수구분)',
            style: AppTextStyles.subtitle.copyWith(fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _FilterTag(
              label: '전체',
              selected: _selectedCourseType == null,
              onTap: () => setState(() => _selectedCourseType = null),
              showCheck: _selectedCourseType == null,
            ),
            ...FilterConstants.courseTypes.entries.map((e) => _FilterTag(
                  label: e.value,
                  selected: _selectedCourseType == e.key,
                  onTap: () => setState(() => _selectedCourseType =
                      _selectedCourseType == e.key ? null : e.key),
                  showCheck: _selectedCourseType == e.key,
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildYearLevelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('학년',
            style: AppTextStyles.subtitle.copyWith(fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _FilterTag(
              label: '전체',
              selected: _selectedYearLevel == null,
              onTap: () => setState(() => _selectedYearLevel = null),
              showCheck: _selectedYearLevel == null,
            ),
            ...FilterConstants.yearLevels.entries.map((e) => _FilterTag(
                  label: e.value,
                  selected: _selectedYearLevel == e.key,
                  onTap: () => setState(() => _selectedYearLevel =
                      _selectedYearLevel == e.key ? null : e.key),
                  showCheck: _selectedYearLevel == e.key,
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildDepartmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('학과',
            style: AppTextStyles.subtitle.copyWith(fontSize: 13)),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterTag(
                label: '전체',
                selected: _selectedDepartment == null,
                onTap: () => setState(() => _selectedDepartment = null),
                showCheck: _selectedDepartment == null,
              ),
              const SizedBox(width: 6),
              ..._departments.map((d) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _FilterTag(
                      label: d.name,
                      selected: _selectedDepartment == d.code,
                      onTap: () => setState(() => _selectedDepartment =
                          _selectedDepartment == d.code ? null : d.code),
                      showCheck: _selectedDepartment == d.code,
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildElearningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('수업 유형',
            style: AppTextStyles.subtitle.copyWith(fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _FilterTag(
              label: '전체',
              selected: _isElearning == null,
              onTap: () => setState(() => _isElearning = null),
              showCheck: _isElearning == null,
            ),
            _FilterTag(
              label: '대면',
              selected: _isElearning == false,
              onTap: () => setState(
                  () => _isElearning = _isElearning == false ? null : false),
              showCheck: _isElearning == false,
            ),
            _FilterTag(
              label: '이러닝',
              selected: _isElearning == true,
              onTap: () => setState(
                  () => _isElearning = _isElearning == true ? null : true),
              showCheck: _isElearning == true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('후기 기간',
            style: AppTextStyles.subtitle.copyWith(fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _FilterTag(
              label: '전체',
              selected: _selectedPeriod == null,
              onTap: () => setState(() => _selectedPeriod = null),
              showCheck: _selectedPeriod == null,
            ),
            ...FilterConstants.periods.entries.map((e) => _FilterTag(
                  label: e.value,
                  selected: _selectedPeriod == e.key,
                  onTap: () => setState(() => _selectedPeriod =
                      _selectedPeriod == e.key ? null : e.key),
                  showCheck: _selectedPeriod == e.key,
                )),
          ],
        ),
      ],
    );
  }
}

class _FilterTag extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showCheck;

  const _FilterTag({
    required this.label,
    required this.selected,
    required this.onTap,
    this.showCheck = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCheck && selected) ...[
              Icon(Icons.check_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.primary = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: outlined ? Border.all(color: AppColors.border) : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(
            fontSize: 13,
            color: primary ? AppColors.onPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class HomeSearchFilters {
  final String query;
  final String? courseType;
  final int? yearLevel;
  final bool? isElearning;
  final String? department;
  final String? period;

  const HomeSearchFilters({
    this.query = '',
    this.courseType,
    this.yearLevel,
    this.isElearning,
    this.department,
    this.period,
  });
}
