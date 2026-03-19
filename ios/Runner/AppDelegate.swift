import Flutter
import UIKit
// import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase를 Flutter 엔진보다 먼저 초기화해야 딥링크(위젯 탭) 수신 시
    // FLTFirebaseAuthPlugin이 Auth.auth()를 호출해도 크래시가 발생하지 않는다.
//     if FirebaseApp.app() == nil {
//       FirebaseApp.configure()
//     }
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "juny.dayly/app_group",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "getAppGroupDirectory" else {
          result(FlutterMethodNotImplemented); return
        }
        if let url = FileManager.default.containerURL(
          forSecurityApplicationGroupIdentifier: "group.juny.dayly"
        ) {
          result(url.path)
        } else {
          result(FlutterError(code: "UNAVAILABLE", message: "App Group not found", details: nil))
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
