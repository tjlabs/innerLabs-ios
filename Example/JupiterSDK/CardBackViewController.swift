//
//  CardBackViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/04/26.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import JupiterSDK
import CoreLocation
import GoogleMaps
import SnapKit

protocol SendPageDelegate {
    func sendPage(data: Int)
}


class CardBackViewController: UIViewController {
    
    enum ContainerViewState {
        case expanded
        case normal
    }
    
    struct cellData {
        var opened = Bool()
        var title = String()
        var sectionData = [String]()
    }
    
    @IBOutlet weak var containerMapView: UIView!
    @IBOutlet weak var sectorNameLabel: UILabel!
    @IBOutlet weak var zoneCollectionView: UICollectionView!
    @IBOutlet weak var cardTopImage: UIImageView!
    @IBOutlet weak var containerOutputScrollView: UIScrollView!
    
    // Output
    @IBOutlet weak var stepCountTxLabel: UILabel!
    @IBOutlet weak var stepCountRxLabel: UILabel!
    @IBOutlet weak var mobileTypeLabel: UILabel!
    @IBOutlet weak var stepLengthLabel: UILabel!
    @IBOutlet weak var sccLabel: UILabel!
    @IBOutlet weak var mobileStatusLabel: UILabel!
    
    
    let sectionSpacing: Double = 40
    let firstSectionHeight: Double = 240
    let secondSectionHeight: Double = 220
    
    var isShow: Bool = false
    var isFirstOpen: Bool = false
    var isSecondOpen: Bool = false
    
    let lat: Double = 37.60044253771222
    let lon: Double = 127.04522864626479
    
    var delegate : SendPageDelegate?
    
    var cardData: CardItemData?
    var page: Int = 0
    
    // containerOutputView와 safe Area Top 사이의 최소값을 지정하기 위한 프로퍼티
    var containerOutputViewMinTopConstant: CGFloat = 400
    
    // 드래그 하기 전에 containerOutputView 의 top Constraint value를 저장하기 위한 프로퍼티
    private lazy var containerOutputViewPanStartingTopConstant: CGFloat = containerOutputViewMinTopConstant
    var defaultHeight: CGFloat = 200
    private var containerViewTopConstraint: NSLayoutConstraint!
    
    // Jupiter Service
    var jupiterService = JupiterService()
    var uuid: String = ""
    
    var timer = Timer()
    var timerCounter: Int = 0
    var timerTimeOut: Int = 10
    let TIMER_INTERVAL: TimeInterval = 1/40 // second
    
    var pastTime: Double = 0
    var elapsedTime: Double = 0
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        setCardData(cardData: cardData!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureMapView()
        configureContainerOutputView()
        setupLayout()
        
        // Pan Gesture Recognizer를 view controller의 view에 추가하기 위한 코드
        let viewPan = UIPanGestureRecognizer(target: self, action: #selector(viewPanned(_:)))
        // 기본적으로 iOS는 터치가 드래그하였을 때 딜레이가 발생함
        // 우리는 드래그 제스쳐가 바로 발생하길 원하기 때문에 딜레이가 없도록 아래와 같이 설정
        viewPan.delaysTouchesBegan = false
        viewPan.delaysTouchesEnded = false
        view.addGestureRecognizer(viewPan)
        
        showContainerOutputView(atState: .normal)
        setupCustomView()
        
        // Start Jupiter Service
        jupiterService.uuid = uuid
        jupiterService.startService(parent: self)
        startTimer()
    }
    
    @IBAction func tapShowOutputViewButton(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: {
        }) { (success) in
            sender.isSelected = !sender.isSelected
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: {
                sender.transform = .identity
            }, completion: nil)
        }
        
