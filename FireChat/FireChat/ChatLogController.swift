//
//  ChatLogController.swift
//  FireChat
//
//  Created by Ajit Kumar Baral on 4/6/17.
//  Copyright © 2017 Ajit Kumar Baral. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class ChatLogController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    let cellId = "cellId"
    
    
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    var startingImageView: UIImageView?
    
    
    var messages = [Message]()
    
    var containerViewButtonAnchor: NSLayoutConstraint?
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            
            observeMessages()
            
        }
    }
    
    func observeMessages() {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid, let toId = user?.id else {
            return
        }
        
        let userMessageReference = FIRDatabase.database().reference().child("user-messages").child(uid).child(toId)
        
        
        userMessageReference.observe(.childAdded, with: { (snapshot) in
            
            let messageId = snapshot.key
            let messagesRef = FIRDatabase.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let dictionary = snapshot.value as? [String:Any] else {
                    return
                }
                
                self.messages.append(Message(dictionary: dictionary))
                
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    //Scroll to the last index
                    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                }
                
            }, withCancel: nil)
            
        }, withCancel: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setting padding for the cell view from the main view
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        //Changing the scroll indicator of the collection view
//        collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        
        collectionView?.alwaysBounceVertical = true
        
        collectionView?.backgroundColor = UIColor.white
        
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        setupKeyboardObservers()
  

        collectionView?.keyboardDismissMode = .interactive
        
        
    }
    
    lazy var inputContainerView: ChatInputContainerView = {
        
        let chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        chatInputContainerView.chatLogController = self
        return chatInputContainerView
    }()
    
    
    //Handle upoading images
    func handleUploadTap() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        //Adding media types videos
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL {
            
            //Selection of a video
            handleVideoSelected(url: videoUrl)
            
        } else {
            //Selection of an image
            handleImageSelected(forInfo: info)
            
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    
    private func handleVideoSelected(url: URL) {
        
        let fileName = NSUUID().uuidString + ".mov"
        let uploadTask = FIRStorage.storage().reference().child("message_movies").child(fileName).putFile(url, metadata: nil, completion: { (metadata, error) in
            
            if error != nil {
                print("Error storing the video: ", error!)
                return
            }
            
            if let videoUrl = metadata?.downloadURL()?.absoluteString {
                
                if let thumbnailImage = self.thumbnailImage(forFileUrl: url) {
                    
                    self.uploadToFirebaseStorageUsingImage(image: thumbnailImage, completion: { (imageUrl) in
                        
                        
                        let properties: [String:Any] = ["imageUrl": imageUrl, "videoUrl":videoUrl, "imageWidth": thumbnailImage.size.width, "imageHeight": thumbnailImage.size.height]
                        self.sendMessage(WithProperties: properties)
                        
                    })
                    
                    
                    
                }
            }
            
        })
        
        uploadTask.observe(.progress) { (snapshot) in
            if snapshot.progress?.completedUnitCount != nil {
                    self.navigationItem.title = "Uploading..."
            }
        }
        
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
        
    }
    
    //Returns and image of the video
    private func thumbnailImage(forFileUrl fileUrl: URL) -> UIImage? {
        let asset = AVAsset(url: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do{
            
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            
            return UIImage(cgImage: thumbnailCGImage)
        
        }catch let err {
            print(err)
        }
        return nil
    }
    

    private func handleImageSelected(forInfo info: [String:Any]) {
        
        var selectedImageFromPicker: UIImage?
        //Selection of an image
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            selectedImageFromPicker = editedImage
            
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            
            
            selectedImageFromPicker = originalImage
            
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadToFirebaseStorageUsingImage(image: selectedImage, completion: { (imageUrl) in
                self.sendMessage(withImageUrl: imageUrl, image: selectedImage)
            })
        }
    }
    
    private func uploadToFirebaseStorageUsingImage(image: UIImage, completion: @escaping (_ imageUrl: String) -> ()) {
       
        
        let imageName = NSUUID().uuidString
        let ref = FIRStorage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            
            ref.put(uploadData, metadata: nil, completion: { (metadata, error) in
                
                if error != nil {
                    print("Failed to upload image: ", error!)
                    return
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    
                    completion(imageUrl)
                    
                }
                
            })
        }
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    override var inputAccessoryView: UIView? {
        
        get {
            return inputContainerView
        }
        
    }
    
    
    //To display the inputAccessoryView
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
     }
    
    //For the keyboard so that ther is no memory leak
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupKeyboardObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: .UIKeyboardDidShow, object: nil)
        
        
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: .UIKeyboardWillShow, object: nil)
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        
        
    }
    
    
    func handleKeyboardDidShow() {
        
        if messages.count > 0 {
            let indexPath = IndexPath(item: messages.count - 1, section: 0)
            collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
        
        
    }
    
    func handleKeyboardWillShow(notification: NSNotification) {
        
        if let userInfo = notification.userInfo {
            if let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect {
                
                
                //Moving the input area up from the keyboard to slide up
                containerViewButtonAnchor?.constant = -keyboardFrame.height
                
                if let keyboardDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double{
                    UIView.animate(withDuration: keyboardDuration, animations: {
                        self.view.layoutIfNeeded()
                    })
                }
            }
        }
    }
    
    func handleKeyboardWillHide(notification: NSNotification) {
        
        if let userInfo = notification.userInfo {
            
            //Moving the input area up from the keyboard to slide at the bottom
            containerViewButtonAnchor?.constant = 0
            
            if let keyboardDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double{
                UIView.animate(withDuration: keyboardDuration, animations: {
                    self.view.layoutIfNeeded()
                })
                
            }
        }
        
        
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
       
        
        cell.chatLogController = self
        
        
        let message = messages[indexPath.row]
        
        cell.message = message
        
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)
        
        if let text = message.text {
            //If it is a text
            cell.textView.isHidden = false
            cell.bubbleWidthAnchor?.constant = estimageFrameForText(text).width + 32
        
        } else if message.imageUrl != nil {
            //if it is an image
            cell.textView.isHidden = true
            cell.bubbleWidthAnchor?.constant = 200
            
        }
        
        //Logic for the playButton for the videos
        cell.playButton.isHidden = message.videoUrl == nil
        
        return cell
    }
    
    
    private func setupCell(cell: ChatMessageCell, message: Message) {

        if let profileImageUrl = self.user?.profileImageUrl {
            
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        
        if message.fromId == FIRAuth.auth()?.currentUser?.uid {
            //Blue bubble
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
            
        }else {
            //Gray bubble
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
        }
        
        
        if let messageUrl = message.imageUrl {
            cell.messageImageView.loadImageUsingCacheWithUrlString(urlString: messageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = UIColor.clear

        } else {
            cell.messageImageView.isHidden = true
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        
        let message = self.messages[indexPath.item]
        //Getting the estimate height
        
        if let text = message.text {
            height = estimageFrameForText(text).height + 20
            
        }else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
            
            
            //Setting the height of the collection view cell same as the height of the imageView
            
            //h1/w1 = h2/w2
            //To solve h1
            //h1 = h2/w2 * w1
            
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
        
    }
    
    //On the device orientation in landscape
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    
    private func estimageFrameForText(_ text: String) -> CGRect {
        
        let size = CGSize(width: 200, height: 1000)
        
        let option = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: option, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    
    func handleSend() {
        
        let properties: [String:Any] = ["text":inputContainerView.inputTextField.text!]
        
        sendMessage(WithProperties: properties)
        
    }
    
    private func sendMessage(withImageUrl imageUrl: String, image: UIImage) {
        let properties: [String:Any] = ["imageUrl":imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height]
        sendMessage(WithProperties: properties)
    }
    
    private func sendMessage(WithProperties properties: [String:Any]) {
        
        let ref = FIRDatabase.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toId = user!.id!
        let fromId = FIRAuth.auth()!.currentUser!.uid
        let timestamp: NSNumber = NSNumber(value: Int(NSDate().timeIntervalSince1970))
        var values: [String:Any] = ["toId": toId, "fromId": fromId, "timestamp": timestamp]
        
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values) { (error, ref) in
            
            if error != nil {
                print(error!)
                return
            }
            
            self.inputContainerView.inputTextField.text = nil
            
            let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId).child(toId)
            
            let messageId = childRef.key
            
            userMessagesRef.updateChildValues([messageId: 1])
            
            let recipientUserMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessagesRef.updateChildValues([messageId: 1])
            
        }
        
    }
    
    
    //Custom Zooming for imageView
    func performZoomingIn(forStartingImage imageView: UIImageView) {
        
        startingImageView = imageView
        startingImageView?.isHidden = true
        
        
        startingFrame = imageView.superview?.convert(imageView.frame, to: nil)
        
        
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.backgroundColor = UIColor.red
        zoomingImageView.image = imageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            
            blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = UIColor.black
            blackBackgroundView?.alpha = 0
            
            keyWindow.addSubview(blackBackgroundView!)
            
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.blackBackgroundView?.alpha = 1
                
                //Hide the inputContainerView
                self.inputContainerView.alpha = 0
                
                //Setting the correct height of the image
                
                //h2/w2 = h1/w1
                //h2 = h1/w1 * w2
                
                let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
                
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                
                
                zoomingImageView.center = keyWindow.center
                
            }, completion: { (completed) in
                //Do Nothing
            })
            
        }
        
    }
    
    func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        if let zoomOutImageView = tapGesture.view {
            //Animating back out to the controller
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
                
            }, completion: { (completed) in
                
                //Removes the animation zooming image
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            })
            
        }
        
    }
    
    
    
    
    
    
    
}
