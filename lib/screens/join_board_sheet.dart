import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:teamtask/app_theme.dart';
import 'package:teamtask/board_provider.dart';

class JoinBoardSheet extends ConsumerStatefulWidget {
  const JoinBoardSheet({super.key});

  @override
  ConsumerState<JoinBoardSheet> createState() => _JoinBoardSheetState();
}

class _JoinBoardSheetState extends ConsumerState<JoinBoardSheet> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Ingresa el código de invitación');
      return;
    }
    if (code.length != 6) {
      setState(() => _error = 'El código debe tener 6 caracteres');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final board = await ref.read(joinBoardProvider).call(code);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Te uniste a "${board.name}"! ${board.emoji}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 20, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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

          // Título
          const Text(
            'Unirse a un tablero',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ).animate().fadeIn(),
          const Gap(6),
          Text(
            'Ingresa el código que te compartió el dueño del tablero',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ).animate().fadeIn(delay: 50.ms),

          const Gap(24),

          // Campo de código
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            ],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'ABC123',
              hintStyle: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
                color: Colors.grey.shade300,
              ),
              counterText: '',
              errorText: _error,
            ),
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _join(),
          ).animate().fadeIn(delay: 100.ms),

          const Gap(24),

          // Botón
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _join,
              child: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white,
                      ),
                    )
                  : const Text('Unirse al tablero'),
            ),
          ).animate().fadeIn(delay: 150.ms),
        ],
      ),
    );
  }
}