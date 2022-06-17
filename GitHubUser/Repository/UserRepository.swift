//
//  UserRepository.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 15/06/2022.
//

import Foundation
import CoreData

protocol UserRepositoryProtocol {
    
    func getUsers(since: Int, completion: @escaping (Result<[RUserItem], CommonError>) -> Void)
    func getUserProfile(userLogin: String, completion: @escaping (Result<RUserItem?, CommonError>) -> Void)
    
    func getLocalUsers(page: Int, size: Int, completion: @escaping (Result<[RUserItem], CommonError>) -> Void)
    func searchUsers(keyword: String, completion: @escaping (Result<[RUserItem], CommonError>) -> Void)
    func getLocalUserProfile(userLogin: String, completion: @escaping (Result<RUserItem?, CommonError>) -> Void)
    
    func bulkInsert(users: [RUserItem], validate: Bool, completion: @escaping (Result<Bool, CommonError>) -> Void)
    func truncateUserItem(completion: @escaping (Result<Bool, CommonError>) -> Void)
    
    func updateUser(note: String, userLogin: String, completion: @escaping (Result<Bool, CommonError>) -> Void)
    func updateUser(new: RUserItem, completion: @escaping (Result<Bool, CommonError>) -> Void)
    func mergeRemoteUserWithLocal(items: [RUserItem], isFullMerging: Bool, completion: @escaping (Result<Bool, CommonError>) -> Void)
}

class UserRepository: UserRepositoryProtocol {
    
    // MARK: - Remote fetchings
    func getUsers(since: Int, completion: @escaping (Result<[RUserItem], CommonError>) -> Void) {
        ApiClient.execute(apiRequest: GetListUserRequest.init(since: since), retry: 0, completionHandler: completion)
    }
    
    func getUserProfile(userLogin: String, completion: @escaping (Result<RUserItem?, CommonError>) -> Void) {
        ApiClient.execute(apiRequest: GetUserProfileRequest.init(userLogin: userLogin), retry: 0, completionHandler: completion)
    }
    
    // MARK: - Local fetchings
    func getLocalUsers(page: Int, size: Int, completion: @escaping (Result<[RUserItem], CommonError>) -> Void) {
        let fetchRequest = LUserItem.fetchRequest()
        
        // we setup a pagination loading here
        fetchRequest.fetchOffset = (page - 1) * size
        fetchRequest.fetchLimit = size
        fetchRequest.fetchBatchSize = size
        fetchRequest.sortDescriptors = [.init(key: "userId", ascending: true)]
        
        LocalDBManager.fetch(request: fetchRequest) { result in
            switch result {
            case .success(let data):
                let finalItems: [RUserItem] = data.map({ lUser in
                    return RUserItem.build(with: lUser)
                })
                completion(.success(finalItems))
            case .failure(let err):
                completion(.failure(.custom(message: err.localizedDescription)))
            }
        }
    }
    
    func getLocalUserProfile(userLogin: String, completion: @escaping (Result<RUserItem?, CommonError>) -> Void) {

        let predicateFormat = "login LIKE %@"
        let searchPredicate = NSPredicate(format: predicateFormat, userLogin)
        
        let fetchRequest = LUserItem.fetchRequest()
        fetchRequest.predicate = searchPredicate
        
        LocalDBManager.fetch(request: fetchRequest) { result in
            switch result {
            case .success(let data):
                if data.isEmpty {
                    completion(.success(nil))
                    return
                }
                let finalItems: [RUserItem] = data.map({ lUser in
                    return RUserItem.build(with: lUser)
                })
                completion(.success(finalItems.first!))
            case .failure(let err):
                completion(.failure(.custom(message: err.localizedDescription)))
            }
        }
    }
    
