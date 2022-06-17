//
//  ListUserVM.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 14/06/2022.
//

import UIKit
import Combine

protocol ListUserVMProtocol {
    func registerCell(tableView: UITableView)
    func getItemCount() -> Int
    func getItemView(tableView: UITableView, indexPath: IndexPath) -> ListUserItemTableCellProtocol
    func getHeight(at indexPath: IndexPath) -> CGFloat
    
    func firstLoad(isUIRefresh: Bool)
    func click(at indexPath: IndexPath)
    func loadMore()
    
    var onSearch: CurrentValueSubject<String, Never> { get }
    var onListStatusChanged: PassthroughSubject<String, Never> { get }
    var onDataChanged: PassthroughSubject<Void, Never> { get }
}

protocol ListUserVMUIProtocol {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
}

class ListUserVM: ListUserVMProtocol {
    
    private var cancellable = Set<AnyCancellable>()
    
    private let repo: UserRepositoryProtocol!
    init(repo: UserRepositoryProtocol) {
        self.repo = repo
        self.currentPageSize = UserDefaults.get(ListUserVM.keyLastPageSize) ?? 0
        self.binding()
    }
    
    // MARK: - Data source props
    fileprivate var listUser: [RUserItem] = []
    fileprivate var listSearchedUser: [RUserItem] = []
    fileprivate var currentPageSize = 0
    fileprivate var currentPageNumber = 1
    fileprivate var canLoadMore = true
    fileprivate var isLoadingData = false
    
    func binding() {
        _onSearch
            .dropFirst() // ignore first/initialized value in this stream
            .sink {[unowned self] keyword in
                self.handleLocalSearching(keyword)
            }.store(in: &cancellable)
        
        let notiNetworkStatus = NSNotification.Name(rawValue: NetworkUtil.KeyNetworkStatus)
        NotificationCenter.default.addObserver(forName: notiNetworkStatus, object: nil, queue: .main)
        {[weak self] _ in
            // Here we only refresh and update local user items
            // if now is connected and app is disconnected before
            if NetworkUtil.connectionStatus && NetworkUtil.isDisconnectedBefore() {
                self?.currentPageSize = 0 // reset for dynamic pageSize
                self?.currentPageNumber = 1
                self?.canLoadMore = true
                
                self?.getRemoteUserData(since: 0, isLoadMore: false, isUIRefresh: false)
            }
        }
        
        let notiUpdateUserNote = NSNotification.Name(rawValue: UserProfileNotificationEnum.updateNote.name)
        NotificationCenter.default.addObserver(forName: notiUpdateUserNote, object: nil, queue: .main)
        {[weak self] noti in
            if let user = noti.object as? RUserItem {
                self?.updateItem(with: user)
            }
        }
    }

    // MARK: - Interface implementations
    
    // MARK: # Variable definitions
    let _onDataChanged = PassthroughSubject<Void, Never>()
    var onDataChanged: PassthroughSubject<Void, Never> {
        return self._onDataChanged
    }
    
    let _onSearch = CurrentValueSubject<String, Never>("")
    var onSearch: CurrentValueSubject<String, Never> {
        return self._onSearch
    }
    
    let _onListStatusChanged = PassthroughSubject<String, Never>()
    var onListStatusChanged: PassthroughSubject<String, Never> {
        return self._onListStatusChanged
    }
    
    // MARK: # For ListView implementations
    func registerCell(tableView: UITableView) {
        tableView.register(UINib(nibName: ListUserItemTableCell.typeName, bundle: nil),
                           forCellReuseIdentifier: ListUserItemTableCell.typeName)
    }
    
    func getItemCount() -> Int {
        if !self._onSearch.value.isEmpty { return self.listSearchedUser.count }
        return listUser.count
    }
    
