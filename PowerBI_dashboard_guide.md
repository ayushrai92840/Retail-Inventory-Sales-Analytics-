# Power BI Build Guide

## 1. Load data
Use **Get Data > Text/CSV** to load `products.csv`, `sales.csv`, `inventory.csv`, and `stores.csv`. Set:
- IDs: Whole Number
- Dates: Date
- Currency amounts: Fixed Decimal Number (INR)
- `discount_pct`: Decimal Number

## 2. Data model
Use a star-schema style model with Products and Stores as dimensions, Sales and Inventory as facts. Add a Date dimension:
```DAX
Date = CALENDAR(DATE(2025,1,1), DATE(2025,12,31))
Year = YEAR('Date'[Date])
Month No = MONTH('Date'[Date])
Month = FORMAT('Date'[Date], "MMM")
Year Month = FORMAT('Date'[Date], "YYYY-MM")
```
Sort `Date[Month]` by `Date[Month No]`. Mark Date as the date table. Relationships should be one-to-many, single direction from dimensions to facts.

## 3. Dashboard pages

### Page 1 — Executive Sales Overview
- KPI cards: Total Revenue, Gross Profit, Gross Margin %, Units Sold, Total Orders, Average Order Value.
- Line chart: Revenue by Year Month.
- Bar chart: Revenue by Category.
- Bar chart: Top 10 Products by Revenue.
- Slicers: Date, Region, Store, Category.

### Page 2 — Inventory Health
- KPI cards: Inventory Units, Inventory Cost Value, Low Stock Product-Store Count.
- Table: Store, Product, Stock Quantity, Reorder Level, Units Below Reorder.
- Bar chart: Inventory Cost Value by Category.
- Matrix: Category by Store with stock units.
- Conditional formatting: red when stock <= reorder level.

### Page 3 — Product Performance
- Top 10 and bottom 10 products by units/revenue.
- Scatter chart: Units Sold vs Gross Profit; product as details, category as legend.
- Matrix: Product, Category, Units Sold, Revenue, Gross Profit, Gross Margin %.
- Slicers: Category and Store.

### Page 4 — Store & Replenishment
- Revenue and AOV by store.
- Low-stock replenishment table.
- Inventory value by store.
- Suggested reorder quantity can be calculated in Power Query or SQL using the trailing 3-month average demand.

## 4. Design guidance
Use a consistent 16:9 canvas. Keep 4–6 KPI cards at the top, align charts to a grid, use clear titles and units (₹), and add a reset-filters button. Use drill-through from category to product and tooltip pages for product-level detail.

## 5. Important analytical definitions
- Gross Profit = Sales Amount − Cost Amount.
- Gross Margin % = Gross Profit / Revenue.
- Inventory Cost Value = On-hand Units × Unit Cost.
- Low stock = on-hand units at or below the reorder level.
- Months of Cover = current stock / average monthly units sold over the selected recent period.
- Inventory Turnover = COGS / Average Inventory Cost Value. A true turnover ratio requires beginning and ending inventory snapshots; this generated dataset has only a 31-Dec snapshot, so do not claim a precise annual turnover ratio from it. Add a second snapshot or use monthly inventory history for a valid turnover calculation.
