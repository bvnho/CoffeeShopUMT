# 📋 Menu Management Module - Implementation Guide

## 📌 Tổng Quan (Overview)

Hệ thống quản lý thực đơn hoàn chỉnh với các tính năng:
- ✅ Liệt kê toàn bộ MenuItem theo danh mục
- ✅ Kéo thả (Drag & Drop) để sắp xếp thứ tự
- ✅ Tìm kiếm trực tiếp (Real-time Search)
- ✅ Bật/tắt tính khả dụng (Availability Toggle)
- ✅ Xóa MenuItem (Delete)
- ✅ Thêm MenuItem mới (Add New Item)
- ✅ Lọc theo danh mục (Category Filter)

---

## 🎨 Các Thành Phần (Components)

### 1. **MenuItemTableCell.swift** 
Customized UITableViewCell để hiển thị dari items với:
- **Thumbnail Image**: Hình ảnh món 
- **Item Info**: Tên, giá tiền
- **Availability Switch**: Bật/tắt sẵn có
- **Drag Indicator**: Biểu tượng ⋮⋮ để kéo thả

```swift
// Cách sử dụng
let cell = tableView.dequeueReusableCell(
    withIdentifier: MenuItemTableCell.identifier, 
    for: indexPath
) as! MenuItemTableCell
cell.configure(with: menuItem)
cell.setEditing(isEditingMode)
```

### 2. **MenuListViewController.swift**
Controller chính:

#### 2.1 MenuListViewModel
```swift
// Quản lý business logic
- loadMockData()              // Tải dữ liệu mẫu
- filterItems(by:)            // Lọc theo danh mục
- moveItem(from:to:)          // Kéo thả sắp xếp
- updateItemAvailability()    // Cập nhật tính khả dụng
- deleteItem(at:)             // Xóa item
- searchItems(by:)            // Tìm kiếm
```

#### 2.2 MenuListViewController
```swift
// UI & Interaction
- setupNavigationBar()        // Thanh điều hướng với nút Edit
- setupSearchBar()            // UITextField tìm kiếm
- setupCategoryCollectionView()  // Danh mục ngang
- setupTableView()            // Bảng danh sách với Drag & Drop
```

### 3. **AddMenuItemViewController.swift**
Form thêm MenuItem mới với:
- Item Name (Tên)
- Price (Giá tiền) 
- Category Picker (Lựa chọn danh mục)
- Description (Mô tả)
- Available Toggle (Tính sẵn có)

---

## 🎯 Các Tính Năng Chi Tiết (Features)

### Feature 1: Drag & Drop Reordering
```
Người dùng kéo item từ vị trí này đến vị trí khác để sắp xếp lại thứ tự
└─ Sử dụng UITableViewDragDelegate & UITableViewDropDelegate
└─ ViewModel tự động cập nhật array items
└─ TableView animate lại positions
```

Cách hoạt động:
1. Dài tap trên item → Bắt đầu drag session
2. Kéo qua các items khác → Highlight drop zone
3. Thả → Item swap vị trí

### Feature 2: Category Filtering
```
Kích horizontal scrollView → Chọn category
└─ "All Items" (Hiển thị tất cả)
└─ "Coffee" (Chỉ cà phê)
└─ "Tea" (Chỉ trà)
└─ "Pastries" (Chỉ bánh)
└─ "Snacks" (Chỉ đồ ăn nhẹ)
```

### Feature 3: Real-time Search
```
Gõ trong search bar → Kết quả lọc tức thì
└─ Tìm kiếm không phân biệt chữ hoa/thường
└─ Lọc theo tên item
└─ Vẫn áp dụng category filter
```

### Feature 4: Edit Mode
```
Nhấn "Edit" ở top right → Vào chế độ chỉnh sửa
└─ Hiện drag indicator ⋮⋮
└─ Có thể kéo thả reorder
└─ Có thể swipe để delete
└─ Có thể bật/tắt switch availability
└─ Nhấn "Done" → Thoát chế độ
```

---

## 📊 Mock Data Structure

```swift
menuItems = [
    MenuItem(
        id: "1", 
        name: "Espresso", 
        price: 25, 
        imageURL: nil, 
        category: "Coffee", 
        isAvailable: true
    ),
    // ... 9 more items
]
```

### Categories:
- ☕ Coffee: 4 items (Espresso, Americano, Cappuccino, Latte)
- 🍵 Tea: 3 items (Matcha Latte, Green Tea, Black Tea)
- 🥐 Pastries: 2 items (Croissant, Donut)
- 🥨 Snacks: 1 item (Chips)

---

## 🎨 Color Scheme

| Element | Color | Hex |
|---------|-------|-----|
| Background | Nâu tối | #221910 |
| Card/Input | Nâu đậm | #2A221D |
| Primary Button | Cam | #BD660F |
| Text | Trắng | #FFFFFF |
| Secondary Text | Xám | #334155 |
| Danger/Delete | Đỏ | #EF4444 |

---

## 🔧 Cách Sử Dụng (Usage)

