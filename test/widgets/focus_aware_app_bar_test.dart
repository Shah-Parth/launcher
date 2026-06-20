import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flauncher/widgets/focus_aware_app_bar.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import '../mocks.mocks.dart';

void main() {
  late MockSettingsService mockSettingsService;
  late MockTvInputsService mockTvInputsService;
  late MockNotificationsService mockNotificationsService;

  setUp(() {
    mockSettingsService = MockSettingsService();
    mockTvInputsService = MockTvInputsService();
    mockNotificationsService = MockNotificationsService();

    // Default mock setup
    when(mockSettingsService.autoHideAppBarEnabled).thenReturn(false);
    when(mockSettingsService.showNetworkIndicatorInStatusBar).thenReturn(false);
    when(mockSettingsService.showDataWidgetInStatusBar).thenReturn(false);
    when(mockSettingsService.showDateInStatusBar).thenReturn(true);
    when(mockSettingsService.showTimeInStatusBar).thenReturn(true);
    when(mockSettingsService.showInputsWidgetInStatusBar).thenReturn(true);
    when(mockSettingsService.showNotificationsWidgetInStatusBar).thenReturn(true);
    when(mockSettingsService.dateFormat).thenReturn(SettingsService.defaultDateFormat);
    when(mockSettingsService.timeFormat).thenReturn(SettingsService.defaultTimeFormat);

    when(mockTvInputsService.hasInputs).thenReturn(false);

    when(mockNotificationsService.hasPermission).thenReturn(false);
    when(mockNotificationsService.notifications).thenReturn([]);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        appBar: FocusAwareAppBar(),
        body: Container(),
      ),
    );
  }

  testWidgets('FocusAwareAppBar renders settings button and date/time widgets', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
          ChangeNotifierProvider<TvInputsService>.value(value: mockTvInputsService),
          ChangeNotifierProvider<NotificationsService>.value(value: mockNotificationsService),
        ],
        child: createWidgetUnderTest(),
      )
    );

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byKey(const Key('statusbar_date')), findsOneWidget);
    expect(find.byKey(const Key('statusbar_clock')), findsOneWidget);
  });

  testWidgets('FocusAwareAppBar auto-hide logic', (WidgetTester tester) async {
    when(mockSettingsService.autoHideAppBarEnabled).thenReturn(true);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
          ChangeNotifierProvider<TvInputsService>.value(value: mockTvInputsService),
          ChangeNotifierProvider<NotificationsService>.value(value: mockNotificationsService),
        ],
        child: createWidgetUnderTest(),
      )
    );

    // Initial state: app bar height should be 0 because auto-hide is true and focused is false
    final animatedContainer = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    expect(animatedContainer.constraints?.maxHeight, 0);

    // Trigger focus to show app bar
    final focusWidget = tester.widget<Focus>(find.descendant(of: find.byType(FocusAwareAppBar), matching: find.byType(Focus)).first);
    focusWidget.onFocusChange?.call(true);

    await tester.pumpAndSettle();

    // After focus: app bar height should be kToolbarHeight
    final animatedContainerFocused = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    expect(animatedContainerFocused.constraints?.maxHeight, kToolbarHeight);
  });

  testWidgets('FocusAwareAppBar renders inputs button based on setting and availability', (WidgetTester tester) async {
    // Case 1: showInputsWidgetInStatusBar is true, and hasInputs is true
    when(mockSettingsService.showInputsWidgetInStatusBar).thenReturn(true);
    when(mockTvInputsService.hasInputs).thenReturn(true);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
          ChangeNotifierProvider<TvInputsService>.value(value: mockTvInputsService),
          ChangeNotifierProvider<NotificationsService>.value(value: mockNotificationsService),
        ],
        child: createWidgetUnderTest(),
      )
    );

    expect(find.byIcon(Icons.tv_outlined), findsOneWidget);

    // Case 2: showInputsWidgetInStatusBar is false, and hasInputs is true
    await tester.pumpWidget(Container()); // fully unmount previous tree
    await tester.pumpAndSettle();

    final mockSettingsService2 = MockSettingsService();
    when(mockSettingsService2.autoHideAppBarEnabled).thenReturn(false);
    when(mockSettingsService2.showNetworkIndicatorInStatusBar).thenReturn(false);
    when(mockSettingsService2.showDataWidgetInStatusBar).thenReturn(false);
    when(mockSettingsService2.showDateInStatusBar).thenReturn(true);
    when(mockSettingsService2.showTimeInStatusBar).thenReturn(true);
    when(mockSettingsService2.showInputsWidgetInStatusBar).thenReturn(false);
    when(mockSettingsService2.showNotificationsWidgetInStatusBar).thenReturn(true);
    when(mockSettingsService2.dateFormat).thenReturn(SettingsService.defaultDateFormat);
    when(mockSettingsService2.timeFormat).thenReturn(SettingsService.defaultTimeFormat);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService2),
          ChangeNotifierProvider<TvInputsService>.value(value: mockTvInputsService),
          ChangeNotifierProvider<NotificationsService>.value(value: mockNotificationsService),
        ],
        child: createWidgetUnderTest(),
      )
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.tv_outlined), findsNothing);
  });
}
