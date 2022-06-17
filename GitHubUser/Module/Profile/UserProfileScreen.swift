//
//  UserProfileScreen.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 16/06/2022.
//

import UIKit
import Combine

class UserProfileScreen: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle { return .darkContent }
    
    @IBOutlet weak var scrollViewContainer: UIScrollView!
    @IBOutlet weak var viewBackgroundHeader: UIView!
    @IBOutlet weak var rootContainerView: UIView!
    @IBOutlet weak var buttonBack: UIView!
    @IBOutlet weak var labelNameOfGitUser: UILabel!
    
    @IBOutlet weak var imageViewAvatar: UIImageView!

    @IBOutlet weak var labelFollowers: UILabel!
    @IBOutlet weak var labelFollowing: UILabel!

    @IBOutlet weak var textViewSummary: UITextView!
    @IBOutlet weak var heightOfTextViewSummary: NSLayoutConstraint!

    @IBOutlet weak var textViewInputNote: UITextView!
    @IBOutlet weak var buttonSaveNote: UIButton!
    @IBOutlet weak var labelNotePlaceHolder: UILabel!
    @IBOutlet weak var heightOfTextViewInputNote: NSLayoutConstraint!
    
    @IBOutlet weak var iconLoadingAvatar: UIActivityIndicatorView!
    
    @IBOutlet weak var groupImageView: SmoothCornerView!
    @IBOutlet weak var groupSummary: SmoothCornerView!
    @IBOutlet weak var groupNote: SmoothCornerView!
    
    var previousRect = CGRect.zero
    
    fileprivate var cancellable = Set<AnyCancellable>()
    var vm: UserProfileVMProtocol!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.binding()
        self.vm.firstLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.registerKeyboardNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.unRegisterKeyboardNotification()
    }
    
    // MARK: - Internal setups
    private func setupUI() {
        self.imageViewAvatar.backgroundColor = UIColor.lightGray
        self.imageViewAvatar.layer.cornerRadius = self.imageViewAvatar.bounds.height / 2
        self.viewBackgroundHeader.dropCommonShadow()
        self.textViewInputNote.isSelectable = false
        self.textViewInputNote.isEditable = true
        self.textViewSummary.textContainer.lineFragmentPadding = 6
        self.textViewSummary.textContainerInset = .init(top: 10, left: 14, bottom: 10, right: 14)
        self.textViewInputNote.textContainer.lineFragmentPadding = 6
        self.textViewInputNote.textContainerInset = .init(top: 10, left: 14, bottom: 10, right: 14)
        self.changeSkeletonEffect(enable: true)
        
        self.textViewInputNote.setupDoneDismiss()
    }
    
    private func binding() {
        self.buttonBack.onClick {[unowned self] _ in
            self.navigationController?.popViewController(animated: true)
        }
        
        self.textViewInputNote.delegate = self
        self.buttonSaveNote.onClick {[unowned self] _ in
            _ = self.textViewInputNote.resignFirstResponder()
            self.vm.updateNote(note: self.textViewInputNote.text)
        }
        
        self.vm.dataStatus
            .receive(on: DispatchQueue.main)
            .sink { status in
                NavigationCenter.showToast(error: status.1, success: status.0)
            }.store(in: &cancellable)
        
        self.vm.userProfile
            .receive(on: DispatchQueue.main)
            .sink {[weak self] user in
                self?.display(userProfile: user)
            }.store(in: &cancellable)
        
        self.vm.loadingChange
            .receive(on: DispatchQueue.main)
            .sink {[weak self] status in
                self?.changeSkeletonEffect(enable: status)
            }.store(in: &cancellable)
    }
    
    private func changeSkeletonEffect(enable: Bool) {
        if enable {
            groupImageView.makeSketelon()
            groupNote.makeSketelon()
            groupSummary.makeSketelon()
            labelNameOfGitUser.makeSketelon()
        } else {
            groupImageView.hideSkeleton()
            groupNote.hideSkeleton()
            groupSummary.hideSkeleton()
            labelNameOfGitUser.hideSkeleton()
        }
    }
    
    private func display(userProfile: IUserProfileDisplayData) {
        self.labelNameOfGitUser.text = userProfile.getName()
        self.labelFollowers.text = userProfile.getFollowers()
        self.labelFollowing.text = userProfile.getFollowing()
        self.textViewSummary.text = userProfile.getSummary()
        
        let sizeToFitIn = CGSize(width: self.textViewSummary.bounds.size.width, height: CGFloat(MAXFLOAT))
        let newSize = self.textViewSummary.sizeThatFits(sizeToFitIn)
        self.heightOfTextViewSummary.constant = newSize.height + 20 > 200 ? 200 : newSize.height + 20
        self.textViewSummary.isScrollEnabled = true
        
        if self.textViewInputNote.text.isEmpty {
            self.textViewInputNote.text = userProfile.getNote()
        }
        self.textViewInputNote.autocorrectionType = .no
        self.textViewInputNote.spellCheckingType = .no
        self.textViewInputNote.keyboardDismissMode = .onDrag
        self.textViewInputNote.isScrollEnabled = true
        self.firstUpdateUIForTextInput()
        
        guard let needLoadImgUrl = userProfile.getAvatarUrl() else {
            self.iconLoadingAvatar.stopAnimating()
            self.imageViewAvatar.image = nil // clear image because this user doesn't have avatar
            return
        }
        
        // else, we start load user's avatar asynchoronously
        self.iconLoadingAvatar.startAnimating()
        self.imageViewAvatar.image = nil
        ImageDownloader.loadImage(imgURL: needLoadImgUrl) {[weak self] imgURL, image in
        
            if needLoadImgUrl == imgURL {
                switchToMain {
                    self?.iconLoadingAvatar.stopAnimating()
                    self?.imageViewAvatar.image = image
                }
            }
        }
    }
}

