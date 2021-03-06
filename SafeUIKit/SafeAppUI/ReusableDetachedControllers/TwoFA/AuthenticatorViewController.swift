//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import UIKit
import SafeUIKit
import MultisigWalletApplication
import Common
import SafariServices

@objc
public protocol AuthenticatorViewControllerDelegate: class {

    func authenticatorViewController(_ controller: AuthenticatorViewController,
                                     didScanAddress address: String,
                                     code: String) throws
    func authenticatorViewControllerDidFinish()
    func didSelectOpenAuthenticatorInfo()
    @objc
    optional func authenticatorViewControllerDidSkipPairing()

}

public final class AuthenticatorViewController: CardViewController {

    enum Strings {
        static let title = LocalizedString("pair_2FA_device", comment: "Pair 2FA device")
        static let header = LocalizedString("ios_connect_browser_extension",
                                            comment: "Header for add browser extension screen")
            .replacingOccurrences(of: "\n", with: " ")
        static let description = LocalizedString("enable_2fa", comment: "Description for add browser extension screen")
        static let downloadExtension = LocalizedString("ios_open_be_link_text",
                                                       comment: "'Download the' Gnosis Safe Chrome browser exntension.")
        static let chromeExtension = LocalizedString("ios_open_be_link_substring",
                                                     comment: "Download the 'Gnosis Safe Chrome browser exntension.'")
        static let scanQRCode = LocalizedString("ios_install_browser_extension",
                                                comment: "Scan its QR code.")
        static let skipSetup = LocalizedString("skip_setup_later",
                                               comment: "Skip button text")
        static let scan = LocalizedString("scan",
                                          comment: "Scan button title in extension setup screen")
    }

    weak var delegate: AuthenticatorViewControllerDelegate?

    private var logger: Logger {
        return MultisigWalletApplication.ApplicationServiceRegistry.logger
    }
    private var walletService: WalletApplicationService {
        return MultisigWalletApplication.ApplicationServiceRegistry.walletService
    }
    private var ethereumService: EthereumApplicationService {
        return MultisigWalletApplication.ApplicationServiceRegistry.ethereumService
    }
    let twoFAView = TwoFAView()

    var downloadExtensionEnabled = true
    var scanBarButtonItem: ScanBarButtonItem!
    private var activityIndicator: UIActivityIndicatorView!
    var backButtonItem: UIBarButtonItem!
    private var didCancel = false

    public var screenTitle: String? = Strings.title {
        didSet {
            updateTexts()
        }
    }

    public var screenHeader: String = Strings.header {
        didSet {
            updateTexts()
        }
    }

    public var descriptionText: String = Strings.description {
        didSet {
            updateTexts()
        }
    }

    public var hidesSkipButton: Bool = false {
        didSet {
            updateSkipButton()
        }
    }

    public var screenTrackingEvent: Trackable = TwoFATrackingEvent.connectAuthenticator
    public var scanTrackingEvent: Trackable = TwoFATrackingEvent.connectAuthenticatorScan

    public static func create(delegate: AuthenticatorViewControllerDelegate?) -> AuthenticatorViewController {
        let controller = AuthenticatorViewController(nibName: String(describing: CardViewController.self),
                                                     bundle: Bundle(for: CardViewController.self))
        controller.delegate = delegate
        return controller
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        backButtonItem = UIBarButtonItem.backButton(target: self, action: #selector(back))

        embed(view: twoFAView, inCardSubview: cardHeaderView)
        subtitleLabel.isHidden = true
        subtitleDetailLabel.isHidden = true
        cardBodyView.isHidden = true
        cardSeparatorView.isHidden = true

        configureScanButton()
        configureActivityIndicator()
        configureStepsLabels()
        configureSkipButton()
        updateTexts()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(screenTrackingEvent)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        didCancel = false
        setCustomBackButton(backButtonItem)
    }

    public func showLoadingTitle() {
        navigationItem.titleView = LoadingTitleView()
    }

    public func hideLoadingTitle() {
        navigationItem.titleView = nil
    }

    func updateTexts() {
        guard isViewLoaded else { return }
        title = screenTitle
        twoFAView.headerLabel.text = screenHeader
        twoFAView.body1Label.text = descriptionText
    }

    func updateSkipButton() {
        footerButton?.isHidden = hidesSkipButton
    }

    @objc func back() {
        didCancel = true
    }

    func handleError(_ error: Error) {
        let err = (error as? WalletApplicationServiceError) ?? WalletApplicationServiceError.networkError
        showError(message: err.localizedDescription, log: err.localizedDescription)
    }

    private func configureScanButton() {
        scanBarButtonItem = ScanBarButtonItem(title: Strings.scan)
        scanBarButtonItem.delegate = self
        scanBarButtonItem.scanValidatedConverter = ethereumService.address(browserExtensionCode:)
        addDebugButtons()
        showScanButton()
    }

    private func configureActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        activityIndicator.color = ColorName.hold.color
    }

