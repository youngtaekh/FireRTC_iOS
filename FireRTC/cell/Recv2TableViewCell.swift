//
//  Recv2TableViewCell.swift
//  FireRTC
//
//  Created by young on 2023/10/10.
//

import UIKit

class Recv2TableViewCell: UITableViewCell {

    @IBOutlet weak var tvMessage: PaddingLabel!
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
