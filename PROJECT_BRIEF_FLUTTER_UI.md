# Project Brief: ShopMint Flutter UI

A comprehensive design and implementation guide for building the Flutter user interface of **ShopMint** ("Never Run Out of Stock"). This document serves as the single source of truth for the frontend architecture, visual design system, screen flows, widget contracts, and interaction models.

---

## 1. Executive Summary & Brand Identity

### 1.1 Product Overview
**ShopMint** is a modern, high-speed retail point-of-sale (POS) and inventory management mobile application designed for Indian Kirana stores, grocery shops, and small retailers. It replaces bloated, slow legacy POS screens with an ultra-clean, tactile, and fast mobile cashier experience.

### 1.2 Core Value Propositions
- **High-Speed Barcode Checkout**: Continuous multi-barcode camera scanning with hardware/software auto-zoom and zero-delay cart addition.
- **Unified Inventory ("Never Run Out of Stock")**: Clean inventory list with low-stock alerts and a 1-tap quick add stock popover modal.
- **Dual Item Support**: Native handling of packaged goods (barcode-driven) and loose staples (weight/measure-driven like kg, g, litre, ml).
- **Fast WhatsApp Receipt Sharing**: Generates clean, formatted text receipts shareable with one tap to customer WhatsApp or via Bluetooth/PDF.
- **Tactile 3D Interaction Language**: Premium mechanical press-down 3D buttons with glass gloss specular sheen, providing physical feedback for fast-paced store counters.

### 1.3 Target Users & Operating Conditions
- **Primary User**: Kirana store owner and counter cashier.
- **Environment**: Fast-moving counter environment, often one-handed phone usage, varied ambient lighting, spotty network connectivity.
- **Languages**: Trilingual support in Release 1 (English, Gujarati, Hindi).

---

## 2. Design System: Teal Mint

The visual language is clean, modern, tactile, and professional. It uses a high-contrast Teal Mint palette.

### 2.1 Color Palette

| Token Name | Hex Code | Purpose & Usage |
| :--- | :--- | :--- |
| **Primary (Teal Mint)** | `#14B8A6` | Primary action highlights, brand elements |
| **Primary Dark** | `#0F766E` | Headings, active navigation states, button bases |
| **Bright Teal Highlight** | `#17C3B2` | Top surface highlight for 3D buttons |
| **Deep Teal Bevel** | `#084B45` | Bottom 3D shadow extrusion for mechanical buttons |
| **Mint Accent** | `#99F6E4` | Badges, secondary highlights, indicator tints |
| **Primary Surface** | `#CCFBF1` | Active filter pill backgrounds, light container fills |
| **Background** | `#F0FDFA` | Main screen background |
| **Surface** | `#FFFFFF` | Cards, modals, dialogs, bottom navigation dock |
| **Text Primary** | `#0F2A29` | Headings and primary body copy |
| **Text Secondary** | `#527270` | Subtitles, stock counts, metadata |
| **Text Disabled** | `#9DB5B3` | Placeholders, inactive icons, disabled states |
| **Border** | `#CDE9E5` | Input borders, card outlines |
| **Divider** | `#DDF0ED` | Subtle list row separators |
| **Success** | `#16A34A` | Completed payments, successful stock updates |
| **Error / Alert** | `#DC2626` | Low-stock warnings, balance due, delete actions |

### 2.2 Strict Visual Rules & Constraints
- **Zero Purple Gradients**: No purple gradients anywhere in the app.
- **No Pill-Shaped Buttons**: Standard rounded rectangles only (`BorderRadius.circular(10)` to `BorderRadius.circular(12)`). Stadium/capsule buttons are strictly prohibited.
- **No Emoji Icons**: All iconography must use official Material vector icons (`Icons.*`).
- **No Em Dashes**: Hyphens, colons, or parentheses must be used instead of em dashes in all copy, labels, and code comments.
- **No Over-The-Top Animations**: Keep transitions crisp, snappy, and functional (50ms to 150ms).
- **No Artificial AI Slop**: Clean typography, real product photography thumbnails, and transparent layouts without clutter.

### 2.3 Typography Scale

| Token | Size | Weight | Line Height | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Display** | 22sp | SemiBold (w600) | 1.25 | Splash screen, major greetings |
| **H1** | 18sp | Bold (w700) | 1.30 | Screen headers, modal titles |
| **H2** | 16sp | Bold (w700) | 1.35 | Section titles, customer names |
| **Body** | 14sp | Regular (w400) | 1.40 | Form labels, standard text |
| **Body Medium** | 14sp | Medium (w500) | 1.40 | List titles, table cells |
| **Amount** | 15sp | Bold (w700) | 1.20 | Prices, bill amounts |
| **Amount Large** | 18sp | Bold (w700) | 1.20 | Grand total, sales overview |
| **Caption** | 12sp | Regular (w400) | 1.35 | Helper text, units, timestamps |

