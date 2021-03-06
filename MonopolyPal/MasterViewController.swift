//
//  MasterViewController.swift
//  MonopolyPal
//
//  Created by Robert Swanson on 7/2/16.
//  Copyright © 2016 Robert Swanson. All rights reserved.
//

import UIKit
import Foundation
extension UIColor {
	convenience init(red: Int, green: Int, blue: Int) {
		assert(red >= 0 && red <= 255, "Invalid red component")
		assert(green >= 0 && green <= 255, "Invalid green component")
		assert(blue >= 0 && blue <= 255, "Invalid blue component")
		
		self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
	}
	
	convenience init(netHex:Int) {
		self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
	}
}

class MasterViewController: UITableViewController {
	// MARK: - Vars
	var game = PlistManager.sharedInstance.getValueForKey("Game", key: "Game")! as! [String:AnyObject]
	var settings = [String:AnyObject]()

	var detailViewController: DetailViewController? = nil
	var peoples: [Player] = []
	var cellColor = UIColor()
	var cellT = UIColor()
	var iconSender: Int? = nil
	
	// MARK: - Costum
	func addPlayerIcon(Sender: Int){
		iconSender = Sender
		self.performSegue(withIdentifier: "icon", sender: self)
		
	}
	func isFreeParking()->Int{
		var a = 0
		for i in peoples{
			if (i.name.lowercased().contains("free parking")) {
				return a
			}
			a += 1
		}
		return Int.min
	}
	func renamePlayer(ip: IndexPath){
		let renamePlayerAlert = UIAlertController(title: "Rename Player", message: "Insert the player's name.", preferredStyle: .alert)
		renamePlayerAlert.addTextField(configurationHandler: {(textF) in
			textF.text = self.peoples[ip.row].name
			textF.selectedTextRange = textF.textRange(from: textF.beginningOfDocument, to: textF.endOfDocument)
		})
		
		let ok = UIAlertAction(title: "OK",
		                       style: .default,
		                                 handler:
			{
				UIAlertAction in
				let newName = renamePlayerAlert.textFields![0].text
				self.peoples[ip.row].name = newName!
				
				var players = self.game["Players"] as! [String:AnyObject]
				var names = players["Names"] as! [String]
				names[ip.row] = newName!
				players["Names"] = names as AnyObject
				self.game["Players"] = players as AnyObject
				
				self.saveGame()
				self.tableView.reloadData()
		}
		)
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		renamePlayerAlert.addAction(ok)
		renamePlayerAlert.addAction(cancelAction)
		present(renamePlayerAlert, animated: true, completion: nil)
	}
	func deletePlayer(ip: IndexPath){
		let deletePlayerAlert = UIAlertController(title: "Remove Player", message: "Are you sure you want to remove this player? You cannot undo this action", preferredStyle: .alert)
		let deleteAction = UIAlertAction(title: "Delete",
		                                 style: .destructive,
		                                 handler:
			{
				UIAlertAction in
				
				self.remove("PlayersNames", valueAtIndex: ip.row)
				self.remove("PlayersScores", valueAtIndex: ip.row)
				self.saveGame()
				self.peoples.remove(at: ip.row)
				self.tableView.deleteRows(at: [ip], with: .fade)
				
		}
		)
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		deletePlayerAlert.addAction(deleteAction)
		deletePlayerAlert.addAction(cancelAction)
		present(deletePlayerAlert, animated: true, completion: nil)

	}
	func customTableColors(){
		func getColor(fromString: String)-> UIColor{
			if (fromString.characters.first == "#"){		//Hex color
				var newColor = fromString
				newColor.remove(at: newColor.startIndex)
				return UIColor(netHex: Int(newColor)!)
			}
			else{			//RGB
				let comp = fromString.components(separatedBy: ",")
				return UIColor(red: Int(comp[0])!, green: Int(comp[1])!, blue: Int(comp[2])!)
			}
		}
		let themes = settings["Themes"] as! [String:[String:String]]
		let selected = settings["Selected Theme"] as! String
		let colors = themes[selected]!
		
		let background = colors["Background"]
		self.tableView.backgroundColor = getColor(fromString: background!)
		
		let cell = colors["Cells"]!
		cellColor = getColor(fromString: cell)
		
		let cellText = colors["Cell Text"]!
		cellT = getColor(fromString: cellText)
		
		
	}
	func addUnit(to: Int)-> String{
		var rv = ""
		var unit = settings["Unit"] as! String
		if (unit.remove(at: unit.startIndex) == "<"){
			rv = unit + String(to)
		}
		else{
			rv = String(to) + unit
		}
		return rv
	}

