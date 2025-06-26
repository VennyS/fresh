import 'package:flutter/material.dart';
import 'package:fresh/models/location.dart';
import 'package:fresh/models/product.dart';
import 'package:fresh/services/database_service.dart';

class ProductProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Product> _products = <Product>[];
  List<Product> _filteredProducts = <Product>[];
  List<Location> _locations = <Location>[];

  List<Product> get products => List<Product>.unmodifiable(_products);
  List<Product> get filteredProducts =>
      List<Product>.unmodifiable(_filteredProducts);
  List<Location> get locations => List<Location>.unmodifiable(_locations);

  Future<void> loadData() async {
    final productsData = await _dbService.queryAllProducts();
    _products = productsData.map((map) => Product.fromMap(map)).toList();
    _filteredProducts = List<Product>.from(_products);

    final locationsData = await _dbService.getAllLocations();
    _locations = locationsData.map((map) => Location.fromMap(map)).toList();

    notifyListeners();
  }

  void filterProducts(String query) {
    _filteredProducts = query.isEmpty
        ? List<Product>.from(_products)
        : _products
              .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
              .toList();
    notifyListeners();
  }

  Future<void> addProduct({
    required String name,
    required int locationId,
    String? expirationDate,
    int? quantity,
    String? unit,
  }) async {
    await _dbService.addProduct(
      name: name,
      locationId: locationId,
      expirationDate: expirationDate,
      quantity: quantity,
      unit: unit,
    );
    await loadData();
  }

  Future<void> updateProduct(Product product) async {
    await _dbService.updateProduct(product.toMap());
    await loadData();
  }

  Future<void> deleteProduct(int id) async {
    await _dbService.deleteProduct(id);
    await loadData();
  }

  Future<void> addLocation(String name) async {
    await _dbService.createLocation(name);
    await loadData();
  }

  Future<void> deleteLocation(int id) async {
    await _dbService.deleteLocation(id);
    await loadData();
  }

  Future<void> updateLocation(int id, String name) async {
    await _dbService.updateLocation(id, name);
    await loadData();
  }

  String getLocationName(int locationId) {
    try {
      return _locations.firstWhere((loc) => loc.id == locationId).name;
    } catch (e) {
      return 'Unknown location';
    }
  }

  List<Product> getProductsByLocation(int locationId) {
    return _products.where((p) => p.locationId == locationId).toList();
  }

  Future<List<Product>> getExpiringSoonProducts() async {
    final data = await _dbService.getExpiringSoonProducts();
    return data.map(Product.fromMap).toList();
  }

  @override
  void dispose() {
    _dbService.close();
    super.dispose();
  }
}
