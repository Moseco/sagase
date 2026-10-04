import 'package:flutter/material.dart';
import 'package:sagase/ui/bottom_sheets/base_bottom_sheet.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked_services/stacked_services.dart';

class TextAnalysisHistoryBottomSheet extends StatelessWidget {
  final SheetRequest request;
  final Function(SheetResponse) completer;

  const TextAnalysisHistoryBottomSheet({
    required this.request,
    required this.completer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final historyFuture = request.data.$1;
    final deletedCallback = request.data.$2;

    return BaseBottomSheet(
      child: FutureBuilder(
        future: historyFuture,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<TextAnalysisHistoryItem>> snapshot,
        ) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Text(
                  'Text analysis history',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _Content(
                  snapshot: snapshot,
                  deletedCallback: deletedCallback,
                  completer: completer,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final AsyncSnapshot<List<TextAnalysisHistoryItem>> snapshot;
  final void Function(TextAnalysisHistoryItem) deletedCallback;
  final Function(SheetResponse) completer;

  const _Content({
    required this.snapshot,
    required this.deletedCallback,
    required this.completer,
  });

  @override
  Widget build(BuildContext context) {
    if (!snapshot.hasData) {
      return Center(child: CircularProgressIndicator());
    } else {
      return _HistoryList(
        items: snapshot.data!,
        deletedCallback: deletedCallback,
        completer: completer,
      );
    }
  }
}

class _HistoryList extends StatefulWidget {
  final List<TextAnalysisHistoryItem> items;
  final void Function(TextAnalysisHistoryItem) deletedCallback;
  final Function(SheetResponse) completer;

  const _HistoryList({
    required this.items,
    required this.deletedCallback,
    required this.completer,
  });

  @override
  State<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<_HistoryList> {
  late final List<TextAnalysisHistoryItem> _items = List.of(widget.items);

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Center(child: Text('No history'));
    }

    return ListView.separated(
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 8,
        endIndent: 8,
      ),
      padding: EdgeInsets.zero,
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final current = _items[index];
        return Dismissible(
          key: ObjectKey(current),
          background: Container(color: Colors.red),
          onDismissed: (_) {
            setState(() => _items.remove(current));
            widget.deletedCallback(current);
          },
          child: ListTile(
            title: Text(
              current.analysisText,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            onTap: () => widget.completer(SheetResponse(data: current)),
          ),
        );
      },
    );
  }
}
