import UIKit
import JupiterSDK

protocol ShowCardDelegate {
    func sendCardItemData(data: [CardItemData])
}

class ShowCardViewController: UIViewController {
    
    var cardItemData: [CardItemData] = []

    var delegate : ShowCardDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func tapToCardButton(_ sender: UIButton) {
        self.presentingViewController?.dismiss(animated: true)
    }
    
    
    @IBAction func tapAddCardButton(_ sender: UIButton) {
    }
    
}
