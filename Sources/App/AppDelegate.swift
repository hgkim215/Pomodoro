//
//  AppDelegate.swift
//  Pomodoro
//
//  Created by 전여훈 on 2023/11/02.
//  Copyright © 2023 io.hgu. All rights reserved.
//

import OSLog
import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let unNotificationCenter = UNUserNotificationCenter.current()
    let pomodoroTimeManager = PomodoroTimeManager.shared

    // MARK: Notification 함수

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge],
            completionHandler: { _, _ in }
        )

        if let defaultFont = UIFont(name: "BMHANNA11yrsoldOTF", size: 17) {
            let attributes = [NSAttributedString.Key.font: defaultFont]
            UINavigationBar.appearance().titleTextAttributes = attributes
        }

        if UserDefaults.standard.bool(forKey: "isFirstVisit") {
            UserDefaults.standard.set(false, forKey: "isFirstVisit")
        }

        Log.debug("didFinishLaunching...")
        pomodoroTimeManager.restoreTimerInfo()
        return true
    }

    // MARK: 앱이 종료될 때 함수

    func applicationWillTerminate(_: UIApplication) {
        Log.debug("Terminate...")
        pomodoroTimeManager.saveTimerInfo()
    }

    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(
        _: UIApplication,
        didDiscardSceneSessions _: Set<UISceneSession>
    ) {}
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.badge, .banner, .list])
    }
}