    func getItemView(tableView: UITableView, indexPath: IndexPath) -> ListUserItemTableCellProtocol {
        let cell: ListUserItemTableCellProtocol
        = tableView.dequeueReusableCell(withIdentifier: ListUserItemTableCell.typeName, for: indexPath)
        as! ListUserItemTableCell
        
        let isInverted = indexPath.item != 0 && (indexPath.item + 1) % 4 == 0
        (cell as? ListUserItemTableCell)?.indexPath = indexPath

        if self._onSearch.value.isEmpty  {
            let item = self.listUser[indexPath.item]
            cell.display(item: item, isInverted: isInverted, hasNote: !item.note.isEmpty, seen: item.isSeen, indexPath: indexPath)
            
            if let imgURL = item.avatarUrlToLoad {
                ImageDownloader.loadImage(imgURL: imgURL, index: indexPath) { loadedURL, loadedImage, loadedIndex in
                    delayOnMain(0.3) {
                        if let cell = tableView.cellForRow(at: loadedIndex) as? ListUserItemTableCellProtocol {
                            cell.display(item: item, isInverted: isInverted, hasNote: !item.note.isEmpty, seen: item.isSeen, indexPath: indexPath)
                        }
                    }
                }
            }
            
        } else {
            let item = self.listSearchedUser[indexPath.item]
            cell.display(item: item, isInverted: isInverted, hasNote: !item.note.isEmpty, seen: item.isSeen, indexPath: indexPath)
            
            if let imgURL = item.avatarUrlToLoad {
                ImageDownloader.loadImage(imgURL: imgURL, index: indexPath) { loadedURL, loadedImage, loadedIndex in
                    delayOnMain(0.3) {
                        if let cell = tableView.cellForRow(at: loadedIndex) as? ListUserItemTableCellProtocol {
                            cell.display(item: item, isInverted: isInverted, hasNote: !item.note.isEmpty, seen: item.isSeen, indexPath: indexPath)
                        }
                    }
                }
            }
        }
        
        return cell
    }
    
    func getHeight(at indexPath: IndexPath) -> CGFloat {
        return ListUserItemTableCell.desiredHeight
    }
    
