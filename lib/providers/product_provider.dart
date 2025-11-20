import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fresh/models/location.dart';
import 'package:fresh/models/product.dart';
import 'package:fresh/services/database_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

class ProductProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Product> _products = <Product>[];
  List<Product> _filteredProducts = <Product>[];
  List<Location> _locations = <Location>[];

  List<Product> get products => List<Product>.unmodifiable(_products);
  List<Product> get filteredProducts =>
      List<Product>.unmodifiable(_filteredProducts);
  List<Location> get locations => List<Location>.unmodifiable(_locations);

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  ProductProvider() {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings);

    // Запрос разрешений для Android 13+
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  Future<void> checkExpiringProducts() async {
    final expiringProducts = await getExpiringSoonProducts();
    final now = DateTime.now();

    for (final product in expiringProducts) {
      if (product.expirationDate == null) continue;

      final expiration = DateTime.parse(product.expirationDate!);
      final difference = expiration.difference(now).inDays;

      String? title;
      String? body;

      if (difference < 0) {
        title = 'Продукт просрочен';
        body = '${product.name} просрочен!';
      } else if (difference <= 3) {
        title = 'Продукт скоро истечет';
        body = '${product.name} истечет через $difference дня(дней)';
      }

      if (title != null && body != null) {
        await _notificationsPlugin.show(
          product.id,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'product_channel',
              'Product Notifications',
              channelDescription: 'Notifications about expiring products',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    }
  }

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