---

## 3. Tactile 3D Button Specification (`App3dButton`)

To enhance tactile usability for store cashiers, all primary call-to-action buttons use a custom mechanical 3D push-down widget (`App3dButton`).

### 3.1 Anatomical Structure
1. **Outer Base Container**:
   - Background: Deep Teal (`#084B45` or `#0F766E`).
   - Corner Radius: Standard rounded rectangle (`12px`).
   - Drop Shadow: Subtle soft shadow (`Offset(0, 3)`, blur radius 4px, black with 11% opacity).
2. **Elevated Surface Plate**:
   - Surface Gradient: Linear top-to-bottom from `#17C3B2` down to `#0F766E`.
   - Resting Depth: `4.5px` of the bottom base is exposed to create a realistic 3D bevel.
3. **Curved Specular Gloss Sheen**:
   - Custom-painted translucent white gradient overlay (`Colors.white.withAlpha(95)` to `withAlpha(18)`).
   - Geometry: Starts at top-left, curves gently down through the middle (at 68% height), and finishes at the right edge (42% height).
4. **Mechanical Press-Down Animation**:
   - When pressed down (`TapDown`): The surface plate translates downward by `3.5px`, exposing only `1px` of the bottom base and simulating a physical keyboard switch.
   - Haptic feedback: Triggers `HapticFeedback.lightImpact()` on tap down.
   - On release (`TapUp`): Returns to resting position and fires `onPressed`.
5. **Content**:
   - White bold typography (`FontWeight.w800`, letter spacing 0.6).
   - Optional leading or trailing icons (e.g. `ADD +` or `[|||||] Stock barcode items`).

---

## 4. Navigation Architecture: 3-Tab Shell

The application is structured into a clean bottom navigation bar with three primary tabs, eliminating hidden menus and complex nested navigation.

```
                    +------------------------------------+
                    |       ShopMint Main Navigation     |
                    +------------------------------------+
                                      |
         +----------------------------+----------------------------+
         |                            |                            |
         v                            v                            v
   [ Tab 1: My Shop ]        [ Tab 2: Make Bill ]         [ Tab 3: My Sales ]
   - Inventory list           - Cashier terminal          - Sales analytics
   - Search & barcode         - Barcode auto-scanner      - Cash/UPI/Credit
   - Filter pills             - Loose items weighing      - Best seller list
   - 1-tap stock popover      - WhatsApp share receipt    - Profit reports
```

### 4.1 Shell Widget Contract (`MainNavigationShell`)
- **Bottom Navigation Items**:
  1. `My Shop` (Icon: `Icons.storefront_outlined` / Selected: `Icons.storefront`)
  2. `Make Bill` (Icon: `Icons.receipt_long_outlined` / Selected: `Icons.receipt_long`)
  3. `My Sales` (Icon: `Icons.bar_chart_outlined` / Selected: `Icons.bar_chart`)
- **Container Styling**: White background, `1px` top border (`#CDE9E5`), elevation 0, active indicator in soft mint (`#CCFBF1`).

---

## 5. Screen Specifications

### 5.1 Tab 1: My Shop Screen (`DashboardTab`)

The central inventory and store overview screen. Clean, uncluttered, and data-focused without unnecessary charts or cards.

#### Visual Hierarchy (Top to Bottom):
1. **Header Row (Inside SafeArea)**:
   - *Left*: Circular avatar with shopkeeper icon (44x44, soft mint background `#CCFBF1`), Title "My Shop" (16sp bold), Subtitle displaying store name (e.g. "Ramesh Kirana Store").
   - *Right*: Stylized brand typography `ShopMint` (`Shop` in `#0F766E`, `Mint` in `#14B8A6`, 18sp bold) + Settings gear button (`Icons.settings_outlined`).
2. **Filter Pills Row**:
   - Two side-by-side rounded rectangle tabs (`BorderRadius.circular(10)`):
     - `Shop items: X` (Active state: `#CCFBF1` background, `#0F766E` bold text).
     - `Pending 0` / `Low stock: X` (Inactive state: `#FFFFFF` background, `#527270` text, subtle border).
   - Tapping switches between all inventory items and items at or below low-stock threshold.
3. **Search & Quick Action Row**:
   - *Search Input (Expanded)*: Height 44px, rounded rectangle (12px), magnifying glass prefix icon, clear button suffix, hint: "Search barcode item". Filters list dynamically on keystroke.
   - *Barcode Scanner Button*: 44x44 square button, rounded rectangle (12px), barcode scanner icon. Launches camera barcode scanner; if barcode exists, immediately opens quick add stock modal.
   - *Loose Items Button*: 44x44 square button, rounded rectangle (12px), shopping bag icon. Opens loose item modal.
