/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import DeliteAI
import SwiftProtobuf

@available(iOS 13.0, *)
class ViewController: UIViewController {

    // MARK: - UI Components
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var initializeButton: UIButton!
    @IBOutlet weak var companyNameTextField: UITextField!
    @IBOutlet weak var companyIdTextField: UITextField!
    @IBOutlet weak var employeeNameTextField: UITextField!
    @IBOutlet weak var employeeIdTextField: UITextField!
    @IBOutlet weak var runTestButton: UIButton!
    @IBOutlet weak var resultTextView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var scrollView: UIScrollView!

    // MARK: - Properties
    private var isSDKInitialized = false
    private var isSDKReady = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardObservers()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Configure title
        titleLabel.text = "DeliteAI iOS SDK Demo"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center

        // Configure status
        statusLabel.text = "SDK Not Initialized"
        statusLabel.textColor = .systemRed
        statusLabel.textAlignment = .center

        // Configure buttons
        setupButton(initializeButton, title: "Initialize SDK", color: .systemBlue)
        setupButton(runTestButton, title: "Run AI Test", color: .systemGreen)
        runTestButton.isEnabled = false

        // Configure text fields
        setupTextField(companyNameTextField, placeholder: "Enter Company Name", defaultText: "TechCorp")
        setupTextField(companyIdTextField, placeholder: "Enter Company ID", defaultText: "12345")
        setupTextField(employeeNameTextField, placeholder: "Enter Employee Name", defaultText: "John Doe")
        setupTextField(employeeIdTextField, placeholder: "Enter Employee ID", defaultText: "E001")

        // Configure result text view
        resultTextView.layer.borderColor = UIColor.systemGray4.cgColor
        resultTextView.layer.borderWidth = 1.0
        resultTextView.layer.cornerRadius = 8.0
        resultTextView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        resultTextView.text = "Results will appear here..."
        resultTextView.isEditable = false

