//
//  HistoryController.swift
//  FireRTC
//
//  Created by young on 2023/08/02.
//

import UIKit
//import FirebaseFirestoreSwift

class HistoryController: UIViewController {
    private let TAG = "HistoryController"
    
    var calls = [Call]()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tvEmpty: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        // Do any additional setup after loading the view.
        print("\(TAG) \(#function)")
        
        getCalls()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("\(TAG) \(#function)")
        
        getCalls()
    }
    
    private func getCalls() {
        CallRepository.getByUserId(
            userId: SharedPreference.instance.getID()
        ) { query, err in
            if err != nil {
                print("\(self.TAG) getCallByUserId error \(err!)")
            } else if query == nil || query!.isEmpty {
                print("\(self.TAG) getCallByUserId call is empty")
            }  else {
                self.calls = [Call]()
                var prevDate: Date? = nil
                for document in query!.documents {
                    let call = Call.fromMap(map: document.data())
                    if self.isDifferentDay(prev: prevDate, cur: call.createdAt) {
                        let date = Call(spaceId: "", createdAt: call.createdAt, counterpartName: "", isHeader: true)
                        self.calls.append(date)
                    }
                    self.calls.append(call)
                    prevDate = call.createdAt
                    print("\(self.TAG) getCallByUserId call \(call.toString())")
                }
            }
            self.reload()
        }
    }
    
    func reload() {
        tvEmpty.isHidden = !calls.isEmpty
        tableView.isHidden = calls.isEmpty
        tableView.reloadData()
    }
    
    func isDifferentDay(prev: Date?, cur: Date?) -> Bool {
        if prev == nil || cur == nil {
            return true
        }
        return dateToString(date: prev!, format: "yy MM dd") != dateToString(date: cur!, format: "yy MM dd")
    }
    
    func dateToString(date: Date, format: String) -> String {
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = format
        dateFormat.locale = Locale(identifier:"ko_KR")
        return dateFormat.string(from: date)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension HistoryController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return calls.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let call = calls[indexPath[1]]
        if (call.isHeader!) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DateTableViewCell", for: indexPath) as! DateTableViewCell
            if call.createdAt != nil {
                cell.tvDate.text = self.dateToString(date: call.createdAt!, format: "yy. MM. dd")
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryTableViewCell", for: indexPath) as! HistoryTableViewCell
            if (calls.isEmpty) {
                cell.tvTitle.text = "Empty!"
            } else {
                print("\(TAG) counterpartName \(call.counterpartName)")
                cell.tvTitle.text = call.counterpartName
                switch (call.type) {
                    case .AUDIO:
                        cell.ivType.image = UIImage(named: "round_call")
                    case .VIDEO:
                        cell.ivType.image = UIImage(named: "round_videocam")
                    case .SCREEN:
                        cell.ivType.image = UIImage(named: "round_mobile_screen_share")
                    case .MESSAGE:
                        cell.ivType.image = UIImage(named: "round_chat_bubble")
                    case .CONFERENCE:
                        print("conference")
                }
                
                if call.direction == Call.Direction.Offer {
                    cell.ivDirection.image = UIImage(named: "round_call_made")
                    cell.ivDirection.tintColor = UIColor.green
                } else {
                    cell.ivDirection.tintColor = UIColor.red
                    if (call.connected) {
                        cell.ivDirection.image = UIImage(named: "round_call_received")
                    } else {
                        cell.ivDirection.image = UIImage(named: "round_call_missed")
                    }
                }
                if call.createdAt != nil {
                    cell.tvTime.text = self.dateToString(date: call.createdAt!, format: "aa hh:mm")
                }
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //클릭한 셀의 이벤트 처리
        tableView.deselectRow(at: indexPath, animated: true)

        print("\(TAG) Click name \(calls[indexPath.row].createdAt!)")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if calls[indexPath[1]].isHeader ?? false {
            return 30.0
        } else {
            return 70.0
        }
    }
}
