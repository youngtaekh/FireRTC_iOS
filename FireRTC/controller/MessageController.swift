//
//  MessageController.swift
//  FireRTC
//
//  Created by young on 2023/09/01.
//

import UIKit

class MessageController: UIViewController {
    private let TAG = "MessageController"
    private let messagePlaceholder = "Message"
    private let maxMessageHeight = 104.0
    private let minMessageHeight = 37.0
    
    var keyboardHeight = 0.0
    
    var isConnected = false
    var isTerminated = false
    var isEnd = false
    var isBottom = true
    var isEdit = false
    var isEmptyMessage = true
    
    let messageVM = MessageViewModel.instance

    @IBOutlet weak var tvTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var etMessage: UITextView!
    @IBOutlet weak var etMessageHeight: NSLayoutConstraint!
    @IBOutlet weak var tvBottom: UIButton!
    @IBOutlet weak var tvSend: UIButton!
    @IBOutlet weak var line2Bottom: NSLayoutConstraint!
    
    override func viewDidLoad() {
        print("\(TAG) \(#function)")
        super.viewDidLoad()
        etMessage.delegate = self
        etMessage.layer.cornerRadius = 15
        etMessage.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        etMessage.text = messagePlaceholder
        etMessage.textColor = .lightGray
        
        tvBottom.isHidden = true
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.transform = CGAffineTransform(rotationAngle: -(CGFloat)(Double.pi))

        messageVM.controllerEvent = self
        messageVM.messageEvent = self
        messageVM.start(completion: nil)

        tvTitle.text = messageVM.participant.name
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        addTapGesture()
    }
    
    @IBAction func finish(_ sender: Any) {
        print("\(TAG) \(#function)")
        isEnd = true
        messageVM.endCall()
    }
    @IBAction func test(_ sender: Any) {
        print("\(TAG) \(#function)")
    }
    @IBAction func send(_ sender: Any) {
        print("\(TAG) \(#function) \(etMessage.text ?? "")")
        if (isEmptyMessage) {
            messageVM.sendData(msg: "empty")
        } else {
            messageVM.sendData(msg: etMessage.text)
        }

        if isEdit {
            etMessage.text = ""
            etMessage.textColor = .black
        } else {
            etMessage.text = messagePlaceholder
            etMessage.textColor = .lightGray
        }
        etMessageHeight.constant = minMessageHeight
        isEmptyMessage = true
        tvSend.tintColor = .lightGray
        tableView.reloadData()
        scrollToBottom()
    }

    @IBAction func toBottom(_ sender: Any) {
        print("\(TAG) \(#function)")
        scrollToBottom()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("\(TAG) \(#function)")
        view.endEditing(true)
    }
    
    private func addTapGesture() {
        print("\(TAG) \(#function)")
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(_:)))
        tapGesture.cancelsTouchesInView = true
        tableView.addGestureRecognizer(tapGesture)
    }
    
    @objc
    private func hideKeyboard(_ sender: Any) {
        print("\(TAG) \(#function)")
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        keyboardHeight = getHeight(notification: notification, view: view)

        line2Bottom.constant = keyboardHeight
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        line2Bottom.constant = 0.0
    }
    
    func scrollToBottom(animated: Bool = true) {
        print("\(TAG) \(#function)")
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: 0, section: 0)
            print("\(#function) indexPath - \(indexPath)")
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
            self.tvBottom.isHidden = true
            self.isBottom = true
        }
    }
}

extension MessageController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("\(TAG) \(#function)")
        return messageVM.messageList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("\(TAG) \(#function) list size \(messageVM.messageList.count)")
        print("\(TAG) \(#function) row \(indexPath.row)")
        let message = messageVM.messageList[indexPath.row]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "aa hh:mm"
        if (message.from == SharedPreference.instance.getID()) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SendMessageCell", for: indexPath) as! SendMessageCell
            cell.tvMessage.text = message.body
            if message.createdAt != nil {
                cell.tvTime.text = dateFormatter.string(from: message.createdAt!)
            }
            cell.transform = CGAffineTransform(rotationAngle: (CGFloat)(Double.pi))
            return cell
        }
        if (indexPath.row == messageVM.messageList.count - 1 || messageVM.messageList[indexPath.row + 1].from == SharedPreference.instance.getID()) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecvMessageCell", for: indexPath) as! RecvMessageCell
            cell.tvName.text = messageVM.participant.name
            cell.tvMessage.text = message.body
            if message.createdAt != nil {
                cell.tvTime.text = dateFormatter.string(from: message.createdAt!)
            }
            cell.transform = CGAffineTransform(rotationAngle: (CGFloat)(Double.pi))
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Recv2MessageCell", for: indexPath) as! Recv2TableViewCell
            cell.tvMessage.text = message.body
            if message.createdAt != nil {
                cell.tvTime.text = dateFormatter.string(from: message.createdAt!)
            }
            cell.transform = CGAffineTransform(rotationAngle: (CGFloat)(Double.pi))
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
        if indexPath.row == 0 {
            tvBottom.isHidden = true
            isBottom = true
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        print("didEndDisplaying Cell Number: " + String(indexPath.row))
        if indexPath.row == 1 {
            tvBottom.isHidden = false
            isBottom = false
        }
    }
}

extension MessageController: ControllerEvent {
    func onTerminatedCall() {
        print("\(TAG) onTerminatedCall")
        isTerminated = true
        if isEnd {
            messageVM.chat = nil
            MoveTo.popController(ui: self, action: true)
        }
    }
    
    func onPCConnected() {
        print("\(TAG) onPCConnected")
        isTerminated = false
        isConnected = true
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

extension MessageController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        print("\(TAG) \(#function)")
        isEdit = true
        
        if etMessage.text == messagePlaceholder {
            etMessage.text = nil
            etMessage.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        print("\(TAG) \(#function)")
        isEdit = false
        
        if etMessage.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            etMessage.text = messagePlaceholder
            etMessage.textColor = .lightGray
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let inputString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let oldString = etMessage.text, let newRange = Range(range, in: oldString) else { return true }
        let newString = oldString.replacingCharacters(in: newRange, with: inputString).trimmingCharacters(in: .whitespacesAndNewlines)
        
        let characterCount = newString.count
        isEmptyMessage = characterCount == 0
        if isEmptyMessage {
            tvSend.tintColor = .lightGray
        } else {
            tvSend.tintColor = .tintColor
        }
        
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.contentSize.height >= maxMessageHeight {
            etMessageHeight.constant = maxMessageHeight
            textView.isScrollEnabled = true
        } else {
            etMessageHeight.constant = minMessageHeight
            textView.frame.size.height = textView.contentSize.height
            textView.isScrollEnabled = false
        }
    }
}
