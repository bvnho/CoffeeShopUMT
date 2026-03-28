import UIKit

// MARK: - Delegate

protocol StaffCellDelegate: AnyObject {
    func editTapped(for user: User)
    func deleteTapped(for user: User)
    func avatarTapped(for user: User)
}

// MARK: - Cell

final class StaffCell: UITableViewCell {

    // IBOutlets – kết nối trong Admin.storyboard
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!

    weak var delegate: StaffCellDelegate?
    private var currentUser: User?

    // MARK: - Setup

    override func awakeFromNib() {
        super.awakeFromNib()
        addCardBackground()
        styleAvatar()
        styleLabels()
        wireAndStyleButtons()
    }

    private func addCardBackground() {
        backgroundColor         = .clear
        contentView.backgroundColor = .clear
        selectionStyle          = .none

        let card = UIView()
        card.backgroundColor        = UIColor(hex: "#2e1c0e")
        card.layer.cornerRadius     = 16
        card.layer.masksToBounds    = true
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.insertSubview(card, at: 0)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])
    }

    private func styleAvatar() {
        guard let iv = avatarImageView else { return }
        iv.layer.cornerRadius   = 38
        iv.clipsToBounds        = true
        iv.layer.borderWidth    = 2
        iv.layer.borderColor    = UIColor.appAccent.cgColor
        iv.contentMode          = .scaleAspectFill
        iv.backgroundColor      = .appDisabled
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleAvatarTap))
        )
    }

    private func styleLabels() {
        nameLabel?.textColor  = .white
        nameLabel?.font       = .systemFont(ofSize: 15, weight: .bold)
        roleLabel?.textColor  = .appTextSecondary
        roleLabel?.font       = .systemFont(ofSize: 13)
        emailLabel?.textColor = UIColor.white.withAlphaComponent(0.75)
        emailLabel?.font      = .systemFont(ofSize: 13)
    }

    private func wireAndStyleButtons() {
        let btns = collectButtons(in: contentView)
        guard btns.count >= 2 else { return }

        // Edit button (index 0)
        apply(config: makeConfig(title: "Sửa", bg: UIColor(hex: "#1e3a5f")!), to: btns[0])
        btns[0].addTarget(self, action: #selector(editBtnTapped(_:)), for: .touchUpInside)

        // Delete button (index 1)
        apply(config: makeConfig(title: "Xóa", bg: .appDanger), to: btns[1])
        btns[1].addTarget(self, action: #selector(deleteBtnTapped(_:)), for: .touchUpInside)
    }

    private func makeConfig(title: String, bg: UIColor) -> UIButton.Configuration {
        var c = UIButton.Configuration.filled()
        c.title               = title
        c.baseBackgroundColor = bg
        c.baseForegroundColor = .white
        c.cornerStyle         = .capsule
        c.contentInsets       = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
        c.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var a = attr; a.font = .systemFont(ofSize: 13, weight: .semibold); return a
        }
        return c
    }

    private func apply(config: UIButton.Configuration, to button: UIButton) {
        button.removeTarget(nil, action: nil, for: .allEvents)
        button.configuration = config
    }

    private func collectButtons(in view: UIView) -> [UIButton] {
        var result: [UIButton] = []
        for sub in view.subviews {
            if let btn = sub as? UIButton { result.append(btn) }
            else { result += collectButtons(in: sub) }
        }
        return result
    }

    // MARK: - Configure

    func configure(with user: User) {
        currentUser = user
        nameLabel.text  = user.fullName
        roleLabel.text  = user.role
        emailLabel.text = user.email

        layoutIfNeeded()
        avatarImageView.layer.cornerRadius = min(avatarImageView.bounds.width,
                                                  avatarImageView.bounds.height) / 2

        avatarImageView.image    = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = .appTextSecondary
        if let url = user.profileImageURL, !url.isEmpty {
            loadAvatar(urlString: url)
        }
    }

    // MARK: - Avatar image loading

    private func loadAvatar(urlString: String) {
        if urlString.hasPrefix("data:image") {
            let b64 = urlString.components(separatedBy: ",").last ?? ""
            if let data = Data(base64Encoded: b64), let img = UIImage(data: data) {
                avatarImageView.image = img
            }
        } else if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { self?.avatarImageView.image = img }
            }.resume()
        }
    }

    // MARK: - Button actions

    @objc private func editBtnTapped(_ sender: UIButton) {
        guard let user = currentUser else { return }
        delegate?.editTapped(for: user)
    }

    @objc private func deleteBtnTapped(_ sender: UIButton) {
        guard let user = currentUser else { return }
        delegate?.deleteTapped(for: user)
    }

    @objc private func handleAvatarTap() {
        guard let user = currentUser else { return }
        delegate?.avatarTapped(for: user)
    }
}
