//
//  DataManager.swift
//  Holmies
//
//  Created by Leonardo Geus on 14/09/15.
//  Copyright (c) 2015 Leonardo Geus. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import MapKit
import Alamofire



class DataManager {
    var friendsArray:NSMutableArray!
    var end:[String]!
    var profilePictureOfFriendsArray:Array<UIImage>!
    var locationUserArray = [Location]()
    var allUser = [User]()
    var allGroup = [Group]()
    var activeGroup = [Group]()
    var friendsDictionaryFace:Dictionary<String,AnyObject>!
    var usersInGroups = [Dictionary<String,AnyObject>]()
    var activeUsers = [User]()
    var allFriends = [User]()
    var allSharers = [Sharer]()
    var myCharms = [Charm]()
    var lastCharms = [Charm]()
    var myUser = User()
    let http = HTTPHelper()
    var actualCell = 0
    var sharesInGroups = [[Sharer]]()
    var friendsInFace = [User]()
    
    var selectedFriends = [User]()
    var selectedGroup = Group()
    var selectedSharer = [Sharer]()
    
    var activeView = String()
    var isCharm = false
    
    var activeMap = GMSMapView?()
    
    var didUpdateCharms = false
    var isUpdating = false
    
    var finishedAllRequest = false
    
    
    var badgeNumber = 0
    
    var windows:UIViewController!
    let mainRed: UIColor = UIColor(red: 220.0/255.0, green: 32.0/255.0, blue: 63.0/255.0, alpha: 1)
    let lightBlue:UIColor = UIColor(red: 61.0/255.0, green: 210.0/255.0, blue: 228.0/255.0, alpha: 1)
    
