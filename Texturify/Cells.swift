//
//  Cells.swift
//  Texturify
//
//  Created by Brian Wang on 9/17/17.
//  Copyright © 2017 BW. All rights reserved.
//

import UIKit

class TextureCell: UITableViewCell {
    
    @IBOutlet weak var squareImageView: UIImageView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var textureLabel: UILabel!
    
    func reset() {
        squareImageView.image = nil
        backgroundImageView.image = nil
        textureLabel.text = ""
    }
}
