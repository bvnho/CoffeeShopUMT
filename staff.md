# 🎨 BẢN THIẾT KẾ UI & LOGIC: QUẢN LÝ NHÂN VIÊN (ROASTMASTER POS)

## 📌 PHẦN 1: MÃ MÀU CHỦ ĐẠO (THEME)
- **Nền ứng dụng (App Background):** `#221910` (Nâu đen tối)
- **Nền Thẻ / Ô nhập liệu (Card/Input Background):** `#1C140D` hoặc `#2A1F17`
- **Màu nhấn (Accent / Buttons):** `#BD660F` (Cam đất)
- **Màu chữ (Text):** Trắng (Primary), Xám nhạt (Secondary)

---

## 🏗 PHẦN 2: KÉO THẢ STORYBOARD & AUTO LAYOUT

### Màn hình 1: StaffListViewController (Danh Sách)
1. **View gốc:** Đổi màu nền thành `#221910`.
2. **Top Header (100pt):** - `UIView` neo Top(0 - Safe Area), Leading(0), Trailing(0). 
   - Kéo `UILabel` "Staff Management" vào góc trái dưới của khối này.
3. **Thanh Tìm Kiếm (`UISearchBar`):** - Neo Top(0 - nối Header), Leading/Trailing(16). Đổi màu nền trong suốt.
4. **Bảng Danh Sách (`UITableView`):**
   - Neo Top(0 - nối SearchBar), Bottom/Leading/Trailing(0). Background = Clear Color.
5. **StaffCell (Thẻ Nhân Viên):**
   - Nền Card (`UIView`): Neo 8-8-16-16 so với Cell.
   - Avatar (`UIImageView`): 50x50, neo góc trái trên của Card.
   - Thông tin (`UIStackView` dọc): Tên, Role, Email. Neo sát cạnh Avatar.
   - Nút Thao Tác (`UIStackView` ngang): Reset, Edit, Disable. Nằm sát đáy Card (Bottom = 16), cao 36pt.
6. **Nút FAB (+):** - Đè lên TableView, góc phải dưới. Width/Height 60x60.

### Màn hình 2: CreateStaffViewController (Form Thêm Mới)
1. **ScrollView & ContentView:**
   - Bọc ScrollView full màn hình (0-0-0-0).
   - ContentView neo 0-0-0-0 vào ScrollView và chọn Equal Widths với View gốc.
2. **FormStackView (Dọc, Spacing 24):**
   - Chứa 4 nhóm nhập liệu (FullName, Username, Password, Role).
   - Mỗi ô `UITextField` ép cứng Height = 50.
3. **Nút Chốt Đáy (Grant Account & Cancel):**
   - Nằm cuối ContentView. Ép cứng Height = 50.
   - **BẮT BUỘC:** Neo Bottom = 30 vào ContentView để cuộn được.

---

## 💻 PHẦN 3: SWIFT CODE - GỌT GIŨA GIAO DIỆN

Để giao diện bo góc mượt mà và viền text field sắc nét giống hệt thiết kế, chúng ta sẽ viết code can thiệp vào file ViewController. 

*Lưu ý: Bạn cần tạo một extension `UIColor(hex:)` trong project để tái sử dụng mã màu.*

### 1. Code cho `CreateStaffViewController.swift`

```swift
import UIKit

class CreateStaffViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var roleButton: UIButton!
    @IBOutlet weak var grantAccountButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var identityIconView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Gọt giũa UI bằng Code
    private func setupUI() {
        // 1. Ẩn thanh Navigation mặc định (Để không bị dư header)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. Định dạng các ô Text Field
        let textFields = [fullNameTextField, usernameTextField, passwordTextField]
        for tf in textFields {
            tf?.backgroundColor = UIColor(hex: "#1C140D") // Màu nền ô nhập
            tf?.layer.cornerRadius = 8
            tf?.layer.borderWidth = 1
            tf?.layer.borderColor = UIColor(hex: "#3D2B1F").cgColor // Viền xám nâu
            tf?.textColor = .white
            
            // Đẩy chữ thò vào trong 16pt cho đẹp (Padding)
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: tf?.frame.height ?? 50))
            tf?.leftView = paddingView
            tf?.leftViewMode = .always
        }
        
        // 3. Định dạng nút Role (Làm cho giống ô nhập liệu)
        roleButton.backgroundColor = UIColor(hex: "#1C140D")
        roleButton.layer.cornerRadius = 8
        roleButton.layer.borderWidth = 1
        roleButton.layer.borderColor = UIColor(hex: "#3D2B1F").cgColor
        roleButton.setTitleColor(.white, for: .normal)
        
        // 4. Định dạng nút Grant Account (Nút chính)
        grantAccountButton.backgroundColor = UIColor(hex: "#BD660F")
        grantAccountButton.layer.cornerRadius = 8
        grantAccountButton.setTitleColor(.white, for: .normal)
        
        // 5. Định dạng nút Cancel (Nút phụ, trong suốt có viền)
        cancelButton.backgroundColor = .clear
        cancelButton.layer.cornerRadius = 8
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor.darkGray.cgColor
        cancelButton.setTitleColor(.lightGray, for: .normal)
        
        // 6. Định dạng viền đứt nét cho Identity Icon (Tùy chọn)
        identityIconView.layer.cornerRadius = identityIconView.frame.height / 2
        identityIconView.layer.borderWidth = 1
        identityIconView.layer.borderColor = UIColor(hex: "#BD660F").cgColor
    }
    
    // MARK: - IBActions
    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}