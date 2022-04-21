import UIKit
import JupiterSDK

protocol ShowCardDelegate {
    func sendCardItemData(data: [CardItemData])
}

class ShowCardViewController: UIViewController, AddCardDelegate {
    
    @IBOutlet weak var editButton: UIButton!
    
    var isEditMode: Bool = false
    
    func sendCardItemData(data: [CardItemData]) {
        cardItemData = data
    }
    
    var cardItemData: [CardItemData] = []

    var delegate : ShowCardDelegate?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        print(cardItemData)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        print(cardItemData)
    }
    
    @IBAction func tapToCardButton(_ sender: UIButton) {
        self.presentingViewController?.dismiss(animated: true)
    }
    
    
    @IBAction func tapAddCardButton(_ sender: UIButton) {

        // CardView로 이동한 후에 AddCard로 이동 //
//        guard let presentingVC = self.presentingViewController else { return }
//
//        self.dismiss(animated: true) {
//            guard let addCardVC = self.storyboard?.instantiateViewController(withIdentifier: "AddCardViewController") as? AddCardViewController else { return }
//            addCardVC.modalPresentationStyle = .currentContext
//
//            addCardVC.cardItemData = self.cardItemData
//            addCardVC.delegate = self
//
//            presentingVC.present(addCardVC, animated: true, completion: nil)
//        }
        
        // 바로 AddCard로 이동 //
        guard let addCardVC = self.storyboard?.instantiateViewController(withIdentifier: "AddCardViewController") as? AddCardViewController else { return }
        addCardVC.modalPresentationStyle = .currentContext

        addCardVC.cardItemData = self.cardItemData
        addCardVC.delegate = self

        self.present(addCardVC, animated: true, completion: nil)
    }
    
    
    @IBAction func tapEditButton(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: {
        }) { (success) in
            sender.isSelected = !sender.isSelected
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: {
                sender.transform = .identity
            }, completion: nil)
        }
        
        if sender.isSelected == false {
            isEditMode = true
            print("여기는 EditMode 입니다")
        }
        else {
            isEditMode = false
            print("여기는 모아보기 입니다")
        }
    }
}
