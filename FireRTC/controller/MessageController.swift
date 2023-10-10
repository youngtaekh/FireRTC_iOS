//
//  MessageController.swift
//  FireRTC
//
//  Created by young on 2023/09/01.
//

import UIKit

class MessageController: UIViewController {
    private let TAG = "MessageController"
    
    let keyboardValue1 = 45.0
    
    var testHeight = 100
    var totalHeight = 0.0
    
    var originBottomY = 0.0
    var originLine1Y = 0.0
    var originY = 0.0
    var originLine2Y = 0.0
    var keyboardHeight = 0.0
    
    var onConnected = false
    var isTerminated = false
    var isEnd = false
    var isBottom = true
    var isKeyboardUp = false
    
    let messageVM = MessageViewModel.instance

    @IBOutlet weak var tvTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var viewLine1: UIView!
    @IBOutlet weak var bottomView: UIStackView!
    @IBOutlet weak var etMessage: UITextView!
    @IBOutlet weak var viewLine2: UIView!
    
    @IBOutlet weak var tvBottom: UIButton!
    
    override func viewDidLoad() {
        print("\(TAG) \(#function)")
        super.viewDidLoad()
        
        tvBottom.isHidden = true
        
        tableView.delegate = self
        tableView.dataSource = self
//        tableView.rowHeight = 70.0
//        tableView.keyboardDismissMode = .onDrag
//        addTapGesture()

        messageVM.controllerEvent = self
        messageVM.messageEvent = self
        messageVM.start() {
            self.addInitData()
        }

        tvTitle.text = messageVM.participant.name
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        print("y \(self.bottomView.frame.origin.y)")
        originLine1Y = self.viewLine1.frame.origin.y
        originY = self.bottomView.frame.origin.y
        originLine2Y = self.viewLine1.frame.origin.y
        originBottomY = self.tvBottom.frame.origin.y
    }
    
    @IBAction func finish(_ sender: Any) {
        print("\(TAG) \(#function)")
        isEnd = true
        messageVM.endCall()
    }
    @IBAction func test(_ sender: Any) {
        testHeight *= -1
        print("\(TAG) \(#function) \(testHeight)")
        print("y \(self.bottomView.frame.origin.y)")
//        isEnd = true
//        messageVM.endCall()
//        addSampleData()
//        self.tableView.scrollRectToVisible(CGRect(x: 0, y: 100, width: 1, height: 1), animated: true)
        if (isKeyboardUp) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                print("originY \(self.originY)")
                self.viewLine1.frame.origin.y -= self.keyboardHeight
                self.bottomView.frame.origin.y -= self.keyboardHeight
                self.viewLine2.frame.origin.y -= self.keyboardHeight
                self.tvBottom.frame.origin.y -= self.keyboardHeight
                print("self.bottomView.frame.origin.y \(self.bottomView.frame.origin.y)")
            }
        } else {
            self.bottomView.frame.origin.y = originY + view.safeAreaInsets.bottom
        }
    }
    @IBAction func send(_ sender: Any) {
        print("\(TAG) \(#function) \(etMessage.text ?? "")")
        if (etMessage.text.isEmpty) {
            messageVM.sendData(msg: "empty")
        } else {
            messageVM.sendData(msg: etMessage.text)
        }

        etMessage.text = ""
        self.tableView.reloadData()
        scrollToBottom()
        if isKeyboardUp {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                print("originY \(self.originY)")
                self.viewLine1.frame.origin.y -= self.keyboardHeight
                self.bottomView.frame.origin.y -= self.keyboardHeight
                self.viewLine2.frame.origin.y -= self.keyboardHeight
                self.tvBottom.frame.origin.y -= self.keyboardHeight
                print("self.bottomView.frame.origin.y \(self.bottomView.frame.origin.y)")
            }
        }
    }

    @IBAction func toBottom(_ sender: Any) {
        print("\(TAG) \(#function)")
        scrollToBottom()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("\(TAG) \(#function)")
        view.endEditing(true)
    }
    
    private func addInitData() {
        print("\(TAG) \(#function)")
        print("\(TAG) chatId \(MessageViewModel.instance.chat!.id)")
        for i in 0..<100 {
            if i % 3 == 0 {
                let message = Message(from: SharedPreference.instance.getID(), chatId: MessageViewModel.instance.chat!.id, body: "sample \(i)")
                message.createdAt = Date.now
                MessageViewModel.instance.messageMap[MessageViewModel.instance.chat!.id]?.append(message)
            } else {
                let message = Message(from: MessageViewModel.instance.participant.id, chatId: MessageViewModel.instance.chat!.id, body: "sample \(i)")
                message.createdAt = Date.now
                MessageViewModel.instance.messageMap[MessageViewModel.instance.chat!.id]?.append(message)
            }
        }
        tableView.reloadData()
        scrollToBottom(animated: false)
    }
    
    private func addSampleData() {
        print("\(TAG) \(#function)")
        for i in 0..<12 {
            print("sample \(i)")
            messageVM.sendData(msg: "sample \(i)")
        }
        self.tableView.reloadData()
        scrollToBottom(animated: false)
    }
    
    private func addTapGesture() {
        print("\(TAG) \(#function)")
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(_:)))
        tapGesture.cancelsTouchesInView = true
        self.tableView.addGestureRecognizer(tapGesture)
    }
    
    @objc
    private func hideKeyboard(_ sender: Any) {
        print("\(TAG) \(#function)")
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        self.isKeyboardUp = true
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        print("\(TAG) \(#function) height \(keyboardViewEndFrame.height)")
        print("\(TAG) \(#function) bottom \(view.safeAreaInsets.bottom)")
        
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        
//        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
//        self.tableView.scrollIndicatorInsets = self.tableView.contentInset
//        let selectedRange = self.tableView.selectedRange
//        self.tableView.scrollRangeToVisible(selectedRange)
        
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.keyboardHeight = keyboardSize.height - view.safeAreaInsets.bottom
            print("\(TAG) \(#function) keyboardSize \(self.keyboardHeight)")
            self.viewLine1.frame.origin.y -= self.keyboardHeight
            self.bottomView.frame.origin.y -= self.keyboardHeight
            self.viewLine2.frame.origin.y -= self.keyboardHeight
            self.tvBottom.frame.origin.y -= self.keyboardHeight
        }
