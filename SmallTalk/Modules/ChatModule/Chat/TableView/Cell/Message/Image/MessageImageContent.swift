//
//  MessageImageContent.swift
//  epam_messenger
//
//  Created by Nickolay Truhin on 22.03.2020.
//

import UIKit
import FirebaseStorage
import FirebaseUI
import TinyConstraints
import NYTPhotoViewer
import AVFoundation

class MessageImageContent: UIView, MessageCellContentProtocol {
    
    // MARK: - Outlets
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var infoStack: UIStackView!
    
    // MARK: - Vars
    
    lazy var loading = UIActivityIndicatorView(style: .large)

    var shouldSetupConstraints = true
    var superInsets: TinyEdgeInsets!
    
    var cell: MessageCellProtocol!
    var mergeContentNext: Bool!
    var mergeContentPrev: Bool!
    var kindIndex: Int!
    var imageMessage: MessageImageProtocol! {
        didSet {
            setupImage()
            setupStack()
        }
    }
    var message: MessageProtocol! {
        return imageMessage
    }
    
    var topMargin: CGFloat {
        return 0
    }
    
    var bottomMargin: CGFloat {
        return 0
    }
    
    private func setupImage() {
        let kindImage = imageMessage.kindImage(at: kindIndex)!
        let imageRef = Storage.storage().reference().child(kindImage.path)
        let size = AVMakeRect(
            aspectRatio: kindImage.size,
            insideRect: .init(x: 0, y: 0, width: 300, height: 300)
        ).size
        imageView.size(
            .init(
                width: max(size.width, 150),
                height: max(size.height, 150)
            )
        )
        didStartLoading()
        loadImage(with: imageRef)
    }
    
    private func didStartLoading() {
        imageView.addSubview(loading)
        loading.centerInSuperview()
        loading.startAnimating()
        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    private func didEndLoading() {
        imageView.backgroundColor = .clear
        loading.removeFromSuperview()
    }
    
    private func loadImage(
        with imageRef: StorageReference
    ) {
        imageView.sd_setSmallImage(
            with: imageRef
        ) { [weak self] image, err, _, _ in
            guard let self = self else { return }

            self.didEndLoading()
        }
    }
    
    private func setupStack() {
        infoStack.isHidden = mergeContentNext
        infoStack.addBackground(color: .chatRectLabelBackground, cornerRadius: infoStack.bounds.height / 2)
        timeLabel.textColor = .chatRectLabelText
    }
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("MessageImageContent", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    // MARK: - Methods
    
    func loadMessage(
        _ message: MessageProtocol,
        index: Int,
        cell: MessageCellProtocol,
        mergeContentNext: Bool,
        mergeContentPrev: Bool
    ) {
        self.kindIndex = index
        self.cell = cell
        self.mergeContentNext = mergeContentNext
        self.mergeContentPrev = mergeContentPrev
        self.imageMessage = message as? MessageImageProtocol
    }
    
    override func updateConstraints() {
        if shouldSetupConstraints {
            if let bubbleView = superview?.superview {
                if message.isIncoming {
                    left(to: bubbleView, offset: -messageTailsInset)
                    right(to: bubbleView, offset: messageTailsInset * 2)
                } else {
                    left(to: bubbleView, offset: -messageTailsInset * 2)
                    right(to: bubbleView, offset: messageTailsInset)
                }
                
                infoStack.right(to: bubbleView, offset: -(messageTailsInset + 6))
            }
            
            shouldSetupConstraints = false
        }
        super.updateConstraints()
    }
    
}

// MARK: Image darken helper

fileprivate extension UIImage {
    func darkened() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let ctx = UIGraphicsGetCurrentContext(), let cgImage = cgImage else {
            return nil
        }
        
        // flip the image, or result appears flipped
        ctx.scaleBy(x: 1.0, y: -1.0)
        ctx.translateBy(x: 0, y: -size.height)
        
        let rect = CGRect(origin: .zero, size: size)
        ctx.draw(cgImage, in: rect)
        UIColor(white: 0, alpha: 0.5).setFill()
        ctx.fill(rect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
