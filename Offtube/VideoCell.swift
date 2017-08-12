//
//  VideoCell.swift
//  Offtube
//
//  Created by Dirk Gerretz on 15.06.17.
//  Copyright © 2017 [code2 app];. All rights reserved.
//

import UIKit

class VideoCell: UITableViewCell {
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var videoDescription: UILabel!
    @IBOutlet weak var downloadStatus: UIButton!
    @IBOutlet weak var duration: UILabel!
}
