import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Keeps a durable on-device copy of shared media while the server remains the
/// source used to synchronize attachments between Android and the web client.
class MobileMediaStore {
  MobileMediaStore._();
  static final MobileMediaStore instance = MobileMediaStore._();

  Future<Directory> _mediaDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'resender_media'));
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  String _key(String value) {
    var hash = 0x811c9dc5;
    for (final byte in value.codeUnits) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  String _extension(String url, String? name) {
    final fromName = name == null ? '' : p.extension(name).toLowerCase();
    final fromUrl = Uri.tryParse(url)?.pathSegments.isNotEmpty == true
        ? p.extension(Uri.parse(url).pathSegments.last).toLowerCase()
        : '';
    final candidate = fromName.isNotEmpty ? fromName : fromUrl;
    if (RegExp(r'^\.[a-z0-9]{1,10}$').hasMatch(candidate)) return candidate;
    return '.bin';
  }

  Future<File> _target(String url, String? name) async {
    final dir = await _mediaDirectory();
    return File(p.join(dir.path, 'media_${_key(url)}${_extension(url, name)}'));
  }

  Future<File> cacheUrl(String url, {String? name}) async {
    final target = await _target(url, name);
    if (await target.exists() && await target.length() > 0) return target;

    final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 45),
        );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Media download failed (${response.statusCode})');
    }
    await target.writeAsBytes(response.bodyBytes, flush: true);
    return target;
  }

  Future<File> cacheLocalFile(String url, File source, {String? name}) async {
    final target = await _target(url, name ?? source.path);
    if (await target.exists() && await target.length() > 0) return target;
    return source.copy(target.path);
  }
}
