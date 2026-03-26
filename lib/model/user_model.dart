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
  final String? teamId;
  final String? teamName;
  final bool? taskAccess;
  final bool? leaveAccess;
  
  // Remaining fields
  final String? personalEmail;
  final String? emergencyMobileNo;
  final String? dateOfBirth;
  final String? maritalStatus;
  final String? gender;
  final String? address;
  final String? city;
  final String? state;
  final String? nationality;
  final String? joiningDate;
  final String? currentSalary;

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
    this.teamId,
    this.teamName,
    this.taskAccess,
    this.leaveAccess,
    this.personalEmail,
    this.emergencyMobileNo,
    this.dateOfBirth,
    this.maritalStatus,
    this.gender,
    this.address,
    this.city,
    this.state,
    this.nationality,
    this.joiningDate,
    this.currentSalary,
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
      mobileNumber: json['mobileNumber']?.toString(),
      manager: json['manager'],
      profilePhotoUrl: json['profilePhotoUrl'],
      teamId: json['teamId']?.toString(),
      teamName: json['teamName']?.toString(),
      taskAccess: json['taskAccess'] is bool
          ? json['taskAccess'] as bool
          : json['taskAccess']?.toString().toLowerCase() == 'true',
      leaveAccess: json['leaveAccess'] is bool
          ? json['leaveAccess'] as bool
          : json['leaveAccess']?.toString().toLowerCase() == 'true',
      personalEmail: json['personalEmail'],
      emergencyMobileNo: json['emergencyMobileNo']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      maritalStatus: json['maritalStatus'],
      gender: json['gender'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      nationality: json['nationality'],
      joiningDate: json['joiningDate']?.toString(),
      currentSalary: json['currentSalary']?.toString(),
    );
  }

  factory UserModel.empty() {
    return UserModel(
      id: '',
      firstName: '',
      lastName: '',
      workEmail: '',
      role: '',
      designation: '',
      department: '',
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
      'teamId': teamId,
      'teamName': teamName,
      'taskAccess': taskAccess,
      'leaveAccess': leaveAccess,
      'personalEmail': personalEmail,
      'emergencyMobileNo': emergencyMobileNo,
      'dateOfBirth': dateOfBirth,
      'maritalStatus': maritalStatus,
      'gender': gender,
      'address': address,
      'city': city,
      'state': state,
      'nationality': nationality,
      'joiningDate': joiningDate,
      'currentSalary': currentSalary,
    };
  }

  String get fullName => "$firstName $lastName";
}
