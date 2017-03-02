//
//  PlaygroupService.swift
//  ios-428-app
//
//  Created by Leonard Loo on 1/4/17.
//  Copyright © 2017 428. All rights reserved.
//

import Foundation

import Firebase
import FirebaseDatabase
import FirebaseAuth
import FirebaseMessaging
import FBSDKCoreKit
import FBSDKLoginKit

// Extends DataService to house Playgroup calls
extension DataService {
    
    func checkIfThereAreAnyPlaygroups(completed: @escaping (_ havePlaygroups: Bool) -> ()) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        REF_USERS.child("\(uid)/playgroups").observeSingleEvent(of: .value, with: { snapshot in
            completed(snapshot.exists())
        })
    }
    
    // Observe for added playgroup of a user, used in PlaygroupsController
    func observePlaygroupAdded(completed: @escaping (_ isSuccess: Bool, _ pid: String) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        // Grabs the user's playgroups
        let ref: FIRDatabaseReference = REF_USERS.child("\(uid)/playgroups")
        let handle = ref.observe(.childAdded, with: { snapshot in
            if !snapshot.exists() {
                completed(false, "")
                return
            }
            guard var _ = snapshot.value as? [String: Any] else {
                completed(false, "")
                return
            }
            completed(true, snapshot.key)
            return
        })
        return (ref, handle)
    }
    
    // Observe updates of a single playgroup for a user, used in PlaygroupsController
    func observePlaygroupUpdates(pid: String, completed: @escaping (_ isSuccess: Bool, _ playgroup: Playgroup?) -> ()) ->(FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let ref: FIRDatabaseReference = REF_USERS.child("\(uid)/playgroups/\(pid)")
        // Observed on value as not childAdded, as playgroups might be deleted in the future
        let handle = ref.observe(.value, with: { snapshot in
            if !snapshot.exists() {
                completed(false, nil)
                return
            }
            guard var classDict = snapshot.value as? [String: Any] else {
                completed(false, nil)
                return
            }
            let pid = snapshot.key
            
            guard let questionNum = classDict["questionNum"] as? Int, let discipline = classDict["discipline"] as? String, let questionImage = classDict["questionImage"] as? String, let questionShareImage = classDict["questionShareImage"] as? String, let questionText = classDict["questionText"] as? String, let timeReplied = classDict["timeReplied"] as? Double, let hasUpdates = classDict["hasUpdates"] as? Bool else {
                completed(false, nil)
                return
            }
            let playgroup = Playgroup(pid: pid, title: discipline, timeReplied: timeReplied, hasUpdates: hasUpdates, questionNum: questionNum, questionText: questionText, imageName: questionImage, shareImageName: questionShareImage)
            completed(true, playgroup)
            return
        })
        return (ref, handle)
    }
    
    fileprivate func isIdenticalArrays(arr1: [Any], arr2: [Any]) -> Bool {
        let set1 = NSCountedSet(array: arr1)
        let set2 = NSCountedSet(array: arr2)
        return set1 == set2
    }
    
    // Observe single playgroup used in ChatPlaygroupController
    func observeSinglePlaygroup(playgroup: Playgroup, completed: @escaping (_ isSuccess: Bool, _ playgroup: Playgroup) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let pid = playgroup.pid
        let ref: FIRDatabaseReference = REF_PLAYGROUPS.child(pid)
        
        let handle = ref.observe(.value, with: { playgroupSnap in
            guard let classDict = playgroupSnap.value as? [String: Any], let playpeerAndSuperlativeType = classDict["memberHasVoted"] as? [String: Int], let questionsDict = classDict["questions"] as? [String: Any] else {
                completed(false, playgroup)
                return
            }
            // Download profiles, and find this user's superlative type
            var members: [Profile] = [Profile]()

            // Used as comparison to know if async task is done
            var memberIds: [String] = [String]()
            let totalMemberIds: [String] = Array(playpeerAndSuperlativeType.keys)

            var didYouKnowId = ""
            if let did = classDict["didYouKnow"] as? String {
                didYouKnowId = did
            }
            
            // Assemble skeleton of questions, load question+answers later only when user clicks Answers
            var questions: [Question] = [Question]()
            
            for (qid, questionDict_) in questionsDict {
                if let questionDict = questionDict_ as? [String: Any], let questionTime = questionDict["timestamp"] as? Double, let userVoteIntForQuestion = questionDict[uid] as? Int, let userVoteForQuestion = QuestionVoteType(rawValue: userVoteIntForQuestion) {
                    questions.append(Question(qid: qid, timestamp: questionTime, userVote: userVoteForQuestion))
                }
            }
            
            var superlativeType: SuperlativeType = SuperlativeType.NOTVOTED
            
            for (uid_, superlativeType_) in playpeerAndSuperlativeType {
                
                // Find superlative type of this user
                if uid_ == uid {
                    superlativeType = SuperlativeType(rawValue: superlativeType_)!
                }
                // Download all playpeers' profiles
                self.getUserFields(uid: uid_, completed: { (isSuccess, userProfile) in
                    
                    if !isSuccess || userProfile == nil {
                        // There was a problem getting a user's profile, so return false)
                        completed(false, playgroup)
                        return
                    }
                    
                    members.append(userProfile!)
                    memberIds.append(userProfile!.uid)
                    
                    if self.isIdenticalArrays(arr1: memberIds, arr2: totalMemberIds) { // All playpeers read
                        
                        // Check if there are superlatives available yet
                        let hasSuperlatives = classDict["superlatives"] != nil
                        
                        // Form playgroup messages in a separate call
                        let updatedPlaygroup = Playgroup(pid: playgroup.pid, title: playgroup.title, timeReplied: playgroup.timeReplied, hasUpdates: playgroup.hasUpdates, questionNum: playgroup.questionNum, questionText: playgroup.questionText, imageName: playgroup.imageName, shareImageName: playgroup.shareImageName, members: members, questions: questions, superlativeType: superlativeType, hasSuperlatives: hasSuperlatives, didYouKnowId: didYouKnowId)
                        completed(true, updatedPlaygroup) // Finally!
                        return
                    }
                })
            }
        })
        return (ref, handle)
    }
    
    // MARK: Questions 
    
    // Used to get questions and answers in AnswersController
    func getQuestionsAndAnswers(playgroup: Playgroup, completed: @escaping (_ isSuccess: Bool, _ playgroup: Playgroup) -> ()) {
        // Note that qids must already be populated in playgroup's questions
        let discipline = playgroup.title
        let oldQuestions = playgroup.questions
        var questionsLeft = playgroup.questions.count
        if questionsLeft == 0 {
            completed(false, playgroup)
            return
        }
        var newQuestions = [Question]()
        for question in oldQuestions {
            // Grab the question data to reform question
            self.REF_QUESTIONS.child("\(discipline)/\(question.qid)").observe(.value, with: { questionSnap in
                questionsLeft -= 1
                if let qDict = questionSnap.value as? [String: Any], let imageName = qDict["image"] as? String, let questionText = qDict["question"] as? String, let answer = qDict["answer"] as? String {
                    newQuestions.append(Question(qid: question.qid, timestamp: question.timestamp, imageName: imageName, question: questionText, answer: answer, userVote: question.userVote))
                }
                if questionsLeft == 0 { // Finished processing all questions, but might not have gotten all questions' info
                    playgroup.questions = newQuestions
                    completed(newQuestions.count == oldQuestions.count, playgroup)
                    return
                }
            });
            
        }
    }
    
    // Used to vote for a question in answers as Boring, Cool or Neutral
    func voteForQuestionInPlaygroup(pid: String, qid: String, userVote: Int) {
        guard let uid = getStoredUid() else {
            return
        }
        REF_PLAYGROUPS.child("\(pid)/questions/\(qid)/\(uid)").setValue(userVote)
    }
    
    // MARK: Chat messages

    // Private helper function that takes in a snapshot of all private messages in a playgroup and returns a Playgroup model
    fileprivate func processPlaygroupChatSnapshot(snapshot: FIRDataSnapshot, playgroup: Playgroup, uid: String) -> Playgroup? {
        if !snapshot.exists() {
            return nil
        }
        
        guard let snaps = snapshot.children.allObjects as? [FIRDataSnapshot] else {
            return nil
        }
        
        playgroup.clearMessages()
        for snap in snaps {
            if let dict = snap.value as? [String: Any], let text = dict["message"] as? String, let timestamp = dict["timestamp"] as? Double, let poster = dict["poster"] as? String {
                let mid: String = snap.key
                let isSentByYou: Bool = poster == uid
                let date = Date(timeIntervalSince1970: timestamp * 1.0 / 1000.0)
                let msg = PlaygroupMessage(mid: mid, parentCid: playgroup.pid, posterUid: poster, text: text, date: date, isSentByYou: isSentByYou)
                playgroup.addMessage(message: msg)
            }
        }
        return playgroup
    }
    
    // Observes all chat messags of one playgroup, used in ChatPlaygroupController
    // Observes up till the limit, ordered by most recent timestamp
    func reobservePlaygroupChatMessages(limit: UInt, playgroup: Playgroup, completed: @escaping (_ isSuccess: Bool, _ playgroup: Playgroup?) -> ()) -> (FIRDatabaseQuery, FIRDatabaseHandle) {
        
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let pid = playgroup.pid
        let ref: FIRDatabaseReference = REF_PLAYGROUPMESSAGES.child(pid)
        ref.keepSynced(true)
        
        let q: FIRDatabaseQuery = ref.queryOrdered(byChild: "timestamp").queryLimited(toLast: limit)
        q.keepSynced(true)
        let handle = q.observe(.value, with: { snapshot in
            let updatedPlaygroup = self.processPlaygroupChatSnapshot(snapshot: snapshot, playgroup: playgroup, uid: uid)
            completed(updatedPlaygroup != nil, updatedPlaygroup)
            return
        })
        return (q, handle)
    }
    
    // Observes all chat messags of one playgroup, used when setting up ChatPlaygroupController
    // The only difference between this and reobserve is that this is a one time observer and does not return the handle
    func observePlaygroupChatMessagesOnce(limit: UInt, playgroup: Playgroup, completed: @escaping (_ isSuccess: Bool, _ playgroup: Playgroup?) -> ()) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let pid = playgroup.pid
        let ref: FIRDatabaseReference = REF_PLAYGROUPMESSAGES.child(pid)
        let q: FIRDatabaseQuery = ref.queryOrdered(byChild: "timestamp").queryLimited(toLast: limit)
        q.observeSingleEvent(of: .value, with: { snapshot in
            q.removeAllObservers()
            let updatedPlaygroup = self.processPlaygroupChatSnapshot(snapshot: snapshot, playgroup: playgroup, uid: uid)
            completed(updatedPlaygroup != nil, updatedPlaygroup)
            return
        })
    }
    
    // Add a chat message to the playgroup
    func addPlaygroupChatMessage(playgroup: Playgroup, text: String, completed: @escaping (_ isSuccess: Bool, _ playgroup: Playgroup?) -> ()) {
        guard let profile = myProfile else {
            completed(false, nil)
            return
        }
        
        let posterUid = profile.uid
        let posterName = profile.name
        let posterImage = profile.profileImageName
        let pid = playgroup.pid
        let playgroupTitle = playgroup.title
        let timestampInSeconds = Date().timeIntervalSince1970 // NOTE: This is in seconds, be careful with this one
        let timestampInMilliseconds = timestampInSeconds * 1000 // All Firebase entries are in milliseconds
        
        // Add to playgroupMessages
        let messageRef: FIRDatabaseReference = REF_PLAYGROUPMESSAGES.child(pid).childByAutoId()
        let mid = messageRef.key
        let newMessage: [String: Any] = ["message": text, "poster": posterUid, "timestamp": timestampInMilliseconds]
        messageRef.setValue(newMessage) { (err, ref) in
            // Message successfully added, append to playgroup
            let msg: PlaygroupMessage = PlaygroupMessage(mid: mid, parentCid: pid, posterUid: posterUid, text: text, date: Date(timeIntervalSince1970: timestampInSeconds), isSentByYou: true)
            playgroup.addMessage(message: msg)
            completed(err == nil, playgroup)
            // NOTE: We do not return here, but also note that there are no more completed calls below
        }
        
        // Add to own playgroup's time replied first (do not add to own hasUpdates)
        REF_USERS.child("\(posterUid)/playgroups/\(pid)/timeReplied").setValue(timestampInMilliseconds) // NOTE: Have to set milliseconds in server
        
        // Add to other playpeers' hasUpdates
        let playpeerUids = playgroup.members.map { (profile) -> String in return profile.uid }.filter{$0 != posterUid}
        for playpeerUid in playpeerUids {
            
            self.REF_USERS.child(playpeerUid).observeSingleEvent(of: .value, with: { (userSnap) in
                if !userSnap.exists() {
                    return
                }
                
                // Get this user's push token and push count, and send it to push server anyway
                guard let userDict = userSnap.value as? [String: Any], let playgroupsDict = userDict["playgroups"] as? [String: Any], let playgroupDict = playgroupsDict[pid] as? [String: Any], let hasUpdates = playgroupDict["hasUpdates"] as? Bool else {
                    return
                }
                guard let pushToken = userDict["pushToken"] as? String, let pushCount = userDict["pushCount"] as? Int else {
                    // No push token, but user still exists in playgroup, so set updates right
                    self.REF_USERS.child("\(playpeerUid)/playgroups/\(pid)").updateChildValues(["hasUpdates": true, "timeReplied": timestampInMilliseconds])
                    return
                }
            
                // Check if this user has the settings that allow message to be push notified
                let settingsRef = self.REF_USERSETTINGS.child(playpeerUid)
                settingsRef.keepSynced(true)
                settingsRef.observeSingleEvent(of: .value, with: { (settingsSnap) in
                    
                    var inAppSettings = true
                    
                    if settingsSnap.exists() {
                        
                        if let settingDict = settingsSnap.value as? [String: Bool], let inApp = settingDict["inAppNotifications"] {
                            inAppSettings = inApp
                        }
                        
                        // Check if /playgroupMessages and /isLoggedIn are both true
                        if let settingDict = settingsSnap.value as? [String: Bool], let acceptsPlaygroupMessages = settingDict["playgroupMessages"], let isLoggedIn = settingDict["isLoggedIn"] {
                            if !acceptsPlaygroupMessages || !isLoggedIn {
                                // Not allowed to push messages. Increment push count if necessary, then return
                                if !hasUpdates {
                                    self.adjustPushCount(isIncrement: true, uid: playpeerUid, completed: { (isSuccess) in })
                                }
                                
                                self.REF_USERS.child("\(playpeerUid)/playgroups/\(pid)").updateChildValues(["hasUpdates": true, "timeReplied": timestampInMilliseconds])
                                return
                            }
                        }
                    }
                    
                    // Allowed to send push notifications
                    if hasUpdates {
                        // There are already new messages in this playgroup for this user, just send a notification without updating push count
                        self.REF_USERS.child("\(playpeerUid)/playgroups/\(pid)").updateChildValues(["hasUpdates": true, "timeReplied": timestampInMilliseconds])
                        self.addToNotificationQueue(type: TokenType.PLAYGROUP, posterUid: posterUid, posterName: posterName, posterImage: posterImage, recipientUid: playpeerUid, pushToken: pushToken, pushCount: pushCount, inApp: inAppSettings, pid: pid, title: playgroupTitle, body: text)
                        return
                    }
                    // No new messages for this user in this playgroup, set hasUpdates to true, and increment push count for this user
                    self.adjustPushCount(isIncrement: true, uid: playpeerUid, completed: { (isSuccess) in
                        self.REF_USERS.child("\(playpeerUid)/playgroups/\(pid)").updateChildValues(["hasUpdates": true, "timeReplied": timestampInMilliseconds])
                        // After push count is incremented, then push notification.
                        self.addToNotificationQueue(type: TokenType.PLAYGROUP, posterUid: posterUid, posterName: posterName, posterImage: posterImage, recipientUid: playpeerUid, pushToken: pushToken, pushCount: pushCount + 1, inApp: inAppSettings, pid: pid, title: playgroupTitle, body: text)
                    })
                })
            })
        }
    }
    
    // See playgroup messages so the updated label goes away
    func seePlaygroupMessages(playgroup: Playgroup, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        let pid = playgroup.pid
        
        REF_USERS.child("\(uid)/playgroups/\(pid)/hasUpdates").setValue(false) { (err, ref) in
            self.updatePushCount { (isSuccess, pushCount) in }
        }
        
    }
    
    // MARK: Superlatives
    
    func submitSuperlativeVote(playgroup: Playgroup, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        
        // Atomic update on memberHasVoted and superlatives
        var classUpdates: [String: Any] = ["memberHasVoted/\(uid)": 1]
        for sup in playgroup.superlatives {
            if let uidVotedFor = sup.userVotedFor?.uid {
                classUpdates["superlatives/\(sup.superlativeName)/\(uid)"] = uidVotedFor
            }
        }
        
        REF_PLAYGROUPS.child(playgroup.pid).updateChildValues(classUpdates) { (err, ref) in
            completed(err == nil)
            return
        }
    }
    
    func shareSuperlative(playgroup: Playgroup, completed: @escaping (_ isSuccess: Bool) -> ()) {
        guard let uid = getStoredUid() else {
            completed(false)
            return
        }
        
        // When a user shares a superlative, simply update the flag for memberHasVoted
        let classUpdates: [String: Any] = ["memberHasVoted/\(uid)": 2]
        REF_PLAYGROUPS.child(playgroup.pid).updateChildValues(classUpdates) { (err, ref) in
            completed(err == nil)
            return
        }
    }
    
    func getSuperlativeState(playgroup: Playgroup, completed: @escaping (_ isSuccess: Bool, _ superlativeState: SuperlativeType) -> ()) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let pid = playgroup.pid
        REF_PLAYGROUPS.child("\(pid)/memberHasVoted/\(uid)").observeSingleEvent(of: .value, with: { snapshot in
            if let superlativeState = snapshot.value as? Int {
                completed(true, SuperlativeType(rawValue: superlativeState)!)
                return
            } else {
                completed(false, SuperlativeType(rawValue: 0)!)
                return
            }
        })
    }
    
    func observeSuperlatives(playgroup: Playgroup, completed: @escaping (_ isSuccess: Bool, _ playgroup: Playgroup?) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        let pid = playgroup.pid
        let ref: FIRDatabaseReference = REF_PLAYGROUPS.child("\(pid)/superlatives")
        ref.keepSynced(true)
        
        let handle = ref.observe(.value, with: { snapshot in
            if !snapshot.exists() {
                playgroup.hasSuperlatives = false
                completed(true, playgroup)
                return
            }
            
            guard let supDict = snapshot.value as? [String: Any] else {
                playgroup.hasSuperlatives = false
                completed(true, playgroup)
                return
            }
            
            var superlatives = [Superlative]()
            var results = [Superlative]()
            let members = playgroup.members
            
            // Used to notify the user if voting is still ongoing or not.
            // If there is a single user who has not voted for a single superlative, this will be flipped to true.
            var isVotingOngoing = false
            
            for (supName, uidVotes_) in supDict {
                guard let uidVotes = uidVotes_ as? [String: String] else {
                    continue
                }
                
                // Update results (the most number of votes for a certain person)
                var voteResults = [String: Int]()
                for (_, uidVotedFor) in uidVotes {
                    if uidVotedFor == "" { // User has not voted yet
                        isVotingOngoing = true
                        continue
                    }
                    var currentVoteCount = voteResults[uidVotedFor]
                    if currentVoteCount == nil || currentVoteCount == 0 {
                        currentVoteCount = 1
                    } else {
                        currentVoteCount! += 1
                    }
                    voteResults[uidVotedFor] = currentVoteCount!
                }
                
                // Find uid with max votes
                var maxVoteCount = 0
                var maxVotedUid = ""
                for (uidVotedFor, voteCount) in voteResults {
                    if voteCount > maxVoteCount {
                        // Note: There could potentially be multiple users with the same vote, but we just choose one of them
                        maxVoteCount = voteCount
                        maxVotedUid = uidVotedFor
                    }
                }
                // Get the user with this uid
                var maxVotedMember = members.filter(){$0.uid == maxVotedUid}
                if maxVotedMember.count == 1 {
                    results.append(Superlative(superlativeName: supName, userVotedFor: maxVotedMember[0]))
                }
                
                // Update superlatives (what this user voted for)
                let uidVotedFor = uidVotes[uid]
                if uidVotedFor == nil || uidVotedFor == "" {
                    superlatives.append(Superlative(superlativeName: supName))
                } else {
                    let member = members.filter(){$0.uid == uidVotedFor!}
                    if member.count != 1 {
                        superlatives.append(Superlative(superlativeName: supName))
                    } else {
                        superlatives.append(Superlative(superlativeName: supName, userVotedFor: member[0]))
                    }
                }
            }
            
            playgroup.superlatives = superlatives
            playgroup.results = results
            playgroup.isVotingOngoing = isVotingOngoing

            completed(true, playgroup)
            return
        })
        return (ref, handle)
    }
    
    func getDidYouKnow(discipline: String, did: String, completed: @escaping (_ isSuccess: Bool, _ videoLink: String) -> ()) {
        REF_DIDYOUKNOWS.child("\(discipline)/\(did)").observeSingleEvent(of: .value, with: { snap in
            guard let didDict = snap.value as? [String: String], let videoLink = didDict["videoLink"] else {
                completed(false, "")
                return
            }
            completed(true, videoLink)
            return
        })
    }
    
    // MARK: Lobby
    
    // Used on IntroController for a new user to create or join a new lobby
    // NOTE: Must be called after uid is saved to NSUserDefaults and user timezone is stored in Firebase
    // This function does not send back a callback but merely creates a lobbyId entry in the users table
    func createOrJoinLobby() {
        let uid = getStoredUid() == nil ? "" : getStoredUid()!
        // First confirm that this user does not have classrooms/lobby yet
        REF_USERS.child(uid).observe(.value, with: { userSnap in
            // User does not exist yet
            guard let userDict = userSnap.value as? [String: Any] else {
                return
            }
            // User already has playgroups
            if userDict["playgroups"] != nil {
                return
            }
            // User has a lobby! Return
            if let _ = userDict["lobbyId"] as? String {
                return
            }
            // Need user timezone in order to find lobby from that timezone
            guard let userTimezone = userDict["timezone"] as? Double else {
                return
            }
            
            let MAX_LOBBY_SIZE = 12
            
            // Find lobbies from the past 24 hours
            let timestampInMilliseconds = Date().timeIntervalSince1970 * 1000
            
            let q: FIRDatabaseQuery = self.REF_LOBBIES.queryOrdered(byChild: "timeCreated").queryStarting(atValue: timestampInMilliseconds - (24 * 60 * 60 * 1000))
            q.observeSingleEvent(of: .value, with: { snapshot in
                
                if let lobbiesSnap = snapshot.children.allObjects as? [FIRDataSnapshot] {
                    // There are lobbies to scan for
                    for lobbySnap in lobbiesSnap {
                        if let lobbyDict = lobbySnap.value as? [String: Any], let timezone = lobbyDict["timezone"] as? Double, let members = lobbyDict["members"] as? [String: Bool] {
                            if timezone == userTimezone && members.count < MAX_LOBBY_SIZE {
                                // Lobby found that user can join!
                                let lid = lobbySnap.key
                                self.REF_USERS.child("\(uid)/lobbyId").setValue(lid)
                                self.REF_LOBBIES.child("\(lid)/members/\(uid)").setValue(true)
                                return
                            }
                        }
                    }
                }
                
                // Scanned all lobbies, and no lobby to be found, have to create a new lobby
                let lobbyRef = self.REF_LOBBIES.childByAutoId()
                let memberDict = [uid: true]
                let lobbyData: [String: Any] = ["timeCreated": timestampInMilliseconds, "timezone": userTimezone, "members": memberDict]
                lobbyRef.setValue(lobbyData, withCompletionBlock: { (error, ref) in
                    if error != nil {
                        log.error("[Error] Error creating lobby for a new user")
                        return
                    }
                    // New lobby created!
                    self.REF_USERS.child("\(uid)/lobbyId").setValue(ref.key)
                    return
                })
                return
            })
        })
    }
    
    // Observe lobby used in LobbyController, a lobby is actually a playgroup model
    func observeSingleLobby(lid: String, completed: @escaping (_ isSuccess: Bool, _ lobby: Playgroup?) -> ()) -> (FIRDatabaseReference, FIRDatabaseHandle) {
        let ref: FIRDatabaseReference = REF_LOBBIES.child(lid)
        let handle = ref.observe(.value, with: { lobbySnap in
            guard let lobbyDict = lobbySnap.value as? [String: Any], let membersDict = lobbyDict["members"] as? [String: Bool] else {
                completed(false, nil)
                return
            }

            var members: [Profile] = [Profile]()
            let totalMemberIds: [String] = Array(membersDict.keys)
            var memberIds = [String]()
            
            // Get members' profiles
            for memberId in totalMemberIds {
                self.getUserFields(uid: memberId, completed: { (isSuccess, userProfile) in
                    if !isSuccess || userProfile == nil {
                        // There was a problem getting a user's profile, so return false)
                        log.error("[Error] Problem getting a user's profile in observing single lobby")
                        completed(false, nil)
                        return
                    }
                    members.append(userProfile!)
                    memberIds.append(userProfile!.uid)
                    if self.isIdenticalArrays(arr1: memberIds, arr2: totalMemberIds) { // All members read
                        // Image name of lobby in assets
                        let lobby = Playgroup(pid: lid, title: "Lobby", questionText: "What was your childhood ambition? I'm Leonard from 428. I wanted to be a doctor when I was little, and the closest I could get to being a doctor was having a doctor's handwriting.", imageName: "lobby", members: members)
                        completed(true, lobby)
                        return
                    }
                })
            }
        })
        return (ref, handle)
    }
    
    // Add a chat message to the lobby
    func addLobbyChatMessage(playgroup: Playgroup, text: String, completed: @escaping (_ isSuccess: Bool, _ playgroup: Playgroup?) -> ()) {
        guard let profile = myProfile else {
            completed(false, nil)
            return
        }
        let posterUid = profile.uid
        let lid = playgroup.pid
        
        let timestampInSeconds = Date().timeIntervalSince1970 // NOTE: This is in seconds, be careful with this one
        let timestampInMilliseconds = timestampInSeconds * 1000 // All Firebase entries are in milliseconds
        
        // Add to playgroupMessages
        let messageRef: FIRDatabaseReference = REF_PLAYGROUPMESSAGES.child(lid).childByAutoId()
        let mid = messageRef.key
        let newMessage: [String: Any] = ["message": text, "poster": posterUid, "timestamp": timestampInMilliseconds]
        messageRef.setValue(newMessage) { (err, ref) in
            // Message successfully added, append to playgroup
            let msg: PlaygroupMessage = PlaygroupMessage(mid: mid, parentCid: lid, posterUid: posterUid, text: text, date: Date(timeIntervalSince1970: timestampInSeconds), isSentByYou: true)
            playgroup.addMessage(message: msg)
            completed(err == nil, playgroup)
            // NOTE: We do not return here, but also note that there are no more completed calls below
        }
    }
}
