class Category {
  final String id;
  final String name;
  final String description;
  final String color; // Hex color code
  final String iconName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.iconName,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor for creating Category from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      color: json['color'] as String? ?? '#2196F3',
      iconName: json['iconName'] as String? ?? 'category',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Convert Category to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'iconName': iconName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy of Category with updated fields
  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    String? iconName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, color: $color)';
  }

  // Default categories
  static List<Category> get defaultCategories {
    final now = DateTime.now();
    return [
      Category(
        id: '1',
        name: 'Work',
        description: 'Work related tasks',
        color: '#FF5722',
        iconName: 'work',
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: '2',
        name: 'Personal',
        description: 'Personal tasks and activities',
        color: '#4CAF50',
        iconName: 'person',
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: '3',
        name: 'Shopping',
        description: 'Shopping lists and purchases',
        color: '#FF9800',
        iconName: 'shopping_cart',
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: '4',
        name: 'Health',
        description: 'Health and fitness related',
        color: '#E91E63',
        iconName: 'favorite',
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: '5',
        name: 'Education',
        description: 'Learning and education',
        color: '#3F51B5',
        iconName: 'school',
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: '6',
        name: 'Finance',
        description: 'Financial planning and budgeting',
        color: '#009688',
        iconName: 'account_balance_wallet',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
