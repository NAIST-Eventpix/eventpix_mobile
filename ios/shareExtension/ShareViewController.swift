import UIKit
import Social
import MobileCoreServices
import Photos
import UniformTypeIdentifiers
import AVFoundation
import ImageIO

@objc(ShareViewController)
class ShareViewController: UIViewController {
    // TODO: IMPORTANT: This should be your host app bundle identifier
    var hostAppBundleIdentifier = "group.com.example.eventpixMobile"
    let sharedKey = "SharingKey"
    var appGroupId = ""
    var sharedMedia: [SharingFile] = []
    var sharedText: [String] = []

    let imageContentType = UTType.image.identifier;
    let videoContentType = UTType.movie.identifier;
    let textContentType = UTType.text.identifier;
    let urlContentType = UTType.url.identifier;
    let fileURLType = UTType.fileURL.identifier;

    override func viewDidLoad() {
        super.viewDidLoad()
        print("[DEBUG] viewDidLoadが呼び出されました。")
        // load group and app id from build info
        loadIds()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("[DEBUG] viewDidAppearが呼び出されました。")

        // UIActivityIndicatorViewを追加して処理中であることを表示
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        print("[DEBUG] UIActivityIndicatorViewを表示しました。")
        
        // 非同期で画像処理を実行
        DispatchQueue.main.async { [weak self] in
            print("[DEBUG] handleImageAttachmentを非同期で実行します。")
            self?.handleImageAttachment()
        }
    }

    private func loadIds() {
        print("[DEBUG] loadIds()を開始します。")
        // loading Share extension App Id
        guard let shareExtensionAppBundleIdentifier = Bundle.main.bundleIdentifier else {
            print("[ERROR] bundleIdentifierの取得に失敗しました。")
            dismissWithError("バンドル識別子の取得に失敗しました。")
            return
        }
        print("[DEBUG] Share Extensionのバンドル識別子: \(shareExtensionAppBundleIdentifier)")
        
        // convert ShareExtension id to host app id
        // By default it is remove last part of id after last point
        // For example: com.test.ShareExtension -> com.test
        guard let lastIndexOfPoint = shareExtensionAppBundleIdentifier.lastIndex(of: ".") else {
            print("[ERROR] バンドル識別子にピリオドが含まれていません。")
            dismissWithError("バンドル識別子の解析に失敗しました。")
            return
        }
        hostAppBundleIdentifier = String(shareExtensionAppBundleIdentifier[..<lastIndexOfPoint])
        print("[DEBUG] ホストアプリのバンドル識別子: \(hostAppBundleIdentifier)")

        // loading custom AppGroupId from Build Settings or use group.<hostAppBundleIdentifier>
        appGroupId = (Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String) ?? "group.\(hostAppBundleIdentifier)"
        print("[DEBUG] AppGroupId: \(appGroupId)")
    }

    func handleImageAttachment(){
        print("[DEBUG] handleImageAttachmentを開始します。")
        if let content = self.extensionContext?.inputItems.first as? NSExtensionItem {
            print("[DEBUG] NSExtensionItemを取得しました。")
            if let contents = content.attachments {
                print("[DEBUG] アタッチメントが存在します。件数: \(contents.count)")
                for (index, attachment) in (contents).enumerated() {
                    print("[DEBUG] アタッチメント\(index)を処理します。タイプ: \(attachment)")
                    if attachment.isImage {
                        print("[DEBUG] アタッチメントが画像です。")
                        handleImages(content: content, attachment: attachment, index: index)
                    } else if attachment.isMovie {
                        print("[DEBUG] アタッチメントが動画です。")
                        handleVideos(content: content, attachment: attachment, index: index)
                    }
                    else if attachment.isFile {
                        print("[DEBUG] アタッチメントがファイルです。")
                        handleFiles(content: content, attachment: attachment, index: index)
                    }
                    else if attachment.isURL {
                        print("[DEBUG] アタッチメントがURLです。")
                        handleUrl(content: content, attachment: attachment, index: index)
                    }
                    else if attachment.isText {
                        print("[DEBUG] アタッチメントがテキストです。")
                        handleText(content: content, attachment: attachment, index: index)
                    } else {
                        print(" \(attachment) File type is not supported by flutter sharing plugin.")
                    }
                }
            } else {
                print("[ERROR] アタッチメントが存在しません。")
                dismissWithError("共有アイテムの取得に失敗しました。")
            }
        } else {
            print("[ERROR] inputItemsが存在しません。")
            dismissWithError("共有アイテムの取得に失敗しました。")
        }
    }

