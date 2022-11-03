import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'kana_viewmodel.dart';

class KanaView extends StatelessWidget {
  const KanaView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<KanaViewModel>.reactive(
      viewModelBuilder: () => KanaViewModel(),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          title: Text(viewModel.showHiragana ? 'Hiragana' : 'Katakana'),
          actions: [
            TextButton(
              onPressed: viewModel.toggleKana,
              child: Text(
                viewModel.showHiragana ? 'ア' : 'あ',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        body: GridView.count(
          crossAxisCount: 5,
          children: viewModel.showHiragana
              ? const [
                  // base
                  _GridItem('あ', 'a'),
                  _GridItem('い', 'i'),
                  _GridItem('う', 'u'),
                  _GridItem('え', 'e'),
                  _GridItem('お', 'o'),
                  // k
                  _GridItem('か', 'ka'),
                  _GridItem('き', 'ki'),
                  _GridItem('く', 'ku'),
                  _GridItem('け', 'ke'),
                  _GridItem('こ', 'ko'),
                  // s
                  _GridItem('さ', 'sa'),
                  _GridItem('し', 'shi'),
                  _GridItem('す', 'su'),
                  _GridItem('せ', 'se'),
                  _GridItem('そ', 'so'),
                  // t
                  _GridItem('た', 'ta'),
                  _GridItem('ち', 'chi'),
                  _GridItem('つ', 'tsu'),
                  _GridItem('て', 'te'),
                  _GridItem('と', 'to'),
                  // n
                  _GridItem('な', 'na'),
                  _GridItem('に', 'ni'),
                  _GridItem('ぬ', 'nu'),
                  _GridItem('ね', 'ne'),
                  _GridItem('の', 'no'),
                  // h
                  _GridItem('は', 'ha'),
                  _GridItem('ひ', 'hi'),
                  _GridItem('ふ', 'fu'),
                  _GridItem('へ', 'he'),
                  _GridItem('ほ', 'ho'),
                  // m
                  _GridItem('ま', 'ma'),
                  _GridItem('み', 'mi'),
                  _GridItem('む', 'mu'),
                  _GridItem('め', 'me'),
                  _GridItem('も', 'mo'),
                  // y
                  _GridItem('や', 'ya'),
                  _GridItem('', ''),
                  _GridItem('ゆ', 'yu'),
                  _GridItem('', ''),
                  _GridItem('よ', 'yo'),
                  // r
                  _GridItem('ら', 'ra'),
                  _GridItem('り', 'ri'),
                  _GridItem('る', 'ru'),
                  _GridItem('れ', 're'),
                  _GridItem('ろ', 'ro'),
                  // w
                  _GridItem('わ', 'wa'),
                  _GridItem('ゐ', 'wi', obsolete: true),
                  _GridItem('', ''),
                  _GridItem('ゑ', 'we', obsolete: true),
                  _GridItem('を', 'o'),
                  // n
                  _GridItem('ん', 'n'),
                  _GridItem('', ''),
                  _GridItem('', ''),
                  _GridItem('', ''),
                  _GridItem('', ''),
                  // g
                  _GridItem('が', 'ga'),
                  _GridItem('ぎ', 'gi'),
                  _GridItem('ぐ', 'gu'),
                  _GridItem('げ', 'ge'),
                  _GridItem('ご', 'go'),
                  // z
                  _GridItem('ざ', 'za'),
                  _GridItem('じ', 'ji'),
                  _GridItem('ず', 'zu'),
                  _GridItem('ぜ', 'ze'),
                  _GridItem('ぞ', 'zo'),
                  // d
                  _GridItem('だ', 'da'),
                  _GridItem('ぢ', 'ji'),
                  _GridItem('づ', 'zu'),
                  _GridItem('で', 'de'),
                  _GridItem('ど', 'do'),
                  // b
                  _GridItem('ば', 'ba'),
                  _GridItem('び', 'bi'),
                  _GridItem('ぶ', 'bu'),
                  _GridItem('べ', 'be'),
                  _GridItem('ぼ', 'bo'),
                  // p
                  _GridItem('ぱ', 'pa'),
                  _GridItem('ぴ', 'pi'),
                  _GridItem('ぷ', 'pu'),
                  _GridItem('ぺ', 'pe'),
                  _GridItem('ぽ', 'po'),
                ]
              : const [
                  // base
                  _GridItem('ア', 'a'),
                  _GridItem('イ', 'i'),
                  _GridItem('ウ', 'u'),
                  _GridItem('エ', 'e'),
                  _GridItem('オ', 'o'),
                  // k
                  _GridItem('カ', 'ka'),
                  _GridItem('キ', 'ki'),
                  _GridItem('ク', 'ku'),
                  _GridItem('ケ', 'ke'),
                  _GridItem('コ', 'ko'),
                  // s
                  _GridItem('サ', 'sa'),
                  _GridItem('シ', 'shi'),
                  _GridItem('ス', 'su'),
                  _GridItem('セ', 'se'),
                  _GridItem('ソ', 'so'),
                  // t
                  _GridItem('タ', 'ta'),
                  _GridItem('チ', 'chi'),
                  _GridItem('ツ', 'tsu'),
                  _GridItem('テ', 'te'),
                  _GridItem('ト', 'to'),
                  // n
                  _GridItem('ナ', 'na'),
                  _GridItem('ニ', 'ni'),
                  _GridItem('ヌ', 'nu'),
                  _GridItem('ネ', 'ne'),
                  _GridItem('ノ', 'no'),
                  // h
                  _GridItem('ハ', 'ha'),
                  _GridItem('ヒ', 'hi'),
                  _GridItem('フ', 'fu'),
                  _GridItem('ヘ', 'he'),
                  _GridItem('ホ', 'ho'),
                  // m
                  _GridItem('マ', 'ma'),
                  _GridItem('ミ', 'mi'),
                  _GridItem('ム', 'mu'),
                  _GridItem('メ', 'me'),
                  _GridItem('モ', 'mo'),
                  // y
                  _GridItem('ヤ', 'ya'),
                  _GridItem('', ''),
                  _GridItem('ユ', 'yu'),
                  _GridItem('', ''),
                  _GridItem('ヨ', 'yo'),
                  // r
                  _GridItem('ラ', 'ra'),
                  _GridItem('リ', 'ri'),
                  _GridItem('ル', 'ru'),
                  _GridItem('レ', 're'),
                  _GridItem('ロ', 'ro'),
                  // w
                  _GridItem('ワ', 'wa'),
                  _GridItem('ヰ', 'wi', obsolete: true),
                  _GridItem('', ''),
                  _GridItem('ヱ', 'we', obsolete: true),
                  _GridItem('ヲ', 'o'),
                  // n
                  _GridItem('ン', 'n'),
                  _GridItem('', ''),
                  _GridItem('', ''),
                  _GridItem('', ''),
                  _GridItem('', ''),
                  // g
                  _GridItem('ガ', 'ga'),
                  _GridItem('ギ', 'gi'),
                  _GridItem('グ', 'gu'),
                  _GridItem('ゲ', 'ge'),
                  _GridItem('ゴ', 'go'),
                  // z
                  _GridItem('ザ', 'za'),
                  _GridItem('ジ', 'ji'),
                  _GridItem('ズ', 'zu'),
                  _GridItem('ゼ', 'ze'),
                  _GridItem('ゾ', 'zo'),
                  // d
                  _GridItem('ダ', 'da'),
                  _GridItem('ヂ', 'ji'),
                  _GridItem('ヅ', 'zu'),
                  _GridItem('デ', 'de'),
                  _GridItem('ド', 'do'),
                  // b
                  _GridItem('バ', 'ba'),
                  _GridItem('ビ', 'bi'),
                  _GridItem('ブ', 'bu'),
                  _GridItem('ベ', 'be'),
                  _GridItem('ボ', 'bo'),
                  // p
                  _GridItem('パ', 'pa'),
                  _GridItem('ピ', 'pi'),
                  _GridItem('プ', 'pu'),
                  _GridItem('ペ', 'pe'),
                  _GridItem('ポ', 'po'),
                ],
        ),
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  final String kana;
  final String romaji;
  final bool obsolete;

  const _GridItem(
    this.kana,
    this.romaji, {
    this.obsolete = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          kana,
          style: TextStyle(
            fontSize: 32,
            color: obsolete ? Colors.black26 : null,
          ),
        ),
        Text(
          romaji,
          style: TextStyle(color: obsolete ? Colors.black26 : null),
        ),
      ],
    );
  }
}
