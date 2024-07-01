import UIKit

class CardCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var centerLabel: UILabel!
    @IBOutlet weak var cardImageView: UIImageView!
    @IBOutlet weak var sectorImageView: UIImageView!
    @IBOutlet weak var sectorName: UILabel!
    @IBOutlet weak var sectorDescription: UILabel!
    @IBOutlet weak var sectorImageWidth: NSLayoutConstraint!
    @IBOutlet weak var sectorImageFromTop: NSLayoutConstraint!
    @IBOutlet weak var sectorNameLeading: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        centerLabel.alpha = 0.0
    }
}
