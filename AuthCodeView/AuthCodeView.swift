//
//  AuthCodeView.swift
//  Playlet
//
//  Created by 丁燕军 on 2024/4/9.
//

import UIKit

protocol AuthCodeViewDelegate: AnyObject {
    func authCodeView(_ view: AuthCodeView, didEndWith code: String)
}

class AuthCodeView: UIView {
    
    struct Config {
        var activeBorderColor: UIColor = .green
        var normalBorderColor: UIColor = .black
        var activeFillColor: UIColor = .clear
        var normalFillColor: UIColor = .clear
        var numberColor: UIColor = .black
        var cursorColor: UIColor = .green
        var size: CGFloat = 48
        var spacing: CGFloat = 8
        var cornerRadius: CGFloat = 8
    }
    
    private var fields: [UITextField] = []
    private var activeField: UITextField! {
        didSet {
            activeField.isEnabled = true
            activeField.layer.borderColor = config.activeBorderColor.cgColor
            activeField.backgroundColor = config.activeFillColor
            activeField.becomeFirstResponder()
            activeField.text = ""
            
            oldValue?.isEnabled = false
            oldValue?.layer.borderColor = config.normalBorderColor.cgColor
            oldValue?.backgroundColor = config.normalFillColor
        }
    }
    
    var authCode: String {
        fields.reduce("") { partialResult, textField in
            partialResult + (textField.text ?? "")
        }
    }
    
    weak var delegate: AuthCodeViewDelegate?
    
    private let count: Int
    private let config: Config
    init(count: Int, config: Config) {
        self.count = count
        self.config = config
        super.init(frame: .zero)
        
        for _ in 0..<count {
            let textField = AuthCodeField()
            textField.textAlignment = .center
            textField.tintColor = config.cursorColor
            textField.textColor = config.numberColor
            textField.keyboardType = .numberPad
            textField.delegate = self
            textField.isEnabled = false
            textField.deleteDelegate = self
            textField.layer.borderWidth = 1.0
            textField.layer.borderColor = config.normalBorderColor.cgColor
            textField.layer.cornerRadius = config.cornerRadius
            
            textField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textField.widthAnchor.constraint(equalToConstant: config.size),
                textField.heightAnchor.constraint(equalToConstant: config.size),
            ])
            fields.append(textField)
        }
        
        let stackView = UIStackView(arrangedSubviews: fields)
        stackView.axis = .horizontal
        stackView.spacing = config.spacing
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview != nil {
            activeField = fields.first
        }
    }
    
    override var intrinsicContentSize: CGSize {
        let count = CGFloat(count)
        return CGSize(width: config.size * count + config.spacing * (count - 1), height: config.size)
    }
    
    func findNextTextField(current: UITextField, forward: Bool) {
        guard let index = fields.firstIndex(of: current) else { return }
        if forward {
            if index < fields.count - 1 {
                activeField = fields[index + 1]
            }
        } else {
            if index > 0 {
                activeField = fields[index - 1]
            }
        }
    }
    
}

extension AuthCodeView: AuthCodeFieldDelegate {
    
    func authCodeFieldDeleteBackward(textField: AuthCodeField) {
        if let text = textField.text, text.isEmpty {
            findNextTextField(current: textField, forward: false)
        }
    }
}

extension AuthCodeView: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        if newLength == 1 {
            delay(seconds: 0.01) {
                self.findNextTextField(current: textField, forward: true)
                if textField === self.fields.last {
                    self.delegate?.authCodeView(self, didEndWith: self.authCode)
                }
            }
        }
        return newLength <= 1
    }
    
    func delay(seconds: Double, completion:@escaping ()->()) {
        let popTime = DispatchTime.now() + seconds
        DispatchQueue.main.asyncAfter(deadline: popTime) {
            completion()
        }
    }
    
}

protocol AuthCodeFieldDelegate: AnyObject {
    func authCodeFieldDeleteBackward(textField: AuthCodeField)
}

class AuthCodeField: UITextField {
    
    weak var deleteDelegate: AuthCodeFieldDelegate?
    
    override func deleteBackward() {
        deleteDelegate?.authCodeFieldDeleteBackward(textField: self)
        super.deleteBackward()
    }
    
}
