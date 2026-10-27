# Shop Management App: Complete Specification

Billing, stock, Udhaar (Khata) and sales management for small shops. Based on the Vaniq reference app, with the Teal Mint design system. This is the single source of truth for design, development and testing. Every default is already decided here, so no further questions need to go to the shopkeeper.

## 1. Summary

**Product.** A mobile app for kirana stores, grocery stores and small retailers to create bills, manage product stock, track customer credit (Udhaar) and view sales and profit.

**Users.** Owner (full access) and Staff (billing and limited viewing).

**Platform.** Flutter mobile app (Android first, iOS later), Node.js + Express REST API, MongoDB.

**Languages.** Gujarati, Hindi, English in release 1. Marathi and others later.

**Currency.** Indian Rupee (₹), two decimal places, Indian digit grouping (12,34,567.50).

### 1.1 In scope for release 1

- Mobile number and OTP login, shop setup
- Dashboard with summary cards and quick actions
- Products, categories, stock add and adjust, low stock alerts
- Billing with cash, UPI, other and credit payment, receipt sharing, bill history, cancel and return
- Customer Khata with ledger, payment received, WhatsApp reminder share
- Sales, profit and best seller reports
- Owner and Staff roles
- Language selection, settings, 30 day free trial and subscription

### 1.2 Out of scope for release 1

AI assistant, demand forecasting, multi-store, automated WhatsApp messages, GST invoicing and returns filing, supplier purchase orders, advanced accounting, printer integration, offline billing sync.

The reference doc suggests picking 2 or 3 small extras later: expense entry, supplier records, expiry alerts. These are listed in section 15 and are not part of release 1.

## 2. Decisions Already Made

These answer the questions a shopkeeper would normally be asked.

| Topic | Decision |
| --- | --- |
| Login | Mobile number plus 6 digit OTP, OTP valid 5 minutes, resend after 30 seconds, max 5 attempts per hour |
| Session | Stay logged in for 30 days, refresh token rotation |
| Shop type options | Kirana, Grocery, General store, Medical, Stationery, Clothing, Other |
| Units | pcs, kg, g, litre, ml, packet, box, dozen, bottle, meter |
| Quantity type | Decimals allowed for kg, g, litre, ml, meter. Whole numbers only for the rest |
| Bill number | Auto, format `B-YYYYMMDD-0001`, resets numbering each day, per shop |
| Payment types | Cash, UPI, Other, Credit (Udhaar) |
| Part payment on a bill | Allowed. Paid amount can be less than total, the rest goes to the customer ledger. Customer required in that case |
| Walk-in customer | Bill without customer is allowed for fully paid bills only |
| Discount | Per item, either ₹ amount or percent, plus one optional bill level ₹ discount |
| Tax | Not in release 1. Receipt is titled "Bill", not "Tax Invoice" |
| Rounding | Grand total rounded to nearest ₹1, round off amount shown on the bill |
| Selling below purchase price | Allowed with a warning |
| Selling more than stock | Blocked by default, owner can enable "allow negative stock" in settings |
| Editing a saved bill | Not allowed. Cancel and create a new bill |
| Cancel bill | Owner only. Staff cannot cancel |
| Return | Owner only. Full or partial item return against an original bill |
| Deleting products | Never deleted, only deactivated, so history stays correct |
| Deleting customers | Only if balance is zero and no bills exist, otherwise deactivate |
| Date and time | Device time shown, server time stored in UTC, displayed in IST |
| Financial year | Not used. Reports use calendar dates |
| Data backup | Cloud database, no manual backup needed |
| Receipt sharing | Share as image or PDF through the phone share sheet (WhatsApp, SMS, others) |
| Free trial | 30 days from first shop creation, no card required |
| Plans | Monthly and annual. Price is a single config value set by the owner of the product, not hardcoded |
| After trial expires | Read only mode. Existing data viewable, new bills and edits blocked until a plan is bought |
| Staff limit | Up to 3 staff per shop in release 1 |
| Shops per owner | 1 in release 1 |

