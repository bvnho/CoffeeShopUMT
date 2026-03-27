import UIKit

// MARK: - Delegate

protocol StaffCellDelegate: AnyObject {
    func resetTapped(for user: User)
    func editRoleTapped(for user: User)
    func disableTapped(for user: User)
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

    /// Giữ tham chiếu nút Disable để đổi màu theo trạng thái isActive
    private weak var disableBtn: UIButton?

    // MARK: - Setup

    override func awakeFromNib() {
        super.awakeFromNib()
        addCardBackground()
        styleAvatar()
        styleLabels()
        wireAndStyleButtons()
    }

    // Card nền tối bo góc nằm bên dưới các subview hiện có
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
        // Avatar trong storyboard: fixedFrame 90×76 → cornerRadius ≈ 38 để gần tròn
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

    /// Duyệt cây subview để tìm 3 UIButton (Reset, Edit, Disable) theo thứ tự
    /// khai báo trong storyboard, rồi đặt style + addTarget programmatically.
    /// Lý do: storyboard dùng buttonConfiguration (iOS 15+) style="gray" nhưng
    /// không có <action> connection nối vào IBAction → nút không hoạt động.
    private func wireAndStyleButtons() {
        let btns = collectButtons(in: contentView)
        guard btns.count >= 3 else { return }

        apply(config: makeConfig(title: "Reset", bg: .appDisabled), to: btns[0])
        btns[0].addTarget(self, action: #selector(resetTapped(_:)), for: .touchUpInside)

        apply(config: makeConfig(title: "Edit",  bg: UIColor(hex: "#1e3a5f")!), to: btns[1])
        btns[1].addTarget(self, action: #selector(editRoleTapped(_:)), for: .touchUpInside)

        disableBtn = btns[2]
        apply(config: makeConfig(title: "Disable", bg: .appDanger), to: btns[2])
        btns[2].addTarget(self, action: #selector(disableTapped(_:)), for: .touchUpInside)
    }

    private func makeConfig(title: String, bg: UIColor) -> UIButton.Configuration {
        var c = UIButton.Configuration.filled()
        c.title              = title
        c.baseBackgroundColor = bg
        c.baseForegroundColor = .white
        c.cornerStyle        = .capsule
        c.contentInsets      = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
        c.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var a = attr; a.font = .systemFont(ofSize: 12, weight: .semibold); return a
        }
        return c
    }

    private func apply(config: UIButton.Configuration, to button: UIButton) {
        // Xoá target cũ (nếu có) trước khi thêm
        button.removeTarget(nil, action: nil, for: .allEvents)
        button.configuration = config
    }

    /// Duyệt theo chiều sâu (depth-first) — giữ đúng thứ tự Reset/Edit/Disable
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

        // Cần layout xong mới tính cornerRadius chính xác theo bounds thực
        layoutIfNeeded()
        avatarImageView.layer.cornerRadius = min(avatarImageView.bounds.width,
                                                  avatarImageView.bounds.height) / 2

        // Avatar: placeholder rồi load từ URL / base64
        avatarImageView.image    = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = .appTextSecondary
        if let url = user.profileImageURL, !url.isEmpty {
            loadAvatar(urlString: url)
        }

        // Đổi màu + title nút Disable theo isActive
        if let btn = disableBtn {
            let active = user.isActive
            apply(
                config: makeConfig(
                    title: active ? "Disable" : "Enable",
                    bg:    active ? .appDanger : .appSuccess
                ),
                to: btn
            )
            btn.addTarget(self, action: #selector(disableTapped(_:)), for: .touchUpInside)
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

    // MARK: - Actions (IBAction + @objc để storyboard hoặc addTarget đều dùng được)

    @IBAction func resetTapped(_ sender: UIButton) {
        guard let user = currentUser else { return }
        delegate?.resetTapped(for: user)
    }

    @IBAction func editRoleTapped(_ sender: UIButton) {
        guard let user = currentUser else { return }
        delegate?.editRoleTapped(for: user)
    }

    @IBAction func disableTapped(_ sender: UIButton) {
        guard let user = currentUser else { return }
        delegate?.disableTapped(for: user)
    }

    @objc private func handleAvatarTap() {
        guard let user = currentUser else { return }
        delegate?.avatarTapped(for: user)
    }
}
