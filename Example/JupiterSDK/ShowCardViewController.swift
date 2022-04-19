import UIKit
import JupiterSDK

protocol ShowCardDelegate {
    func sendCardItemData(data: [CardItemData])
}

class ShowCardViewController: UIViewController, AddCardDelegate {
    func sendCardItemData(data: [CardItemData]) {
        cardItemData = data
    }
    
    var cardItemData: [CardItemData] = []

    var delegate : ShowCardDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(cardItemData)
    }
    
    @IBAction func tapToCardButton(_ sender: UIButton) {
        self.presentingViewController?.dismiss(animated: true)
    }
    
    
    @IBAction func tapAddCardButton(_ sender: UIButton) {
        guard let presentingVC = self.presentingViewController else { return }

        self.dismiss(animated: false) {
            guard let addCardVC = self.storyboard?.instantiateViewController(withIdentifier: "AddCardViewController") as? AddCardViewController else { return }
            addCardVC.modalPresentationStyle = .currentContext
            
            addCardVC.cardItemData = self.cardItemData
            addCardVC.delegate = self
            
            presentingVC.present(addCardVC, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func tapEditButton(_ sender: UIButton) {
    }
    
}
