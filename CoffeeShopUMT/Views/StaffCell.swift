import UIKit

protocol StaffCellDelegate: AnyObject {
    func resetTapped(for user: User)
    func editRoleTapped(for user: User)
    func disableTapped(for user: User)
}

final class StaffCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!

    weak var delegate: StaffCellDelegate?
    private var currentUser: User?

    func configure(with user: User) {
        currentUser = user
        nameLabel.text = user.fullName
        roleLabel.text = user.role
        emailLabel.text = user.email
    }

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
}