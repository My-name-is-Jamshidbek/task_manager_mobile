import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Simple PIN/SMS code input with fixed length boxes.
class PinCodeField extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final String? initial;
  final bool autoFocus;

  const PinCodeField({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.initial,
    this.autoFocus = true,
  });

  @override
  State<PinCodeField> createState() => _PinCodeFieldState();
}

class _PinCodeFieldState extends State<PinCodeField> {
  late List<FocusNode> _nodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _nodes = List.generate(widget.length, (i) => FocusNode());
    _controllers = List.generate(widget.length, (i) => TextEditingController());
    if (widget.initial != null) {
      for (var i = 0; i < widget.initial!.length && i < widget.length; i++) {
        _controllers[i].text = widget.initial![i];
      }
    }
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _nodes.first.requestFocus());
    }
  }

  @override
  void dispose() {
    for (final n in _nodes) n.dispose();
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  void _notify() {
    final code = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(code);
    if (code.length == widget.length && !_controllers.any((c) => c.text.isEmpty)) {
      widget.onCompleted?.call(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) {
        return SizedBox(
          width: 46,
            child: TextField(
            controller: _controllers[i],
            focusNode: _nodes[i],
            autofocus: false,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
            keyboardType: TextInputType.number,
            maxLength: 1,
            decoration: const InputDecoration(
              counterText: '',
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) {
              if (val.length == 1 && i < widget.length - 1) {
                _nodes[i + 1].requestFocus();
              } else if (val.isEmpty && i > 0) {
                _nodes[i - 1].requestFocus();
              }
              _notify();
            },
          ),
        );
      }),
    );
  }
}
