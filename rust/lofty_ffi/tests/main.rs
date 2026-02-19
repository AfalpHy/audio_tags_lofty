use lofty_ffi::*;
use std::ffi::CStr;
use std::os::raw::c_char;

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

    let meta = lofty_read_metadata(c_path.as_ptr(), false);
    assert!(!meta.is_null());

    unsafe {
        let meta = &*meta;

        print_cstr("title", meta.title);
        print_cstr("artist", meta.artist);
        print_cstr("album", meta.album);

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
