import UIKit
import JupiterSDK

class SpotTableViewCell: UITableViewCell {
    
    static let identifier = "SpotTableViewCell"
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var ccsLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func updateResult(data: Spot) {
        print("Update Result : \(data)")
        let locationString: String = "\(data.building_name)_\(data.level_name)"
        self.locationLabel.text = locationString
        self.nameLabel.text = data.spot_name
        
        var typeName: String = ""
        switch(data.structure_feature_id) {
        case 1:
            typeName = "계단"
        case 2:
            typeName = "엘리베이터"
        case 3:
            typeName = "에스컬레이터"
        case 4:
            typeName = "사무공간"
        case 5:
            typeName = "회의실"
        case 6:
            typeName = "출입구"
        case 7:
            typeName = "탕비실"
        case 8:
            typeName = "프린터"
        case 9:
            typeName = "화장실"
        default:
            typeName = "Unvalid"
        }
        
        self.typeLabel.text = typeName
        self.ccsLabel.text = String(format: "%.4f", data.ccs)
    }
}
