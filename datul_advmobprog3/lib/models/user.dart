class User {
  final int id;
  final String uid;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final int age;
  final String contactNo;
  final String gender;
  final String image;
  final String accessToken;
  final String refreshToken;
  final String loginType;

  User({
    required this.id,
    this.uid = '',
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.age = 0,
    this.contactNo = '',
    required this.gender,
    required this.image,
    required this.accessToken,
    required this.refreshToken,
    this.loginType = 'dummyJson',
  });

  /// Factory constructor to instantiate User from JSON / Map representation
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      uid: json['uid']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: (json['email'] ?? json['emailAddress'])?.toString() ?? '',
      firstName: (json['firstName'] ?? json['fName'])?.toString() ?? '',
      lastName: (json['lastName'] ?? json['lName'])?.toString() ?? '',
      age: json['age'] is int
          ? json['age'] as int
          : int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      contactNo: (json['contactNo'] ?? json['phone'])?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      accessToken: (json['accessToken'] ?? json['token'])?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      loginType: json['loginType']?.toString() ?? 'dummyJson',
    );
  }

  /// Convert User instance into JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'contactNo': contactNo,
      'phone': contactNo,
      'gender': gender,
      'image': image,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'token': accessToken,
      'loginType': loginType,
    };
  }

  /// Helper to return combined full name
  String get fullName => '$firstName $lastName'.trim();
}
