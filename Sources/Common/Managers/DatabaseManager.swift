//
//  DatabaseManager.swift
//  Pomodoro
//
//  Created by 김현기 on 2/24/24.
//

import Foundation
import OSLog
import RealmSwift

enum RealmService {
    static func read<T: Object>(_ object: T.Type) throws -> Results<T> {
        do {
            let database = try Realm()
//            Log.info("Realm is located at: \(String(describing: database.configuration.fileURL))")
            return database.objects(object)
        } catch {
            Log.error(error)
            throw error
        }
    }

    static func createPomodoro(tag: Tag, phaseTime: Int) {
        do {
            let database = try Realm()
//            Log.info("Realm is located at: \(String(describing: database.configuration.fileURL))")
            var id = 0
            if let lastPomodoro = database.objects(Pomodoro.self).last {
                id = lastPomodoro.id + 1
            }
            let pomodoro = Pomodoro(
                id: id,
                phaseTime: phaseTime,
                phase: 1,
                currentTag: tag,
                participateDate: Date.now
            )
            write(pomodoro)
        } catch {
            Log.error(error)
        }
    }

    static func write(_ object: some Object) {
        do {
            let database = try Realm()
            Log.info("Realm is located at: \(String(describing: database.configuration.fileURL))")
            try database.write {
                database.add(object, update: .modified)
            }
        } catch {
            Log.error(error)
        }
    }

    static func update<T: Object>(_ object: T, completion: @escaping ((T) -> Void)) {
        do {
            let database = try Realm()
//            Log.info("Realm is located at: \(String(describing: database.configuration.fileURL))")
            try database.write {
                completion(object)
            }
        } catch {
            Log.error(error)
        }
    }

    static func delete(_ object: some Object) {
        do {
            let database = try Realm()
//            Log.info("Realm is located at: \(String(describing: database.configuration.fileURL))")
            try database.write {
                database.delete(object)
            }
        } catch {
            Log.error(error)
        }
    }

    static func deleteAll() {
        do {
            let database = try Realm()
//            Log.info("Realm is located at: \(String(describing: database.configuration.fileURL))")
            try database.write {
                database.deleteAll()
            }
        } catch {
            Log.error(error)
        }
    }

    static func sort<T: Object>(
        _ object: T.Type,
        by keyPath: String,
        ascending: Bool = true
    ) throws -> Results<T> {
        do {
            let database = try Realm()
//            Log.info("Realm is located at: \(String(describing: database.configuration.fileURL))")
            return database.objects(object).sorted(byKeyPath: keyPath, ascending: ascending)
        } catch {
            Log.error(error)
            throw error
        }
    }
}
