class Location {
  final int id;
  final String name;

  Location({required this.id, required this.name});

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(id: map['id'] as int, name: map['name'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}