## 3. Design System: Teal Mint

Fresh, modern, friendly and professional.

### 3.1 Colors

| Name | Hex | Use |
| --- | --- | --- |
| Teal Mint (primary) | `#14B8A6` | Primary buttons, selected states, brand accents |
| Dark Teal | `#0F766E` | Headings, active states, secondary buttons, links |
| Mint | `#99F6E4` | Highlights, selected tab indicator, chips, subtle accents |
| Background | `#F0FDFA` | Main screen backgrounds |
| White | `#FFFFFF` | Cards, forms, inputs, bottom bar |
| Success | `#16A34A` | Payments received, success messages |
| Error | `#DC2626` | Pending Udhaar, errors, low stock alerts |

Added neutrals (not in the original palette, needed for readable UI):

| Name | Hex | Use |
| --- | --- | --- |
| Text primary | `#0F2A29` | Body text |
| Text secondary | `#527270` | Captions, helper text |
| Text disabled | `#9DB5B3` | Disabled text, hints |
| Border | `#CDE9E5` | Card and input borders |
| Divider | `#DDF0ED` | List dividers |
| Success soft | `#DCFCE7` | Received status background |
| Error soft | `#FEE2E2` | Pending status background |
| On primary | `#042F2E` | Text on teal buttons (white on `#14B8A6` is too low contrast) |

### 3.2 Typography

| Style | Size | Weight | Color |
| --- | --- | --- | --- |
| H1 | 28 | 700 | Dark Teal |
| H2 | 22 | 700 | Dark Teal |
| H3 | 18 | 600 | Dark Teal |
| Body large | 16 | 400 | Text primary |
| Body | 14 | 400 | Text primary |
| Caption | 12 | 400 | Text secondary |
| Button | 16 | 600 | On primary |
| Amount | 16 | 600, tabular figures | Text primary, green if received, red if pending |
| Amount large | 26 | 700, tabular figures | Dark Teal |

Fonts: system font with Noto Sans Gujarati and Noto Sans Devanagari as fallbacks. Gujarati and Hindi text needs about 10 percent more line height, so test every screen in all three languages.

### 3.3 Layout and components

- Spacing on a 4 point grid: 4, 8, 12, 16, 24, 32. Screen side padding 16.
- Corner radius: 6 small, 10 buttons and inputs, 14 cards. Rounded rectangles only, no pill shapes.
- Cards: white, 1 px border `#CDE9E5`, no shadow.
- Primary button: teal fill, dark text, 52 high, full width. Secondary: dark teal outline.
- Inputs: white fill, 1 px border, 2 px teal border on focus, red on error with message below.
- Bottom navigation: 3 tabs (My Shop, My Khata, My Sales), mint indicator, dark teal when selected.
- Floating action button on lists: teal, used for the main add action.
- Status chips: Received (green on soft green), Pending (red on soft red), Low stock (red on soft red).
- Icons: Material outline icons only. No emoji in the UI.
- No decorative gradients, no fake numbers, no stock photos. Empty states use a simple line icon and one sentence.

## 4. User Journey

1. Splash screen (1 second, logo, checks login and trial status)
2. Language selection (first launch only)
3. Login with mobile number
4. OTP verification
5. New user: Shop profile, then Initial products (can skip)
6. Existing user: straight to Dashboard
7. Daily use: New Bill, Add Stock, Khata, Reports

## 5. Navigation and Screen Inventory

| Module | Screens |
| --- | --- |
| Authentication | Splash, Language, Login, OTP |
| Setup | Shop Profile, Initial Products |
| Dashboard | Home, Notifications |
| Billing | New Bill, Product Search, Cart, Payment, Receipt, Bill History, Bill Detail, Return |
| Products | Product List, Add/Edit Product, Categories, Barcode Scan |
| Inventory | Stock List, Add Stock, Stock Adjustment, Stock History, Low Stock |
| Khata | Customer List, Add/Edit Customer, Customer Ledger, Receive Payment, Add Manual Entry |
| Sales | Overview, Sales History, Profit Report, Best Sellers |
| Staff | Staff List, Invite Staff, Staff Detail |
| Settings | Shop Settings, Invoice Preferences, Language, Subscription, Help, Privacy Policy, Terms, Logout |

