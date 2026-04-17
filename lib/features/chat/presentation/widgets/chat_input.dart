import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

typedef OnSend = Future<bool> Function(String text);

class ChatInput extends StatefulWidget {
  final OnSend onSend;
  final bool busy;
  final bool enabled;

  static const int maxLength = 500;

  const ChatInput({
    super.key,
    required this.onSend,
    this.busy = false,
    this.enabled = true,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final ok = await widget.onSend(text);
    if (!mounted) return;
    if (ok) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled || widget.busy;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.divider.withValues(alpha: 0.4)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                enabled: widget.enabled,
                minLines: 1,
                maxLines: 4,
                maxLength: ChatInput.maxLength,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => disabled ? null : _handleSend(),
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje',
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            IconButton(
              onPressed: disabled ? null : _handleSend,
              icon: widget.busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: AppColors.primary),
              tooltip: 'Enviar',
            ),
          ],
        ),
      ),
    );
  }
}