    private func handleText(content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        print("[DEBUG] handleTextを開始します。インデックス: \(index)")
        attachment.loadItem(forTypeIdentifier: textContentType, options: nil) { [weak self] data, error in
            if let error = error {
                print("[ERROR] テキストのロード中にエラーが発生しました: \(error.localizedDescription)")
                self?.dismissWithError("テキストの読み込みに失敗しました。")
                return
            }

            guard let this = self else {
                print("[ERROR] selfがnilです。")
                return
            }

            guard let item = data as? String else {
                print("[ERROR] データがString型ではありません。")
                this.dismissWithError("テキストの読み込みに失敗しました。")
                return
            }

            this.sharedText.append(item)
            print("[DEBUG] 共有テキストを追加しました。現在の共有テキスト: \(this.sharedText)")

            // 最後のアイテムであれば保存とリダイレクトを実行
            if index == (content.attachments?.count ?? 0) - 1 {
                print("[DEBUG] 最後のアイテムです。UserDefaultsに保存し、ホストアプリにリダイレクトします。")
                if let userDefaults = UserDefaults(suiteName: this.appGroupId) {
                    userDefaults.set(this.toData(data: this.sharedMedia), forKey: this.sharedKey)
                    // userDefaults.synchronize() // 非推奨のため削除
                    print("[DEBUG] UserDefaultsに共有テキストを保存しました。")
                } else {
                    print("[ERROR] UserDefaultsの取得に失敗しました。")
                    this.dismissWithError("データの保存に失敗しました。")
                    return
                }
                this.redirectToHostApp(type: .text)
            }
        }
    }

    private func handleUrl (content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        print("[DEBUG] handleUrlを開始します。イン��ックス: \(index)")
        attachment.loadItem(forTypeIdentifier: urlContentType, options: nil) { [weak self] data, error in
            if let error = error {
                print("[ERROR] URLのロード中にエラーが発生しました: \(error.localizedDescription)")
                self?.dismissWithError("URLの読み込みに失敗しました。")
                return
            }

            guard let this = self else {
                print("[ERROR] selfがnilです。")
                return
            }

            guard let item = data as? URL else {
                print("[ERROR] データがURL型ではありません。")
                this.dismissWithError("URLの読み込みに失敗しました。")
                return
            }

            this.sharedMedia.append(SharingFile(value: item.absoluteString, thumbnail: nil, duration: nil, type: .url))
            print("[DEBUG] 共有メディアにURLを追加しました。現在の共有メディア: \(this.sharedMedia)")

            // 最後のアイテムであれば保存とリダイレクトを実行
            if index == (content.attachments?.count ?? 0) - 1 {
                print("[DEBUG] 最後のアイテムです。UserDefaultsに保存し、ホストアプリにリダイレクトします。")
                if let userDefaults = UserDefaults(suiteName: this.appGroupId) {
                    userDefaults.set(this.toData(data: this.sharedMedia), forKey: this.sharedKey)
                    // userDefaults.synchronize() // 非推奨のため削除
                    print("[DEBUG] UserDefaultsに共有メディアデータを保存しました。")
                } else {
                    print("[ERROR] UserDefaultsの取得に失敗しました。")
                    this.dismissWithError("データの保存に失敗しました。")
                    return
                }
                this.redirectToHostApp(type: .url)
            }
        }
    }

