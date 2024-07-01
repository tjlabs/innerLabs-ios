import UIKit

class WardCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var wardView: UIView!
    @IBOutlet weak var wardIdLabel: UILabel!
    @IBOutlet weak var wardRssiLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
