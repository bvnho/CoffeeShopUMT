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
│   └── Staff.storyboard        # Chứa TabBar và các luồng của Staff
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