class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final int memberCount;
  final List<dynamic>? members; // Can map to UserModel list if needed

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    required this.memberCount,
    this.members,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      createdBy: json['createdBy'] ?? '',
      memberCount: json['memberCount'] ?? 0,
      members: json['members'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'memberCount': memberCount,
      'members': members,
    };
  }
}
