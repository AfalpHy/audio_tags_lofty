import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

final class LoftyPicture extends Struct {
  external Pointer<Uint8> data;
  @Uint64()
  external int len;
}

final class LoftyMetadata extends Struct {
  external Pointer<Utf8> title;
  external Pointer<Utf8> artist;
  external Pointer<Utf8> album;
  external Pointer<Utf8> genre;

  @Uint32()
  external int year;

  @Uint32()
  external int track;

  @Uint32()
  external int trackTotal;

  @Uint32()
  external int disc;

  @Uint32()
  external int discTotal;

  @Uint64()
  external int durationMs;

  @Uint32()
  external int bitrate;

  @Uint32()
  external int samplerate;

  external Pointer<Utf8> lyrics;
  external Pointer<LoftyPicture> picture;
}

DynamicLibrary _loadLib() {
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('liblofty_ffi.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('lofty_ffi.dll');
  }
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.process();
  }
  throw UnsupportedError('Unsupported platform');
}

final DynamicLibrary _lib = _loadLib();

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

typedef _WriteMetadataNative =
    Uint8 Function(
      Pointer<Utf8> path,
      Pointer<Utf8> title,
      Pointer<Utf8> artist,
      Pointer<Utf8> album,
      Pointer<Utf8> genre,
      Pointer<Utf8> lyrics,
      Pointer<Uint32> year,
      Pointer<Uint32> track,
      Pointer<Uint32> trackTotal,
      Pointer<Uint32> disc,
      Pointer<Uint32> discTotal,
      Pointer<Uint8> pictureData,
      Uint64 pictureLen,
    );

typedef _WriteMetadataDart =
    int Function(
      Pointer<Utf8> path,
      Pointer<Utf8> title,
      Pointer<Utf8> artist,
      Pointer<Utf8> album,
      Pointer<Utf8> genre,
      Pointer<Utf8> lyrics,
      Pointer<Uint32> year,
      Pointer<Uint32> track,
      Pointer<Uint32> trackTotal,
      Pointer<Uint32> disc,
      Pointer<Uint32> discTotal,
      Pointer<Uint8> pictureData,
      int pictureLen,
    );

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

final _loftyWriteMetadata = _lib
    .lookupFunction<_WriteMetadataNative, _WriteMetadataDart>(
      'lofty_write_metadata',
    );

class AudioMetadata {
  String? title;
  String? artist;
  String? album;
  String? genre;

  int? year;

  int? track;
  int? trackTotal;

  int? disc;
  int? discTotal;

  int? bitrate;
  int? samplerate;

  Duration? duration;
  String? lyrics;
  Uint8List? pictureBytes;

  AudioMetadata({
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.year,
    this.track,
    this.trackTotal,
    this.disc,
    this.discTotal,
    this.bitrate,
    this.samplerate,
    this.duration,
    this.lyrics,
    this.pictureBytes,
  });

  @override
  String toString() {
    return "Title: $title\n"
        "Artist: $artist\n"
        "Album: $album\n"
        "Genre: $genre\n"
        "Year: $year\n"
        "Track: $track/$trackTotal\n"
        "Disc: $disc/$discTotal\n"
        "Bitrate: $bitrate\n"
        "SampleRate: $samplerate\n"
        "Duration: $duration\n"
        "Lyrics: ${lyrics ?? 'N/A'}\n"
        "Picture: ${pictureBytes != null ? '${pictureBytes!.length} bytes' : 'None'}";
  }
}

AudioMetadata? readMetadata(String path, bool needPicture) {
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
    genre: meta.genre.toDartStringSafe(),
    year: meta.year == 0 ? null : meta.year,
    track: meta.track == 0 ? null : meta.track,
    trackTotal: meta.trackTotal == 0 ? null : meta.trackTotal,
    disc: meta.disc == 0 ? null : meta.disc,
    discTotal: meta.discTotal == 0 ? null : meta.discTotal,
    bitrate: meta.bitrate == 0 ? null : meta.bitrate,
    samplerate: meta.samplerate == 0 ? null : meta.samplerate,
    duration: Duration(milliseconds: meta.durationMs),
    lyrics: meta.lyrics.toDartStringSafe(),
    pictureBytes: pictureBytes,
  );

  _loftyFreeMetadata(metaPtr);
  return result;
}

Future<AudioMetadata?> readMetadataAsync(String path, bool needPicture) async {
  return Isolate.run(() => readMetadata(path, needPicture));
}

