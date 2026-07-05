enum FavoriteItemType { provider, ad }

FavoriteItemType favoriteItemTypeFromValue(String? value) {
  switch (value) {
    case 'provider':
      return FavoriteItemType.provider;
    case 'ad':
    default:
      return FavoriteItemType.ad;
  }
}

extension FavoriteItemTypeX on FavoriteItemType {
  String get value {
    switch (this) {
      case FavoriteItemType.provider:
        return 'provider';
      case FavoriteItemType.ad:
        return 'ad';
    }
  }

  String get arabicLabel {
    switch (this) {
      case FavoriteItemType.provider:
        return 'مقدم خدمة';
      case FavoriteItemType.ad:
        return 'إعلان';
    }
  }
}

class FavoriteItem {
  const FavoriteItem({
    required this.favoriteId,
    required this.userId,
    required this.itemId,
    required this.type,
    required this.createdAt,
  });

  final String favoriteId;
  final String userId;
  final String itemId;
  final FavoriteItemType type;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'favoriteId': favoriteId,
      'userId': userId,
      'itemId': itemId,
      'type': type.value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      favoriteId: json['favoriteId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      itemId: json['itemId'] as String? ?? '',
      type: favoriteItemTypeFromValue(json['type'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