    lazy var locationManager: CLLocationManager! = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.requestAlwaysAuthorization()
        manager.distanceFilter = 0.5
        return manager
    }()
    
    var timer = NSTimer()
    var timer2 = NSTimer()
    var timer3 = NSTimer()
    var appIsActive = true
    
    class var sharedInstance: DataManager {
        struct Static {
            static var instance: DataManager?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = DataManager()
        }
        
        return Static.instance!
    }
    
    func reverseGeocodeCoordinate(coordinate: CLLocationCoordinate2D) {   //transforma coordenadas em endereço
        let geocoder = GMSGeocoder()
        var lines:[String]!
        geocoder.reverseGeocodeCoordinate(coordinate) { response , error in
            if let address = response?.firstResult() {
                lines = address.lines as! [String]
                
                
                if lines != nil {
                    DataManager.sharedInstance.end = lines
                }
            }
        }
        
    }
    
    func createLocalNotification(title:String,body:String,timeAfterClose:NSTimeInterval,userInfo:NSDictionary) {
        let localNotification:UILocalNotification = UILocalNotification()
        localNotification.alertAction = title
        localNotification.alertBody = body
        localNotification.fireDate = NSDate(timeIntervalSinceNow: timeAfterClose)
        //localNotification.userInfo = userInfo as [NSObject : AnyObject]
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    func createLocalNotificationWithoutUserInfo(title:String,body:String) {
        let localNotification:UILocalNotification = UILocalNotification()
        localNotification.alertAction = title
        localNotification.alertBody = body
        localNotification.fireDate = NSDate(timeIntervalSinceNow: 1)
        //localNotification.userInfo = userInfo as [NSObject : AnyObject]
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    func findDocumentsDirectory() -> String {
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask, true)[0] as String
    }
    
    func readJsonFromBundle(nomeArquivo:String) -> NSDictionary {
        do {
            let path = NSBundle.mainBundle().pathForResource("\(nomeArquivo)", ofType: "json")
            let jsonData = NSData(contentsOfFile:path!)
            
            let jsonResult: NSDictionary = try NSJSONSerialization.JSONObjectWithData(jsonData!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            return jsonResult
        }
        catch let error {
            print("\(error)")
            let dic = [ "nil":["nil"]] as NSDictionary
            return dic
        }
    }
    
    func readJsonFromDocuments(nomeArquivo:String) -> NSDictionary {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask, true)[0] as String
            let jsonData = NSData(contentsOfFile:path)
            
            let jsonResult: NSDictionary = try NSJSONSerialization.JSONObjectWithData(jsonData!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            return jsonResult
        }
        catch let error {
            print("\(error)")
            let dic = [ "nil":["nil"]] as NSDictionary
            return dic
        }
    }
    
    func testIfFileExistInDocuments (name:String) -> Bool{
        let docs = findDocumentsDirectory()
        let destinationPath = docs.stringByAppendingString("\(name)")
        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(destinationPath) {
            return true
        }
        else {
            return false
        }
    }
    
    func moveJsonFromDocumentsToBundle(nomeArquivo:String) {
        do {
            let fileManager = NSFileManager.defaultManager()
            
            let documentsDirectory = findDocumentsDirectory()
            let destinationPath = documentsDirectory.stringByAppendingString("\(nomeArquivo).json")
            
            if fileManager.fileExistsAtPath(destinationPath) {
                return
            }
            let sourcePath = (NSBundle.mainBundle().resourcePath)?.stringByAppendingString("\(nomeArquivo).json")
            try fileManager.copyItemAtPath(sourcePath!, toPath: destinationPath) }
        catch let error {
            print("\(error)")
            
            return
        }
    }
    
    func actualTime() -> String{
        let currDate = NSDate()
        let dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy  hh:mm"
        let dateString = dateFormatter.stringFromDate(currDate) as String
        
        return dateString
        
        
    }
    
    func requestFacebook(view:UIViewController,completion:(result:NSMutableArray)->Void) {
        let friendRequest = FBSDKGraphRequest(graphPath: "/me/friends", parameters: nil)
        friendRequest.startWithCompletionHandler{ (connection: FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            if error == nil {
                self.friendsDictionaryFace = result as! Dictionary<String,AnyObject>
                if let friends = self.friendsDictionaryFace["data"] as? NSMutableArray{
                    DataManager.sharedInstance.friendsArray = friends
                    
                    for friend in DataManager.sharedInstance.friendsArray {
                        let id = friend["id"] as! String
                        self.http.signInWithFacebookID(id, completion: { (result) -> Void in
                            let json = result
                            
                            if json["error"] != nil {
                                DataManager.sharedInstance.createSimpleUIAlert(view, title: "Error", message: json["error"] as! String, button1: "OK")
                                print("Nao Localizado")
                            }
                            
                            else {
                                let user = DataManager.sharedInstance.convertJsonToUserUnique(json)
                                DataManager.sharedInstance.friendsInFace.append(user)
                                
                                var alreadyFriend = false
                                
                                for friend in DataManager.sharedInstance.allFriends {
                                    if friend.userID == user.userID {
                                        alreadyFriend = true
                                        break
                                    }
                                    
                                }
                                
                                if !alreadyFriend {
                                    
                                    DataManager.sharedInstance.allFriends.append(user)
                                    let userdic = DataManager.sharedInstance.convertUserToNSDic(DataManager.sharedInstance.allFriends)
                                    DataManager.sharedInstance.createJsonFile("friends", json: userdic)
                                    
                                }
                                    
                            }
                            
                            
                        })
                    }
                    
                    
                    
                    
                    completion(result: self.friendsArray)
                }
                
                
            }
            else {
                print("\(error)")
            }
        }
        
        
    }
    
    func saveImage(image:UIImage?, id:String) -> String {
        if let _ = image {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
            let destinationPath = documentsPath.stringByAppendingString("/\(id).jpg")
            UIImageJPEGRepresentation(image!,1.0)!.writeToFile(destinationPath, atomically: true)
            
            
            return destinationPath }
        else {
            return ""
        }
    }
    
    func getProfPic(fid: String, serverId:String) -> UIImage? {
        let fileManager = NSFileManager.defaultManager()
        let documentsDirectory = findDocumentsDirectory()
        let destinationPath = documentsDirectory.stringByAppendingString("/\(serverId).jpg")
        var fbImage:UIImage!
        
        var myuser1 = String()
        if let myUser = myUser.facebookID {
            myuser1 = myUser
        }
        else {
            myuser1 = "0"
        }
        
        if !(fileManager.fileExistsAtPath(destinationPath)) {
            if (fid != "") {
                let imgURLString:String!
                if (fid == myuser1) {
                    imgURLString = "http://graph.facebook.com/" + fid + "/picture?height=960" //type=normal
                    
                }else{
                    imgURLString = "http://graph.facebook.com/" + fid + "/picture?type=large" //type=normal
                }
                
                let imgURL = NSURL(string: imgURLString)
                let imageData = NSData(contentsOfURL: imgURL!)
                fbImage = UIImage(data: imageData!)
                
                return fbImage
            }
            
            return nil
        }
        return nil
    }
    
    func findImage(id:String) -> UIImage {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let destinationPath = documentsPath.stringByAppendingString("/\(id).jpg")
        if testIfFileExistInDocuments("/\(id).jpg") == true {
            let image = UIImage(contentsOfFile: destinationPath)
            return image!
        }
        else {
            if id == DataManager.sharedInstance.myUser.userID {
                return UIImage(named: "whiteChar.png")!
            }
            
            else {
            
            return UIImage(named: "mainRedChar.png")!
            }
        }
        
        
    }
    
    func convertDicionaryToJson(dic:[Location],nomeArq:String) -> String {
        
        
        var array = Array<Dictionary<String,String>>()
        
        for var i = 0 ; i < (friendsArray.count-1) ; i++ {
            let time = DataManager.sharedInstance.locationUserArray[i].location.timestamp
            let coord = DataManager.sharedInstance.locationUserArray[i].location.coordinate
            let lat = coord.latitude
            let long = coord.longitude
            
            let address = DataManager.sharedInstance.locationUserArray[i].address
            
            
            let dicMod = ["tempo":"\(time)","lat":"\(lat)","long":"\(long)","address":"\(address)"]
            
            array.append(dicMod)
            
            
        }
        
        let documents = findDocumentsDirectory()
        let path = documents.stringByAppendingString("/\(nomeArq).json")
        
        let outputStream = NSOutputStream(toFileAtPath: path, append: true)
        outputStream?.open()
        NSJSONSerialization.writeJSONObject(array, toStream: outputStream!, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
        outputStream?.close()
        
        
        return path
        
    }
    
    
    func createJsonFile(name:String,json:AnyObject) {
        
        print("inicio\(name)")
        let documents = DataManager.sharedInstance.findDocumentsDirectory()
        let path = documents.stringByAppendingString("/\(name).json")
        
        if name == "myInfo" {
            let date = NSDate()
            let formatter = NSDateFormatter()
            formatter.timeStyle = .ShortStyle
            formatter.stringFromDate(date)
            let lat = json["latitude"]
            let long = json["longitude"]
            let time = "\(date)"
            let dicMod:NSDictionary!
            if let address = DataManager.sharedInstance.end {
                dicMod = ["tempo":"\(time)","lat":"\(lat!!)","long":"\(long!!)","address":"\(address)"]
            }
            else {
                dicMod = ["tempo":"\(time)","lat":"\(lat!!)","long":"\(long!!)"]}
            let pathAppend = documents.stringByAppendingString("/\(name)log.json")
            print("Arquivo com suas informacoes criado ou atualizado - pode ser atualizacao de coordenadas")
            let outputStream = NSOutputStream(toFileAtPath: pathAppend, append: true)
            outputStream?.open()
            NSJSONSerialization.writeJSONObject(dicMod, toStream: outputStream!, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
            outputStream?.close()
            
        } else {
            print("Arquivo com nome: \(name) criado")
        }
        
        let outputStream = NSOutputStream(toFileAtPath: path, append: false)
        outputStream?.open()
        NSJSONSerialization.writeJSONObject(json, toStream: outputStream!, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
        outputStream?.close()
        print("fim\(name)")
    }
    
    func loadJsonFromDocuments(nomeArq:String) -> AnyObject {
        let documents = findDocumentsDirectory()
        let path = documents.stringByAppendingString("/\(nomeArq).json")
        print("Arquivo \(nomeArq) carregado do Docs")
        do {
            let data = try NSData(contentsOfFile: path, options: .DataReadingUncached)
            
            do {
                let parse = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)
                return parse
                
                
            }
            catch let error {
                print(error)
                
            }
            
            
            
            
        }
        catch _ {
        }
        return []
        
    }
    
    
    
    func convertJsonToUser(json:AnyObject) -> [User] {
        var userArray = [User]()
        if let dic = json as? [NSDictionary] {
            for user in dic {
                let newUser = User()
                newUser.altitude = user["altitude"] as? String
                newUser.createdAt = user["created_at"] as? String
                newUser.email = user["email"] as? String
                newUser.facebookID = user["fbid"] as? String
                let id = user["id"]
                if id != nil {
                    newUser.userID = "\(id!)"
                    if let locationString = user["location"] as? String {
                        if locationString.containsString(":") {
                            let locationArray = locationString.componentsSeparatedByString(":") as [String]
                            newUser.location.latitude = locationArray[0]
                            newUser.location.longitude = locationArray[1]
                        }
                    }
                    
                    
                    newUser.name = user["name"] as? String
                    newUser.password = user["password"] as? String
                    newUser.photo = user["photo"] as? String
                    newUser.updatedAt = user["updated_at"] as? String
                    newUser.username = user["username"] as? String
                    userArray.append(newUser)
                }
            }
            
        }
        
        return userArray
    }
    
    
    func convertJsonToUserUnique(json:AnyObject) -> User {
        let newUser = User()
        if let dic = json as? NSDictionary {
            let id = dic["id"]
            
            
            
            newUser.userID = "\(id!)"
            
            newUser.altitude = dic["altitude"] as? String
            newUser.createdAt = dic["created_at"] as? String
            newUser.email = dic["email"] as? String
            newUser.facebookID = dic["fbid"] as? String

            if let locationString = dic["location"] as? String {
                if locationString.containsString(":") {
                    let locationArray = locationString.componentsSeparatedByString(":") as [String]
                    newUser.location.latitude = locationArray[0]
                    newUser.location.longitude = locationArray[1]
                }
            }
            
            
            newUser.name = dic["name"] as? String
            newUser.password = dic["password"] as? String
            newUser.photo = dic["photo"] as? String
            newUser.updatedAt = dic["updated_at"] as? String
            newUser.username = dic["username"] as? String
            
        }
        
        return newUser
    }
    
    
    func convertJsonToGroup(json:AnyObject) -> [Group] {
        var groupDic = [Group]()
        if let dic = json as? [NSDictionary] {
            for group in dic {
                let newGroup = Group()
                newGroup.createdAt = group["created_at"] as? String
                let id = group["id"]
                newGroup.id = "\(id!)"
                newGroup.name = group["name"] as? String
                newGroup.photo = group["photo"] as? String
                newGroup.updateAt = group["updateAt"] as? String
                
                
                groupDic.append(newGroup)
            }
            
        }
        return groupDic
        
    }
    
    func importID()
    {
        let file = "/id.txt"
        
        let dirs: [String]? = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true) as [String]
        
        if (dirs != nil)
        {
            let directories:[String] = dirs!
            let dirs = directories[0]; //documents directory
            let path = dirs.stringByAppendingString(file)
            
            var text:String!
            do{
                let text2 = try String(contentsOfFile: path, encoding:NSUTF8StringEncoding)
                if text2 == "nil" {
                    //saveID()
                }
                else {
                    text = text2
                    DataManager.sharedInstance.myUser.userID = text!
                }
            }
            catch let error {
                if !(text == nil) {
                    saveID()}
                print(error)
            }
            
            
        }
    }
    
    func saveID ()
    {
        let file = "/id.txt"
        
        let dirs: [String]? = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true) as [String]
        
        if (dirs != nil)
        {
            let directories:[String] = dirs!
            let dirs = directories[0]; //documents directory
            let path = dirs.stringByAppendingString(file)
            let text = DataManager.sharedInstance.myUser.userID
            
            //writing
            do {
                try text.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding) }
            catch _ {}
        }
    }
    
    func updateLocationUsers(mapView:GMSMapView) {
        mapView.clear()
        for user in activeUsers {
            var actualSharer = Sharer()
            
            if isCharm {
                actualSharer = selectedSharer[0]
            }
            else {
                for sharer in DataManager.sharedInstance.selectedSharer {
                    if user.userID == sharer.owner {
                        actualSharer = sharer
                        break
                    }
                }
            }
            
            if actualSharer.status != nil {
            if actualSharer.status == "accepted" || actualSharer.status == "active" {
                let name = user.name
                let lat = user.location.latitude
                let long = user.location.longitude
                let date = user.updatedAt
                if lat != "" {
                
                
                
                    let latitudeConvertida = (lat as NSString).doubleValue as CLLocationDegrees
                    let longitudeConvertida = (long as NSString).doubleValue as CLLocationDegrees
                    let position = CLLocationCoordinate2D(latitude: latitudeConvertida, longitude: longitudeConvertida)
                    let marker = GMSMarker(position: position)
                    marker.title = name
                    marker.snippet = date
                    marker.icon = GMSMarker.markerImageWithColor(UIColor.blueColor())
                    marker.infoWindowAnchor = CGPointMake(0.5, 0.5)
                    marker.map = mapView
                    marker.userData = user
                    
                    
                    let topImage = findImage(user.userID)
                    let topImageView = UIImageView(image: topImage)
                    let bottomImage = UIImage(named: "pin2.png")
                    topImageView.bounds.size = CGSizeMake(120, 120)
                    topImageView.layer.cornerRadius = 60
                    topImageView.clipsToBounds = true
                    let newSize = CGSizeMake((bottomImage!.size.width), (bottomImage!.size.height))
                    UIGraphicsBeginImageContext(newSize)
                    bottomImage!.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
                    UIGraphicsBeginImageContextWithOptions(topImageView.bounds.size, topImageView.opaque, 0.0)
                    topImageView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
                    let ui2 = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    ui2.drawAtPoint(CGPointMake(12,15), blendMode: CGBlendMode.Normal, alpha: 1.0)
                    let newImage = UIGraphicsGetImageFromCurrentImageContext()
                    let resizedImage = imageResize(newImage, sizeChange: CGSizeMake(60,80.625))
                    marker.icon = resizedImage
                }
                else {
                    createSimpleUIAlert(windows, title: "Not Found", message: "\(user.name) couldn't be located", button1: "OK")
                }
                }
            }
        }
    }
    
    
    func imageResize(image:UIImage, sizeChange:CGSize) -> UIImage {
        
        UIGraphicsBeginImageContext(sizeChange)
        image.drawInRect(CGRectMake(0, 0, sizeChange.width, sizeChange.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    
    
    func requestGroups (completion:(result:[NSDictionary])->Void) {
        let id = DataManager.sharedInstance.myUser.userID
        http.getInfoFromID(DataManager.sharedInstance.myUser.userID, desiredInfo: .userReceiverGroups) { (result) -> Void in
            let JSON = result
            self.usersInGroups.removeAll()
            DataManager.sharedInstance.createJsonFile("groups", json: JSON)
            DataManager.sharedInstance.convertJsonToGroup(JSON)
            for group in DataManager.sharedInstance.allGroup {
                let id = group.id
                self.requestUsersInGroupId(id, completion: { (users) -> Void in
                    group.users = users
                })
            }
            completion(result: JSON)
           // print(JSON)
            //            } else {
            //                let dic = DataManager.sharedInstance.loadJsonFromDocuments("groups")
            //                DataManager.sharedInstance.convertJsonToGroup(dic)
            //            }
            
        }
        
        
        
        
        //
        //        Alamofire.request(.GET, "https://tranquil-coast-5554.herokuapp.com/users/\(DataManager.sharedInstance.idUser)/get_user_receiver_groups").responseJSON { response in
        //            if let JSON = response.result.value {
        //                self.usersInGroups.removeAll()
        //                DataManager.sharedInstance.createJsonFile("groups", json: JSON)
        //                DataManager.sharedInstance.convertJsonToGroup(JSON)
        //                for index in DataManager.sharedInstance.allGroup {
        //                    let id = index.id
        //                    self.requestUsersInGroupId(id)
        //                }
        //                print(self.usersInGroups)
        //            } else {
        //                let dic = DataManager.sharedInstance.loadJsonFromDocuments("groups")
        //                DataManager.sharedInstance.convertJsonToGroup(dic)
        //            }
        //        }
    }
    
    func requestUsersInGroupId(groupId:String,completion:(users:[User]) -> Void) {
        http.getInfoFromID(groupId, desiredInfo: .groupSenderUsers) { (result) -> Void in
            
            
            //DataManager.sharedInstance.createJsonFile("users\(groupId)", json: result)
            var users = DataManager.sharedInstance.convertJsonToUser(result)
            let usersDic = DataManager.sharedInstance.convertUserToNSDic(users)
            
            DataManager.sharedInstance.createJsonFile("users\(groupId)", json: usersDic)
            var num = 0
            for group in DataManager.sharedInstance.allGroup {
                if group.id == groupId {
                    
                    
                    
                    //retira eu da lista de users dos grupos
                    var i = 0
                    for user in users {
                        if user.userID == DataManager.sharedInstance.myUser.userID {
                            users.removeAtIndex(i)
                            break
                        }
                        i++
                    }
                    
                    
                    DataManager.sharedInstance.allGroup[num].users = users
                    if DataManager.sharedInstance.allGroup[num].users.count < 1 {
                        self.destroyGroupWithGroup(DataManager.sharedInstance.allGroup[num])
                    }
                }
                num++
            }
            
            
            
            //            self.testIfGroupIsEmpty({ (result) -> Void in
            //                //completion do grupo apagado
            var userForTest = [User()]
            let user1 = User()
            
            user1.name = "Test"
            userForTest.append(user1)
            completion(users: userForTest)
            //            })
        }
        
    }
    
    func createSimpleUIAlert (view:UIViewController,title:String,message:String,button1:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: button1, style: UIAlertActionStyle.Default, handler: nil))
        view.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    func shakeTextField (textField:UITextField) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue = NSValue(CGPoint: CGPointMake(textField.center.x - 10, textField.center.y))
        animation.toValue = NSValue(CGPoint: CGPointMake(textField.center.x + 10, textField.center.y))
        textField.layer.addAnimation(animation, forKey: "position")
    }
    
    
    func removeUserFromGroupInBackEnd(groupId:String,completion:(result:String) -> Void) {
        print("fazer aqui o delete do user em servidor")
        requestGroups { (result) -> Void in
            print("fez request do grupos após remover user")
            completion(result: "terminou")
        }
    }
    
    func convertGroupToNSDic (groupClass:[Group]) -> [Dictionary<String,AnyObject>] {
        var groupDic = [Dictionary<String,AnyObject>]()
        for oneGroup in groupClass {
            var circle = Dictionary<String,AnyObject>()
            circle["id"] = oneGroup.id
            circle["name"] = oneGroup.name
            circle["updated_at"] = oneGroup.updateAt
            circle["created_at"] = oneGroup.createdAt
            circle["photo"] = oneGroup.photo
            groupDic.append(circle)
        }
        return groupDic
    }
    
    func convertUserToNSDic (userClass:[User]) -> [Dictionary<String,AnyObject>] {
        var userDic = [Dictionary<String,AnyObject>]()
        for user in userClass {
            var people = Dictionary<String,AnyObject>()
            people["altitude"] = user.altitude
            people["createdAt"] = user.createdAt
            people["email"] = user.email
            people["fbid"] = user.facebookID
            people["id"] = user.userID
            
            people["name"] = user.name
            people["photo"] = user.photo
            people["updatedAt"] = user.updatedAt
            people["username"] = user.username
            userDic.append(people)
        }
        return userDic
    }
    
    func testIfGroupIsEmpty(completion:(result:String)->Void) {
        for group in DataManager.sharedInstance.allGroup {
            //            let groupq = group
            //            let usersInGroups = (group["users"] as! NSArray).count
            
            let users = group.users
            let id = group.id
            
            if users.count < 1 {
                destroyGroupWithGroup(group)
                completion(result: "\(id)")
            }
        }
    }
    
    func destroyGroupWithNotification(groupObject:Group,view:UIViewController) {
        let idGroup = groupObject.id
        createSimpleUIAlert(view, title: "Group Destroy", message: "The group \(groupObject.name) has been destroyed", button1: "OK")
        http.destroyGroupWithID(idGroup) { (result) -> Void in
            print("apagado grupo \(idGroup)")
        }
    }
    
    func destroySharerWithNotification(group:Group,view:UIViewController) {
        createSimpleUIAlert(view, title: "Removed", message: "You're not sharing with \(group.name) anymore", button1: "OK")
        self.http.destroySharerWithSharerType(.userToGroup, ownerID: DataManager.sharedInstance.myUser.userID, receiverID: group.id, completion: { (result) -> Void in
            
        })
    
    }
    
    func destroyGroupWithGroup(groupObject:Group) {
        let idGroup = groupObject.id
        
        http.destroyGroupWithID(idGroup) { (result) -> Void in
            print("apagado grupo \(idGroup)")
        }
    }
    
    func randomStringWithLength (len : Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        for (var i=0; i < len; i++){
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString
    }
    
    func requestSharers(completion:(result:String)->Void){
        var completedFirst = false
        let id = DataManager.sharedInstance.myUser.userID
        var sharersArray = DataManager.sharedInstance.allSharers
        sharersArray.removeAll()
        http.getInfoFromID(id, desiredInfo: .userSenderSharers) { (result) -> Void in
            let json = result
            DataManager.sharedInstance.createJsonFile("sharers", json: json)
            
            //            DataManager.sharedInstance.allSharers = self.convertJsonToSharer(json)
            let senderSharers = self.convertJsonToSharer(json)
            sharersArray = sharersArray + senderSharers
            if completedFirst {
                DataManager.sharedInstance.allSharers = sharersArray
                DataManager.sharedInstance.myCharms = self.selectCharmsFromSharersArray(DataManager.sharedInstance.allSharers)
                NSNotificationCenter.defaultCenter().postNotificationName("delegateUpdate", object: nil)
                completion(result: "DEU")
            }
            else {
                completedFirst = true
            }
            
        }
        http.getInfoFromID(id, desiredInfo: HTTPHelper.DesiredInfo.userReceiverSharers) { (result) -> Void in
            let json = result
            DataManager.sharedInstance.createJsonFile("receiverSharers", json: json)
            
            //            DataManager.sharedInstance.allSharers = self.convertJsonToSharer(json)
            let receiverSharers = self.convertJsonToSharer(json)
            sharersArray = sharersArray + receiverSharers
            if completedFirst {
                DataManager.sharedInstance.allSharers = sharersArray
                DataManager.sharedInstance.myCharms = self.selectCharmsFromSharersArray(DataManager.sharedInstance.allSharers)
                completion(result: "DEU")
            }
            else {
                completedFirst = true
            }
        }
    }
    
    func convertJsonToSharer(json:AnyObject) -> [Sharer] {
        var sharers = [Sharer]()
        if let dic = json as? [NSDictionary] {
            //print(dic)

            if dic.count != 0 {
                if dic[0]["error"] != nil {
                    
                    print("erro")
                }
                else {
                    for sharer in dic {
                        let newSharer = Sharer()
                        newSharer.createdAt = sharer["created_at"] as? String
                        let id = sharer["id"] as! Int
                        
                        newSharer.id = "\(id)"
                        newSharer.until = sharer["until"] as? String
                        if sharer["relation"] as? String == "u2u" {
                            newSharer.relation = .userToUser
                            let receiverId = sharer["receiver_user_id"]
                            let receiverIdFormat = "\(receiverId!)"
                            newSharer.receiver = receiverIdFormat
                        }
                        else if sharer["relation"] as? String == "u2g" {
                            newSharer.relation = .userToGroup
                            let receiverId = sharer["receiver_group_id"]
                            let receiverIdFormat = "\(receiverId!)"
                            newSharer.receiver = receiverIdFormat
                        }
                        
                        newSharer.updatedAt = sharer["updated_at"] as? String
                        newSharer.updater = sharer["last_updater"] as? String
                        let ownerId = sharer["owner_user_id"]
                        let ownerIdFormat = "\(ownerId!)"
                        newSharer.owner = ownerIdFormat
                        if let status = sharer["status"] {
                            let statusString  = status as! String
                            newSharer.status = statusString
                        }
                        
                        
                        
                        sharers.append(newSharer)
                    }
                }
            
            }
        }
        return sharers
    }
    
    func convertJsonToSharerUnique(json:AnyObject) -> Sharer {
        let newSharer = Sharer()
        if let dic = json as? NSDictionary {
            
            newSharer.createdAt = dic["created_at"] as? String
            let id = dic["id"] as! Int
            
            newSharer.id = "\(id)"
            newSharer.until = dic["until"] as? String
            if dic["relation"] as? String == "u2u" {
                newSharer.relation = .userToUser
            }
            else if dic["relation"] as? String == "u2g" {
                newSharer.relation = .userToGroup
            }
            
            newSharer.updatedAt = dic["updated_at"] as? String
            newSharer.status = dic["sharer"] as? String
            // newSharer.owner = //
            let receiverId = dic["receiver_group_id"]
            let receiverIdFormat = "\(receiverId!)"
            newSharer.receiver = receiverIdFormat
            newSharer.owner = dic["owner_user_id"] as? String
            let ownerId = dic["owner_user_id"]
            let ownerIdFormat = "\(ownerId!)"
            newSharer.owner = ownerIdFormat
            
            let status = dic["status"]
            newSharer.status = status as? String
        }
        
        
        return newSharer
    }
    
    
    
    
    //    func findUntilBETA () {
    //        for sharer in DataManager.sharedInstance.allSharers {
    //            for group in DataManager.sharedInstance.allGroup {
    //                if sharer.receiver == group.id {
    //                    group.until = sharer.until
    //                    group.createdAt = sharer.createdAt
    //                }
    //            }
    //        }
    //    }
    
    
    //    func linkSharerToGroup () {
    //        for sharer in DataManager.sharedInstance.allSharers {
    //            if sharer.relation == SharerType.userToGroup {
    //                for group in DataManager.sharedInstance.allGroup {
    //                    if sharer.receiver == group.id {
    //                        group.share = sharer
    //                        group.createdAt = sharer.createdAt
    //                    }
    //                }
    //            }
    //        }
    //    }
    
    func linkGroupAndUserToSharer (completion:(result:String)->Void) {
        if DataManager.sharedInstance.allSharers.count == 0 {
            completion(result: "FAIL, nenhum sharer no array")
        }
        else {
            for sharer in DataManager.sharedInstance.allSharers {
                if sharer.relation == SharerType.userToGroup {
                    for group in DataManager.sharedInstance.allGroup {
                        
                        if sharer.receiver == group.id {
                            sharer.receiverObject = group
                            group.share = sharer
                            
                            let fileManager = NSFileManager.defaultManager()
                            
                            let documentsDirectory = findDocumentsDirectory()
                            let destinationPath = documentsDirectory.stringByAppendingString("/users\(group.id).json")
                            
                            if fileManager.fileExistsAtPath(destinationPath) {
                                
                                let userInGroup = loadJsonFromDocuments("users\(group.id)")
                                var userInGroupUSER = convertJsonToUser(userInGroup)
                                var i = 0
                                for user in userInGroupUSER {
                                    if user.userID == DataManager.sharedInstance.myUser.userID {
                                        userInGroupUSER.removeAtIndex(i)
                                        break
                                    }
                                    i++
                                }
                                group.users = userInGroupUSER
                                
                                
                            }
                            
                            
                            
                            
                        }
                    }
                }
                //else if sharer.relation == SharerType.userToUser {
                //ainda nao tem
                //}
                
            }
            sortGroupArray()
            
            verifyIfGroupIsActive()
            
            

            
            
            completion(result: "Linkou tudo")
            
        
        }
    }
    
    func verifyIfGroupIsActive() {
        var groupisActive = false
        for group in DataManager.sharedInstance.allGroup {
            if group.share != nil {
                if group.share.status == "accepted" {
                    for active in DataManager.sharedInstance.activeGroup {
                        if group == active {
                            groupisActive = true
                        }
                    }
                    if !groupisActive {
                        DataManager.sharedInstance.activeGroup.append(group)
                        let activeGroup = DataManager.sharedInstance.activeGroup
                        let dicio = DataManager.sharedInstance.convertGroupToNSDic(activeGroup)
                        DataManager.sharedInstance.createJsonFile("activeGroups", json: dicio)
                        
                        
                    }
                    groupisActive = false
                }
            }
        }
    }
    
    func saveMyInfo () {
        let myInfo = DataManager.sharedInstance.myUser
        var people = Dictionary<String,AnyObject>()
        people["altitude"] = myInfo.altitude
        people["createdAt"] = myInfo.createdAt
        people["email"] = myInfo.email
        people["fbid"] = myInfo.facebookID
        people["userID"] = myInfo.userID
        people["name"] = myInfo.name
        people["photo"] = myInfo.photo
        people["updatedAt"] = myInfo.updatedAt
        people["username"] = myInfo.username
        people["latitude"] = myInfo.location.latitude
        people["longitude"] = myInfo.location.longitude
        createJsonFile("myInfo", json: people)
    }
    
    func loadMyInfo () {
        let json = loadJsonFromDocuments("myInfo")
        if let dic = json as? NSDictionary {
            let myInfo = User()
            myInfo.altitude = dic["altitude"] as? String
            myInfo.createdAt = dic["createdAt"] as? String
            myInfo.email = dic["email"] as? String
            myInfo.facebookID = dic["fbid"] as? String
            myInfo.userID = dic["userID"] as? String
            myInfo.name = dic["name"] as? String
            myInfo.photo = dic["photo"] as? String
            myInfo.updatedAt = dic["updatedAt"] as? String
            myInfo.username = dic["username"] as? String
            let lat = dic["latitude"] as? String
            let long = dic["longitude"] as? String
            myInfo.location.latitude = "\(lat)"
            myInfo.location.longitude = "\(long)"
            DataManager.sharedInstance.myUser = myInfo
        }
    }
    

    
    //    func updateFriends () {
    //        Alamofire.request(.GET, "https://tranquil-coast-5554.herokuapp.com/users/lista").responseJSON { response in
    //            if let JSON = response.result.value {
    //                DataManager.sharedInstance.createJsonFile("users", json: JSON)
    //                DataManager.sharedInstance.allUser = DataManager.sharedInstance.convertJsonToUser(JSON)
    //                for index in DataManager.sharedInstance.allUser {
    //                    let faceId = index.facebookID
    //                    let id = "\(index.userID!)"
    //                    if !(faceId == nil) {
    //                        let image = DataManager.sharedInstance.getProfPic(faceId, serverId: id)
    //                        DataManager.sharedInstance.saveImage(image, id: id)
    //                    }
    //                }
    //                DataManager.sharedInstance.updateLocationUsers(self.mapView)
    //                self.controlNet.alpha = 0
    
    //                self.controlNet.enabled = false
    //            } else {
    //                let dic = DataManager.sharedInstance.loadJsonFromDocuments("users")
    //                DataManager.sharedInstance.allUser = DataManager.sharedInstance.convertJsonToUser(dic)
    //                DataManager.sharedInstance.updateLocationUsers(self.mapView)
    //                self.controlNet.alpha = 1
    //                self.controlNet.enabled = true
    //
    //            }
    //        }
    //        //DataManager.sharedInstance.requestGroups()
    //    }
    
    
    func requestSharerInGroups() {
        DataManager.sharedInstance.sharesInGroups.removeAll()
        print(DataManager.sharedInstance.sharesInGroups.count)
        for group in DataManager.sharedInstance.allGroup {
            self.http.getInfoFromID(group.id, desiredInfo: .groupReceiverSharers, completion: { (result) -> Void in
                let json = result
                DataManager.sharedInstance.createJsonFile("sharers\(group.id)", json: json)
                let sharerServer = DataManager.sharedInstance.convertJsonToSharer(json)
                DataManager.sharedInstance.sharesInGroups.append(sharerServer)
                print(DataManager.sharedInstance.sharesInGroups.count)
            })
        }
    }
    
    
    func saveSharersInGroup() {
        
        
        for sharers in DataManager.sharedInstance.sharesInGroups {
            for share in sharers {
                var groupSharer = Dictionary<String,AnyObject>()
                groupSharer["owner"] = share.owner
                groupSharer["receiver"] = share.receiver
                groupSharer["status"] = share.status
                groupSharer["updatedAt"] = share.updatedAt
                groupSharer["until"] = share.until
                groupSharer["createdAt"] = share.createdAt
                
            }
        }
    }
    
    func selectCharmsFromSharersArray(sharersArray:[Sharer]) -> [Charm] {
        var charmsArray = [Charm]()
        for sharer in sharersArray {
            if sharer.relation == SharerType.userToUser {
                //                charmsArray.append(sharer)
                for friend in allFriends {
                    if sharer.owner == friend.userID || sharer.receiver == friend.userID {
                        let newCharm = Charm()
                        newCharm.friend = friend
                        newCharm.sharer = sharer
                        charmsArray.append(newCharm)
                    }
                }
            }
        }
        DataManager.sharedInstance.didUpdateCharms = true
        return charmsArray
    }
    
    func sortGroupArray() {
        var i = 0
        
        for group in DataManager.sharedInstance.allGroup {
            for activeGroup in DataManager.sharedInstance.activeGroup {
                if group.id == activeGroup.id {
                    let oldGroup = group
                    DataManager.sharedInstance.allGroup.removeAtIndex(i)
                    DataManager.sharedInstance.allGroup.insert(oldGroup, atIndex: 0)
                    break
                }
            }
            i++
        }

        DataManager.sharedInstance.allGroup = DataManager.sharedInstance.allGroup.reverse()
        DataManager.sharedInstance.allGroup = DataManager.sharedInstance.allGroup.reverse()
        
        
        i = 0
        for group in DataManager.sharedInstance.allGroup {
            if group.share != nil {
                let createdHour = group.createdAt
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
                dateFormatter.timeZone = NSTimeZone(name: "UTC")
                let date = dateFormatter.dateFromString(createdHour)
                let durationString = group.share.until
                if !(durationString == "0") {
                    let durationFloat = Float(durationString)
                    let finalDate = date?.dateByAddingTimeInterval(NSTimeInterval(durationFloat!))
                    
                    
                    let duration = finalDate?.timeIntervalSinceNow
                    if duration < 0 {
                        let oldGroup = group
                        DataManager.sharedInstance.allGroup.removeAtIndex(i)
                        DataManager.sharedInstance.allGroup.insert(oldGroup, atIndex: 0)
                    }
                    
                    
                }
            }
            i++
        }
        

        DataManager.sharedInstance.allGroup = DataManager.sharedInstance.allGroup.reverse()
        
        
    }
    
    func loadSharerInAGroupFromDocuments(groupId:String) -> [Sharer]{
        let sharersUniqueJson = DataManager.sharedInstance.loadJsonFromDocuments("sharers\(groupId)")
        let sharerUnique = DataManager.sharedInstance.convertJsonToSharer(sharersUniqueJson)
        return sharerUnique
    
    }
    
    func findStatusOfUserInGroup(userId:String,groupId:String) -> String {
        let json = loadJsonFromDocuments("sharers\(groupId)")
        let sharers  = convertJsonToSharer(json)
        var status = ""
        for sharer in sharers {
            if userId == sharer.owner {
                status = sharer.status
                break
            }
        }
        if status == "" {
            status = "unexisting"
        }
        return status
        
    }
    
    func verifySharerStatus(sharer:Sharer) -> Int? {
        let createdHour = sharer.createdAt
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        let date = dateFormatter.dateFromString(createdHour)
        let durationString = sharer.until
        if !(durationString == "0") {
            let durationFloat = Float(durationString)
            let finalDate = date?.dateByAddingTimeInterval(NSTimeInterval(durationFloat!))
            
            
            if let duration = finalDate?.timeIntervalSinceNow {
                return Int(duration)
            }


            
            
        }
        return nil

    }
    
    func updateActiveFriendLocation() {
        let friend = DataManager.sharedInstance.activeUsers[0]
        http.findFriendWithUsername(friend.username) { (result) -> Void in
            let newFriend = DataManager.sharedInstance.convertJsonToUserUnique(result)
            DataManager.sharedInstance.activeUsers[0] = newFriend
            
            if let map = self.activeMap {
                self.updateLocationUsers(map)
            }
            
        }
    }
    
    func eraseData() {
        let fileManager = NSFileManager()
        let documentsDirectory = findDocumentsDirectory()
        do {let listOfItens = try fileManager.contentsOfDirectoryAtPath(documentsDirectory)
            for filename in listOfItens {
                let path = documentsDirectory + "/\(filename)"
                do {try fileManager.removeItemAtPath(path)} catch {}
            }
        }
        catch {}
    }

    
    
}

