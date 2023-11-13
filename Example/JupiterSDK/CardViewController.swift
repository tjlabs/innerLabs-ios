import UIKit
import Kingfisher
import JupiterSDK

class CardViewController: UIViewController, ServiceViewPageDelegate, FusionViewPageDelegate, GalleryViewPageDelegate, AddCardDelegate, ShowCardDelegate {
    
    func sendCardItemData(data: [CardItemData]) {
        cardItemData = data
    }
    
    func sendPage(data: Int) {
        currentPage = data
        currentIndex = CGFloat(data)
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var loginInfoButton: UIButton!
    @IBOutlet weak var privacyPolicyButton: UIButton!
    
    var region: String = ""
    var uuid: String = ""
    var cardItemData: [CardItemData] = []
    var cardImages: [UIImage] = []
    var sectorImages: [UIImage] = []
    var cardSize: [Double]?
    var collectionViewSize: [Double] = [0, 0]
    
    @IBOutlet weak var blackView: UIView!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var menuViewWidth: NSLayoutConstraint!
    @IBOutlet weak var menuViewRight: NSLayoutConstraint!
    
    @IBOutlet weak var showCardButton: UIButton!
    @IBOutlet weak var addCardButton: UIButton!
    
    var isMenuOpened: Bool = false
    
    // Card
    var currentIndex: CGFloat = 0
    let lineSpacing: CGFloat = 0
    
    var currentPage: Int = 0
    var previousIndex: Int = 0
    
    // Default : 0.7
    let cellWidthRatio: CGFloat = 0.8
    let cellheightRatio: CGFloat = 0.9
    
    var isOneStepPaging = true
    var isCardSmall = true
    
    let serviceManager = ServiceManager()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        initCardVC()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        serviceManager.changeRegion(regionName: self.region)
        changeButtonNameByRegion(region: self.region)
//        serviceManager.startService(id: self.uuid, sector_id: 10, service: "CLD", mode: "pdr")
        
        blackView.backgroundColor = UIColor.black
        blackView.alpha = 0
        blackView.isHidden = true
        
        menuViewRight.constant = -menuViewRight.constant
        menuView.isHidden = true
        
        blackView.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(self.tappedOnView))
        blackView.addGestureRecognizer(tapRecognizer)
        
        
//        print("(innerLabs) Region : \(self.region)")
    }
    
    @objc func tappedOnView(_ sender:UITapGestureRecognizer) {
        switch sender.state {
        case .began:
            break
        case .changed:
            break
        case .ended:
            if isMenuOpened {
                hideMenu() {
                    
                }
                isMenuOpened = false
            }
            else {
                openMenu()
                isMenuOpened = true
            }
            break
        default:
            print("default")
        }
        
    }
    
    func openMenu() {
        menuViewRight.constant = 0
            
        menuView.isHidden = false
        blackView.isHidden = false
        
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
                self.blackView.alpha = 0.5
            }, completion: { (complete) in
            })
        }
        
    func hideMenu(completionHandler: @escaping () -> Void) {
        menuViewRight.constant = -menuViewRight.constant

        UIView.animate(withDuration: 0.1, animations: {
                self.view.layoutIfNeeded()
                self.blackView.alpha = 0
            }, completion: { (complete) in
                self.blackView.isHidden = true
                self.menuView.isHidden = true
                completionHandler()
            })
    }
    
    func initCardVC() {
        setData(data: cardItemData)
        
        collectionViewSize = [collectionView.frame.width, collectionView.frame.height]
        
//        let sizes = checkImageSize(cards: cardImages, sectors: sectorImages)
//        print("Card -> Size of CollectionView : \(collectionViewSize)")
//        print("Card -> Size of Card : \(sizes.sizeCard)")
//        print("Card -> Size of Sector : \(sizes.sizeSector)")
        
        setupCollectionView()
        setupProgressView()
        
        if (currentPage == 0) {
            currentPage = getInitSectionFisrtCardIndex()
            currentIndex = CGFloat(currentPage)
            moveToInitSectionFirstCard()
        } else {
            moveToIndexCard(index: currentPage)
        }
    }
    
    func checkImageSize(cards: Array<UIImage>, sectors: Array<UIImage>) -> (sizeCard: Array<Double>, sizeSector: Array<Double>) {
        let cardImage = cards[0]
        let sectorImage = sectors[0]
        
        let sizeCard: [Double] = [cardImage.size.width, cardImage.size.height]
        let sizeSector: [Double] = [sectorImage.size.width, sectorImage.size.height]
        
        return (sizeCard, sizeSector)
    }
    
    func setData(data: Array<CardItemData>) {
        cardImages = []
        sectorImages = []
        for i in 0..<data.count {
            let imageName: String = data[i].cardColor + "Card"
            if let cardImage = UIImage(named: imageName) {
                cardImages.append(cardImage)
            } else {
                let defaultColor: String = "purpleCard"
                cardImages.append(UIImage(named: defaultColor)!)
            }
            
            let id = data[i].sector_id
            var sectorImage = UIImage(named: "sectorDefault")!
            
            switch(id) {
            case 0:
                sectorImage = UIImage(named: "sectorDefault")!
                sectorImages.append(sectorImage)
            default:
                sectorImage = UIImage(named: "sectorDefault")!
                sectorImages.append(sectorImage)
            }
        }
    }
    
    func moveToInitSectionFirstCard() {
        let firstCard = getInitSectionFisrtCardIndex()
        collectionView.scrollToItem(at: IndexPath(item: firstCard, section: 0), at: .centeredHorizontally, animated: false)
    }
    
    func moveToInitSectionLastCard() {
        let lastCard = getInitSectionLastCardIndex()
        collectionView.scrollToItem(at: IndexPath(item: lastCard, section: 0), at: .centeredHorizontally, animated: false)
    }
    
    func moveToIndexCard(index: Int) {
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: false)
    }
    
    func getInitSectionFisrtCardIndex() -> Int {
        let cardCount = cardItemData.count
        let section = (9-1)/2
        let firstCard = cardCount*section
        
        return firstCard
    }
    
    func getInitSectionLastCardIndex() -> Int {
        let cardCount = cardItemData.count
        let section = (9-1)/2
        let lastCard = (cardCount*section) + (cardCount-1)
        
        return lastCard
    }
    
    override func viewDidLayoutSubviews() {
        moveToInitSectionFirstCard()
    }
    
    public func setupProgressView() {
        self.progressView.clipsToBounds = true
        self.progressView.progress = 0.0
        self.progressView.layer.cornerRadius = 3.0
        
        let cardCount = cardItemData.count
        let progress: Float = 1/Float(cardCount)
        self.progressView.setProgress(progress, animated: true)
    }
    
    // 수정 필요
    public func getProgressValue(currentPage: Int) -> Float {
        var progressValue: Float = 0.0
        let cardCount = cardItemData.count
        var modPage = (currentPage+1)%cardCount
        if (modPage == 0) {
            modPage = cardItemData.count
        }
        progressValue = Float(modPage)/Float(cardItemData.count)

        return progressValue
    }
    
    public func setupCollectionView() {
        // width, height 설정
        let cellWidth = floor(collectionView.frame.width * cellWidthRatio)
        let cellHeight = floor(collectionView.frame.height * cellheightRatio)
        
        // 상하, 좌우 inset value 설정
        let insetX = (collectionView.bounds.width - cellWidth) / 2.0
        let insetY = (collectionView.bounds.height - cellHeight) / 2.0
        
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        layout.minimumLineSpacing = lineSpacing
        layout.scrollDirection = .horizontal
        collectionView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(UINib(nibName: "CardCollectionViewCell", bundle: .main), forCellWithReuseIdentifier: "CardCollectionViewCell")
        self.collectionView.reloadData()
        
        // 스크롤 시 빠르게 감속 되도록 설정
        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
    }
    
    
    @IBAction func tapShowUserInfoButton(_ sender: UIButton) {
        if isMenuOpened {
            hideMenu() {
                
            }
            isMenuOpened = false
        }
        else {
            openMenu()
            isMenuOpened = true
        }
    }
    
    func changeButtonNameByRegion(region: String) {
        var loginInfoTitle: String = "로그인 정보"
        var privacyPolicyTitle: String = "개인정보처리방침"
        switch (region) {
        case "Korea":
            loginInfoTitle = "로그인 정보"
            privacyPolicyTitle = "개인정보처리방침"
            self.showCardButton.setImage(UIImage(named: "showCard.png"), for: .normal)
            self.addCardButton.setImage(UIImage(named: "addCard.png"), for: .normal)
        case "Canada":
            loginInfoTitle = "Login Info"
            privacyPolicyTitle = "Privacy Policy"
            self.showCardButton.setImage(UIImage(named: "showCardEng.png"), for: .normal)
            self.addCardButton.setImage(UIImage(named: "addCardEng.png"), for: .normal)
        default:
            loginInfoTitle = "Login Info"
            privacyPolicyTitle = "Privacy Policy"
            self.showCardButton.setImage(UIImage(named: "showCardEng.png"), for: .normal)
            self.addCardButton.setImage(UIImage(named: "addCardEng.png"), for: .normal)
        }
        self.loginInfoButton.setTitle(loginInfoTitle, for: .normal)
        self.privacyPolicyButton.setTitle(privacyPolicyTitle, for: .normal)
    }
    
    @IBAction func tapLoginInfoButton(_ sender: UIButton) {
        var popUpTitle: String = "로그인 정보"
        switch (self.region) {
        case "Korea":
            popUpTitle = "로그인 정보"
        case "Canada":
            popUpTitle = "Login Information"
        default:
            popUpTitle = "Login Information"
            
        }
        showPopUp(title: popUpTitle, message: self.uuid)
    }
    
    
    @IBAction func tapShowPrivacyPolicy(_ sender: UIButton) {
        showPPVC()
    }
    
    func showPPVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PrivacyPolicyViewController") as! PrivacyPolicyViewController
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .coverVertical
        self.present(vc, animated: true, completion: nil)
    }
    
    
    @IBAction func tapShowCardButton(_ sender: UIButton) {
        guard let showCardVC = self.storyboard?.instantiateViewController(withIdentifier: "ShowCardViewController") as? ShowCardViewController else { return }
        showCardVC.modalPresentationStyle = .currentContext
        
        showCardVC.uuid = self.uuid
        showCardVC.cardItemData = self.cardItemData
        showCardVC.page = self.currentPage
        showCardVC.delegate = self
        
        self.present(showCardVC, animated: true, completion: nil)
    }
    
    
    @IBAction func tapAddCardButton(_ sender: UIButton) {
        guard let addCardVC = self.storyboard?.instantiateViewController(withIdentifier: "AddCardViewController") as? AddCardViewController else { return }
        addCardVC.modalPresentationStyle = .currentContext
        
        addCardVC.uuid = uuid
        addCardVC.cardItemData = self.cardItemData
        addCardVC.page = self.currentPage
        addCardVC.delegate = self
        
        self.present(addCardVC, animated: true, completion: nil)
    }
    
    @IBAction func tapLogoutButton(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
}