extension UserProfileScreen: UITextViewDelegate {
    
    fileprivate func firstUpdateUIForTextInput() {
        self.labelNotePlaceHolder.isHidden = !self.textViewInputNote.text.isEmpty
        
        let sizeToFitIn = CGSize(width: self.textViewInputNote.bounds.size.width, height: CGFloat(MAXFLOAT))
        let newSize = self.textViewInputNote.sizeThatFits(sizeToFitIn)
        
        let newHeight = newSize.height + 20 > 240 ? 240 : newSize.height + 20
        self.heightOfTextViewInputNote.constant = newHeight < 140 ? 140 : newHeight
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.labelNotePlaceHolder.isHidden = !textView.text.isEmpty
        
        let sizeToFitIn = CGSize(width: textView.bounds.size.width, height: CGFloat(MAXFLOAT))
        let newSize = textView.sizeThatFits(sizeToFitIn)
        
        let newHeight = newSize.height + 20 > 240 ? 240 : newSize.height + 20
        heightOfTextViewInputNote.constant = newHeight < 140 ? 140 : newHeight
        
        let pos = textView.endOfDocument
        let currentRect = textView.caretRect(for: pos)
        self.previousRect = self.previousRect.origin.y == 0.0 ? currentRect : self.previousRect
        if currentRect.origin.y > self.previousRect.origin.y {
//            onReload()
        }
        self.previousRect = currentRect
        
        let y = scrollViewContainer.contentInset.bottom
        scrollViewContainer.setContentOffset(CGPoint.init(x: 0, y: y), animated: true)
    }
}

extension UserProfileScreen {
    static func build(user: RUserItem) -> UserProfileScreen {
        let view = UserProfileScreen()
        view.vm = UserProfileVM(repo: UserRepository(), userItem: user)
        return view
    }
}

extension UserProfileScreen {
    
    fileprivate func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIControl.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIControl.keyboardWillHideNotification, object: nil)
    }
    
    fileprivate func unRegisterKeyboardNotification() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc fileprivate func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrameValue = notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue else { return }
        let keyboardFrame = view.convert(keyboardFrameValue.cgRectValue, from: nil)
        let delta: CGFloat = 46
        let sizeSubHeight = self.scrollViewContainer.contentSize.height - self.scrollViewContainer.bounds.height
        let bottomInset = NavigationCenter.currentWindow.safeAreaInsets.bottom
        if sizeSubHeight < 0 {
            scrollViewContainer.contentInset = .init(top: 0, left: 0, bottom: keyboardFrame.size.height + sizeSubHeight - delta + bottomInset, right: 0)
            let y = scrollViewContainer.contentInset.bottom
            scrollViewContainer.setContentOffset(CGPoint.init(x: 0, y: y), animated: true)
        } else {
            scrollViewContainer.contentInset = .init(top: 0, left: 0, bottom: keyboardFrame.size.height + sizeSubHeight - delta + bottomInset, right: 0)
            let y = scrollViewContainer.contentInset.bottom
            scrollViewContainer.setContentOffset(CGPoint.init(x: 0, y: y), animated: true)
        }

    }

    @objc fileprivate func keyboardWillHide(_ notification: Notification) {
        scrollViewContainer.contentInset = .zero
        scrollViewContainer.contentOffset = .zero
    }
}
