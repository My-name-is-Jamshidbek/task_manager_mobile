class Contact {
  final int id;
  final String name;
  final String phone;
  final String? avatarUrl;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    this.avatarUrl,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'phone': phone, 'avatar_url': avatarUrl};
  }

  /// Get display name (prioritize name, fallback to phone)
  String get displayName => name.isNotEmpty ? name : phone;

  /// Check if contact is online (placeholder for future implementation)
  bool get isOnline => false; // TODO: Implement real online status

  /// Create a copy with modified fields
  Contact copyWith({int? id, String? name, String? phone, String? avatarUrl}) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Contact{id: $id, name: $name, phone: $phone, avatarUrl: $avatarUrl}';
  }
}

class ContactsResponse {
  final List<Contact> data;
  final Map<String, dynamic> links;
  final Map<String, dynamic> meta;

  ContactsResponse({
    required this.data,
    required this.links,
    required this.meta,
  });

  factory ContactsResponse.fromJson(Map<String, dynamic> json) {
    return ContactsResponse(
      data: (json['data'] as List)
          .map((item) => Contact.fromJson(item as Map<String, dynamic>))
          .toList(),
      links: json['links'] as Map<String, dynamic>? ?? {},
      meta: json['meta'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((contact) => contact.toJson()).toList(),
      'links': links,
      'meta': meta,
    };
  }
}
