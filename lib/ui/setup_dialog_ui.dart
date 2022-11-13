import 'package:flutter/material.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:stacked_services/stacked_services.dart';

void setupDialogUi() {
  final dialogService = locator<DialogService>();

  final builders = {
    DialogType.form: (context, sheetRequest, completer) =>
        _FormDialog(sheetRequest, completer),
  };

  dialogService.registerCustomDialogBuilders(builders);
}

// ignore: must_be_immutable
class _FormDialog extends StatelessWidget {
  final DialogRequest request;
  final Function(DialogResponse) completer;

  String textInput = '';

  _FormDialog(
    this.request,
    this.completer, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                request.title!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TextFormField(
                initialValue: request.data,
                autofocus: true,
                onChanged: (value) => textInput = value,
                decoration: InputDecoration(hintText: request.description!),
              ),
            ),
            GestureDetector(
              onTap: () => completer(DialogResponse(data: textInput)),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  request.mainButtonTitle!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

enum DialogType {
  form,
}
