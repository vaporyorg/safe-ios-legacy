//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import UIKit
import SafeUIKit
import Common
import MultisigWalletApplication

class BasicPaymentMethodViewController: UIViewController {

    var tokens = [TokenData]()
    var paymentToken: TokenData!

    let tableView = UITableView(frame: CGRect.zero, style: .grouped)
    var topViewHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorName.paleGrey.color

        let topView = UIView()
        topView.backgroundColor = .white
        topView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topView)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UINib(nibName: "BasicTableViewCell", bundle: Bundle(for: BasicTableViewCell.self)),
                           forCellReuseIdentifier: "BasicTableViewCell")
        tableView.rowHeight = BasicTableViewCell.tokenDataCellHeight
        registerHeaderAndFooter()
        tableView.separatorStyle = .none
        view.addSubview(tableView)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(updateData), for: .valueChanged)
        tableView.refreshControl = refreshControl

        topViewHeightConstraint = topView.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            topView.leftAnchor.constraint(equalTo: view.leftAnchor),
            topView.topAnchor.constraint(equalTo: view.topAnchor),
            topView.rightAnchor.constraint(equalTo: view.rightAnchor),
            topViewHeightConstraint,
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateData()
    }

    func registerHeaderAndFooter() {
        preconditionFailure("To override")
    }

    /// Called on viewWillAppear and on refresh triggering.
    @objc func updateData() {
        preconditionFailure("To override")
    }

    /// Used for CreationFeeIntroViewController, CreationFeePaymentMethodViewController.
    /// Updates view model and reloads table view.
    ///
    /// - Parameter estimations: operation estimations in different payment methods.
    func update(with estimations: [TokenData]) {
        self.tokens = estimations
        var paymentMethodData = ApplicationServiceRegistry.walletService.feePaymentTokenData
        var estimationBalance = estimations.first { $0.address == paymentMethodData.address }?.balance
        if estimationBalance == nil && !estimations.isEmpty {
            // Selected wallet payment method is not amoung estimations. As a fallback we set payment method to Eth.
            ApplicationServiceRegistry.walletService.changePaymentToken(TokenData.Ether)
            paymentMethodData = ApplicationServiceRegistry.walletService.feePaymentTokenData
            estimationBalance = estimations.first { $0.address == paymentMethodData.address }!.balance
        }
        self.paymentToken = paymentMethodData.withBalance(estimationBalance)
        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
    }

}

// MARK: - Table view data source

extension BasicPaymentMethodViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tokens.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicTableViewCell",
                                                 for: indexPath) as! BasicTableViewCell
        let tokenData = tokens[indexPath.row]
        cell.configure(tokenData: tokenData,
                       displayBalance: true,
                       displayFullName: false,
                       accessoryType: .none)
        cell.accessoryView = tokenData.address == paymentToken.address ? checkmarkImageView() : emptyImageView()
        cell.rightTrailingConstraint.constant = 14
        if tokenData.balance ?? 0 == 0 {
            cell.selectionStyle = .none
            cell.leftTextLabel.textColor = ColorName.darkSlateBlue.color.withAlphaComponent(0.5)
            cell.rightTextLabel.textColor = ColorName.darkSlateBlue.color.withAlphaComponent(0.5)
            cell.leftImageView.alpha = 0.5
        }
        return cell
    }

    private func checkmarkImageView() -> UIImageView {
        let checkmarkImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 13))
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.image = Asset.checkmark.image
        return checkmarkImageView
    }

    private func emptyImageView() -> UIImageView {
        return UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 13))
    }

}

// MARK: - Table view delegate

extension BasicPaymentMethodViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let tokenData = tokens[indexPath.row]
        guard tokenData.balance ?? 0 > 0 else { return }
        ApplicationServiceRegistry.walletService.changePaymentToken(tokenData)
        paymentToken = ApplicationServiceRegistry.walletService.feePaymentTokenData
        tableView.reloadData()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentOffset.y <= 0 else { return }
        topViewHeightConstraint.constant = abs(scrollView.contentOffset.y)
    }

}
