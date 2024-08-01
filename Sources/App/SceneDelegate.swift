//
//  SceneDelegate.swift
//  Pomodoro
//
//  Created by 전여훈 on 2023/11/02.
//  Copyright © 2023 io.hgu. All rights reserved.
//

import PomodoroDesignSystem
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    let pomodoroTimeManager = PomodoroTimeManager.shared

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
        window?.rootViewController = UINavigationController(rootViewController: MainPageViewController())
        window?.makeKeyAndVisible()
        window?.backgroundColor = .pomodoro.background
    }

    func sceneDidDisconnect(_: UIScene) {}

    func sceneDidBecomeActive(_: UIScene) {
        print("ACTIVE!!! + isNeedRestore -> \(pomodoroTimeManager.isNeedRestore)")

        pomodoroTimeManager.setupIsNeedRestore(
            bool: UserDefaults.standard.bool(forKey: UserDefaultsKeys.isNeedRestore)
        )

        if pomodoroTimeManager.isNeedRestore {
            print("RESTORE!!!")
            pomodoroTimeManager.restoreTimerInfo()

            if let navController = window?.rootViewController as? UINavigationController,
               let mainPageViewController = navController.viewControllers.first as? MainPageViewController,
               let pageViewController = mainPageViewController.children.first as? UIPageViewController,
               let mainViewController = pageViewController.viewControllers?.first(where: { $0 is MainViewController }) as? MainViewController
            {
                print("\(mainViewController.isTimerRunning)")
                if mainViewController.isTimerRunning == false {
                    print("START!!!")
                    mainViewController.currentPomodoro = try? RealmService.read(Pomodoro.self).last
                    mainViewController.startTimer()
                }
            } else {
                Log.error("MainViewController를 찾을 수 없습니다.")
            }
        }
    }

    func sceneWillResignActive(_: UIScene) {}

    func sceneWillEnterForeground(_: UIScene) {}

    func sceneDidEnterBackground(_: UIScene) {
        Log.info("max: \(pomodoroTimeManager.finishTime), curr: \(pomodoroTimeManager.currentTime)")
        if pomodoroTimeManager.currentTime != 0 {
            pomodoroTimeManager.saveTimerInfo()
        }
    }
}