Bottom tabs: **My Shop** (dashboard, products, stock, billing), **My Khata** (customers and Udhaar), **My Sales** (reports). Notifications bell and settings gear sit in the top bar of My Shop.

## 6. Screen Specifications

### 6.1 Login

- Field: mobile number, 10 digits, starts with 6 to 9, country code +91 fixed
- Button: Send OTP (disabled until valid)
- Footer: links to Privacy Policy and Terms
- Errors: "Enter a valid 10 digit mobile number", "Could not send OTP, try again"

### 6.2 OTP

- 6 digit input, auto read SMS where the platform allows
- Resend timer 30 seconds, then "Resend OTP"
- Wrong OTP: "Incorrect OTP". After 5 wrong attempts: "Too many attempts, try again after 1 hour"
- Success: new number goes to Shop Profile, known number goes to Dashboard

### 6.3 Shop Profile

| Field | Required | Rules |
| --- | --- | --- |
| Shop name | Yes | 2 to 60 characters |
| Owner name | Yes | 2 to 60 characters |
| Mobile number | Yes | Prefilled from login, read only |
| Shop type | Yes | Dropdown, see section 2 |
| Address | No | Up to 200 characters |
| Preferred language | Yes | Gujarati, Hindi, English, prefilled from earlier choice |
| Shop logo | No | Image, max 2 MB, shown on receipt |

Button: Save and continue. Starts the 30 day trial.

### 6.4 Initial Products

Shows the Add Product form (6.9) with a "Skip for now" link and "Add another" button. Maximum guidance text: "You can add products later from My Shop".

### 6.5 Dashboard (My Shop home)

Top bar: shop name, notifications bell with unread dot, settings gear.

Summary cards (2 by 2 grid):

| Card | Value | Tap action |
| --- | --- | --- |
| Today Sales | Sum of today's non-cancelled bill totals | Opens Sales Overview (today) |
| Today Profit | Today's gross profit | Opens Profit Report (today) |
| Pending Udhaar | Total outstanding across customers, red | Opens My Khata |
| Low Stock | Count of items at or below minimum | Opens Low Stock list |

Quick actions (three large buttons): **New Bill**, **Add Stock**, **Add Customer**.

Below: recent 5 bills with number, time, customer, amount, payment status. Link "View all" goes to Bill History.

Empty state (no bills today): cards show ₹0, recent list shows "No bills yet today".

Trial banner: when 7 days or fewer remain, show "Free trial ends in N days" with a Subscribe button.

### 6.6 New Bill

Layout: search bar with barcode icon at top, cart list in the middle, sticky total bar at bottom with **Continue** button.

1. Add item by: typing product name or barcode in search, tapping barcode icon to scan, or picking from the product list or a category chip row.
2. Each cart row shows name, quantity stepper, rate, line total, remove icon.
3. Tap the row to edit quantity (keypad), rate and discount.
4. A calculator mode allows adding a custom item with a name (optional) and amount only, for items not in the catalog. Custom items do not touch stock.
5. Bottom bar shows item count and grand total.
6. Continue goes to Payment.

Rules: quantity must be greater than 0. Rate cannot be negative. Discount cannot exceed line total. Out of stock items show a red "0 left" chip and are blocked unless negative stock is allowed.

### 6.7 Payment and Receipt

Payment screen fields:

| Field | Rule |
| --- | --- |
| Customer | Optional search or add new. Required if paid amount is less than total |
| Bill discount | Optional ₹ amount |
| Payment type | Cash, UPI, Other, Credit |
| Amount received | Defaults to grand total. For Credit, defaults to 0 |
| Balance to Udhaar | Auto calculated, shown in red when above 0 |
| Note | Optional, up to 100 characters |