	func remove(_ fromValue: String, valueAtIndex: Int)
	{
		switch fromValue {
		case "PlayersNames":
			
			var a = self.game["Players"]! as! [String:AnyObject]
			let b = a["Names"]!
			let c = b as! NSMutableArray
			c.removeObject(at: valueAtIndex)
			a["Names"] = c
			game["Players"] = a as AnyObject?
			
		case "PlayersScores":
			var a = self.game["Players"]! as! [String:AnyObject]
			let b = a["Scores"]!
			let c = b as! NSMutableArray
			c.removeObject(at: valueAtIndex)
			a["Scores"] = c
			game["Players"] = a as AnyObject?
			
		default:
			print("ERROR:(26)-No such value in plist")
		}
		self.saveGame()
		
	}
	func add(_ toValue: String, value: AnyObject)
	{
		switch toValue {
		case "PlayersNames":
			var a = self.game["Players"]! as! [String:AnyObject]
			let b = a["Names"]!
			let c = b as! NSMutableArray
			c.add(value as! NSString)
			a["Names"] = c
			game["Players"] = a as AnyObject?
			
		case "PlayersScores":
			
			var a = self.game["Players"]! as! [String:AnyObject]
			let b = a["Scores"]!
			let c = b as! NSMutableArray
			c.add(value as! NSNumber)
			a["Scores"] = c
			game["Players"] = a as AnyObject?
			
			
		default:
			print("ERROR:(26)-No such value in plist")
		}
		self.saveGame()
	}
	func actionPlistNamer(_ Name: String) -> Dictionary<String,String>
	{
		var sec: Int = 0
		var rv = [String:String]()
		var string: String = ""
		for i in Name.characters
		{
			if (i==":")
			{
				rv["\(sec)"]=string
				string = ""
				sec += 1
			}
			else
			{
				string = "\(string)\(i)"
			}
			rv["\(sec)"]=string
		}
		return rv
	}
	
	// MARK: - Initializer
	func saveGame ()
	{
		PlistManager.sharedInstance.saveValue("Game", value: game as AnyObject, forKey: "Game")
	}
	
	func updateGame ()
	{
		game = PlistManager.sharedInstance.getValueForKey("Game", key: "Game")! as! [String:AnyObject]
		settings = game["Settings"] as! [String : AnyObject]
	}
	override func viewDidLoad() {
		settings = game["Settings"] as! [String : AnyObject]
		customTableColors()
		super.viewDidLoad()
		self.navigationItem.leftBarButtonItem = self.editButtonItem
		let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(respondToNewPlayer(_:)))
		self.navigationItem.rightBarButtonItem = addButton
//		if let split = self.splitViewController {
//			let controllers = split.viewControllers
//			self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
//		}
		updateGame()
		
		let a = game["Badge"] as! Int
		tabBarController?.tabBar.items?[1].badgeValue = (a == 0) ? nil : String(a)
		
