import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class NaosLottieIntro extends StatefulWidget {
  const NaosLottieIntro({
    super.key,
    this.onCompleted,
  });

  final VoidCallback? onCompleted;

  @override
  State<NaosLottieIntro> createState() => _NaosLottieIntroState();
}

class _NaosLottieIntroState extends State<NaosLottieIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/animations/naos_cosmic_test.json',
        controller: _controller,
        fit: BoxFit.contain,
        repeat: false,
        onLoaded: (composition) {
          _controller.duration = composition.duration;
          _controller.forward(from: 0);
        },
      ),
    );
  }
}