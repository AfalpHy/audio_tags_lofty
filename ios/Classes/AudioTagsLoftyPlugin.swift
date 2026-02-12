import Flutter
import UIKit

@_silgen_name("lofty_read_metadata")
func lofty_read_metadata_raw(_ path: UnsafePointer<Int8>?) -> UnsafeMutableRawPointer?

@_silgen_name("lofty_read_picture")
func lofty_read_picture_raw(_ path: UnsafePointer<Int8>?) -> UnsafeMutableRawPointer?

@_silgen_name("lofty_free_metadata")
func lofty_free_metadata_raw(_ ptr: UnsafeMutableRawPointer?)

@_silgen_name("lofty_free_picture")
func lofty_free_picture_raw(_ ptr: UnsafeMutableRawPointer?)

public class AudioTagsLoftyPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        _ = lofty_read_metadata_raw(nil)
        _ = lofty_read_picture_raw(nil)
        lofty_free_metadata_raw(nil)
        lofty_free_picture_raw(nil)
    }
}