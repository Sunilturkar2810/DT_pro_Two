class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String workEmail;
  final String role;
  final String designation;
  final String department;
  final String? mobileNumber;
  final String? manager;
  final String? profilePhotoUrl;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.workEmail,
    required this.role,
    required this.designation,
    required this.department,
    this.mobileNumber,
    this.manager,
    this.profilePhotoUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // ✅ 'userId' aur 'id' dono ko handle karein
      id: json['userId'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      workEmail: json['workEmail'] ?? '',
      role: json['role'] ?? 'User',
      designation: json['designation'] ?? '',
      department: json['department'] ?? 'General',
      mobileNumber: json['mobileNumber'],
      manager: json['manager'],
      profilePhotoUrl: json['profilePhotoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': id,
      'firstName': firstName,
      'lastName': lastName,
      'workEmail': workEmail,
      'role': role,
      'designation': designation,
      'department': department,
      'mobileNumber': mobileNumber,
      'manager': manager,
      'profilePhotoUrl': profilePhotoUrl,
    };
  }

  String get fullName => "$firstName $lastName";
}