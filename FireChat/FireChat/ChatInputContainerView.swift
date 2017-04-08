//
//  ChatInputContainerView.swift
//  FireChat
//
//  Created by Ajit Kumar Baral on 4/8/17.
//  Copyright © 2017 Ajit Kumar Baral. All rights reserved.
//

import UIKit

class ChatInputContainerView: UIView, UITextFieldDelegate {
    
    
    let sendButton = UIButton(type: .system)
    
    var chatLogController: ChatLogController? {
        didSet {
            sendButton.addTarget(chatLogController, action: #selector(ChatLogController.handleSend), for: .touchUpInside)
            
            uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: chatLogController, action: #selector(ChatLogController.handleUploadTap)))
        }
    }
    
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter a message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    
    let uploadImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "picture_icon")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        
        addSubview(uploadImageView)
        
        //Constraints for the uploadImageView
        uploadImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 8).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        
        
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        
        
        addSubview(sendButton)
        
        //Constraints for send button
        
        sendButton.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        
        //adding inputTextField in the containerview's subview
        addSubview(self.inputTextField)
        
        
        //Constraints for input text field
        
        self.inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 8).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(separatorLineView)
        
        
        //Constraints for separator view
        separatorLineView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        chatLogController?.handleSend()
        return true
    }
}
