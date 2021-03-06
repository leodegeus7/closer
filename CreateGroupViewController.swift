//
//  CreateGroupViewController.swift
//  Holmies
//
//  Created by Leonardo Koppe Malanski on 27/10/15.
//  Copyright © 2015 Leonardo Geus. All rights reserved.
//

import UIKit

class CreateGroupViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UITextFieldDelegate {

    @IBOutlet weak var groupName: UITextField!
    @IBOutlet weak var upSliderLabel: UILabel!
    @IBOutlet weak var downSlideLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
   // @IBOutlet weak var addUserButton: UIButton!
    
    @IBOutlet weak var timeSlider: UISlider!
    
    let redCheck = UIImage(named: "redCheck.png")
    let grayCheck = UIImage(named: "grayCheck.png")
    let mainRed = UIColor(red: 220.0/255.0, green: 32.0/255.0, blue: 63.0/255.0, alpha: 1.0)
    let lightGray = UIColor(red: 170.0/255.0, green: 170.0/255.0, blue: 170.0/255.0, alpha: 1.0)
    let http = HTTPHelper()
    var until = ""
    var filteredArray = Array<User>()
    var resultSearchController = UISearchController()
    var chosenHour:Int!
    var chosenDay:Int!
    var isCharm = false
    var selectedUserIndex = Int?()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.layoutMargins = UIEdgeInsetsZero
        
        if isCharm {
            let buttonSend = UIBarButtonItem(title: "Send", style: .Plain, target: self, action: "continueAction")
            self.navigationItem.rightBarButtonItem = buttonSend

        }
        else{
            
            let buttonContinue = UIBarButtonItem(title: "Create", style: .Plain, target: self, action: "continueAction")
            self.navigationItem.rightBarButtonItem = buttonContinue

        }
        
        
        self.tableView.rowHeight = 45
        
        self.navigationController?.title = "Edit group \(DataManager.sharedInstance.selectedGroup.name)"
        applyDesign()
        startSearchController()
        
