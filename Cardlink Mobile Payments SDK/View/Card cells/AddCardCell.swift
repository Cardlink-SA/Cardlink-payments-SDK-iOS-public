//
//  AddCardCell.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 2/12/22.
//

import UIKit

class AddCardCell: UITableViewCell {
    @IBOutlet private var cellTextLabel: UILabel!
    
    override func awakeFromNib() {
        prepareLiterals()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        contentView.backgroundColor = highlighted ? UIColor(hex: "#EEEEEE") : .white
    }
}

private extension AddCardCell {
    func prepareLiterals() {
        cellTextLabel.text = NSLocalizedString("Use other card", comment: "")
    }
}
