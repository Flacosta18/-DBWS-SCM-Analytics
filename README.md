 Dade Bevs, Wines and Spirits (DBWS)

A supply chain analytics database and SQL query library for a regional beverage distributor. Covers inventory management, demand forecasting, replenishment planning, supplier performance, and logistics KPI reporting — designed to support Tableau dashboards and adhoc analysis across SCM functions.

................................................

 Project Overview

Dade Bevs, Wines and Spirits (DBWS) is a fictional regional beverage distribution company modeled after realworld wholesale distributor operations. This project demonstrates endtoend SCM analytics capabilities across the full supply chain lifecycle.

Business Context: A multi  warehouse beverage distributor managing wine, beer, and spirits SKUs across the Southeast US, sourcing from 6 suppliers and serving restaurants, retail, hotels, and bars.



 Database Schema — 10 Tables

Table              Description                                    

`Suppliers`        Vendor master with lead times and payment terms
`Categories`       Beverage category/subcategory hierarchy        
`Products`         SKU master with cost, price, and pack size     
`Warehouses`       Distribution centers with regional assignments 
`Inventory`        Realtime stock position with reorder logic    
`Customers`        Account master with territory and type         
`Sales_Orders`     Order header with status and ship dates        
`Sales_Order_Lines`Linelevel order detail with qty and revenue   
`Purchase_Orders`  Replenishment POs with receipt tracking        
`PO_Lines`         PO line detail with qty ordered vs received    
`Demand_Forecast`  Monthly forecasts vs actuals by SKU/warehouse  
`Logistics`        Delivery performance and ontime tracking      



 SQL Query Library — 14 Analytical Queries

Each query maps directly to a core SCM analytics function:

 Query                              SCM Function             

1 Inventory Status Dashboard         Inventory Management     
2 Reorder Alert Report               Replenishment Planning   
3 Forecast Accuracy — MAPE by SKU    Demand Planning          
4 Supplier Performance Scorecard     Procurement / Vendor Mgmt
5 Revenue & Margin by Category       Financial KPIs           
6 Inventory Turnover Rate            Inventory Optimization   
7 OnTime Delivery Rate by Carrier   Logistics                
8 Forecast vs Actual Monthly Trend   Demand Planning          
9 Order Fill Rate by Customer        Service Level            
10Days of Supply by SKU              Replenishment Planning   
11Warehouse Inventory Value Summary  Working Capital          
12ABC Classification (Pareto)        Inventory Prioritization 
13Open PO Visibility                 Inbound Supply Planning  
14Monthly Sales Trend (TableauReady)KPI Reporting            



 Key SCM Metrics Demonstrated

 ''MAPE''  Mean Absolute Percentage Error for forecast accuracy
 
 ''Inventory Turnover Ratio''  COGS / Average Inventory Value
 
 ''Days of Supply (DOS)'' Onhand ÷ Average Daily Demand
 
 ''Fill Rate'' — Cases Shipped ÷ Cases Ordered
 
 ''OnTime Delivery (OTD)''  % of deliveries meeting promised date
 
 ''Supplier Fill Rate''  Cases Received ÷ Cases Ordered
 
 ''ABC Classification''  Paretobased SKU prioritization
 
 ''Gross Margin %''  (Revenue − COGS) ÷ Revenue



 Technical Highlights

 ''Window functions'' — `SUM() OVER()` for cumulative revenue (ABC query)
 
 ''CTEs'' — Common Table Expressions for multistep calculations
 
 ''CASE logic'' — Dynamic classification (Critical/Reorder/Healthy, A/B/C tiers)
 
 ''NULLIF() safety'' — Divisionbyzero protection throughout
 
 ''Tableauready output'' — Query 14 structured for direct dashboard connection
 
 ''Date functions'' — `DATEDIFF`, `DATE_FORMAT`, `CURDATE()` for timebased KPIs



 How to Run

1. Open MySQL Workbench or any MySQL client
1. Run `sql/dbws_scm_schema.sql`
1. The script will:
 Create the `dbws_scm` database
 Build all 12 tables with constraints and foreign keys
 Insert realistic sample data across all tables
 Execute 14 analytical queries covering key SCM KPIs



 Tools & Technologies

 ''Database:'' MySQL
 ''Analytics:'' SQL — joins, aggregations, window functions, CTEs
 ''Visualization Target:'' Tableau (Query 14 structured as Tableau data source)
 ''SCM Domains:'' Inventory, Demand Planning, Replenishment, Procurement, Logistics



 Portfolio project ''''' Dade Bevs, Wines and Spirits (DBWS) is a fictitious business scenario designed to demonstrate SCM analytics competencies. 
