import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'about_viewmodel.dart';

class AboutView extends StackedView<AboutViewModel> {
  const AboutView({super.key});

  @override
  AboutViewModel viewModelBuilder(context) => AboutViewModel();

  @override
  Widget builder(context, viewModel, child) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/icon.png',
                  width: 100,
                  height: 100,
                ),
              ),
              const Text(
                'Sagase',
                style: TextStyle(fontSize: 24),
              ),
              const Text('1.1.0'),
              const SizedBox(height: 16),
              Text.rich(
                textAlign: TextAlign.left,
                TextSpan(
                  children: [
                    // Introduction
                    const TextSpan(
                      text:
                          'Sagase is built using data from several amazing projects. Thank you to the projects and the people working on them for making Sagase possible. Below is a list of the projects and data used.\n\n',
                    ),
                    // EDRDG
                    TextSpan(
                      text:
                          'Electronic Dictionary Research and Development Group',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap =
                            () => viewModel.openUrl(r'https://www.edrdg.org'),
                    ),
                    const TextSpan(
                      text:
                          ' manages the source dictionary files for the vocab and kanji.\n\n',
                    ),
                    // Tatoeba
                    TextSpan(
                      text: 'Tatoeba',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap =
                            () => viewModel.openUrl(r'https://tatoeba.org'),
                    ),
                    const TextSpan(
                      text:
                          ' manages the Japanese-English example sentence pairs.\n\n',
                    ),
                    // KanjiVG
                    const TextSpan(
                      text: 'The ',
                    ),
                    TextSpan(
                      text: 'KanjiVG project',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () =>
                            viewModel.openUrl(r'https://kanjivg.tagaini.net'),
                    ),
                    const TextSpan(
                      text:
                          ' manages stroke order and component information.\n\n',
                    ),

                    // MeCab
                    TextSpan(
                      text: 'MeCab',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => viewModel
                            .openUrl(r'https://taku910.github.io/mecab'),
                    ),
                    const TextSpan(
                      text: ' is a Japanese text analyzer and tokenizer.\n\n',
                    ),
                    // Mifunetoshiro
                    TextSpan(
                      text: 'Mifunetoshiro',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => viewModel.openUrl(
                            r'https://github.com/mifunetoshiro/kanjium'),
                    ),
                    const TextSpan(
                      text: ' on Github manages the pitch accent data.\n\n',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
