class RoomModel {
  final String id;
  final String name;
  final List<String> userIds;
  final DateTime createdAt;
  final String? imageUrl;

  RoomModel({
    required this.id,
    required this.name,
    required this.userIds,
    required this.createdAt,
    this.imageUrl,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'],
      name: json['name'],
      userIds: List<String>.from(json['userIds']),
      createdAt: DateTime.parse(json['createdAt']),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userIds': userIds,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }
}