import Flutter
import UIKit
import sharing_intent

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Share Extensionからのデータをチェック
    let sharedDefaults = UserDefaults(suiteName: "group.com.example.eventpixMobile")
    if let imageURL = sharedDefaults?.string(forKey: "sharedImageURL") {
      // 画像URLを処理
      sharedDefaults?.removeObject(forKey: "sharedImageURL")
    }
    if let text = sharedDefaults?.string(forKey: "sharedText") {
      // テキストを処理
      sharedDefaults?.removeObject(forKey: "sharedText")
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}