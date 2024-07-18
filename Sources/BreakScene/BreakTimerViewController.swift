//
//  BreakTimerViewController.swift
//  Pomodoro
//
//  Created by 김하람 on 2/19/24.
//

import OSLog
import RealmSwift
import SnapKit
import Then
import UIKit

final class BreakTimerViewController: UIViewController, TimeSettingViewControllerDelegate {
    func didSelectTime(time _: Int) {}

    private var timer: Timer?
    private var notificationId = UUID().uuidString
    private var currentTime = 0
    private lazy var maxTime: Int = stepManager.timeSetting.setUpBreakTime()
    private var timerHeightConstraint: Constraint?
    var stepManager = PomodoroStepManger()
    private let timeLabel = UILabel().then {
        $0.textAlignment = .center
        $0.font = UIFont.systemFont(ofSize: 60, weight: .heavy)
    }

    private var longPressTimer: Timer?
    private var longPressTime: Float = 0.0

    private let longPressGestureRecognizer = UILongPressGestureRecognizer()

    private let longPressGuideLabel = UILabel().then {
        $0.text = "길게 클릭해서 타이머를 정지할 수 있어요"
        $0.textAlignment = .center
        $0.textColor = .pomodoro.blackMedium
        $0.font = .pomodoroFont.heading6()
        $0.isHidden = false
    }

    private let progressBar = UIProgressView().then {
        $0.progressViewStyle = .default
        $0.trackTintColor = UIColor.pomodoro.disabled
        $0.progressTintColor = UIColor.pomodoro.primary900
        $0.progress = 0.0
        $0.isHidden = true
    }

    private lazy var breakLabel = UILabel().then {
        $0.text = "휴식시간"
        $0.textColor = .black
        $0.font = .pomodoroFont.heading1()
    }

    private lazy var timerBackground = UIView().then {
        $0.backgroundColor = .pomodoro.primary900
    }

    private func setupLongPressGestureRecognizer() {
        view.addGestureRecognizer(longPressGestureRecognizer)
        longPressGestureRecognizer.addTarget(self, action: #selector(handleLongPress))
        longPressGestureRecognizer.isEnabled = true
        longPressGestureRecognizer.allowableMovement = .infinity
        longPressGestureRecognizer.minimumPressDuration = 0.2
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .pomodoro.background
        navigationController?.isNavigationBarHidden = true
        addSubviews()
        setupConstraints()
        startTimer()

        if let realmOption = try? RealmService.read(Option.self).first,
           realmOption.isTimerEffect {
            startAnimationTimer()
        }

        setupLongPressGestureRecognizer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateTimeLabel()
        navigationController?.isNavigationBarHidden = true
        // FIXME: Remove startTimer() after implementing time setup
    }

    private func updateTimeLabel() {
        let minutes = (maxTime - currentTime) / 60
        let seconds = (maxTime - currentTime) % 60
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
    }
}

// MARK: - Action

extension BreakTimerViewController {
    @objc private func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        progressBar.isHidden = false
        longPressGuideLabel.isHidden = true

        longPressTimer?.invalidate()
        longPressTimer = Timer.scheduledTimer(
            timeInterval: 0.02,
            target: self,
            selector: #selector(setProgress),
            userInfo: nil,
            repeats: true
        )
        longPressTimer?.fire()

        if gestureRecognizer.state == .cancelled || gestureRecognizer.state == .ended {
            progressBar.isHidden = true
            longPressGuideLabel.isHidden = false

            longPressTime = 0.0
            progressBar.progress = 0.0

            longPressTimer?.invalidate()
        }
    }

    @objc private func setProgress() {
        longPressTime += 0.01
        progressBar.setProgress(longPressTime, animated: true)

        if longPressTime >= 1 {
            longPressTime = 0.0
            progressBar.progress = 0.0

            longPressTimer?.invalidate()

            stopTimer()

            progressBar.isHidden = true
            longPressGuideLabel.isHidden = true
        }
    }

    @objc private func stopTimer() {
        timer?.invalidate()
        currentTime = 0
        maxTime = 0
        updateTimeLabel()
        stepManager.router.moveToNextStep(
            navigationController: navigationController ?? UINavigationController()
        )
        // - TODO: do pomodoroStep initialize
        stepManager.timeSetting.initPomodoroStep()
        longPressGuideLabel.isHidden = true
    }

    @objc private func timeSetting() {
        let timeSettingviewController = TimeSettingViewController(delegate: self)
        navigationController?.pushViewController(timeSettingviewController, animated: true)
    }

    @objc private func startTimer() {
        longPressTime = 0.0
        progressBar.progress = 0.0

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else {
                return
            }

            let minutes = (maxTime - currentTime) / 60
            let seconds = (maxTime - currentTime) % 60
            timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
            timeLabel.font = .pomodoroFont.heading1()
            currentTime += 1

            if currentTime > maxTime {
                Log.debug("Break Finish")
                let isVibrate = try? RealmService.read(Option.self).first?.isVibrate
                if isVibrate ?? false {
                    HapticService.hapticNotification(type: .success)
                }

                timer.invalidate()
                stepManager.router.moveToNextStep(
                    navigationController: self.navigationController ?? UINavigationController()
                )
                longPressGuideLabel.isHidden = true
                return
            }

            let timerBackgroundMinY = self.timerBackground.layer.presentation()?.frame.minY
            self.timeLabel.textColor = self.breakLabel.frame.minY < timerBackgroundMinY ?? .infinity
                ? .black
                : .white
            self.breakLabel.textColor = self.breakLabel.frame.minY < timerBackgroundMinY ?? .infinity
                ? .black
                : .white
            self.longPressGuideLabel.textColor = self.breakLabel.frame.minY < timerBackgroundMinY ?? .infinity
                ? .lightGray
                : .white
        }
        timer?.fire()
    }

    private func startAnimationTimer() {
        DispatchQueue.main.async {
            self.timerHeightConstraint?.update(offset: self.view.frame.height)
            UIView.animate(withDuration: TimeInterval(self.maxTime)) {
                self.view.layoutIfNeeded()
            }
        }
    }
}

// MARK: - UI

extension BreakTimerViewController {
    private func addSubviews() {
        view.addSubview(timerBackground)
        view.addSubview(timeLabel)
        view.addSubview(breakLabel)
        view.addSubview(longPressGuideLabel)
        view.addSubview(progressBar)
    }

    private func setupConstraints() {
        breakLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().multipliedBy(0.9)
        }
        timeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(breakLabel.snp.bottom).offset(20)
            make.width.equalTo(240)
        }
        longPressGuideLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.snp.bottom).offset(-112)
        }
        progressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(longPressGuideLabel)
            make.width.equalToSuperview().multipliedBy(0.8)
        }
        timerBackground.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
            self.timerHeightConstraint = make.height.equalTo(0).constraint
        }
    }
}
