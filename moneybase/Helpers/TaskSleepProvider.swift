//
//  TaskSleepProvider.swift
//  moneybase
//
//  Created by Deepak Gupta on 27/03/26.
//

import Foundation

protocol AsyncSleepProviding {
    func sleep(seconds: TimeInterval) async throws
}

struct TaskSleepProvider: AsyncSleepProviding {
    func sleep(seconds: TimeInterval) async throws {
        let nanoseconds = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}
