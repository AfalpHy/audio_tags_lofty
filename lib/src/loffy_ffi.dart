import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

/// ---------------------------
/// FFI structs
/// ---------------------------
final class LoftyPicture extends Struct {
  external Pointer<Uint8> data;
  @Uint64()
  external int len;
}

final class LoftyMetadata extends Struct {
  external Pointer<Utf8> title;
  external Pointer<Utf8> artist;
  external Pointer<Utf8> album;
  @Uint64()
  external int durationMs;
  external Pointer<Utf8> lyrics;
  external Pointer<LoftyPicture> picture; // optional
}

/// ---------------------------
/// Load Rust library
/// ---------------------------
final DynamicLibrary _lib = DynamicLibrary.open('lib/liblofty_ffi.so');

/// ---------------------------
/// FFI function bindings
/// ---------------------------
typedef _ReadMetadataNative =
    Pointer<LoftyMetadata> Function(Pointer<Utf8> path, Uint8 needPicture);
typedef _ReadMetadataDart =
    Pointer<LoftyMetadata> Function(Pointer<Utf8> path, int needPicture);

typedef _ReadPictureNative = Pointer<LoftyPicture> Function(Pointer<Utf8> path);
typedef _ReadPictureDart = Pointer<LoftyPicture> Function(Pointer<Utf8> path);

typedef _FreeMetadataNative = Void Function(Pointer<LoftyMetadata>);
typedef _FreeMetadataDart = void Function(Pointer<LoftyMetadata>);

typedef _FreePictureNative = Void Function(Pointer<LoftyPicture>);
typedef _FreePictureDart = void Function(Pointer<LoftyPicture>);

final _loftyReadMetadata = _lib
    .lookupFunction<_ReadMetadataNative, _ReadMetadataDart>(
      'lofty_read_metadata',
    );

final _loftyReadPicture = _lib
    .lookupFunction<_ReadPictureNative, _ReadPictureDart>('lofty_read_picture');

final _loftyFreeMetadata = _lib
    .lookupFunction<_FreeMetadataNative, _FreeMetadataDart>(
      'lofty_free_metadata',
    );

final _loftyFreePicture = _lib
    .lookupFunction<_FreePictureNative, _FreePictureDart>('lofty_free_picture');

/// ---------------------------
/// Dart wrapper classes
/// ---------------------------
class AudioMetadata {
  final String? title;
  final String? artist;
  final String? album;
  final int durationMs;
  final String? lyrics;
  final Uint8List? pictureBytes;

  AudioMetadata({
    this.title,
    this.artist,
    this.album,
    required this.durationMs,
    this.lyrics,
    this.pictureBytes,
  });

  @override
  String toString() {
    return "Title: $title\n"
        "Artist: $artist\n"
        "Album: $album\n"
        "Duration: ${Duration(milliseconds: durationMs)}\n"
        "Lyrics: ${lyrics ?? 'N/A'}\n"
        "Picture: ${pictureBytes != null ? '${pictureBytes!.length} bytes' : 'None'}";
  }
}

/// ---------------------------
/// Read metadata + optional picture
/// ---------------------------
AudioMetadata? getAudioMetadata(String path, needPicture) {
  final pathPtr = path.toNativeUtf8();
  final metaPtr = _loftyReadMetadata(pathPtr, needPicture ? 1 : 0);
  calloc.free(pathPtr);

  if (metaPtr == nullptr) return null;

  final meta = metaPtr.ref;

  Uint8List? pictureBytes;
  if (meta.picture != nullptr) {
    final pic = meta.picture.ref;
    pictureBytes = Uint8List.fromList(pic.data.asTypedList(pic.len));
  }

  final result = AudioMetadata(
    title: meta.title.toDartStringSafe(),
    artist: meta.artist.toDartStringSafe(),
    album: meta.album.toDartStringSafe(),
    durationMs: meta.durationMs,
    lyrics: meta.lyrics.toDartStringSafe(),
    pictureBytes: pictureBytes,
  );

  _loftyFreeMetadata(metaPtr);
  return result;
}

/// ---------------------------
/// Read only picture
/// ---------------------------
Uint8List? getAudioPicture(String path) {
  final pathPtr = path.toNativeUtf8();
  final picPtr = _loftyReadPicture(pathPtr);
  calloc.free(pathPtr);

  if (picPtr == nullptr) return null;

  final pic = picPtr.ref;
  final data = Uint8List.fromList(pic.data.asTypedList(pic.len));
  _loftyFreePicture(picPtr);
  return data;
}

/// ---------------------------
/// Extension: safely convert nullable Pointer
/// ---------------------------
extension PointerUtf8Safe on Pointer<Utf8> {
  String? toDartStringSafe() {
    if (this == nullptr) return null;
    return toDartString();
  }
}