Uint8List? readPicture(String path) {
  final pathPtr = path.toNativeUtf8();
  final picPtr = _loftyReadPicture(pathPtr);
  calloc.free(pathPtr);

  if (picPtr == nullptr) return null;

  final pic = picPtr.ref;
  final data = Uint8List.fromList(pic.data.asTypedList(pic.len));
  _loftyFreePicture(picPtr);
  return data;
}

Future<Uint8List?> readPictureAsync(String path) async {
  return Isolate.run(() => readPicture(path));
}

/// ------------------------------------------------
/// String field rules:
/// - NULL  -> do not modify
/// - ""    -> delete
/// - other -> replace
///
/// Picture rules:
/// - pictureBytes != NULL -> write / replace
/// - pictureBytes == NULL && deletePicture == false -> do not modify
/// - pictureBytes == NULL && deletePicture == true  -> delete
/// ------------------------------------------------
bool writeMetadata({
  required String path,
  String? title,
  String? artist,
  String? album,
  String? genre,
  String? lyrics,
  int? year,
  int? track,
  int? trackTotal,
  int? disc,
  int? discTotal,
  Uint8List? pictureBytes,
  bool deletePicture = false,
}) {
  final pathPtr = path.toNativeUtf8();

  Pointer<Utf8> strPtr(String? value) {
    if (value == null) return nullptr;
    return value.toNativeUtf8();
  }

  Pointer<Uint32> intPtr(int? value) {
    if (value == null) return nullptr;
    final p = calloc<Uint32>();
    p.value = value;
    return p;
  }

  final titlePtr = strPtr(title);
  final artistPtr = strPtr(artist);
  final albumPtr = strPtr(album);
  final genrePtr = strPtr(genre);
  final lyricsPtr = strPtr(lyrics);

  final yearPtr = intPtr(year);
  final trackPtr = intPtr(track);
  final trackTotalPtr = intPtr(trackTotal);
  final discPtr = intPtr(disc);
  final discTotalPtr = intPtr(discTotal);

  Pointer<Uint8> picturePtr = nullptr;
  int pictureLen = 0;

  if (pictureBytes != null) {
    picturePtr = calloc<Uint8>(pictureBytes.length);
    picturePtr.asTypedList(pictureBytes.length).setAll(0, pictureBytes);
    pictureLen = pictureBytes.length;
  } else if (deletePicture) {
    picturePtr = nullptr;
    pictureLen = 1;
  }

  final result = _loftyWriteMetadata(
    pathPtr,
    titlePtr,
    artistPtr,
    albumPtr,
    genrePtr,
    lyricsPtr,
    yearPtr,
    trackPtr,
    trackTotalPtr,
    discPtr,
    discTotalPtr,
    picturePtr,
    pictureLen,
  );

  calloc.free(pathPtr);
  if (titlePtr != nullptr) calloc.free(titlePtr);
  if (artistPtr != nullptr) calloc.free(artistPtr);
  if (albumPtr != nullptr) calloc.free(albumPtr);
  if (genrePtr != nullptr) calloc.free(genrePtr);
  if (lyricsPtr != nullptr) calloc.free(lyricsPtr);

  if (yearPtr != nullptr) calloc.free(yearPtr);
  if (trackPtr != nullptr) calloc.free(trackPtr);
  if (trackTotalPtr != nullptr) calloc.free(trackTotalPtr);
  if (discPtr != nullptr) calloc.free(discPtr);
  if (discTotalPtr != nullptr) calloc.free(discTotalPtr);

  if (picturePtr != nullptr) calloc.free(picturePtr);

  return result != 0;
}

Future<bool> writeMetadataAsync({
  required String path,
  String? title,
  String? artist,
  String? album,
  String? genre,
  String? lyrics,
  int? year,
  int? track,
  int? trackTotal,
  int? disc,
  int? discTotal,
  Uint8List? pictureBytes,
  bool deletePicture = false,
}) async {
  return Isolate.run(
    () => writeMetadata(
      path: path,
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      lyrics: lyrics,
      year: year,
      track: track,
      trackTotal: trackTotal,
      disc: disc,
      discTotal: discTotal,
      pictureBytes: pictureBytes,
      deletePicture: deletePicture,
    ),
  );
}

extension PointerUtf8Safe on Pointer<Utf8> {
  String? toDartStringSafe() {
    if (this == nullptr) return null;
    return toDartString();
  }
}
