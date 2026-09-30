import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/user_profile.dart';
import '../../profile/providers/profile_providers.dart';

/// Lets the user set a 4-digit MMDD bypass key (birth month + birth day).
/// Pops with `true` on success.
class SetBypassKeyScreen extends ConsumerStatefulWidget {
  final UserProfile profile;
  const SetBypassKeyScreen({super.key, required this.profile});

  @override
  ConsumerState<SetBypassKeyScreen> createState() => _SetBypassKeyScreenState();
}

class _SetBypassKeyScreenState extends ConsumerState<SetBypassKeyScreen>
    with SingleTickerProviderStateMixin {
  // We use two separate 2-digit pickers (MM and DD) for clarity.
  final _monthCtrl = TextEditingController();
  final _dayCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscure = true;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 16).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  String? _validateMonth(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final n = int.tryParse(v);
    if (n == null || n < 1 || n > 12) return '01 – 12';
    return null;
  }

  String? _validateDay(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final n = int.tryParse(v);
    if (n == null || n < 1 || n > 31) return '01 – 31';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Zero-pad to 2 digits each
    final mm = _monthCtrl.text.trim().padLeft(2, '0');
    final dd = _dayCtrl.text.trim().padLeft(2, '0');
    final mmdd = '$mm$dd';

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.setBypassKey(widget.profile, mmdd);
      ref.invalidate(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bypass key saved')),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Bypass Key'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Explainer card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your bypass key is your birth month and birth day '
                        '(MMDD). For example, if you were born on March 15 '
                        'your bypass key is 0315.\n\n'
                        'Use this to reset your PIN if you forget it.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Birth Month (MM)',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
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
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _monthCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        obscureText: _obscure,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: '01 – 12',
                          counterText: '',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: _validateMonth,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '/',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w300),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _dayCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        obscureText: _obscure,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: '01 – 31',
                          counterText: '',
                          labelText: 'Day (DD)',
                        ),
                        validator: _validateDay,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Text(
                'This key is stored securely on your device only.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Bypass Key'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
