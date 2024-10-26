import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';

const _scopes = [calendar.CalendarApi.calendarScope];
const _tokenFile = 'token.json';

class GoogleCalendarApi {
  final String credentialsPath;
  final String eventPath;
  AccessCredentials? credentials;

  GoogleCalendarApi(this.credentialsPath, this.eventPath);

  Future<void> authenticate() async {
    final credentialsFile = File(credentialsPath);
    final credentialsJson = jsonDecode(await credentialsFile.readAsString());

    final clientId = ClientId(
      credentialsJson['installed']['client_id'],
      credentialsJson['installed']['client_secret'],
    );

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
    if (credentials == null || credentials!.accessToken.hasExpired) {
      var client = await clientViaUserConsent(clientId, _scopes, (url) {
        print('Please go to the following URL:');
        print('  => $url');
        print('Enter the verification code:');
      });

      credentials = client.credentials;

      // トークンを保存
      final tokenJson = jsonEncode({
        'type': credentials!.accessToken.type,
        'data': credentials!.accessToken.data,
        'expiry': credentials!.accessToken.expiry.toIso8601String(),
        'refreshToken': credentials!.refreshToken,
      });
      await File(_tokenFile).writeAsString(tokenJson);

      // クライアントを閉じる
      client.close();
    }
  }

  Future<void> addEvent() async {
    var client = authenticatedClient(http.Client(), credentials!);
    var calendarApi = calendar.CalendarApi(client);

    // カレンダーリストを取得
    var calendarList = await calendarApi.calendarList.list();
    for (var calendar in calendarList.items!) {
      print('Calendar: ${calendar.summary} (${calendar.id})');
    }

    // 予定を追加するJSONファイルを読み込む
    final eventFile = File(eventPath);
    final eventJson = jsonDecode(await eventFile.readAsString());

    // 予定を作成
    var event = calendar.Event.fromJson(eventJson);

    // 予定をカレンダーに追加
    await calendarApi.events.insert(event, 'primary');

    print('Event added: ${event.summary}');

    // クライアントを閉じる
    client.close();
  }
}

void main() async {
  final api = GoogleCalendarApi('credentials.json', 'sample_event.json');
  await api.authenticate();
  await api.addEvent();
}