### 1. Hiển thị danh sách
```swift
let vc = MenuListViewController()
navigationController?.pushViewController(vc, animated: true)
```

### 2. Thêm item mới
```swift
let newItem = MenuItem(
    id: UUID().uuidString,
    name: "Cappuccino",
    price: 45,
    imageURL: nil,
    category: "Coffee",
    isAvailable: true
)
viewModel.addItem(newItem)
```

### 3. Cập nhật tính khả dụng
```swift
viewModel.updateItemAvailability(at: indexPath.row, isAvailable: true)
```

### 4. Xóa item
```swift
viewModel.deleteItem(at: indexPath.row)
```

---

## 📱 UI Layout

### MenuListViewController Layout:
```
┌─────────────────────────────────────┐
│  Menu Management              Edit  │  <- Navigation Bar
├─────────────────────────────────────┤
│  🔍 Search menu items...           │  <- Search Bar (UITextField)
├─────────────────────────────────────┤
│  All Items  Coffee  Tea  Pastries  │  <- Category Filter (Horizontal)
├─────────────────────────────────────┤
│  ⋮⋮  [IMG]  Espresso                │
│      2500đ         [Toggle]  (ON)   │
│                                     │  <- Table Cell
│  ⋮⋮  [IMG]  Americano               │
│      3000đ         [Toggle]  (ON)   │
│                                     │
│  ⋮⋮  [IMG]  Cappuccino              │
│      4500đ         [Toggle]  (ON)   │
│                                     │
│       ... more items                │
│                                     │
│                              [+]    │  <- FAB Button (Add New)
└─────────────────────────────────────┘
```

### AddMenuItemViewController Layout:
```
┌─────────────────────────────────────┐
│  Add Menu Item             Cancel   │  <- NavBar
├─────────────────────────────────────┤
│  Item Name *                        │
│  [________________]                 │
│                                     │
│  Price (VNĐ) *                      │
│  [________________]                 │
│                                     │
│  Category *                         │
│  [Coffee       ▼]                   │  <- Picker
│                                     │
│  Description                        │
│  [_____________________________]    │  <- Multi-line TextArea
│  [_____________________________]    │
│                                     │
│  Available                    [ON]  │  <- Toggle
│                                     │
│  [  Add Item  ]                     │  <- Save Button
│                                     │
└─────────────────────────────────────┘
```

---

## 🔄 Data Flow

```
MenuListViewController
├─ MenuListViewModel
│  ├─ menuItems: [MenuItem]        (Dữ liệu gốc)
│  ├─ filteredItems: [MenuItem]    (Dữ liệu sau lọc)
│  ├─ selectedCategory: String
│  └─ onItemsUpdated: Closure      (Callback khi dữ liệu thay đổi)
│
├─ UITableView
│  ├─ DataSource: MenuListViewController
│  ├─ Delegate: MenuListViewController
│  ├─ DragDelegate: MenuListViewController
│  └─ DropDelegate: MenuListViewController
│
└─ UICollectionView (Category)
   ├─ DataSource: MenuListViewController
   ├─ Delegate: MenuListViewController
   └─ Cells: CategoryCell
```

---

## 🚀 Tiếp Theo (Next Steps)

### 1. **Firebase Integration**
```swift
// Cập nhật ViewModel để fetch từ Firebase
private func loadFromFirebase() {
    let db = Firestore.firestore()
    db.collection("menuItems").getDocuments { snapshot in
        self.menuItems = snapshot?.documents
            .compactMap { try? $0.data(as: MenuItem.self) } ?? []
        self.filterItems(by: self.selectedCategory)
    }
}
```

### 2. **Image Upload**
```swift
// Cho phép chọn ảnh trong AddMenuItemViewController
private func selectImage() {
    let picker = UIImagePickerController()
    picker.delegate = self
    present(picker, animated: true)
}
```

### 3. **Persistence**
```swift
// Lưu order changes
private func saveOrderToDatabase() {
    for (index, item) in filteredItems.enumerated() {
        // Update position in database
    }
}
```

### 4. **Analytics**
```swift
// Track user interactions
Analytics.logEvent("menu_item_reordered", parameters: [
    "item_id": item.id,
    "from_position": sourceIndex,
    "to_position": destinationIndex
])
```

---

## 🐛 Troubleshooting

| Lỗi | Giải Pháp |
|-----|-----------|
| Drag & Drop không hoạt động | Kiểm tra `dragInteractionEnabled = true` |
| Search không tìm được | Kiểm tra case-sensitive, có space thừa không |
| Order không lưu | Firebase rules có cho phép write không |
| Cell không reload | Kiểm tra main thread, call `tableView.reloadData()` |

---

## 📝 Notes

- Mock data được tạo trong ViewModel, có thể thay bằng Firebase
- Hiện tại không có image upload, items sử dụng default icon
- Drag & Drop chỉ hoạt động khi có `dragInteractionEnabled = true`
- Search vẫn work khi đang ở Edit mode nhưng drag & drop sẽ disabled

