import Flutter
import UIKit

@_silgen_name("lofty_read_picture")
func lofty_read_picture_raw(_ path: UnsafePointer<Int8>?) -> UnsafeMutableRawPointer?

public class AudioTagsLoftyPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // avoid dead code elimination
        _ = lofty_read_picture_raw(nil)
    }
}