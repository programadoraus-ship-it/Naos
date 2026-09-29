import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../shared/widgets/naos_lottie_intro.dart';
import 'naos_cosmic_game.dart';

class NaosCosmicTestPage extends StatefulWidget {
  const NaosCosmicTestPage({
    super.key,
  });

  @override
  State<NaosCosmicTestPage> createState() =>
      _NaosCosmicTestPageState();
}

class _NaosCosmicTestPageState
    extends State<NaosCosmicTestPage> {
  bool _showIntro = true;

  @override
  void initState() {
    super.initState();

    // --------------------------------------------------------
    // SEGURIDAD
    // --------------------------------------------------------
    //
    // Si por alguna razón el Lottie no dispara onCompleted,
    // la escena tampoco queda bloqueada.
    //
    Timer(
      const Duration(
        seconds: 4,
      ),
      () {
        if (!mounted) return;

        setState(() {
          _showIntro = false;
        });
      },
    );
  }

  void _finishIntro() {
    if (!mounted) return;

    setState(() {
      _showIntro = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF020312,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ==================================================
          // ESCENA CÓSMICA
          // ==================================================

          GameWidget<NaosCosmicGame>(
            game: NaosCosmicGame(),
          ),

          // ==================================================
          // LOTTIE DE INTRODUCCIÓN
          // ==================================================

          if (_showIntro)
            IgnorePointer(
              child: Container(
                color: const Color(
                  0xFF020312,
                ),
                alignment: Alignment.center,
                child: SizedBox(
                  width: 420,
                  height: 320,
                  child: NaosLottieIntro(
                    onCompleted: _finishIntro,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}