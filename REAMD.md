
│   └── User.swif
```

## Ý nghĩa từng thư mục

- `Controllers/`: Chứa logic điều khiển màn hình (MVC Controller), xử lý tương tác giữa View và Model.
	- `Admin/`: Màn hình và logic dành cho quản trị viên.
	- `Auth/`: Màn hình đăng nhập/đăng ký/xác thực tài khoản.
	- `Shared/`: Controller dùng chung cho nhiều vai trò người dùng.
	- `Staff/`: Controller dành cho nhân viên.

- `Models/`: Định nghĩa cấu trúc dữ liệu chính của hệ thống.
	- `MenuItem`: Món ăn/thức uống trong menu.
	- `Order`: Đơn hàng.
	- `Table`: Bàn trong quán.
	- `User`: Thông tin người dùng.

- `Services/`: Tầng xử lý nghiệp vụ và giao tiếp dữ liệu.
	- `AuthService`: Xử lý đăng nhập/xác thực người dùng (Firebase Auth).
	- `DatabaseService`: Xử lý đọc/ghi dữ liệu (Firestore/Storage).

- `Views/`: Các custom UI components như `UITableViewCell`, `UICollectionViewCell`.

- `Storyboards/`: Chứa các storyboard tách theo module (`Admin`, `Auth`, `Shared`, `Staff`) để dễ quản lý giao diện.

- `Assets.xcassets/`: Tài nguyên giao diện (ảnh, icon, màu sắc).

- `Extensions/`: Mở rộng class có sẵn (UIKit/Foundation) để tái sử dụng logic.

## Thành phần ngoài thư mục app

- `CoffeeShopUMT.xcodeproj`, `CoffeeShopUMT.xcworkspace`: File cấu hình dự án/workspace của Xcode.
- `Podfile`, `Pods/`: Quản lý và chứa thư viện bên thứ ba (Firebase, Alamofire, SnapKit, ...).

## Gợi ý chuẩn hóa

- Có thể đổi tên `REAMD.md` thành `README.md` để đồng bộ chuẩn GitHub.

