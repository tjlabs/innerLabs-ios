import UIKit
import JupiterSDK

protocol ShowCardDelegate {
    func sendCardItemData(data: [CardItemData])
}

class ShowCardViewController: UIViewController, AddCardDelegate {
    
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var showCardCollectionView: UICollectionView!
    
    var isEditMode: Bool = false
    var cardShowImages: [UIImage] = []
    var sectorShowImages: [UIImage] = []
    
    var cardSize: [Double]?
    var collectionViewSize: [Double] = [0, 0]
    
    var isCardSmall = true
    
    func sendCardItemData(data: [CardItemData]) {
        cardItemData = data
    }
    
    var cardItemData: [CardItemData] = []
    
    var delegate : ShowCardDelegate?
    
    
    //test
//    let collectionView: UICollectionView = {
//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .vertical
//        let collection = UICollectionView(frame: CGRect(x: 50, y: 50, width: UIScreen.main.bounds.width-100, height: UIScreen.main.bounds.height-100), collectionViewLayout: layout)
////        let collection = UICollectionView(frame: CGRect(x: 0, y: 0, width: 390, height: 633), collectionViewLayout: layout)
//        return collection
//    }()
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        initShowCardVC()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func initShowCardVC() {
        setData(data: cardItemData)
        
        // Size 확인
        let sizes = checkImageSize(cards: cardShowImages, sectors: sectorShowImages)
        collectionViewSize = [showCardCollectionView.bounds.width, showCardCollectionView.bounds.height]
        
        print("Size of CollectionView : \(collectionViewSize)")
        print("Size of Card : \(sizes.sizeCard)")
        print("Size of Sector : \(sizes.sizeSector)")
        isCardSmall = checkRatio(collectionViewSize: collectionViewSize, sizeCard: sizes.sizeCard)
        
        setupCollectionView()
    }
    
    func setData(data: Array<CardItemData>) {
        cardShowImages = []
        sectorShowImages = []
        for i in 0..<data.count {
            let cardImage = UIImage(named: data[i].cardShowImage)!
            cardShowImages.append(cardImage)
            
            let sectorImage = UIImage(named: data[i].sectorShowImage)!
            sectorShowImages.append(sectorImage)
        }
    }
    
    public func setupCollectionView() {
        view.addSubview(showCardCollectionView)
        
        showCardCollectionView.register(UINib(nibName: "ShowCardCollectionViewCell", bundle: .main), forCellWithReuseIdentifier: "ShowCardCollectionViewCell")
        
        showCardCollectionView.dataSource = self
        showCardCollectionView.delegate = self
        
        self.showCardCollectionView.reloadData()
        showCardCollectionView.decelerationRate = UIScrollView.DecelerationRate.fast
    }
    
    func checkImageSize(cards: Array<UIImage>, sectors: Array<UIImage>) -> (sizeCard: Array<Double>, sizeSector: Array<Double>) {
        let cardImage = cards[0]
        let sectorImage = sectors[0]
        
        let sizeCard: [Double] = [cardImage.size.width, cardImage.size.height]
        let sizeSector: [Double] = [sectorImage.size.width, sectorImage.size.height]
        
        return (sizeCard, sizeSector)
    }
    
    func checkRatio(collectionViewSize: Array<Double>, sizeCard: Array<Double>) -> Bool {
        let collectionViewSizeHeight = collectionViewSize[1]
        
        let sizeCardHeight = sizeCard[1]
        
        if (collectionViewSizeHeight < sizeCardHeight) {
            // 카드가 더 크면
            return false
        } else {
            // 카드가 더 작으면
            return true
        }
    }
    
    @IBAction func tapToCardButton(_ sender: UIButton) {
        self.delegate?.sendCardItemData(data: cardItemData)
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
            self.showCardCollectionView.reloadData()
        }
        else {
            isEditMode = false
            print("여기는 모아보기 입니다")
            self.showCardCollectionView.reloadData()
        }
    }
}


extension ShowCardViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: collectionView.bounds.width-32, height: 48)
        return CGSize(width: collectionView.bounds.width-10, height: 80)
    }
}

extension ShowCardViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return cardItemData.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShowCardCollectionViewCell", for: indexPath) as! ShowCardCollectionViewCell
        
        let sectorName = cardItemData[indexPath.item].name
        let sectorID = cardItemData[indexPath.item].sectorID
        cell.nameLabel.text = sectorName
        
        let width = showCardCollectionView.bounds.width
        cell.cardShowImageWidth.constant = width
        
        cell.cardShowImage.image = cardShowImages[indexPath.item]
        cell.sectorShowImage.image = sectorShowImages[indexPath.item]
        
        if (isEditMode) {
            if (sectorID != 0) {
                cell.deleteButton.alpha = 1.0
                cell.deleteButton.isEnabled = true
                
                let shakeAnimation = CABasicAnimation(keyPath: "position")
                shakeAnimation.duration = 0.1
                shakeAnimation.repeatCount = 20
                shakeAnimation.autoreverses = true
                shakeAnimation.fromValue = NSValue(cgPoint: CGPoint(x: cell.cardShowImage.center.x - 5, y: cell.cardShowImage.center.y))
                shakeAnimation.toValue = NSValue(cgPoint: CGPoint(x: cell.cardShowImage.center.x + 5, y: cell.cardShowImage.center.y))
//                shakeAnimation.fromValue = NSValue(cgPoint: CGPoint(x: cell.cardShowImage.center.x, y: cell.cardShowImage.center.y - 5))
//                shakeAnimation.toValue = NSValue(cgPoint: CGPoint(x: cell.cardShowImage.center.x, y: cell.cardShowImage.center.y + 5))
                
//                shakeAnimation.fromValue = NSValue(cgPoint: CGPoint(x: cell.sectorShowImage.center.x - 5, y: cell.sectorShowImage.center.y))
//                shakeAnimation.toValue = NSValue(cgPoint: CGPoint(x: cell.sectorShowImage.center.x + 5, y: cell.sectorShowImage.center.y))
                
                cell.cardShowImage.layer.add(shakeAnimation, forKey: "position")
                
            }
        } else {
            cell.deleteButton.alpha = 0.0
            cell.deleteButton.isEnabled = false
        }
        
        cell.delete = {
            [unowned self] in
            // 내가 선택한 카드 삭제
            self.cardItemData.remove(at: indexPath.item)
            setData(data: cardItemData)
            
            // CollectionView Reload
            self.showCardCollectionView.reloadData()
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        print("Want to delete : \(indexPath.item)")
    }
}
