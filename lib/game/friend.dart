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

import '../models/friend_data.dart';

// This class represent an friend component.
class Friend extends SpriteComponent
    with CollisionCallbacks, HasGameReference<SpacescapeGame> {
  // The speed of this Friend.
  double _speed = 250;

  // This direction in which this Friend will move.
  // Defaults to vertically downwards.
  Vector2 moveDirection = Vector2(0, 1);

  // Controls for how long Friend should be frozen.
  late Timer _freezeTimer;

  // Holds an object of Random class to generate random numbers.
  final _random = Random();

  // The data required to create this Friend.
  final FriendData friendData;

  // Represents health of this friend.
  int _hitPoints = 0;

  // To display health in game world.
  final _hpText = TextComponent(
    text: '10 HP',
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
  //       textCenterX - 100; // Adjust 250 according to your vector width
  //   double vectorY = textPosition.y + _hpText.height;
  //   return Vector2(vectorX, vectorY);
  // }

  // Returns a random direction vector with slight angle to +ve y axis.
  Vector2 getRandomDirection() {
    return (Vector2.random(_random) - Vector2(0.5, -1)).normalized();
  }

  List<String> badPasswords = [
    'P@1sword',
    'Secur#2!',
    'StrngP@1',
    'Admin#12',
    'LetMe1n!',
    'User@123',
    'Monkey#1',
    '12Av@567',
    'P@s^word',
    '1#@bCdEf',
  ];

  Friend({
    required Sprite? sprite,
    required this.friendData,
    required Vector2? position,
    required Vector2? size,
  }) : super(sprite: sprite, position: position, size: size) {
    // Rotates the Friend component by 180 degrees. This is needed because
    // all the sprites initially face the same direct, but we want enemies to be
    // moving in opposite direction.
    angle = pi;

    // Set the current speed from FriendData.
    _speed = friendData.speed;

    // Set hitpoint to correct value from FriendData.
    _hitPoints = friendData.level * 10;
    _hpText.text = badPasswords[_random.nextInt(badPasswords.length)];
    // print(_hpText.text);

    // Sets freeze time to 2 seconds. After 2 seconds speed will be reset.
    _freezeTimer = Timer(2, onTick: () {
      _speed = friendData.speed;
    });

    // If this friend can move horizontally, randomize the move direction.
    if (friendData.hMove) {
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

    // To place the text just behind the friend.
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
    } else if (other is Player) {
      // If the other Collidable is Player, destroy.
      destroy();
    }
  }

  // This method will destroy this friend.
  void destroy() {
    // Ask audio player to play friend destroy effect.
    game.addCommand(Command<AudioPlayerComponent>(action: (audioPlayer) {
      audioPlayer.playSfx('laser1.ogg');
    }));

    removeFromParent();

    // Before dying, register a command to increase
    // player's score by 1.
    // final command = Command<Player>(action: (player) {
    //   // Use the correct killPoint to increase player's score.
    //   player.addToScore(friendData.killPoint);
    // });
    // game.addCommand(command);

    // Generate 20 white circle particles with random speed and acceleration,
    // at current position of this friend. Each particles lives for exactly
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
    // destroy this friend.
    if (_hitPoints <= 0) {
      destroy();
    }

    _freezeTimer.update(dt);

    // Update the position of this friend using its speed and delta time.
    position += moveDirection * _speed * dt;

    // If the friend leaves the screen, destroy it.
    if (position.y > game.fixedResolution.y) {
      final command = Command<Player>(action: (player) {
        // Use the correct killPoint to increase player's score.
        player.addToScore(friendData.killPoint);
      });
      game.addCommand(command);
      removeFromParent();
    } else if ((position.x < size.x / 2) ||
        (position.x > (game.fixedResolution.x - size.x / 2))) {
      // friend is going outside vertical screen bounds, flip its x direction.
      moveDirection.x *= -1;
    }
  }

  // Pauses friend for 2 seconds when called.
  void freeze() {
    _speed = 0;
    _freezeTimer.stop();
    _freezeTimer.start();
  }
}
