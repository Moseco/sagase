// The content of this file is based on https://github.com/yamagoya/jconj

import 'package:sagase/utils/conjugation_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

class Conjugation {
  final PartOfSpeech pos;
  final ConjugationForm form;
  final bool negative;
  final bool formal;
  final int onum;
  final int stem;
  final String okuri;
  final String? euphr;
  final String? euphk;

  const Conjugation(
    this.pos,
    this.form,
    this.negative,
    this.formal,
    this.onum,
    this.stem,
    this.okuri,
    this.euphr,
    this.euphk,
  );
}
