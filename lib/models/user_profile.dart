import 'package:flutter/foundation.dart';

enum UserType { customer, retailer }

class UserProfileModel extends ChangeNotifier {
  String? _userId;
  String? _name;
  String? _email;
  UserType _userType = UserType.customer;

  String? get userId => _userId;
  String? get name => _name;
  String? get email => _email;
  UserType get userType => _userType;

  void updateProfile({
    String? userId,
    String? name,
    String? email,
    UserType? userType,
  }) {
    if (userId != null) _userId = userId;
    if (name != null) _name = name;
    if (email != null) _email = email;
    if (userType != null) _userType = userType;
    notifyListeners();
  }

  void clear() {
    _userId = null;
    _name = null;
    _email = null;
    _userType = UserType.customer;
    notifyListeners();
  }
}