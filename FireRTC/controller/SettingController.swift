//
//  SettingController.swift
//  FireRTC
//
//  Created by young on 2023/07/19.
//

import UIKit

class SettingController: UIViewController {
    private let TAG = "SettingController"
    @IBOutlet weak var tableView: UITableView!
    
    let tableViewData1 = ["1","2","3","4","5","6","7","8","9","10","11","12"]
    let tableViewData2 = ["첫번째","두번째","세번째","네번째","다섯번째","여섯번째","일곱번째","여덞번째","아홉번째","열번째","열한번째","열두번째"]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("\(TAG) \(#function)")
        tableView.delegate = self
        tableView.dataSource = self
//        tableView.estimatedRowHeight = 200.0 // Adjust Primary table height
        tableView.rowHeight = 70.0
    }
}

extension SettingController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("\(TAG) \(#function) \(section)")
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("\(TAG) \(#function) \(indexPath)")
        print("\(TAG) \(#function) \(indexPath[1])")
        if (indexPath[1] == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingTableViewCell", for: indexPath) as! SettingTableViewCell
            cell.tvTitle.text = "Sign Out"
//            cell.tvTitle.textColor = UIColor(named: .bl)
            return cell
//        } else if indexPath[1] == 1 {
//            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTableViewCell", for: indexPath) as? CustomTableViewCell else { return UITableViewCell() }
//            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //클릭한 셀의 이벤트 처리
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            let sp = SharedPreference.instance
            sp.setSign(value: false)
            MoveTo.controller(ui: self, identifier: MoveTo.signIdentifier)
        } else {
            print("Click Cell Number: " + String(indexPath.row))
            
            print("Click Cell Value1: " + tableViewData1[indexPath.row])
            print("Click Cell Value2: " + tableViewData2[indexPath.row])
        }
    }
}
