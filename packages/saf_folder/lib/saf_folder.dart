import 'package:flutter/services.dart';

/// Satu berkas di folder pilihan.
typedef SafFile = ({String doc, String name, int size});

/// Gagal mengakses folder; [code]: no_permission, not_found, no_space, io.
class SafFolderException implements Exception {
  const SafFolderException(this.code, this.message);

  final String code;
  final String? message;

  @override
  String toString() => 'SafFolderException($code)';
}

/// Folder pilihan pengguna lewat Storage Access Framework.
class SafFolder {
  const SafFolder();

  static const MethodChannel _channel = MethodChannel('saf_folder');

  Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw SafFolderException(e.code, e.message);
    }
  }

  /// Buka pemilih folder (butuh layar). Null bila dibatalkan.
  Future<({String tree, String label})?> pick() async {
    final Map<Object?, Object?>? r = await _call<Map<Object?, Object?>>('pick');
    return r == null ? null : (tree: r['tree']! as String, label: r['label']! as String);
  }

  Future<bool> accessible(String tree) async => await _call<bool>('accessible', {'tree': tree}) ?? false;

  Future<List<SafFile>> list(String tree) async {
    final List<Object?> r = await _call<List<Object?>>('list', {'tree': tree}) ?? const [];
    return [
      for (final Object? e in r)
        if (e case final Map<Object?, Object?> m)
          (doc: m['doc']! as String, name: m['name']! as String, size: (m['size']! as num).toInt()),
    ];
  }

  Future<void> write(String tree, String name, Uint8List bytes) =>
      _call<String>('write', {'tree': tree, 'name': name, 'bytes': bytes});

  Future<void> delete(String doc) => _call<Object?>('delete', {'doc': doc});

  Future<void> release(String tree) => _call<Object?>('release', {'tree': tree});
}
