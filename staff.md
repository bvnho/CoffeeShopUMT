Act as an Expert iOS Interface Builder & Storyboard Architect. I need you to generate the raw XML source code for an iOS Storyboard (`.storyboard` file) that contains two View Controllers for a "Staff Management" flow. 

CRITICAL RULES:
1. ONLY output valid, well-formed Apple Interface Builder XML. 
2. Ensure every `<scene>`, `<viewController>`, `<view>`, `<tableView>`, and UI element has a unique 3-part alphanumeric ID (e.g., "a1b-2c-3d4").
3. Ensure all tags are properly opened and closed. Missing a tag will corrupt the file.
4. Include valid `<constraints>` for Auto Layout so the UI doesn't collapse.

Please generate the XML for these two scenes:

### Scene 1: StaffListViewController
- **storyboardIdentifier**: "StaffListVC"
- **UI Elements**:
  - A `UISearchBar` at the top.
  - A `UITableView` filling the rest of the screen.
  - Inside the table view, ONE `<tableViewCell>` (identifier: "StaffCell", rowHeight: 150).
    - Inside the cell's `contentView`: An `UIImageView` (Avatar), and three `UILabel`s (Name, Role, Email).
    - A horizontal `<stackView>` containing 3 `<button>`s (Reset, Edit Role, Disable).
  - A floating Action `<button>` (the "+" add button) pinned to the bottom-trailing corner.

### Scene 2: CreateStaffViewController
- **storyboardIdentifier**: "CreateStaffVC"
- **UI Elements**:
  - A Header section with an `UIImageView` and a `UILabel` ("STAFF IDENTITY").
  - A vertical `<stackView>` centered in the screen containing:
    - 4 pairs of `<label>` and `<textField>` (Full Name, Username, Default Password). 
    - 1 `<button>` acting as a dropdown for "Role Assignment".
  - A vertical `<stackView>` at the bottom containing 2 `<button>`s ("Grant Account" and "Cancel").

Output the complete XML code block starting with `<?xml version="1.0" encoding="UTF-8"?>` and `<document ...>`. Make sure the scenes are wrapped inside the `<scenes>` tag.