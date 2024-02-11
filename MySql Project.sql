
#CUSTOMER ANALYSIS

#Finding the customers who have the highest average order value

SELECT cutomer_and_orderValue.customerNumber,
		 cutomer_and_orderValue.average_order_value,
		 c.customerName
FROM(
	SELECT customerNumber, 
       	ROUND(AVG(orderValue),3) AS average_order_value
	FROM (
    	SELECT o.customerNumber,
           	 o.orderNumber,
           	 SUM(od.quantityOrdered * od.priceEach) AS orderValue
    	FROM orders o
      JOIN orderdetails od 
		ON o.orderNumber = od.orderNumber
    	GROUP BY o.customerNumber, o.orderNumber
			) AS customer_orders
	GROUP BY customerNumber
		)AS cutomer_and_orderValue 
LEFT JOIN customers c
USING (customerNumber)
ORDER BY average_order_value DESC;

#Checking customer's demographic

SELECT country,
		 COUNT(country) AS total_customers
FROM customers
GROUP BY country
ORDER BY total_customers DESC;

#Finding the customerNumber of the customer who has the highest frequency of placing orders to the company in 2004

SELECT customerNumber, 
		 COUNT(customerNumber) AS frequency
FROM orders
WHERE orderDate BETWEEN '2004-01-01' AND '2004-12-31'
GROUP BY customerNumber
ORDER BY frequency DESC;


#Finding the names of customers who are most often to make payments during the weekend 

SELECT customerNumber,
	(SELECT customerName
	 FROM customers
	 WHERE payments.customerNumber = customers.customerNumber) AS frequent_name, 
	 COUNT(customerNumber) AS frequency
FROM payments
WHERE DAYOFWEEK(paymentDate) IN (1,7)
GROUP BY customerNumber
ORDER BY frequency DESC;


#EMPLOYEE ANALYSIS

#Finding the sales representative that brings the most revenue to the company

CREATE TABLE payment_salesReEmployee AS 
(SELECT customerNumber, 
		  ROUND(SUM(amount),2) AS total_amount,
		(SELECT salesRepEmployeeNumber
		 FROM customers
 		 WHERE customers.customerNumber = payments.customerNumber
		) AS sales_representative
FROM payments
GROUP BY customerNumber);

SELECT sales_representative, 
		 ROUND(SUM(total_amount),2) AS revenue
FROM payment_salesReEmployee
GROUP BY sales_representative
ORDER BY revenue DESC;


#PRODUCT ANALYSIS

#Finding products that have been ordered the most

SELECT productCode, 
		 COUNT(productCode) AS order_count
FROM orderdetails
GROUP BY productCode
ORDER BY order_count DESC;

# Checking the average days it take for each product to be shipped
SELECT productCode,
    	 DATEDIFF(shippedDate, orderDate) AS avg_shipping_day
FROM orders 
INNER JOIN orderdetails 
USING (orderNumber)
GROUP BY productCode
ORDER BY avg_shipping_day DESC; 

#Calculating the average selling price of each product

SELECT 
    productCode,
    ROUND(AVG(priceEach),3) AS Avg_selling_price
FROM orders 
INNER JOIN orderdetails
USING (orderNumber)
GROUP BY productCode
ORDER BY Avg_selling_price DESC;

#Determining which product line is the most profitable

SELECT pl.productLine,
    	 ROUND(SUM(od.quantityOrdered * od.priceEach),3) AS total_revenue,
    	 ROUND(SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)),3) AS total_profit
FROM productlines pl
JOIN products AS p
USING (productLine)
JOIN orderdetails AS od
USING (productCode)
GROUP BY pl.productLine
ORDER BY total_profit DESC;

#ORDER ANALYSIS

#Caculating the total value of each order and finding the order that generate the highest revenue

SELECT orderNumber, 
    	 customerNumber, 
       GROUP_CONCAT(productCode) AS Products_odered, 
       ROUND(SUM(quantityOrdered*priceEach),3) AS total_revenue
FROM (
		SELECT * 
     	FROM orders AS o
      INNER JOIN orderdetails AS od 
		USING (orderNumber)
		) AS orders_info
GROUP BY orderNumber
ORDER BY total_revenue;

#Calculating the orders that have not been paid (customer's debt)

SELECT support_table.customerNumber, 
    	 support_table.customerName, 
    	 total_billing, 
    	 total_paid, 
    	 ROUND((total_billing-total_paid),3) AS debt
FROM (
	  SELECT 
        o.customerNumber, 
        customerName, 
        ROUND(SUM(quantityOrdered*priceEach),3) AS total_billing
     FROM orderdetails AS od
     INNER JOIN orders AS o 
	  USING (orderNumber)
     INNER JOIN customers AS c 
	  USING (customerNumber)
     GROUP BY o.customerNumber
	  ) AS support_table 
INNER JOIN (
		SELECT 
        payments.customerNumber, 
        ROUND(SUM(amount),3) AS total_paid
    	FROM payments
    	GROUP BY payments.customerNumber) AS support 
USING (customerNumber)    
ORDER BY debt DESC;
