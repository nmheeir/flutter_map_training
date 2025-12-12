import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    let channelName: String = "com.example.flutter_map_training/map_live_activity"
    
    var methodChannel: FlutterMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller = window?.rootViewController as! FlutterViewController
        
        methodChannel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: controller.binaryMessenger
        )
        
        let liveActivityManager = LiveActivityManager()
        
        methodChannel?.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "startLiveActivity":
                liveActivityManager.startLiveActivity(data: call.arguments as? [String: Any])
                result(true)
                
            case "updateLiveActivity":
                liveActivityManager.updateLiveActivity(data: call.arguments as? [String: Any])
                result(true)
                
            case "endLiveActivity":
                liveActivityManager.endLiveActivity()
                result(true)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        
        if url.scheme == "fluttermap" {
            let methodName = url.host 
            
            if let method = methodName {
                methodChannel?.invokeMethod(method, arguments: nil)
                return true
            }
        }
        
        return super.application(app, open: url, options: options)
    }
}
