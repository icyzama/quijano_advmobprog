enum LoginType {
  dummyJson,
  firebase,
}

extension LoginTypeLabel on LoginType {
  String get storageValue {
    switch (this) {
      case LoginType.dummyJson:
        return 'dummyJson';
      case LoginType.firebase:
        return 'firebase';
    }
  }

  String get label {
    switch (this) {
      case LoginType.dummyJson:
        return 'DummyJSON';
      case LoginType.firebase:
        return 'Firebase';
    }
  }

  static LoginType fromStorage(String? value) {
    switch (value) {
      case 'firebase':
        return LoginType.firebase;
      case 'dummyJson':
      default:
        return LoginType.dummyJson;
    }
  }
}

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final int? age;
  final String image;
  final String? accessToken;
  final String? refreshToken;
  final LoginType loginType;
  final String? firebaseUid;
  final String contactNumber;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.image,
    this.age,
    this.accessToken,
    this.refreshToken,
    this.loginType = LoginType.dummyJson,
    this.firebaseUid,
    this.contactNumber = '',
  });

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? username : name;
  }

  bool get hasAuthToken => accessToken != null && accessToken!.isNotEmpty;
  bool get isFirebase => loginType == LoginType.firebase;
  bool get isDummyJson => loginType == LoginType.dummyJson;

  // Enhancement 3: User model used for profile data and user-specific cart retrieval.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      age: (json['age'] as num?)?.toInt(),
      image: json['image'] as String? ?? '',
      accessToken:
          (json['accessToken'] as String?) ?? (json['token'] as String?),
      refreshToken: json['refreshToken'] as String?,
      loginType: LoginTypeLabel.fromStorage(json['loginType'] as String?),
      firebaseUid: json['firebaseUid'] as String?,
      contactNumber: json['contactNumber'] as String? ?? '',
    );
  }

  factory User.firebaseProfile({
    required String firebaseUid,
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    required int age,
    required String contactNumber,
    String image = '',
  }) {
    return User(
      id: 0,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      gender: '',
      age: age,
      image: image,
      loginType: LoginType.firebase,
      firebaseUid: firebaseUid,
      contactNumber: contactNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'age': age,
      'image': image,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'loginType': loginType.storageValue,
      'firebaseUid': firebaseUid,
      'contactNumber': contactNumber,
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? gender,
    int? age,
    String? image,
    String? accessToken,
    String? refreshToken,
    LoginType? loginType,
    String? firebaseUid,
    String? contactNumber,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      image: image ?? this.image,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      loginType: loginType ?? this.loginType,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      contactNumber: contactNumber ?? this.contactNumber,
    );
  }
}