    private func configureSkipButton() {
        footerButton.setTitle(Strings.skipSetup, for: .normal)
        footerButton.isHidden = hidesSkipButton
        footerButton.addTarget(self, action: #selector(skipPairing(_:)), for: .touchUpInside)
    }

    private func configureStepsLabels() {
        let body2Text = NSMutableAttributedString(string: Strings.downloadExtension)
        let range = body2Text.mutableString.range(of: Strings.chromeExtension)
        body2Text.addAttribute(.foregroundColor, value: ColorName.hold.color, range: range)
        twoFAView.body2Label.attributedText = body2Text
        twoFAView.body2Label.isUserInteractionEnabled = true
        twoFAView.body2Label.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                         action: #selector(downloadBrowserExtension)))
        twoFAView.body3Label.text = Strings.scanQRCode
    }

    @objc private func downloadBrowserExtension() {
        guard downloadExtensionEnabled else { return }
        delegate?.didSelectOpenAuthenticatorInfo()
    }

    private func disableButtons() {
        scanBarButtonItem?.isEnabled = false
        footerButton?.isEnabled = false
        downloadExtensionEnabled = false
    }

    private func enableButtons() {
        scanBarButtonItem?.isEnabled = true
        footerButton?.isEnabled = true
        downloadExtensionEnabled = true
    }

    private func processValidCode(_ code: String) {
        let address = scanBarButtonItem.scanValidatedConverter!(code)!
        do {
            try self.delegate?.authenticatorViewController(self, didScanAddress: address, code: code)
            if self.didCancel { return }
            trackEvent(OnboardingTrackingEvent.twoFAScanSuccess)
            DispatchQueue.main.async {
                self.delegate?.authenticatorViewControllerDidFinish()
            }
        } catch let e {
            if self.didCancel { return }
            DispatchQueue.main.async {
                self.handleError(e)
            }
        }
    }

    private func showError(message: String, log: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController.operationFailed(message: message)
            self.present(alert, animated: true, completion: nil)
            ApplicationServiceRegistry.logger.error(log)
        }
    }

    private func showActivityIndicator() {
        DispatchQueue.main.async {
            let activityButton = UIBarButtonItem(customView: self.activityIndicator)
            self.activityIndicator.startAnimating()
            self.navigationItem.rightBarButtonItem = activityButton
        }
    }

    private func showScanButton() {
        navigationItem.rightBarButtonItem = scanBarButtonItem
    }

    @IBAction func skipPairing(_ sender: Any) {
        delegate?.authenticatorViewControllerDidSkipPairing?()
    }

    // MARK: - Debug Buttons

    private let validCodeTemplate = """
        {
            "expirationDate" : "%@",
            "signature": {
                "v" : 27,
                "r" : "15823297914388465068645274956031579191506355248080856511104898257696315269079",
                "s" : "38724157826109967392954642570806414877371763764993427831319914375642632707148"
            }
        }
        """

    private func addDebugButtons() {
        scanBarButtonItem.addDebugButtonToScannerController(
            title: "Scan Valid Code", scanValue: validCode(timeIntervalSinceNow: 5 * 60))
        scanBarButtonItem.addDebugButtonToScannerController(
            title: "Scan Invalid Code", scanValue: "invalid_code")
        scanBarButtonItem.addDebugButtonToScannerController(
            title: "Scan Expired Code", scanValue: validCode(timeIntervalSinceNow: -5 * 60))
    }

    private func validCode(timeIntervalSinceNow: TimeInterval) -> String {
        let dateStr = DateFormatter.networkDateFormatter.string(from: Date(timeIntervalSinceNow: timeIntervalSinceNow))
        return String(format: validCodeTemplate, dateStr)
    }

}

extension AuthenticatorViewController: ScanBarButtonItemDelegate {

    public func scanBarButtonItemWantsToPresentController(_ controller: UIViewController) {
        present(controller, animated: true)
        trackEvent(scanTrackingEvent)
    }

    public func scanBarButtonItemDidScanValidCode(_ code: String) {
        disableButtons()
        showLoadingTitle()
        DispatchQueue.global().async {
            self.processValidCode(code)
            DispatchQueue.main.async {
                self.hideLoadingTitle()
                self.enableButtons()
            }
        }
    }

}
