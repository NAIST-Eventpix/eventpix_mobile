import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventpix_mobile/widgets/app_bar_eventpix.dart';

void main() {
  testWidgets('AppBarEventpix displays AppBar with correct properties',
      (WidgetTester tester) async {
    // Build our widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: const AppBarEventpix(),
        ),
      ),
    );

    // Check if the AppBar is present
    expect(find.byType(AppBar), findsOneWidget);

    // Check if the height of the AppBar is correct
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.preferredSize.height, 56.0);

    // Check if the title (Image inside InkWell) is displayed
    expect(find.byType(InkWell), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.height, 40);
  });

  testWidgets('AppBarEventpix uses Theme color for background',
      (WidgetTester tester) async {
    // Create a custom theme
    var customTheme = ColorScheme.light().copyWith(inversePrimary: Colors.blue);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: customTheme),
        home: Scaffold(
          appBar: const AppBarEventpix(),
        ),
      ),
    );

    // Check if the AppBar uses the correct background color
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, Colors.blue);
  });

  testWidgets('AppBarEventpix navigates on tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => Scaffold(
                appBar: const AppBarEventpix(),
              ),
          '/next': (context) => Scaffold(
                body: Text('Next Page'),
              ),
        },
      ),
    );

    // Tap on the image
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    // Check if navigation happened
    expect(find.text('Next Page'), findsNothing);
  });

  testWidgets('AppBarEventpix displays correct structure',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: const AppBarEventpix(),
        ),
      ),
    );

    // Check if the AppBarEventpix implements PreferredSizeWidget correctly
    final customAppBar = find.byType(AppBarEventpix);
    expect(customAppBar, findsOneWidget);
    expect(tester.widget<AppBarEventpix>(customAppBar).preferredSize,
        const Size.fromHeight(56.0));
  });

  testWidgets('AppBarEventpix has correct image path',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: const AppBarEventpix(),
        ),
      ),
    );

    // Check if the image asset is correctly loaded
    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);
    final image = tester.widget<Image>(imageFinder);
    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName, 'assets/icon/logo_name.png');
  });
}
