use std::ffi::{c_char, CStr, CString};
use std::ptr;

use lofty::file::TaggedFileExt;
use lofty::prelude::AudioFile;
use lofty::probe::Probe;
use lofty::tag::ItemKey;

/// ---------------------------
/// Picture struct (bytes)
/// ---------------------------
#[repr(C)]
pub struct LoftyPicture {
    pub data: *mut u8,
    pub len: usize,
}

/// ---------------------------
/// Metadata struct (FFI-safe)
/// ---------------------------
#[repr(C)]
pub struct LoftyMetadata {
    pub title: *mut c_char,
    pub artist: *mut c_char,
    pub album: *mut c_char,
    pub duration_ms: u64,
    pub lyrics: *mut c_char,
    pub picture: *mut LoftyPicture, // optional picture
}

/// ---------------------------
/// Read metadata + optional picture
/// ---------------------------
#[unsafe(no_mangle)]
pub extern "C" fn lofty_read_metadata(
    path: *const c_char,
    need_picture: bool,
) -> *mut LoftyMetadata {
    if path.is_null() {
        return ptr::null_mut();
    }

    let path = unsafe {
        match CStr::from_ptr(path).to_str() {
            Ok(v) => v,
            Err(_) => return ptr::null_mut(),
        }
    };

    let tagged_file = match Probe::open(path).and_then(|p| p.read()) {
        Ok(v) => v,
        Err(_) => return ptr::null_mut(),
    };

    let tag = tagged_file.primary_tag();

    let get_string = |key: ItemKey| -> *mut c_char {
        tag.and_then(|t| t.get_string(key))
            .map(|s| {
                // s is Cow<'_, str>, convert explicitly to &str
                let s_ref: &str = s.as_ref();
                CString::new(s_ref).unwrap().into_raw()
            })
            .unwrap_or(ptr::null_mut())
    };

    // Lyrics support
    let lyrics = tag
        .and_then(|t| t.get_string(ItemKey::Lyrics))
        .map(|s| {
            let s_ref: &str = s.as_ref(); // explicitly convert Cow<str> -> &str
            CString::new(s_ref).unwrap().into_raw()
        })
        .unwrap_or(ptr::null_mut());

    // Picture support
    let picture = if need_picture {
        if let Some(t) = tag {
            let pics = t.pictures();
            if !pics.is_empty() {
                let p = &pics[0];
                let mut data = p.data().to_vec();
                let len = data.len();
                let ptr = data.as_mut_ptr();
                std::mem::forget(data);
                Box::into_raw(Box::new(LoftyPicture { data: ptr, len }))
            } else {
                ptr::null_mut()
            }
        } else {
            ptr::null_mut()
        }
    } else {
        ptr::null_mut()
    };

    let meta = LoftyMetadata {
        title: get_string(ItemKey::TrackTitle),
        artist: get_string(ItemKey::TrackArtist),
        album: get_string(ItemKey::AlbumTitle),
        duration_ms: tagged_file.properties().duration().as_millis() as u64,
        lyrics,
        picture,
    };

    Box::into_raw(Box::new(meta))
}

/// ---------------------------
/// Free metadata
/// ---------------------------
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
        if !meta.lyrics.is_null() {
            drop(CString::from_raw(meta.lyrics));
        }
        if !meta.picture.is_null() {
            lofty_free_picture(meta.picture);
        }
    }
}

/// ---------------------------
/// Read first embedded picture (or NULL)
/// ---------------------------
#[unsafe(no_mangle)]
pub extern "C" fn lofty_read_picture(path: *const c_char) -> *mut LoftyPicture {
    if path.is_null() {
        return ptr::null_mut();
    }

    let path = unsafe {
        match CStr::from_ptr(path).to_str() {
            Ok(v) => v,
            Err(_) => return ptr::null_mut(),
        }
    };

    let tagged_file = match Probe::open(path).and_then(|p| p.read()) {
        Ok(v) => v,
        Err(_) => return ptr::null_mut(),
    };

    let tag = match tagged_file.primary_tag() {
        Some(t) => t,
        None => return ptr::null_mut(),
    };

    let pictures = tag.pictures();
    if pictures.is_empty() {
        return ptr::null_mut();
    }
    let picture = &pictures[0];

    let mut data = picture.data().to_vec();
    let len = data.len();
    let ptr = data.as_mut_ptr();

    std::mem::forget(data);

    Box::into_raw(Box::new(LoftyPicture { data: ptr, len }))
}

/// ---------------------------
/// Free picture bytes
/// ---------------------------
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
