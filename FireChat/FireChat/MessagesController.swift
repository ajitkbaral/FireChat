//
//  ViewController.swift
//  FireChat
//
//  Created by Ajit Kumar Baral on 4/5/17.
//  Copyright © 2017 Ajit Kumar Baral. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController {

    var timer: Timer?
    
    let cellId = "cellId"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        tableView.allowsMultipleSelectionDuringEditing = true
        
        
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        let message = self.messages[indexPath.row]
        
        
        
        if let chatPartherId = message.chatPartnerId() {
            
            FIRDatabase.database().reference().child("user-messages").child(uid).child(chatPartherId).removeValue(completionBlock: { (error, ref) in
                
                if error != nil {
                    print("Failed to delete the message: ", error!)
                    return
                }
                
                
                self.messagesDictionary.removeValue(forKey: chatPartherId)
                self.attemptReloadOfTable()
                
                
//                Unsafe way for deleting the message as the messages are stored in
//                the messageDictionary
//                self.messages.remove(at: indexPath.row)
//                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                
                
            })
        }
        
    }
    
    var messages = [Message]()
    var messagesDictionary = [String:Message]()
    
    func observeUserMessages() {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        let ref = FIRDatabase.database().reference().child("user-messages").child(uid)
        
        ref.observe(.childAdded, with: { (snapshot) in
        
            let userId = snapshot.key
            
            FIRDatabase.database().reference().child("user-messages").child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
                
                let messageId = snapshot.key
                self.fetchMessage(withMessageId: messageId)
                
            }, withCancel: nil)
            
            
        }, withCancel: nil)
        
        
        ref.observe(.childRemoved, with: { (snapshot) in
            
            self.messagesDictionary.removeValue(forKey: snapshot.key)
            self.attemptReloadOfTable()
            
        }, withCancel: nil)
        
    }
    
    private func fetchMessage(withMessageId messageId: String) {
        let messagesReference = FIRDatabase.database().reference().child("messages").child(messageId)
        messagesReference.observeSingleEvent(of: .value, with: { (snapshot) in
            
            
            if let dictionary = snapshot.value as? [String:Any] {
                
                let message = Message(dictionary: dictionary)
                //self.messages.append(message)
                
                
                
                if let chatPartnerId = message.chatPartnerId() {
                    
                    self.messagesDictionary[chatPartnerId] = message
                    
                }
                
                //Setting the time interval for populating the right information in the cell
                self.attemptReloadOfTable()
                
            }
            
            
        }, withCancel: nil)
    }
    
    
    private func attemptReloadOfTable() {
        
        self.messages = Array(self.messagesDictionary.values)
        self.messages.sort(by: { (message1, message2) -> Bool in
            return (message1.timestamp?.intValue)! > (message2.timestamp?.intValue)! //Descending order messages
        })
        
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
    
    func handleReloadTable() {
        
        //Transferring it to the main thread
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let message = messages[indexPath.row]
        guard let chatPartnerId = message.chatPartnerId() else{
            return
        }
        
        let ref = FIRDatabase.database().reference().child("users").child(chatPartnerId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String:Any] else {
                return
            }
            
            let user = User()
            user.id = chatPartnerId
            user.setValuesForKeys(dictionary)
            
            self.showChatControllerForUser(user: user)
            
        }, withCancel: nil)
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        let message = messages[indexPath.row]
        
        cell.message = message
        
        
        return cell
    }
    
    func handleNewMessage() {
        let newMessageController = NewMessageController()
        newMessageController.messagesController = self
        present(UINavigationController(rootViewController: newMessageController), animated: true, completion: nil)
    }
    
    
    func checkIfUserIsLoggedIn() {
        //User is not logged in
        if FIRAuth.auth()?.currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else{
            fetchUserAndSetupNavBarTitle()
        }
    }
    
    func fetchUserAndSetupNavBarTitle() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        FIRDatabase.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String:Any]{
                
                let user = User()
                user.setValuesForKeys(dictionary)
                self.setupNavBarWithUser(user)
            }
            
        }, withCancel: nil)
    }
    
    func handleLogout() {
        
        do{
            try FIRAuth.auth()?.signOut()
        }catch let logoutError {
            print(logoutError)
        }
        
        let loginController = LoginController()
        loginController.messagesController = self
        present(loginController, animated: true, completion: nil)
    }
    
    
    func setupNavBarWithUser(_ user: User) {
        
        messages.removeAll()
        messagesDictionary.removeAll()
        
        
        observeUserMessages()
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
//        titleView.backgroundColor = UIColor.red
        
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(containerView)
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.layer.masksToBounds = true
        if let profileImageUrl = user.profileImageUrl{
            profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        
        containerView.addSubview(profileImageView)
        
        
        
        //Constraints for profile image view
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        let nameLabel = UILabel()
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        
        containerView.addSubview(nameLabel)
        
        //Constraints for name label
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor, multiplier: 1).isActive = true
        
        
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
        self.navigationItem.titleView = titleView
        
        
        //titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showChatController)))

    }
    
    func showChatControllerForUser(user : User) {
        
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }


}