		print("Master View Did Load")
	}
	override func viewWillAppear(_ animated: Bool) {
		updateGame()
		customTableColors()
		let players = game["Players"]! as! [String:AnyObject]
		let names = players["Names"]! as! [String]
		let num = names.count
		let scores = players["Scores"]! as! [Int]
		let icons = players["Icons"]! as! [String:String]
		
		let empty: [Player] = []
		peoples = empty
		
		if (num > 0)
		{
			for i in 0...num-1
			{
				var piece: String? = nil
				var iconP: UIImage? = nil
				if let icon = icons[names[i]]{
					piece = icon
					iconP = UIImage(named: icon)
				}
				peoples.append(Player(PlayerName: names[i], Score: scores[i], Icon: iconP, imagePath: piece))
			}
		}
		let a = game["Badge"] as! Int
		tabBarController?.tabBar.items?[1].badgeValue = (a == 0) ? nil : String(a)
		tableView.reloadData()
//		self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
		super.viewWillAppear(animated)
		
		
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	func copyAlert(_ name: String)
	{
		let copyAlert = UIAlertController(title: "Duplicate Name", message: "There is already sombody named \(name)", preferredStyle: .alert)
		let okAction = UIAlertAction(title: "OK", style: .default, handler:{UIAlertAction in self.respondToNewPlayer(self)})
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		copyAlert.addAction(okAction)
		copyAlert.addAction(cancelAction)
		present(copyAlert, animated: true, completion: nil)
	}
	// MARK: - Alerts
	func respondToNewPlayer(_ sender: AnyObject)
	{
		let newPlayerAlert = UIAlertController(title: "New Player", message: "Insert your name", preferredStyle: .alert)
		let okAction = UIAlertAction(title: "OK",
		                             style: .default,
		                             handler:
			{
				UIAlertAction in
				
				var cancel = false
				let Pname = newPlayerAlert.textFields![0].text!
				
				for i in self.peoples
				{
					if (i.name == Pname)
					{
						self.copyAlert(Pname)
						cancel = true
					}
				}
				
				if !cancel
				{
					self.add("PlayersNames", value: Pname as AnyObject)

					
					let b = Pname.lowercased().contains("free parking")
					if (self.isFreeParking() != Int.min || b){	// There is free parking
						if (b){									// This is free parking
							self.peoples.append(Player(PlayerName: Pname, Score: 0))
							self.add("PlayersScores", value: 0 as AnyObject)
							
							self.saveGame()
							self.tableView.reloadData()
						}
						else{									// There was already free parking
							self.peoples.append(Player(PlayerName: Pname, Score: 2000))
							self.add("PlayersScores", value: 2000 as AnyObject)
							self.tableView.insertRows(at: [IndexPath(row: self.peoples.count-2, section: 1)], with: .fade)
							self.addPlayerIcon(Sender: self.peoples.count-2)
						}
					}
					else{										// There is no free parking
						self.peoples.append(Player(PlayerName: Pname, Score: 2000))
						self.add("PlayersScores", value: 2000 as AnyObject)
						let indexes: [IndexPath] = [IndexPath(row: self.peoples.count-1, section: 0)]
						self.saveGame()
						self.tableView.insertRows(at: indexes, with: .fade)
						self.addPlayerIcon(Sender: self.peoples.count-1)
					}
				}
		}
		)
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		newPlayerAlert.addAction(okAction)
		newPlayerAlert.addAction(cancelAction)
		newPlayerAlert.addTextField { (textF) in
			textF.placeholder = "Enter Name"
		}
		present(newPlayerAlert, animated: true, completion: nil)
		
	}
	
	// MARK: - Segues
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showDetail" {
			if self.tableView.indexPathForSelectedRow != nil {
				//				let object = peoples[indexPath.row]
				let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
				let indexPath = self.tableView.indexPathForSelectedRow
				controller.senderPlayer = indexPath!.row
				controller.senderPlayerName = peoples[indexPath!.row].name
				controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
				controller.navigationItem.leftItemsSupplementBackButton = true
				controller.navigationItem.title! = peoples[indexPath!.row].name + "'s Actions"

			}
		}
		if (segue.identifier == "icon"){
			let controller = (segue.destination as! UINavigationController).topViewController as! PlayerIconPickerViewController
			controller.sender = iconSender
			var ppl = peoples
			if (isFreeParking() != Int.min){
				ppl.remove(at: isFreeParking())
			}
			
			let s = ppl[iconSender!].name + "'s Piece"
			print(s)
			controller.title = s
		}
	}
	
	// MARK: - Table View
	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		let delete = UITableViewRowAction(style: .destructive, title: "Forfeit", handler: {action, index in
			self.deletePlayer(ip: indexPath)
		})
		let rename = UITableViewRowAction(style: .normal, title: "Name", handler: {action, index in
			self.renamePlayer(ip: indexPath)
		})
		let icon = UITableViewRowAction(style: .normal, title: "Piece", handler: {action, index in
			self.addPlayerIcon(Sender: indexPath.row)
		})
		rename.backgroundColor = .blue
		
//		if (isFreeParking() != Int.min && indexPath.section == 0)
//		{
//			return [rename]
//		}
		return [delete, rename, icon]
	}
	override func numberOfSections(in tableView: UITableView) -> Int
	{
		return isFreeParking() == Int.min ? 1 : 2
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if (section == 1){
			return peoples.count - 1
		}
		else{
			if (isFreeParking() != Int.min){
				return 1
			}
			return peoples.count
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		updateGame()
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		var ppls = peoples
		if (isFreeParking() != Int.min){
			ppls.remove(at: isFreeParking())
			if(indexPath.section == 0){
				let fp = peoples[isFreeParking()]
//				let free = tableView.dequeueReusableCell(withIdentifier: "free", for: indexPath)
				cell.textLabel?.text = fp.name
				cell.detailTextLabel?.text = addUnit(to: fp.score)
				cell.isUserInteractionEnabled = false
//				cell.backgroundColor = cellColor
//				cell.backgroundColor = UIColor(red: 232, green: 232, blue: 232)
//				cell.textLabel?.textColor = cellT
				cell.imageView?.image = #imageLiteral(resourceName: "Free")
				cell.accessoryType = .none
				return cell
			}
		}
		cell.imageView?.image = ppls[indexPath.row].icon
		cell.isUserInteractionEnabled = true
		let object = ppls[indexPath.row].name
//		if !(isFreeParking() != Int.min && indexPath.section == 0){
			cell.textLabel!.text = object
			cell.detailTextLabel?.text = addUnit(to: ppls[indexPath.row].score)
//		}
		
		cell.accessoryType = .disclosureIndicator
//		cell.backgroundColor = cellColor
//		cell.backgroundColor = UIColor(red: 232, green: 232, blue: 232)
//		cell.textLabel?.textColor = cellT
		cell.imageView?.image = ppls[indexPath.row].icon
		return cell
	}
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
	{
		if (indexPath.section == 0 && isFreeParking() != Int.min){
			return false
		}
		return true
	}
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			
			
			
			
		} else if editingStyle == .insert {
			// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
		}
	}
	
	
}


