//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import UIKit
import SafeUIKit
import Common

public class CardViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var wrapperAroundContentStackView: UIView!
    @IBOutlet weak var contentStackView: UIStackView!

    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var subtitleDetailLabel: UILabel!

    @IBOutlet weak var cardView: CardView!
    @IBOutlet weak var cardStackView: UIStackView!

    @IBOutlet weak var cardHeaderView: UIView!
    @IBOutlet weak var cardBodyView: UIView!

    @IBOutlet weak var cardSeparatorView: UIView!

    @IBOutlet weak var footerButton: StandardButton!

    public override func viewDidLoad() {
        super.viewDidLoad()
        footerButton.style = .plain
        [view,
         scrollView,
         scrollContentView,
         wrapperAroundContentStackView,
         cardSeparatorView].forEach { view in
            view?.backgroundColor = ColorName.white.color
        }
        [cardView,
         cardHeaderView,
         cardBodyView].forEach { view in
            view?.backgroundColor = ColorName.snowwhite.color
        }

    }

    func embed(view: UIView, inCardSubview cardSubview: UIView, insets: UIEdgeInsets = .zero) {
        view.translatesAutoresizingMaskIntoConstraints = false
        cardSubview.addSubview(view)
        cardSubview.wrapAroundDynamicHeightView(view, insets: insets)
    }

    func setSubtitle(_ subtitle: String?, showError: Bool = false) {
        guard let subtitle = subtitle else {
            subtitleLabel.isHidden = true
            return
        }
        let subtitleText = NSMutableAttributedString()
        if showError {
            let attachment = NSTextAttachment(image: Asset.errorIcon.image,
                                              bounds: CGRect(x: 0, y: -2, width: 16, height: 16))
            subtitleText.append(attachment)
            subtitleText.append(" ")
        }
        subtitleText.append(NSAttributedString(string: subtitle, style: SubtitleStyle()))
        subtitleLabel.attributedText = subtitleText
    }

    func setSubtitleDetail(_ detail: String?) {
        guard let detail = detail else {
            subtitleDetailLabel.isHidden = true
            return
        }
        let detailText = NSMutableAttributedString(string: detail, style: DescriptionStyle())
        // non-breaking space before [?]
        detailText.append(NSAttributedString(string: "\u{00A0}[?]", style: SubtitleDetailRightButtonStyle()))

        subtitleDetailLabel.attributedText = detailText
        subtitleDetailLabel.addTarget(self, action: #selector(showNetworkFeeInfo))
    }

    @objc func showNetworkFeeInfo() {
        // override
    }

    class CommonTextStyle: DescriptionStyle {

        override var fontColor: UIColor { return ColorName.darkBlue.color }

    }

    class SubtitleStyle: DescriptionStyle {

        override var fontWeight: UIFont.Weight { return .semibold }

    }

    class SubtitleDetailRightButtonStyle: DescriptionStyle {

        override var fontColor: UIColor { return ColorName.hold.color }

    }

}


extension NSTextAttachment {

    convenience init(image: UIImage, bounds: CGRect = .zero) {
        self.init()
        self.image = image
        self.bounds = bounds
    }

}

extension UILabel {

    func addTarget(_ target: Any?, action: Selector) {
        isUserInteractionEnabled = true
        gestureRecognizers?.compactMap { $0 }.forEach { removeGestureRecognizer($0) }
        let recognizer = UITapGestureRecognizer(target: target, action: action)
        addGestureRecognizer(recognizer)
    }

}

extension NSMutableAttributedString {

    func append(_ string: String) {
        self.append(NSAttributedString(string: string))
    }

    func append(_ attachment: NSTextAttachment) {
        self.append(NSAttributedString(attachment: attachment))
    }
}