extension CardViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cardItemData.count * 9
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cardCount = cardItemData.count
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCollectionViewCell", for: indexPath) as! CardCollectionViewCell
        let mod = indexPath.item%cardCount
        
        // Sector Name & Description
        let sectorID: Int = cardItemData[mod].sector_id
        cell.sectorName.text = cardItemData[mod].sector_name
        cell.sectorDescription.text = cardItemData[mod].description
        
        // Sector 7
        if (sectorID == 7) {
            cell.sectorName.textColor = .black
            cell.sectorDescription.textColor = .black
        } else {
            cell.sectorName.textColor = .white
            cell.sectorDescription.textColor = .white
        }
        
        // Sector Image
        cell.cardImageView.contentMode = .scaleAspectFit
        cell.cardImageView.image = cardImages[mod]
        
//        cell.sectorNameLeading.constant = floor((cell.sectorImageView.frame.size.width - cell.sectorImageView.frame.size.height * 0.6)/2)
        
        if (sectorID == 0) {
            cell.sectorImageView.image = sectorImages[mod]
        } else if (sectorID == 10) {
            cell.sectorImageView.image = nil
        }
        else {
            let urlSector = URL(string: "https://storage.googleapis.com/\(IMAGE_URL)/card/\(sectorID)/main_image.png")
//            let resourceSector = ImageResource(downloadURL: urlSector!, cacheKey: "\(sectorID)Main")
            cell.sectorImageView.kf.setImage(with: urlSector!, placeholder: nil, options: [.transition(.fade(1.2))], completionHandler: nil)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cardCount = cardItemData.count
        let mod = indexPath.item%cardCount
        
        let sector_id = cardItemData[mod].sector_id
        let serviceName = cardItemData[mod].service
//        serviceManager.stopService()
        
        let region: String = self.region
        switch (region) {
        case "Korea":
            if (sector_id == 0) {
                guard let guideVC = self.storyboard?.instantiateViewController(withIdentifier: "GuideViewController") as? GuideViewController else { return }
                guideVC.page = currentPage
                self.navigationController?.pushViewController(guideVC, animated: true)
            } else if (sector_id == 1) {
//                guard let fusionVC = self.storyboard?.instantiateViewController(withIdentifier: "FusionViewController") as? FusionViewController else { return }
//                fusionVC.cardData = cardItemData[mod]
//                fusionVC.region = region
//                fusionVC.uuid = uuid
//                fusionVC.page = currentPage
//                self.navigationController?.pushViewController(fusionVC, animated: true)
                guard let serviceVC = self.storyboard?.instantiateViewController(withIdentifier: "ServiceViewController") as? ServiceViewController else { return }
                serviceVC.cardData = cardItemData[mod]
                serviceVC.region = region
                serviceVC.uuid = uuid
                serviceVC.page = currentPage
                self.navigationController?.pushViewController(serviceVC, animated: true)
            }
            else if (sector_id == 10) {
                guard let collectVC = self.storyboard?.instantiateViewController(withIdentifier: "CollectViewController") as? CollectViewController else { return }
                collectVC.cardData = cardItemData[mod]
                collectVC.userId = uuid
                collectVC.page = currentPage
                self.navigationController?.pushViewController(collectVC, animated: true)
            } else if (sector_id == 7) {
                guard let galleryVC = self.storyboard?.instantiateViewController(withIdentifier: "GalleryViewController") as? GalleryViewController else { return }
                galleryVC.cardData = cardItemData[mod]
                galleryVC.uuid = uuid
                galleryVC.page = currentPage
                self.navigationController?.pushViewController(galleryVC, animated: true)
            } else if (sector_id == 8) {
                guard let spotVC = self.storyboard?.instantiateViewController(withIdentifier: "SpotViewController") as? SpotViewController else { return }
                spotVC.cardData = cardItemData[mod]
                spotVC.region = region
                spotVC.userId = uuid
                spotVC.page = currentPage
                self.navigationController?.pushViewController(spotVC, animated: true)
            } else if (serviceName == "OSA") {
               guard let neptuneVC = self.storyboard?.instantiateViewController(withIdentifier: "NeptuneViewController") as? NeptuneViewController else { return }
                neptuneVC.cardData = cardItemData[mod]
                neptuneVC.region = region
                neptuneVC.userId = uuid
                neptuneVC.page = currentPage
                self.navigationController?.pushViewController(neptuneVC, animated: true)
            } else if (sector_id == 14) {
                guard let neptuneVC = self.storyboard?.instantiateViewController(withIdentifier: "NeptuneViewController") as? NeptuneViewController else { return }
                neptuneVC.cardData = cardItemData[mod]
                neptuneVC.region = region
                neptuneVC.userId = uuid
                neptuneVC.page = currentPage
                self.navigationController?.pushViewController(neptuneVC, animated: true)
            } else if (sector_id == 5) { //serviceName == "FLT+"
//                guard let fusionVC = self.storyboard?.instantiateViewController(withIdentifier: "FusionViewController") as? FusionViewController else { return }
//                fusionVC.cardData = cardItemData[mod]
//                fusionVC.region = region
//                fusionVC.uuid = uuid
//                fusionVC.page = currentPage
//                self.navigationController?.pushViewController(fusionVC, animated: true)
                
                guard let serviceVC = self.storyboard?.instantiateViewController(withIdentifier: "ServiceViewController") as? ServiceViewController else { return }
                serviceVC.cardData = cardItemData[mod]
                serviceVC.region = region
                serviceVC.uuid = uuid
                serviceVC.page = currentPage
                self.navigationController?.pushViewController(serviceVC, animated: true)
            } else {
                guard let serviceVC = self.storyboard?.instantiateViewController(withIdentifier: "ServiceViewController") as? ServiceViewController else { return }
                serviceVC.cardData = cardItemData[mod]
                serviceVC.region = region
                serviceVC.uuid = uuid
                serviceVC.page = currentPage
                self.navigationController?.pushViewController(serviceVC, animated: true)
//                guard let serviceVC = self.storyboard?.instantiateViewController(withIdentifier: "SampleViewController") as? SampleViewController else { return }
//                serviceVC.cardData = cardItemData[mod]
//                serviceVC.region = region
//                serviceVC.uuid = uuid
//                serviceVC.page = currentPage
//                self.navigationController?.pushViewController(serviceVC, animated: true)
            }
        case "Canada":
            if (sector_id == 0) {
                guard let guideVC = self.storyboard?.instantiateViewController(withIdentifier: "GuideViewController") as? GuideViewController else { return }
                guideVC.page = currentPage
                self.navigationController?.pushViewController(guideVC, animated: true)
            } else if (sector_id == 10) {
                guard let collectVC = self.storyboard?.instantiateViewController(withIdentifier: "CollectViewController") as? CollectViewController else { return }
                collectVC.cardData = cardItemData[mod]
                collectVC.userId = uuid
                collectVC.page = currentPage
                self.navigationController?.pushViewController(collectVC, animated: true)
            } else if (serviceName == "FLT+") {
                guard let fusionVC = self.storyboard?.instantiateViewController(withIdentifier: "FusionViewController") as? FusionViewController else { return }
                fusionVC.cardData = cardItemData[mod]
                fusionVC.region = region
                fusionVC.uuid = uuid
                fusionVC.page = currentPage
                self.navigationController?.pushViewController(fusionVC, animated: true)
            } else if (serviceName == "OSA") {
                guard let neptuneVC = self.storyboard?.instantiateViewController(withIdentifier: "NeptuneViewController") as? NeptuneViewController else { return }
                 neptuneVC.cardData = cardItemData[mod]
                 neptuneVC.region = region
                 neptuneVC.userId = uuid
                 neptuneVC.page = currentPage
                 self.navigationController?.pushViewController(neptuneVC, animated: true)
            } else {
                guard let serviceVC = self.storyboard?.instantiateViewController(withIdentifier: "ServiceViewController") as? ServiceViewController else { return }
                serviceVC.cardData = cardItemData[mod]
                print("Leo : card = \(cardItemData[mod])")
                serviceVC.region = region
                serviceVC.uuid = uuid
                serviceVC.page = currentPage
                self.navigationController?.pushViewController(serviceVC, animated: true)
            }
        default:
            if (sector_id == 0) {
                guard let guideVC = self.storyboard?.instantiateViewController(withIdentifier: "GuideViewController") as? GuideViewController else { return }
                guideVC.page = currentPage
                self.navigationController?.pushViewController(guideVC, animated: true)
            } else if (sector_id == 1) {
                guard let fusionVC = self.storyboard?.instantiateViewController(withIdentifier: "FusionViewController") as? FusionViewController else { return }
                fusionVC.cardData = cardItemData[mod]
                fusionVC.region = region
                fusionVC.uuid = uuid
                fusionVC.page = currentPage
                self.navigationController?.pushViewController(fusionVC, animated: true)
            }
            else if (sector_id == 10) {
                guard let collectVC = self.storyboard?.instantiateViewController(withIdentifier: "CollectViewController") as? CollectViewController else { return }
                collectVC.cardData = cardItemData[mod]
                collectVC.userId = uuid
                collectVC.page = currentPage
                self.navigationController?.pushViewController(collectVC, animated: true)
            } else if (sector_id == 7) {
                guard let galleryVC = self.storyboard?.instantiateViewController(withIdentifier: "GalleryViewController") as? GalleryViewController else { return }
                galleryVC.cardData = cardItemData[mod]
                galleryVC.uuid = uuid
                galleryVC.page = currentPage
                self.navigationController?.pushViewController(galleryVC, animated: true)
            } else if (sector_id == 8) {
                guard let spotVC = self.storyboard?.instantiateViewController(withIdentifier: "SpotViewController") as? SpotViewController else { return }
                spotVC.cardData = cardItemData[mod]
                spotVC.region = region
                spotVC.userId = uuid
                spotVC.page = currentPage
                self.navigationController?.pushViewController(spotVC, animated: true)
            } else if (serviceName == "OSA") {
               guard let neptuneVC = self.storyboard?.instantiateViewController(withIdentifier: "NeptuneViewController") as? NeptuneViewController else { return }
                neptuneVC.cardData = cardItemData[mod]
                neptuneVC.region = region
                neptuneVC.userId = uuid
                neptuneVC.page = currentPage
                self.navigationController?.pushViewController(neptuneVC, animated: true)
            } else if (sector_id == 14) {
                guard let neptuneVC = self.storyboard?.instantiateViewController(withIdentifier: "NeptuneViewController") as? NeptuneViewController else { return }
                neptuneVC.cardData = cardItemData[mod]
                neptuneVC.region = region
                neptuneVC.userId = uuid
                neptuneVC.page = currentPage
                self.navigationController?.pushViewController(neptuneVC, animated: true)
            } else if (serviceName == "FLT+") {
                guard let fusionVC = self.storyboard?.instantiateViewController(withIdentifier: "FusionViewController") as? FusionViewController else { return }
                fusionVC.cardData = cardItemData[mod]
                fusionVC.region = region
                fusionVC.uuid = uuid
                fusionVC.page = currentPage
                self.navigationController?.pushViewController(fusionVC, animated: true)
            } else {
                guard let serviceVC = self.storyboard?.instantiateViewController(withIdentifier: "ServiceViewController") as? ServiceViewController else { return }
                serviceVC.cardData = cardItemData[mod]
                serviceVC.region = region
                serviceVC.uuid = uuid
                serviceVC.page = currentPage
                self.navigationController?.pushViewController(serviceVC, animated: true)
            }
        }
    }
    
}

