//
//  DashboardPieChartCell.swift
//  Pomodoro
//
//  Created by 김하람 on 1/30/24.
//  Copyright © 2024 io.hgu. All rights reserved.
//

import DGCharts
import RealmSwift
import SnapKit
import UIKit

final class DashboardPieChartCell: UICollectionViewCell {
    private var selectedDate: Date = .init()
    private var dayData: [String] = []
    private var priceData: [Double] = [10]
    var tagLabelHeightConstraint: Constraint?
    let legendStackView = UIStackView()
    let chartCenterText = UILabel()
    private let pieBackgroundView = UIView().then { view in
        view.layer.cornerRadius = 20
        view.backgroundColor = .white
    }

    private let donutPieChartView = PieChartView().then { chart in
        chart.noDataText = "출력 데이터가 없습니다."
        chart.noDataFont = .systemFont(ofSize: 20)
        chart.noDataTextColor = .red
        chart.holeColor = .clear
        chart.backgroundColor = .clear
        chart.drawSlicesUnderHoleEnabled = false
        chart.holeRadiusPercent = 0.7
        chart.drawEntryLabelsEnabled = false
        chart.highlightPerTapEnabled = false
        chart.legend.enabled = false
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(pieBackgroundView)
        pieBackgroundView.addSubview(donutPieChartView)
        backgroundColor = .clear
        layer.cornerRadius = 20
        setTagLabel()
        setupPieChart()
        setLegendLabel()
        setPieChartData(for: Date(), dateType: .day)
    }

