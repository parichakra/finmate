import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/user_profile.dart';
import '../../profile/providers/profile_providers.dart';

/// Two-step PIN setup: enter → confirm.
/// Pass the current [UserProfile] via route extra.
/// On success pops with `true` so the caller can update the profile reload.
class SetupPinScreen extends ConsumerStatefulWidget {
  final UserProfile profile;
  const SetupPinScreen({super.key, required this.profile});

  @override
  ConsumerState<SetupPinScreen> createState() => _SetupPinScreenState();
}

enum _Step { enter, confirm }

class _SetupPinScreenState extends ConsumerState<SetupPinScreen>
    with SingleTickerProviderStateMixin {
  _Step _step = _Step.enter;
  String _first = '';
  String _entered = '';
  bool _isLoading = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 24).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  String get _prompt => _step == _Step.enter
      ? 'Set a 4-digit PIN'
      : 'Confirm your PIN';

  void _onDigit(String d) {
    if (_entered.length >= 4 || _isLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _entered += d);
    if (_entered.length == 4) _advance();
  }

  void _onDelete() {
    if (_entered.isEmpty || _isLoading) return;
    HapticFeedback.selectionClick();
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _advance() async {
    if (_step == _Step.enter) {
      setState(() {
        _first = _entered;
        _entered = '';
        _step = _Step.confirm;
      });
      return;
    }

    // Confirm step
    if (_entered != _first) {
      HapticFeedback.vibrate();
      await _shakeCtrl.forward(from: 0);
      setState(() {
        _entered = '';
        _first = '';
        _step = _Step.enter;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PINs did not match. Please try again.'),
          ),
        );
      }
      return;
    }

    // PINs match → save
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.setPin(widget.profile, _entered);
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN set successfully')),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() {
          _entered = '';
          _first = '';
          _step = _Step.enter;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set PIN'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(false),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Step indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepDot(filled: true),
                const SizedBox(width: 8),
                _StepDot(filled: _step == _Step.confirm),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              _prompt,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _step == _Step.enter
                  ? 'This PIN will be required every time you open the app.'
                  : 'Re-enter the PIN to confirm.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            // PIN dots
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(
                  _shakeCtrl.isAnimating
                      ? (_shakeAnim.value *
                          ((_shakeCtrl.value < 0.5) ? 1 : -1))
                      : 0,
                  0,
                ),
                child: child,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _entered.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppTheme.primary : Colors.transparent,
                      border: Border.all(
                        color:
                            filled ? AppTheme.primary : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),

            const Spacer(flex: 1),

            _isLoading
                ? const CircularProgressIndicator()
                : _NumPad(onDigit: _onDigit, onDelete: _onDelete),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool filled;
  const _StepDot({required this.filled});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? AppTheme.primary : Colors.grey.shade300,
        ),
      );
}

// ── Shared NumPad (same as PinLockScreen) ────────────────────────────────────
class _NumPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  const _NumPad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          ...rows.map((row) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row
                    .map((d) => _DigitKey(label: d, onTap: () => onDigit(d)))
                    .toList(),
              )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72),
              _DigitKey(label: '0', onTap: () => onDigit('0')),
              SizedBox(
                width: 72,
                height: 72,
                child: IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.backspace_outlined),
                  iconSize: 26,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DigitKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DigitKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 72,
        height: 72,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Colors.grey.shade100,
            foregroundColor: const Color(0xFF0F172A),
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: Text(label),
        ),
      );
}