4. **Primary Action Button**:
   - Full-width `App3dButton.mint`: `[|||||] Stock barcode items`.
   - Launches continuous scanner. Looks up scanned items in the shop inventory or offline master catalog, then presents the stocking interface.
5. **Product Inventory List (`ListView.separated`)**:
   - Each item row contains:
     - Leading thumbnail: 46x46 rounded rectangle (8px) with subtle border, rendering the real product photo.
     - Title: Product name (14sp semi-bold, max 1 line with ellipsis).
     - Subtitle: Stock quantity (e.g. "55 pieces"). **Critical**: If stock is low (`isLowStock == true`), the text is styled in warning red (`#DC2626`, bold, e.g. "3 pieces").
     - Trailing: Selling price in Rupees (e.g. "₹299", 15sp bold) and grey chevron `>`.
   - **Interaction**: Tapping any row opens the floating `QuickAddStockModal` for that specific product.

---

### 5.2 Modal: Quick Add Stock Popover (`QuickAddStockModal`)

An interactive popover modal that allows the store owner to add stock and update purchase prices in seconds.

#### Modal Specifications:
- **Presentation**: Bottom sheet with top rounded corners (`16px`), auto-adjusting to keyboard insets.
- **Header**: Top drag handle (36x4px), followed by product summary row:
  - Product thumbnail (48x48 rounded rectangle).
  - Barcode number (11sp grey text, e.g. `8901234567890`).
  - Product title (15sp bold).
- **Form Row 1: Total Amount Paid (₹)**:
  - Left label: `Total Amount Paid (₹)`.
  - Right input: Numeric text field (width 90px, centered text, auto-calculates unit purchase cost).
- **Form Row 2: Total Pieces Bought**:
  - Left label: `Total Pieces Bought` (or dynamic unit like `Total Kg Bought`).
  - Right input: Numeric text field (width 90px, centered text, defaults to 10).
- **Action Button**:
  - Full-width `App3dButton.mint`: `ADD +` (Height 48px).
  - Updates product stock in database, updates unit cost in paise, refreshes dashboard provider, and shows a confirmation toast.

---

### 5.3 Tab 2: Make Bill Terminal (`NewBillScreen`)

The primary checkout screen optimized for speed. Enables creating a complete grocery bill within 15 seconds.

#### Screen Components:
1. **App Bar**:
   - Title: "Make Bill".
   - Actions: Camera scanner shortcut icon, custom item calculator icon, clear cart button.
2. **Search Autocomplete & Fast Scan Box**:
   - Search bar filtering store products by name or barcode.
   - Selecting a product instantly adds 1 unit to the cart.
3. **Fast Moving Staples & Loose Items Bar**:
   - Horizontal scrolling chip list for instant 1-tap cart additions:
     - `+ Loose Item` (Opens `LooseItemModal` for weighing items).
     - `+ Custom Item` (Opens dialog for ad-hoc unlisted goods).
     - Frequent store items (Milk, Sugar, Bread, Eggs, Atta, Tea).
4. **Active Cart List**:
   - Each row displays product thumbnail, item name, unit rate, quantity stepper (`-`, qty, `+`), and line total.
   - Removing quantity to 0 removes the item from the bill.
5. **Customer & Khata Assignment Row**:
   - Dropdown defaulting to "Walk-in Customer (Cash/UPI)".
   - Option to select existing customer from credit ledger or tap `+` to add a customer.
6. **Payment Mode Selector**:
   - Three selectable tabs: `Cash`, `UPI`, `Credit (Udhaar)`.
   - Selecting `Credit` enforces selecting or creating a customer record.
7. **Bottom Checkout Dock**:
   - Left: Total amount in Rupees (large bold font).
   - Right: Full-width `App3dButton.mint` with `COMPLETE & SHARE BILL (₹XXX)`.
   - Automatically deducts stock, records payment, updates ledger if credit, and navigates to `ReceiptScreen`.

---

### 5.4 Modal: Loose Items Calculator (`LooseItemModal`)

Allows rapid calculation and billing for items sold by weight, volume, or count without barcodes.

#### Features & Presets:
- **Unit Selector**: Switch between `kg`, `g`, `litre`, `ml`, `packet`, `box`.
- **Quick Preset Weight Chips**:
  - `100g`, `250g`, `500g`, `1kg`, `2kg`, `5kg`
  - `500ml`, `1L`
- **Dynamic Price Calculation**: Real-time total calculation based on rate per unit and selected weight.
- **Action Button**: `App3dButton.mint` labeled `Add to Bill (₹XXX)`.