    private func setTagLabel() {
        let tagLabel = UILabel().then {
            contentView.addSubview($0)
            $0.text = "태그 비율"
            $0.textColor = .pomodoro.blackHigh
            $0.font = .pomodoroFont.heading4()
        }
        tagLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(10)
        }
    }

    private func calculateFocusTimePerTag(for selectedDate: Date) -> [String: Int] {
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        guard let endOfDay = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: startOfDay
        ) else { return [:] }

        let sessions = (try? RealmService.read(Pomodoro.self).filter {
            $0.participateDate >= startOfDay && $0.participateDate < endOfDay && $0.isSuccess == true
        }) ?? []

        var focusTimePerTag = [String: Int]()
        for session in sessions {
            focusTimePerTag[session.currentTag?.tagName ?? "집중", default: 0] += 1
        }

        return focusTimePerTag
    }

    private func setupPieChart() {
        pieBackgroundView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalTo(30)
            self.tagLabelHeightConstraint = make.height.equalTo(0).constraint
        }
        donutPieChartView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalTo(donutPieChartView.snp.width)
        }
    }

    private func entryData(values: [Double]) -> [ChartDataEntry] {
        var pieDataEntries: [ChartDataEntry] = []
        for index in 0 ..< values.count {
            let pieDataEntry = ChartDataEntry(x: Double(index), y: values[index])
            pieDataEntries.append(pieDataEntry)
        }
        return pieDataEntries
    }

    private func calculateFocusTimePerTag(from startDate: Date, to endDate: Date) -> [String: Int] {
        var focusTimePerTag = [String: Int]()
        let filteredSessions = (try? RealmService.read(Pomodoro.self).filter {
            $0.participateDate >= startDate && $0.participateDate < endDate && $0.isSuccess == true
        }) ?? []
        for session in filteredSessions {
            focusTimePerTag[session.currentTag?.tagName ?? "집중", default: 0] += session.phaseTime
        }
        return focusTimePerTag
    }

    func setPieChartData(for date: Date, dateType: DashboardDateType) {
        let (startDate, endDate) = getDateRange(for: date, dateType: dateType)
        let focusTimePerTag = calculateFocusTimePerTag(from: startDate, to: endDate)
        let sortedFocusTimePerTag = focusTimePerTag.sorted { $0.value > $1.value }

        var tagColors: [String: UIColor] = [:] // MARK: tag color 사용

        let tags = try? RealmService.read(Tag.self)
        if let tags {
            for tag in tags {
                let color = tag.setupTagTypoColor()
                tagColors[tag.tagName] = color
            }
        }

        let totalFocusTime = focusTimePerTag.reduce(0) { $0 + $1.value }

        if sortedFocusTimePerTag.isEmpty || totalFocusTime == 0 {
            let emptyEntry = PieChartDataEntry(value: 1, label: "없음", data: UIColor.gray as AnyObject)
            let pieChartDataSet = PieChartDataSet(entries: [emptyEntry], label: "").then {
                $0.colors = [.gray]
                $0.drawValuesEnabled = false
            }
            let pieChartData = PieChartData(dataSet: pieChartDataSet)
            donutPieChartView.data = pieChartData

            updatePieChartText(totalFocusTime: 0)
            updateLegendLabel(with: ["없음": 0], tagColors: ["없음": .gray])
        } else {
            let pieChartDataEntries = sortedFocusTimePerTag.map { (tag: String, time: Int) -> PieChartDataEntry in
                let entryColor = tagColors[tag] ?? .gray
                return PieChartDataEntry(value: Double(time), label: tag, data: entryColor as AnyObject)
            }

            let pieChartDataSet = PieChartDataSet(entries: pieChartDataEntries, label: "").then {
                var dataSetColors: [UIColor] = []
                for entry in pieChartDataEntries {
                    if let color = entry.data as? UIColor {
                        dataSetColors.append(color)
                    }
                }
                $0.colors = dataSetColors
                $0.drawValuesEnabled = false
            }

            let pieChartData = PieChartData(dataSet: pieChartDataSet)
            donutPieChartView.data = pieChartData

            updatePieChartText(totalFocusTime: totalFocusTime)
            updateLegendLabel(with: focusTimePerTag, tagColors: tagColors)
        }
    }

    private func setLegendLabel() {
        legendStackView.axis = .vertical
        legendStackView.distribution = .equalSpacing
        legendStackView.alignment = .fill
        legendStackView.spacing = 8
        legendStackView.backgroundColor = .clear

        donutPieChartView.addSubview(legendStackView)
        legendStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(donutPieChartView.snp.bottom).offset(20)
        }
        donutPieChartView.addSubview(chartCenterText)
        chartCenterText.then {
            $0.textAlignment = .center
            $0.numberOfLines = 0
        }
        chartCenterText.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    private func setupLabels(font: UIFont, textColor: UIColor, text: String? = nil) -> UILabel {
        let label = UILabel()
        label.font = font
        label.textColor = textColor
        if let text {
            label.text = text
        }
        return label
    }

    private func setupStackView(axis: NSLayoutConstraint.Axis, spacing: CGFloat = 0) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = axis
        stackView.spacing = spacing
        return stackView
    }

    private func parsingTimes(from focusTime: Int) -> String {
        let days = focusTime / (24 * 60)
        let hours = (focusTime % (24 * 60)) / 60
        let minutes = focusTime % 60
        var timeText = ""
        if days > 0 { timeText += "\(days)일 " }
        if hours > 0 || days > 0 { timeText += "\(hours)시간 " }
        if focusTime == 0 { timeText += "---분" } else { timeText += "\(minutes * 4)분" }
        return timeText
    }

    private func updateLegendLabel(with focusTimePerTag: [String: Int], tagColors: [String: UIColor]) {
        legendStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let sortedFocusTime = focusTimePerTag.sorted { $0.value > $1.value }
        let totalFocusTime = sortedFocusTime.reduce(0) { $0 + $1.value }

        for (tagId, focusTime) in sortedFocusTime {
            let tagLabel = setupLabels(
                font: .pomodoroFont.heading5(),
                textColor: .pomodoro.blackHigh,
                text: tagId
            )
            let timeRatioTextLabel = setupLabels(
                font: .pomodoroFont.text4(),
                textColor: .pomodoro.blackHigh
            )

            let tagColor = UIView()
            tagColor.layer.cornerRadius = 7
            tagColor.backgroundColor = tagColors[tagId] ?? .gray
            NSLayoutConstraint.activate([
                tagColor.widthAnchor.constraint(equalToConstant: 15),
                tagColor.heightAnchor.constraint(equalToConstant: 15),
            ])

            let timeText = parsingTimes(from: focusTime)
            let percentage = (Double(focusTime) / Double(totalFocusTime)) * 100
            let displayPercentage = percentage.isNaN ? 0 : percentage

            timeRatioTextLabel.text = "\(timeText) (\(String(format: "%.0f", displayPercentage))%)"

            let labelandColorStackView = setupStackView(axis: .horizontal, spacing: 5)
            labelandColorStackView.addArrangedSubview(tagColor)
            labelandColorStackView.addArrangedSubview(tagLabel)

            let labelStackView = setupStackView(axis: .horizontal)
            labelStackView.addArrangedSubview(labelandColorStackView)
            labelStackView.addArrangedSubview(timeRatioTextLabel)

            legendStackView.addArrangedSubview(labelStackView)
        }

        tagLabelHeightConstraint?.update(offset: 360 + 25 * sortedFocusTime.count)
        UIView.animate(withDuration: 0) { self.layoutIfNeeded() }
    }

    private func updatePieChartText(totalFocusTime: Int) {
        if totalFocusTime == 0 {
            chartCenterText.text = "합계\n-"
            chartCenterText.textColor = .pomodoro.primary900
            chartCenterText.font = .pomodoroFont.heading4()
            chartCenterText.textAlignment = .center
            chartCenterText.numberOfLines = 0
        } else {
            let days = totalFocusTime / (24 * 60)
            let hours = (totalFocusTime % (24 * 60)) / 60
            let minutes = totalFocusTime % 60
            var totalTimeText = "합계\n"

            if days > 0 {
                totalTimeText += "\(days)일"
            }
            if hours > 0 || days > 0 {
                totalTimeText += "\(hours)시간"
            }
            totalTimeText += "\(minutes * 4)분"

            chartCenterText.text = totalTimeText
            chartCenterText.then {
                $0.textColor = .pomodoro.blackHigh
                $0.text = totalTimeText
                $0.font = .pomodoroFont.heading3()
                $0.textAlignment = .center
                $0.numberOfLines = 0
                $0.setAttributedTextFontandColor(
                    targetString: "합계",
                    font: .pomodoroFont.heading4(),
                    color: .pomodoro.primary900
                )
            }
        }
    }

    private func getDateRange(for date: Date, dateType: DashboardDateType) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        switch dateType {
        case .day:
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                return (startOfDay, startOfDay)
            }
            return (startOfDay, endOfDay)
        case .week:
            guard let startOfWeek = calendar.date(
                from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)),
                let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)
            else {
                return (date, date)
            }
            return (startOfWeek, endOfWeek)
        case .month:
            guard let monthStartDate = calendar.date(
                from: calendar.dateComponents([.year, .month], from: date)),
                let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: monthStartDate),
                let monthEndDate = calendar.date(byAdding: .day, value: -1, to: nextMonthDate)
            else {
                return (date, date)
            }
            return (monthStartDate, monthEndDate)
        case .year:
            guard let yearStartDate = calendar.date(from: calendar.dateComponents([.year], from: date)),
                  let nextYearDate = calendar.date(byAdding: .year, value: 1, to: yearStartDate),
                  let yearEndDate = calendar.date(byAdding: .day, value: -1, to: nextYearDate)
            else {
                return (date, date)
            }
            return (yearStartDate, yearEndDate)
        }
    }
}

extension DashboardPieChartCell: DashboardTabDelegate {
    func dateArrowButtonDidTap(data date: Date) {
        selectedDate = date
    }
}
