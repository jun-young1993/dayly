import 'package:dayly/models/dayly_widget_model.dart';
import 'package:dayly/theme/dayly_theme_presets.dart';
import 'package:flutter/material.dart';

/// Bottom sheet for creating a new D-Day widget.
///
/// Minimal by design:
/// - Date (default: today)
/// - Sentence (why it matters)
/// - Theme preset
/// - Expression mode
Future<DaylyWidgetModel?> showAddWidgetBottomSheet({
  required BuildContext context,
}) {
  return showModalBottomSheet<DaylyWidgetModel>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _AddWidgetSheet(),
  );
}

class _AddWidgetSheet extends StatefulWidget {
  const _AddWidgetSheet();

  @override
  State<_AddWidgetSheet> createState() => _AddWidgetSheetState();
}

class _AddWidgetSheetState extends State<_AddWidgetSheet> {
  final _sentenceController = TextEditingController();
  late DateTime _targetDate;
  var _themePreset = DaylyThemePreset.night;
  var _countdownMode = DaylyCountdownMode.days;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toLocal();
    _targetDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _sentenceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 30),
    );
    if (picked == null) return;
    setState(() => _targetDate = picked);
  }

  void _submit() {
    final sentence = _sentenceController.text.trim();
    if (sentence.isEmpty) return;

    final base = DaylyWidgetStyle.defaults();
    final style = base.copyWith(
      themePreset: _themePreset,
      background: backgroundForTheme(_themePreset),
      countdownMode: _countdownMode,
      numberFormat: _countdownMode == DaylyCountdownMode.dMinus
          ? DaylyNumberFormat.dMinus
          : DaylyNumberFormat.daysSuffix,
    );

    Navigator.of(context).pop(
      DaylyWidgetModel(
        primarySentence: sentence,
        targetDate: _targetDate,
        style: style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canSubmit = _sentenceController.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: bottomInset + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            '새 D-Day 위젯',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text('캘린더가 아니라 “왜 중요한지”를 한 문장으로 남겨요.'),
          const SizedBox(height: 14),

          const _SectionLabel(text: '날짜'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event),
            label: Text('${_targetDate.year}.${_targetDate.month.toString().padLeft(2, '0')}.${_targetDate.day.toString().padLeft(2, '0')}'),
          ),

          const SizedBox(height: 14),
          const _SectionLabel(text: '문장'),
          const SizedBox(height: 8),
          TextField(
            controller: _sentenceController,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '예) 우리는 다시 만날 때까지 23일',
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 14),
          const _SectionLabel(text: '테마'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DaylyThemePreset.values.map((preset) {
              return ChoiceChip(
                label: Text(daylyThemeLabel(preset)),
                selected: _themePreset == preset,
                avatar: CircleAvatar(
                  radius: 8,
                  backgroundColor: previewColorForTheme(preset),
                ),
                onSelected: (_) => setState(() => _themePreset = preset),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),
          const _SectionLabel(text: '표현 방식'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DaylyCountdownMode.values.map((mode) {
              final label = switch (mode) {
                DaylyCountdownMode.days => '23일',
                DaylyCountdownMode.dMinus => 'D-23',
                DaylyCountdownMode.weeksDays => '3주 2일',
                DaylyCountdownMode.mornings => '42번의 아침',
                DaylyCountdownMode.nights => '42번의 밤',
                DaylyCountdownMode.hidden => '숫자 숨김',
              };
              return ChoiceChip(
                label: Text(label),
                selected: _countdownMode == mode,
                onSelected: (_) => setState(() => _countdownMode = mode),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          FilledButton(
            onPressed: canSubmit ? _submit : null,
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w700));
  }
}

