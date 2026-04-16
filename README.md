# audio_tags_lofty

A Flutter FFI plugin based on [lofty](https://github.com/Serial-ATA/lofty-rs.git) for reading and writing audio tags.

## Supported Formats

| File Format | Metadata Format(s)           |
|-------------|------------------------------|
| AAC (ADTS)  | `ID3v2`, `ID3v1`             |
| Ape         | `APE`, `ID3v2`\*, `ID3v1`    |
| AIFF        | `ID3v2`, `Text Chunks`       |
| FLAC        | `Vorbis Comments`, `ID3v2`\* |
| MP3         | `ID3v2`, `ID3v1`, `APE`      |
| MP4         | `iTunes-style ilst`          |
| MPC         | `APE`, `ID3v2`\*, `ID3v1`\*  |
| Opus        | `Vorbis Comments`            |
| Ogg Vorbis  | `Vorbis Comments`            |
| Speex       | `Vorbis Comments`            |
| WAV         | `ID3v2`, `RIFF INFO`         |
| WavPack     | `APE`, `ID3v1`               |

\* The tag will be **read only**, due to lack of official support

## Usage

~~~dart
class AudioMetadata {
  String? format;
  String? title;
  String? artist;
  String? album;
  String? albumArtist;
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
  albumArtist: albumArtist,
  genre: genre,
  year: year,
  track: track,
  trackTotal: trackTotal,
  disc: disc,
  discTotal: discTotal,
  lyrics: lyrics,
  pictureBytes: pictureBytes,
  deletePicture: false
);
~~~
