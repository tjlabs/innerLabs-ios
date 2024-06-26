import UIKit
import Kingfisher
import JupiterSDK

class ShowCardViewController: UIViewController, AddCardDelegate {
    func sendPage(data: Int) {
        page = data
    }
    
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var showCardCollectionView: UICollectionView!
    @IBOutlet weak var editLabel: UILabel!
    
    @IBOutlet weak var toCardButton: UIButton!
    @IBOutlet weak var addCardButton: UIButton!
    
    var longPressGesture: UILongPressGestureRecognizer?
    
    var isEditMode: Bool = false
    var cardShowImages: [UIImage] = []
    var sectorShowImages: [UIImage] = []
    
    var cardSize: [Double]?
    var collectionViewSize: [Double] = [0, 0]
    
    func sendCardItemData(data: [CardItemData]) {
        cardItemData = data
    }
    
    var uuid: String = ""
    var cardItemData: [CardItemData] = []
    
    var delegate : ShowCardDelegate?
    
    var page: Int = 0
    
    var currentRegion: String = ""
    var editText: String = ""
    var confirmText: String = ""
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longTap(_:)))
        showCardCollectionView.addGestureRecognizer(longPressGesture!)
        
        initShowCardVC()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let locale = Locale.current
        if let countryCode = locale.regionCode, countryCode == "KR" {
            self.currentRegion = "Korea"
        } else {
            self.currentRegion = "Canada"
            
        }
        self.setTextByRegion(region: self.currentRegion)
    }
    
    func setTextByRegion(region: String) {
        switch (region) {
        case "Korea":
            self.editText = "편집"
            self.confirmText = "완료"
            
            self.toCardButton.setImage(UIImage(named: "toCard.png"), for: .normal)
            self.addCardButton.setImage(UIImage(named: "addCard.png"), for: .normal)
        case "Canada":
            self.editText = "Edit"
            self.confirmText = "Confirm"
            
            self.toCardButton.setImage(UIImage(named: "toCardEng.png"), for: .normal)
            self.addCardButton.setImage(UIImage(named: "addCardEng.png"), for: .normal)
        default:
            self.editText = "Edit"
            self.confirmText = "Confirm"
            
            self.toCardButton.setImage(UIImage(named: "toCardEng.png"), for: .normal)
            self.addCardButton.setImage(UIImage(named: "addCardEng.png"), for: .normal)
        }
        
        self.editLabel.text = self.editText
    }
    
    func initShowCardVC() {
        setData(data: cardItemData)
        
        // Size 확인
        collectionViewSize = [showCardCollectionView.bounds.width, showCardCollectionView.bounds.height]
//        let sizes = checkImageSize(cards: cardShowImages, sectors: sectorShowImages)
//        print("Show Card -> Size of CollectionView : \(collectionViewSize)")
//        print("Show Card -> Size of Card : \(sizes.sizeCard)")
//        print("Show Card -> Size of Sector : \(sizes.sizeSector)")
        
        setupCollectionView()
    }
    
    func setData(data: Array<CardItemData>) {
        cardShowImages = []
        sectorShowImages = []
        for i in 0..<data.count {
            let imageName: String = data[i].cardColor + "CardShow"
            let cardImage = UIImage(named: imageName)!
            cardShowImages.append(cardImage)
            
            let id = data[i].sector_id
//            var sectorImage = UIImage(named: "tjlabsShow")!
            var sectorImage = UIImage(named: "tjlabsShow")!
            
            switch(id) {
            case 0:
                sectorImage = UIImage(named: "tjlabsShow")!
                sectorShowImages.append(sectorImage)
            case 10:
                sectorImage = UIImage(named: "tjlabsShow")!
                sectorShowImages.append(sectorImage)
            default:
                sectorImage = UIImage(named: "tjlabsShow")!
                sectorShowImages.append(sectorImage)
            }
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
    
    @objc func longTap(_ gesture: UIGestureRecognizer){
        switch(gesture.state) {
        case .began:
            guard let selectedIndexPath = showCardCollectionView.indexPathForItem(at: gesture.location(in: showCardCollectionView)) else {
                return
            }
            showCardCollectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            showCardCollectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case .ended:
            showCardCollectionView.endInteractiveMovement()
            self.showCardCollectionView.reloadData()
        default:
            showCardCollectionView.cancelInteractiveMovement()
        }
    }
    
    @IBAction func tapToCardButton(_ sender: UIButton) {
        self.delegate?.sendCardItemData(data: cardItemData)
        self.delegate?.sendPage(data: page)
        self.presentingViewController?.dismiss(animated: true)
    }
    
    
    @IBAction func tapAddCardButton(_ sender: UIButton) {
        // 바로 AddCard로 이동 //
        guard let addCardVC = self.storyboard?.instantiateViewController(withIdentifier: "AddCardViewController") as? AddCardViewController else { return }
        addCardVC.modalPresentationStyle = .currentContext
        
        addCardVC.uuid = self.uuid
        addCardVC.cardItemData = self.cardItemData
        addCardVC.page = self.page
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
            self.editLabel.text = self.confirmText
            self.editLabel.textColor = .systemBlue
            self.showCardCollectionView.reloadData()
        }
        else {
            isEditMode = false
            self.editLabel.text = self.editText
            self.editLabel.textColor = .systemGray
            self.showCardCollectionView.reloadData()
            
            // Save Card Order
            var order = [String: Int]()
            for i in 1..<cardItemData.count {
                let id: String = String(cardItemData[i].sector_id)
                let value: Int = i
                
                order[id] = value
            }
            
            let input = OrderCard(user_id: uuid, card_orders: order)
            Network.shared.orderCard(url: CARD_URL, input: input, completion: { statusCode, returnedString in
            })
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
        
        let sectorName: String = cardItemData[indexPath.item].sector_name
        let sectorID = cardItemData[indexPath.item].sector_id
        cell.nameLabel.text = sectorName
        
        if (IS_OLYMPUS) {
            if (sectorID == 9) {
                cell.nameLabel.textColor = .black
            } else {
                cell.nameLabel.textColor = .white
            }
            
            let ratio: Double = 8.05
            let width = collectionViewSize[0]
            cell.cardWidth.constant = collectionViewSize[0]
            cell.sectorShowImageLeading.constant = (width/ratio)
            
            cell.cardShowImage.image = cardShowImages[indexPath.item]
            
            if (sectorID == 0) {
                cell.sectorShowImage.image = sectorShowImages[indexPath.item]
            } else if (sectorID == 1) {
                cell.sectorShowImage.image = sectorShowImages[indexPath.item]
            } else {
                let urlSectorShow = URL(string: "\(USER_IMAGE_URL)/card/\(sectorID)/edit.png")
                cell.sectorShowImage.kf.setImage(with: urlSectorShow!, placeholder: nil, options: [.transition(.fade(1.2))], completionHandler: nil)
            }
            
            if (isEditMode) {
                if (sectorID != 0) {
                    cell.deleteButton.alpha = 1.0
                    cell.deleteButton.isEnabled = true
                    
                    cell.startAnimate()
                    
                } else {
                    cell.deleteButton.alpha = 0.0
                    cell.deleteButton.isEnabled = false
                    
                    cell.stopAnimate()
                }
            } else {
                cell.deleteButton.alpha = 0.0
                cell.deleteButton.isEnabled = false
            }
            
            cell.delete = {
                [unowned self] in
                // 내가 선택한 카드 삭제
                let uuid = self.uuid
                let sector_id = self.cardItemData[indexPath.item].sector_id
                
                let input = DeleteCard(user_id: uuid, sector_id: sector_id)
                Network.shared.deleteCard(url: USER_CARD_URL, input: input, completion: { [self] statusCode, returnedString in
                    self.cardItemData.remove(at: indexPath.item)
                    self.delegate?.sendCardItemData(data: self.cardItemData)
                    self.page = 0
                    
                    self.setData(data: cardItemData)
                    
                    // CollectionView Reload
                    self.showCardCollectionView.reloadData()
                })
            }
        } else {
            if (sectorID == 7) {
                cell.nameLabel.textColor = .black
            } else {
                cell.nameLabel.textColor = .white
            }
            
            let ratio: Double = 8.05
            let width = collectionViewSize[0]
            cell.cardWidth.constant = collectionViewSize[0]
            cell.sectorShowImageLeading.constant = (width/ratio)
            
            cell.cardShowImage.image = cardShowImages[indexPath.item]
            
            if (sectorID == 0) {
                cell.sectorShowImage.image = sectorShowImages[indexPath.item]
            } else if (sectorID == 10) {
                cell.sectorShowImage.image = sectorShowImages[indexPath.item]
            } else {
                let urlSectorShow = URL(string: "https://storage.googleapis.com/\(IMAGE_URL)/card/\(sectorID)/edit_image.png")
                cell.sectorShowImage.kf.setImage(with: urlSectorShow!, placeholder: nil, options: [.transition(.fade(1.2))], completionHandler: nil)
            }
            
            if (isEditMode) {
                if (sectorID != 0) {
                    cell.deleteButton.alpha = 1.0
                    cell.deleteButton.isEnabled = true
                    
                    cell.startAnimate()
                    
                } else {
                    cell.deleteButton.alpha = 0.0
                    cell.deleteButton.isEnabled = false
                    
                    cell.stopAnimate()
                }
            } else {
                cell.deleteButton.alpha = 0.0
                cell.deleteButton.isEnabled = false
            }
            
            cell.delete = {
                [unowned self] in
                // 내가 선택한 카드 삭제
                let uuid = self.uuid
                let sector_id = self.cardItemData[indexPath.item].sector_id
                
                let input = DeleteCard(user_id: uuid, sector_id: sector_id)
                Network.shared.deleteCard(url: USER_URL, input: input, completion: { [self] statusCode, returnedString in
                    self.cardItemData.remove(at: indexPath.item)
                    self.delegate?.sendCardItemData(data: self.cardItemData)
                    self.page = 0
                    
                    self.setData(data: cardItemData)
                    
                    // CollectionView Reload
                    self.showCardCollectionView.reloadData()
                })
            }
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //        print("Want to delete : \(indexPath.item)")
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//        print("Start index :- \(sourceIndexPath.item)")
//        print("End index :- \(destinationIndexPath.item)")
                
        let tmp = cardItemData[sourceIndexPath.item]
        cardItemData[sourceIndexPath.item] = cardItemData[destinationIndexPath.item]
        cardItemData[destinationIndexPath.item] = tmp
        
        setData(data: cardItemData)
                
        showCardCollectionView.reloadData()
    }
}
