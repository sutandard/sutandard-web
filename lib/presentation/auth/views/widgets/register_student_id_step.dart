import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../common/widgets/sutandard_button.dart';
import '../../../common/widgets/sutandard_text_field.dart';
import '../../viewmodels/register_viewmodel.dart';

class RegisterStudentIdStep extends ConsumerStatefulWidget {
  const RegisterStudentIdStep({super.key});

  @override
  ConsumerState<RegisterStudentIdStep> createState() =>
      _RegisterStudentIdStepState();
}

class _RegisterStudentIdStepState
    extends ConsumerState<RegisterStudentIdStep> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentId = ref.read(registerViewModelProvider).studentId;
    if (currentId.isNotEmpty) {
      _controller.text = currentId;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerViewModelProvider);
    final vm = ref.read(registerViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '학번을 입력해주세요.',
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: 8),
        Text(
          '수원대학교 학번을 입력해주세요.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 32),
        SutandardTextField(
          controller: _controller,
          label: '학번',
          hint: '학번을 입력해주세요.',
          keyboardType: TextInputType.number,
          errorText: state.error,
          onChanged: (v) => vm.setStudentId(v.trim()),
        ),
        const SizedBox(height: 40),
        SutandardButton(
          label: '다음',
          onPressed: _controller.text.trim().isNotEmpty
              ? () => vm.goToPortalAuth()
              : null,
        ),
      ],
    );
  }
}
