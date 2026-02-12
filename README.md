# audio_tags_lofty

A Flutter FFI plugin based on [lofty](https://github.com/Serial-ATA/lofty-rs.git) for reading audio tags (writing not implemented yet).

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
final pictureBytes = readPicture(song.filePath);
~~~

## Important

On iOS, set **Strip Linked Product** to **No** in Xcode.  
Currently, I haven’t found a way to prevent the function symbols from being removed by the linker.
