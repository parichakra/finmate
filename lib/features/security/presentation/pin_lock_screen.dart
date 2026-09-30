import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../profile/providers/profile_providers.dart';

/// Shown at app start when isPinEnabled. Unlocks via 4-digit PIN
/// or falls back to the MMDD bypass key flow.
class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen>
    with SingleTickerProviderStateMixin {
  String _entered = '';
  String? _errorMsg;
  bool _isBypassMode = false;

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

  // ── label above dots ────────────────────────────────────────────────────
  String get _prompt =>
      _isBypassMode ? 'Enter bypass key\n(birth month + day  e.g. 0315)' : 'Enter PIN';

  // ── key length expected ─────────────────────────────────────────────────
  int get _expectedLen => 4;

  void _onDigit(String d) {
    if (_entered.length >= _expectedLen) return;
    HapticFeedback.lightImpact();
    setState(() {
      _entered += d;
      _errorMsg = null;
    });
    if (_entered.length == _expectedLen) _verify();
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _verify() async {
    final repo = ref.read(profileRepositoryProvider);
    bool ok;

    if (_isBypassMode) {
      ok = await repo.verifyBypassKey(_entered);
    } else {
      ok = await repo.verifyPin(_entered);
    }

    if (ok) {
      HapticFeedback.heavyImpact();
      ref.read(appLockStateProvider.notifier).unlock();
    } else {
      HapticFeedback.vibrate();
      await _shakeCtrl.forward(from: 0);
      setState(() {
        _entered = '';
        _errorMsg = _isBypassMode
            ? 'Incorrect bypass key. Try again.'
            : 'Incorrect PIN. Try again.';
      });
    }
  }

  void _toggleBypass() {
    setState(() {
      _isBypassMode = !_isBypassMode;
      _entered = '';
      _errorMsg = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // App icon / title
            const Icon(Icons.lock_outline_rounded, size: 48, color: AppTheme.primary),
            const SizedBox(height: 12),
            const Text(
              'FinMate',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // Prompt
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _prompt,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // PIN dots with shake animation
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
                children: List.generate(_expectedLen, (i) {
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
                        color: filled
                            ? AppTheme.primary
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Error message
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: _errorMsg != null ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                _errorMsg ?? '',
                style: TextStyle(color: AppTheme.expense, fontSize: 13),
              ),
            ),

            const Spacer(flex: 1),

            // Numpad
            _NumPad(onDigit: _onDigit, onDelete: _onDelete),

            const SizedBox(height: 16),

            // Forgot PIN / Back to PIN
            TextButton(
              onPressed: _toggleBypass,
              child: Text(
                _isBypassMode ? 'Back to PIN' : 'Forgot PIN?',
                style: const TextStyle(color: AppTheme.primary),
              ),
            ),

            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Numeric keypad widget
// ─────────────────────────────────────────────────────────────────────────────
class _NumPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _NumPad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const digits = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          ...digits.map(
            (row) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row
                  .map((d) => _DigitKey(label: d, onTap: () => onDigit(d)))
                  .toList(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72), // spacer left
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
  Widget build(BuildContext context) {
    return SizedBox(
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
}
