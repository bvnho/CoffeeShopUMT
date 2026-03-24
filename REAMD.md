CoffeeShopUMT (Thư mục màu xanh dương gốc)
│
├── App/                        # Chứa các file hệ thống
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── Assets.xcassets         # Chứa hình ảnh, logo, icon
│   └── Info.plist
│
├── Models/                     # Chứa Schema dữ liệu (Firebase)
│   ├── User.swift              # Chứa role (admin/staff), tên, lương...
│   ├── MenuItem.swift          # Chứa tên món, giá tiền, hình ảnh...
│   ├── Order.swift             # Chứa mã bill, trạng thái đơn, tổng tiền...
│   └── Table.swift             # Chứa mã bàn, trạng thái (trống/có khách)...
│
├── Services/                   # Nơi giao tiếp với Firebase
│   ├── AuthService.swift       # Xử lý Login, Đổi mật khẩu
│   └── DatabaseService.swift   # Xử lý lấy/thêm/sửa/xóa Món, Đơn hàng, Bàn
│
├── Storyboards/                # File giao diện Kéo thả
│   ├── Auth.storyboard         # Giao diện Login
│   ├── Admin.storyboard        # Chứa TabBar và các luồng của Admin
│   ├── Staff.storyboard        # Chứa TabBar và các luồng của Staff
│   └──Shared.storyboard        # Chứa các màn hình dùng chung (POS, Zone Layout, Order Detail)
│   
├── Views/                      # (Tùy chọn) Chứa giao diện các Cell lặp đi lặp lại
│   ├── ItemCollectionViewCell.swift  # Cái ô vuông hiển thị ly cafe trong POS
│   ├── OrderTableViewCell.swift      # Cái thanh dài hiển thị bill trong Kitchen
│   └── TableCollectionViewCell.swift # Cái ô hiển thị bàn T-01, T-02
│
└── Controllers/                # NƠI CHỨA CÁC FILE ĐIỀU KHIỂN MÀN HÌNH
    │
    ├── Auth/                   # 1. Luồng Đăng nhập
    │   └── LoginViewController.swift
    │
    ├── Shared/                 # 2. LUỒNG DÙNG CHUNG CẢ ADMIN & STAFF
    │   ├── POSViewController.swift         # Màn hình chọn món (POS)
    │   ├── TableLayoutViewController.swift # Màn hình sơ đồ bàn (Zone Layout)
    │   └── GeneratedOrderViewController.swift # Cái pop-up (Bottom sheet) khi bấm vào bàn
    │
    ├── Admin/                  # 3. LUỒNG DÀNH RIÊNG CHO ADMIN
    │   ├── Dashboard/
    │   │   ├── DashboardViewController.swift     # Màn hình Analytics, Revenue
    │   │   ├── RevenueDetailViewController.swift # Chi tiết danh sách doanh thu
    │   │   └── OrderStatusViewController.swift   # Màn hình Orders In Progress / Completed
    │   │
    │   ├── MenuManagement/
    │   │   ├── MenuListViewController.swift      # Danh sách món ăn
    │   │   └── AddMenuItemViewController.swift   # Form thêm món mới
    │   │
    │   ├── StaffManagement/
    │   │   ├── StaffListViewController.swift     # Danh sách nhân viên & Payroll
    │   │   └── CreateStaffViewController.swift   # Form tạo tài khoản nhân viên
    │   │
    │   └── Profile/
    │       ├── AdminProfileViewController.swift  # Pop-up thông tin Admin
    │       └── AdminResetPasswordViewController.swift 
    │
    └── Staff/                  # 4. LUỒNG DÀNH RIÊNG CHO STAFF
        ├── KitchenDisplay/
        │   └── KitchenDisplayViewController.swift # Màn hình bếp (Active / Completed)
        │
        └── Settings/
            ├── StaffProfileViewController.swift   # Màn hình Body (Clock in/out)
            └── ResetPasswordViewController.swift  # Form đổi mật khẩu của Staff


màu nền: 221910( nâu)

màu cho các ô: BD660F(cam)

màu tick thành công: 10B981 (xanh lá)

fail: EF4444 ( đỏ)

màu làm mờ khi ko dùng đến nút đó: 334155 (xám)





**QUAN TRỌNG:** TÔI SẼ TỰ THIẾT KẾ GIAO DIỆN BẰNG KÉO THẢ XCODE STORYBOARD.
Tuyệt đối KHÔNG viết code tạo UI bằng tay (như `view.addSubview`, `NSLayoutConstraint`, v.v.). 
Nhiệm vụ của bạn là đọc mô tả và viết file code Swift chứa `@IBOutlet`, `@IBAction`, logic xử lý.

**LƯU Ý VỀ STORYBOARD:** Dự án của tôi không dùng `Main.storyboard`. Màn hình này nằm trong file `Admin.storyboard`. 
Khi viết code điều hướng (Push/Present/Instantiate), bắt buộc phải dùng cú pháp:
`UIStoryboard(name: "Admin", bundle: nil)` để đảm bảo đúng file storyboard.

---

# Đặc tả Phân hệ Quản lý Thực đơn (Menu Management Module)