        if isCharm {
            groupName.hidden = true
            upSliderLabel.hidden = true
            downSlideLabel.hidden = true
            timeSlider.hidden = true
        }
        

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
        tableView.reloadData()
        resultSearchController.searchBar.hidden = false
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        let fontDictionary = [ NSForegroundColorAttributeName:UIColor.whiteColor() ]
        self.navigationController?.navigationBar.titleTextAttributes = fontDictionary
        self.navigationController?.navigationBar.setBackgroundImage(imageLayerForGradientBackground(), forBarMetrics: UIBarMetrics.Default)
        
    }
    
    private func imageLayerForGradientBackground() -> UIImage {
        
        var updatedFrame = self.navigationController?.navigationBar.bounds
        updatedFrame!.size.height += 20
        let layer = CAGradientLayer.gradientLayerForBounds(updatedFrame!)
        UIGraphicsBeginImageContext(layer.bounds.size)
        layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (resultSearchController.active) {
            return filteredArray.count
        }
        let friends = DataManager.sharedInstance.allFriends
        let count = friends.count
        
        return count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("friend", forIndexPath: indexPath) as! CreateGroupTableViewCell
        
        //MARK - CRIAR METODO DE PERSISTIR NO DATAMANAGER PARA DEPOIS ACESSAR E VER SE PERMENECEU PERSISTIDO
        

        
        cell.friendName.font = UIFont(name: "SFUIText-Regular", size: 17)
        cell.friendName.textColor = lightGray
    
        cell.friendPhoto.layer.cornerRadius = cell.friendPhoto.frame.size.width / 3.1
        cell.friendPhoto.clipsToBounds = true
        cell.checkImage.image = grayCheck
        cell.friendPhoto.layer.borderWidth = 0
        var referenceArray = [User]()
        var index = 0
        var alreadyExist = false
        
        
        if (resultSearchController.active) {
            referenceArray = filteredArray
        }
        else {
            referenceArray = DataManager.sharedInstance.allFriends
        }
        
        cell.friendName.text = referenceArray[indexPath.row].username
        cell.friendPhoto.image = DataManager.sharedInstance.findImage("\(referenceArray[indexPath.row].userID)")
        
        
        if isCharm {
            if indexPath.row == selectedUserIndex {
                cell.checkImage.image = redCheck
                cell.friendPhoto.layer.borderColor = mainRed.CGColor
                cell.friendPhoto.layer.borderWidth = 1
                cell.friendName.textColor = mainRed
            }
            else {
                for charm in DataManager.sharedInstance.myCharms {
                    if charm.friend.userID == referenceArray[indexPath.row].userID {
                        cell.selectionStyle = UITableViewCellSelectionStyle.None
                        cell.userInteractionEnabled = false
                        let barradoView = UIImageView()
                        barradoView.frame.size = cell.friendPhoto.frame.size
                        barradoView.backgroundColor = UIColor.grayColor()
                        barradoView.alpha = 0.5
                        cell.friendPhoto.addSubview(barradoView)
                    }
                }
                cell.checkImage.image = grayCheck
                cell.friendPhoto.layer.borderWidth = 0
                cell.friendName.textColor = lightGray
            }
        }
        else {
            for friend in DataManager.sharedInstance.selectedFriends {
                index++
                if friend.userID == referenceArray[indexPath.row].userID {
                    alreadyExist = true
                    break
                }
            }
            
            if !(alreadyExist) {
                cell.checkImage.image = grayCheck
                cell.friendPhoto.layer.borderWidth = 0
                cell.friendName.textColor = lightGray
            }
                
            else {
                cell.checkImage.image = redCheck
                cell.friendPhoto.layer.borderColor = mainRed.CGColor
                cell.friendPhoto.layer.borderWidth = 1
                cell.friendName.textColor = mainRed
            }
        }
        
        
        
        
        
        
        
    
        
        
        return cell
    }
    
    func applyDesign () {
       
    //MARK (Criar uma string para povoar o placeholder
        groupName.attributedPlaceholder = NSAttributedString(string: "Name of Group", attributes: [NSForegroundColorAttributeName: lightGray])
        groupName.font = UIFont(name: "SFUIText-Medium", size: 17)
        groupName.layer.borderColor = mainRed.CGColor
        groupName.layer.borderWidth = 1
        groupName.layer.cornerRadius = 8
        groupName.tintColor = mainRed
        groupName.textColor = mainRed
       
        tableView.layer.borderColor = mainRed.CGColor
        tableView.layer.borderWidth = 1
        tableView.layer.cornerRadius = 8
        
//        addUserButton.setTitle("New User", forState: UIControlState.Normal)
//        addUserButton.setTitleColor(mainRed, forState: UIControlState.Normal)
//        addUserButton.setAttributedTitle(NSAttributedString(string: "New User", attributes: [NSFontAttributeName: UIFont(name: "SFUIText-Medium", size: 17)!]), forState: UIControlState.Normal)
//        addUserButton.titleLabel!.textColor = mainRed
//        addUserButton.backgroundColor = UIColor.clearColor()
//        addUserButton.layer.borderColor = mainRed.CGColor
//        addUserButton.layer.borderWidth = 1
//        addUserButton.layer.cornerRadius = 8
        
        upSliderLabel.textColor = lightGray
        upSliderLabel.text = "Set duration of group"
        
        downSlideLabel.alpha = 0.0
        downSlideLabel.textColor = mainRed

        
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! CreateGroupTableViewCell
        if isCharm {
            if selectedUserIndex == indexPath.row {
                cell.checkImage.image = grayCheck
                cell.friendPhoto.layer.borderWidth = 0
                cell.friendName.textColor = lightGray
                selectedUserIndex = nil
            }
            else {
                cell.checkImage.image = redCheck
                cell.friendPhoto.layer.borderColor = mainRed.CGColor
                cell.friendPhoto.layer.borderWidth = 1
                cell.friendName.textColor = mainRed
                selectedUserIndex = indexPath.row
                tableView.reloadData()
            }
        }
        else {
            var alreadyExist = false
            
            var index = -1
            
            var referenceArray = [User]()
            
            
            if (resultSearchController.active) {
                referenceArray = filteredArray
            }
            else {
                referenceArray = DataManager.sharedInstance.allFriends
            }
            for friend in DataManager.sharedInstance.selectedFriends {
                if !(alreadyExist) {
                    index++
                }
     
                if friend.userID == referenceArray[indexPath.row].userID {
                    alreadyExist = true
                    break
                }
            }
            
            if alreadyExist {
                            cell.checkImage.image = grayCheck
                            cell.friendPhoto.layer.borderWidth = 0
                            cell.friendName.textColor = lightGray
                            DataManager.sharedInstance.selectedFriends.removeAtIndex(index)
            }
                
            else {
                DataManager.sharedInstance.selectedFriends.append(referenceArray[indexPath.row])
                cell.checkImage.image = redCheck
                cell.friendPhoto.layer.borderColor = mainRed.CGColor
                cell.friendPhoto.layer.borderWidth = 1
                cell.friendName.textColor = mainRed
            }
        }
        
        

        
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
//        let cell = tableView.cellForRowAtIndexPath(indexPath) as! CreateGroupTableViewCell
//        var i = 0
//        
//       
//        
//        var alreadyExist = false
//        
//        var index = 0
//        var indexInAllFriends = 0
//        
//        if (resultSearchController.active) {
//            let allfriend = DataManager.sharedInstance.allFriends
//            let selected = DataManager.sharedInstance.selectedFriends
//            let filtered = filteredArray
//            for userInUser in DataManager.sharedInstance.allFriends {
//                if userInUser.userID == filteredArray[indexInAllFriends].userID {
//                    indexInAllFriends = index
//                }
//                index++
//            }
//        }
//        else {
//            indexInAllFriends = indexPath.row
//        }
//
//        
//        for friend in DataManager.sharedInstance.selectedFriends {
//            if friend.userID == DataManager.sharedInstance.allFriends[indexInAllFriends].userID {
//                alreadyExist = true
//                break
//            }
//            
//            
//        }
//        
//        if alreadyExist {
//            cell.selected = false
//            
//            cell.checkImage.image = grayCheck
//            cell.friendPhoto.layer.borderWidth = 0
//            cell.friendName.textColor = lightGray
//            for userSelected in DataManager.sharedInstance.selectedFriends {
//                
//                if DataManager.sharedInstance.allFriends[indexPath.row].userID == userSelected.userID {
//                    DataManager.sharedInstance.selectedFriends.removeAtIndex(i)
//                    break
//                }
//                i++
//            }
//            
//        }
        
        

//        cell.checkImage.image = grayCheck
//        cell.friendPhoto.layer.borderWidth = 0
//        cell.friendName.textColor = lightGray
    }
    
    func startSearchController() {
        resultSearchController = UISearchController(searchResultsController: nil)
        resultSearchController.searchResultsUpdater = self
        resultSearchController.dimsBackgroundDuringPresentation = false
        resultSearchController.definesPresentationContext = true
        tableView.tableHeaderView = resultSearchController.searchBar
        resultSearchController.searchBar.tintColor = mainRed
        let textFieldInsideSearchBar = resultSearchController.searchBar.valueForKey("searchField") as? UITextField
        textFieldInsideSearchBar!.textColor = mainRed
        textFieldInsideSearchBar!.font = UIFont(name: "SFUIText-Regular", size: 15)
        textFieldInsideSearchBar!.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [NSForegroundColorAttributeName: lightGray])
        resultSearchController.searchBar.searchBarStyle = .Minimal
        resultSearchController.searchBar.tintColor = mainRed
        resultSearchController.searchBar.backgroundColor = UIColor.clearColor()
        resultSearchController.hidesNavigationBarDuringPresentation = false
        var myBounds = self.tableView.bounds
        myBounds.origin.y += self.resultSearchController.searchBar.frame.size.height
        self.tableView.bounds = myBounds
        resultSearchController.searchBar.sizeToFit()
        
        
        
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        if (parent == nil) {
            resultSearchController.active = false
            
        }
        
    }
    
    func exitView() {
//        navigationController?.popViewControllerAnimated(true)
//        dismissViewControllerAnimated(true, completion: { () -> Void in
//            
//        })
        //navigationController?.popToViewController(self, animated: true)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filteredArray.removeAll(keepCapacity: false)
        let arrayTeste = DataManager.sharedInstance.allFriends.filter({$0.username.lowercaseString.rangeOfString(searchController.searchBar.text!.lowercaseString) != nil})
        filteredArray = arrayTeste
        tableView.reloadData()
        
    }
    
    @IBAction func addUser(sender: AnyObject) {
        performSegueWithIdentifier("addFriend", sender: self)
        
    }

    
    @IBAction func timeSlider(sender: UISlider) {
        let currentValue = Int(sender.value)
        upSliderLabel.text = "\(currentValue) hours"
        until = "\(currentValue)"
        
        switch currentValue {
        case 0:
            chosenHour = 1
            chosenDay = chosenHour / 24
            upSliderLabel.text = "\(1) hour"
            upSliderLabel.textColor = mainRed
            upSliderLabel.fadeIn(0.5)
            downSlideLabel.fadeOut(0.5)
            break
        case 1:
            chosenHour = currentValue
            chosenDay = chosenHour / 24
            upSliderLabel.text = "\(chosenHour) hour"
            upSliderLabel.textColor = mainRed
            upSliderLabel.fadeIn(0.5)
            downSlideLabel.fadeOut(0.5)
            break
        case 2...23:
            chosenHour = currentValue
            chosenDay = chosenHour / 24
            upSliderLabel.text = "\(chosenHour) hours"
            upSliderLabel.textColor = mainRed
            upSliderLabel.fadeIn(0.5)
            downSlideLabel.fadeOut(0.5)
            break
        case 24...27:
            chosenHour = 24
            chosenDay = chosenHour / 24
            upSliderLabel.text = "\(chosenHour) hours"
            upSliderLabel.textColor = mainRed
            upSliderLabel.fadeIn(0.5)
            downSlideLabel.text = "\(chosenDay) day"
            downSlideLabel.fadeIn(0.5)
            break
        case 28...30:
            chosenHour = 48
            chosenDay = chosenHour / 24
            upSliderLabel.text = "\(chosenHour) hours"
            upSliderLabel.textColor = mainRed
            upSliderLabel.fadeIn(0.5)
            downSlideLabel.text = "\(chosenDay) days"
            downSlideLabel.fadeIn(0.5)
            break
        case 31...33:
            chosenHour = 72
            chosenDay = chosenHour / 24
            upSliderLabel.text = "\(chosenHour) hours"
            upSliderLabel.textColor = mainRed
            upSliderLabel.fadeIn(0.5)
            downSlideLabel.text = "\(chosenDay) days"
            downSlideLabel.fadeIn(0.5)
            break
        case 34...36:
            chosenHour = 96
            chosenDay = chosenHour / 24
            upSliderLabel.text = "\(chosenHour) hours"
            upSliderLabel.textColor = mainRed
            upSliderLabel.fadeIn(0.5)
            downSlideLabel.text = "\(chosenDay) days"
            downSlideLabel.fadeIn(0.5)
            break
        case 37...39:
            chosenHour = 120
            chosenDay = chosenHour / 24
            upSliderLabel.text = "\(chosenHour) hours"
            upSliderLabel.textColor = mainRed
            upSliderLabel.fadeIn(0.5)
            downSlideLabel.text = "\(chosenDay) days"
            downSlideLabel.fadeIn(0.5)
            break
        case 40...42:
            chosenHour = 144
            chosenDay = chosenHour / 24
            upSliderLabel.text = "\(chosenHour) hours"
            upSliderLabel.textColor = mainRed
            upSliderLabel.fadeIn(0.5)
            downSlideLabel.text = "\(chosenDay) days"
            downSlideLabel.fadeIn(0.5)
            break
        case 43...45:
            chosenHour = 168
            chosenDay = chosenHour / 24
            upSliderLabel.text = "\(chosenHour) hours"
            upSliderLabel.textColor = mainRed
            upSliderLabel.fadeIn(0.5)
            downSlideLabel.text = "\(chosenDay) days"
            downSlideLabel.fadeIn(0.5)
            break
        case 46...50:
            chosenHour = 0
            upSliderLabel.text = "\(168) hours"
            upSliderLabel.fadeOut(0.5)
            downSlideLabel.text = "Undetermined"
            downSlideLabel.fadeIn(0.5)
            break
        default:
            break
        }
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func continueAction () {
        
        if isCharm {
            if let index = selectedUserIndex {
                let myUser = DataManager.sharedInstance.myUser
                let selectedFriend = DataManager.sharedInstance.allFriends[index]
                http.createNewSharerWithType(.userToUser, ownerID: myUser.userID, receiverID: selectedFriend.userID, until: "\(150)", completion: { (result) -> Void in
                    self.navigationController?.popToRootViewControllerAnimated(true)
                })
//                http.createNewSharerWithType(.userToUser, ownerID: myUser.userID, receiverID: selectedFriend.userID, until: "\(30)", completion: { (result) -> Void in
//                    self.navigationController?.popToRootViewControllerAnimated(true)
//                })

            }
            else {
                DataManager.sharedInstance.createSimpleUIAlert(self, title: "Friend", message: "Select a friend to receive your Whistle", button1: "OK")
            }
        }
        else {
            if groupName.text?.isEmpty  == true {
                DataManager.sharedInstance.createSimpleUIAlert(self, title: "Group Name", message: "Please insert a name for this group", button1: "OK")
            } else if chosenHour == nil {
                DataManager.sharedInstance.createSimpleUIAlert(self, title: "Duration", message: "Please choose a duration for this group ", button1: "OK")
            }
            else {
                let groupNameText = groupName.text
                
                

                
                http.createNewGroupWithName("\(groupNameText!)", completion: { (result) -> Void in
                    
                    
                    
                    
                    
                    
                    let dic = result as NSDictionary
                    let id = dic["id"]
                    let formatId = "\(id!)"
                    //let hour = self.chosenHour
                    self.http.createNewSharerWithType(.userToGroup, ownerID: DataManager.sharedInstance.myUser.userID, receiverID: formatId, until: "\(self.chosenHour*3600)", completion: { (result) -> Void in
                        
                        let json = result
                        
                        let sharerID = json["id"]
                        
                        
                        self.http.updateSharerWithID("\(sharerID!)", until: nil, status: "accepted", completion: { (result) -> Void in
                        })
                        
                    })
                    
                    for user in DataManager.sharedInstance.selectedFriends {
                        let userId = user.userID
                        
                        self.http.createNewSharerWithType(.userToGroup, ownerID: "\(userId)", receiverID: formatId, until: "\(self.chosenHour*3600)", completion: { (result) -> Void in
                            
                        })
                       
                    }
                    
                    let group = Group()
                    group.id = formatId

                    
                    
                    DataManager.sharedInstance.activeGroup.append(group)
                    let activeGroup = DataManager.sharedInstance.activeGroup
                    
                    let dicio = DataManager.sharedInstance.convertGroupToNSDic(activeGroup)
                    
                    DataManager.sharedInstance.createJsonFile("activeGroups", json: dicio)
                    let idGroup = id as! Int
                    
                    for sharer in DataManager.sharedInstance.allSharers {
                        if sharer.receiver == "\(idGroup)" && sharer.owner == DataManager.sharedInstance.myUser.userID {
                            self.http.updateSharerWithID(sharer.id, until: nil, status: "accepted", completion: { (result) -> Void in
                            })
                        }
                    }
                    
                    
                    DataManager.sharedInstance.requestUsersInGroupId("\(idGroup)", completion: { (users) -> Void in
                        DataManager.sharedInstance.linkGroupAndUserToSharer({ (result) -> Void in
                            NSNotificationCenter.defaultCenter().postNotificationName("ExistGroup", object: nil)
                            self.navigationController?.popToRootViewControllerAnimated(true)
                            
                        })
                        
                        
                    })
                    
                    
                    
                })
                
                
            
            }
        }
        
        
        
    }

    override func viewWillDisappear(animated: Bool) {
        resultSearchController.searchBar.hidden = true
        
        
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



public extension UIView {
    

    
    func turnRed(color:UIColor, label:UILabel, duration:NSTimeInterval = 2){
        UIView.animateWithDuration(duration, animations: {
            label.textColor = color
            
        })
    }
}