Button: **Save Bill**. On save, the server in one transaction: creates the bill, reduces stock for each catalog item, records the payment, and adds any balance to the customer ledger.

Receipt screen: shop name and logo, address and mobile, bill number, date and time, customer name if any, item table (name, quantity, rate, amount), discount, round off, grand total, payment type, amount received, balance due, staff name, footer "Thank you, visit again". Actions: Share, Print later (not in release 1), New Bill, Done.

### 6.8 Bill History and Bill Detail

- List grouped by date, newest first, with filter by date range, payment type, customer, staff, status (Active, Cancelled)
- Search by bill number or customer name
- Detail shows full receipt, payment history, and status. Owner sees **Cancel Bill** and **Return Items**
- Cancel needs a reason (free text, 3 to 100 characters) and confirmation. Cancelling restores stock and reverses payment and ledger entries
- Return: pick items and quantities up to what was sold. Stock goes back, bill value reduces, if bill had balance due the ledger reduces first, any extra becomes a refund recorded as cash or credit to customer

### 6.9 Products

Product List: search, category filter chips, sort (name, stock low to high, recently added). Each row: name, selling price, current stock with unit, low stock chip if at or below minimum. FAB adds product. Swipe or menu: Edit, Deactivate.

Add/Edit Product form:

| Field | Required | Rules |
| --- | --- | --- |
| Name | Yes | 2 to 80 characters, unique within shop (case insensitive) |
| Category | No | Pick or create inline |
| Unit | Yes | See section 2 |
| Purchase price | Yes | 0 or more |
| Selling price | Yes | 0 or more, warning if below purchase price |
| Opening stock | No | Default 0 |
| Minimum stock level | No | Default 0, low stock when stock is at or below this |
| Barcode | No | Scan or type, unique within shop |
| Photo | No | Camera or gallery, max 2 MB |
| Active | Yes | Default on |

Categories: list, add, rename, deactivate. A category with products cannot be deleted.

### 6.10 Stock Operations

- **Add Stock**: pick product, quantity, optional new purchase price, optional supplier note, date (default today). Updates stock and, if a new purchase price is entered, the product purchase price for future sales only
- **Adjust Stock**: pick product, direction (decrease or increase), quantity, reason (Damaged, Expired, Lost, Count correction, Other), note
- **Stock History**: per product list of movements with type (Opening, Purchase, Sale, Return, Cancel, Adjustment), quantity change, balance after, date, user
- **Low Stock**: all products at or below minimum, sorted by shortage, with a quick Add Stock button

### 6.11 My Khata (Udhaar)

Customer List: search, filter (All, Has balance), sort (highest balance, name, recent). Each row: name, mobile, balance in red if owed. Top card: total outstanding and number of customers with balance. FAB adds customer.

Add/Edit Customer: name (required, 2 to 60), mobile (optional but needed for WhatsApp, 10 digits, unique within shop), address (optional), opening balance (optional, treated as a previous balance entry).

Customer Ledger: header with name, mobile, current balance. Actions: **Receive Payment**, **Add Credit** (manual), **Send Reminder**. Below, a timeline of entries, newest first: date, description (Bill number, Payment received, Manual credit, Opening balance, Return), amount (red for credit given, green for payment), running balance.

Receive Payment: amount (required, greater than 0, may exceed balance only if confirmed as advance), mode (Cash, UPI, Other), date, note. Entry is added, balance updated.

Send Reminder: opens the phone share sheet with a prefilled message in the shop's language, for example: "Hello \[name\], your pending balance at \[shop name\] is ₹\[amount\]. Please pay when convenient. Thank you." The shopkeeper taps send. No automatic sending.

Ledger entries are never edited or deleted. Mistakes are fixed with a reversing entry.

Example: previous balance ₹500, new credit bill +₹800, payment received -₹600, remaining balance ₹700.

### 6.12 My Sales (Reports)