        if sender.isSelected == false {
            isShow = true
            showOutputView()
        }
        else {
            isShow = false
            hideOutputView()
        }
    }
    
    @IBAction func tapBackButton(_ sender: UIButton) {
        self.delegate?.sendPage(data: page)
        self.navigationController?.popViewController(animated: true)
    }
    
    func setCardData(cardData: CardItemData) {
        self.sectorNameLabel.text = cardData.name
        self.cardTopImage.image = UIImage(named: cardData.cardTopImage)!
    }
    
    func showOutputView() {
        containerViewTopConstraint.constant = containerOutputViewMinTopConstant
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func hideOutputView() {
        hideContainerOutputView()
    }
    
    func setupLayout() {
        let topConstant: CGFloat = defaultHeight
        
        containerViewTopConstraint = containerOutputScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topConstant)
        NSLayoutConstraint.activate([
            containerOutputScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            containerOutputScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            containerOutputScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerViewTopConstraint,
        ])
        
        view.addSubview(dragIndicatorView)
        dragIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dragIndicatorView.widthAnchor.constraint(equalToConstant: 60),
            dragIndicatorView.heightAnchor.constraint(equalToConstant: dragIndicatorView.layer.cornerRadius * 2),
            dragIndicatorView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            dragIndicatorView.bottomAnchor.constraint(equalTo: containerOutputScrollView.topAnchor, constant: -10)
        ])
    }
    
    
    func setupCustomView() {
        // OutputView
        let outputViewidentifier = String(describing: OutputView.self)
        guard let outputView = Bundle.main.loadNibNamed(outputViewidentifier, owner: self, options: nil)?.first as? OutputView else { return }
        outputView.frame = CGRect(x: 0, y: 0, width: containerOutputScrollView.bounds.width, height: containerOutputScrollView.bounds.height)
        
        outputView.stackViewHeight.constant = 0
        outputView.infoViewHeight.constant = 0
        containerOutputScrollView.addSubview(outputView)
        
        
        // RobotView
        let robotViewidentifier = String(describing: RobotView.self)
        guard let robotView = Bundle.main.loadNibNamed(robotViewidentifier, owner: self, options: nil)?.first as? RobotView else { return }
        robotView.frame = CGRect(x: 0, y: sectionSpacing, width: containerOutputScrollView.bounds.width, height: containerOutputScrollView.bounds.height)
        robotView.containerViewHeight.constant = 0
        containerOutputScrollView.addSubview(robotView)
        
        
        // Show & Hide Detail
        outputView.showDetail = {
            [unowned self] in
            var positionY: Double = 0
            positionY = sectionSpacing + firstSectionHeight
            
            var scrollHeight: Double = 0
            if (isSecondOpen) {
                scrollHeight = sectionSpacing + firstSectionHeight + sectionSpacing + secondSectionHeight
            } else {
                scrollHeight = sectionSpacing + firstSectionHeight + sectionSpacing
            }
            
            
            outputView.stackViewHeight.constant = 100
            outputView.infoViewHeight.constant = 120
            
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
                robotView.frame = CGRect(x: 0, y: positionY, width: containerOutputScrollView.bounds.width, height: containerOutputScrollView.bounds.height)
                changeScrollViewHeight(height: scrollHeight)
            }
            isFirstOpen = true
        }
        
        outputView.hideDetail = {
            [unowned self] in
            var positionY: Double = 0
            positionY = sectionSpacing
            
            var scrollHeight: Double = 0
            if (isSecondOpen) {
                scrollHeight = sectionSpacing + secondSectionHeight
            } else {
                scrollHeight = sectionSpacing*3
            }
            
            outputView.stackViewHeight.constant = 0
            outputView.infoViewHeight.constant = 0
            
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
                robotView.frame = CGRect(x: 0, y: positionY, width: containerOutputScrollView.bounds.width, height: containerOutputScrollView.bounds.height)
                changeScrollViewHeight(height: scrollHeight)
            }
            isFirstOpen = false
        }
        
        robotView.showDetail = {
            [unowned self] in
            var positionY: Double = 0
            var scrollHeight: Double = 0
            
            if (isFirstOpen) {
                positionY = sectionSpacing + firstSectionHeight
                scrollHeight = sectionSpacing + firstSectionHeight + sectionSpacing + secondSectionHeight + sectionSpacing
            } else {
                positionY = sectionSpacing
                scrollHeight = sectionSpacing + secondSectionHeight
            }
            
            robotView.containerViewHeight.constant = 200
            
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
                robotView.frame = CGRect(x: 0, y: positionY, width: containerOutputScrollView.bounds.width, height: containerOutputScrollView.bounds.height)
                changeScrollViewHeight(height: scrollHeight)
            }
            isSecondOpen = true
        }
        
        robotView.hideDetail = {
            [unowned self] in
            var positionY: Double = 0
            
            var scrollHeight: Double = 0
            
            if (isFirstOpen) {
                positionY = sectionSpacing + firstSectionHeight
                scrollHeight = sectionSpacing + firstSectionHeight
            } else {
                positionY = sectionSpacing
                scrollHeight = sectionSpacing*3
            }
            
            robotView.containerViewHeight.constant = 0
            
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
                robotView.frame = CGRect(x: 0, y: positionY, width: containerOutputScrollView.bounds.width, height: containerOutputScrollView.bounds.height)
                changeScrollViewHeight(height: scrollHeight)
            }
            isSecondOpen = false
        }
    }
    
    func configureMapView() {
        let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: lon, zoom: 16)
        let mapView = GMSMapView.map(withFrame: self.containerMapView.frame, camera: camera)
        self.view.addSubview(mapView)

        // Creates a marker in the center of the map.
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        marker.title = "KIST"
        marker.snippet = "Korea Institute of Science Technology"
        marker.map = mapView
    }
    
    func configureContainerOutputView() {
        containerOutputScrollView.clipsToBounds = true
        containerOutputScrollView.layer.cornerRadius = 30
        containerOutputScrollView.layer.maskedCorners = CACornerMask(arrayLiteral: .layerMinXMinYCorner, .layerMaxXMinYCorner)

//        containerOutputView.layer.shadowOpacity = 0.5
//        containerOutputView.layer.shadowOffset = CGSize(width: 0, height: -5)
//        containerOutputView.layer.shadowRadius = 10
//        containerOutputView.layer.masksToBounds = false

        self.view.addSubview(containerOutputScrollView)
        self.view.bringSubviewToFront(self.containerOutputScrollView)
        changeScrollViewHeight(height: sectionSpacing*3)
    }
    
    private let dragIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 3
        
