//
//  ViewController.swift
//  Firebase-Example
//
//  Created by Lachi Agnew on 10/15/18.
//  Copyright © 2018 Lachlan Agnew. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class ViewController: UIViewController, UITableViewDelegate,
                      UITableViewDataSource, UITextFieldDelegate {
  @IBOutlet weak var statusLabel: UILabel!
  @IBOutlet weak var selectionSegment: UISegmentedControl!
  @IBOutlet weak var messagerTextField: UITextField!
  @IBOutlet weak var messagesTableView: UITableView!
  
  var messages : [String] = []
  let COLORS = ["ff0000","00ff00","0000ff"]
  let LABELS = ["Started","Going","Stopped"]
  
  func setStatus(status: Int, color: UIColor){
    selectionSegment.selectedSegmentIndex = status
    statusLabel.textColor = color
    statusLabel.text = LABELS[status]
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    messagesTableView.delegate = self
    messagesTableView.dataSource = self
    
    statusListener()
    messageListener()
  }

  func statusListener(){
    Firestore.firestore().collection("settings").document("device1")
      .addSnapshotListener { documentSnapshot, error in
        guard let document = documentSnapshot else {
          print("Error fetching document: \(error!)")
          return
        }
        guard let data = document.data() else {
          print("Document data was empty.")
          return
        }
        let status = data["status"] as! Int
        let color = UIColor(hex: data["color"] as! String)
        self.setStatus(status: status, color: color)
    }
  }
  
  func messageListener(){
    Firestore.firestore().collection("messages")
      .whereField("created", isGreaterThan: Date.timeIntervalBetween1970AndReferenceDate - 1000)
      .order(by: "created")
      .addSnapshotListener { documentSnapshot, error in
        guard let snap = documentSnapshot else {
          print("Error fetching document: \(error!)")
          return
        }
        self.messages = []
        for doc in snap.documents{
          self.messages.insert(doc.data()["message"] as! String, at: 0)
        }
        self.messagesTableView.reloadData()
    }
  }
  
  @IBAction func onChangeSelection(_ sender: Any) {
    let selection = selectionSegment.selectedSegmentIndex
    let color = COLORS[selection]
    let ref = Firestore.firestore().collection("settings").document("device1")
    ref.setData([
      "status": selection,
      "color": color
    ]){ err in
      if let err = err {
        print("Error writing document: \(err)")
      } else {
        print("Document successfully written!")
      }
    }
  }
  
  @IBAction func sendButtonPressed(_ sender: Any) {
    if let message = messagerTextField.text {
      self.messagerTextField.text = ""
      Firestore.firestore().collection("messages").addDocument(data: [
        "message": message,
        "created": Date().timeIntervalSince1970
      ]) { (err) in
        if let err = err {
          self.messagerTextField.text = message
          print("Error writing document: \(err)")
        } else {
          print("Document successfully written!")
        }
      }
    }
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return messages.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell()
    let label = UILabel(frame: cell.frame)
    label.text = messages[indexPath.row]
    cell.addSubview(label)
    return cell
  }
}