Date filter: Today, This Week, This Month, Custom range. Default Today.

**Sales Overview**: total billed sales, number of bills, payments received (cash, UPI, other), credit given, line chart of sales by day or hour, list of bills in range.

**Profit Report**: revenue, cost of goods sold (purchase price stored on each bill line at the time of sale), gross profit, expenses (zero in release 1, see section 15), net profit equals gross profit for now. Profit percent shown.

**Best Sellers**: top 20 products ranked by quantity sold, each with quantity, revenue and profit, for the selected range.

Owner sees all reports. Staff does not see My Sales.

### 6.13 Staff

- Staff List: name, mobile, status (Active, Disabled)
- Invite Staff: name and mobile. Staff logs in with their own mobile and OTP and lands in the owner's shop
- Staff Detail: bills created count, last active, toggle to disable access
- A disabled staff member is logged out at the next request and sees "Your access has been disabled by the shop owner"

Permission matrix:

| Feature | Owner | Staff |
| --- | --- | --- |
| Create bill | Yes | Yes |
| View own bills | Yes | Yes |
| View all bills | Yes | No |
| Cancel bill, return | Yes | No |
| View products and stock | Yes | Yes (view only) |
| Add or edit products, stock | Yes | No |
| Khata: view balances | Yes | Yes |
| Khata: receive payment | Yes | Yes |
| Add or edit customers | Yes | Add only |
| Reports | Yes | No |
| Dashboard cards | All four | Today Sales (own), Low Stock |
| Staff management, settings, subscription | Yes | No |

### 6.14 Settings

- **Shop Settings**: edit shop profile fields from 6.3
- **Invoice Preferences**: show logo, footer message (up to 100 characters), show staff name, receipt paper style (standard only in release 1)
- **Payment Preferences**: UPI ID (optional, shown on receipt), allow negative stock toggle
- **Language**: Gujarati, Hindi, English, applies instantly
- **Subscription**: trial status and expiry date, current plan, Monthly and Annual options, Restore purchase
- **Help**: FAQ list, WhatsApp support link, support email
- **Privacy Policy** and **Terms and Conditions**: in app web view of hosted pages
- **Logout**: confirmation dialog

### 6.15 Notifications

In app list only in release 1, with these types: low stock, trial ending (7, 3, 1 days), subscription expired, staff access changes. Push notifications use the same events. Mark read on open, "Mark all read" action.

### 6.16 Subscription

- Trial: 30 days, shown as days left
- Plans: Monthly and Annual with the price read from server config. The annual plan shows the saving as a calculated figure, not a made up number
- Payment through Google Play Billing on Android. Server verifies the purchase token and sets plan and expiry
- Reminders at 7, 3 and 1 days before expiry
- Expired: read only mode with a banner and Subscribe button
- Restore Purchase re-checks Play Billing for the signed in account

## 7. Business Rules

### 7.1 Billing

- Line amount = quantity × rate − line discount
- Subtotal = sum of line amounts
- Grand total = subtotal − bill discount, then rounded to the nearest ₹1, round off stored
- Balance due = grand total − amount received
- Save bill, stock deduction, payment record and ledger update happen in one database transaction. If any step fails, nothing is saved
- Each bill line stores product name, unit, rate, purchase price at sale time and quantity, so later product edits never change old bills
- Double tap on Save Bill is prevented by a client idempotency key

### 7.2 Stock

- Remaining stock = opening stock + stock added − units sold + units returned or cancelled ± adjustments
- Every change creates a stock movement row, stock is never edited directly
- Low stock when remaining stock is at or below minimum level and minimum is above 0

### 7.3 Khata

- Customer balance = sum of credit entries − sum of payments, always derived from the ledger
- Positive balance means the customer owes the shop
- Payments are applied to the total balance, not to individual bills

### 7.4 Profit

- Gross profit = revenue − purchase cost of items sold (using cost stored on each bill line)
- Cancelled bills are excluded, returns reduce revenue and cost
- Custom calculator items have no cost and count fully as profit unless a cost is entered

