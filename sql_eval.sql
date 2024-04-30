-- Step 1: Create output with required fields

WITH Orders AS (
    SELECT 
        TO_DATE(CONCAT('1-', 'Jan', ' ', EXTRACT(YEAR FROM CURRENT_DATE)), 'DD-MON YYYY') AS Order_Month,
        Product_Name,
        p.Product_Category,
        SUM(Order_Quantity) AS Sum_Order_Qty,
        SUM(Sales) AS Sum_Sales
    FROM 
        Salesstore s
    INNER JOIN 
        Product p ON s.Product_Name = p.Product_Name
    GROUP BY 
        TO_DATE(CONCAT('1-', 'Jan', ' ', EXTRACT(YEAR FROM CURRENT_DATE)), 'DD-MON YYYY'),
        Product_Name,
        p.Product_Category
),

-- Step 2: Calculate cumulative order quantity and sales from Jan 1 2024 till date

Cumulative AS (
    SELECT 
        Order_Month,
        Product_Name,
        Product_Category,
        Sum_Order_Qty,
        Sum_Sales,
        SUM(Sum_Order_Qty) OVER (ORDER BY Order_Month) AS Cumulative_Order_Qty,
        SUM(Sum_Sales) OVER (ORDER BY Order_Month) AS Cumulative_Sales
    FROM 
        Orders
    WHERE 
        Order_Month >= TO_DATE('01-JAN-2024', 'DD-MON-YYYY')
),

-- Step 3: Calculate cumulative order quantity and sales for corresponding Customer_Segment for the same month

Cumulative_Segment AS (
    SELECT 
        s.Order_Month,
        s.Product_Name,
        s.Product_Category,
        s.Sum_Order_Qty,
        s.Sum_Sales,
        c.Customer_Segment,
        SUM(s.Sum_Order_Qty) OVER (PARTITION BY s.Order_Month, c.Customer_Segment) AS Cumulative_Order_Qty_Segment,
        SUM(s.Sum_Sales) OVER (PARTITION BY s.Order_Month, c.Customer_Segment) AS Cumulative_Sales_Segment
    FROM 
        Orders s
    INNER JOIN 
        Salesstore ss ON s.Order_Month = ss.Order_Month AND s.Product_Name = ss.Product_Name
    INNER JOIN 
        Product p ON ss.Product_Name = p.Product_Name
    INNER JOIN 
        Customer c ON ss.Customer_Name = c.Customer_Name
)

-- Step 4: calculate market share percentage based on order quantity for the same customer segment of the order for the same month

SELECT 
    Order_Month,
    Product_Name,
    Product_Category,
    Sum_Order_Qty,
    Sum_Sales,
    Cumulative_Order_Qty,
    Cumulative_Sales,
    Customer_Segment,
    Cumulative_Order_Qty_Segment,
    Cumulative_Sales_Segment,
    (Cumulative_Order_Qty_Segment * 100.0) / SUM(Cumulative_Order_Qty_Segment) OVER (PARTITION BY Order_Month, Customer_Segment) AS Marketshare_Percentage
FROM 
    Cumulative_Segment;
