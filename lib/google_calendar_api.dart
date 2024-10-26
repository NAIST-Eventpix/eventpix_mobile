import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';

const _scopes = [calendar.CalendarApi.calendarScope];
const _tokenFile = 'token.json';

void main() async {
  // credentials.jsonから認証情報を読み込む
  final credentialsFile = File('credentials.json');
  final credentialsJson = jsonDecode(await credentialsFile.readAsString());

  final clientId = ClientId(
    credentialsJson['installed']['client_id'],
    credentialsJson['installed']['client_secret'],
  );

  AccessCredentials? credentials;

  // トークンファイルが存在する場合、トークンを読み込む
  if (await File(_tokenFile).exists()) {
    final tokenJson = jsonDecode(await File(_tokenFile).readAsString());
    credentials = AccessCredentials(
      AccessToken(tokenJson['type'], tokenJson['data'],
          DateTime.parse(tokenJson['expiry'])),
      tokenJson['refreshToken'],
      _scopes,
    );
  }

  // トークンが存在しないか期限切れの場合、新しいトークンを取得
  if (credentials == null || credentials.accessToken.hasExpired) {
    var client = await clientViaUserConsent(clientId, _scopes, (url) {
      print('Please go to the following URL:');
      print('  => $url');
      print('Enter the verification code:');
    });

    credentials = client.credentials;

    // トークンを保存
    final tokenJson = jsonEncode({
      'type': credentials.accessToken.type,
      'data': credentials.accessToken.data,
      'expiry': credentials.accessToken.expiry.toIso8601String(),
      'refreshToken': credentials.refreshToken,
    });
    await File(_tokenFile).writeAsString(tokenJson);

    // クライアントを閉じる
    client.close();
  }

  // Google Calendar APIのクライアントを作成
  var client = authenticatedClient(http.Client(), credentials);
  var calendarApi = calendar.CalendarApi(client);

  // カレンダーリストを取得
  var calendarList = await calendarApi.calendarList.list();
  for (var calendar in calendarList.items!) {
    print('Calendar: ${calendar.summary} (${calendar.id})');
  }

  // 予定を追加するJSONファイルを読み込む
  final eventFile = File('sample_event.json');
  final eventJson = jsonDecode(await eventFile.readAsString());

  // 予定を作成
  var event = calendar.Event.fromJson(eventJson);

  // 予定をカレンダーに追加
  await calendarApi.events.insert(event, 'primary');

  print('Event added: ${event.summary}');

  // クライアントを閉じる
  client.close();
}
