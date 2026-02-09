/// Interface for persistent storage used by Infusion.
/// Allows swapping the underlying storage mechanism (e.g. SecureStorage vs Memory).
abstract class InfusionStoragePort {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}
