use lofty_ffi::*;
use std::ffi::CStr;
use std::os::raw::c_char;
use std::ptr::null;

unsafe fn print_cstr(label: &str, ptr: *mut c_char) {
    if ptr.is_null() {
        println!("{label}: <null>");
        return;
    }

    let s = unsafe { CStr::from_ptr(ptr).to_str().unwrap_or("<invalid utf8>") };

    println!("{label}: {s}");
}

#[test]
fn read_metadata_from_env_path() {
    let path = std::env::var("TEST_AUDIO_PATH").expect("please set TEST_AUDIO_PATH");

    let c_path = std::ffi::CString::new(path).unwrap();

    let meta = lofty_read_metadata(c_path.as_ptr(), false, null(), null());
    assert!(!meta.is_null());

    unsafe {
        let meta = &*meta;

        print_cstr("format", meta.format);

        print_cstr("title", meta.title);
        print_cstr("artist", meta.artist);
        print_cstr("album", meta.album);
        print_cstr("albumArtist", meta.album_artist);

        println!("duration_ms: {}", meta.duration_ms);

        print_cstr("lyrics", meta.lyrics);

        if meta.picture.is_null() {
            println!("picture: <none>");
        } else {
            println!("picture: <has picture>");
        }
    }

    lofty_free_metadata(meta);
}

// #[test]
// fn write_metadata_to_env_path() {
//     use std::ffi::CString;

//     let path = std::env::var("TEST_AUDIO_PATH").expect("please set TEST_AUDIO_PATH");
//     let c_path = CString::new(path.clone()).unwrap();

//     // Example new metadata
//     let new_title = CString::new("Test Title").unwrap();
//     let new_artist = CString::new("Test Artist").unwrap();
//     let new_album = CString::new("Test Album").unwrap();
//     let new_genre = CString::new("Test Genre").unwrap();
//     let new_lyrics = CString::new("These are test lyrics").unwrap();

//     // Optional: test picture (replace with actual bytes or null)
//     let picture_data: *const u8 = std::ptr::null();
//     let picture_len = 0;

//     let year: u32 = 2026;
//     let track: u32 = 1;
//     let track_total: u32 = 10;
//     let disc: u32 = 1;
//     let disc_total: u32 = 1;

//     // Call your FFI write function
//     let result = lofty_write_metadata(
//         c_path.as_ptr(),
//         new_title.as_ptr(),
//         new_artist.as_ptr(),
//         new_album.as_ptr(),
//         new_genre.as_ptr(),
//         new_lyrics.as_ptr(),
//         &year as *const u32,
//         &track as *const u32,
//         &track_total as *const u32,
//         &disc as *const u32,
//         &disc_total as *const u32,
//         picture_data,
//         picture_len,
//     );

//     assert!(result, "Failed to write metadata");

//     // Verify by reading back
//     let meta = lofty_read_metadata(c_path.as_ptr(), false);
//     assert!(!meta.is_null());

//     unsafe {
//         let meta = &*meta;

//         fn print_cstr(name: &str, ptr: *mut std::os::raw::c_char) {
//             if ptr.is_null() {
//                 println!("{}: <none>", name);
//             } else {
//                 let s = unsafe { std::ffi::CStr::from_ptr(ptr).to_string_lossy() };
//                 println!("{}: {}", name, s);
//             }
//         }

//         print_cstr("title", meta.title);
//         print_cstr("artist", meta.artist);
//         print_cstr("album", meta.album);
//         print_cstr("genre", meta.genre);
//         print_cstr("lyrics", meta.lyrics);

//         println!("year: {}", meta.year);
//         println!("track: {}/{}", meta.track, meta.track_total);
//         println!("disc: {}/{}", meta.disc, meta.disc_total);

//         if meta.picture.is_null() {
//             println!("picture: <none>");
//         } else {
//             println!("picture: <has picture>");
//         }
//     }

//     lofty_free_metadata(meta);
// }
