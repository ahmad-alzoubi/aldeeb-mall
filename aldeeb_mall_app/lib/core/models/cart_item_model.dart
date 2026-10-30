import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  double quantity;
  String? notes;

  CartItemModel({
    required this.product,
    this.quantity = 1.0,
    this.notes,
  });

  double get totalPrice => product.price * quantity;

  String get formattedQuantity {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    return quantity.toStringAsFixed(2);
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'notes': notes,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      notes: json['notes'] as String?,
    );
  }
}
