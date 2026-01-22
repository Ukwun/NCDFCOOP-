class User {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String? token;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      photoUrl: json['photoUrl'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'photoUrl': photoUrl,
    'token': token,
  };

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      token: token ?? this.token,
    );
  }
}
