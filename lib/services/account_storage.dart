import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'backend_api.dart';
import '../models/remedy_data.dart';

class UserProfile {
  final String name;
  final String gender;
  final String email;
  final String phone;
  final String place;
  final String userType;
  final String username;
  final DateTime createdAt;

  const UserProfile({
    required this.name,
    required this.gender,
    required this.email,
    required this.phone,
    required this.place,
    required this.userType,
    required this.username,
    required this.createdAt,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    final first = parts.first[0];
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'gender': gender,
        'email': email,
        'phone': phone,
        'place': place,
        'userType': userType,
        'username': username,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      place: json['place'] as String? ?? '',
      userType: json['userType'] as String? ?? '',
      username: json['username'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ShippingDetails {
  final String name;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String pincode;

  const ShippingDetails({
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
  });

  Map<String, String> toJson() => {
        'name': name.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'city': city.trim(),
        'state': state.trim(),
        'pincode': pincode.trim(),
      };
}

class RemedyOrder {
  final String id;
  final String remedyId;
  final String remedyName;
  final int price;
  final int quantity;
  final int unitPrice;
  final String status;
  final String paymentId;
  final DateTime? validityStartsAt;
  final DateTime? validityEndsAt;
  final DateTime purchasedAt;

  const RemedyOrder({
    this.id = '',
    required this.remedyId,
    required this.remedyName,
    required this.price,
    this.quantity = 1,
    this.unitPrice = 0,
    this.status = 'confirmed',
    this.paymentId = '',
    this.validityStartsAt,
    this.validityEndsAt,
    required this.purchasedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'remedyId': remedyId,
        'remedyName': remedyName,
        'price': price,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'status': status,
        'paymentId': paymentId,
        'validityStartsAt': validityStartsAt?.toIso8601String(),
        'validityEndsAt': validityEndsAt?.toIso8601String(),
        'purchasedAt': purchasedAt.toIso8601String(),
      };

  factory RemedyOrder.fromJson(Map<String, dynamic> json) {
    return RemedyOrder(
      id: json['id'] as String? ?? '',
      remedyId: json['remedyId'] as String? ?? '',
      remedyName: json['remedyName'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toInt() ??
          (json['price'] as num?)?.toInt() ??
          0,
      status: json['status'] as String? ?? 'confirmed',
      paymentId: json['paymentId'] as String? ?? '',
      validityStartsAt:
          DateTime.tryParse(json['validityStartsAt'] as String? ?? ''),
      validityEndsAt:
          DateTime.tryParse(json['validityEndsAt'] as String? ?? ''),
      purchasedAt: DateTime.tryParse(json['purchasedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class PaymentSession {
  final String purchaseId;
  final String checkoutUrl;
  final int amount;

  const PaymentSession({
    required this.purchaseId,
    required this.checkoutUrl,
    required this.amount,
  });
}

class CartLine {
  final RemedyItem remedy;
  final int quantity;

  const CartLine({required this.remedy, required this.quantity});

  int get total => remedy.price * quantity;

  Map<String, dynamic> toJson() => {
        'remedy': remedy.toJson(),
        'quantity': quantity,
      };

  factory CartLine.fromJson(Map<String, dynamic> json) => CartLine(
        remedy: RemedyItem.fromJson(
          json['remedy'] as Map<String, dynamic>? ?? const {},
        ),
        quantity: ((json['quantity'] as num?)?.toInt() ?? 1).clamp(1, 20),
      );
}

class AccountStorage extends ChangeNotifier {
  static const _profileKey = 'divinewall.profile.v1';
  static const _ordersKey = 'divinewall.orders.v1';
  static const _tokenKey = 'divinewall.sessionToken.v1';
  static const _cartKey = 'divinewall.cart.v1';

  final BackendApi _api;

  AccountStorage({BackendApi? api}) : _api = api ?? BackendApi();

  UserProfile? _profile;
  List<RemedyOrder> _orders = [];
  String? _token;
  List<CartLine> _cart = [];
  bool _loaded = false;

  UserProfile? get profile => _profile;
  List<RemedyOrder> get orders => List.unmodifiable(_orders);
  bool get loaded => _loaded;
  bool get hasAccount => _profile != null;
  bool get isLoggedIn => _profile != null && (_token?.isNotEmpty ?? false);
  List<CartLine> get cart => List.unmodifiable(_cart);
  int get cartCount => _cart.fold(0, (sum, line) => sum + line.quantity);
  int get cartTotal => _cart.fold(0, (sum, line) => sum + line.total);

  RemedyOrder? activePurchaseFor(String remedyId) {
    for (final order in _orders) {
      if (order.remedyId == remedyId &&
          order.status == 'paid' &&
          order.validityEndsAt != null &&
          order.validityEndsAt!.isAfter(DateTime.now())) {
        return order;
      }
    }
    return null;
  }

  Future<void> load() async {
    if (_loaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawProfile = prefs.getString(_profileKey);
      if (rawProfile != null && rawProfile.isNotEmpty) {
        _profile = UserProfile.fromJson(
          jsonDecode(rawProfile) as Map<String, dynamic>,
        );
      }
      _token = prefs.getString(_tokenKey);

      final rawOrders = prefs.getString(_ordersKey);
      if (rawOrders != null && rawOrders.isNotEmpty) {
        final decoded = jsonDecode(rawOrders) as List<dynamic>;
        _orders = decoded
            .map((item) => RemedyOrder.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      final rawCart = prefs.getString(_cartKey);
      if (rawCart != null && rawCart.isNotEmpty) {
        final decoded = jsonDecode(rawCart) as List<dynamic>;
        _cart = decoded
            .map((item) => CartLine.fromJson(item as Map<String, dynamic>))
            .where((line) => line.remedy.id.isNotEmpty)
            .toList();
      }
      await _refreshFromBackend();
    } catch (e) {
      debugPrint('Kubar Vastu: Failed to load account: $e');
      _profile = null;
      _orders = [];
      _token = null;
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String gender,
    required String email,
    required String phone,
    required String place,
    required String userType,
    required String username,
    required String password,
  }) async {
    final response = await _api.register(
      name: name,
      gender: gender,
      email: email,
      phone: phone,
      place: place,
      userType: userType,
      username: username,
      password: password,
    );
    if (response != null) {
      await _applyAuthResponse(response);
      return;
    }
    throw Exception('Backend URL is not configured');
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final response = await _api.login(username: username, password: password);
    if (response == null) {
      throw Exception('Backend URL is not configured');
    }
    await _applyAuthResponse(response);
  }

  Future<void> addOrder(RemedyOrder order) async {
    _orders.insert(0, order);
    notifyListeners();
    final synced = await _syncOrder(order);
    if (synced != null) {
      _orders[0] = synced;
      notifyListeners();
    }
    await _persistOrders();
  }

  Future<void> addToCart(RemedyItem remedy) async {
    final index = _cart.indexWhere((line) => line.remedy.id == remedy.id);
    if (index < 0) {
      _cart.add(CartLine(remedy: remedy, quantity: 1));
    } else {
      final line = _cart[index];
      _cart[index] = CartLine(
        remedy: remedy,
        quantity: (line.quantity + 1).clamp(1, 20),
      );
    }
    notifyListeners();
    await _persistCart();
  }

  Future<void> setCartQuantity(String remedyId, int quantity) async {
    final index = _cart.indexWhere((line) => line.remedy.id == remedyId);
    if (index < 0) return;
    if (quantity <= 0) {
      _cart.removeAt(index);
    } else {
      _cart[index] = CartLine(
        remedy: _cart[index].remedy,
        quantity: quantity.clamp(1, 20),
      );
    }
    notifyListeners();
    await _persistCart();
  }

  Future<List<RemedyOrder>> checkoutCart() async {
    if (!isLoggedIn || _profile == null || _token == null) {
      throw Exception('Please login before checkout.');
    }
    if (_cart.isEmpty) throw Exception('Your cart is empty.');
    final response = await _api.checkoutCart(
      email: _profile!.email,
      token: _token!,
      items: _cart
          .map((line) => {
                'remedyId': line.remedy.id,
                'quantity': line.quantity,
              })
          .toList(),
    );
    if (response == null) throw Exception('Backend URL is not configured.');
    final purchased = (response['orders'] as List<dynamic>? ?? const [])
        .map((item) => RemedyOrder.fromJson(item as Map<String, dynamic>))
        .toList();
    _orders = [...purchased, ..._orders];
    _cart.clear();
    notifyListeners();
    await Future.wait([_persistOrders(), _persistCart()]);
    return purchased;
  }

  Future<PaymentSession> createPaymentSession(ShippingDetails shipping) async {
    if (!isLoggedIn || _token == null) {
      throw Exception('Please login before payment.');
    }
    if (_cart.isEmpty) throw Exception('Your cart is empty.');
    final response = await _api.createPayment(
      token: _token!,
      shipping: shipping.toJson(),
      returnUrl: kIsWeb
          ? Uri.base
              .replace(
                path: '/',
                queryParameters: const {'payment': 'success'},
                fragment: '',
              )
              .toString()
          : null,
      items: _cart
          .map((line) => {
                'remedyId': line.remedy.id,
                'quantity': line.quantity,
              })
          .toList(),
    );
    if (response == null) throw Exception('Backend URL is not configured.');
    return PaymentSession(
      purchaseId: response['purchaseId'] as String? ?? '',
      checkoutUrl: response['checkoutUrl'] as String? ?? '',
      amount: (response['amount'] as num?)?.toInt() ?? cartTotal,
    );
  }

  Future<bool> refreshPayment(PaymentSession session) async {
    final token = _token;
    if (token == null || token.isEmpty) return false;
    final response = await _api.fetchPaymentStatus(
      purchaseId: session.purchaseId,
      token: token,
    );
    if (response == null || response['status'] != 'paid') return false;
    final purchased = (response['orders'] as List<dynamic>? ?? const [])
        .map((item) => RemedyOrder.fromJson(item as Map<String, dynamic>))
        .toList();
    _orders = [
      ...purchased,
      ..._orders.where(
        (existing) => !purchased.any((item) => item.id == existing.id),
      ),
    ];
    _cart.clear();
    notifyListeners();
    await Future.wait([_persistOrders(), _persistCart()]);
    return true;
  }

  Future<void> deleteAccount(String password) async {
    final token = _token;
    if (token == null || token.isEmpty) throw Exception('Please login first');
    // Never clear the session unless the server confirms deletion.
    await _api.deleteAccount(token, password);
    _token = null;
    _cart.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('kubar.content.v1.testimonials');
    await signOut();
    await _persistCart();
  }

  Future<void> signOut() async {
    final token = _token;
    if (token != null && token.isNotEmpty) {
      try {
        await _api.logout(token);
      } catch (e) {
        debugPrint('Kubar Vastu: Backend logout failed: $e');
      }
    }
    _profile = null;
    _token = null;
    _orders = [];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_profileKey),
      prefs.remove(_tokenKey),
      prefs.remove(_ordersKey),
    ]);
  }

  Future<void> _applyAuthResponse(Map<String, dynamic> response) async {
    final user = response['user'] as Map<String, dynamic>? ?? {};
    _profile = UserProfile.fromJson(user);
    _token = response['token'] as String?;
    if (_profile!.username.isEmpty || (_token?.isEmpty ?? true)) {
      _profile = null;
      _token = null;
      throw Exception('Invalid authentication response from server');
    }
    await _persistProfile();
    await _persistToken();
    await _refreshFromBackend();
    notifyListeners();
  }

  Future<void> _persistProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = _profile;
    if (profile == null) {
      await prefs.remove(_profileKey);
    } else {
      await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    }
  }

  Future<void> _persistOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ordersKey,
      jsonEncode(_orders.map((order) => order.toJson()).toList()),
    );
  }

  Future<void> _persistCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cartKey,
      jsonEncode(_cart.map((line) => line.toJson()).toList()),
    );
  }

  Future<void> _persistToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = _token;
    if (token == null || token.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  Future<void> _refreshFromBackend() async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    try {
      final response = await _api.fetchMe(token);
      if (response == null) return;
      final user = response['user'] as Map<String, dynamic>? ?? {};
      final orders = response['orders'] as List<dynamic>? ?? const [];
      _profile = UserProfile.fromJson(user);
      _orders = orders
          .map((item) => RemedyOrder.fromJson(item as Map<String, dynamic>))
          .toList();
      await _persistProfile();
      await _persistOrders();
    } catch (e) {
      debugPrint('Kubar Vastu: Backend session refresh failed: $e');
    }
  }

  Future<RemedyOrder?> _syncOrder(RemedyOrder order) async {
    final profile = _profile;
    if (profile == null) return null;
    try {
      final response = await _api.saveOrder(
        email: profile.email,
        remedyId: order.remedyId,
        token: _token,
      );
      final synced = response?['order'] as Map<String, dynamic>?;
      return synced == null ? null : RemedyOrder.fromJson(synced);
    } catch (e) {
      debugPrint('Kubar Vastu: Backend order sync failed: $e');
      return null;
    }
  }
}
