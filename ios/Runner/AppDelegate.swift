import UIKit
import Flutter
import flutter_sharing_intent

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // 追加部分
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let sharingIntent = SwiftFlutterSharingIntentPlugin.instance
        print("[DEBUG] AppDelegateがURLを受信しました: \(url.absoluteString)")
        if sharingIntent.hasSameSchemePrefix(url: url) {
            let handled = sharingIntent.application(app, open: url, options: options)
            print("[DEBUG] flutter_sharing_intentがURLをハンドリングしました: \(handled)")
            return handled
        }

        // Proceed url handling for other Flutter libraries like uni_links
        let result = super.application(app, open: url, options:options)
        print("[DEBUG] super.applicationがURLをハンドリングしました: \(result)")
        return result
    }
}