        // Configure activity indicator
        activityIndicator.hidesWhenStopped = true
    }

    private func setupButton(_ button: UIButton, title: String, color: UIColor) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8.0
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
    }

    private func setupTextField(_ textField: UITextField, placeholder: String, defaultText: String) {
        textField.placeholder = placeholder
        textField.text = defaultText
        textField.borderStyle = .roundedRect
        textField.font = UIFont.systemFont(ofSize: 16)
    }

    // MARK: - Keyboard Handling
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    // MARK: - Actions
    @IBAction func initializeButtonTapped(_ sender: UIButton) {
        initializeSDK()
    }

    @IBAction func runTestButtonTapped(_ sender: UIButton) {
        runAITest()
    }

    // MARK: - SDK Integration
    private func initializeSDK() {
        activityIndicator.startAnimating()
        initializeButton.isEnabled = false
        statusLabel.text = "Initializing SDK..."
        statusLabel.textColor = .systemOrange

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let config = NimbleNetConfig(
                clientId: "testclient",
                clientSecret: BundleConfig.clientSecret,
                host: BundleConfig.host,
                deviceId: "hello-ios",
                debug: true,
                compatibilityTag: "proto-test",
                online: true
            )

            let initResult = NimbleNetApi.initialize(config: config)

            DispatchQueue.main.async {
                self?.handleInitializationResult(initResult)
            }
        }
    }

    private func handleInitializationResult(_ result: NimbleNetResult<Void>) {
        activityIndicator.stopAnimating()
        initializeButton.isEnabled = true

        if result.status {
            isSDKInitialized = true
            statusLabel.text = "SDK Initialized - Checking Readiness..."
            statusLabel.textColor = .systemOrange
            appendToResults("✅ SDK Initialization: SUCCESS")
            checkSDKReadiness()
        } else {
            statusLabel.text = "SDK Initialization Failed"
            statusLabel.textColor = .systemRed
            appendToResults("❌ SDK Initialization: FAILED - \(result.error?.message ?? "Unknown error")")
        }
    }

    private func checkSDKReadiness() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var attempts = 0
            let maxAttempts = 30

            while attempts < maxAttempts {
                let readyResult = NimbleNetApi.isReady()

                DispatchQueue.main.async {
                    if readyResult.status {
                        self?.handleSDKReady()
                        return
                    } else {
                        self?.statusLabel.text = "Waiting for SDK Ready... (\(attempts + 1)/\(maxAttempts))"
                    }
                }

                if readyResult.status {
                    break
                }

                Thread.sleep(forTimeInterval: 1)
                attempts += 1
            }

            if attempts >= maxAttempts {
                DispatchQueue.main.async {
                    self?.handleSDKTimeout()
                }
            }
        }
    }

    private func handleSDKReady() {
        isSDKReady = true
        statusLabel.text = "SDK Ready ✅"
        statusLabel.textColor = .systemGreen
        runTestButton.isEnabled = true
        appendToResults("✅ SDK Ready: SUCCESS")
    }

    private func handleSDKTimeout() {
        statusLabel.text = "SDK Ready Timeout ⚠️"
        statusLabel.textColor = .systemRed
        appendToResults("⚠️ SDK Ready: TIMEOUT after 30 seconds")
    }

    private func runAITest() {
        guard isSDKInitialized && isSDKReady else {
            showAlert(title: "Error", message: "SDK is not ready. Please initialize first.")
            return
        }

        guard let companyName = companyNameTextField.text, !companyName.isEmpty,
              let companyId = companyIdTextField.text, !companyId.isEmpty,
              let employeeName = employeeNameTextField.text, !employeeName.isEmpty,
              let employeeId = employeeIdTextField.text, !employeeId.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields.")
            return
        }

        activityIndicator.startAnimating()
        runTestButton.isEnabled = false

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = self?.executeAITest(companyName: companyName, companyId: companyId, employeeName: employeeName, employeeId: employeeId)

            DispatchQueue.main.async {
                self?.handleAITestResult(result)
            }
        }
    }

    private func executeAITest(companyName: String, companyId: String, employeeName: String, employeeId: String) -> NimbleNetResult<NimbleNetOutput>? {
        // Create company data structure
        var company = Generated_Company()
        company.companyID = companyId
        company.companyName = companyName

        // Create departments
        var engineeringDept = Generated_Company.Department()
        engineeringDept.departmentID = 1
        engineeringDept.departmentName = "Engineering"

        var managementDept = Generated_Company.Department()
        managementDept.departmentID = 2
        managementDept.departmentName = "Management"

        // Create employee
        var employee = Generated_Company.Department.Employee()
        employee.employeeID = employeeId
        employee.name = employeeName
        employee.title = "Software Engineer"

        // Create contact info
        var contactInfo = Generated_Company.Department.Employee.ContactInfo()
        contactInfo.phone = "+1234567890"

        // Create address
        var address = Generated_Address()
        address.street = "123 Main St"
        address.city = "San Francisco"
        address.state = "CA"
        address.zipCode = "94105"
        address.additionalInfo["landmark"] = "Near Central Park"

        // Register and set address
        Google_Protobuf_Any.register(messageType: Generated_Address.self)
        do {
            contactInfo.address = try Google_Protobuf_Any(message: address)
            employee.contactInfo = contactInfo
        } catch {
            print("Error setting address: \(error)")
        }

        // Create project
        var project = Generated_Company.Department.Employee.Project()
        project.projectID = "P001"
        project.projectName = "AI Research"
        project.role = "Lead Developer"

        // Assemble data structure
        employee.projects.append(project)
        engineeringDept.employees.append(employee)
        company.departments.append(engineeringDept)
        company.departments.append(managementDept)

        // Create model inputs
        let modelInputs = [
            "inputData": NimbleNetTensor(
                data: company,
                datatype: DataType.FE_OBJ,
                shape: nil
            )
        ]

        // Run the AI method
        return NimbleNetApi.runMethod(methodName: "test_as_is", inputs: modelInputs)
    }

    private func handleAITestResult(_ result: NimbleNetResult<NimbleNetOutput>?) {
        activityIndicator.stopAnimating()
        runTestButton.isEnabled = true

        guard let result = result else {
            appendToResults("❌ AI Test: FAILED - No result returned")
            return
        }

        if result.status {
            appendToResults("✅ AI Test: SUCCESS")
            if let payload = result.payload {
                appendToResults("📊 Result Data: \(payload)")
            }
        } else {
            appendToResults("❌ AI Test: FAILED - \(result.error?.message ?? "Unknown error")")
        }
    }

    // MARK: - Helper Methods
    private func appendToResults(_ text: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logEntry = "[\(timestamp)] \(text)\n"

        if resultTextView.text == "Results will appear here..." {
            resultTextView.text = logEntry
        } else {
            resultTextView.text += logEntry
        }

        // Scroll to bottom
        let bottom = NSMakeRange(resultTextView.text.count - 1, 1)
        resultTextView.scrollRangeToVisible(bottom)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

// MARK: - Extensions
@available(iOS 13.0, *)
extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
