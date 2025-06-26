class Product {
  final int id;
  final String name;
  final int locationId;
  final String? expirationDate;
  final int? quantity;
  final String? unit;
  final DateTime addedDate;

  Product({
    required this.id,
    required this.name,
    required this.locationId,
    this.expirationDate,
    this.quantity,
    this.unit,
    required this.addedDate,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      locationId: map['location_id'] as int,
      expirationDate: map['expiration_date'] as String?,
      quantity: map['quantity'] as int?,
      unit: map['unit'] as String?,
      addedDate: DateTime.parse(map['added_date'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location_id': locationId,
      'expiration_date': expirationDate,
      'quantity': quantity,
      'unit': unit,
      'added_date': addedDate.toIso8601String(),
    };
  }
}
