//
//  MatchesVC.swift
//  ios-428
//
//  Created by Leonard Loo on 10/5/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit

class MatchesVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    private var matches: [Match] = [Match]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initNavController()
        log.info("Hi")
        self.stubData()
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    // MARK: Nav controller

    private func initNavController() {
        self.navigationItem.title = "Matches"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Settings"), style: .plain, target: self, action: #selector(MatchesVC.goToSettings))
    }
    
    func goToSettings() {
        self.performSegue(withIdentifier: SEGUE_SETTINGS, sender: nil)
    }
    
    // MARK: Stub data - to be replaced with server data
    
    private func stubData() {
        let match1 = Match(userPicUrl: "leo-profile", username: "Leonard", recentMsg: "Zoology is fascinating! Could you tell me more the next time we meet?", lastSentTime: 1475707911)
        let match2 = Match(userPicUrl: "tomas-profile", username: "Tomas", recentMsg: "Want to meet up in the gym next time???", lastSentTime: 1475607911)
        let match3 = Match(userPicUrl: "jenny-profile", username: "Jenny", recentMsg: "My favorite hobby is eating. How about you? I'm sure you love eating too...?", lastSentTime: 1474707911)
        self.matches.append(match1)
        self.matches.append(match2)
        self.matches.append(match3)
    }
    
    // MARK: Table view
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.matches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let match = self.matches[indexPath.row]
        let cell: MatchCell
        if let reusedCell = tableView.dequeueReusableCell(withIdentifier: "MatchCell") as? MatchCell {
            cell = reusedCell
        } else {
            cell = MatchCell()
        }
        cell.configureCell(matchObj: match)
        return cell
    }
}