**Dự án:** RoastMaster / CoffeeShopUMT
**Nền tảng:** iOS (Swift, UIKit, Storyboard)
**Cơ sở dữ liệu:** Sử dụng Mảng dữ liệu ảo (Mock Data - In-memory array) cho giai đoạn dựng UI.
**Tiêu chuẩn Tiền tệ:** VNĐ (Ví dụ: 55.000 đ)

---

## 🎨 1. Bảng màu chuẩn (Global Color Palette - Dùng để set trong Storyboard)
Toàn bộ phân hệ áp dụng ngôn ngữ thiết kế Dark Mode:
* **Background (Nền ứng dụng):** `#221910` (Nâu tối)
* **Primary/Active (Màu nhấn/Nút bấm chính):** `#BD660F` (Cam)
* **Card/TextField (Màu thẻ/Ô nhập liệu):** `#120E0A` hoặc `#2A221D`
* **Inactive/Disabled (Màu vô hiệu hóa/Phụ):** `#334155` (Xám)
* **Danger (Màu cảnh báo/Xóa):** `#EF4444` (Đỏ)
* **Text (Chữ):** Trắng (`#FFFFFF`) cho tiêu đề, Cam (`#BD660F`) cho giá tiền.

---

## 📱 2. Màn hình 1: Danh sách Thực đơn (Menu List)
**Mô tả:** Màn hình chính của Admin dùng để xem, tìm kiếm, lọc và bật/tắt nhanh trạng thái món ăn.

### 2.1. Cấu trúc kéo thả Storyboard (Tôi sẽ tự làm phần này, bạn lấy thông tin để tạo @IBOutlet)
* **Top Header & Search:** Label tiêu đề "Menu Management". Khung `UISearchBar` nền `#221910`, ô nhập liệu `#120E0A`.
* **Category Filter:** `UICollectionView` cuộn ngang.
* **Menu List:** `UITableView` (Row Height ~100pt).
    * **Menu Item Cell:** Gồm `UIImageView` (Ảnh món), `UILabel` (Tên món trắng), `UILabel` (Giá VNĐ cam), `UISwitch` (Bật/Tắt trạng thái, onTint `#BD660F`), `UIButton` (Icon Edit).
* **FAB (Floating Action Button):** `UIButton` `[+]` hình tròn lơ lửng góc phải.

### 2.2. Luồng Logic Yêu cầu Code (Code Workflow - Mock Data)
Hãy viết file `MenuListViewController.swift` và `MenuTableViewCell.swift` đáp ứng các logic sau:
* **Load Data:** Khởi tạo mảng `allItems` chứa các đối tượng `MenuItem` ảo (Caramel Latte, Matcha...). Gán cho `displayItems` và gọi `tableView.reloadData()`.
* **Filter & Search:** Lọc mảng `displayItems` kết hợp giữa tab Category đang chọn và Text nhập trong `UISearchBar`.
* **Cell Actions (Dùng Closure):** * Gạt Switch $\rightarrow$ Bắn closure ra ngoài ViewController $\rightarrow$ Tìm vị trí món trong `allItems` và cập nhật biến `isAvailable`.
    * Bấm Edit $\rightarrow$ Bắn closure ra ngoài $\rightarrow$ Gọi hàm `showAddEditScreen(with: item)`.

---

## 📱 3. Màn hình 2: Thêm/Sửa Món ăn (Add/Edit Menu Item)
**Mô tả:** Màn hình Modal chứa form nhập liệu chi tiết. Dùng chung layout cho cả Thêm và Sửa.

### 3.1. Cấu trúc kéo thả Storyboard (Tôi sẽ tự làm phần này, bạn lấy thông tin để tạo @IBOutlet)
*(Ghi chú: Toàn bộ UI sẽ được tôi bọc trong `UIScrollView`)*
* **Top Navigation:** Nút `[ X ]` (Đóng) bên trái, Label Tiêu đề ở giữa, Nút `[ Save ]` bên phải.
* **Image Upload:** Khối nền chứa icon Camera và nút "Choose Photo".
* **Form Fields:**
    * `UITextField` (Item Name).
    * `UIStackView` ngang chứa 4 `UIButton` (Coffee, Tea, Pastries, Others).
    * `UITextField` (Price - Keyboard Type: Number Pad).
    * `UITextView` (Description).
* **Bottom Area:** `UISwitch` "Available in POS" và `UIButton` `[ Delete Item ]`.

### 3.2. Luồng Logic Yêu cầu Code (Code Workflow - Mock Data)
Hãy viết file `AddMenuItemViewController.swift` đáp ứng các logic sau:
* **Check Mode (Add vs Edit):** Khởi tạo kiểm tra biến `menuItem`.
    * Nếu `nil` $\rightarrow$ Form trống, ẩn nút Delete, tiêu đề "Add", chọn sẵn tab "Coffee".
    * Nếu có data $\rightarrow$ Đổ dữ liệu vào Text Field, bôi cam nút Category tương ứng, hiện nút Delete, đổi tiêu đề "Edit".
* **Keyboard Handling:** Chạm ra ngoài gọi `view.endEditing(true)`.
* **Save Action:** * Validate rỗng các trường Tên và Giá.
    * Tạo object `MenuItem` mới. Bắn Closure `onSave?(newItem)` về màn hình List để append/update mảng.
    * Đóng form bằng `dismiss(animated: true)`.