//
//  ListUserItemTableCell.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 14/06/2022.
//

import UIKit

protocol ListUserItemTableCellProtocol: UITableViewCell {
    func display(item: RUserItem, isInverted: Bool, hasNote: Bool, seen: Bool, indexPath: IndexPath)
}

class ListUserItemTableCell: UITableViewCell, ListUserItemTableCellProtocol {

    static let desiredHeight: CGFloat = 86
    
    @IBOutlet weak var stackViewContainer: UIStackView!
    @IBOutlet weak var viewHasNote: UIView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var imageViewAvatar: UIImageView!
    @IBOutlet weak var labelDesc: UILabel!
    @IBOutlet weak var iconLoadingAvatar: UIActivityIndicatorView!
    
    var indexPath: IndexPath?
    var pendingImgURL: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.imageViewAvatar.layer.cornerRadius = self.imageViewAvatar.bounds.height / 2
        self.imageViewAvatar.clipsToBounds = true
        self.imageViewAvatar.backgroundColor = UIColor.lightGray
        self.stackViewContainer.layer.cornerCurve = .continuous
        self.stackViewContainer.layer.cornerRadius = 10
        self.stackViewContainer.clipsToBounds = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.iconLoadingAvatar.startAnimating()
        self.imageViewAvatar.image = nil
    }
    
    func display(item: RUserItem, isInverted: Bool, hasNote: Bool, seen: Bool, indexPath: IndexPath) {
        self.viewHasNote.isHidden = !hasNote
        self.labelName.text = item.login.uppercased()
        self.labelDesc.text = item.type
        self.stackViewContainer.backgroundColor = seen ? .systemGray5 : .white
        
        guard let needLoadImgUrl = item.avatarUrlToLoad else {
            self.iconLoadingAvatar.stopAnimating()
            self.imageViewAvatar.image = nil // clear image because this user doesn't have avatar
            self.pendingImgURL = nil
            return
        }
        
        // else, we start load user's avatar asynchoronously
        self.pendingImgURL = needLoadImgUrl
        self.iconLoadingAvatar.startAnimating()
        self.imageViewAvatar.image = nil
        let imageStatus = ImageDownloader.syncLoadImage(imgURL: needLoadImgUrl)
        switch imageStatus.2 {
        case .new, .loading:
            break
        case .error:
            self.iconLoadingAvatar.stopAnimating()
        case .done:
            guard let loadedImg = imageStatus.1 else {
                return self.iconLoadingAvatar.stopAnimating()
            }
            let neededImage = isInverted ? loadedImg.inverseImage() : loadedImg
            self.iconLoadingAvatar.stopAnimating()
            self.imageViewAvatar.image = neededImage
        }
    }
}
