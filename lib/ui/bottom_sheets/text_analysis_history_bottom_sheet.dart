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
                  'Text Analysis History',
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
    } else if (snapshot.data!.isEmpty) {
      return Center(child: Text('No history'));
    } else {
      return ListView.separated(
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: 8,
          endIndent: 8,
        ),
        padding: EdgeInsets.zero,
        itemCount: snapshot.data!.length,
        itemBuilder: (context, index) {
          final current = snapshot.data![index];
          return Dismissible(
            key: ObjectKey(current),
            background: Container(color: Colors.red),
            onDismissed: (_) => deletedCallback(current),
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text(
                current.analysisText,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              onTap: () => completer(SheetResponse(data: current)),
            ),
          );
        },
      );
    }
  }
}
