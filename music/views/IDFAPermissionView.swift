//
//  IDFAPermissionView.swift
//  PlayXFlash
//
//  Created by pc on 18.08.25.
//


import SwiftUI
import AdSupport
import FirebaseAnalytics
import UIKit
import AppTrackingTransparency

struct IDFAPermissionView: View {
    var onIDFAResponded: () -> Void
    @State private var isRequesting = false
    @State private var idfaCompleted = false

    var body: some View {
        ZStack {
            // Background image
            Image("bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
            .ignoresSafeArea()
            
            // Content overlay with tap gesture
            Image("idfa") // Use the content image that has everything
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 20)
                        .scaleEffect(isRequesting ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isRequesting)
                .onTapGesture {
                    if !isRequesting {
                        requestIDFA()
                    }
            }
        }
        .onAppear {
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

#Preview {
    IDFAPermissionView(onIDFAResponded: {})
}


