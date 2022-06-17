//
//  ListUserScreen.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 14/06/2022.
//

import UIKit
import Combine

class ListUserScreen: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle { return .darkContent }

    @IBOutlet weak var viewContainerTextSearch: UIView!
    @IBOutlet weak var textFieldSearch: BaseTextField!
    @IBOutlet weak var tableViewUser: UITableView!
    @IBOutlet weak var labelListStatus: UILabel!
    
    fileprivate var lastOffSet = CGPoint.zero
    fileprivate var cancellable = Set<AnyCancellable>()
    var vm: (ListUserVMProtocol & ListUserVMUIProtocol)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.binding()
        self.vm.firstLoad(isUIRefresh: false)
        Logger.d("LIFE_CYCLE", "ListUserScreen is loaded.", #fileID, #line)
    }
    
    fileprivate func setupUI() {
        self.viewContainerTextSearch.clipsToBounds = true
        self.viewContainerTextSearch.layer.cornerRadius
        = self.viewContainerTextSearch.bounds.height / 2
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.tableViewUser.tableFooterView = UIView()
        self.tableViewUser.separatorStyle = .none
        
        let refresh = UIRefreshControl()
        refresh.tintColor = .lightGray
        refresh.addTarget(self, action: #selector(triggerRefreshOnUI), for: .valueChanged)
        self.tableViewUser.refreshControl = refresh
    }
    
    fileprivate func binding() {
        
        self.tableViewUser.dataSource = self
        self.tableViewUser.delegate = self
        self.vm.registerCell(tableView: self.tableViewUser)
        
        self.vm.onDataChanged
            .receive(on: DispatchQueue.main)
            .sink {[weak self] in
                self?.tableViewUser.reloadData()
                self?.tableViewUser.refreshControl?.endRefreshing()
            }.store(in: &cancellable)
        
        self.vm.onListStatusChanged
            .receive(on: DispatchQueue.main)
            .sink {[weak self] statusStr in
                self?.labelListStatus.text = statusStr
            }.store(in: &cancellable)
        
        self.textFieldSearch.debounce(0.5) { text in
            self.vm.onSearch.send(text)
        }
    }
    
    @objc fileprivate func triggerRefreshOnUI() {
        self.vm.firstLoad(isUIRefresh: true)
    }
    
    deinit {
        Logger.d("LIFE_CYCLE", "ListUserScreen is deinitialized.", #fileID, #line)
    }
}

extension ListUserScreen: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vm.getItemCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return vm.getItemView(tableView: tableView, indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return vm.getHeight(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        vm.click(at: indexPath)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offSetY = scrollView.contentOffset.y
        let isScrollUp = lastOffSet.y < offSetY
        lastOffSet = scrollView.contentOffset

        if !isScrollUp { return }
        // we suppose that when user scroll the list until the bottom side of visible frame reach the end area
        // ex: area height is 100px
        let focusPointY = offSetY + scrollView.bounds.height
        let reachedEndArea = scrollView.contentSize.height - focusPointY <= 150
        if reachedEndArea {
            vm.loadMore()
        }
    }
    
    // MARK: - ListUserVMUIProtocol
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        vm.scrollViewWillBeginDragging(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        vm.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        vm.scrollViewDidEndDecelerating(scrollView)
    }
}

extension ListUserScreen {
    static func build() -> ListUserScreen {
        let view = ListUserScreen()
        view.vm = ListUserVM(repo: UserRepository())
        return view
    }
}
