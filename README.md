# Retail Inventory & Sales Analytics

**Level:** Intermediate  
**Stack:** MySQL 8.0, Python (Pandas/NumPy/Matplotlib/Seaborn), Power BI, Excel  
**Currency:** INR (₹)  
**Data period:** 1 Jan 2025 – 31 Dec 2025

## Business problem
A multi-store retailer needs better visibility into revenue, product demand, stock shortages, excess stock, and store performance. This project uses synthetic but realistic transaction data to demonstrate an end-to-end analytics workflow.

## Dataset inventory
| File | Grain | Approx. rows |
|---|---|---:|
| products.csv | One row per product | 50 |
| stores.csv | One row per store | 6 |
| sales.csv | One row per product line in an order | 25,370 |
| inventory.csv | One product-store snapshot | 300 |

Sales data includes order date, product, store, units, unit price, discount, net sales amount and cost amount. Inventory is a 31-Dec-2025 snapshot.

## Folder structure
- `dataset/` — source CSV files
- `sql/retail_analytics.sql` — MySQL schema and business queries
- `python/retail_inventory_sales_analysis.ipynb` — data quality, EDA, KPIs and exports
- `powerbi/` — dashboard guide and DAX measures
- `excel/` — workbook with source data and a data dictionary
- `documentation/` — project report and business interpretation

## How to run
1. Extract the project ZIP.
2. Open MySQL Workbench and run `sql/retail_analytics.sql` to create the database and tables.
3. Import CSVs into matching tables using the MySQL Table Data Import Wizard. Import stores and products first, then sales and inventory.
4. Open the notebook in Jupyter. Install dependencies: `pip install pandas numpy matplotlib seaborn jupyter`.
5. Update `DATA_DIR` in the notebook if needed, then run all cells.
6. Load the four CSVs into Power BI and follow `powerbi/PowerBI_dashboard_guide.md`.
7. Use the Excel workbook for quick inspection and validation.

## Important modeling notes
- Sales is a line-item fact table. `order_id` repeats when an order contains multiple products; use `COUNT(DISTINCT order_id)` for order counts.
- Inventory is a point-in-time snapshot at 31-Dec-2025.
- The generated dataset is synthetic and should be labelled as such in a portfolio.
- A precise inventory turnover ratio requires average inventory value over a period (ideally monthly snapshots). Do not calculate annual turnover using only the ending snapshot.

## Suggested portfolio outcomes
- Revenue, gross profit and gross margin by month/category/store.
- Top and slow-moving products.
- Low-stock and overstock product-store combinations.
- Inventory cost value and suggested reorder quantities.
- Recommendations supported by actual query outputs, not invented percentages.

## Resume bullet template
**Retail Inventory & Sales Analytics | MySQL, Python, Power BI, Excel**
- Analyzed 25,370 synthetic retail sales line items across 6 stores and 50 products to identify demand patterns and inventory risks.
- Built MySQL queries using joins, CTEs, aggregations and window-ready summaries to report revenue, profitability, product performance and replenishment needs.
- Used Python (Pandas, NumPy, Matplotlib and Seaborn) for data validation, exploratory analysis and inventory risk segmentation.
- Designed a Power BI dashboard specification covering executive sales KPIs, inventory health, product performance and store replenishment.
- Translated analysis into recommendations for reorder planning, excess stock reduction and product availability.

Replace the scale and achievement claims with the final numbers and validated insights from your own run.