### 7.5 Roles and security

- All business rules run on the server, the app only displays results
- Every API call is authenticated and filtered by shop id from the token, never from request input
- Staff actions record the staff id on every bill and ledger entry

## 8. Data Model (MongoDB)

| Collection | Key fields |
| --- | --- |
| users | \_id, mobile (unique), name, role (owner or staff), shopId, status, language, createdAt, lastLoginAt |
| shops | \_id, ownerId, name, ownerName, mobile, type, address, logoUrl, language, settings (invoiceFooter, showLogo, showStaff, upiId, allowNegativeStock), createdAt |
| staff | \_id, shopId, userId, name, mobile, status, createdAt, disabledAt |
| categories | \_id, shopId, name, active |
| products | \_id, shopId, name, categoryId, unit, purchasePrice, sellingPrice, currentStock, minStock, barcode, imageUrl, active, createdAt, updatedAt |
| stock\_movements | \_id, shopId, productId, type, quantityChange, balanceAfter, refType, refId, reason, note, createdBy, createdAt |
| customers | \_id, shopId, name, mobile, address, balance, active, createdAt |
| bills | \_id, shopId, billNo, customerId, items\[ {productId, name, unit, qty, rate, purchasePrice, discount, amount} \], subtotal, billDiscount, roundOff, grandTotal, paymentType, amountReceived, balanceDue, note, status, cancelReason, createdBy, createdAt, idempotencyKey |
| returns | \_id, shopId, billId, items\[\], refundAmount, refundMode, createdBy, createdAt |
| payments | \_id, shopId, customerId, billId (optional), amount, mode, note, createdBy, createdAt |
| ledger\_entries | \_id, shopId, customerId, type (credit, payment, opening, return, reversal), amount, refType, refId, balanceAfter, createdBy, createdAt |
| subscriptions | \_id, shopId, plan, status, trialStartedAt, trialEndsAt, currentPeriodEnd, purchaseToken, updatedAt |
| notifications | \_id, shopId, userId, type, title, body, read, createdAt |

Indexes: shopId on every collection, unique (shopId, barcode), unique (shopId, billNo), unique (shopId, mobile) on customers, createdAt for reports.

## 9. API Endpoints

All under `/api/v1`, JSON, bearer token auth except login.

| Area | Endpoints |
| --- | --- |
| Auth | POST /auth/send-otp, POST /auth/verify-otp, POST /auth/refresh, POST /auth/logout |
| Shop | GET /shop, POST /shop, PUT /shop, POST /shop/logo |
| Categories | GET, POST, PUT /categories |
| Products | GET /products (search, category, lowStock, page), POST, PUT /products/:id, PATCH /products/:id/active, GET /products/barcode/:code |
| Stock | POST /stock/add, POST /stock/adjust, GET /stock/movements, GET /stock/low |
| Bills | POST /bills, GET /bills, GET /bills/:id, POST /bills/:id/cancel, POST /bills/:id/return |
| Customers | GET, POST, PUT /customers, GET /customers/:id/ledger |
| Payments | POST /customers/:id/payments, POST /customers/:id/credit |
| Reports | GET /reports/summary, /reports/sales, /reports/profit, /reports/best-sellers (all take from and to) |
| Dashboard | GET /dashboard |
| Staff | GET, POST /staff, PATCH /staff/:id/status |
| Subscription | GET /subscription, POST /subscription/verify |
| Notifications | GET /notifications, POST /notifications/read |

Pagination: `page` and `limit` (default 20, max 100). Errors return `{ code, message }` with proper HTTP status. Money is stored as integers in paise to avoid rounding errors.

## 10. Error and Empty State Messages

