import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'cosmic_meteor.dart';
import 'cosmic_nebula.dart';
import 'cosmic_ship.dart';
import 'cosmic_star.dart';

class NaosCosmicGame extends FlameGame {
  final math.Random _random = math.Random();

  // ==========================================================
  // COMPONENTES
  // ==========================================================

  final List<CosmicStar> stars = [];

  final List<CosmicMeteor> meteors = [];

  final List<CosmicMeteor> foregroundMeteors = [];

  late CosmicNebula nebula;

  late CosmicShip ship;

  double _time = 0;

  // ==========================================================
  // BACKGROUND
  // ==========================================================

  @override
  Color backgroundColor() {
    return const Color(0xFF020617);
  }

  // ==========================================================
  // LOAD
  // ==========================================================

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // --------------------------------------------------------
    // NEBULOSA / SHADER
    // --------------------------------------------------------
    //
    // La nebulosa se agrega primero y con prioridad negativa.
    // Esto garantiza que permanezca detrás de toda la escena.
    //
    // Orden visual:
    //
    //   🌌 Nebulosa
    //   ✨ Estrellas
    //   ☄️ Meteoritos
    //   🚀 Nave
    //   🔥 Propulsores
    //
    // --------------------------------------------------------

    nebula = CosmicNebula();

    nebula.priority = -1000;

    await add(nebula);

    // --------------------------------------------------------
    // ESTRELLAS
    // --------------------------------------------------------

    await _createStars();

    // --------------------------------------------------------
    // METEORITOS
    // --------------------------------------------------------

    await _createMeteors();

    // --------------------------------------------------------
    // NAVE
    // --------------------------------------------------------

    ship = CosmicShip(
      position: Vector2(
        size.x * 0.30,
        size.y * 0.50,
      ),
    );

    ship.priority = 5;

    await add(ship);

    // --------------------------------------------------------
    // OBJETOS DE PRIMER PLANO
    // --------------------------------------------------------

