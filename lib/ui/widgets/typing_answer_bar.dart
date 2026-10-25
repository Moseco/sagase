import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sagase/utils/hiragana_input_formatter.dart';
import 'package:sagase/utils/romaji_converter.dart';

/// Text field with a submit button used by typing based practice tools.
///
/// When [convertToHiragana] is true, romaji is converted to hiragana while the
/// user types and the answer passed to [onSubmit] is fully converted.
/// While [showingAnswer] is true the input is locked and shown in green if
/// [answerCorrect] or red otherwise, and the submit button changes to a next
/// button. If [onRetry] is provided, deleting text while a wrong answer is
/// shown clears the input and calls it so that a typo can be corrected.
class TypingAnswerBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String answer) onSubmit;
  final bool showingAnswer;
  final bool answerCorrect;
  final void Function()? onRetry;
  final bool convertToHiragana;
  final String? hintText;

  const TypingAnswerBar({
    required this.controller,
    required this.onSubmit,
    this.showingAnswer = false,
    this.answerCorrect = false,
    this.onRetry,
    this.convertToHiragana = false,
    this.hintText,
    super.key,
  });

  void _submit() {
    if (convertToHiragana && !showingAnswer) {
      final finalized = romajiToHiragana(controller.text, finalize: true);
      if (finalized != controller.text) {
        controller.value = TextEditingValue(
          text: finalized,
          selection: TextSelection.collapsed(offset: finalized.length),
        );
      }
    }
    onSubmit(controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final answerColor = answerCorrect ? Colors.green : Colors.red;

    return Card(
      elevation: 8,
      margin: EdgeInsets.only(
        left: 8,
        right: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom * 1.2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _submit,
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (!showingAnswer) return newValue;
                      if (onRetry != null &&
                          !answerCorrect &&
                          newValue.text.length < oldValue.text.length) {
                        onRetry!();
                        return TextEditingValue.empty;
                      }
                      return oldValue;
                    }),
                    if (convertToHiragana) const HiraganaInputFormatter(),
                  ],
                  showCursor: !showingAnswer,
                  style: showingAnswer ? TextStyle(color: answerColor) : null,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: _submit,
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: showingAnswer ? answerColor : Colors.green,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
                child: Icon(
                  showingAnswer ? Icons.arrow_forward : Icons.check,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
