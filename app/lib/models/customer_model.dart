class CustomerModel {
  final String id;
  final String name;
  final String mobile;
  final String address;
  final int balance; // in paise, >0 means customer owes shop
  final bool active;

  CustomerModel({
    required this.id,
    required this.name,
    this.mobile = '',
    this.address = '',
    this.balance = 0,
    this.active = true,
  });

  bool get hasBalance => balance > 0;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      address: json['address'] ?? '',
      balance: json['balance'] ?? 0,
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'address': address,
      'balance': balance,
      'active': active,
    };
  }
}

