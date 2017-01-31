//
//  PlayerView.swift
//  Pods
//
//  Created by Vadim Kononov on 13/11/2016.
//
//

import UIKit

/// A simple `UIView` subclass that is backed by an `AVPlayerLayer` layer.
class PlayerView: UIView {

    var playerLayer: CALayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(playerLayer: CALayer) {
        super.init(frame: CGRect.zero)
        self.playerLayer = playerLayer
        self.layer.addSublayer(self.playerLayer!)
    }
    
    override var frame: CGRect {
        didSet {
            self.playerLayer?.frame = CGRect(origin: CGPoint.zero, size: frame.size)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.playerLayer?.frame = CGRect(origin: CGPoint.zero, size: frame.size)
    }
}
