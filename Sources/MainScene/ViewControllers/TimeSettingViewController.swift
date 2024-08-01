//  TimeSettingViewController.swift
//  Pomodoro
//
//  Created by 진세진 on 2023/12/21.
//  Copyright © 2023 io.hgu. All rights reserved.

import PomodoroDesignSystem
import SnapKit
import Then
import UIKit

protocol TimeSettingViewControllerDelegate: AnyObject {
    func didSelectTime(time: Int)
}

final class TimeSettingViewController: UIViewController {
    private var isSelectedTime: Bool = false
    private let colletionViewIdentifier = "TimerCollectionViewCell"
    private var centerIndexPath: IndexPath?
    private let timeSelectRange = 5
    var selectedTime: Int = 0
    private let pomodoroTimeManager = PomodoroTimeManager.shared
    private var endTime: String?
    private var isSelectedCellBiggerfive: Bool = true
    private let stepManager = PomodoroStepManger()

    private weak var delegate: TimeSettingViewControllerDelegate?

    init(delegate: TimeSettingViewControllerDelegate) {
        super.init(nibName: nil, bundle: nil)
        selectedTime = pomodoroTimeManager.maxTime
        self.delegate = delegate
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let timeSettingTitleLabel = UILabel().then {
        $0.text = "시간 설정"
        $0.font = .pomodoroFont.heading4()
    }

    private let timerImageView = UIImageView().then {
        $0.image = UIImage(named: "timer")?.withRenderingMode(.alwaysOriginal)
    }

    private lazy var closeButton = UIButton().then {
        $0.setImage(UIImage(named: "closeButton"), for: .normal)
        $0.tintColor = .pomodoro.blackMedium
        $0.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
    }

    private let explanationLabel = UILabel().then {
        $0.text = "드래그하여 시간을 설정하세요"
        $0.textColor = .pomodoro.blackMedium
        $0.font = .pomodoroFont.text2()
    }

    private lazy var endTimeLabel = UILabel().then {
        $0.text = endTime ?? ""
        $0.textColor = .pomodoro.blackMedium
        $0.font = .pomodoroFont.text3()
    }

    private lazy var confirmButton = PomodoroConfirmButton(title: "설정 완료") { [weak self] in
        self?.didTapConfirmButton()
    }

    private var titleTime = UILabel().then {
        $0.font = .pomodoroFont.heading1(size: 80)
        $0.textAlignment = .center
    }

    private let collectionFlowlayout = UICollectionViewFlowLayout().then {
        $0.scrollDirection = .horizontal
        $0.itemSize.width = 22
    }

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: collectionFlowlayout
    ).then {
        $0.backgroundColor = .pomodoro.background
        $0.showsHorizontalScrollIndicator = true
        $0.register(TimerCollectionViewCell.self, forCellWithReuseIdentifier: colletionViewIdentifier)
        $0.showsHorizontalScrollIndicator = false

        let padding = 308 / 2 - (collectionFlowlayout.itemSize.width / 2)
        $0.contentInset = UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        view.backgroundColor = .pomodoro.background
        collectionView.dataSource = self
        collectionView.delegate = self
        setUpLayout()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let initialIndexPath = IndexPath(item: selectedTime, section: 0)
        centerCell(at: initialIndexPath)
    }

    private func setUpLayout() {
        view.addSubview(timeSettingTitleLabel)
        view.addSubview(closeButton)
        view.addSubview(titleTime)
        view.addSubview(endTimeLabel)
        view.addSubview(timerImageView)
        view.addSubview(explanationLabel)
        view.addSubview(collectionView)
        view.addSubview(confirmButton)
    }

    private func setupConstraints() {
        timeSettingTitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(24)
        }
        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(timeSettingTitleLabel)
            make.trailing.equalToSuperview().offset(-26)
            make.width.equalTo(15)
            make.height.equalTo(15)
        }
        titleTime.snp.makeConstraints { make in
            make.top.equalTo(timeSettingTitleLabel.snp.bottom).offset(165)
            make.centerX.equalToSuperview()
        }
        timerImageView.snp.makeConstraints { make in
            make.top.equalTo(titleTime.snp.bottom).offset(23.31)
            make.leading.equalToSuperview().offset(163)
        }
        endTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(titleTime.snp.bottom).offset(21.59)
            make.leading.equalTo(timerImageView.snp.trailing).offset(6.31)
        }
        explanationLabel.snp.makeConstraints { make in
            make.top.equalTo(titleTime.snp.bottom).offset(91)
            make.centerX.equalToSuperview()
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(explanationLabel.snp.top).offset(25)
            make.centerX.equalToSuperview()
            make.width.equalTo(308)
            make.height.equalTo(78)
        }
        confirmButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-170)
            make.width.equalTo(212)
            make.height.equalTo(60)
        }
    }

    private func centerCell(at indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            self.updateCellPositions()
        }
    }

    private func calculateEndTime(time selectedTime: Int) {
        let formatterTime = DateFormatter()
        formatterTime.dateFormat = "hh:mm"
        let currentTime = Date()

        guard let endTime = Calendar.current.date(
            byAdding: .second, value: selectedTime, to: currentTime
        ) else {
            return
        }
        self.endTime = formatterTime.string(from: endTime)
        endTimeLabel.text = self.endTime ?? ""
    }

    private func didTapConfirmButton() {
        Log.debug("Selected Time: \(Int(centerIndexPath?.item ?? 0))")
        delegate?.didSelectTime(time: Int(centerIndexPath?.item ?? 0))
        dismiss(animated: true)
    }

    @objc private func didTapCloseButton() {
        dismiss(animated: true)
    }
}

