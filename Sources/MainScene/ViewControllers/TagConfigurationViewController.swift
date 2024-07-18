//
//  TagConfigurationViewController.swift
//  Pomodoro
//
//  Created by SonSinghae on 2024/02/15.
//

import PomodoroDesignSystem
import Realm
import RealmSwift
import SnapKit
import Then
import UIKit

final class TagConfigurationViewController: UIViewController, UITextFieldDelegate {
    // TODO: Realm Tag write

    private var selectedColorIndex: String?
    private var selectedPosition: Int?

    private var allButtons: [UIButton] = []

    // MARK: 태그명 레이블

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "태그명"
        label.font = .pomodoroFont.heading5()
        label.textAlignment = .left
        return label
    }()

    private let paletteTitleLabel = UILabel().then { label in
        label.text = "태그 색상"
        label.font = .pomodoroFont.heading5()
        label.textAlignment = .left
    }

    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.returnKeyType = .done
        textField.placeholder = "ex. 공부"
        textField.font = .pomodoroFont.heading6()
        textField.delegate = self
        textField.textAlignment = .left
        let bottomLine = UIView()
        bottomLine.backgroundColor = .black
        textField.addSubview(bottomLine)
        bottomLine.snp.makeConstraints { make in
            make.bottom.equalTo(textField.snp.bottom).offset(10)
            make.left.right.equalTo(textField)
            make.height.equalTo(2)
        }
        return textField
    }()

    private lazy var createTagConfirmButton = PomodoroConfirmButton(title: "태그 생성",
                                                                    didTapHandler: saveTagButtonTapped)

    private let colorPaletteStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .equalSpacing
        $0.spacing = 8
    }

    private let dimmedView = UIView().then {
        $0.backgroundColor = .pomodoro.blackHigh.withAlphaComponent(0.2)
    }

    private let titleView = UILabel().then {
        $0.text = "태그 설정"
        $0.font = .pomodoroFont.heading4()
    }

    private let closeButton = UIButton().then {
        $0.setImage(UIImage(named: "closeButton"), for: .normal)
    }

    weak var delegate: TagCreationDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .pomodoro.background
        navigationController?.isNavigationBarHidden = false
        setupViews()
        setupConstraints()
        setupColorPalette()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }

    @objc private func dismissModal() {
        dismiss(animated: true, completion: nil)
    }

    @objc func saveTagButtonTapped() {
        guard let tagText = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !tagText.isEmpty else {
            PomodoroPopupBuilder()
                .add(body: "태그 이름을 입력해주세요.")
                .add(button: .confirm(title: "확인", action: {}))
                .show(on: self)
            return
        }
        guard let selectedColorIndex else {
            PomodoroPopupBuilder()
                .add(body: "태그 색상을 선택해주세요.")
                .add(button: .confirm(title: "확인", action: {}))
                .show(on: self)
            return
        }
        do {
            let existingTag = try RealmService.read(Tag.self).filter("tagName == %@", tagText).first
            if existingTag != nil {
                PomodoroPopupBuilder()
                    .add(title: "태그 중복")
                    .add(body: "똑같은 태그명이 있어요. \n 다시 작성해주세요.")
                    .add(button: .confirm(title: "확인", action: {}))
                    .show(on: self)
            } else {
                let newTag = Tag(
                    tagName: tagText,
                    colorIndex: selectedColorIndex,
                    position: calculateNextPosition()
                )
                RealmService.write(newTag)
                delegate?.createTag(tag: tagText, color: selectedColorIndex, position: newTag.position)
                dismiss(animated: true, completion: nil)
            }
        } catch {
            Log.info("태그 조회 실패: \(error)")
            PomodoroPopupBuilder()
                .add(body: "태그를 검증하는 과정에서 오류가 발생했습니다.")
                .add(button: .confirm(title: "확인", action: {}))
                .show(on: self)
        }
    }

    private func calculateNextPosition() -> Int {
        do {
            let tags = try RealmService.read(Tag.self)
            return (tags.max(ofProperty: "position") as Int? ?? -1) + 1
        } catch {
            Log.info("Failed to fetch tags from Realm: \(error)")
            return 0
        }
    }

    private func setupViews() {
        closeButton.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
        let contentView = UIView().then {
            $0.backgroundColor = .pomodoro.background
            $0.layer.cornerRadius = 20
            $0.addSubview(titleView)
            $0.addSubview(closeButton)
            $0.addSubview(titleLabel)
            $0.addSubview(textField)
            $0.addSubview(paletteTitleLabel)
            $0.addSubview(createTagConfirmButton)
            $0.addSubview(colorPaletteStackView)
        }
        dimmedView.addSubview(contentView)
        view.addSubview(dimmedView)
        contentView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(view.frame.height * 0.8)
        }
    }

    private func setupConstraints() {
        closeButton.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(20)
        }

        titleView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(closeButton.snp.centerY)
        }

        dimmedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(59)
            make.left.equalToSuperview().inset(40)
        }

        textField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(40)
        }

        paletteTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(52)
            make.leading.trailing.equalToSuperview().inset(40)
        }

        colorPaletteStackView.snp.makeConstraints { make in
            make.top.equalTo(paletteTitleLabel.snp.bottom).offset(34)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(150)
        }

        createTagConfirmButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(110)
            make.top.equalTo(colorPaletteStackView.snp.bottom).offset(66)
            make.height.equalTo(60)
        }
    }

    private func setupColorPalette() {
        let colors: [UIColor] = [
            .pomodoro.tagTypo1,
            .pomodoro.tagTypo2,
            .pomodoro.tagTypo3,
            .pomodoro.tagTypo4,
            .pomodoro.tagTypo5,
            .pomodoro.tagTypo6,
            .pomodoro.tagTypo7,
            .white,
        ]

        colorPaletteStackView.axis = .vertical
        colorPaletteStackView.distribution = .fillEqually
        colorPaletteStackView.spacing = 20

        let rows = [UIStackView(), UIStackView()]
        for row in rows {
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 15
            colorPaletteStackView.addArrangedSubview(row)
        }

        for (index, color) in colors.enumerated() {
            let colorButton = UIButton().then {
                $0.backgroundColor = color
                $0.layer.cornerRadius = 33
                $0.snp.makeConstraints { make in
                    make.size.equalTo(CGSize(width: 55, height: 55))
                }
                $0.addTarget(self, action: #selector(colorButtonTapped), for: .touchUpInside)
                $0.tag = index
                Log.info("tag:/(index)")
            }
            allButtons.append(colorButton)

            if index < 4 {
                rows[0].addArrangedSubview(colorButton)
            } else {
                rows[1].addArrangedSubview(colorButton)
            }
        }
    }

    @objc private func colorButtonTapped(from sender: UIButton) {
        removeAllRingEffect()
        showRingEffect(around: sender, color: sender.backgroundColor ?? .gray)

        let index = sender.tag
        let colorString = indexToString(index)
        selectedColorIndex = colorString
    }

    func showRingEffect(around button: UIButton, color: UIColor) {
        let ringLayer = CAShapeLayer().then {
            let ringPath = UIBezierPath(ovalIn: button.bounds.insetBy(dx: -7, dy: -7))
            $0.path = ringPath.cgPath
            $0.fillColor = UIColor.clear.cgColor
            $0.strokeColor = color.cgColor
            $0.lineWidth = 1.5
        }

        button.layer.addSublayer(ringLayer)
        button.layer.setValue(ringLayer, forKey: "ring")
    }

    func removeAllRingEffect() {
        for button in allButtons {
            if let ringLayer = button.layer.value(forKey: "ring") as? CAShapeLayer {
                ringLayer.removeFromSuperlayer()
            }
        }
    }

    func indexToString(_ index: Int) -> String {
        switch index {
        case 0:
            return "one"
        case 1:
            return "two"
        case 2:
            return "three"
        case 3:
            return "four"
        case 4:
            return "five"
        case 5:
            return "six"
        case 6:
            return "seven"
        case 7:
            return "eight"
        default:
            return "unknown"
        }
    }
}

extension TagConfigurationViewController {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else {
            return true
        }
        let newLength = text.count + string.count - range.length
        return newLength <= 4
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
