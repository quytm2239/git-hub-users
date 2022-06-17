//
//  UserProfileVM.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 16/06/2022.
//

import Foundation
import Combine

enum UserProfileNotificationEnum: String {
    case updateNote
    
    var name: String {
        switch self {
        case .updateNote: return "\(self)"
        }
    }
}

protocol UserProfileVMProtocol {
    func firstLoad()
    func updateNote(note: String)
    
    var userProfile: PassthroughSubject<RUserItem, Never> { get }
    var dataStatus: PassthroughSubject<(Bool,String), Never> { get }
    var loadingChange: PassthroughSubject<Bool, Never> { get }
}

class UserProfileVM: UserProfileVMProtocol {
    
    private var cancellable = Set<AnyCancellable>()
    
    private let repo: UserRepositoryProtocol!
    init(repo: UserRepositoryProtocol, userItem: RUserItem) {
        self.repo = repo
        self.userItem = userItem
        self.binding()
    }
    
    private let localQueue = DispatchQueue(label: "USER_PROFILE_LOCAL_QUEUE")
    
    // MARK: - Data source properties
    private var userItem: RUserItem!
        
    func binding() {
        let notiNetworkStatus = NSNotification.Name(rawValue: NetworkUtil.KeyNetworkStatus)
        NotificationCenter.default.addObserver(forName: notiNetworkStatus, object: nil, queue: .main)
        {[weak self] _ in
            // Here we only refresh and update local user items
            // if now is connected and app is disconnected before
            if NetworkUtil.connectionStatus && NetworkUtil.isDisconnectedBefore() {
                self?.firstLoad()
            }
        }
    }

    // MARK: - Interface implementations
    
    // MARK: # Variable definitions

    let _userProfile = PassthroughSubject<RUserItem, Never>()
    var userProfile: PassthroughSubject<RUserItem, Never> {
        return self._userProfile
    }
    
    let _dataStatus = PassthroughSubject<(Bool,String), Never>()
    var dataStatus: PassthroughSubject<(Bool,String), Never> {
        return self._dataStatus
    }
    
    let _loadingChange = PassthroughSubject<Bool, Never>()
    var loadingChange: PassthroughSubject<Bool, Never> {
        return self._loadingChange
    }
        
    // MARK: # For UI action handler implementations
    
    func firstLoad() {
        self.repo.getLocalUserProfile(userLogin: self.userItem.login) { [weak self] localResult in
            guard let _self = self else { return }
            _self.handleLoadResult(localResult, isLocal: true)
            
            // Delay reload for user profile
            _self.localQueue.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                _self.repo.getUserProfile(userLogin: _self.userItem.login) { remoteResult in
                    _self.handleLoadResult(remoteResult, isLocal: false)
                }
            }
        }
    }
    
    func updateNote(note: String) {
        if note.count >= LUserItem.maxNoteLength {
            return self._dataStatus.send((false, "Note's length must not exceed: \(LUserItem.maxNoteLength)"))
        }
        self.repo.updateUser(note: note, userLogin: self.userItem.login) { updateResult in
            switch updateResult {
            case .success(_):
                self.userItem.note = note // save for next usage
                NotificationCenter.post(UserProfileNotificationEnum.updateNote.name, object: self.userItem)
                self._dataStatus.send((true, "Updated note successfully!"))
                Logger.d("USER_PROFILE", "Update note successfully", #fileID, #line)
            case .failure(let error):
                self._dataStatus.send((false, error.errorDescription ?? CommonError.unknow.errorDescription!))
            }
        }
    }
    
    private func handleLoadResult(_ result: Result<RUserItem?, CommonError>, isLocal: Bool) {
        switch result {
        case .success(let user):
            if let _user = user {
                
                if !isLocal {
                    // We update current user item by remote data fetched from api call
                    self.userItem.update(remote: _user)
                    
                    // trigger hide the skeleton when we get the remote user profile data
                    self._loadingChange.send(false)
                    self._userProfile.send(self.userItem)

                    self.userItem.isProfileLoaded = true
                    self.repo.updateUser(new: self.userItem) { result in
                        switch result {
                        case .success(_):
                            Logger.d("USER_PROFILE", "Finish updating user profile with detail data", #fileID, #line)
                        case .failure(let error):
                            Logger.error("USER_PROFILE", "Fail to update user profile: \(error.errorDescription ?? "")", #fileID, #line)
                        }
                    }
                } else {
                    
                    // We save the local user that is fectched by query
                    self.userItem = _user // save for next usage
                    
                    if self.userItem.isProfileLoaded {
                        // if this user's profile is loaded, trigger hide the skeleton
                        self._loadingChange.send(false)
                        self._userProfile.send(self.userItem)
                    }
                    
                    // Delay trigger UI update to avoid blocking
                    self.localQueue.asyncAfter(deadline: DispatchTime.now() + 5) {
                        self._userProfile.send(self.userItem)
                    }
                        
                    // Update seen status
                    self.userItem.isSeen = true
                    self.repo.updateUser(new: self.userItem) { result in
                        switch result {
                        case .success(_):
                            NotificationCenter.post(UserProfileNotificationEnum.updateNote.name, object: self.userItem)
                            Logger.d("USER_PROFILE", "Finish updating user profile seen status", #fileID, #line)
                        case .failure(let error):
                            Logger.error("USER_PROFILE", "Fail to update seen status: \(error.errorDescription ?? "")", #fileID, #line)
                        }
                    }
                }
            } else {
                self._dataStatus.send((false, "User: \(self.userItem.login) not found"))
            }
        case .failure(let error):
            self._dataStatus.send((false, error.errorDescription ?? CommonError.unknow.errorDescription!))
        }
    }
}