    await _createForegroundObjects();
  }

  // ==========================================================
  // UPDATE
  // ==========================================================

  @override
  void update(double dt) {
    super.update(dt);

    _time += dt;
    // ========================================================
// WARP BASADO EN VELOCIDAD
// ========================================================

if (nebula.isMounted) {
  final speedRatio =
      (ship.velocityX / 120.0).clamp(
    0.0,
    1.0,
  );

  nebula.warpStrength =
      speedRatio * speedRatio;
}

    // ========================================================
    // ESTRELLAS
    // ========================================================

    for (final star in stars) {
      final parallaxSpeed =
          5.0 + (star.depth * 22.0);

      star.x += parallaxSpeed * dt;

      if (star.x > size.x + 30) {
        star.x = -30;

        star.y =
            _random.nextDouble() * size.y;
      }
    }

    // ========================================================
    // METEORITOS NORMALES
    // ========================================================

    for (final meteor in meteors) {
      final parallaxSpeed =
          4.0 + (meteor.depth * 18.0);

      meteor.x -= parallaxSpeed * dt;

      if (meteor.x < -meteor.radius * 4) {
        meteor.x =
            size.x + meteor.radius * 4;

        meteor.y =
            50 +
            _random.nextDouble() *
                math.max(
                  1,
                  size.y - 100,
                );
      }
    }

    // ========================================================
    // METEORITOS DE PRIMER PLANO
    // ========================================================

    for (final meteor in foregroundMeteors) {
      final foregroundSpeed =
          35.0 + (meteor.radius * 1.8);

      meteor.x -= foregroundSpeed * dt;

      meteor.y +=
          math.sin(
                _time * 1.2 +
                    meteor.angle,
              ) *
              4.0 *
              dt;

      // ------------------------------------------------------
      // REAPARECER POR LA DERECHA
      // ------------------------------------------------------

      if (meteor.x <
          -meteor.radius * 6) {
        meteor.x =
            size.x +
            meteor.radius * 6 +
            _random.nextDouble() * 250;

        meteor.y =
            40 +
            _random.nextDouble() *
                math.max(
                  1,
                  size.y - 80,
                );

        meteor.angle =
            _random.nextDouble() *
                math.pi *
                2;
      }
    }

    // ========================================================
    // MICRO MOVIMIENTO DEL ESPACIO
    // ========================================================

    final sceneMotion =
        math.sin(_time * 0.35) * 0.15;

    for (final star in stars) {
      star.y +=
          sceneMotion *
              star.depth *
              dt;
    }
  }

  // ==========================================================
  // CREATE STARS
  // ==========================================================

  Future<void> _createStars() async {
    // --------------------------------------------------------
    // ESTRELLAS LEJANAS
    // --------------------------------------------------------

    for (int i = 0; i < 110; i++) {
      await _addStar(
        depth: 0.15,
        baseSize:
            0.45 +
            _random.nextDouble() *
                0.40,
        speed:
            2.5 +
            _random.nextDouble() *
                2.5,
      );
    }

    // --------------------------------------------------------
    // ESTRELLAS MEDIAS
    // --------------------------------------------------------

    for (int i = 0; i < 55; i++) {
      await _addStar(
        depth: 0.45,
        baseSize:
            0.65 +
            _random.nextDouble() *
                0.70,
        speed:
            5 +
            _random.nextDouble() *
                6,
      );
    }

    // --------------------------------------------------------
    // ESTRELLAS CERCANAS
    // --------------------------------------------------------

    for (int i = 0; i < 24; i++) {
      await _addStar(
        depth: 0.85,
        baseSize:
            1.0 +
            _random.nextDouble() *
                1.2,
        speed:
            10 +
            _random.nextDouble() *
                14,
      );
    }
  }

  // ==========================================================
  // ADD STAR
  // ==========================================================

  Future<void> _addStar({
    required double depth,
    required double baseSize,
    required double speed,
  }) async {
    final star = CosmicStar(
      position: Vector2(
        _random.nextDouble() *
            (size.x + 160),
        _random.nextDouble() *
            size.y,
      ),
      depth: depth,
      baseSize: baseSize,
      baseSpeed: speed,
    );

    stars.add(star);

    await add(star);
  }

  // ==========================================================
  // CREATE METEORS
  // ==========================================================

  Future<void> _createMeteors() async {
    // --------------------------------------------------------
    // LEJANOS
    // --------------------------------------------------------

    for (int i = 0; i < 8; i++) {
      await _addMeteor(
        depth: 0.20,
        radius:
            6 +
            _random.nextDouble() *
                6,
        speed:
            12 +
            _random.nextDouble() *
                12,
      );
    }

    // --------------------------------------------------------
    // MEDIOS
    // --------------------------------------------------------

    for (int i = 0; i < 6; i++) {
      await _addMeteor(
        depth: 0.50,
        radius:
            11 +
            _random.nextDouble() *
                10,
        speed:
            25 +
            _random.nextDouble() *
                20,
      );
    }

    // --------------------------------------------------------
    // CERCANOS
    // --------------------------------------------------------

    for (int i = 0; i < 4; i++) {
      await _addMeteor(
        depth: 0.82,
        radius:
            18 +
            _random.nextDouble() *
                15,
        speed:
            50 +
            _random.nextDouble() *
                40,
      );
    }
  }

  // ==========================================================
  // ADD METEOR
  // ==========================================================

  Future<void> _addMeteor({
    required double depth,
    required double radius,
    required double speed,
  }) async {
    final meteor = CosmicMeteor(
      position: Vector2(
        size.x +
            _random.nextDouble() *
                size.x,
        50 +
            _random.nextDouble() *
                math.max(
                  1,
                  size.y - 100,
                ),
      ),
      depth: depth,
      radius: radius,
      speed: speed,
      rotationSpeed:
          (-0.8 +
                  _random.nextDouble() *
                      1.6) *
              depth,
    );

    meteors.add(meteor);

    await add(meteor);
  }

  // ==========================================================
  // FOREGROUND OBJECTS
  // ==========================================================

  Future<void> _createForegroundObjects() async {
    for (int i = 0; i < 3; i++) {
      await _addForegroundMeteor();
    }
  }

  // ==========================================================
  // ADD FOREGROUND METEOR
  // ==========================================================

  Future<void> _addForegroundMeteor() async {
    final radius =
        30 +
        _random.nextDouble() *
            25;

    final meteor = CosmicMeteor(
      position: Vector2(
        size.x +
            200 +
            _random.nextDouble() *
                size.x,
        60 +
            _random.nextDouble() *
                math.max(
                  1,
                  size.y - 120,
                ),
      ),
      depth: 1.0,
      radius: radius,
      speed:
          100 +
          _random.nextDouble() *
              80,
      rotationSpeed:
          -1.5 +
          _random.nextDouble() *
              3.0,
    );

    // --------------------------------------------------------
    // ESCALA
    // --------------------------------------------------------

    final foregroundScale =
        1.25 +
        _random.nextDouble() *
            0.75;

    meteor.scale =
        Vector2.all(
          foregroundScale,
        );

    // --------------------------------------------------------
    // PRIORIDAD
    // --------------------------------------------------------

    meteor.priority = 10;

    foregroundMeteors.add(meteor);

    await add(meteor);
  }
}