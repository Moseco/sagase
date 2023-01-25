import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

class FlashcardDeck extends StatefulWidget {
  final bool swipeUpEnabled;
  final FlashcardDeckController controller;
  final Widget currentFlashcard;
  final Widget nextFlashcard;
  final Widget blankFlashcard;
  final void Function(SwipeAnimation) onSwipeFinished;

  const FlashcardDeck({
    required this.swipeUpEnabled,
    required this.controller,
    required this.currentFlashcard,
    required this.nextFlashcard,
    required this.onSwipeFinished,
    required this.blankFlashcard,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _FlashcardDeckState();
}

class _FlashcardDeckState extends State<FlashcardDeck>
    with SingleTickerProviderStateMixin {
  final int _swipeThreshold = 50;
  final double _maxAngle = 30 * (pi / 180);

  double _horizontalOffset = 0;
  double _verticalOffset = 0;
  double _totalOffset = 0;
  double _angle = 0;
  double _scale = 0.9;
  double _verticalDifference = 40;
  SwipeAnimation _currentSwipeAnimation = SwipeAnimation.none;
  final _swipeHistory = ListQueue<SwipeAnimation>();

  late AnimationController _animationController;
  late Animation<double> _leftAnimation;
  late Animation<double> _topAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _differenceAnimation;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(() {
      // Only start new swipe from controller if currently not doing one
      if (_currentSwipeAnimation == SwipeAnimation.none) {
        switch (widget.controller.state) {
          case SwipeAnimation.wrong:
            _swipeWrong(context);
            break;
          case SwipeAnimation.correct:
            _swipeCorrect(context);
            break;
          case SwipeAnimation.veryCorrect:
            _swipeVeryCorrect(context);
            break;
          case SwipeAnimation.repeat:
            _swipeRepeat(context);
            break;
          case SwipeAnimation.undoSwipe:
            _undoSwipe(context);
            break;
          default:
            break;
        }
        _animationController.forward();
      }
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _animationController.addListener(() {
      if (_animationController.status == AnimationStatus.forward) {
        setState(() {
          _horizontalOffset = _leftAnimation.value;
          _verticalOffset = _topAnimation.value;
          _scale = _scaleAnimation.value;
          _verticalDifference = _differenceAnimation.value;
        });
      } else if (_animationController.status == AnimationStatus.completed) {
        setState(() {
          _animationController.reset();
          _horizontalOffset = 0;
          _verticalOffset = 0;
          _totalOffset = 0;
          _angle = 0;
          _scale = 0.9;
          _verticalDifference = 40;

          widget.onSwipeFinished(_currentSwipeAnimation);

          _currentSwipeAnimation = SwipeAnimation.none;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 40,
          left: 0,
          child: Transform.scale(
            scale: 0.9,
            child: widget.blankFlashcard,
          ),
        ),
        Positioned(
          top: _verticalDifference,
          left: 0,
          child: Transform.scale(
            scale: _scale,
            child: _currentSwipeAnimation != SwipeAnimation.none &&
                    _currentSwipeAnimation != SwipeAnimation.reset
                ? widget.nextFlashcard
                : widget.blankFlashcard,
          ),
        ),
        Positioned(
          left: _horizontalOffset,
          top: _verticalOffset,
          child: GestureDetector(
            child: Transform.rotate(
              angle: _angle,
              child: widget.currentFlashcard,
            ),
            onPanUpdate: (tapInfo) {
              // Don't allow manually swiping the card during another animation
              if (_currentSwipeAnimation == SwipeAnimation.none) {
                setState(() {
                  _horizontalOffset += tapInfo.delta.dx;
                  _verticalOffset += tapInfo.delta.dy;
                  _totalOffset =
                      _horizontalOffset.abs() + _verticalOffset.abs();
                  _calculateAngle();
                  _calculateScale();
                  _calculateDifference();
                });
              }
            },
            onPanEnd: (tapInfo) {
              // Don't allow manually swiping the card during another animation
              if (_currentSwipeAnimation == SwipeAnimation.none) {
                if (_horizontalOffset < -_swipeThreshold) {
                  _swipeWrong(context);
                } else if (_horizontalOffset > _swipeThreshold) {
                  _swipeCorrect(context);
                } else if (widget.swipeUpEnabled &&
                    _verticalOffset < -_swipeThreshold) {
                  _swipeRepeat(context);
                } else {
                  _resetFlashcard(context);
                }
              }
            },
          ),
        ),
      ],
    );
  }

  void _calculateAngle() {
    _angle = ((_maxAngle / 100) * (_horizontalOffset / 10))
        .clamp(-_maxAngle, _maxAngle);
  }

  void _calculateScale() {
    _scale = (0.9 + (_totalOffset / 5000)).clamp(0.9, 1.0);
  }

  void _calculateDifference() {
    _verticalDifference = (40 - (_totalOffset / 10)).clamp(0, 40);
  }

  void _resetFlashcard(BuildContext context) {
    setState(() {
      _currentSwipeAnimation = SwipeAnimation.reset;
      _leftAnimation = Tween<double>(
        begin: _horizontalOffset,
        end: 0,
      ).animate(_animationController);
      _topAnimation = Tween<double>(
        begin: _verticalOffset,
        end: 0,
      ).animate(_animationController);
      _scaleAnimation = Tween<double>(
        begin: _scale,
        end: 0.9,
      ).animate(_animationController);
      _differenceAnimation = Tween<double>(
        begin: _verticalDifference,
        end: 40,
      ).animate(_animationController);
      _animationController.forward();
    });
  }

  void _swipeWrong(BuildContext context) {
    setState(() {
      _currentSwipeAnimation = SwipeAnimation.wrong;
      _swipeHistory.add(SwipeAnimation.wrong);
      _leftAnimation = Tween<double>(
        begin: _horizontalOffset,
        end: -MediaQuery.of(context).size.width,
      ).animate(_animationController);
      _topAnimation = Tween<double>(
        begin: _verticalOffset,
        end: _verticalOffset + _verticalOffset,
      ).animate(_animationController);
      _scaleAnimation = Tween<double>(
        begin: _scale,
        end: 1.0,
      ).animate(_animationController);
      _differenceAnimation = Tween<double>(
        begin: _verticalDifference,
        end: 0,
      ).animate(_animationController);
      _animationController.forward();
    });
  }

  void _swipeCorrect(BuildContext context) {
    setState(() {
      _currentSwipeAnimation = SwipeAnimation.correct;
      _swipeHistory.add(SwipeAnimation.correct);
      _leftAnimation = Tween<double>(
        begin: _horizontalOffset,
        end: MediaQuery.of(context).size.width,
      ).animate(_animationController);
      _topAnimation = Tween<double>(
        begin: _verticalOffset,
        end: _verticalOffset + _verticalOffset,
      ).animate(_animationController);
      _scaleAnimation = Tween<double>(
        begin: _scale,
        end: 1.0,
      ).animate(_animationController);
      _differenceAnimation = Tween<double>(
        begin: _verticalDifference,
        end: 0,
      ).animate(_animationController);
      _animationController.forward();
    });
  }

  void _swipeVeryCorrect(BuildContext context) {
    setState(() {
      _currentSwipeAnimation = SwipeAnimation.veryCorrect;
      _swipeHistory.add(SwipeAnimation.veryCorrect);
      _leftAnimation = Tween<double>(
        begin: _horizontalOffset,
        end: MediaQuery.of(context).size.width,
      ).animate(_animationController);
      _topAnimation = Tween<double>(
        begin: _verticalOffset,
        end: _verticalOffset + _verticalOffset,
      ).animate(_animationController);
      _scaleAnimation = Tween<double>(
        begin: _scale,
        end: 1.0,
      ).animate(_animationController);
      _differenceAnimation = Tween<double>(
        begin: _verticalDifference,
        end: 0,
      ).animate(_animationController);
      _animationController.forward();
    });
  }

  void _swipeRepeat(BuildContext context) {
    setState(() {
      _currentSwipeAnimation = SwipeAnimation.repeat;
      _swipeHistory.add(SwipeAnimation.repeat);
      _leftAnimation = Tween<double>(
        begin: _horizontalOffset,
        end: _horizontalOffset + _horizontalOffset,
      ).animate(_animationController);
      _topAnimation = Tween<double>(
        begin: _verticalOffset,
        end: -MediaQuery.of(context).size.height,
      ).animate(_animationController);
      _scaleAnimation = Tween<double>(
        begin: _scale,
        end: 1.0,
      ).animate(_animationController);
      _differenceAnimation = Tween<double>(
        begin: _verticalDifference,
        end: 0,
      ).animate(_animationController);
      _animationController.forward();
    });
  }

  void _undoSwipe(BuildContext context) {
    setState(() {
      _currentSwipeAnimation = SwipeAnimation.undoSwipe;

      switch (_swipeHistory.last) {
        case SwipeAnimation.wrong:
          _leftAnimation = Tween<double>(
            begin: -MediaQuery.of(context).size.width,
            end: 0,
          ).animate(_animationController);
          _topAnimation = Tween<double>(
            begin: 0,
            end: 0,
          ).animate(_animationController);
          break;
        case SwipeAnimation.correct:
          _leftAnimation = Tween<double>(
            begin: MediaQuery.of(context).size.width,
            end: 0,
          ).animate(_animationController);
          _topAnimation = Tween<double>(
            begin: 0,
            end: 0,
          ).animate(_animationController);
          break;
        case SwipeAnimation.veryCorrect:
          _leftAnimation = Tween<double>(
            begin: MediaQuery.of(context).size.width,
            end: 0,
          ).animate(_animationController);
          _topAnimation = Tween<double>(
            begin: 0,
            end: 0,
          ).animate(_animationController);
          break;
        case SwipeAnimation.repeat:
          _leftAnimation = Tween<double>(
            begin: 0,
            end: 0,
          ).animate(_animationController);
          _topAnimation = Tween<double>(
            begin: -MediaQuery.of(context).size.height,
            end: 0,
          ).animate(_animationController);

          break;
        default:
          break;
      }

      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: _scale,
      ).animate(_animationController);
      _differenceAnimation = Tween<double>(
        begin: 0,
        end: _verticalDifference,
      ).animate(_animationController);
      _animationController.forward();

      _swipeHistory.removeLast();
      _animationController.forward();
    });
  }
}

class FlashcardDeckController extends ChangeNotifier {
  SwipeAnimation? state;

  void swipeWrong() {
    state = SwipeAnimation.wrong;
    notifyListeners();
  }

  void swipeCorrect() {
    state = SwipeAnimation.correct;
    notifyListeners();
  }

  void swipeVeryCorrect() {
    state = SwipeAnimation.veryCorrect;
    notifyListeners();
  }

  void swipeRepeat() {
    state = SwipeAnimation.repeat;
    notifyListeners();
  }

  void undoSwipe() {
    state = SwipeAnimation.undoSwipe;
    notifyListeners();
  }
}

enum SwipeAnimation {
  none,
  reset,
  wrong,
  correct,
  veryCorrect,
  repeat,
  undoSwipe,
}