| Situation | Message |
| --- | --- |
| No internet | "No internet connection. Please try again." |
| Server error | "Something went wrong. Please try again." |
| Session expired | "Please log in again." |
| Product not found for barcode | "No product found for this barcode." with Add Product button |
| Out of stock | "Only N left in stock." |
| Duplicate product name | "A product with this name already exists." |
| Duplicate customer mobile | "A customer with this mobile already exists." |
| Trial expired | "Your free trial has ended. Subscribe to continue billing." |
| No products | "No products yet. Add your first product." |
| No customers | "No customers yet. Add a customer to track Udhaar." |
| No bills | "No bills in this period." |
| No low stock | "All products are well stocked." |

## 11. Non-Functional Requirements

- **Performance.** App cold start under 3 seconds on a mid range Android phone. Product search results within 300 ms for 5,000 products. Bill save within 2 seconds on 4G
- **Network.** Release 1 needs internet. Show clear messages when offline. Product list cached for read only viewing
- **Security.** HTTPS only, OTP rate limits, hashed refresh tokens, per shop data isolation, input validation on server, no sensitive data in logs
- **Privacy.** Collect only what is listed in this document. Hosted Privacy Policy and Terms pages are required before store release
- **Accessibility.** Tap targets at least 48 dp, contrast at least 4.5:1 for text, support system font scaling up to 130 percent
- **Localization.** All strings in ARB files, no hardcoded text, number and date formatting by locale
- **Devices.** Android 8 and above, phones only, portrait only
- **Analytics and crash reporting.** Crash reports only, no advertising or tracking SDKs

## 12. Technology

- **App.** Flutter with GetX or Provider for state, Dio for HTTP, secure storage for tokens, mobile\_scanner for barcodes, share\_plus for sharing, in\_app\_purchase for subscriptions, Firebase Cloud Messaging for push
- **API.** Node.js and Express, JWT access and refresh tokens, Joi or Zod validation, Mongoose, MongoDB transactions for billing and payments
- **OTP.** An SMS gateway provider that supports Indian DLT rules. Template registration is needed before launch
- **Theme.** `app_colors.dart`, `app_tokens.dart` and `app_theme.dart` already created for this design system

## 13. Acceptance Criteria

1. A new user can sign up, create a shop, add a product and save a first bill in under 3 minutes
2. Saving a bill reduces stock, and cancelling it restores the same stock
3. A credit bill increases the customer balance, and the example in 6.11 ends at ₹700
4. Dashboard numbers match the sum of bills, payments and stock records for the day
5. Profit uses the purchase price stored at the time of sale, even after the product price changes
6. A disabled staff member cannot call any API after the next request
7. Staff cannot see reports, cancel bills or edit products
8. Every screen renders correctly in Gujarati, Hindi and English with no clipped text
9. After trial expiry the app is read only and Subscribe works end to end
10. Cancelling the same bill twice or tapping Save Bill twice never creates duplicate entries

## 14. Timeline

One experienced developer, 6 to 10 weeks.

| Week | Work |
| --- | --- |
| 1 | Theme, navigation shell, auth and OTP, shop setup |
| 2 | Products, categories, barcode |
| 3 | Stock operations, low stock, dashboard |
| 4 to 5 | Billing, payment, receipt sharing, bill history, cancel and return |
| 6 | Khata, ledger, reminders |
| 7 | Reports, staff and roles |
| 8 | Settings, languages, subscription, notifications |
| 9 to 10 | Testing, fixes, store listing, release |

## 15. Later Ideas (not in release 1)

Choose at most 2 or 3 after launch: expense entry (feeds net profit), supplier records and purchase history, expiry date alerts, Bluetooth receipt printer, GST bills, offline billing, more languages.

## 16. Release Checklist

- Privacy Policy and Terms pages hosted and linked in app and store listing
- SMS OTP templates approved
- Play Store listing: icon, screenshots in Gujarati, Hindi and English, short and full description
- Subscription products created in Play Console and tested with a license tester
- Server in production with backups and monitoring
- Crash reporting enabled
- Acceptance criteria in section 13 all passed

## 17. Only Open Item

The monthly and annual subscription prices are the one value this document cannot decide. Everything else is set. Prices are read from server config, so they can be changed any time without an app update.