    private func handleImages(content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        print("[DEBUG] handleImagesを開始します。インデックス: \(index)")
        attachment.loadItem(forTypeIdentifier: imageContentType, options: nil) { [weak self] data, error in
            if let error = error {
                print("[ERROR] 画像のロード中にエラーが発生しました: \(error.localizedDescription)")
                self?.dismissWithError("画像の読み込みに失敗しました。")
                return
            }

            guard let this = self else {
                print("[ERROR] selfがnilです。")
                return
            }

            guard let url = data as? URL else {
                print("[ERROR] データがURL型ではありません。")
                this.dismissWithError("画像の読み込みに失敗しました。")
                return
            }

            let fileName = this.getFileName(from: url, type: .image)
            let destinationURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: this.appGroupId)!
                .appendingPathComponent(fileName)

            print("[DEBUG] 画像をコピーします。元URL: \(url)、先URL: \(destinationURL)")

            if this.copyFile(at: url, to: destinationURL) {
                print("[DEBUG] 画像のコピーに成功しました。")
                let sharingFile = SharingFile(value: destinationURL.absoluteString, thumbnail: nil, duration: nil, type: .image)
                this.sharedMedia.append(sharingFile)
                print("[DEBUG] 共有メディアに画像を追加しました。現在の共有メディア: \(this.sharedMedia)")
            } else {
                print("[ERROR] 画像のコピーに失敗しました。")
                this.dismissWithError("画像のコピーに失敗しました。")
                return
            }

            // If this is the last item, save imagesData in userDefaults and redirect to host app
            if index == (content.attachments?.count ?? 0) - 1 {
                print("[DEBUG] 最後のアイテムです。UserDefaultsに保存し、ホストアプリにリダイレクトします。")
                if let userDefaults = UserDefaults(suiteName: this.appGroupId) {
                    userDefaults.set(this.toData(data: this.sharedMedia), forKey: this.sharedKey)
                    // userDefaults.synchronize() // 非推奨のため削除
                    print("[DEBUG] UserDefaultsに共有メディアデータを保存しました。")
                } else {
                    print("[ERROR] UserDefaultsの取得に失敗しました。")
                    this.dismissWithError("データの保存に失敗しました。")
                    return
                }
                this.redirectToHostApp(type: .media)
            }
        }
    }

    private func handleVideos(content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        print("[DEBUG] handleVideosを開始します。インデックス: \(index)")
        // 動画処理の実装が必要です。以下に例を示します。
        attachment.loadItem(forTypeIdentifier: videoContentType, options: nil) { [weak self] data, error in
            if let error = error {
                print("[ERROR] 動画のロード中にエラーが発生しました: \(error.localizedDescription)")
                self?.dismissWithError("動画の読み込みに失敗しました。")
                return
            }

            guard let this = self else {
                print("[ERROR] selfがnilです。")
                return
            }

            guard let url = data as? URL else {
                print("[ERROR] データがURL型ではありません。")
                this.dismissWithError("動画の読み込みに失敗しました。")
                return
            }

            let fileName = this.getFileName(from: url, type: .video)
            let destinationURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: this.appGroupId)!
                .appendingPathComponent(fileName)

            print("[DEBUG] 動画をコピーします。元URL: \(url)、先URL: \(destinationURL)")

            if this.copyFile(at: url, to: destinationURL) {
                print("[DEBUG] 動画のコピーに成功しました。")
                if let sharingFile = this.getSharedMediaFile(forVideo: destinationURL) {
                    this.sharedMedia.append(sharingFile)
                    print("[DEBUG] 共有メディアに動画を追加しました。現在の共有メディア: \(this.sharedMedia)")
                } else {
                    print("[ERROR] 動画の共有ファイル作成に失敗しました。")
                    this.dismissWithError("動画の処理に失敗しました。")
                    return
                }
            } else {
                print("[ERROR] 動画のコピーに失敗しました。")
                this.dismissWithError("動画のコピーに失敗しました。")
                return
            }

            // If this is the last item, save imagesData in userDefaults and redirect to host app
            if index == (content.attachments?.count ?? 0) - 1 {
                print("[DEBUG] 最後のアイテムです。UserDefaultsに保存し、ホストアプリにリダイレクトします。")
                if let userDefaults = UserDefaults(suiteName: this.appGroupId) {
                    userDefaults.set(this.toData(data: this.sharedMedia), forKey: this.sharedKey)
                    // userDefaults.synchronize() // 非推奨のため削除
                    print("[DEBUG] UserDefaultsに共有メディアデータを保存しました。")
                } else {
                    print("[ERROR] UserDefaultsの取得に失敗しました。")
                    this.dismissWithError("データの保存に失敗しました。")
                    return
                }
                this.redirectToHostApp(type: .media)
            }
        }
    }

    private func handleFiles(content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        print("[DEBUG] handleFilesを開始します。インデックス: \(index)")
        // ファイル処理の実装が必要です。以下に例を示します。
        attachment.loadItem(forTypeIdentifier: fileURLType, options: nil) { [weak self] data, error in
            if let error = error {
                print("[ERROR] ファイルのロード中にエラーが発生しました: \(error.localizedDescription)")
                self?.dismissWithError("ファイルの読み込みに失敗しました。")
                return
            }

            guard let this = self else {
                print("[ERROR] selfがnilです。")
                return
            }

            guard let url = data as? URL else {
                print("[ERROR] データがURL型ではありません。")
                this.dismissWithError("ファイルの読み込みに失敗しました。")
                return
            }

            let fileName = this.getFileName(from: url, type: .file)
            let destinationURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: this.appGroupId)!
                .appendingPathComponent(fileName)

            print("[DEBUG] ファイルをコピーします。元URL: \(url.absoluteString)、先URL: \(destinationURL.absoluteString)")

            if this.copyFile(at: url, to: destinationURL) {
                print("[DEBUG] ファイルのコピーに成功しました。")
                let sharingFile = SharingFile(value: destinationURL.absoluteString, thumbnail: nil, duration: nil, type: .file)
                this.sharedMedia.append(sharingFile)
                print("[DEBUG] 共有メディアにファイルを追加しました。現在の共有メディア: \(this.sharedMedia)")
            } else {
                print("[ERROR] ファイルのコピーに失敗しました。")
                this.dismissWithError("ファイルのコピーに失敗しました。")
                return
            }

            // 最後のアイテムであれば保存とリダイレクトを実行
            if index == (content.attachments?.count ?? 0) - 1 {
                print("[DEBUG] 最後のアイテムです。UserDefaultsに保存し、ホストアプリにリダイレクトします。")
                if let userDefaults = UserDefaults(suiteName: this.appGroupId) {
                    userDefaults.set(this.toData(data: this.sharedMedia), forKey: this.sharedKey)
                    // userDefaults.synchronize() // 非推奨のため削除
                    print("[DEBUG] UserDefaultsに共有メディアデータを保存しました。")
                } else {
                    print("[ERROR] UserDefaultsの取得に失敗しました。")
                    this.dismissWithError("データの保存に失敗しました。")
                    return
                }
                this.redirectToHostApp(type: .file)
            }
     
        }
    }

    private func redirectToHostApp(type: RedirectType) {
        print("[DEBUG] redirectToHostAppを開始します。タイプ: \(type)")
        loadIds()
        let urlString = "SharingMedia-\(hostAppBundleIdentifier)://dataUrl=\(sharedKey)#\(type)"
        print("[DEBUG] 生成されたURL: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("[ERROR] 無効なURLです。urlString: \(urlString)")
            dismissWithError("無効なURLが生成されました。")
            return
        }
        
        print("[DEBUG] URLを開こうとしています: \(url.absoluteString)")
        extensionContext?.open(url, completionHandler: { [weak self] success in
            guard let self = self else {
                print("[ERROR] selfがnilです。")
                return
            }
            DispatchQueue.main.async {
                if success {
                    print("[DEBUG] ホストアプリの起動に成功しました。URL: \(url.absoluteString)")
                } else {
                    print("[ERROR] ホストアプリの起動に失敗しました。URL: \(url.absoluteString)")
                    self.dismissWithError("ホストアプリの起動に失敗しました。")
                }
            }
        })
    }

    enum RedirectType {
        case media
        case text
        case file
        case url
    }

    func getExtension(from url: URL, type: SharingFileType) -> String {
        print("[DEBUG] getExtensionを開始します。URL: \(url.absoluteString), タイプ: \(type)")
        let parts = url.lastPathComponent.components(separatedBy: ".")
        var ex: String? = nil
        if (parts.count > 1) {
            ex = parts.last
            print("[DEBUG] ファイル拡張子: \(ex!)")
        }

        if (ex == nil) {
            switch type {
                case .image:
                    ex = "PNG"
                case .video:
                    ex = "MP4"
                case .file:
                    ex = "TXT"
                case .text:
                    ex = "TXT"
                case .url:
                    ex = "TXT"
                }
            print("[DEBUG] デフォルトのファイル拡張子を設定: \(ex!)")
        }
        return ex ?? "Unknown"
    }

    func getFileName(from url: URL, type: SharingFileType) -> String {
        var name = url.lastPathComponent
        print("[DEBUG] getFileName: 元のファイル名: \(name)")

        if (name.isEmpty) {
            name = UUID().uuidString + "." + getExtension(from: url, type: type)
            print("[DEBUG] getFileName: UUIDを使用したファイル名: \(name)")
        }

        return name
    }

    func copyFile(at srcURL: URL, to dstURL: URL) -> Bool {
        print("[DEBUG] copyFileを開始します。srcURL: \(srcURL.absoluteString), dstURL: \(dstURL.absoluteString)")
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                print("[DEBUG] 既存のファイルを削除します。")
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
            print("[DEBUG] ファイルのコピーに成功しました。")
        } catch (let error) {
            print("[ERROR] Cannot copy item at \(srcURL) to \(dstURL): \(error)")
            return false
        }
        return true
    }

    private func getSharedMediaFile(forVideo: URL) -> SharingFile? {
        print("[DEBUG] getSharedMediaFileを開始します。URL: \(forVideo.absoluteString)")
        let asset = AVAsset(url: forVideo)
        let duration = (CMTimeGetSeconds(asset.duration) * 1000).rounded()
        let thumbnailPath = getThumbnailPath(for: forVideo)
        print("[DEBUG] 動画の長さ（ミリ秒）: \(duration)、サムネイルパス: \(thumbnailPath.absoluteString)")

        if FileManager.default.fileExists(atPath: thumbnailPath.path) {
            print("[DEBUG] サムネイルが既に存在します。")
            return SharingFile(value: forVideo.absoluteString, thumbnail: thumbnailPath.absoluteString, duration: duration, type: .video)
        }

        var saved = false
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        // let scale = UIScreen.main.scale
        assetImgGenerate.maximumSize = CGSize(width: 360, height: 360)
        do {
            let img = try assetImgGenerate.copyCGImage(at: CMTimeMakeWithSeconds(600, preferredTimescale: 1), actualTime: nil)
            if let imageData = UIImage(cgImage: img).pngData() {
                try imageData.write(to: thumbnailPath)
                saved = true
                print("[DEBUG] サムネイルを保存しました。")
            } else {
                print("[ERROR] UIImageのpngDataが取得できませんでした。")
                saved = false
            }
        } catch {
            print("[ERROR] サムネイルの生成中にエラーが発生しました: \(error)")
            saved = false
        }

        return saved ? SharingFile(value: forVideo.absoluteString, thumbnail: thumbnailPath.absoluteString, duration: duration, type: .video) : nil
    }

    private func getThumbnailPath(for url: URL) -> URL {
        print("[DEBUG] getThumbnailPathを開始します。URL: \(url.absoluteString)")
        let fileName = Data(url.lastPathComponent.utf8).base64EncodedString().replacingOccurrences(of: "==", with: "")
        let path = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)!
            .appendingPathComponent("\(fileName).jpg")
        print("[DEBUG] サムネイルパス: \(path.absoluteString)")
        return path
    }

    func toData(data: [SharingFile]) -> Data {
        print("[DEBUG] toDataを開始します。共有データ数: \(data.count)")
        let encodedData = try? JSONEncoder().encode(data)
        if let encoded = encodedData {
            print("[DEBUG] データのエンコードに成功しました。")
            return encoded
        } else {
            print("[ERROR] データのエンコードに失敗しました。")
            return Data()
        }
    }

    private func dismissWithError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                print("[ERROR] selfがnilです。")
                return
            }
            let alert = UIAlertController(title: "エラー", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        // 他のバックグラウンドスレッドでの処理があればここに記述
    }
}

extension Array {
    subscript (safe index: UInt) -> Element? {
        return Int(index) < count ? self[Int(index)] : nil
    }
}

// MARK: - Attachment Types
extension NSItemProvider {
    var isImage: Bool {
        return hasItemConformingToTypeIdentifier(UTType.image.identifier)
    }

    var isMovie: Bool {
        return hasItemConformingToTypeIdentifier(UTType.movie.identifier)
    }

    var isText: Bool {
        return hasItemConformingToTypeIdentifier(UTType.text.identifier)
    }

    var isURL: Bool {
        return hasItemConformingToTypeIdentifier(UTType.url.identifier)
    }

    var isFile: Bool {
        return hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
    }
}