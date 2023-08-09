//
//  SettingController.swift
//  FireRTC
//
//  Created by young on 2023/07/19.
//

import UIKit

class SettingController: UIViewController {
    private let TAG = "SettingController"
    private var space: Space?
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("\(TAG) \(#function)")
        tableView.delegate = self
        tableView.dataSource = self
//        tableView.estimatedRowHeight = 200.0 // Adjust Primary table height
        tableView.rowHeight = 70.0
    }
    
    private func readActiveSpace() {
        SpaceRepository.getActiveSpace(name: SharedPreference.instance.getID()) { query, error in
            if let err = error {
                print("\(self.TAG) Error get queryDocuments: \(err)")
            } else {
                print("\(self.TAG) count \(query!.documents.count)")
                for document in query!.documents {
                    print("\(self.TAG) document \(document)")
                }
            }
        }
    }
    
    private func readSpace() {
        SpaceRepository.getSpace(id: "D97B0F6E5F1C18EE6A0D2FFC9B519272278DB555F86B0BA38FD3775CD9D79812") { result in
            switch result {
                case .success(let space):
                    self.space = space
                    print(space.toString())
                case .failure(let error):
                    print("Error decoding user: \(error)")
            }
        }
    }
    
    private func createSpace() {
        let space = Space(callType: .AUDIO)
        SpaceRepository.post(space: space) { error in
            self.printResult(err: error, info: #function)
        }
    }
    
    private func addCallList() {
        SpaceRepository.addCallList(spaceId: "D97B0F6E5F1C18EE6A0D2FFC9B519272278DB555F86B0BA38FD3775CD9D79812", callId: "callId") { err in
            self.printResult(err: err, info: #function)
        }
    }
    
    private func addParticipantList() {
        SpaceRepository.addParticipantList(spaceId: "D97B0F6E5F1C18EE6A0D2FFC9B519272278DB555F86B0BA38FD3775CD9D79812", participantId: "participantId") { err in
            self.printResult(err: err, info: #function)
        }
    }
    
    private func addLeaveList() {
        SpaceRepository.addLeaveList(spaceId: "D97B0F6E5F1C18EE6A0D2FFC9B519272278DB555F86B0BA38FD3775CD9D79812", participantId: "leaveId") { err in
            self.printResult(err: err, info: #function)
        }
    }
    
    private func removeCallList() {
        SpaceRepository.removeCallList(spaceId: "D97B0F6E5F1C18EE6A0D2FFC9B519272278DB555F86B0BA38FD3775CD9D79812", callId: "participantId") { err in
            self.printResult(err: err, info: #function)
        }
    }
    
    private func updateSpaceStatus() {
        self.space?.terminated = true
        SpaceRepository.updateStatus(space: self.space!, completion: { err in
            self.printResult(err: err, info: #function)
        })
    }
    
    private func updateSpace() {
        SpaceRepository.update(id: "D97B0F6E5F1C18EE6A0D2FFC9B519272278DB555F86B0BA38FD3775CD9D79812", map: [SPACE_STATUS: Space.SpaceStatus.ACTIVE.rawValue], completion: {err in
            self.printResult(err: err, info: #function)
        })
    }
    
    private func getCall() {
        CallRepository.getCall(id: "0289BFE2CBA95E191834F6A4F54FBEE7171AE7FE667E682CF6A3017A6E1E55C1") { result in
            switch result {
                case .success(let call):
                    print("\(self.TAG) getCall \(call.toString())")
                case .failure(let err):
                    print("\(self.TAG) getCall err \(err)")
            }
        }
    }
    
    private func getCallBySpaceId() {
        CallRepository.getBySpaceId(spaceId: "54E38E442EAB4C0F45CB6C1ACB69EDFCC56809057397B370F9785B83F135809C") { query, err in
            if err != nil {
                print("\(self.TAG) getCallBySpaceId error \(err!)")
            } else if query == nil || query!.isEmpty {
                print("\(self.TAG) getCallBySpaceId call is empty")
            }  else {
                for document in query!.documents {
//                    print("\(self.TAG) call \(document.data())")
                    let call = Call.fromMap(map: document.data())
                    print("call \(call.toString())")
                }
            }
        }
    }
    
    private func printResult(err: Error?, info: String) {
        if let err = err {
            print("\(TAG) \(info) error \(err)")
        } else {
            print("\(TAG) \(info) success")
        }
    }
}

extension SettingController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingTableViewCell", for: indexPath) as! SettingTableViewCell
        if (indexPath[1] == 0) {
            cell.tvTitle.text = "Sign Out"
        } else if indexPath[1] == 1 {
            cell.tvTitle.text = "Test 1"
            cell.tvTitle.textColor = UIColor.black
        } else if indexPath[1] == 2 {
            cell.tvTitle.text = "Test 2"
            cell.tvTitle.textColor = UIColor.black
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //클릭한 셀의 이벤트 처리
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            let sp = SharedPreference.instance
            sp.setSign(value: false)
            let _ = MoveTo.controller(ui: self, identifier: MoveTo.signIdentifier)
        } else if indexPath.row == 1 {
            getCall()
        } else if indexPath.row == 2 {
            getCallBySpaceId()
        } else {
            print("Click Cell Number: " + String(indexPath.row))
        }
    }
}
