/// This class represents all the details required
/// to create an [Enemy] component.
class FriendData {
  // Speed of the Friend.
  final double speed;

  // Sprite ID from the main sprite sheet.
  final int spriteId;

  // Level of this Friend.
  final int level;

  // Indicates if this Friend can move horizontally.
  final bool hMove;

  // Points gains after destroying this Friend.
  final int killPoint;

  const FriendData({
    required this.speed,
    required this.spriteId,
    required this.level,
    required this.hMove,
    required this.killPoint,
  });
}
