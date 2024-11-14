//
//  ShareViewController.swift
//  shareExtension_new
//
//  Created by mars I on 2024/11/14.
//

import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

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
        let sharedDefaults = UserDefaults(suiteName: "group.com.example.eventpixMobile.shareExtension_new")

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