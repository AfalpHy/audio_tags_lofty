# audio_tags_lofty

A Flutter FFI plugin based on [lofty](https://github.com/Serial-ATA/lofty-rs.git) for reading and writing audio tags.

## Usage

~~~dart
class AudioMetadata {
  String? title;
  String? artist;
  String? album;
  Duration? duration;
  String? lyrics;
  Uint8List? pictureBytes;
}

final metadata = readMetadata(path, true /* need picture */);
final pictureBytes = readPicture(path);

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
final success = writeMetadata(
  path: path,
  title: title,
  artist: artist,
  album: album,
  lyrics: lyrics,
  pictureBytes: pictureBytes,
  deletePicture: false
);
~~~

## Important

On iOS, set **Strip Linked Product** to **No** in Xcode.  
Currently, I haven’t found a way to prevent the function symbols from being removed by the linker.
