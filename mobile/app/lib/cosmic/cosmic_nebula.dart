import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// ============================================================
/// NAOS — COSMIC NEBULA
/// ============================================================
///
/// Capa de nebulosa generada mediante Flutter FragmentShader.
///
/// Uniforms utilizados por naos_nebula.frag:
///
/// 0 -> ancho de pantalla
/// 1 -> alto de pantalla
/// 2 -> tiempo
///
/// La nebulosa es sutil y está pensada para quedar detrás de:
///
/// - estrellas
/// - meteoritos
/// - nave
///
/// Esta clase se utiliza únicamente en la página cósmica
/// de prueba.
/// ============================================================

class CosmicNebula extends Component
    with HasGameReference<FlameGame> {
  ui.FragmentProgram? _program;
  ui.FragmentShader? _shader;

  double _time = 0;
  double warpStrength = 0;

  bool _ready = false;

  // ==========================================================
  // LOAD
  // ==========================================================

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // --------------------------------------------------------
    // CARGAR SHADER
    // --------------------------------------------------------

    _program = await ui.FragmentProgram.fromAsset(
      'shaders/naos_nebula.frag',
    );

    _shader = _program!.fragmentShader();

    _ready = true;
  }

  // ==========================================================
  // UPDATE
  // ==========================================================

  @override
  void update(double dt) {
    super.update(dt);

    _time += dt;

    // Evita que el contador crezca indefinidamente.
    if (_time > 100000) {
      _time = 0;
    }
  }

  // ==========================================================
  // RENDER
  // ==========================================================

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // El shader todavía no terminó de cargar.
    if (!_ready || _shader == null) {
      return;
    }

    final shader = _shader!;

    final width = game.size.x;
    final height = game.size.y;

    if (width <= 0 || height <= 0) {
      return;
    }

    // --------------------------------------------------------
    // UNIFORMS
    // --------------------------------------------------------

    shader.setFloat(
      0,
      width,
    );

    shader.setFloat(
      1,
      height,
    );

    shader.setFloat(2, _time);
shader.setFloat(3, warpStrength);

    // --------------------------------------------------------
    // PAINT
    // --------------------------------------------------------

    final paint = Paint()
      ..shader = shader
      ..blendMode = BlendMode.plus;

    // --------------------------------------------------------
    // NEBULOSA
    // --------------------------------------------------------

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        width,
        height,
      ),
      paint,
    );
  }
}