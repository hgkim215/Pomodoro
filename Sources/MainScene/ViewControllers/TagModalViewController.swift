//
//  TagModalViewController.swift
//  Pomodoro
//
//  Created by SonSinghae on 2023/11/17.
//  Copyright © 2023 io.hgu. All rights reserved.
//
import PomodoroDesignSystem
import Realm
import RealmSwift
import SnapKit
import Then
import UIKit

protocol TagCreationDelegate: AnyObject {
    func createTag(tag: String, color: String, position: Int)
}

protocol TagModalViewControllerDelegate: AnyObject {
    func tagSelected(with tag: Tag)
    func tagDidRemoved(tagName: String)
}

final class TagModalViewController: UIViewController {
    weak var selectionDelegate: TagModalViewControllerDelegate?
    private var selectedTag: Tag? {
        didSet {
            tagSettingCompletedButton.isEnabled = selectedTag != nil
        }
    }

    private lazy var editTagButton = UIButton().then {
        $0.setTitle("Edit", for: .normal)
        $0.titleLabel?.font = .pomodoroFont.heading5()
        $0.setTitleColor(.pomodoro.blackHigh, for: .normal)
        $0.contentMode = .scaleAspectFit
        $0.backgroundColor = .pomodoro.background
        $0.layer.cornerRadius = 15
        $0.clipsToBounds = true
        $0.addTarget(self, action: #selector(createMinusButton), for: .touchUpInside)
    }

    private let tagsStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 16
        $0.alignment = .center
        $0.distribution = .equalSpacing
    }

    private let titleView = UILabel().then {
        $0.text = "태그 설정"
        $0.font = .pomodoroFont.heading4()
    }

    private let closeButton = UIButton().then {
        $0.setImage(UIImage(named: "closeButton"), for: .normal)
    }

    private lazy var tagSettingCompletedButton = PomodoroConfirmButton(
        title: "설정 완료",
        didTapHandler: didTapSettingCompleteButton
    )

