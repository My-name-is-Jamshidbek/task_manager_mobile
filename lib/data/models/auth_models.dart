import '../../core/utils/multilingual_message.dart';

class LoginRequest {
  final String phone;
  final String password;

  LoginRequest({required this.phone, required this.password});

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'password': password};
  }
}

class LoginResponse {
  final bool success;
  final MultilingualMessage? message;
  final String? token;
  final User? user;

  LoginResponse({required this.success, this.message, this.token, this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // If we have a token and user, consider it successful
    // The API might not always send an explicit 'success' field
    final hasToken = json['token'] != null;
    final hasUser = json['user'] != null;
    final explicitSuccess = json['success'] ?? false;

    return LoginResponse(
      success: explicitSuccess || (hasToken && hasUser),
      message: json['message'] != null
          ? MultilingualMessage.fromJson(json['message'])
          : null,
      token: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  /// Gets the message in the current app language
  String? getLocalizedMessage() {
    return message?.getMessage();
  }
}

class User {
  final int? id;
  final String? name;
  final String? phone;
  final String? email;

  /// Avatar relative or absolute URL (server may return avatar or avatar_url)
  final String? avatar;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.avatar,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Support both avatar and avatar_url keys
    final rawAvatar = json['avatar'] ?? json['avatar_url'];
    return User(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      avatar: rawAvatar,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'avatar': avatar,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VerifyRequest {
  final String phone;
  final String code;

  VerifyRequest({required this.phone, required this.code});

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'code': code};
  }
}

class VerifyResponse {
  final bool success;
  final MultilingualMessage? message;
  final String? token;
  final User? user;

  VerifyResponse({required this.success, this.message, this.token, this.user});

  factory VerifyResponse.fromJson(Map<String, dynamic> json) {
    return VerifyResponse(
      success: json['success'] ?? false,
      message: json['message'] != null
          ? MultilingualMessage.fromJson(json['message'])
          : null,
      token: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  /// Gets the message in the current app language
  String? getLocalizedMessage() {
    return message?.getMessage();
  }
}

class TokenVerifyResponse {
  final MultilingualMessage message;
  final User? user;
  final bool tokenValid;

  TokenVerifyResponse({
    required this.message,
    this.user,
    required this.tokenValid,
  });

  factory TokenVerifyResponse.fromJson(Map<String, dynamic> json) {
    return TokenVerifyResponse(
      message: MultilingualMessage.fromJson(json['message']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      tokenValid: json['token_valid'] ?? false,
    );
  }

  /// Gets the message in the current app language
  String getLocalizedMessage() {
    return message.getMessage();
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message.toJson(),
      'user': user?.toJson(),
      'token_valid': tokenValid,
    };
  }
}

class PasswordChangeResponse {
  final MultilingualMessage message;

  PasswordChangeResponse({required this.message});

  factory PasswordChangeResponse.fromJson(Map<String, dynamic> json) {
    return PasswordChangeResponse(
      message: json['message'] != null
          ? MultilingualMessage.fromJson(json['message'])
          : const MultilingualMessage(), // fallback to empty message
    );
  }

  /// Gets the message in the current app language
  String getLocalizedMessage() {
    return message.getMessage();
  }

  Map<String, dynamic> toJson() {
    return {'message': message.toJson()};
  }
}

class ProfileUpdateResponse {
  final User user;
  final MultilingualMessage? message;

  ProfileUpdateResponse({required this.user, this.message});

  factory ProfileUpdateResponse.fromJson(Map<String, dynamic> json) {
    return ProfileUpdateResponse(
      user: User.fromJson(json['data'] ?? json), // Handle nested data structure
      message: json['message'] != null
          ? MultilingualMessage.fromJson(json['message'])
          : null,
    );
  }

  /// Gets the message in the current app language
  String? getLocalizedMessage() {
    return message?.getMessage();
  }

  Map<String, dynamic> toJson() {
    return {
      ...user.toJson(),
      if (message != null) 'message': message!.toJson(),
    };
  }
}
