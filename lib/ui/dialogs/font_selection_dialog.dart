import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';

class FontSelectionDialog extends StatelessWidget {
  final DialogRequest request;
  final Function(DialogResponse) completer;

  const FontSelectionDialog({
    required this.request,
    required this.completer,
    super.key,
  });

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
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Japanese font',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Material(
                  color: Colors.transparent,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    onTap: () => completer(DialogResponse(data: false)),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: request.data
                              ? Colors.transparent
                              : Theme.of(context).brightness == Brightness.light
                                  ? Colors.black
                                  : Colors.white,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            '字',
                            style: TextStyle(
                              fontSize: 80,
                              height: 1,
                              fontFamily: 'NotoSansJP',
                            ),
                          ),
                          Text('Standard'),
                        ],
                      ),
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    onTap: () => completer(DialogResponse(data: true)),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: request.data
                              ? Theme.of(context).brightness == Brightness.light
                                  ? Colors.black
                                  : Colors.white
                              : Colors.transparent,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            '字',
                            style: TextStyle(
                              fontSize: 80,
                              height: 1,
                              fontFamily: 'NotoSansWithSerifJP',
                            ),
                          ),
                          Text('Alternative'),
                        ],
                      ),
                    ),
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
