import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class PercentIndicatorDialog extends StatefulWidget {
  final DialogRequest request;
  final Function(DialogResponse) completer;

  const PercentIndicatorDialog({
    required this.request,
    required this.completer,
    super.key,
  });

  @override
  State<PercentIndicatorDialog> createState() => _PercentIndicatorDialogState();
}

class _PercentIndicatorDialogState extends State<PercentIndicatorDialog> {
  double _downloadStatus = 0;

  @override
  initState() {
    super.initState();

    widget.request.data.listen((double event) {
      double newStatus = (event * 100).floorToDouble() / 100;
      if (newStatus != _downloadStatus) {
        setState(() {
          _downloadStatus = _downloadStatus = newStatus;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.request.title!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: CircularPercentIndicator(
                radius: 40,
                lineWidth: 8,
                animation: true,
                animateFromLastPercent: true,
                percent: _downloadStatus,
                center: Text(
                  "${(_downloadStatus * 100).toInt()}%",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
