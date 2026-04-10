use std::ffi::{c_char, CStr, CString};
use std::ptr;

use lofty::file::{TaggedFile, TaggedFileExt};
use lofty::prelude::AudioFile;

use lofty::{
    config::{ParseOptions, ParsingMode, WriteOptions},
    picture::{Picture, PictureType},
    probe::Probe,
    tag::{Accessor, ItemKey, Tag},
};

mod http_file;
use http_file::HttpFile;

use tempfile::NamedTempFile;

#[repr(C)]
pub struct LoftyPicture {
    pub data: *mut u8,
    pub len: usize,
}

#[repr(C)]
pub struct LoftyMetadata {
    pub title: *mut c_char,
    pub artist: *mut c_char,
    pub album: *mut c_char,
    pub genre: *mut c_char,
    pub year: u32,
    pub track: u32,
    pub track_total: u32,
    pub disc: u32,
    pub disc_total: u32,
    pub bitrate: u32,
    pub samplerate: u32,
    pub duration_ms: u64,
    pub lyrics: *mut c_char,
    pub picture: *mut LoftyPicture,
}

fn c_path<'a>(ptr: *const c_char) -> Option<&'a str> {
    if ptr.is_null() {
        return None;
    }
    unsafe { CStr::from_ptr(ptr).to_str().ok() }
}

fn to_c_string(s: &str) -> *mut c_char {
    CString::new(s)
        .map(|c| c.into_raw())
        .unwrap_or(ptr::null_mut())
}

fn read_tagged_file(path: &str, need_picture: bool) -> Option<TaggedFile> {
    if path.starts_with("http://") || path.starts_with("https://") {
        let http = HttpFile::new(path, if need_picture { 1024 } else { 512 })?;

        return Probe::new(http)
            .guess_file_type()
            .ok()?
            .options(
                ParseOptions::new()
                    .parsing_mode(ParsingMode::Relaxed)
                    .read_cover_art(need_picture),
            )
            .read()
            .ok();
    }

    Probe::open(path)
        .ok()?
        .guess_file_type()
        .ok()?
        .options(
            ParseOptions::new()
                .parsing_mode(ParsingMode::Relaxed)
                .read_cover_art(need_picture),
        )
        .read()
        .ok()
}

fn build_picture(tag: Option<&Tag>) -> *mut LoftyPicture {
    let picture = tag
        .and_then(|t| t.pictures().first())
        .map(|p| p.data().to_vec());

    match picture {
        Some(mut data) => {
            let len = data.len();
            let ptr = data.as_mut_ptr();
            std::mem::forget(data);
            Box::into_raw(Box::new(LoftyPicture { data: ptr, len }))
        }
        None => ptr::null_mut(),
    }
}

fn get_string(tag: Option<&Tag>, key: ItemKey) -> *mut c_char {
    tag.and_then(|t| t.get_string(key))
        .map(|s| to_c_string(s.as_ref()))
        .unwrap_or(ptr::null_mut())
}

fn get_year(tag: Option<&Tag>) -> u32 {
    tag.and_then(|t| t.get_string(ItemKey::RecordingDate))
        .and_then(|s| s.get(0..4))
        .and_then(|s| s.parse::<u32>().ok())
        .unwrap_or(0)
}