//        view.layer.shadowOpacity = 0.5
//        view.layer.shadowOffset = CGSize(width: 0, height: -5)
//        view.layer.shadowRadius = 10
//        view.layer.masksToBounds = false
        
        return view
    }()
    
    private func showContainerOutputView(atState: ContainerViewState = .normal) {
        if atState == .normal {
            let safeAreaHeight: CGFloat = view.safeAreaLayoutGuide.layoutFrame.height
            let bottomPadding: CGFloat = view.safeAreaInsets.bottom
            containerViewTopConstraint.constant = (safeAreaHeight + bottomPadding) - defaultHeight
        } else {
            containerViewTopConstraint.constant = containerOutputViewMinTopConstant
        }
    }
    
    private func hideContainerOutputView() {
        let safeAreaHeight = view.safeAreaLayoutGuide.layoutFrame.height
        let bottomPadding = view.safeAreaInsets.bottom
        containerViewTopConstraint.constant = safeAreaHeight + bottomPadding - 200
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func changeScrollViewHeight(height: Double) {
        self.containerOutputScrollView.contentSize = CGSize(width: containerOutputScrollView.bounds.width, height: height)
    }
    
    //주어진 CGFloat 배열의 값 중 number로 주어진 값과 가까운 값을 찾아내는 메소드
    func nearest(to number: CGFloat, inValues values: [CGFloat]) -> CGFloat {
        guard let nearestVal = values.min(by: { abs(number - $0) < abs(number - $1) })
        else { return number }
        return nearestVal
    }
    
    // 해당 메소드는 사용자가 view를 드래그하면 실행됨
    @objc private func viewPanned(_ panGestureRecognizer: UIPanGestureRecognizer) {
        let translation = panGestureRecognizer.translation(in: self.view)
        
        let velocity = panGestureRecognizer.velocity(in: view)
        
        switch panGestureRecognizer.state {
        case .began:
            containerOutputViewPanStartingTopConstant = containerViewTopConstraint.constant
        case .changed:
            if containerOutputViewPanStartingTopConstant + translation.y > containerOutputViewMinTopConstant {
                containerViewTopConstraint.constant = containerOutputViewPanStartingTopConstant + translation.y
            }
        case .ended:
            if velocity.y > 1500 {
                hideContainerOutputView()
                return
            }
            
            let safeAreaHeight = view.safeAreaLayoutGuide.layoutFrame.height
            let bottomPadding = view.safeAreaInsets.bottom
            
            let defaultPadding = safeAreaHeight+bottomPadding - defaultHeight
            
            let nearestValue = nearest(to: containerViewTopConstraint.constant, inValues: [containerOutputViewMinTopConstant, defaultPadding, safeAreaHeight + bottomPadding])
            
            if nearestValue == containerOutputViewMinTopConstant {
                showContainerOutputView(atState: .expanded)
            } else if nearestValue == defaultPadding {
                showContainerOutputView(atState: .normal)
            } else {
                hideContainerOutputView()
            }
        default:
            break
        }
    }
    
    func startTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
        
        timerCounter = 0
    }
    
    func stopTimer() {
        self.timer.invalidate()
    }
    
    @objc func timerUpdate() {
        let timeStamp = getCurrentTimeInMilliseconds()
        let dt = timeStamp - pastTime
        pastTime = timeStamp
        
        if (dt < 100) {
            elapsedTime += (dt*1e-3)
        }
//        self.timeLabel.text = String(format: "%.2f", elapsedTime)
        
        let isStepDetected = jupiterService.stepResult.isStepDetected
        let unitIdx = Int(jupiterService.stepResult.unit_idx)
        let unitLength = jupiterService.stepResult.step_length
        let flag = jupiterService.stepResult.lookingFlag
        
        if (isStepDetected) {
            self.stepCountTxLabel.text = String(unitIdx)
            self.stepCountRxLabel.text = String(unitIdx)
            self.stepLengthLabel.text = String(format: "%.4f", unitLength)
            self.mobileStatusLabel.text = String(flag)
        }
    }
    
    func getCurrentTimeInMilliseconds() -> Double
    {
        return Double(Date().timeIntervalSince1970 * 1000)
    }
}
