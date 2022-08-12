//
//  RegisterViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/08/08.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import TextFieldEffects

class RegisterViewController: UIViewController, UITextFieldDelegate {
    
    weak var alertController: UIAlertController?
    
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var emailDuplicateCheckButton: UIButton!
    @IBOutlet weak var nicknameDuplicateCheckButton: UIButton!
    @IBOutlet weak var passwordCheckImage: UIImageView!
    @IBOutlet weak var notMatchedPasswordLabel: UILabel!
    
    
    // TextField
    @IBOutlet weak var emailTextField: HoshiTextField!
    @IBOutlet weak var passwordTextField: HoshiTextField!
    @IBOutlet weak var passwordCheckTextField: HoshiTextField!
    @IBOutlet weak var nicknameTextField: HoshiTextField!
    
    var userEmail: String = ""
    var userPassword: String = ""
    var userPasswordCheck: String = ""
    var userNickname: String = ""
    
    var isEmailValid: Bool = false
    var isPasswordValid: Bool = false
    var isNicknameValid: Bool = false
    
    let BLUE: UIColor = UIColor(red: 0.251, green: 0.694, blue: 0.898, alpha: 1)
    let GRAY: UIColor = UIColor(red: 0.779, green: 0.779, blue: 0.779, alpha: 1)
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        passwordCheckTextField.delegate = self
        nicknameTextField.delegate = self
        
        makeUI()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == passwordTextField) {
            self.userPassword = passwordTextField.text ?? ""
            checkPassword()
        } else if (textField == passwordCheckTextField) {
            self.userPasswordCheck = passwordCheckTextField.text ?? ""
            checkPassword()
        }
        
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        passwordCheckTextField.resignFirstResponder()
        nicknameTextField.resignFirstResponder()
        
        checkConfirmButton()
        
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        
        self.userEmail = emailTextField.text ?? ""
        self.userPassword = passwordTextField.text ?? ""
        self.userPasswordCheck = passwordCheckTextField.text ?? ""
        self.userNickname = nicknameTextField.text ?? ""
        
        checkPassword()
        checkConfirmButton()
    }
    
    func makeUI() {
        self.view.bringSubviewToFront(emailDuplicateCheckButton)
        self.view.bringSubviewToFront(nicknameDuplicateCheckButton)

        confirmButton.layer.backgroundColor = GRAY.cgColor
        
        emailTextField.borderActiveColor = BLUE
        passwordTextField.borderActiveColor = BLUE
        passwordCheckTextField.borderActiveColor = BLUE
        nicknameTextField.borderActiveColor = BLUE
        
        emailTextField.borderInactiveColor = BLUE
        passwordTextField.borderInactiveColor = BLUE
        passwordCheckTextField.borderInactiveColor = BLUE
        nicknameTextField.borderInactiveColor = BLUE
    }
    
    @IBAction func tapEmailDuplicateCheckButton(_ sender: UIButton) {
        self.userEmail = emailTextField.text ?? ""
        
        // Nertwork 중복확인
        emailDuplicateCheckButton.setTitle("사용가능", for: .normal)
        emailDuplicateCheckButton.setTitleColor(BLUE, for: .normal)
        emailTextField.isUserInteractionEnabled = false
        emailTextField.textColor = .darkgrey4
        isEmailValid = true
        
        checkConfirmButton()
    }
    
    
    @IBAction func tapNicknameDuplicateCheckButton(_ sender: UIButton) {
        self.userNickname = nicknameTextField.text ?? ""
        
        // Network 중복확인
        nicknameDuplicateCheckButton.setTitle("사용가능", for: .normal)
        nicknameDuplicateCheckButton.setTitleColor(BLUE, for: .normal)
        nicknameTextField.isUserInteractionEnabled = false
        nicknameTextField.textColor = .darkgrey4
        isNicknameValid = true
        
        checkConfirmButton()
    }
    
    
    @IBAction func tapConfirmButton(_ sender: UIButton) {
    }
    
    
    @IBAction func tapCancelButton(_ sender: UIButton) {
        showAlert(message: "회원가입을 취소하시겠습니까?",
                  cancelButtonName: "취소",
                  confirmButtonName: "확인",
                  confirmButtonCompletion: {
            do {
                self.navigationController?.popViewController(animated: true)
            } catch {
                print("Cancle SignIn")
            }
        })
    }
    
    func checkPassword() {
        if (self.userPassword != "" || self.userPasswordCheck != "") {
            if (self.userPassword == self.userPasswordCheck) {
                passwordCheckImage.image = UIImage(systemName: "chevron.down.circle.fill")
                passwordCheckImage.tintColor = BLUE
                
//                self.passwordTextField.borderActiveColor = BLUE
//                self.passwordCheckTextField.borderActiveColor = BLUE
                notMatchedPasswordLabel.isHidden = true
                
                isPasswordValid = true
            } else {
                passwordCheckImage.image = UIImage(systemName: "chevron.down.circle")
                passwordCheckImage.tintColor = .red1
                
//                self.passwordTextField.borderActiveColor = .red1
//                self.passwordCheckTextField.borderActiveColor = .red1
//                self.passwordTextField.
                notMatchedPasswordLabel.isHidden = false
                
                isPasswordValid = false
            }
        } else {
            passwordCheckImage.image = UIImage(systemName: "chevron.down.circle")
            passwordCheckImage.tintColor = .darkgrey4
            
//            self.passwordTextField.borderActiveColor = .red1
//            self.passwordCheckTextField.borderActiveColor = .red1
            notMatchedPasswordLabel.isHidden = true
            
            isPasswordValid = false
        }
    }
    
    func checkConfirmButton() {
//        print("Email :", emailTextField.text!)
//        print("Password :", passwordTextField.text!)
//        print("Password Check :", passwordCheckTextField.text!)
//        print("Nickname :", nicknameTextField.text!)
        
        if (self.isEmailValid && self.isPasswordValid && self.isNicknameValid) {
            self.confirmButton.backgroundColor = BLUE
            self.confirmButton.isEnabled = true
        } else {
            self.confirmButton.backgroundColor = GRAY
            self.confirmButton.isEnabled = false
        }
    }
    
    func showAlert(title: String? = nil,
                   message: String? = nil,
                   preferredStyle: UIAlertController.Style = .alert,
                   cancelButtonName: String? = nil,
                   confirmButtonName: String? = nil,
                   cancelButtonCompletion: (() -> Void)? = nil,
                   confirmButtonCompletion: (() -> Void)? = nil) {
        let alertViewController = UIAlertController(title: title,
                                                    message: message,
                                                    preferredStyle: preferredStyle)
        
        if let cancelButtonName = cancelButtonName {
            let cancelAction = UIAlertAction(title: cancelButtonName,
                                             style: .cancel) { _ in
                cancelButtonCompletion?()
            }
            alertViewController.addAction(cancelAction)
        }
        
        if let confirmButtonName = confirmButtonName {
            let confirmAction = UIAlertAction(title: confirmButtonName,
                                              style: .default) { _ in
                confirmButtonCompletion?()
            }
            alertViewController.addAction(confirmAction)
        }
        
        alertController = alertViewController
        present(alertViewController, animated: true)
    }
    
    @objc private func didInputTextField(field: UITextField) {
        if let alertController = alertController {
            alertController.preferredAction?.isEnabled = field.hasText
        }
    }
}