//        self.tableView.scrollRectToVisible(CGRect(x: 0, y: 500, width: 1, height: 1), animated: true)
        if isBottom {
            self.scrollToBottom()
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.isKeyboardUp = false
        print("\(TAG) \(#function) safe.bottom \(self.keyboardHeight)")
        self.viewLine1.frame.origin.y += self.keyboardHeight
        self.bottomView.frame.origin.y += self.keyboardHeight
        self.viewLine2.frame.origin.y += self.keyboardHeight
        self.tvBottom.frame.origin.y += self.keyboardHeight
        
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func scrollToBottom(animated: Bool = true) {
        print("\(TAG) \(#function)")
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.self.messageVM.messageList.count-1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
//            self.tvBottom.isHidden = true
            self.isBottom = true
        }
    }
}

extension MessageController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("\(TAG) \(#function)")
        return self.messageVM.messageList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        print("\(TAG) \(#function)")
        let message = self.messageVM.messageList[indexPath.row]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "aa hh:mm"
        if (message.from == SharedPreference.instance.getID()) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SendMessageCell", for: indexPath) as! SendMessageCell
            cell.tvMessage.text = "\(message.body) \(indexPath.row)"
            if message.createdAt != nil {
                cell.tvTime.text = dateFormatter.string(from: message.createdAt!)
            }
            return cell
        }
        if (indexPath.row == 0 || self.messageVM.messageList[indexPath.row - 1].from == SharedPreference.instance.getID()) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecvMessageCell", for: indexPath) as! RecvMessageCell
            cell.tvName.text = messageVM.participant.name
            cell.tvMessage.text = "\(message.body) \(indexPath.row)"
            if message.createdAt != nil {
                cell.tvTime.text = dateFormatter.string(from: message.createdAt!)
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Recv2MessageCell", for: indexPath) as! Recv2TableViewCell
            cell.tvMessage.text = "\(message.body) \(indexPath.row)"
            if message.createdAt != nil {
                cell.tvTime.text = dateFormatter.string(from: message.createdAt!)
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("\(TAG) \(#function)")
        tableView.deselectRow(at: indexPath, animated: true)
        print("Click Cell Number: " + String(indexPath.row))
        
        view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        print("willDisplay Cell Number: " + String(indexPath.row))
        if indexPath.row == self.messageVM.messageList.count - 1 {
//            tvBottom.isHidden = true
            isBottom = true
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        print("didEndDisplaying Cell Number: " + String(indexPath.row))
        if indexPath.row == self.messageVM.messageList.count - 2 {
//            tvBottom.isHidden = false
//            isBottom = false
        }
    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        print("\(TAG) \(#function)")
//        if (indexPath.row > 100) {
//            totalHeight += 100.0
//            return 100.0
//        }
//        totalHeight += 70.0
//        return 70.0
//    }
}

extension MessageController: ControllerEvent {
    func onTerminatedCall() {
        print("\(TAG) onTerminatedCall")
        isTerminated = true
        if isEnd {
            MoveTo.popController(ui: self, action: true)
        }
    }
    
    func onPCConnected() {
        print("\(TAG) onPCConnected")
        onConnected = true
    }
}

extension MessageController: MessageEvent {
    func onMessageReceived(msg: String) {
        print("\(TAG) \(msg)")
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.scrollToBottom()
        }
    }
}
