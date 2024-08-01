//
//  DashboardStatusCell.swift
//  Pomodoro
//
//  Created by 김하람 on 1/30/24.
//  Copyright © 2024 io.hgu. All rights reserved.
//

import DGCharts
import SnapKit
import Then
import UIKit

final class DashboardStatusCell: UICollectionViewCell {
    private let participateLabel = UILabel()
    private let achieveLabel = UILabel()
    private let failLabel = UILabel()
    private var selectedDate = Date()
    private let totalStatusCircleView = StatusCircleView(type: .total)
    private let failStatusCircleView = StatusCircleView(type: .failure)
    private let successStatusCircleView = StatusCircleView(type: .success)

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("이 생성자를 사용하려면 스토리보드를 구현해주세요.")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    private func setupUI() {
        let circleStackView = UIStackView().then {
            $0.addArrangedSubview(totalStatusCircleView)
            $0.addArrangedSubview(failStatusCircleView)
            $0.addArrangedSubview(successStatusCircleView)
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            $0.spacing = 10
        }
        contentView.addSubview(circleStackView)

        circleStackView.snp.makeConstraints { make in
            make.centerX.centerY.edges.equalToSuperview()
        }

        layer.cornerRadius = 20
        backgroundColor = .clear
    }

    private func getStartAndEndDate(
        for date: Date,
        of component: Calendar.Component
    ) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        guard let dateInterval = calendar.dateInterval(of: component, for: date) else {
            return (date, date)
        }
        let startDate = dateInterval.start
        let endDate = dateInterval.end
        return (startDate, endDate)
    }

    func updateUI(for date: Date, dateType: DashboardDateType) {
        let component: Calendar.Component = {
            switch dateType {
            case .day:
                return .day
            case .week:
                return .weekOfYear
            case .month:
                return .month
            case .year:
                return .year
            }
        }()

        let (startDate, endDate) = getStartAndEndDate(for: date, of: component)

        let data = try? RealmService.read(Pomodoro.self)

        let filteredData = (data?.filter { $0.participateDate >= startDate &&
                $0.participateDate < endDate
        }) ?? []
        let participateDates = Set(filteredData.map { Calendar.current.startOfDay(for: $0.participateDate) })
        let totalParticipateCount = participateDates.count
        let filteredDataCount = filteredData.count
        let totalSuccessCount = filteredData.filter(\.isSuccess).count
        let totalFailureCount = filteredData.filter { !$0.isSuccess && !$0.isIng }.count

        participateLabel.text = "\(totalParticipateCount)번"
        totalStatusCircleView.updateStatus(count: filteredDataCount)
        failStatusCircleView.updateStatus(count: totalFailureCount)
        successStatusCircleView.updateStatus(count: totalSuccessCount)
        achieveLabel.font = UIFont.pomodoroFont.heading3()
        failLabel.font = UIFont.pomodoroFont.heading3()
    }

    func getDateRange(for date: Date, dateType: DashboardDateType) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        switch dateType {
        case .day:
            return (date, calendar.date(byAdding: .day, value: 1, to: date) ?? .now)
        case .week:
            let startOfWeek = calendar.date(
                from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? .now
            let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) ?? .now
            return (startOfWeek, endOfWeek)
        case .month:
            let startOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: date)
            ) ?? .now
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? .now
            return (startOfMonth, endOfMonth)
        case .year:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: date)) ?? .now
            let endOfYear = calendar.date(byAdding: .year, value: 1, to: startOfYear) ?? .now
            return (startOfYear, endOfYear)
        }
    }
}

// MARK: - DayViewControllerDelegate

extension DashboardStatusCell: DashboardTabDelegate {
    func dateArrowButtonDidTap(data date: Date) {
        selectedDate = date
    }
}

final class StatusCircleView: UIView {
    enum StatusType {
        case total
        case failure
        case success

        var title: String {
            switch self {
            case .total:
                return "횟수"
            case .failure:
                return "실패"
            case .success:
                return "성공"
            }
        }
    }

    private let titleLabel = UILabel().then {
        $0.textColor = .darkGray
        $0.font = .pomodoroFont.heading6()
    }

    private let countLabel = UILabel().then {
        $0.textColor = .black
        $0.font = UIFont.pomodoroFont.heading3()
    }

    private let circleView = UIView().then {
        $0.backgroundColor = .white
        $0.backgroundColor = .pomodoro.surface
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    convenience init(type: StatusType) {
        self.init(frame: .zero)
        titleLabel.text = type.title
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        circleView.layer.cornerRadius = frame.width / 2
    }

    func updateStatus(count: Int) {
        countLabel.text = "\(count)번"
    }

    private func setupViews() {
        addSubview(circleView)
        circleView.addSubview(titleLabel)
        circleView.addSubview(countLabel)

        circleView.snp.makeConstraints { make in
            make.width.equalTo(circleView.snp.height)
            make.width.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(30)
        }

        countLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
        }
    }
}
