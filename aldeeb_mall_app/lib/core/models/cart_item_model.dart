import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  double quantity;
  String? notes;
  String substitutionPreference; // 'best_match', 'contact_me', 'do_not_replace'

  CartItemModel({
    required this.product,
    this.quantity = 1.0,
    this.notes,
    this.substitutionPreference = 'best_match',
  });

  double get totalPrice => product.price * quantity;
  String get productNameAr => product.nameAr;
  String get productNameEn => product.nameEn;
  String get productImage => product.firstImage;
  String get unit => product.unitLabelAr;
  double get unitPrice => product.price;

  String get substitutionLabelAr {
    switch (substitutionPreference) {
      case 'contact_me':
        return 'اتصل بي للاستشارة';
      case 'do_not_replace':
        return 'لا تستبدل، استرد المبلغ';
      case 'best_match':
      default:
        return 'استبدال بأفضل جودة';
    }
  }

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