    func searchUsers(keyword: String, completion: @escaping (Result<[RUserItem], CommonError>) -> Void) {
        let fetchRequest = LUserItem.fetchRequest()
        
        // Compare with [login] first then [note]
        let orCombine = " OR "
        let predicateFormat = "login LIKE[c] %@"
            .appending(orCombine).appending("login CONTAINS[c] %@")
            .appending(orCombine).appending("note LIKE[c] %@")
            .appending(orCombine).appending("note CONTAINS[c] %@")
        
        let searchPredicate = NSPredicate(format: predicateFormat, keyword, keyword, keyword, keyword)
        fetchRequest.predicate = searchPredicate
        fetchRequest.sortDescriptors = [.init(key: "userId", ascending: true)]

        Logger.d("USER_REPO", predicateFormat, #fileID, #line)
        
        LocalDBManager.fetch(request: fetchRequest) { result in
            switch result {
            case .success(let data):
                let finalItems: [RUserItem] = data.map({ lUser in
                    return RUserItem.build(with: lUser)
                })
                completion(.success(finalItems))
            case .failure(let err):
                completion(.failure(.custom(message: err.localizedDescription)))
            }
        }
    }
    
    func bulkInsert(users: [RUserItem], validate: Bool, completion: @escaping (Result<Bool, CommonError>) -> Void) {
        
        /// for testing only
//        if validate {
//            for item in users {
//                if item.note.count > LUserItem.maxNoteLength {
//                    let result: Result<Bool, CommonError> = .failure(.custom(message: "Length of [Note] is longer than \(LUserItem.maxNoteLength)"))
//                    completion(result)
//                    return
//                }
//            }
//        }
        
        var index = 0
        let total = users.count
        
        let batchInsert = NSBatchInsertRequest(
            entity: LUserItem.entity()) { (managedObject: NSManagedObject) -> Bool in
                guard index < total else { return true }
                
                if let lUser = managedObject as? LUserItem {
                    let data = users[index]
                    lUser.updateFully(with: data)
                }

                index += 1
                return false
            }
 
        LocalDBManager.batch(insertRequest: batchInsert) { insertResult in
            switch insertResult {
            case .success(let success):
                completion(.success(success))
            case .failure(let err):
                completion(.failure(.custom(message: err.localizedDescription)))
            }
        }
    }
    
    func truncateUserItem(completion: @escaping (Result<Bool, CommonError>) -> Void) {
        
        LocalDBManager.truncate(table: LUserItem.self) { truncateResult in
            switch truncateResult {
            case .success(let success):
                completion(.success(success))
            case .failure(let err):
                completion(.failure(.custom(message: err.localizedDescription)))
            }
        }

    }
    
    func updateUser(new: RUserItem, completion: @escaping (Result<Bool, CommonError>) -> Void) {
        let predicateFormat = "login LIKE %@"
        let searchPredicate = NSPredicate(format: predicateFormat, new.login)
        
        let fetchRequest = LUserItem.fetchRequest()
        fetchRequest.predicate = searchPredicate
        
        LocalDBManager.fetchForModification(request: fetchRequest) { result in
            switch result {
            case .success(let data):
                data.first?.updateFully(with: new)
                LocalDBManager.commitChange { commitResult in
                    switch commitResult {
                    case .success(_):
                        completion(.success(true))
                    case .failure(let err):
                        completion(.failure(.custom(message: err.localizedDescription)))
                    }
                }
            case .failure(let err):
                completion(.failure(.custom(message: err.localizedDescription)))
            }
        }
    }
    
    func updateUser(note: String, userLogin: String, completion: @escaping (Result<Bool, CommonError>) -> Void) {
        let predicateFormat = "login LIKE %@"
        let searchPredicate = NSPredicate(format: predicateFormat, userLogin)
        
        let fetchRequest = LUserItem.fetchRequest()
        fetchRequest.predicate = searchPredicate
        
        LocalDBManager.fetchForModification(request: fetchRequest) { result in
            switch result {
            case .success(let data):
                data.first?.note = note
                LocalDBManager.commitChange { commitResult in
                    switch commitResult {
                    case .success(_):
                        completion(.success(true))
                    case .failure(let err):
                        completion(.failure(.custom(message: err.localizedDescription)))
                    }
                }
            case .failure(let err):
                completion(.failure(.custom(message: err.localizedDescription)))
            }
        }
    }
    
    func mergeRemoteUserWithLocal(items: [RUserItem], isFullMerging: Bool, completion: @escaping (Result<Bool, CommonError>) -> Void) {
        
        let needMergedIds = items.map({ $0.userId })
        let dictUser = Dictionary.init(grouping: items, by: { $0.userId })

        // Retrieve record with item_id which is inside the wantedItemIDs array
        let inclusivePredicate = NSPredicate(format: "userId IN %@", needMergedIds)

        let fetchRequest = LUserItem.fetchRequest()
        fetchRequest.predicate = inclusivePredicate
        
        LocalDBManager.fetchForModification(request: fetchRequest) { result in
            switch result {
            case .success(let data):
                
                for lUser in data {
                    if let remoteUser = dictUser[lUser.userId]?.first {
                        if isFullMerging {
                            lUser.updateFully(with: remoteUser)
                        } else {
                            lUser.updateAsListItem(with: remoteUser)
                        }
                    }
                }
                
                LocalDBManager.commitChange { commitResult in
                    switch commitResult {
                    case .success(_):
                        completion(.success(true))
                    case .failure(let err):
                        completion(.failure(.custom(message: err.localizedDescription)))
                    }
                }
            case .failure(let err):
                completion(.failure(.custom(message: err.localizedDescription)))
            }
        }
    }
}

class GetListUserRequest: ApiRequest {

    var externalUrl: String?
    var method: ApiMethod = .get
    var path: String = "users"
    var parameters: [String : String] = [:]
    var body: [String : Any] = [:]
    
    internal init(since: Int) {
        self.parameters = ["since": "\(since)"]
    }
}

class GetUserProfileRequest: ApiRequest {

    var externalUrl: String?
    var method: ApiMethod = .get
    var path: String = "users"
    var parameters: [String : String] = [:]
    var body: [String : Any] = [:]
    
    internal init(userLogin: String) {
        self.path.append("/\(userLogin)")
    }
}
