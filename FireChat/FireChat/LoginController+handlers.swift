//
//  LoginController+handlers.swift
//  FireChat
//
//  Created by Ajit Kumar Baral on 4/5/17.
//  Copyright © 2017 Ajit Kumar Baral. All rights reserved.
//

import UIKit
import Firebase

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            selectedImageFromPicker = editedImage
            
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            
            
            selectedImageFromPicker = originalImage
            
        }
        
        if let selectedImage = selectedImageFromPicker {
                profileImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Picker canceled")
        dismiss(animated: true, completion: nil)
    }
    
    func handleLoginRegister() {
        if loginRegisterSegmentedControl.selectedSegmentIndex == 0 {
            handleLogin()
        }else {
            handleRegister()
        }
    }
    
    func handleLogin() {
        
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            print("Form is not valid")
            return
        }
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {
                print(error!)
                return
            }
            
            
            //Successfully logged in
            
            self.messagesController?.fetchUserAndSetupNavBarTitle()
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    
    func handleRegister() {
        
        guard let name = nameTextField.text, let email = emailTextField.text, let password = passwordTextField.text else {
            print("Form is not valid")
            return
        }
        
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
            
            if error != nil {
                print(error!)
                return
            }
            
            guard let uid = user?.uid else{
                return
            }
            
            //Successfully authenticated
            
            //Store the profile image
            let imageName = NSUUID().uuidString //Gives the unique id
            
            let storageRef = FIRStorage.storage().reference().child("profile_images").child("\(imageName).jpg")
            
            
            //Compressing the image sizes
            
            if let profileImage = self.profileImageView.image, let uploadData = UIImageJPEGRepresentation(profileImage, 0.1) {
                    
                    //if let uploadData = UIImagePNGRepresentation(self.profileImageView.image!) {
                    storageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
                        if error != nil {
                            print(error!)
                            return
                        }
                        
                        if let profileImageUrl = metadata?.downloadURL()?.absoluteString {
                            
                            let values = ["name": name, "email": email, "profileImageUrl": profileImageUrl]
                            
                            self.registerUserIntoDatabaseWithUID(uid: uid, values: values)
                        }
                    })
                
            }
            
            
        })
    }
    
    
    private func registerUserIntoDatabaseWithUID(uid: String, values: [String:Any]) {
        
        let ref = FIRDatabase.database().reference()
        let userReference = ref.child("users").child(uid)
        userReference.updateChildValues(values, withCompletionBlock: { (error: Error?, ref: FIRDatabaseReference) in
            
            if error != nil {
                print(error!)
                return
            }
            
            
//            self.messagesController?.navigationItem.title = values["name"] as? String
            let user = User()
            user.setValuesForKeys(values)
            self.messagesController?.setupNavBarWithUser(user)
            
            self.dismiss(animated: true, completion: nil)
            
            
        })
    }
    
    
    //Segmented Control
    
    func handleLoginRegisterChange() {
        let title = loginRegisterSegmentedControl.titleForSegment(at: loginRegisterSegmentedControl.selectedSegmentIndex)
        loginRegisterButton.setTitle(title, for: .normal)
        
        
        //Change hight of the inputsContainerView
        inputsContainerViewHeightAnchor?.constant = loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 100: 150
        
        //Change hight of the nameTextField
        nameTextFieldHeightAnchor?.isActive = false
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 0 : 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        nameTextField.isHidden = loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? true : false
        //nameTextField.placeholder = loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? "" : "Name"
        
        //Change hight of the emailTextField
        emailTextFieldHeightAnchor?.isActive = false
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        //Change hight of the passwordTextField
        passwordTextFieldHeightAnchor?.isActive = false
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        passwordTextFieldHeightAnchor?.isActive = true
    }
}
