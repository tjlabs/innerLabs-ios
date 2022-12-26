//
//  SwieeftSwitchButton.swift
//  SwieeftSwitch
//
//  Created by 1 on 14/02/2020.
//  Copyright © 2020 swieeft. All rights reserved.
//

import UIKit

protocol CustomSwitchButtonDelegate: class {
    func isOnValueChange(isOn: Bool)
}

class CustomSwitchButton: UIButton {
    typealias SwitchColor = (bar: UIColor, circle: UIColor)

    private var barView: UIView!
    private var circleView: UIView!

    var isOn: Bool = false {
        didSet {
            self.changeState()
        }
    }

    // on 상태의 스위치 색상
    var onColor: SwitchColor = (#colorLiteral(red: 1, green: 0.9960784314, blue: 0.5647058824, alpha: 1), #colorLiteral(red: 1, green: 0.7886461807, blue: 0.1811748367, alpha: 1)) {
        didSet {
            if isOn {
                self.barView.backgroundColor = self.onColor.bar
                self.circleView.backgroundColor = self.onColor.circle
            }
        }
    }

    // off 상태의 스위치 색상
    var offColor: SwitchColor = (#colorLiteral(red: 0.9098039216, green: 0.9098039216, blue: 0.9098039216, alpha: 1), #colorLiteral(red: 0.7709601521, green: 0.7709783912, blue: 0.7709685564, alpha: 1)) {
        didSet {
            if isOn == false {
                self.barView.backgroundColor = self.offColor.bar
                self.circleView.backgroundColor = self.offColor.circle
            }
        }
    }

    // 스위치가 이동하는 애니메이션 시간
    var animationDuration: TimeInterval = 0.25

    // 스위치 isOn 값 변경 시 애니메이션 여부
    private var isAnimated: Bool = false

    // barView의 상, 하단 마진 값
    var barViewTopBottomMargin: CGFloat = 5

    weak var delegate: CustomSwitchButtonDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.buttonInit(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.buttonInit(frame: frame)
    }

    private func buttonInit(frame: CGRect) {

        let barViewHeight = frame.height - (barViewTopBottomMargin * 2)

        barView = UIView(frame: CGRect(x: 0, y: barViewTopBottomMargin, width: frame.width, height: barViewHeight))
        barView.backgroundColor = self.offColor.bar
        barView.layer.masksToBounds = true
        barView.layer.cornerRadius = barViewHeight / 2

        self.addSubview(barView)

        circleView = UIView(frame: CGRect(x: 0, y: 0, width: frame.height, height: frame.height))
        circleView.backgroundColor = self.offColor.circle
        circleView.layer.masksToBounds = true
        circleView.layer.cornerRadius = frame.height / 2

        self.addSubview(circleView)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.setOn(on: !self.isOn, animated: true)
    }

    func setOn(on: Bool, animated: Bool) {
        self.isAnimated = animated
        self.isOn = on
    }

    private func changeState() {

        var circleCenter: CGFloat = 0
        var barViewColor: UIColor = .clear
        var circleViewColor: UIColor = .clear

        if self.isOn {
            circleCenter = self.frame.width - (self.circleView.frame.width / 2)
            barViewColor = self.onColor.bar
            circleViewColor = self.onColor.circle
        } else {
            circleCenter = self.circleView.frame.width / 2
            barViewColor = self.offColor.bar
            circleViewColor = self.offColor.circle
        }

        let duration = self.isAnimated ? self.animationDuration : 0

        UIView.animate(withDuration: duration, animations: { [weak self] in
            guard let self = self else { return }

            self.circleView.center.x = circleCenter
            self.barView.backgroundColor = barViewColor
            self.circleView.backgroundColor = circleViewColor

        }) { [weak self] _ in
            guard let self = self else { return }

            self.delegate?.isOnValueChange(isOn: self.isOn)
            self.isAnimated = false
        }
    }
    
    public func setSwitchButtonColor(colorName: String) {
        let switchColor: (UIColor, UIColor) = (#colorLiteral(red: 0.5291011186, green: 0.7673488115, blue: 1, alpha: 1), #colorLiteral(red: 0.2705247761, green: 0.3820963617, blue: 1, alpha: 1))
        
        switch(colorName) {
        case "orange":
            let color: (UIColor, UIColor) = (#colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1), #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1))
            self.onColor = color
        case "gray":
            let color: (UIColor, UIColor) = (#colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
            self.onColor = color
        case "pink":
            let color: (UIColor, UIColor) = (#colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1), #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1))
            self.onColor = color
        case "green":
            let color: (UIColor, UIColor) = (#colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1), #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1))
            self.onColor = color
        case "charcoal":
            let color: (UIColor, UIColor) = (#colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
            self.onColor = color
        default:
            let color: (UIColor, UIColor) = (#colorLiteral(red: 0.5291011186, green: 0.7673488115, blue: 1, alpha: 1), #colorLiteral(red: 0.2705247761, green: 0.3820963617, blue: 1, alpha: 1))
            self.onColor = color
        }
    }
}
