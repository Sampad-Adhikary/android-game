import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/experimental.dart';
import 'package:flame/particles.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'game.dart';
import 'bullet.dart';
import 'player.dart';
import 'command.dart';
import 'audio_player_component.dart';

import '../models/enemy_data.dart';

// This class represent an enemy component.
class Enemy extends SpriteComponent
    with CollisionCallbacks, HasGameReference<SpacescapeGame> {
  // The speed of this enemy.
  double _speed = 250;

  // This direction in which this Enemy will move.
  // Defaults to vertically downwards.
  Vector2 moveDirection = Vector2(0, 1);

  // Controls for how long enemy should be frozen.
  late Timer _freezeTimer;

  // Holds an object of Random class to generate random numbers.
  final _random = Random();

  // The data required to create this enemy.
  final EnemyData enemyData;

  // Represents health of this enemy.
  int _hitPoints = 25;

  // To display health in game world.
  final _hpText = TextComponent(
    text: 'password',
    textRenderer: TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        // fontFamily: 'BungeeInline',
      ),
    ),
  );

  // This method generates a random vector with its angle
  // between from 0 and 360 degrees.
  Vector2 getRandomVector() {
    return (Vector2.random(_random) - Vector2.random(_random)) * 500;
  }

  // Vector2 getRandomVector() {
  //   // Calculate the position of the text component relative to the enemy's position
  //   Vector2 textPosition = position +
  //       Vector2(50, 80); // Adjust this according to your text position

  //   // Calculate the center of the text horizontally
  //   double textCenterX = textPosition.x + _hpText.width / 2;
  //   // print(textCenterX);

  //   // Calculate the position of the vector below the text vertically and at the center horizontally
  //   double vectorX =
  //       textCenterX - 250 / 2; // Adjust 250 according to your vector width
  //   double vectorY = textPosition.y + _hpText.height;
  //   return Vector2(vectorX, vectorY);
  // }

  // Returns a random direction vector with slight angle to +ve y axis.
  Vector2 getRandomDirection() {
    return (Vector2.random(_random) - Vector2(0.5, -1)).normalized();
  }

  List<String> badPasswords = [
    'rootuser',
    'mondayyy',
    'qwertyke',
    'administ',
    'letmeing',
    'user1234',
    'monkeyyq',
    '12345688',
    'password',
    '12345678',
  ];

  Enemy({
    required Sprite? sprite,
    required this.enemyData,
    required Vector2? position,
    required Vector2? size,
  }) : super(sprite: sprite, position: position, size: size) {
    // Rotates the enemy component by 180 degrees. This is needed because
    // all the sprites initially face the same direct, but we want enemies to be
    // moving in opposite direction.
    angle = pi;

    // Set the current speed from enemyData.
    _speed = enemyData.speed;

    // Set hitpoint to correct value from enemyData.
    _hitPoints = ((enemyData.level / 4) * 100) as int;
    // print(_hitPoints);

    _hpText.text = badPasswords[_random.nextInt(badPasswords.length)];
    // print(_hpText.text);

    // Sets freeze time to 2 seconds. After 2 seconds speed will be reset.
    _freezeTimer = Timer(2, onTick: () {
      _speed = enemyData.speed;
    });

    // If this enemy can move horizontally, randomize the move direction.
    if (enemyData.hMove) {
      moveDirection = getRandomDirection();
    }
  }

  @override
  void onMount() {
    super.onMount();

    // Adding a circular hitbox with radius as 0.8 times
    // the smallest dimension of this components size.
    final shape = CircleHitbox.relative(
      0.8,
      parentSize: size,
      position: size / 2,
      anchor: Anchor.center,
    );
    add(shape);

    // As current component is already rotated by pi radians,
    // the text component needs to be again rotated by pi radians
    // so that it is displayed correctly.
    _hpText.angle = pi;

    _hpText.text = badPasswords[_random.nextInt(badPasswords.length)];

    // To place the text just behind the enemy.
    _hpText.position = Vector2(70, 80);

    // Add as child of current component.
    add(_hpText);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Bullet) {
      // If the other Collidable is a Bullet,
      // reduce health by level of bullet times 10.
      _hitPoints -= other.level * 10;
      // int hitPoints = ((other.level / 4) * 10) as int;
      // final command = Command<Player>(action: (player) {
      //   // Use the correct killPoint to increase player's score.
      //   player.decreaseHealthBy(hitPoints);
      // });
      // game.addCommand(command);
    } else if (other is Player) {
      // If the other Collidable is Player, destroy.
      destroy();
    }
  }

  // This method will destroy this enemy.
  void destroy() {
    // Ask audio player to play enemy destroy effect.
    game.addCommand(Command<AudioPlayerComponent>(action: (audioPlayer) {
      audioPlayer.playSfx('laser1.ogg');
    }));

    removeFromParent();

    // Before dying, register a command to increase
    // player's score by 1.
    // final command = Command<Player>(action: (player) {
    //   // Use the correct killPoint to increase player's score.
    //   player.addToScore(enemyData.killPoint);
    // });
    // game.addCommand(command);

    // Generate 20 white circle particles with random speed and acceleration,
    // at current position of this enemy. Each particles lives for exactly
    // 0.1 seconds and will get removed from the game world after that.
    final particleComponent = ParticleSystemComponent(
      particle: Particle.generate(
        count: 20,
        lifespan: 0.1,
        generator: (i) => AcceleratedParticle(
          acceleration: getRandomVector(),
          speed: getRandomVector(),
          position: position.clone(),
          child: CircleParticle(
            radius: 2,
            paint: Paint()..color = Colors.white,
          ),
        ),
      ),
    );

    game.world.add(particleComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Sync-up text component and value of hitPoints.
    // _hpText.text = '$_hitPoints HP'; // Add Password Here

    // If hitPoints have reduced to zero,
    // destroy this enemy.
    if (_hitPoints <= 0) {
      destroy();
    }

    _freezeTimer.update(dt);

    // Update the position of this enemy using its speed and delta time.
    position += moveDirection * _speed * dt;

    // If the enemy leaves the screen, destroy it.
    if (position.y > game.fixedResolution.y - 100) {
      removeFromParent();
      final command = Command<Player>(action: (player) {
        // Use the correct killPoint to increase player's score.
        int decreaseScore = ((enemyData.level / 4) * 100) as int;
        player.decreaseHealthBy(decreaseScore);
      });
      game.addCommand(command);
      final particleComponent = ParticleSystemComponent(
        particle: Particle.generate(
          count: 15,
          lifespan: 0.3,
          generator: (i) => AcceleratedParticle(
            acceleration: getRandomVector(),
            speed: getRandomVector(),
            position: position.clone(),
            child: CircleParticle(
              radius: 3,
              paint: Paint()..color = Colors.white,
            ),
          ),
        ),
      );

      game.addCommand(Command<AudioPlayerComponent>(action: (audioPlayer) {
        audioPlayer.playSfx('laser1.ogg');
      }));
      game.world.add(particleComponent);
    } else if ((position.x < size.x / 2) ||
        (position.x > (game.fixedResolution.x - size.x / 2))) {
      // Enemy is going outside vertical screen bounds, flip its x direction.
      moveDirection.x *= -1;
    }
  }

  // Pauses enemy for 2 seconds when called.
  void freeze() {
    _speed = 0;
    _freezeTimer.stop();
    _freezeTimer.start();
  }
}
