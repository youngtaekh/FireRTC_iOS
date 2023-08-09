//
//  DateTableViewCell.swift
//  FireRTC
//
//  Created by young on 2023/08/04.
//

import UIKit

class DateTableViewCell: UITableViewCell {

    @IBOutlet weak var tvDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
