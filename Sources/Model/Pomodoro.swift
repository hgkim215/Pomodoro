//
//  Pomodoro.swift
//  Pomodoro
//
//  Created by 김현기 on 12/27/23.
//  Copyright © 2023 io.hgu. All rights reserved.
//

import RealmSwift
import UIKit

class Pomodoro: Object {
    @Persisted(primaryKey: true) var id: Int
    @Persisted var phaseTime: Int
    @Persisted var phase: Int
    // 1 -> 2 -> 3 -> 4 순으로 가되, 뽀모도로가 모두 완료되면 (성공이든, 실패이든 0으로 변경)
    @Persisted var currentTag: Tag? = Tag(tagName: "집중", colorIndex: "one", position: 0)
    @Persisted var participateDate: Date
    @Persisted var isSuccess: Bool
    @Persisted var isIng: Bool

    convenience init(
        id: Int,
        phaseTime: Int,
        phase: Int = 1,
        currentTag: Tag,
        participateDate: Date = Date.now,
        isSuccess: Bool = false,
        isIng: Bool = true
    ) {
        self.init()
        self.id = id
        self.phaseTime = phaseTime
        self.phase = phase
        self.currentTag = currentTag
        self.participateDate = participateDate
        self.isSuccess = isSuccess
        self.isIng = isIng
    }
}
