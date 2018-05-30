//
//  HighScoresTableViewCell.swift
//  AddingUp
//
//  Created by Daniel Jinks on 30/05/2018.
//  Copyright © 2018 Daniel Jinks. All rights reserved.
//

import UIKit

class HighScoresTableViewCell: UITableViewCell {

    @IBOutlet var arrows: [UIImageView]!
    @IBOutlet var medals: [UIImageView]!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    

}
