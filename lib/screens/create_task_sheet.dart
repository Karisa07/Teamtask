import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:teamtask/board_provider.dart';
import 'package:teamtask/app_theme.dart';

class CreateTaskSheet extends ConsumerStatefulWidget {
  final String boardId;
  const CreateTaskSheet({super.key, required this.boardId});

  @override
  ConsumerState<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<CreateTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'medium';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(taskActionsProvider(widget.boardId)).createTask(
            title: _titleController.text.trim(),
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            priority: _priority,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(20),
          const Text(
            'Nueva tarea',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const Gap(20),
          TextField(
            controller: _titleController,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Título *',
              prefixIcon: Icon(Icons.task_outlined),
            ),
          ),
          const Gap(12),
          TextField(
            controller: _descController,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
              prefixIcon: Icon(Icons.notes),
              alignLabelWithHint: true,
            ),
          ),
          const Gap(20),
          const Text('Prioridad',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const Gap(10),
          Row(
            children: [
              _PriorityOption(
                label: 'Baja',
                value: 'low',
                color: AppTheme.successColor,
                selected: _priority == 'low',
                onTap: () => setState(() => _priority = 'low'),
              ),
              const Gap(8),
              _PriorityOption(
                label: 'Media',
                value: 'medium',
                color: AppTheme.warningColor,
                selected: _priority == 'medium',
                onTap: () => setState(() => _priority = 'medium'),
              ),
              const Gap(8),
              _PriorityOption(
                label: 'Alta',
                value: 'high',
                color: AppTheme.errorColor,
                selected: _priority == 'high',
                onTap: () => setState(() => _priority = 'high'),
              ),
            ],
          ),
          const Gap(24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _create,
              child: _isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Crear tarea'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityOption extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityOption({
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.flag, size: 18,
                  color: selected ? color : Colors.grey.shade400),
              const Gap(4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}