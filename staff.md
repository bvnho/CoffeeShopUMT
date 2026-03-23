# TASK: GENERATE SWIFT CODE FOR EXISTING FILES
Act as a Senior iOS Developer. I am building a CoffeeShopUMT app using Swift, UIKit (Storyboards), and Firebase.

### 🛑 CRITICAL INSTRUCTIONS FOR AI:
1. **DO NOT CREATE A WORKSPACE OR DIRECTORIES.** All files and folders already exist in my project.
2. **ONLY OUTPUT RAW SWIFT CODE** for the 5 specific files listed below.
3. **NO PROGRAMMATIC UI:** The UI is 100% finished in Storyboards. You must ONLY use `@IBOutlet` and `@IBAction`. Absolutely NO `addSubview`, NO `translatesAutoresizingMaskIntoConstraints`, and NO UI configuration code.
4. **ROLE DEFAULT:** When creating a new staff account, hardcode the role to "Staff". Do not ask for user input for the role.

Below are the exact implementation requirements for each existing file:

---

### File 1: `Models/User.swift`
Create a `Codable` struct named `User` with the following properties:
- `id`: String
- `fullName`: String
- `email`: String
- `role`: String
- `isActive`: Bool

---

### File 2: `Services/DatabaseService.swift`
Create a `DatabaseService` class (Singleton is fine) using `FirebaseFirestore` to handle data operations. Add these functions:
- `fetchStaffAndAdmins`: Fetch all users from the "Users" collection where `role` is "Admin" or "Staff". (Return an array of `User` objects via completion or async/await).
- `toggleUserStatus`: Update the `isActive` boolean for a specific user ID.
- `updateUserRole`: Update the `role` string for a specific user ID.
- `createNewUserDocument`: Save a newly created user to the "Users" collection using their Auth UID as the document ID.

*(Assume `AuthService` already exists to handle Auth operations like `sendPasswordReset`).*

---

### File 3: `Views/Cells/StaffCell.swift`
Create a custom `UITableViewCell` subclass named `StaffCell`.
- **Outlets:** `@IBOutlet` for `avatarImageView`, `nameLabel`, `roleLabel`, `emailLabel`.
- **Actions:** `@IBAction` for `resetTapped`, `editRoleTapped`, `disableTapped`.
- **Logic:** Define a protocol `StaffCellDelegate` with methods for the 3 button taps, passing the current `User` object. Add a `delegate` property and a `configure(with user: User)` method. Do not put Firebase logic inside this cell.

---

### File 4: `Controllers/Admin/StaffManagement/StaffListViewController.swift`
- **Outlets:** `@IBOutlet` for `searchBar` (`UISearchBar`) and `tableView` (`UITableView`).
- **Setup:** Configure delegates and data source. 
- **Data Logic:** Call `DatabaseService` in `viewDidLoad` to fetch data. Populate an array of `User` objects and reload the table.
- **Search Logic:** Filter the local array by `fullName` or `email` when the search bar text changes.
- **Delegate Implementation (`StaffCellDelegate`):**
  - `resetTapped`: Call `Auth.auth().sendPasswordReset(withEmail:)` (or via AuthService). Show a success alert.
  - `editRoleTapped`: Show a `UIAlertController` (ActionSheet) to pick "Admin" or "Staff". On selection, call `DatabaseService` to update the role and refresh the list.
  - `disableTapped`: Show a confirmation alert, then call `DatabaseService` to toggle `isActive` and refresh the list.

---

### File 5: `Controllers/Admin/StaffManagement/CreateStaffViewController.swift`
- **Outlets:** `@IBOutlet` for `fullNameTextField`, `emailTextField`, `passwordTextField`. (No role button/picker).
- **Actions:** `@IBAction` for `grantAccountTapped`, `cancelTapped`.
- **Logic for `grantAccountTapped`:**
  1. Validate that no text fields are empty.
  2. Call `Auth.auth().createUser(withEmail:password:)`. *(Add a comment noting that Firebase automatically signs in the new user, which might require a workaround later).*
  3. Get the `uid` from the result.
  4. Call `DatabaseService.createNewUserDocument` passing the `uid`, `fullName`, `email`, hardcoded `role: "Staff"`, and hardcoded `isActive: true`.
  5. On success, call `self.navigationController?.popViewController(animated: true)`.
- **Logic for `cancelTapped`:**
  - Call `self.navigationController?.popViewController(animated: true)`.

Please generate the complete Swift code for each of these 5 files.