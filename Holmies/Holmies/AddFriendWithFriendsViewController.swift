//
//  AddFriendWithFriendsViewController.swift
//  Holmies
//
//  Created by Leonardo Geus on 01/12/15.
//  Copyright © 2015 Leonardo Geus. All rights reserved.
//

import UIKit

class AddFriendWithFriendsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var FriendsTableView: UITableView!
    @IBOutlet weak var addFriendTextField: UITextField!
    let http = HTTPHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FriendsTableView.separatorInset = UIEdgeInsetsZero
        FriendsTableView.layoutMargins = UIEdgeInsetsZero
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
        
    }
    
    override func viewWillAppear(animated: Bool) {
        FriendsTableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = DataManager.sharedInstance.allFriends.count
        
        return count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("friend", forIndexPath: indexPath) as! FriendsInFriendsTableViewCell
        
        //MARK - CRIAR METODO DE PERSISTIR NO DATAMANAGER PARA DEPOIS ACESSAR E VER SE PERMENECEU PERSISTIDO
        
        self.FriendsTableView.rowHeight = 45
        
        cell.friendUsername.font = UIFont(name: "SFUIText-Regular", size: 17)
        cell.friendUsername.textColor = UIColor.grayColor()
        
        cell.imageUser.layer.cornerRadius = 19
        cell.imageUser.clipsToBounds = true
        cell.imageUser.layer.borderWidth = 0

        
        cell.friendUsername.text = DataManager.sharedInstance.allFriends[indexPath.row].username
        cell.imageUser.image = DataManager.sharedInstance.findImage(DataManager.sharedInstance.allFriends[indexPath.row].userID)
        
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        } else {
            // Fallback on earlier versions
            tableView.separatorInset = UIEdgeInsetsZero
            tableView.preservesSuperviewLayoutMargins = false
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
        }
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        continueAction()
        self.view.endEditing(true)
        return false
    }
    
    func continueAction() {
        
        if (addFriendTextField.text == "") {
            DataManager.sharedInstance.shakeTextField(addFriendTextField)
            DataManager.sharedInstance.createSimpleUIAlert(self, title: "Atenção", message: "Digite um username de amigo para adicionar", button1: "OK")
        } else {
            if addFriendTextField.text == DataManager.sharedInstance.myUser.username {
                DataManager.sharedInstance.createSimpleUIAlert(self, title: "Naoo add", message: "Esse username é você", button1: "Ok")
            }
            else {
                addFriend({ (result) -> Void in
                })
            }
        }
    }
    
    func addFriend (completion:(result:String)->Void) {
        http.findFriendWithUsername("\(addFriendTextField.text!)") { (result) -> Void in
            let JSON = result
            let dic = JSON as NSDictionary
            
            if dic["error"] != nil {
                DataManager.sharedInstance.createSimpleUIAlert(self, title: "Error", message: dic["error"] as! String, button1: "Ok")
                print("Nao Localizado")
            }
            else {
                
                let newUser = User()
                newUser.username = dic["username"] as? String
                newUser.altitude = dic["altitude"] as? String
                newUser.createdAt = dic["created_at"] as? String
                newUser.email = dic["email"] as? String
                newUser.facebookID = dic["fbid"] as? String
                let id = dic["id"] as? Int
                newUser.userID = "\(id!)"
                newUser.name = dic["name"] as? String
                if let locationString = dic["location"] as? String {
                    if locationString.containsString(":") {
                        let locationArray = locationString.componentsSeparatedByString(":") as [String]
                        newUser.location.latitude = locationArray[0]
                        newUser.location.longitude = locationArray[1]
                    }
                }
                
                var friendAlreadyExist = false
                for friend in DataManager.sharedInstance.allFriends {
                    if friend.userID == newUser.userID {
                        DataManager.sharedInstance.createSimpleUIAlert(self, title: "User ja amigo", message: "add outro user", button1: "Ok")
                        friendAlreadyExist = true
                    }
                    
                }
                
                if friendAlreadyExist == false {
                    DataManager.sharedInstance.allFriends.append(newUser)
                    //                    let friends = DataManager.sharedInstance.allFriends
                    
                    let alertController = UIAlertController(title: "Sucesso", message: "Amigo \(newUser.username)", preferredStyle: .Alert)
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                        UIAlertAction in
                    }
                    
                    
                    alertController.addAction(okAction)
                    
                    let userdic = DataManager.sharedInstance.convertUserToNSDic(DataManager.sharedInstance.allFriends)
                    DataManager.sharedInstance.createJsonFile("friends", json: userdic)
                    
                    completion(result: "sucesso")
                    self.presentViewController(alertController, animated: true, completion: nil)
                    self.FriendsTableView.reloadData()
                }
                
                
            }
        }
        
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}