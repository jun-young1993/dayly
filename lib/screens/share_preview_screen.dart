import 'dart:async';

import 'package:dayly/models/dayly_widget_model.dart';
import 'package:dayly/utils/dayly_sentence_templates.dart';
import 'package:dayly/utils/dayly_share_export.dart';
import 'package:dayly/widgets/dayly_widget_card.dart';
import 'package:flutter/material.dart';

class SharePreviewScreen extends StatefulWidget {
  const SharePreviewScreen({
    super.key,
    required this.initialModel,
  });

  final DaylyWidgetModel initialModel;

  @override
  State<SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends State<SharePreviewScreen> {
  final GlobalKey _captureKey = GlobalKey();
  late DaylyWidgetModel _model;
  var _isSharing = false;

  @override
  void initState() {
    super.initState();
    _model = widget.initialModel;
  }

  Future<void> _shareCurrentPreview() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      // Ensure a frame is painted before capture.
      await Future<void>.delayed(const Duration(milliseconds: 16));
      final pngBytes = await captureBoundaryPng(boundaryKey: _captureKey);
      await sharePngBytes(
        pngBytes: pngBytes,
        fileName: 'dayly-share.png',
        text: 'dayly',
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('share failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공유에 실패했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _editSentence() async {
    final controller = TextEditingController(text: _model.primarySentence);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                '문장 수정',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '날짜가 아니라, “왜 중요한지”를 말해 주세요. (최대 2줄)',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '예) 우리는 다시 만날 때까지 23일',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                child: const Text('적용'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (result == null) return;
    if (result.isEmpty) return;
    setState(() => _model = _model.copyWith(primarySentence: result));
  }

  Future<void> _openTemplateGenerator() async {
    final request = await showModalBottomSheet<DaylyTemplateRequest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _TemplateSheet(
          initialDayDiff: DateTime.now().toLocal().difference(_model.targetDate.toLocal()).inDays * -1,
          initialCountdownMode: _model.style.countdownMode,
        );
      },
    );

    if (request == null) return;
    final sentence = generateDaylySentence(request);
    if (sentence.trim().isEmpty) return;
    setState(() => _model = _model.copyWith(primarySentence: sentence.trim()));
  }

  Future<void> _editTargetDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _model.targetDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 30),
    );
    if (picked == null) return;
    setState(() => _model = _model.copyWith(targetDate: picked));
  }

  Future<void> _pickCountdownMode() async {
    final picked = await showModalBottomSheet<DaylyCountdownMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  '표현 방식',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
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
                    final isSelected = _model.style.countdownMode == mode;
                    return ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (_) => Navigator.of(context).pop(mode),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null) return;
    setState(() => _model = _model.copyWith(style: _model.style.copyWith(countdownMode: picked)));
  }

  void _togglePremium() {
    final nextPremium = !_model.style.isPremium;
    setState(
      () => _model = _model.copyWith(
        style: _model.style.copyWith(
          isPremium: nextPremium,
          // If premium, watermark will be hidden by rendering logic.
        ),
      ),
    );
  }

  void _toggleDivider() {
    setState(() => _model = _model.copyWith(style: _model.style.copyWith(showDivider: !_model.style.showDivider)));
  }

  @override
  Widget build(BuildContext context) {
    final canShare = !_isSharing;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_model);
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Share Preview'),
        leading: IconButton(
          tooltip: '뒤로',
          onPressed: () => Navigator.of(context).pop(_model),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: '공유',
            onPressed: canShare ? _shareCurrentPreview : null,
            icon: _isSharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              // Preview area (matches widget visual exactly)
              Expanded(
                child: Center(
                  child: RepaintBoundary(
                    key: _captureKey,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: DaylyWidgetCard(
                        model: _model,
                        size: DaylyWidgetSize.large,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Quick controls (app exists to configure and share the widget)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: _openTemplateGenerator,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('템플릿'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _editSentence,
                    icon: const Icon(Icons.edit_note),
                    label: const Text('문장'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _editTargetDate,
                    icon: const Icon(Icons.event),
                    label: const Text('날짜'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickCountdownMode,
                    icon: const Icon(Icons.numbers),
                    label: const Text('표현'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _toggleDivider,
                    icon: const Icon(Icons.more_horiz),
                    label: Text(_model.style.showDivider ? '디바이더 On' : '디바이더 Off'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _togglePremium,
                    icon: const Icon(Icons.workspace_premium),
                    label: Text(_model.style.isPremium ? 'Premium' : 'Free'),
                  ),
                  FilledButton.icon(
                    onPressed: canShare ? _shareCurrentPreview : null,
                    icon: const Icon(Icons.ios_share),
                    label: const Text('공유하기'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _TemplateSheet extends StatefulWidget {
  const _TemplateSheet({
    required this.initialDayDiff,
    required this.initialCountdownMode,
  });

  final int initialDayDiff;
  final DaylyCountdownMode initialCountdownMode;

  @override
  State<_TemplateSheet> createState() => _TemplateSheetState();
}

class _TemplateSheetState extends State<_TemplateSheet> {
  var _relationship = DaylyRelationshipType.couple;
  var _tone = DaylyTone.calm;
  late DaylyCountdownMode _mode;
  final _eventController = TextEditingController(text: '결혼식');

  @override
  void initState() {
    super.initState();
    _mode = widget.initialCountdownMode;
  }

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = DaylyTemplateRequest(
      relationshipType: _relationship,
      tone: _tone,
      eventLabel: _eventController.text,
      dayDiff: widget.initialDayDiff,
      countdownMode: _mode,
    );
    final preview = generateDaylySentence(request);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              '문장 템플릿',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('숫자 대신 “문장”을 고르는 경험을 만들어요.'),
            const SizedBox(height: 14),
            _SectionLabel(text: '관계'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <_ChipSpec<DaylyRelationshipType>>[
                _ChipSpec(DaylyRelationshipType.couple, '커플'),
                _ChipSpec(DaylyRelationshipType.family, '가족'),
                _ChipSpec(DaylyRelationshipType.solo, '혼자'),
                _ChipSpec(DaylyRelationshipType.goal, '목표'),
              ].map((spec) {
                return ChoiceChip(
                  label: Text(spec.label),
                  selected: _relationship == spec.value,
                  onSelected: (_) => setState(() => _relationship = spec.value),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            _SectionLabel(text: '톤'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <_ChipSpec<DaylyTone>>[
                _ChipSpec(DaylyTone.calm, '담백'),
                _ChipSpec(DaylyTone.flutter, '설렘'),
                _ChipSpec(DaylyTone.longing, '애틋'),
                _ChipSpec(DaylyTone.playful, '장난'),
              ].map((spec) {
                return ChoiceChip(
                  label: Text(spec.label),
                  selected: _tone == spec.value,
                  onSelected: (_) => setState(() => _tone = spec.value),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            _SectionLabel(text: '표현 방식'),
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
                  DaylyCountdownMode.hidden => '숨김',
                };
                return ChoiceChip(
                  label: Text(label),
                  selected: _mode == mode,
                  onSelected: (_) => setState(() => _mode = mode),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            _SectionLabel(text: '이벤트(선택)'),
            const SizedBox(height: 8),
            TextField(
              controller: _eventController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '예) 결혼식 / 전역 / 시험 / 여행',
              ),
            ),
            const SizedBox(height: 14),
            _SectionLabel(text: '미리보기'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(preview, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(request),
              child: const Text('이 문장 적용'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700),
    );
  }
}

class _ChipSpec<T> {
  const _ChipSpec(this.value, this.label);
  final T value;
  final String label;
}
