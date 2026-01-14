import 'dart:async';

import 'package:dayly/models/dayly_widget_model.dart';
import 'package:dayly/screens/add_widget_bottom_sheet.dart';
import 'package:dayly/screens/share_preview_screen_v2.dart';
import 'package:dayly/storage/dayly_widget_storage.dart';
import 'package:dayly/widgets/dayly_widget_card.dart';
import 'package:flutter/material.dart';

/// Widget-first gallery.
///
/// Rule alignment:
/// - Each tile represents ONE widget (ONE active D-Day per widget).
/// - Tap a widget -> open Share Preview (no generic dashboard flow).
class WidgetGridScreen extends StatefulWidget {
  const WidgetGridScreen({super.key});

  @override
  State<WidgetGridScreen> createState() => _WidgetGridScreenState();
}

class _WidgetGridScreenState extends State<WidgetGridScreen> {
  var _isLoading = true;
  List<DaylyWidgetModel> _widgets = const <DaylyWidgetModel>[];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final loaded = await loadDaylyWidgets();
    if (!mounted) return;
    setState(() {
      _widgets = loaded.isEmpty ? <DaylyWidgetModel>[DaylyWidgetModel.defaults()] : loaded;
      _isLoading = false;
    });
  }

  Future<void> _persist() async {
    await saveDaylyWidgets(_widgets);
  }

  Future<void> _openSharePreview(int index) async {
    final model = _widgets[index];
    final updated = await Navigator.of(context).push<DaylyWidgetModel>(
      MaterialPageRoute(
        builder: (_) => SharePreviewScreenV2(initialModel: model),
      ),
    );
    if (updated == null) return;
    setState(() => _widgets[index] = updated);
    unawaited(_persist());
  }

  void _addWidget() {
    unawaited(_openAddWidgetSheet());
  }

  Future<void> _openAddWidgetSheet() async {
    final created = await showAddWidgetBottomSheet(context: context);
    if (created == null) return;
    setState(() => _widgets.add(created));
    unawaited(_persist());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('dayly'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWidget,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
            itemCount: _widgets.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2x2 placement
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openSharePreview(index),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isTinyTile =
                          constraints.maxWidth < 160 || constraints.maxHeight < 160;
                      return DaylyWidgetCard(
                        model: _widgets[index],
                        size: isTinyTile ? DaylyWidgetSize.small : DaylyWidgetSize.medium,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

