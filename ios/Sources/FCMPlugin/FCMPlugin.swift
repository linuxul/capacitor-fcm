import Foundation
import Capacitor
import UserNotifications

import FirebaseCore
import FirebaseMessaging
import FirebaseInstallations

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitor.ionicframework.com/docs/plugins/ios
 *
 * Created by Stewan Silva on 1/23/19.
 */
@objc(FCMPlugin)
public class FCMPlugin: CAPPlugin, CAPBridgedPlugin, MessagingDelegate {
    public let identifier = "FCMPlugin"
    public let jsName = "FCM"
    public let pluginMethods: [CAPPluginMethod] = [
        .promise("subscribeTo", FCMPlugin.subscribeTo),
        .promise("unsubscribeFrom", FCMPlugin.unsubscribeFrom),
        .promise("getToken", FCMPlugin.getToken),
        .promise("refreshToken", FCMPlugin.refreshToken),
        .promise("deleteInstance", FCMPlugin.deleteInstance),
        .promise("setAutoInit", FCMPlugin.setAutoInit),
        .promise("isAutoInitEnabled", FCMPlugin.isAutoInitEnabled)
    ]

    // The methods stay synchronous: the bridge queue starts the subscriptions, the token requests and the deletion in
    // the order of the calls, and they settle from the Firebase completion handlers, as before.

    var fcmToken: String?

    override public func load() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        Messaging.messaging().delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(self.didRegisterWithToken(notification:)), name: .capacitorDidRegisterForRemoteNotifications, object: nil)
    }

    @objc func didRegisterWithToken(notification: NSNotification) {
        guard let deviceToken = notification.object as? Data else {
            return
        }
        Messaging.messaging().apnsToken = deviceToken
    }

    func subscribeTo(_ call: CAPPluginCall) {
        let topicName = call.getString("topic") ?? ""
        Messaging.messaging().subscribe(toTopic: topicName) { error in
            // print("Subscribed to weather topic")
            if (error) != nil {
                print("ERROR while trying to subscribe topic \(topicName)")
                call.reject("Can't subscribe to topic \(topicName)")
            } else {
                call.resolve([
                    "message": "subscribed to topic \(topicName)"
                ])
            }
        }
    }

    func unsubscribeFrom(_ call: CAPPluginCall) {
        let topicName = call.getString("topic") ?? ""
        Messaging.messaging().unsubscribe(fromTopic: topicName) { error in
            if (error) != nil {
                call.reject("Can't unsubscribe from topic \(topicName)")
            } else {
                call.resolve([
                    "message": "unsubscribed from topic \(topicName)"
                ])
            }
        }
    }

    func getToken(_ call: CAPPluginCall) {
        if (fcmToken ?? "").isEmpty {
            Messaging.messaging().token { token, error in
                if let error = error {
                    print("Error fetching FCM registration token: \(error)")
                    call.reject("Failed to get instance FirebaseID", error.localizedDescription)
                } else if let token = token {
                    print("FCM registration token: \(token)")
                    self.fcmToken = token
                    call.resolve([
                        "token": token
                    ])
                }
            }
        } else {
            call.resolve([
                "token": fcmToken
            ])
        }
    }

    func refreshToken(_ call: CAPPluginCall) {
        // Delete FCM Token on Firebase
        FirebaseMessaging.Messaging.messaging().deleteData { error in
            guard let error = error else {
                print("Delete FCMToken successful!")
                return
            }
            call.reject("Delete FCMToken failed", error.localizedDescription)
            print("Delete FCMToken failed: \(String(describing: error.localizedDescription))!")
        }

        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
                call.reject("Failed to get instance FirebaseID", error.localizedDescription)
            } else if let token = token {
                print("FCM registration token: \(token)")
                self.fcmToken = token
                call.resolve([
                    "token": token
                ])
            }
        }
    }

    func deleteInstance(_ call: CAPPluginCall) {
        Installations.installations().delete { error in
            // reset fcmToken
            self.fcmToken = ""
            if let error = error {
                print("Error deleting installation: \(error)")
                call.reject("Cant delete Firebase Instance ID", error.localizedDescription)
                // The call used to be resolved after this rejection as well.
                return
            }
            call.resolve()
        }
    }

    func setAutoInit(_ call: CAPPluginCall) {
        let enabled: Bool = call.getBool("enabled") ?? false
        Messaging.messaging().isAutoInitEnabled = enabled
        call.resolve()
    }

    func isAutoInitEnabled(_ call: CAPPluginCall) {
        call.resolve([
            "enabled": Messaging.messaging().isAutoInitEnabled
        ])
    }

    @objc public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        self.fcmToken = fcmToken
    }
}