#[unsafe(no_mangle)]
pub extern "C" fn lofty_read_metadata(
    path: *const c_char,
    need_picture: bool,
) -> *mut LoftyMetadata {
    let path = match c_path(path) {
        Some(p) => p,
        None => return ptr::null_mut(),
    };

    let tagged_file = match read_tagged_file(path, need_picture) {
        Some(v) => v,
        None => return ptr::null_mut(),
    };

    let tag = tagged_file.primary_tag();
    let props = tagged_file.properties();

    let meta = LoftyMetadata {
        title: get_string(tag, ItemKey::TrackTitle),
        artist: get_string(tag, ItemKey::TrackArtist),
        album: get_string(tag, ItemKey::AlbumTitle),
        genre: get_string(tag, ItemKey::Genre),

        year: get_year(tag),

        track: tag.and_then(|t| t.track()).unwrap_or(0) as u32,
        track_total: tag.and_then(|t| t.track_total()).unwrap_or(0) as u32,

        disc: tag.and_then(|t| t.disk()).unwrap_or(0) as u32,
        disc_total: tag.and_then(|t| t.disk_total()).unwrap_or(0) as u32,

        bitrate: props.audio_bitrate().unwrap_or(0) as u32,
        samplerate: props.sample_rate().unwrap_or(0) as u32,

        duration_ms: props.duration().as_millis() as u64,
        lyrics: get_string(tag, ItemKey::Lyrics),
        picture: if need_picture {
            build_picture(tag)
        } else {
            ptr::null_mut()
        },
    };

    Box::into_raw(Box::new(meta))
}

#[unsafe(no_mangle)]
pub extern "C" fn lofty_read_picture(path: *const c_char) -> *mut LoftyPicture {
    let path = match c_path(path) {
        Some(p) => p,
        None => return ptr::null_mut(),
    };

    let tagged_file = match read_tagged_file(path, true) {
        Some(v) => v,
        None => return ptr::null_mut(),
    };

    build_picture(tagged_file.primary_tag())
}

