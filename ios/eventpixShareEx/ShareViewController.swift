import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        handleIncomingContent()
    }

    private func handleIncomingContent() {
        if let item = extensionContext?.inputItems.first as? NSExtensionItem {
            // 画像を取得
            if let attachments = item.attachments {
                for attachment in attachments {
                    if attachment.hasItemConformingToTypeIdentifier("public.image") {
                        attachment.loadItem(forTypeIdentifier: "public.image", options: nil) { (data, error) in
                            if let imageURL = data as? URL {
                                self.saveToAppGroup(imageURL: imageURL)
                            }
                        }
                    } else if attachment.hasItemConformingToTypeIdentifier("public.text") {
                        // テキストを取得
                        attachment.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
                            if let text = data as? String {
                                self.saveToAppGroup(text: text)
                            }
                        }
                    }
                }
            }
        }
    }

    private func saveToAppGroup(imageURL: URL? = nil, text: String? = nil) {
        // App Groupで共有するためのUserDefaultsをセットアップ
        let sharedDefaults = UserDefaults(suiteName: "group.com.example.myapp")

        // 画像のURLを保存
        if let imageURL = imageURL {
            sharedDefaults?.set(imageURL.absoluteString, forKey: "sharedImageURL")
        }

        // テキストを保存
        if let text = text {
            sharedDefaults?.set(text, forKey: "sharedText")
        }
        
        sharedDefaults?.synchronize()
        
        // 完了したらExtensionを閉じる
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