    private var selectedTagButton: UIButton?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addTagsToStackView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadDefaultTagsIfNeeded()
        setupViews()
        closeButton.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
        tagSettingCompletedButton.isEnabled = false // 첫 화면에는 설정완료 비활성화
        view.backgroundColor = .pomodoro.background
    }

    private func setupViews() {
        view.addSubview(closeButton)
        view.addSubview(titleView)
        view.addSubview(tagSettingCompletedButton)
        view.addSubview(tagsStackView)
        view.addSubview(tagSettingCompletedButton)

        closeButton.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(20)
        }

        titleView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(closeButton.snp.centerY)
        }

        view.addSubview(editTagButton)
        editTagButton.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(20)
            make.trailing.equalTo(closeButton.snp.trailing)
        }
        tagsStackView.snp.makeConstraints { make in
            make.top.equalTo(editTagButton.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(45)
        }
        tagSettingCompletedButton.snp.makeConstraints { make in
            make.top.equalTo(tagsStackView.snp.bottom).offset(60)
            make.centerX.equalToSuperview()
            make.width.equalTo(186)
            make.height.equalTo(60)
        }
    }

    private func makeRowStackView() -> UIStackView {
        UIStackView().then {
            $0.axis = .horizontal
            $0.spacing = 10
            $0.alignment = .fill
            $0.distribution = .fillEqually
        }
    }

    private func loadDefaultTagsIfNeeded() {
        if UserDefaults.standard.bool(forKey: "isFirstVisit") {
            guard let tagCount = try? RealmService.read(Tag.self).count, tagCount == 0 else { return }

            let defaultTags = [
                Tag(tagName: "공부", colorIndex: "one", position: 0),
                Tag(tagName: "수영", colorIndex: "two", position: 1),
                Tag(tagName: "독서", colorIndex: "three", position: 2),
            ]

            for tag in defaultTags {
                do {
                    RealmService.write(tag)
                    Log.info("Added tag: \(tag.tagName)")
                } catch {
                    Log.info("Error preloading tag \(tag.tagName): \(error)")
                }
            }

            UserDefaults.standard.set(false, forKey: "isFirstVisit")
        }
    }

    private func addTagsToStackView() {
        for arrangedSubview in tagsStackView.arrangedSubviews {
            arrangedSubview.removeFromSuperview()
        }

        let tagList = try? RealmService.read(Tag.self)
        Log.info("TAGLIST: \(String(describing: tagList))")
        let maxTags = 7
        let firstRow = makeRowStackView()
        let secondRow = makeRowStackView()
        let thirdRow = makeRowStackView()

        for item in 0 ... maxTags {
            let button: UIButton

            if let tagList, tagList.count > item {
                let title = tagList[item].tagName
                let index = tagList[item].colorIndex
                let position = tagList[item].position
                button = createRoundButton(title: title, colorIndex: index, tagIndex: position)
            } else {
                button = createEmptyButton(borderColor: .pomodoro.tagBackground1)
            }
            switch item {
            case 0 ... 1:
                firstRow.addArrangedSubview(button)
            case 2 ... 4:
                secondRow.addArrangedSubview(button)
            case 5 ... 6:
                thirdRow.addArrangedSubview(button)
            default:
                break
            }
        }

        tagsStackView.addArrangedSubview(firstRow)
        tagsStackView.addArrangedSubview(secondRow)
        tagsStackView.addArrangedSubview(thirdRow)
    }

    private func createRoundButton(title: String, colorIndex: String, tagIndex: Int) -> UIButton {
        let backgroundColor = TagCase(rawValue: colorIndex)?.backgroundColor ?? .black
        let titleColor = TagCase(rawValue: colorIndex)?.typoColor ?? .black

        Log.info(TagCase(rawValue: colorIndex)?.typoColor ?? .black)
        Log.info("태그 인덱스: \(tagIndex)")
        let button = UIButton().then {
            $0.setTitle(title, for: .normal)
            $0.titleLabel?.font = .pomodoroFont.heading4()
            $0.backgroundColor = backgroundColor
            $0.setTitleColor(titleColor, for: .normal)
            $0.tag = tagIndex
            $0.layer.cornerRadius = 40
            $0.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 80, height: 80))
            }
        }

        button.addAction(UIAction { [weak self] _ in
            self?.buttonTapped(tag: title, color: colorIndex, sender: button)
        }, for: .touchUpInside)

        let minusButton = UIButton().then {
            $0.setImage(UIImage(named: "minusButton"), for: .normal)
            $0.backgroundColor = .white
            $0.layer.borderColor = UIColor.gray.cgColor
            $0.layer.borderWidth = 1
            $0.layer.cornerRadius = 10
            $0.isHidden = true // 기본적으로 숨김
            $0.tag = tagIndex
            Log.info("마이너스 버튼의 태그 인덱스: \(tagIndex)")
        }

        button.addSubview(minusButton)

        minusButton.snp.makeConstraints { make in
            make.top.equalTo(button.snp.top).offset(2)
            make.right.equalTo(button.snp.right).offset(-2)
            make.width.height.equalTo(20)
        }

        minusButton.addTarget(self, action: #selector(deletTag(sender:)), for: .touchUpInside)

        return button
    }

    private func createEmptyButton(borderColor: UIColor) -> UIButton {
        UIButton().then {
            $0.titleLabel?.font = .pomodoroFont.heading4()
            $0.backgroundColor = .clear
            $0.layer.borderColor = borderColor.cgColor
            $0.layer.borderWidth = 1
            $0.layer.cornerRadius = 40
            $0.setImage(UIImage(named: "plusButton"), for: .normal)
            $0.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 80, height: 80))
            }
            $0.addTarget(self, action: #selector(presentTagEditViewController), for: .touchUpInside)
        }
    }

    func selectTag(with tag: Tag) {
        selectionDelegate?.tagSelected(with: tag)
        dismiss(animated: true, completion: nil)
    }

    @objc private func dismissModal() {
        dismiss(animated: true, completion: nil)
    }

    @objc func buttonTapped(tag: String, color _: String, sender: UIButton) {
        if let tag = try? RealmService.read(Tag.self).filter("tagName == %@", tag).first {
            if selectedTag == tag {
                selectedTag = nil
            } else {
                selectedTag = tag
            }
        } else {
            presentTagEditViewController()
        }

        if let previousTagButton = selectedTagButton {
            if previousTagButton == sender {
                animateButtonFade(sender, fadeIn: false)
                selectedTagButton = nil
                updateSettingCompleteButtonState()
                return
            } else {
                animateButtonFade(previousTagButton, fadeIn: false)
            }
        }
        animateButtonFade(sender, fadeIn: true)

        selectedTagButton = sender

        updateSettingCompleteButtonState()
    }

    private func animateButtonFade(_ button: UIButton, fadeIn: Bool) {
        UIView.animate(withDuration: 0.3) {
            if fadeIn {
                button.alpha = 0.5
            } else {
                button.alpha = 1.0
            }
        }
    }

    private func updateSettingCompleteButtonState() {
        if selectedTag != nil {
            tagSettingCompletedButton.isEnabled = true
        } else {
            tagSettingCompletedButton.isEnabled = false
        }
    }

    @objc func presentTagEditViewController() {
        let configureTagViewController = TagConfigurationViewController()
        configureTagViewController.modalPresentationStyle = .fullScreen
        present(configureTagViewController, animated: true)
        tagSettingCompletedButton.isEnabled.toggle()
    }

    @objc private func didTapSettingCompleteButton() {
        guard let selectedTag else {
            return
        }
        selectionDelegate?.tagSelected(with: selectedTag)
        dismiss(animated: true)
    }

    @objc private func deletTag(sender: UIButton) {
        let tagIndex = sender.tag
        Log.info("Button with tag \(sender.tag) was clicked")
        PomodoroPopupBuilder()
            .add(title: "태그 삭제")
            .add(body: "태그를 정말 삭제하시겠습니까? 한 번 삭제한 태그는 다시 되돌릴 수 없습니다.")
            .add(
                button: .cancellable(
                    cancelButtonTitle: "취소",
                    confirmButtonTitle: "확인",
                    cancelButtonAction: nil,
                    confirmButtonAction: { [weak self] in
                        guard let self else { return }
                        do {
                            if let tagToDelete = try RealmService.read(Tag.self).filter("position == \(tagIndex)").first {
                                Log.info("Tag at index \(tagIndex) deleted")
                                selectionDelegate?.tagDidRemoved(tagName: tagToDelete.tagName)
                                RealmService.delete(tagToDelete)
                                tagSettingCompletedButton.isEnabled = true
                                addTagsToStackView()
                            } else {
                                Log.info("No tag found at index \(tagIndex)")
                            }
                        } catch {
                            Log.info("Error deleting tag: \(error)")
                        }
                    }
                )
            )
            .show(on: self)
    }

    @objc private func createMinusButton() {
        tagSettingCompletedButton.isEnabled.toggle()
        for case let button as UIButton in tagsStackView.arrangedSubviews.flatMap(\.subviews) {
            if let minusButton = button.subviews.first(where: { subview in
                guard let btn = subview as? UIButton else { return false }
                return btn.image(for: .normal) == UIImage(named: "minusButton")
            }) as? UIButton {
                minusButton.isHidden.toggle()
                button.bringSubviewToFront(minusButton)
            }
        }
    }
}

// MARK: - TagCreationDelegate

extension TagModalViewController: TagCreationDelegate {
    func createTag(tag: String, color: String, position: Int) {
        RealmService.write(Tag(tagName: tag, colorIndex: color, position: position))
        Log.info("New tag created ==> Name: \(tag), Color Index: \(color), Position: \(position)")
    }
}
