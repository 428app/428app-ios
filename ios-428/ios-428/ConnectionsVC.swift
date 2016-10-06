//
//  ConnectionsVC.swift
//  ios-428
//
//  Created by Leonard Loo on 10/5/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit

class ConnectionsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    private var connections: [Connection] = [Connection]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initNavController()
        self.stubData()
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    // MARK: Nav controller

    private func initNavController() {
        self.navigationItem.title = "Connections"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Settings"), style: .plain, target: self, action: #selector(ConnectionsVC.goToSettings))
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    }
    
    func goToSettings() {
        self.performSegue(withIdentifier: SEGUE_SETTINGS, sender: nil)
    }
    
    // MARK: Stub data - to be replaced with server data
    
    private func stubData() {
        let conn1 = Connection(userPicUrl: "leo-profile", username: "Leonard", recentMsg: "Zoology is fascinating! Could you tell me more the next time we meet?", discipline: "Business")
        let conn2 = Connection(userPicUrl: "tomas-profile", username: "Tomas", recentMsg: "Want to meet up in the gym next time???", discipline: "Computer")
        let conn3 = Connection(userPicUrl: "jenny-profile", username: "Jenny", recentMsg: "My favorite hobby is eating. How about you? I'm sure you love eating too...?", discipline: "Biology")
        let conn4 = Connection(userPicUrl: "spandan-profile", username: "Spandan", recentMsg: "Ever thought of applying computer vision to Tinder? Imagine if we can...", discipline: "Computer")
        self.connections.append(conn1)
        self.connections.append(conn2)
        self.connections.append(conn3)
        self.connections.append(conn4)
    }
    
    // MARK: Table view
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.connections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let connection = self.connections[indexPath.row]
        let cell: ConnectionCell
        if let reusedCell = tableView.dequeueReusableCell(withIdentifier: "ConnectionCell") as? ConnectionCell {
            cell = reusedCell
        } else {
            cell = ConnectionCell()
        }
        cell.configureCell(connectionObj: connection)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let connection = self.connections[indexPath.row]
        self.performSegue(withIdentifier: SEGUE_CHAT, sender: connection)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       if segue.identifier == SEGUE_CHAT, let connection = sender as? Connection,
        let vc = segue.destination as? ChatVC {
        vc.connection = connection
        }
    }
}