extension TimeSettingViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        1501
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: colletionViewIdentifier,
            for: indexPath
        ) as? TimerCollectionViewCell else {
            return UICollectionViewCell()
        }
        isSelectedTime = indexPath == centerIndexPath
        configureCurrentCell(item: indexPath.row, indexPathCell: cell, selected: isSelectedTime)
        cell.timeLabel.text = "\(Int(indexPath.item))"
        cell.isSelectedTime = isSelectedTime
        return cell
    }

    private func configureCurrentCell(
        item currentItem: Int,
        indexPathCell cell: TimerCollectionViewCell,
        selected isSelectedTime: Bool
    ) {
        if currentItem % 5 == 0 {
            cell.timeLabel.isHidden = false
            if isSelectedTime {
                cell.setHeightView(height: 28, widthBar: 4)
            } else {
                cell.setHeightView(height: 13.95, widthBar: 3)
            }
            cell.setDefualtColor(color: .pomodoro.blackHigh)
        } else {
            cell.timeLabel.isHidden = true
            if isSelectedTime {
                cell.setHeightView(height: 6.98, widthBar: 4)
            } else {
                cell.setHeightView(height: 6.98, widthBar: 3)
            }
            cell.setDefualtColor(color: .pomodoro.blackMedium)
        }
    }

    func findClosestSelectableTime(for currentTime: Int) -> Int {
        let reminder = currentTime % timeSelectRange

        guard reminder != .zero else {
            return currentTime
        }

        if reminder > 2 {
            return currentTime + (timeSelectRange - reminder)
        } else {
            return currentTime - reminder
        }
    }
}

extension TimeSettingViewController: UIScrollViewDelegate, UICollectionViewDelegateFlowLayout {
    func scrollViewDidScroll(_: UIScrollView) {
        let center = CGPoint(
            x: (collectionView.contentOffset.x) + (collectionView.bounds.width / 2),
            y: collectionView.bounds.height / 2
        )

        guard let centerIndexPathCalculation = collectionView.indexPathForItem(at: center) else {
            return
        }
        let currentTimeInMinutes = centerIndexPathCalculation.item * 60
        let minutes = currentTimeInMinutes / 60
        let seconds = currentTimeInMinutes % 60
        titleTime.text = String(format: "%02d:%02d", minutes, seconds)

        if centerIndexPath != centerIndexPathCalculation {
            centerIndexPath = centerIndexPathCalculation
            collectionView.reloadData()
        }

        if centerIndexPathCalculation.item >= 5 {
            endTimeLabel.isHidden = false
            timerImageView.isHidden = false
        } else {
            endTimeLabel.isHidden = true
            timerImageView.isHidden = true
        }

        calculateEndTime(time: centerIndexPathCalculation.item)
    }

    func collectionView(
        _: UICollectionView,
        layout _: UICollectionViewLayout,
        sizeForItemAt _: IndexPath
    ) -> CGSize {
        CGSize(width: 22, height: 78)
    }

    func scrollViewDidEndDecelerating(_: UIScrollView) {
        updateCellPositions()
    }

    func scrollViewDidEndDragging(_: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateCellPositions()
        }
    }

    func collectionView(_: UICollectionView, didSelectItemAt _: IndexPath) {
        updateCellPositions()
    }

    func updateCellPositions() {
        let center = CGPoint(
            x: collectionView.contentOffset.x + (collectionView.bounds.width / 2),
            y: collectionView.bounds.height / 2
        )

        selectTimeHiddenTimeButton()

        guard let centerIndexPathCalculation = collectionView.indexPathForItem(at: center) else {
            return
        }

        if (centerIndexPathCalculation.item % timeSelectRange) != .zero {
            let indexPathToScroll = IndexPath(
                item: findClosestSelectableTime(for: centerIndexPathCalculation.item),
                section: 0
            )

            if let cell = collectionView.cellForItem(at: indexPathToScroll) {
                let targetOffset = CGPoint(
                    x: cell.frame.origin.x - collectionView.contentInset.left,
                    y: 0
                )
                collectionView.setContentOffset(targetOffset, animated: true)
            }
        }

        if centerIndexPath != centerIndexPathCalculation {
            centerIndexPath = centerIndexPathCalculation
            collectionView.reloadData()
        }
    }

    func selectTimeHiddenTimeButton() {
        let center = CGPoint(
            x: collectionView.contentOffset.x + (collectionView.bounds.width / 2),
            y: collectionView.bounds.height / 2
        )

        guard let centerIndexPathCalculation = collectionView.indexPathForItem(at: center) else {
            return
        }
    }

    func collectionView(
        _: UICollectionView,
        layout _: UICollectionViewLayout,
        minimumLineSpacingForSectionAt _: Int
    ) -> CGFloat {
        0
    }
}
