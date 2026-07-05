import '../../../shared/models/favorite_models.dart';
import '../../../shared/services/app_storage_service.dart';

class FavoriteRepository {
  FavoriteRepository(this._storage);

  final AppStorageService _storage;

  List<FavoriteItem> getFavoritesForUser(String userId) {
    final List<FavoriteItem> items = _storage
        .loadFavorites()
        .where((FavoriteItem item) => item.userId == userId)
        .toList(growable: false);
    items.sort((FavoriteItem a, FavoriteItem b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  bool isFavorite({
    required String userId,
    required String itemId,
    required FavoriteItemType type,
  }) {
    return _storage.loadFavorites().any(
          (FavoriteItem item) =>
              item.userId == userId && item.itemId == itemId && item.type == type,
        );
  }

  Future<bool> toggleFavorite({
    required String userId,
    required String itemId,
    required FavoriteItemType type,
  }) async {
    final List<FavoriteItem> items = _storage.loadFavorites().toList(growable: true);
    final int index = items.indexWhere(
      (FavoriteItem item) => item.userId == userId && item.itemId == itemId && item.type == type,
    );
    if (index >= 0) {
      items.removeAt(index);
      await _storage.saveFavorites(items);
      return false;
    }
    items.add(
      FavoriteItem(
        favoriteId: _generateId('favorite'),
        userId: userId,
        itemId: itemId,
        type: type,
        createdAt: DateTime.now(),
      ),
    );
    await _storage.saveFavorites(items);
    return true;
  }

  Future<void> removeFavorite({
    required String userId,
    required String itemId,
    required FavoriteItemType type,
  }) async {
    final List<FavoriteItem> items = _storage
        .loadFavorites()
        .where(
          (FavoriteItem item) =>
              !(item.userId == userId && item.itemId == itemId && item.type == type),
        )
        .toList(growable: true);
    await _storage.saveFavorites(items);
  }

  String _generateId(String prefix) {
    final int stamp = DateTime.now().microsecondsSinceEpoch;
    return '$prefix-$stamp';
  }
}
