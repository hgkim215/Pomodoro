//
//  PomodoroTimeManager.swift
//  Pomodoro
//
//  Created by 김현기 on 2/13/24.
//

import Foundation
import UserNotifications

enum UserDefaultsKeys {
    static let isFirstVisit = "isFirstVisit"
    static let isNeedRestore = "isNeedRestore"
    static let exitDate = "exitTime"
    static let currentTime = "currentTime"
    static let finishTime = "finishTime"
}

final class PomodoroTimeManager {
    static let shared = PomodoroTimeManager()
    private init() {}

    var pomodoroTimer: Timer?
    private let notificationId = UUID().uuidString

    private(set) var currentTime = 0

    func setupCurrentTime(curr: Int) {
        currentTime = curr
    }

    private(set) var finishTime = 0

    func setupFinishTime(time: Int) {
        finishTime = time
    }

    // 다시 불러오는 과정이 필요하면 True, 아니면 False
    private(set) var isNeedRestore: Bool = false

    func setupIsNeedRestore(bool: Bool) {
        isNeedRestore = bool
        UserDefaults.standard.set(isNeedRestore, forKey: UserDefaultsKeys.isNeedRestore)
    }

    private(set) var isStarted: Bool = false

    func setupIsStarted(bool: Bool) {
        isStarted = bool
    }

    func startTimer(timerBlock: @escaping ((Timer, Int, Int) -> Void)) {
        guard finishTime > 0 else {
            print("Error: maxTime must be greater than 0. Current finishTime: \(finishTime)")
            return
        }

        pomodoroTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            timerBlock(timer, self.currentTime + 1, self.finishTime)
            self.currentTime += 1
        }
        pomodoroTimer?.fire()
    }

    func stopTimer(completion: () -> Void) {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        currentTime = 0

        let recent = try? RealmService.read(Pomodoro.self).last
        finishTime = (recent?.phaseTime ?? 25) * 60

        completion()
    }

    func saveTimerInfo() {
        Log.debug("Save Timer Info")

        let exitDate = Date().timeIntervalSince1970
        isNeedRestore = true
        UserDefaults.standard.set(isNeedRestore, forKey: UserDefaultsKeys.isNeedRestore)

        UserDefaults.standard.set(exitDate, forKey: UserDefaultsKeys.exitDate)
        UserDefaults.standard.set(currentTime, forKey: UserDefaultsKeys.currentTime)
        UserDefaults.standard.set(finishTime, forKey: UserDefaultsKeys.finishTime)
    }

    func restoreTimerInfo() {
        guard let lastExitDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.exitDate) as? TimeInterval,
              let existCurrentTime = UserDefaults.standard.object(forKey: UserDefaultsKeys.currentTime) as? Int,
              let existFinishTime = UserDefaults.standard.object(forKey: UserDefaultsKeys.finishTime) as? Int
        else {
            setupDefaultTimer()
            return
        }

        let currentDate = Date().timeIntervalSince1970
        let elapsedTime = Int(currentDate - lastExitDate)
        let updatedCurrentTime = min(existCurrentTime + elapsedTime, existFinishTime)

        if updatedCurrentTime < existFinishTime {
            currentTime = updatedCurrentTime
            finishTime = existFinishTime
            isNeedRestore = false
            UserDefaults.standard.set(isNeedRestore, forKey: UserDefaultsKeys.isNeedRestore)
        } else {
            setupDefaultTimer()
        }
    }

    private func setupDefaultTimer() {
        Log.debug("setupDefaultTimer")
        let recent = try? RealmService.read(Pomodoro.self).last
        Log.debug("phaseTime: \(recent?.phaseTime)")
        finishTime = recent?.phaseTime ?? 1000
        currentTime = 0

        isNeedRestore = false
        UserDefaults.standard.set(isNeedRestore, forKey: UserDefaultsKeys.isNeedRestore)
    }
}