    // MARK: # For data loading, UI action,...
    private var focusedIndex: IndexPath?
    func click(at indexPath: IndexPath) {
        Logger.i("FOCUS_USER", "index: \(indexPath.item)", #fileID, #line)
        self.focusedIndex = indexPath // cache here for fast update
        if self._onSearch.value.isEmpty {
            NavigationCenter.openUserProfile(user: self.listUser[indexPath.item])
        } else {
            NavigationCenter.openUserProfile(user: self.listSearchedUser[indexPath.item])
        }
    }
    
    func updateItem(with user: RUserItem) {
        guard let indexToUpdate = focusedIndex else { return }
        // update corresponding item with above index
        if self._onSearch.value.isEmpty {
            if indexToUpdate.item < self.listUser.count {
                self.listUser[indexToUpdate.item] = user
            }
        } else {
            if indexToUpdate.item < self.listSearchedUser.count {
                self.listSearchedUser[indexToUpdate.item] = user
            }
        }
        self._onDataChanged.send()
    }
    
    func firstLoad(isUIRefresh: Bool) {
        
        if isUIRefresh && !self._onSearch.value.isEmpty {
            // If user pull down to refresh while in SEARCH_MODE,
            // we just refresh UI to close refreshing and do nothing
            self._onDataChanged.send()
            return
        }
        
        // reset paging data
        self.currentPageNumber = 1
        self.canLoadMore = true
        
        // Load local DB if connection is not available, we already have last pageSize that is saved before
        if self.currentPageSize > 0 {
            self.fetchLocalUserItems(page: self.currentPageNumber, size: self.currentPageSize)
            {[weak self] hasData in
                if !hasData {
                    // we fetch remote data if local is empty
                    self?.getRemoteUserData(since: 0, isLoadMore: false, isUIRefresh: isUIRefresh)
                } else {
                    // we still update silently the local data with remote data
                    self?.getRemoteUserAndCacheSilently(since: 0)
                }
            }
            
        } else {
            // we fetch remote data because of local is empty
            self.getRemoteUserData(since: 0, isLoadMore: false, isUIRefresh: isUIRefresh)
        }
    }
    
    func loadMore() {
        
        // if user is searching something, we dont do loadmore or pagination
        if !self._onSearch.value.isEmpty { return }
        
        // Reached last page we cant loadmore
        if !self.canLoadMore { return }
        
        guard let last = self.listUser.last else { return }
        
        if self.isLoadingData { return }
        self.isLoadingData = true // set this flag to block UI triggers loadmore
        
        let lastItemId = last.userId

        // Load local DB if connection is not available, we already have last pageSize that is saved before
        if self.currentPageSize > 0 {
            self.fetchLocalUserItems(page: self.currentPageNumber, size: self.currentPageSize)
            {[weak self] hasData in
                guard let _self = self else { return }
                
                if !hasData {
                    // we fetch remote data if local is empty
                    _self.getRemoteUserData(since: Int(lastItemId), isLoadMore: true, isUIRefresh: false)
                } else {
                    // we still update silently the local data with remote data
                    _self.getRemoteUserAndCacheSilently(since: Int(lastItemId))
                }
            }
        } else {
            // we fetch remote data because of local is empty
            // in case, we failed to save currentPageSize
            self.getRemoteUserData(since: Int(lastItemId), isLoadMore: true, isUIRefresh: false)
        }
    }
        
    // Handle debounce searching
    func handleLocalSearching(_ keyword: String) {
        
        // we return to normal list if user doesnt search anything (empty keyword)
        if keyword.isEmpty {
            self._onListStatusChanged.send("Total user is \(self.listUser.count)")
            self._onDataChanged.send()
            return
        }
        
        self.repo.searchUsers(keyword: keyword) {[weak self] result in
            switch result {
            case .success(let data):
                self?.listSearchedUser = data
                self?._onListStatusChanged.send("Found total \(data.count) item(s)")
            case .failure(_):
                self?.listSearchedUser = []
                self?._onListStatusChanged.send("Found nothing with keyword: \(keyword)")
            }
            self?._onDataChanged.send()
        }
    }
    
    // MARK: - Local functions
    private func getRemoteUserData(since: Int, isLoadMore: Bool, isUIRefresh: Bool) {
        
        // User pull down to refresh so we won't show the loading
        if !isUIRefresh {
            if isLoadMore {
                CustomLoading.showNonBlock()
            } else {
                CustomLoading.show()
            }
        }
        
        self.repo.getUsers(since: since) { [weak self] result in
            CustomLoading.hide()
            
            // We update dataSource and trigger reload,...
            self?.handleOnUsersResult(result, isLoadMore: isLoadMore, fromRemote: true)
            
            switch result {
            case .success(let remoteData):
                // We persist to localDB to allow user can use app in offline mode
                self?.cacheRemoteUser(remoteData, isMerging: false)
                
            case .failure(let error):
                Logger.error("LIST_USER", "Load remote user: \(String(describing: error.errorDescription))", #fileID, #line)
            }
        }
    }
    
    private func getRemoteUserAndCacheSilently(since: Int) {
        Logger.d("LIST_USER", "Start remote user silently with userId: \(since)", #fileID, #line)
        self.repo.getUsers(since: since) { [weak self] result in
            
            switch result {
            case .success(let remoteData):
                // We persist to localDB to allow user can use app in offline mode
                self?.cacheRemoteUser(remoteData, isMerging: true)
                
            case .failure(let error):
                Logger.error("LIST_USER", "Load remote user silently: \(String(describing: error.errorDescription))", #fileID, #line)
            }
        }
    }
    
    private func cacheRemoteUser(_ remoteData: [RUserItem], isMerging: Bool) {
        
        if isMerging {
            self.repo.mergeRemoteUserWithLocal(items: remoteData, isFullMerging: false) { mergeResult in
                switch mergeResult {
                case .success(_):
                    Logger.d("LIST_USER", "Merge succesfully", #fileID, #line)
                case .failure(let error):
                    Logger.error("LIST_USER", "Merge had error: \(String(describing: error.errorDescription))", #fileID, #line)
                }
            }
            return
        }
        
        // We persist to localDB to allow user can use app in offline mode
        // BulkInsert for first insert, if objects are presented, we perform merging
        self.repo.bulkInsert(users: remoteData, validate: false) { insertResult in
            switch insertResult {
            case .success(_):
                Logger.d("LIST_USER", "Inserted succesfully", #fileID, #line)
            case .failure(let error):
                Logger.error("LIST_USER", "Inserting had error: \(String(describing: error.errorDescription))", #fileID, #line)
            }
        }
    }
    
    /// - completion - return true if we already have local data of users
    private func fetchLocalUserItems(page: Int, size: Int, completion: @escaping (Bool) -> Void) {
        self.repo.getLocalUsers(page: page, size: size)
        { [weak self] localUserFetchResult in
            switch localUserFetchResult {
            case .success(let localUsers):
                if localUsers.isEmpty {
                    completion(false)
                } else {
                    self?.handleOnUsersResult(localUserFetchResult, isLoadMore: page > 1, fromRemote: false)
                    completion(true)
                }
            case .failure(let error):
                Logger.error("LIST_USER", "Fetch local: \(String(describing: error.errorDescription))", #fileID, #line)
                completion(false)
            }
        }
    }
    
    private func handleOnUsersResult(_ value: Result<[RUserItem], CommonError>, isLoadMore: Bool, fromRemote: Bool) {
        switch value {
        case .success(let data):
            
            // Here is loadmore so we append new items to current list
            if isLoadMore {
                self.listUser.append(contentsOf: data)
            } else {
                self.listUser = data
            }
            
            // If not in SEARCH MODE, we will update list status
            if self._onSearch.value.isEmpty {
                self._onListStatusChanged.send("Total user is \(self.listUser.count)")
            }
            
            // Trigger UI updating
            self._onDataChanged.send()
            
            Logger.d("LOAD_USER", "item count: \(data.count), page: \(self.currentPageNumber)", #fileID, #line)
            
            // We save the dynamic pageSize when user perform first loading
            if self.currentPageNumber == 1 && fromRemote {
                self.currentPageSize = data.count
                UserDefaults.setValue(data.count, ListUserVM.keyLastPageSize)
            }
            
            // Move to next page for next loadmore
            self.currentPageNumber += 1
            
            // We reached the last page if this loading call returns less record than pageSize
            self.canLoadMore = data.count == self.currentPageSize

        case .failure(let error):
            NavigationCenter.showToast(error: error.errorDescription ?? "")
            Logger.error("LOAD_USER", error.errorDescription ?? "", #fileID, #line)
        }
        
        self.isLoadingData = false // reset this flag here for next action
    }
}

extension ListUserVM: ListUserVMUIProtocol {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        ImageDownloader.pauseAllDownload()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            handleResumeDownloadOnEndDragging(scrollView: scrollView)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handleResumeDownloadOnEndDragging(scrollView: scrollView)
    }
    
    private func handleResumeDownloadOnEndDragging(scrollView: UIScrollView) {
        if let tableView = scrollView as? UITableView, let visibleIndex = tableView.indexPathsForVisibleRows {
            var imgToDownload = Set<String>()
            
            for path in visibleIndex {
                if self.onSearch.value.isEmpty {
                    // not in SEARCHING MODE
                    if let avtUrl = self.listUser[path.item].avatarUrl {
                        imgToDownload.insert(avtUrl)
                    }
                } else {
                    // in SEARCHING MODE
                    if let avtUrl = self.listSearchedUser[path.item].avatarUrl {
                        imgToDownload.insert(avtUrl)
                    }
                }
            }
            // Update prioritized downloader
            ImageDownloader.forceDownload(setNeedToBeDownloaded: imgToDownload)
            // Trigger UI update for current visible cell item
            tableView.reloadRows(at: visibleIndex, with: .none)
        }
    }
    
    static let keyLastPageSize = "keyLastPageSize"
}
