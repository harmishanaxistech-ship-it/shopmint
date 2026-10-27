class UserModel {
  final String id;
  final String mobile;
  final String name;
  final String shopName;
  final String role;
  final String language;

  UserModel({
    required this.id,
    required this.mobile,
    required this.name,
    required this.shopName,
    required this.role,
    this.language = 'gu',
  });

  bool get isAdmin => role == 'admin';
  bool get isOwner => role == 'owner';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      mobile: json['mobile'] ?? '',
      name: json['name'] ?? '',
      shopName: json['shopName'] ?? '',
      role: json['role'] ?? 'owner',
      language: json['language'] ?? 'gu',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mobile': mobile,
      'name': name,
      'shopName': shopName,
      'role': role,
      'language': language,
    };
  }
}

