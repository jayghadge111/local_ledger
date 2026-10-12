import '../../core/responsive/adaptive_scale.dart';
import '../../core/ui/haptics.dart';

import 'package:flutter/material.dart';

/// A simple numeric PIN pad: dot indicators for entered digits plus a
/// 0-9 + backspace keypad. Calls [onSubmitted] once [length] digits have
/// been entered.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.length,
    required this.onSubmitted,
    this.errorText,
  });

  final int length;
  final ValueChanged<String> onSubmitted;
  final String? errorText;

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> {
  String _value = '';

  void clear() => setState(() => _value = '');

  void _onKey(String digit) {
    if (_value.length >= widget.length) return;
    setState(() => _value += digit);
    if (_value.length == widget.length) {
      final submitted = _value;
      widget.onSubmitted(submitted);
    }
  }

  void _onBackspace() {
    if (_value.isEmpty) return;
    setState(() => _value = _value.substring(0, _value.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = focusedBoost(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (i) {
            final filled = i < _value.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              margin: EdgeInsets.symmetric(horizontal: 10 * b),
              width: (filled ? 20 : 18) * b,
              height: (filled ? 20 : 18) * b,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? theme.colorScheme.secondary
                    : Colors.transparent,
                border: Border.all(
                  color: filled
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                  width: 1.5,
                ),
              ),
            );
          }),
        ),
        if (widget.errorText != null) ...[
          SizedBox(height: 14 * b),
          Text(
            widget.errorText!,
            style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
          ),
        ],
        SizedBox(height: 36 * b),
        _Keypad(onDigit: _onKey, onBackspace: _onBackspace),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  static const _buttonSize = 76.0;

  /// The key size, bigger on a tablet.
  static double sizeFor(BuildContext context) =>
      _buttonSize * focusedBoost(context);

  @override
  Widget build(BuildContext context) {
    final size = sizeFor(context);
    final gap = 18 * focusedBoost(context);
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final d in row) ...[
                  _KeypadButton(
                    label: d,
                    onTap: () {
                      Haptics.tap();
                      onDigit(d);
                    },
                  ),
                  if (d != row.last) SizedBox(width: gap),
                ],
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: size, height: size),
              SizedBox(width: gap),
              _KeypadButton(
                label: '0',
                onTap: () {
                  Haptics.tap();
                  onDigit('0');
                },
              ),
              SizedBox(width: gap),
              SizedBox(
                width: size,
                height: size,
                child: IconButton(
                  tooltip: 'Delete',
                  onPressed: onBackspace,
                  icon: Icon(
                    Icons.backspace_outlined,
                    size: 24 * focusedBoost(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = _Keypad.sizeFor(context);
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              // Grows with the screen's FocusedBoost text scaling.
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
