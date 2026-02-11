use lofty::tag::TagType;

#[unsafe(no_mangle)]
pub extern "C" fn lofty_supported_id3v2() -> u32 {
    matches!(TagType::Id3v2, TagType::Id3v2) as u32
}
