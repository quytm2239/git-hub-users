//
//  LocalDBManager.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 14/06/2022.
//

import Foundation
import CoreData

class LocalDBManager: NSObject {
    
    var container: NSPersistentContainer!
    
    private override init() { super.init() }
    static let current = LocalDBManager()
    
    private var mainContext: NSManagedObjectContext!
    private var backgroundContext: NSManagedObjectContext!
    
    private var writingQueue = DispatchQueue.init(label: "LOCAL_STORAGE_WRITING_QUEUE")

    static func firstSetup() {
        current.container = NSPersistentContainer(name: "GitHubUser")

        current.container.loadPersistentStores { storeDescription, error in
            if let error = error {
                Logger.error("LOCAL_STORAGE_INIT", error.localizedDescription, #fileID, #line)
            }
        }
        current.mainContext = current.container.newBackgroundContext()
        current.backgroundContext = current.container.newBackgroundContext()
        current.backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
//        current.backgroundContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Core Data Fetching/Saving support
    static func fetch<T: NSManagedObject>(request: NSFetchRequest<T>, completion: @escaping (Result<[T], Error>) -> Void) {
        current.mainContext.perform {
            do {
                let resultT = try current.mainContext.fetch(request)
                completion(.success(resultT))
                
            } catch let error as NSError {
                Logger.error("LOCAL_STORAGE", error.localizedDescription, #fileID, #line)
                completion(.failure(error))
            }
        }
    }
    
    static func fetchForModification<T: NSManagedObject>(request: NSFetchRequest<T>, completion: @escaping (Result<[T], Error>) -> Void) {
        current.mainContext.perform {
            do {
                let resultT = try current.backgroundContext.fetch(request)
                completion(.success(resultT))
                
            } catch let error as NSError {
                Logger.error("LOCAL_STORAGE", error.localizedDescription, #fileID, #line)
                completion(.failure(error))
            }
        }
    }
    
    static func commitChange(completion: @escaping (Result<Bool, Error>) -> Void) {
        current.writingQueue.async {
            let contextBG = current.backgroundContext!
            if contextBG.hasChanges {
                do {
                    try contextBG.save()
                    contextBG.refreshAllObjects()
                    completion(.success(true))
                } catch {
                    let nserror = error as NSError
                    Logger.error("LOCAL_STORAGE", nserror.localizedDescription, #fileID, #line)
                    completion(.failure(nserror))
                }
            }
        }
    }
    
    static func batch(insertRequest: NSBatchInsertRequest, completion: @escaping (Result<Bool, Error>) -> Void) {
        current.writingQueue.async {
            do {
                try current.backgroundContext.execute(insertRequest)
                try current.backgroundContext.save()
                current.mainContext.refreshAllObjects()
                current.backgroundContext.refreshAllObjects()
                Logger.d("LOCAL_STORAGE", "Finished batch insert", #fileID, #line)
                completion(.success(true))
                
            } catch let error as NSError {
                Logger.error("LOCAL_STORAGE", error.localizedDescription, #fileID, #line)
                completion(.failure(error))
            }
        }
    }
    
    // fetch all then delete all item
    static func truncate<T: NSManagedObject>(table: T.Type, completion: @escaping (Result<Bool, Error>) -> Void) {
        let fetchRequest = table.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        current.writingQueue.async {
            do {
                try current.backgroundContext.execute(deleteRequest)
                try current.backgroundContext.save()
                
                current.mainContext.refreshAllObjects()
                current.backgroundContext.refreshAllObjects()
                Logger.d("LOCAL_STORAGE", "Finished truncate", #fileID, #line)
                completion(.success(true))
                
            } catch let error as NSError {
                Logger.error("LOCAL_STORAGE", error.localizedDescription, #fileID, #line)
                completion(.failure(error))
            }
        }
    }

    static func saveContext() {
        current.writingQueue.async {
            let context = current.mainContext!
            if context.hasChanges {
                do {
                    try context.save()
                    context.refreshAllObjects()
                } catch {
                    let nserror = error as NSError
                    Logger.error("LOCAL_STORAGE", nserror.localizedDescription, #fileID, #line)
                }
            }
            
            let contextBG = current.backgroundContext!
            if contextBG.hasChanges {
                do {
                    try contextBG.save()
                    contextBG.refreshAllObjects()
                } catch {
                    let nserror = error as NSError
                    Logger.error("LOCAL_STORAGE", nserror.localizedDescription, #fileID, #line)
                }
            }
        }
    }
}
