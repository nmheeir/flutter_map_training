import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    let channelName : String = "com.example.flutter_map_training/map_live_activity"
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let liveActivityChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
        let liveActivityManager = LiveActivityManager()
        liveActivityChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "startLiveActivity":
                liveActivityManager.startLiveActivity(data: call.arguments as? Dictionary<String,Any>)
                result(true)
                break
            case "updateLiveActivity":
                liveActivityManager.updateLiveActivity(data: call.arguments as? Dictionary<String,Any>)
                result(true)
                break
            case "endLiveActivity":
                liveActivityManager.endLiveActivity()
                result(true)
                break
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
