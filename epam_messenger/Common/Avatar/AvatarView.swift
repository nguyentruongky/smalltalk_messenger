//
//  AvatarView.swift
//  epam_messenger
//
//  Created by Nickolay Truhin on 14.04.2020.
//

import UIKit
import FirebaseStorage
import FirebaseAuth

class AvatarView: UIImageView {
    
    // MARK: - Vars
    
    let loading = UIActivityIndicatorView()
    var placeholderLabel = UILabel()
    
    // MARK: - Init
    
    private func baseSetup(roundCorners: Bool = true) {
        contentMode = .scaleAspectFill
        layer.cornerRadius = roundCorners ? bounds.width / 2 : 0
        layer.masksToBounds = true
        placeholderLabel.removeFromSuperview()
        set(image: nil, focusOnFaces: true)
        backgroundColor = .clear
    }
    
    private func setupPlaceholder(_ text: String?, _ color: UIColor) {
        placeholderLabel.font = UIFont.systemFont(ofSize: bounds.height / 5 * 2, weight: .semibold)
        placeholderLabel.textColor = UIColor.lightText.withAlphaComponent(1)
        placeholderLabel.numberOfLines = 1
        placeholderLabel.textAlignment = .center
        placeholderLabel.lineBreakMode = .byClipping
        placeholderLabel.text = text?.uppercased()
        backgroundColor = color
        
        addSubview(placeholderLabel)
        placeholderLabel.edgesToSuperview()
    }
    
    override func awakeFromNib() {
        addSubview(loading)
        loading.centerInSuperview()
        loading.startAnimating()
    }
    
    func setup(withUser user: UserProtocol?) {
        if let user = user {
            if user.documentId == Auth.auth().currentUser!.uid {
                setupBookmark()
            } else {
                setup(
                    withRef: user.avatarRef,
                    text: user.placeholderName,
                    color: user.color ?? .accent
                )
            }
        } else {
            setup(withImage: #imageLiteral(resourceName: "ic_unknown_user"))
        }
    }
    
    func setup(withRef ref: StorageReference, text: String, color: UIColor, roundCorners: Bool = true) {
        baseSetup(roundCorners: roundCorners)
        
        sd_setSmallImage(with: ref) { [weak self] _, err, _, _ in
            guard let self = self else { return }
            self.loading.removeFromSuperview()
            
            if err != nil {
                self.setupPlaceholder(text, color)
            }
        }
    }
    
    func setup(withPlaceholder text: String? = nil, color: UIColor = .accent) {
        baseSetup()
        
        loading.removeFromSuperview()
        setupPlaceholder(text, color)
    }
    
    func setup(withImage image: UIImage? = nil) {
        baseSetup()
        
        loading.removeFromSuperview()
        set(image: image, focusOnFaces: true)
    }
    
    func setupBookmark() {
        baseSetup()
        contentMode = .center
        
        backgroundColor = .accent
        loading.removeFromSuperview()
        image = UIImage(systemName: "bookmark.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25))
        tintColor = .white
    }
    
}