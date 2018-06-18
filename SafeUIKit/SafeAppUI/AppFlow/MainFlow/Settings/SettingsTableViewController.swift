//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import UIKit

public class SettingsTableViewController: UITableViewController {

    private var settings = [(section: SettingsSection, cellHeight: CGFloat, items: [Any])]()

    private enum Strings {
        static let createSafe = LocalizedString("settings.action.create_safe", comment: "Create new Safe menu item")
        static let recoverSafe = LocalizedString("settings.action.recover_safe", comment: "Recover Safe menu item")
        static let manageTokens = LocalizedString("settings.action.manage_tokens", comment: "Manage Tokens menu item")
        static let addressBook = LocalizedString("settings.action.address_book", comment: "Address Book menu item")
        static let generalSettings = LocalizedString("settings.action.general_settings",
                                                     comment: "General Settings menu item")
    }

    public static func create() -> SettingsTableViewController {
        return StoryboardScene.Main.settingsTableViewController.instantiate()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        generateData()
    }

    private func generateData() {
        settings = [
            (.selectedSafe, 90,
             [
                SafeDescription(address: "0x5a0b54d5dc17e0aadc383d2db43b0a0d3e029c4c",
                                name: "Tobias Funds",
                                image: UIImage.createBlockiesImage(seed: "0x5a0b54d5dc17e0aadc383d2db43b0a0d3e029c4c"))
             ]),
            (.safeList, 80,
             [
                SafeDescription(address: "0x40e5bcfece45f3a61a88e5445ba342f89629e301",
                                name: "VC Safe Public Fundraiser Fund",
                                image: UIImage.createBlockiesImage(seed: "0x40e5bcfece45f3a61a88e5445ba342f89629e301")),
                SafeDescription(address: "0x72558bf6ab0a70a3469e32719b8778f8aa41c1db",
                                name: "GNO Honey Pot",
                                image: UIImage.createBlockiesImage(seed: "0x72558bf6ab0a70a3469e32719b8778f8aa41c1db")),
                SafeDescription(address: "0x41e98fb1abced605b475f8cc8110f7ae0ae4ccd9",
                                name: "Untitled",
                                image: UIImage.createBlockiesImage(seed: "0x41e98fb1abced605b475f8cc8110f7ae0ae4ccd9"))
             ]),
            (.menuItems, 54,
             [
                MenuItem(name: Strings.createSafe, icon: Asset.TokenIcons.eth.image),
                MenuItem(name: Strings.recoverSafe, icon: Asset.TokenIcons.btc.image),
                MenuItem(name: Strings.manageTokens, icon: Asset.TokenIcons.gnt.image),
                MenuItem(name: Strings.addressBook, icon: Asset.TokenIcons.ada.image),
                MenuItem(name: Strings.generalSettings, icon: Asset.TokenIcons.steem.image)
             ])
        ]
    }

    // MARK: - Table view data source

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings[section].items.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch settings[indexPath.section].section {
        case .selectedSafe:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SelectedSafeTableViewCell", for: indexPath)
                as! SelectedSafeTableViewCell
            cell.configure(safe: settings[indexPath.section].items[indexPath.row] as! SafeDescription)
            return cell
        case .safeList:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SafeTableViewCell", for: indexPath)
                as! SafeTableViewCell
            cell.configure(safe: settings[indexPath.section].items[indexPath.row] as! SafeDescription)
            return cell
        case .menuItems:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MenuItemTableViewCell", for: indexPath)
                as! MenuItemTableViewCell
            cell.configure(menuItem: settings[indexPath.section].items[indexPath.row] as! MenuItem)
            return cell

        }
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return settings[indexPath.section].cellHeight
    }

}

struct SafeDescription {
    var address: String
    var name: String
    var image: UIImage
}

struct MenuItem {
    var name: String
    var icon: UIImage
}

enum SettingsSection: Hashable {
    case selectedSafe
    case safeList
    case menuItems
}