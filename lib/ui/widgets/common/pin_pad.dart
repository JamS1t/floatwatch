import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// Reusable PIN entry pad used on all PIN entry screens.
///
/// Displays [pinLength] masked dots + a numeric keypad.
/// Calls [onComplete] when the full PIN has been entered.
/// Calls [onChanged] on every digit change (optional).
class PinPad extends StatefulWidget {
  final int pinLength;
  final void Function(String pin) onComplete;
  final void Function(String current)? onChanged;
  final String? errorMessage;
  final bool clearOnError;

  const PinPad({
    super.key,
    this.pinLength = AppConstants.pinLength,
    required this.onComplete,
    this.onChanged,
    this.errorMessage,
    this.clearOnError = true,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  @override
  void didUpdateWidget(PinPad old) {
    super.didUpdateWidget(old);
    if (widget.errorMessage != null &&
        widget.errorMessage != old.errorMessage &&
        widget.clearOnError) {
      setState(() => _pin = '');
    }
  }

  void _addDigit(String digit) {
    if (_pin.length >= widget.pinLength) return;
    setState(() => _pin += digit);
    widget.onChanged?.call(_pin);
    if (_pin.length == widget.pinLength) {
      widget.onComplete(_pin);
    }
  }

  void _removeDigit() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
    widget.onChanged?.call(_pin);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Dot indicators ────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.pinLength, (i) {
            final filled = i < _pin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: filled ? AppColors.primary : AppColors.inputBorder,
                  width: 2,
                ),
              ),
            );
          }),
        ),

        if (widget.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.errorMessage!,
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 32),

        // ── Keypad ────────────────────────────────────────────────────────
        ...List.generate(3, (row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (col) {
                final digit = (row * 3 + col + 1).toString();
                return _DigitKey(digit: digit, onTap: () => _addDigit(digit));
              }),
            ),
          );
        }),

        // Bottom row: empty | 0 | backspace
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80),
            _DigitKey(digit: '0', onTap: () => _addDigit('0')),
            SizedBox(
              width: 80,
              height: 64,
              child: IconButton(
                onPressed: _removeDigit,
                icon: const Icon(Icons.backspace_outlined, size: 24),
                color: AppColors.textPrimary,
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DigitKey extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;

  const _DigitKey({required this.digit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
