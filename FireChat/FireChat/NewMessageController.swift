//
//  NewMessageViewController.swift
//  FireChat
//
//  Created by Ajit Kumar Baral on 4/5/17.
//  Copyright © 2017 Ajit Kumar Baral. All rights reserved.
//

import UIKit
import Firebase

class NewMessageController: UITableViewController {
    
    let cellId = "cellId"
    
    var users = [User]()

    override func viewDidLoad() {
        super.viewDidLoad()

        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancel))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        fetchUser()
    }
    
    
    
    func fetchUser() {
        FIRDatabase.database().reference().child("users").observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String:Any] {
                let user = User()
                
                user.id = snapshot.key
                //The attributes of the class need to be same as the firebase
                user.setValuesForKeys(dictionary)
                
//                //If the attributes are not same
//                user.name = dictionary["name"] as! String
//                user.email = dictionary["email"] as! String
                
                
                self.users.append(user)
                
                //dispatch queue
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            }
            
        }, withCancel: nil)
    }

    
    func handleCancel() {
            dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
    
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let user = users[indexPath.row]
        
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        
        
        if let profileImageUrl = user.profileImageUrl {
            
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
            
//            let url = URL(string: profileImageUrl)
//            
//            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
//                
//                //Download error
//                if error != nil {
//                    print(error!)
//                    return
//                }
//                
//                DispatchQueue.main.async {
//                    cell.profileImageView.image = UIImage(data: data!)
//                }
//                
//                
//            }).resume()
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    
    var messagesController: MessagesController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) {
            let user = self.users[indexPath.row]
            self.messagesController?.showChatControllerForUser(user: user)
        }
    }
}
