# eventpix_mobile

# 環境構築
(文責：山﨑 `@Hietan` )

## Flutterのセットアップ (必須)

事前に，Flutterの環境構築を行なってください．
環境構築については公式のDocument等を参照．

ターミナルで，`flutter doctor` を実行し，`No issues found` となればOK

!["flutter doctor" の成功画面](/docs/assets/flutter_doctor.png)

## GoogleカレンダーAPIの認証ファイル
予定をGoogle Calendarに登録する場合に必要となり，組織アカウントのみに対応しています．
Google Calendar APIのドキュメントをもとに，credentials.jsonを作成し，プロジェクトのルートディレクトリに配置してください．
https://developers.google.com/calendar/api/quickstart/python?hl=ja
## 実機のセットアップ (実機デバッグする場合)

実機でデバッグを行う場合，開発者モードをONにする必要があります．
PC上のエミュレータでもほぼ全ての検証を行うことは可能です．

> [!WARNING]
> カメラ機能は実機で検証する必要があります．

### Androidの開発者モード

* `設定` > `デバイス情報` を開く
* `ビルド番号` を7回タップすると，開発者モードがONになる
* `設定` > `システム` > `開発者向けオプション` を開く
* `デバッグ` > `USBデバッグ` をONにする

### iPhone

検証中．

# 実行

プロジェクトのルートディレクトリで，以下のコマンドを実行

`flutter run`