---

### 5.5 Tab 3: My Sales Screen (`SalesTab`)

Provides instant sales performance visibility for the store owner.

#### Sections:
1. **Sales Overview Card**: Total revenue billed today, total bills count, and gross profit estimate.
2. **Payment Mode Breakdown**: Three distinct metric pills:
   - Cash Received (₹)
   - UPI Received (₹)
   - Credit Given / Udhaar (₹)
3. **Interactive Sales Analytics Chart (`SalesAnalyticsChart`)**:
   - Weekly and monthly visual trend bar chart showing sales patterns.
4. **Best Sellers List**:
   - Top fast-moving items ranked by revenue and quantity sold.

---

### 5.6 Receipt & Bill Sharing Screen (`ReceiptScreen`)

The post-checkout confirmation screen designed for friction-free digital sharing.

#### Key Elements:
- Clean white paper receipt card with dashed dividers.
- Store details, bill number, timestamp, itemized list, subtotal, discount, grand total, and payment status.
- **Fast Bill Sharing Actions**:
  - `App3dButton.mint` labeled `Share Receipt` (Direct native WhatsApp / phone share sheet).
  - Outlined button `Copy` (Copies clean ASCII text receipt to clipboard).
- `Next Bill` button: Clears the cart and returns to the cashier terminal for the next customer.

---

## 6. Offline Master Catalog Architecture

To eliminate manual data entry for standard packaged goods:
- **SQLite Database (`assets/db/master_products.db`)**: Pre-loaded catalog containing over 10,000 common Indian FMCG barcodes, product names, categories, standard units, and packaging images.
- **Lookup Priority Pipeline**:
  1. Check Shop Inventory (MongoDB local cache via `ProductProvider`).
  2. If not found, check Offline SQLite Master Catalog (`MasterCatalogService`).
  3. If found in Master Catalog, auto-populate name, unit, and image, asking the cashier only for their selling price and purchase price.
  4. If not found in Master Catalog, prompt manual addition via `AddProductDialog`.

---

## 7. State Management Architecture

The Flutter application strictly follows the `Provider` pattern with separation of concerns:

| Provider | Responsibility |
| :--- | :--- |
| `AuthProvider` | User authentication, store owner profile, 4-digit PIN session token |
| `ProductProvider` | Shop inventory, barcode lookups, stock increment, low-stock filtering |
| `BillingProvider` | Active cart, quantity calculations, discounts, payment mode, bill creation |
| `CustomerProvider` | Khata customer list, balances, credit ledger history |
| `DashboardProvider` | Store summary metrics, daily revenue, active bill counters |
| `LocaleProvider` | Trilingual runtime language switching (English, Gujarati, Hindi) |

---

## 8. Directory & File Structure

```
app/lib/
├── core/
│   ├── constants/        # API endpoints, storage keys
│   ├── localization/     # Language dictionaries (en, gu, hi), LocaleProvider
│   ├── network/          # Dio client, interceptors, auth token injection
│   ├── storage/          # SQLite master catalog service, SecureStorage
│   ├── theme/            # AppColors, AppTokens, AppTheme
│   └── utils/            # CurrencyFormatter, ReceiptShareHelper, ImagePicker
├── models/               # ProductModel, BillModel, CustomerModel, UserModel
├── providers/            # AuthProvider, BillingProvider, ProductProvider, etc.
├── screens/
│   ├── admin/            # Platform administration screens
│   ├── auth/             # PinLoginScreen, QuickRegisterScreen
│   ├── billing/          # NewBillScreen, BarcodeScannerModal, ReceiptScreen
│   │   └── widgets/      # LooseItemModal
│   ├── dashboard/        # DashboardTab (My Shop)
│   │   └── widgets/      # SalesAnalyticsChart
│   ├── main_navigation_shell.dart  # 3-Tab Bottom Navigation
│   ├── products/         # AddProductDialog, ProductsTab
│   │   └── widgets/      # QuickAddStockModal
│   ├── sales/            # SalesTab (My Sales)
│   └── settings/         # SettingsScreen, language switcher
└── widgets/              # App3dButton, ProductImageView
```

---

## 9. Quality & Verification Standards

Before any build or pull request is approved:
1. **Static Analysis**: `flutter analyze` must return 0 issues.
2. **Automated Tests**: All unit and widget tests in `test/` must pass (`flutter test`).
3. **Em Dash Compliance**: Strictly zero em dashes anywhere in Dart code or UI strings. Use standard hyphens instead.
4. **Style Compliance**: All primary action buttons must use `App3dButton.mint` with tactile press interaction.
5. **Responsiveness**: All screens must support compact Android devices (360dp width) up to modern high-density screens without pixel overflow.
