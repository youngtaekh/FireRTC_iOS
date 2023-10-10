//
//  RecvMessageCell.swift
//  FireRTC
//
//  Created by young on 2023/09/01.
//

import UIKit

class RecvMessageCell: UITableViewCell {
    @IBOutlet weak var tvMessage: UILabel!
    @IBOutlet weak var tvName: UILabel!
    @IBOutlet weak var tvTime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.tvMessage.clipsToBounds = true
        self.tvMessage.layer.cornerRadius = 15
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
