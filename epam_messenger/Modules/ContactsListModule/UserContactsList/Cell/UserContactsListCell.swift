//
//  UserContactsListCell.swift
//  epam_messenger
//
//  Created by Maxim on 25.03.2020.
//

import UIKit
import Reusable
import Firebase

class UserContactsListCell: UITableViewCell, NibReusable {
    
    @IBOutlet private var avatarImageView: UIImageView!
    @IBOutlet private var localName: UILabel!
    //@IBOutlet private var userIdLabel: UILabel!
    
    var model: UserContactsListModel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        avatarImageView.image = #imageLiteral(resourceName: "Nathan-Tannar")
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
    }
    
    func loadUserContactsListModel(_ contactsModel: UserContactsListModel) {
        self.model = contactsModel
        localName.text = contactsModel.localName
        //userIdLabel.text = contactsModel.userId
    }
}
