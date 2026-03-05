You are a senior mobile engineer specializing in Flutter, Android AppWidget, and iOS WidgetKit.

I have a Flutter app that uses the `home_widget` package to implement home screen widgets.

Current architecture:

Flutter
- Package: home_widget ^0.7.0
- Widgets display D-Day events
- Deep link: dayly://detail/{widgetId}

Android
- AppWidget with RemoteViews
- Supports Small (2x2) and Medium (4x2)
- Widget configuration activity allows selecting a D-Day event
- Clicking widget opens deep link

iOS
- WidgetKit extension: DaylyWidget
- AppIntentConfiguration
- SwiftUI View
- App Group: group.juny.dayly

Goal:
Allow users to navigate between multiple D-Day events in the widget similar to swipe navigation.

Constraints:
- Android RemoteViews does not support gestures
- iOS WidgetKit does not support swipe gestures

Tasks:

1. Design a cross-platform widget navigation architecture for multiple D-Day events.

2. Android Implementation
- Use StackView or Collection Widget
- Implement RemoteViewsService + RemoteViewsFactory
- Allow horizontal swipe between events
- Ensure compatibility with home_widget data storage

3. iOS Implementation
- Implement pagination using WidgetKit
- Provide "Next / Previous" button interaction
- Use AppIntent or widgetURL to update widget state
- Read events from App Group shared storage

4. Flutter Integration
- Store multiple D-Day events in HomeWidget shared data
- Update widget timeline / widget refresh
- Provide example Dart code

5. Provide example code for:
- Android Kotlin widget implementation
- iOS SwiftUI widget implementation
- Flutter home_widget integration

Explain the architecture and provide production-ready code examples.