extension CardViewController : UIScrollViewDelegate {
    
    // 사용자가 스크롤하고 스크린과 손이 떨어졌을 경우
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        // item의 사이즈와 item 간의 간격 사이즈를 구해서 하나의 item 크기로 설정.
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let cellWidthIncludingSpacing = layout.itemSize.width + layout.minimumLineSpacing
        
        // targetContentOff을 이용하여 x좌표가 얼마나 이동했는지 확인
        // 이동한 x좌표 값과 item의 크기를 비교하여 몇 페이징이 될 것인지 값 설정
        var offset = targetContentOffset.pointee
        let index = (offset.x + scrollView.contentInset.left) / cellWidthIncludingSpacing
        var roundedIndex = round(index)
        
        // scrollView, targetContentOffset의 좌표 값으로 스크롤 방향을 알 수 있다.
        // index를 반올림하여 사용하면 item의 절반 사이즈만큼 스크롤을 해야 페이징이 된다.
        // 스크롤로 방향을 체크하여 올림,내림을 사용하면 좀 더 자연스러운 페이징 효과를 낼 수 있다.
        if scrollView.contentOffset.x > targetContentOffset.pointee.x {
            roundedIndex = floor(index)
        } else if scrollView.contentOffset.x < targetContentOffset.pointee.x {
            roundedIndex = ceil(index)
        } else {
            roundedIndex = round(index)
        }
        
