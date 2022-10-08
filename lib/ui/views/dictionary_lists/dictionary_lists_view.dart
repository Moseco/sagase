import 'package:flutter/material.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/ui/widgets/home_header.dart';
import 'package:stacked/stacked.dart';

import 'dictionary_lists_viewmodel.dart';

class DictionaryListsView extends StatelessWidget {
  const DictionaryListsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DictionaryListsViewModel>.reactive(
      disposeViewModel: false,
      initialiseSpecialViewModelsOnce: true,
      viewModelBuilder: () => locator<DictionaryListsViewModel>(),
      builder: (context, viewModel, child) => Scaffold(
        body: HomeHeader(
          title: const Text(
            'Lists',
            maxLines: 1,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MainListItem(
                leadingText: '語',
                titleText: 'Vocabulary',
                onTap: () {},
              ),
              _MainListItem(
                leadingText: '字',
                titleText: 'Kanji',
                onTap: () {},
              ),
              _MainListItem(
                leadingText: '廴',
                titleText: 'Radicals',
                onTap: viewModel.navigateToRadicals,
              ),
              _MainListItem(
                leadingIcon: Icons.star,
                titleText: 'My lists',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainListItem extends StatelessWidget {
  final String? leadingText;
  final IconData? leadingIcon;
  final String titleText;
  final void Function() onTap;

  const _MainListItem({
    this.leadingText,
    this.leadingIcon,
    required this.titleText,
    required this.onTap,
    Key? key,
  })  : assert(leadingText != null || leadingIcon != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple,
                ),
                child: Center(
                  child: leadingIcon != null
                      ? Icon(
                          leadingIcon,
                          color: Colors.white,
                        )
                      : Text(
                          leadingText!,
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    titleText,
                    style: const TextStyle(fontSize: 24),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
