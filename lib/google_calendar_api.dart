import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';

const _scopes = [calendar.CalendarApi.calendarScope];
const _tokenFile = 'token.json';

class GoogleCalendarApi {
  final String credentialsPath;
  AccessCredentials? credentials;

  GoogleCalendarApi(this.credentialsPath);

  Future<void> authenticate() async {
    final Map<String, dynamic> credentialsJson =
        jsonDecode(await File(credentialsPath).readAsString());

    final clientId = ClientId(
      credentialsJson['installed']['client_id'],
      credentialsJson['installed']['client_secret'],
    );

    // トークンファイルが存在する場合、トークンを読み込む
    if (await File(_tokenFile).exists()) {
      final Map<String, dynamic> tokenJson = jsonDecode(await File(_tokenFile).readAsString());
      credentials = AccessCredentials(
        AccessToken(tokenJson['type'], tokenJson['data'],
            DateTime.parse(tokenJson['expiry'])),
        tokenJson['refreshToken'],
        _scopes,
      );
    }

    // トークンが存在しないか期限切れの場合、新しいトークンを取得
    if (credentials == null || credentials!.accessToken.hasExpired) {
      var client = await clientViaUserConsent(clientId, _scopes, (url) {
        print('Please go to the following URL:');
        print('  => $url');
        print('Enter the verification code:');
      });

      credentials = client.credentials;

      // トークンを保存
      final Map<String, dynamic> tokenJson = {
        'type': credentials!.accessToken.type,
        'data': credentials!.accessToken.data,
        'expiry': credentials!.accessToken.expiry.toIso8601String(),
        'refreshToken': credentials!.refreshToken,
      };
      await File(_tokenFile).writeAsString(jsonEncode(tokenJson));

      // クライアントを閉じる
      client.close();
    }
  }

  Future<void> addEvent(String eventFilePath) async {
    var client = authenticatedClient(http.Client(), credentials!);
    var calendarApi = calendar.CalendarApi(client);

    // 予定を追加するJSONファイルを読み込む
    final String eventJson = await File(eventFilePath).readAsString();
    final Map<String, dynamic> eventMap = jsonDecode(eventJson);

    // 予定を作成
    var event = calendar.Event.fromJson(eventMap);

    // 予定をカレンダーに追加
    await calendarApi.events.insert(event, 'primary');

    // クライアントを閉じる
    client.close();
  }
}

void main() async {
  final api = GoogleCalendarApi('credentials.json');
  await api.authenticate();
  await api.addEvent('sample_event.json');
}