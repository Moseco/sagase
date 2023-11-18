import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/stroke_order_diagram_large.dart';
import 'package:stacked_services/stacked_services.dart';

class StrokeOrderBottomSheet extends StatefulWidget {
  final SheetRequest request;
  final Function(SheetResponse) completer;

  const StrokeOrderBottomSheet({
    required this.request,
    required this.completer,
    super.key,
  });

  @override
  State<StrokeOrderBottomSheet> createState() => StrokeOrderBottomSheetState();
}

class StrokeOrderBottomSheetState extends State<StrokeOrderBottomSheet> {
  int page = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: StrokeOrderDiagramLarge(
                    strokes: widget.request.data,
                    page: page,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_left),
                    onPressed: () => setState(() {
                      page = (page - 1)
                          .clamp(0, widget.request.data.length - 1)
                          .toInt();
                    }),
                  ),
                ),
                Text('${page + 1}/${widget.request.data.length}'),
                Expanded(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_right),
                    onPressed: () => setState(() {
                      page = (page + 1)
                          .clamp(0, widget.request.data.length - 1)
                          .toInt();
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
