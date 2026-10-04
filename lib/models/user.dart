class UserModel {
  static const int defaultAnalysisLimit = 10;

  static const Map<String, bool> defaultNotificationPrefs = {
    'pushNotifications': true,
    'labResults': true,
    'healthTips': true,
    'testReminders': true,
    'weeklyReport': true,
    'dietaryReminders': false,
    'promotions': false,
    'appUpdates': false,
  };

  final String id;
  final String email;
  final String username;
  final int age;
  final String? photoUrl;
  final DateTime createdAt;
  // Only an admin can change analysisLimit; Firestore rules let the user
  // raise analysesUsed by exactly one while it is below the limit.
  final int analysisLimit;
  final int analysesUsed;
  final String firstName;
  final String lastName;
  final String phone;
  final String city;
  final String country;
  final Map<String, bool> notificationPrefs;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.age,
    this.photoUrl,
    required this.createdAt,
    this.analysisLimit = defaultAnalysisLimit,
    this.analysesUsed = 0,
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.city = '',
    this.country = '',
    this.notificationPrefs = defaultNotificationPrefs,
  });

  int get remainingAnalyses => (analysisLimit - analysesUsed).clamp(0, analysisLimit);

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : username;
  }

  String get initial => displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final prefs = json['notificationPrefs'] as Map<String, dynamic>?;
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      age: json['age'] as int,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      analysisLimit: json['analysisLimit'] as int? ?? defaultAnalysisLimit,
      analysesUsed: json['analysesUsed'] as int? ?? 0,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      notificationPrefs: {
        ...defaultNotificationPrefs,
        if (prefs != null) ...prefs.map((k, v) => MapEntry(k, v == true)),
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'age': age,
    'photoUrl': photoUrl,
    'createdAt': createdAt.toIso8601String(),
    'analysisLimit': analysisLimit,
    'analysesUsed': analysesUsed,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'city': city,
    'country': country,
    'notificationPrefs': notificationPrefs,
  };

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    int? age,
    String? photoUrl,
    DateTime? createdAt,
    int? analysisLimit,
    int? analysesUsed,
    String? firstName,
    String? lastName,
    String? phone,
    String? city,
    String? country,
    Map<String, bool>? notificationPrefs,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      age: age ?? this.age,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      analysisLimit: analysisLimit ?? this.analysisLimit,
      analysesUsed: analysesUsed ?? this.analysesUsed,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      country: country ?? this.country,
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
    );
  }
}
