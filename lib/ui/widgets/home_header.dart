import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final Widget title;
  final Widget child;

  const HomeHeader({required this.title, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return Column(
      children: [
        Container(
          height: 80 + padding.top,
          decoration: const BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            top: padding.top,
            left: padding.left,
            right: padding.right,
          ),
          child: Center(child: title),
        ),
        Expanded(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: padding.left,
                  right: padding.right,
                ),
                child: child,
              ),
              Align(
                alignment: Alignment.topRight,
                child: ClipPath(
                  clipper: const CustomCornerClipPath(),
                  child: Container(
                    width: 24,
                    height: 24,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CustomCornerClipPath extends CustomClipper<Path> {
  final double radius;

  const CustomCornerClipPath({this.radius = 24});

  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(radius, size.height)
    ..arcToPoint(
      Offset(0, size.height - radius),
      radius: Radius.circular(radius),
      clockwise: false,
    );

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
