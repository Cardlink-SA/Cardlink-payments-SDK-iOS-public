//
//  ViewController.swift
//  ExampleApp
//
//  Created by Manolis Katsifarakis on 23/11/22.
//

import Cardlink_Mobile_Payments_SDK
import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var amount: UITextField!
    @IBOutlet weak var desc: UITextField!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var address: UITextField!
    @IBOutlet weak var city: UITextField!
    @IBOutlet weak var postCode: UITextField!
    @IBOutlet weak var frequency: UITextField!
    @IBOutlet weak var frequencyEndDate: UITextField!
    
    var datePicker: UIDatePicker?
    
    let dateFormatter: DateFormatter = {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "YYYYMMdd"
        return dateformatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        datePicker = UIDatePicker(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 200))
        datePicker?.datePickerMode = .date
        datePicker?.minimumDate = Date()
        if #available(iOS 13.4, *) {
            datePicker?.preferredDatePickerStyle = .wheels
        }
        datePicker?.addTarget(self, action: #selector(self.dateChanged), for: .allEvents)
        frequencyEndDate.inputView = datePicker
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.datePickerDone))
        let clearButton = UIBarButtonItem(title: "Clear", style: .done, target: self, action: #selector(self.clearButtonTapped))
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 44))
        toolBar.setItems([UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil), clearButton,
                          UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil), doneButton], animated: true)
        frequencyEndDate.inputAccessoryView = toolBar
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared.enable = false
        IQKeyboardManager.shared.enableAutoToolbar = false
    }
    
    @objc func clearButtonTapped() {
        frequencyEndDate.text = ""
    }
    
    @objc func datePickerDone() {
        frequencyEndDate.resignFirstResponder()
    }
    
    @objc func dateChanged() {
        guard let datePicker = datePicker else { return }
        frequencyEndDate.text = "\(datePicker.date)"
    }
    
    @IBAction func payTapped() {
        validateAndPay()
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == postCode {
            view.endEditing(true)
            pay()
            return true
        }
        
        IQKeyboardManager.shared.goNext()
        return true
    }
}

private extension ViewController {
    func validateAndPay() {
        let amountInt = UInt(amount.text ?? "") ?? 0
        if amountInt < 1 {
            amount.becomeFirstResponder()
            return
        }
        
        let isNotValid = isEmpty(desc)
        || isEmpty(name)
        || isEmpty(address)
        || isEmpty(city)
        || isEmpty(postCode)
        
        if (isNotValid) {
            return
        }
        
        view.endEditing(true)
        DispatchQueue.main.async { [weak self] in
            self?.pay()
        }
    }
    
    func pay() {
        let amountInt = UInt(amount.text ?? "") ?? 0
        let frequency = Int(frequency.text ?? "")
        CardlinkSDK(
            serverURL: URL(string: "https://in-app-payments.novidea.gr/")!
        ).makePayment(
            present: self,
            amount: amountInt,
            description: desc.text ?? "",
            TDS2CardHolderName: name.text ?? "",
            TDS2BillAddrCity: city.text ?? "",
            TDS2BillAddrLine1: address.text ?? "",
            TDS2BillAddrPostCode: postCode.text ?? "",
            frequency: frequency,
            frequencyEndDate: frequency ?? .zero > .zero ? getDateString() : ""
        )
    }
    
    func getDateString() -> String {
        guard let date = datePicker?.date else { return "" }
        
        return dateFormatter.string(from: date)
    }
    
    func isEmpty(_ textField: UITextField) -> Bool {
        let isEmpty = textField.text?.isEmpty != false
        if isEmpty {
            textField.becomeFirstResponder()
        }
        
        return isEmpty
    }
}

