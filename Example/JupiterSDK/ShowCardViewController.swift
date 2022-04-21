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
    
    func sendCardItemData(data: [CardItemData]) {
        cardItemData = data
    }
    
    var cardItemData: [CardItemData] = []

    var delegate : ShowCardDelegate?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        setData(data: cardItemData)
//        print(cardItemData)
        print(cardShowImages)
        print(sectorShowImages)
        
        setupCollectionView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        print(cardItemData)
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
        // width, height 설정
        let cellWidth = floor(showCardCollectionView.frame.width * 0.9)
        let cellHeight = floor(showCardCollectionView.frame.height * 0.9)
        
        // 상하, 좌우 inset value 설정
        let insetX = (showCardCollectionView.bounds.width - cellWidth) / 2.0
        let insetY = (showCardCollectionView.bounds.height - cellHeight) / 2.0
        
        let layout = showCardCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        layout.minimumLineSpacing = 10
        layout.scrollDirection = .vertical
        showCardCollectionView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
        
        showCardCollectionView.delegate = self
        showCardCollectionView.dataSource = self
        
        showCardCollectionView.register(UINib(nibName: "ShowCardCollectionViewCell", bundle: .main), forCellWithReuseIdentifier: "ShowCardCollectionViewCell")
        self.showCardCollectionView.reloadData()
        
        // 스크롤 시 빠르게 감속 되도록 설정
        showCardCollectionView.decelerationRate = UIScrollView.DecelerationRate.fast
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

extension ShowCardViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cardItemData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cardCount = cardItemData.count
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShowCardCollectionViewCell", for: indexPath) as! ShowCardCollectionViewCell
        

        cell.showCardImage.image = cardShowImages[indexPath.row]
//        cell.sectorImageView.image = sectorShowImages[indexPath]
        
//        cell.cardImageView.image = cardImagesResized[mod]
//        cell.sectorImageView.image = sectorImagesResized[mod]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cardCount = cardItemData.count
    }
}