        if isOneStepPaging {
            if currentIndex > roundedIndex {
                currentIndex -= 1
                roundedIndex = currentIndex
            } else if currentIndex < roundedIndex {
                currentIndex += 1
                roundedIndex = currentIndex
            }
        }
        
        // 위 코드를 통해 페이징 될 좌표값을 targetContentOffset에 대입하면 된다.
        offset = CGPoint(x: roundedIndex * cellWidthIncludingSpacing - scrollView.contentInset.left, y: -scrollView.contentInset.top)
        targetContentOffset.pointee = offset
        
//        print("Current Index : \(currentIndex)")
        currentPage = Int(roundedIndex)
//        print("Current Page: \(currentPage)")
        
        // ProgressBar
        let progress = getProgressValue(currentPage: currentPage)
        UIView.animate(withDuration: 0.5) {
            self.progressView.setProgress(progress, animated: true)
        }
    }
    
    func animateZoomforCell(zoomCell: UICollectionViewCell) {
        UIView.animate( withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: { zoomCell.transform = .identity }, completion: nil)
    }
    
    func animateZoomforCellremove(zoomCell: UICollectionViewCell) {
        UIView.animate( withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: { zoomCell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8) }, completion: nil)
        
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        
        let cellWidth = floor(collectionView.frame.width * cellWidthRatio)
        
        let cellWidthIncludeSpacing = cellWidth + layout.minimumLineSpacing
        
        let offsetX = collectionView.contentOffset.x
        let index = (offsetX + collectionView.contentInset.left) / cellWidthIncludeSpacing
        let roundedIndex = round(index)
        let indexPath = IndexPath(item: Int(roundedIndex), section: 0)
        
//        print("indexPath :", indexPath)
        
//        print("roundedIndex : \(roundedIndex)")
//        print("previousIndex : \(previousIndex)")
        
        if let cell = collectionView.cellForItem(at: indexPath) {
//            print("This Cell will be Original Size :", indexPath)
//            animateZoomforCell(zoomCell: cell)
        }
        if Int(roundedIndex) != previousIndex {
            let preIndexPath = IndexPath(item: previousIndex, section: 0)
            if let preCell = collectionView.cellForItem(at: preIndexPath)
            {
//                print("This Cell will be Smaller Size :", preIndexPath)
//                animateZoomforCellremove(zoomCell: preCell)
                
            }
            previousIndex = indexPath.item
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if currentPage == 0 {
            moveToInitSectionFirstCard()
            let index = getInitSectionFisrtCardIndex()
            currentIndex = CGFloat(index)
            previousIndex = index+1
        } else if currentPage == (cardItemData.count*9)-1 {
            moveToInitSectionLastCard()
            let index = getInitSectionLastCardIndex()
            currentIndex = CGFloat(index)
            previousIndex = index-1
        }
    }
}


