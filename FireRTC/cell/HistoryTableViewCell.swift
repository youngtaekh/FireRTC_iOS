//
//  HistoryTableViewCell.swift
//  FireRTC
//
//  Created by young on 2023/08/03.
//

import UIKit

class HistoryTableViewCell: UITableViewCell {
    @IBOutlet weak var ivType: UIImageView!
    @IBOutlet weak var ivDirection: UIImageView!
    
    @IBOutlet weak var tvTitle: UILabel!
    @IBOutlet weak var tvTime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
