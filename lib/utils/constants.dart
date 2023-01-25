import 'package:sagase/datamodels/kanji_radical.dart';

const int dictionaryVersion = 2;
const int nestedNavigationKey = 1;

const int dictionaryListIdJouyou = 0;
const int dictionaryListIdJlptN1 = 1;
const int dictionaryListIdJlptN2 = 2;
const int dictionaryListIdJlptN3 = 3;
const int dictionaryListIdJlptN4 = 4;
const int dictionaryListIdJlptN5 = 5;

final kanjiRegExp = RegExp(r'(\p{Script=Han})', unicode: true);

const keyInitialCorrectInterval = 'initial_correct_interval';
const keyInitialVeryCorrectInterval = 'initial_very_correct_interval';

const radicals = [
  KanjiRadical('', 0, ''), // Empty to align radical number with list index
  KanjiRadical('一', 1, 'one'),
  KanjiRadical('丨', 1, 'line'),
  KanjiRadical('丶', 1, 'dot'),
  KanjiRadical('丿', 1, 'slash'),
  KanjiRadical('乙', 1, 'second', variants: '⺄ 乚'),
  KanjiRadical('亅', 1, 'hook'),
  KanjiRadical('二', 2, 'two'),
  KanjiRadical('亠', 2, 'lid'),
  KanjiRadical('人', 2, 'person', variants: '亻'),
  KanjiRadical('儿', 2, 'legs'),
  KanjiRadical('入', 2, 'enter'),
  KanjiRadical('八', 2, 'eight'),
  KanjiRadical('冂', 2, 'open country'),
  KanjiRadical('冖', 2, 'cover'),
  KanjiRadical('冫', 2, 'ice'),
  KanjiRadical('几', 2, 'table'),
  KanjiRadical('凵', 2, 'container'),
  KanjiRadical('刀', 2, 'sword', variants: '刂'),
  KanjiRadical('力', 2, 'power, force'),
  KanjiRadical('勹', 2, 'wrap'),
  KanjiRadical('匕', 2, 'spoon'),
  KanjiRadical('匚', 2, 'box'),
  KanjiRadical('匸', 2, 'hiding enclosure'),
  KanjiRadical('十', 2, 'ten'),
  KanjiRadical('卜', 2, 'divination'),
  KanjiRadical('卩', 2, 'seal', variants: '⺋'),
  KanjiRadical('厂', 2, 'cliff'),
  KanjiRadical('厶', 2, 'private'),
  KanjiRadical('又', 2, 'again'),
  KanjiRadical('口', 3, 'mouth'),
  KanjiRadical('囗', 3, 'enclosure'),
  KanjiRadical('土', 3, 'earth'),
  KanjiRadical('士', 3, 'scholar'),
  KanjiRadical('夂', 3, 'go'),
  KanjiRadical('夊', 3, 'go slowly'),
  KanjiRadical('夕', 3, 'evening'),
  KanjiRadical('大', 3, 'big'),
  KanjiRadical('女', 3, 'woman'),
  KanjiRadical('子', 3, 'child'),
  KanjiRadical('宀', 3, 'roof'),
  KanjiRadical('寸', 3, 'inch'),
  KanjiRadical('小', 3, 'small'),
  KanjiRadical('尢', 3, 'lame', variants: '尣'),
  KanjiRadical('尸', 3, 'corpse'),
  KanjiRadical('屮', 3, 'sprout'),
  KanjiRadical('山', 3, 'mountain'),
  KanjiRadical('巛', 3, 'river', variants: '川'),
  KanjiRadical('工', 3, 'work'),
  KanjiRadical('己', 3, 'oneself', variants: '已 巳'),
  KanjiRadical('巾', 3, 'cloth, turban'),
  KanjiRadical('干', 3, 'dry'),
  KanjiRadical('幺', 3, 'short thread'),
  KanjiRadical('广', 3, 'dotted cliff'),
  KanjiRadical('廴', 3, 'long stride'),
  KanjiRadical('廾', 3, 'two hands'),
  KanjiRadical('弋', 3, 'shoot, arrow'),
  KanjiRadical('弓', 3, 'bow'),
  KanjiRadical('彐', 3, 'snout', variants: '彑'),
  KanjiRadical('彡', 3, 'bristle'),
  KanjiRadical('彳', 3, 'step'),
  KanjiRadical('心', 4, 'heart', variants: '忄 㣺'),
  KanjiRadical('戈', 4, 'halberd'),
  KanjiRadical('戶', 4, 'door', variants: '戸'),
  KanjiRadical('手', 4, 'hand', variants: '扌'),
  KanjiRadical('支', 4, 'branch'),
  KanjiRadical('攴', 4, 'strike', variants: '攵'),
  KanjiRadical('文', 4, 'writing'),
  KanjiRadical('斗', 4, 'dipper'),
  KanjiRadical('斤', 4, 'axe'),
  KanjiRadical('方', 4, 'square'),
  KanjiRadical('无', 4, 'not'),
  KanjiRadical('日', 4, 'day'),
  KanjiRadical('曰', 4, 'say'),
  KanjiRadical('月', 4, 'moon'),
  KanjiRadical('木', 4, 'tree'),
  KanjiRadical('欠', 4, 'lack'),
  KanjiRadical('止', 4, 'stop'),
  KanjiRadical('歹', 4, 'death'),
  KanjiRadical('殳', 4, 'weapon'),
  KanjiRadical('毋', 4, 'do not'),
  KanjiRadical('比', 4, 'compare'),
  KanjiRadical('毛', 4, 'hair'),
  KanjiRadical('氏', 4, 'clan'),
  KanjiRadical('气', 4, 'air'),
  KanjiRadical('水', 4, 'water', variants: '氵 氺'),
  KanjiRadical('火', 4, 'fire', variants: '灬'),
  KanjiRadical('爪', 4, 'nail', variants: '爫'),
  KanjiRadical('父', 4, 'father'),
  KanjiRadical('爻', 4, 'mix'),
  KanjiRadical('爿', 4, 'split wood', variants: '丬'),
  KanjiRadical('片', 4, 'slice'),
  KanjiRadical('牙', 4, 'fang'),
  KanjiRadical('牛', 4, 'cow', variants: '牜'),
  KanjiRadical('犬', 4, 'dog', variants: '犭'),
  KanjiRadical('玄', 5, 'profound'),
  KanjiRadical('玉', 5, 'king, ball', variants: '王 玊'),
  KanjiRadical('瓜', 5, 'melon'),
  KanjiRadical('瓦', 5, 'tile'),
  KanjiRadical('甘', 5, 'sweet'),
  KanjiRadical('生', 5, 'life'),
  KanjiRadical('用', 5, 'use', variants: '甩'),
  KanjiRadical('田', 5, 'field'),
  KanjiRadical('疋', 5, 'bolt of cloth'),
  KanjiRadical('疒', 5, 'disease'),
  KanjiRadical('癶', 5, 'footsteps'),
  KanjiRadical('白', 5, 'white'),
  KanjiRadical('皮', 5, 'skin'),
  KanjiRadical('皿', 5, 'plate'),
  KanjiRadical('目', 5, 'eye', variants: '罒'),
  KanjiRadical('矛', 5, 'spear'),
  KanjiRadical('矢', 5, 'arrow'),
  KanjiRadical('石', 5, 'stone'),
  KanjiRadical('示', 5, 'altar', variants: '礻'),
  KanjiRadical('禸', 5, 'track'),
  KanjiRadical('禾', 5, 'grain'),
  KanjiRadical('穴', 5, 'cave'),
  KanjiRadical('立', 5, 'stand'),
  KanjiRadical('竹', 6, 'bamboo'),
  KanjiRadical('米', 6, 'rice'),
  KanjiRadical('糸', 6, 'thread', variants: '糹'),
  KanjiRadical('缶', 6, 'can'),
  KanjiRadical('网', 6, 'net', variants: '罒 罓'),
  KanjiRadical('羊', 6, 'sheep'),
  KanjiRadical('羽', 6, 'wing'),
  KanjiRadical('老', 6, 'old', variants: '耂'),
  KanjiRadical('而', 6, 'and'),
  KanjiRadical('耒', 6, 'plow'),
  KanjiRadical('耳', 6, 'ear'),
  KanjiRadical('聿', 6, 'brush', variants: '肀'),
  KanjiRadical('肉', 6, 'meat', variants: '月'),
  KanjiRadical('臣', 6, 'minister'),
  KanjiRadical('自', 6, 'oneself'),
  KanjiRadical('至', 6, 'arrive'),
  KanjiRadical('臼', 6, 'mortar'),
  KanjiRadical('舌', 6, 'tongue'),
  KanjiRadical('舛', 6, 'oppose'),
  KanjiRadical('舟', 6, 'boat'),
  KanjiRadical('艮', 6, 'stopping'),
  KanjiRadical('色', 6, 'color'),
  KanjiRadical('艸', 6, 'grass', variants: '艹'),
  KanjiRadical('虍', 6, 'tiger'),
  KanjiRadical('虫', 6, 'bug'),
  KanjiRadical('血', 6, 'blood'),
  KanjiRadical('行', 6, 'go, do'),
  KanjiRadical('衣', 6, 'clothes', variants: '衤'),
  KanjiRadical('襾', 6, 'west', variants: '覀 西'),
  KanjiRadical('見', 7, 'see'),
  KanjiRadical('角', 7, 'horn'),
  KanjiRadical('言', 7, 'talk', variants: '訁'),
  KanjiRadical('谷', 7, 'valley'),
  KanjiRadical('豆', 7, 'bean'),
  KanjiRadical('豕', 7, 'pig'),
  KanjiRadical('豸', 7, 'badger'),
  KanjiRadical('貝', 7, 'shell'),
  KanjiRadical('赤', 7, 'red'),
  KanjiRadical('走', 7, 'run'),
  KanjiRadical('足', 7, 'foot'),
  KanjiRadical('身', 7, 'body'),
  KanjiRadical('車', 7, 'vehicle'),
  KanjiRadical('辛', 7, 'bitter'),
  KanjiRadical('辰', 7, 'morning'),
  KanjiRadical('辵', 7, 'walk', variants: '辶'),
  KanjiRadical('邑', 7, 'city', variants: '阝'),
  KanjiRadical('酉', 7, 'sake'),
  KanjiRadical('釆', 7, 'distinguish'),
  KanjiRadical('里', 7, 'village'),
  KanjiRadical('金', 8, 'gold'),
  KanjiRadical('長', 8, 'long'),
  KanjiRadical('門', 8, 'gate'),
  KanjiRadical('阜', 8, 'mound', variants: '阝'),
  KanjiRadical('隶', 8, 'slave'),
  KanjiRadical('隹', 8, 'small bird'),
  KanjiRadical('雨', 8, 'rain'),
  KanjiRadical('靑', 8, 'blue', variants: '青'),
  KanjiRadical('非', 8, 'wrong'),
  KanjiRadical('面', 9, 'face'),
  KanjiRadical('革', 9, 'leather'),
  KanjiRadical('韋', 9, 'tanned leather'),
  KanjiRadical('韭', 9, 'leek'),
  KanjiRadical('音', 9, 'sound'),
  KanjiRadical('頁', 9, 'leaf'),
  KanjiRadical('風', 9, 'wind'),
  KanjiRadical('飛', 9, 'fly'),
  KanjiRadical('食', 9, 'food', variants: '飠'),
  KanjiRadical('首', 9, 'neck'),
  KanjiRadical('香', 9, 'smell'),
  KanjiRadical('馬', 10, 'horse'),
  KanjiRadical('骨', 10, 'bone'),
  KanjiRadical('高', 10, 'tall', variants: '髙'),
  KanjiRadical('髟', 10, 'long hair'),
  KanjiRadical('鬥', 10, 'fight'),
  KanjiRadical('鬯', 10, 'sacrificial wine'),
  KanjiRadical('鬲', 10, 'tripod'),
  KanjiRadical('鬼', 10, 'demon'),
  KanjiRadical('魚', 11, 'fish'),
  KanjiRadical('鳥', 11, 'bird'),
  KanjiRadical('鹵', 11, 'salt'),
  KanjiRadical('鹿', 11, 'dear'),
  KanjiRadical('麥', 11, 'wheat', variants: '麦'),
  KanjiRadical('麻', 11, 'hemp'),
  KanjiRadical('黃', 12, 'yellow', variants: '黄'),
  KanjiRadical('黍', 12, 'millet'),
  KanjiRadical('黑', 12, 'black', variants: '黒'),
  KanjiRadical('黹', 12, 'embroidery'),
  KanjiRadical('黽', 13, 'frog'),
  KanjiRadical('鼎', 13, 'tripod'),
  KanjiRadical('鼓', 13, 'drum'),
  KanjiRadical('鼠', 13, 'mouse'),
  KanjiRadical('鼻', 14, 'nose'),
  KanjiRadical('齊', 14, 'even', variants: '斉'),
  KanjiRadical('齒', 15, 'tooth', variants: '歯'),
  KanjiRadical('龍', 16, 'dragon', variants: '竜'),
  KanjiRadical('龜', 16, 'turtle', variants: '亀'),
  KanjiRadical('龠', 17, 'flute'),
];
