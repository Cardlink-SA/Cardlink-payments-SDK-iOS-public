//
//  CardCell.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 2/12/22.
//

import UIKit

class CardCell: UITableViewCell {
    @IBOutlet weak var cardImage: UIImageView!
    @IBOutlet weak var cardType: UILabel!
    @IBOutlet weak var cardNumber: UILabel!
    @IBOutlet weak var checkImage: UIImageView!
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        contentView.backgroundColor = highlighted ? UIColor(hex: "#EEEEEE") : .white
    }
}