#[unsafe(no_mangle)]
pub extern "C" fn lofty_free_metadata(meta: *mut LoftyMetadata) {
    if meta.is_null() {
        return;
    }

    unsafe {
        let meta = Box::from_raw(meta);

        if !meta.title.is_null() {
            drop(CString::from_raw(meta.title));
        }
        if !meta.artist.is_null() {
            drop(CString::from_raw(meta.artist));
        }
        if !meta.album.is_null() {
            drop(CString::from_raw(meta.album));
        }
        if !meta.genre.is_null() {
            drop(CString::from_raw(meta.genre));
        }
        if !meta.lyrics.is_null() {
            drop(CString::from_raw(meta.lyrics));
        }
        if !meta.picture.is_null() {
            lofty_free_picture(meta.picture);
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn lofty_free_picture(pic: *mut LoftyPicture) {
    if pic.is_null() {
        return;
    }

    unsafe {
        let pic = Box::from_raw(pic);
        drop(Vec::from_raw_parts(pic.data, pic.len, pic.len));
    }
}

/// Rules:
/// - value == NULL  -> do not modify
/// - value == ""    -> delete the field
/// - otherwise      -> replace the field
fn apply_string_field(tag: &mut Tag, key: ItemKey, value: *const c_char) -> Result<(), ()> {
    if value.is_null() {
        return Ok(());
    }

    let value = unsafe { CStr::from_ptr(value).to_str().map_err(|_| ())? };

    tag.remove_key(key);

    if !value.is_empty() {
        tag.insert_text(key, value.to_string());
    }

    Ok(())
}

fn get_u32(ptr: *const u32) -> Option<u32> {
    if ptr.is_null() {
        None
    } else {
        Some(unsafe { *ptr })
    }
}

fn apply_year_field(tag: &mut Tag, value: Option<u32>) {
    if value.is_none() {
        return;
    }

    tag.remove_key(ItemKey::RecordingDate);

    if let Some(v) = value {
        if v != 0 {
            tag.insert_text(ItemKey::RecordingDate, v.to_string());
        }
    }
}

fn apply_number_pair(
    tag: &mut Tag,
    current: Option<u32>,
    total: Option<u32>,
    set_current: fn(&mut Tag, u32),
    set_total: fn(&mut Tag, u32),
) {
    if let Some(c) = current {
        if c != 0 {
            set_current(tag, c);
        }
    }

    if let Some(t) = total {
        if t != 0 {
            set_total(tag, t);
        }
    }
}

/// Rules:
/// - data == NULL && len == 0  -> do not modify
/// - data == NULL && len != 0  -> delete picture
/// - data != NULL && len > 0   -> write / replace picture
/// - otherwise                 -> invalid
fn apply_picture_field(tag: &mut Tag, data: *const u8, len: usize) -> Result<(), ()> {
    if data.is_null() {
        if len == 0 {
            return Ok(());
        }

        while !tag.pictures().is_empty() {
            tag.remove_picture(0);
        }
        return Ok(());
    }

    if len == 0 {
        return Err(());
    }

    let bytes = unsafe { std::slice::from_raw_parts(data, len) };

    while !tag.pictures().is_empty() {
        tag.remove_picture(0);
    }

    let picture = Picture::unchecked(bytes.to_vec())
        .pic_type(PictureType::CoverFront)
        .build();

    tag.push_picture(picture);

    Ok(())
}

#[unsafe(no_mangle)]
pub extern "C" fn lofty_write_metadata(
    path: *const c_char,
    title: *const c_char,
    artist: *const c_char,
    album: *const c_char,
    genre: *const c_char,
    lyrics: *const c_char,
    year: *const u32,
    track: *const u32,
    track_total: *const u32,
    disc: *const u32,
    disc_total: *const u32,
    picture_data: *const u8,
    picture_len: usize,
) -> bool {
    let original_path = match c_path(path) {
        Some(p) => p,
        None => return false,
    };

    let mut temp_file_opt: Option<NamedTempFile> = None;
    let path_str: &str;

    if original_path.starts_with("http://") || original_path.starts_with("https://") {
        let tmp = match download_http_to_temp(original_path) {
            Some(f) => f,
            None => return false,
        };
        // Move tmp into temp_file_opt first
        temp_file_opt = Some(tmp);
        // Then safely get a reference to the path
        path_str = temp_file_opt
            .as_ref()
            .unwrap()
            .path()
            .to_str()
            .unwrap_or("");
    } else {
        path_str = original_path;
    }

    let mut tagged_file = match read_tagged_file(path_str, true) {
        Some(v) => v,
        None => return false,
    };

    let tag = match tagged_file.primary_tag_mut() {
        Some(t) => t,
        None => return false,
    };

    if apply_string_field(tag, ItemKey::TrackTitle, title).is_err()
        || apply_string_field(tag, ItemKey::TrackArtist, artist).is_err()
        || apply_string_field(tag, ItemKey::AlbumTitle, album).is_err()
        || apply_string_field(tag, ItemKey::Genre, genre).is_err()
        || apply_string_field(tag, ItemKey::Lyrics, lyrics).is_err()
        || apply_picture_field(tag, picture_data, picture_len).is_err()
    {
        return false;
    }

    apply_year_field(tag, get_u32(year));

    apply_number_pair(
        tag,
        get_u32(track),
        get_u32(track_total),
        Tag::set_track,
        Tag::set_track_total,
    );

    apply_number_pair(
        tag,
        get_u32(disc),
        get_u32(disc_total),
        Tag::set_disk,
        Tag::set_disk_total,
    );

    let result = tagged_file
        .save_to_path(path_str, WriteOptions::default())
        .is_ok();

    if let Some(tmp) = temp_file_opt {
        if !upload_temp_to_http(original_path, &tmp) {
            return false;
        }
    }

    result
}

fn download_http_to_temp(url: &str) -> Option<tempfile::NamedTempFile> {
    let client = reqwest::blocking::Client::new();
    let mut resp = client.get(url).send().ok()?;
    if !resp.status().is_success() {
        eprintln!("Download failed: {}", resp.status());
        return None;
    }
    let mut tmp = tempfile::NamedTempFile::new().ok()?;
    std::io::copy(&mut resp, &mut tmp).ok()?;
    Some(tmp)
}

fn upload_temp_to_http(url: &str, tmp: &tempfile::NamedTempFile) -> bool {
    let client = reqwest::blocking::Client::new();
    let bytes = match std::fs::read(tmp.path()) {
        Ok(b) => b,
        Err(_) => return false,
    };

    client
        .put(url)
        .body(bytes)
        .send()
        .map(|r| r.status().is_success())
        .unwrap_or(false)
}
