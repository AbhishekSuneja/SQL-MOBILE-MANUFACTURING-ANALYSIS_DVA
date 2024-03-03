SELECT * FROM DIM_MANUFACTURER

SELECT * FROM DIM_MODEL

SELECT * FROM DIM_CUSTOMER

SELECT * FROM DIM_LOCATION

SELECT * FROM DIM_DATE


/*Q1--    List all the states in which we have customers who have bought 
          cellphones from 2005 till today.*/


		  SELECT DISTINCT A.STATE FROM DIM_LOCATION A 
		  INNER JOIN FACT_TRANSACTIONS B
		  ON A.IDLOCATION = B.IDLOCATION
		  WHERE YEAR(B.DATE)>=2005

		  ---or--- with  group by

		  SELECT A.STATE FROM DIM_LOCATION A 
		  INNER JOIN FACT_TRANSACTIONS B
		  ON A.IDLOCATION = B.IDLOCATION
		  WHERE YEAR(B.DATE)>=2005
		  GROUP BY A.STATE


/*Q2 --   What state in the US is buying the most 'Samsung' 
          cell phones?*/


		  SELECT TOP 1 WITH TIES A.STATE, SUM(B.QUANTITY) AS QTY 
		  FROM DIM_LOCATION A
		       INNER JOIN FACT_TRANSACTIONS B
		     ON A.IDLOCATION = B.IDLOCATION
		       INNER JOIN DIM_MODEL C
		     ON B.IDModel=C.IDModel
		       INNER JOIN DIM_MANUFACTURER D
		     ON D.IDManufacturer = C.IDManufacturer
		  WHERE D.Manufacturer_Name ='SAMSUNG'
		  GROUP BY A.STATE
	      ORDER BY 2 DESC


/*Q3--    Show the number of transactions for each model per zip code 
          per state.*/

		  SELECT A.STATE, A.ZIPCODE, 
		    COUNT(A.IDLOCATION) AS TOTAL_TRANSACTIONS
		  FROM DIM_LOCATION A
		  INNER JOIN FACT_TRANSACTIONS B ON A.IDLOCATION = B.IDLOCATION
	      INNER JOIN DIM_MODEL C ON B.IDMODEL = C.IDMODEL
		  GROUP BY A.STATE, A.ZIPCODE
		  ORDER BY 1 ASC
		  

/*Q4--    Show the cheapest cellphone with its price.*/

          SELECT TOP 1 B.Model_Name, C.MANUFACTURER_NAME, A.TotalPrice 
		  FROM FACT_TRANSACTIONS A
		  INNER JOIN DIM_MODEL B ON A.IDModel = B.IDModel
	      INNER JOIN DIM_MANUFACTURER C ON B.IDManufacturer = C.IDManufacturer
		  ORDER BY 3 ASC


/*Q5--    Find out the average price for each model in the top5 manufacturers in
          terms of sales quantity and order by average price.*/

		  
		  SELECT TOP 5 C.MANUFACTURER_NAME, A.MODEL_NAME, SUM(B.QUANTITY) AS QTY_SUM, 
		               ROUND(AVG(TotalPrice),2) AVG_ORDER_VALUE
		  FROM DIM_MODEL A 
		  INNER JOIN FACT_TRANSACTIONS B 
		  ON A.IDModel = B.IDModel
		  INNER JOIN DIM_MANUFACTURER C 
		  ON C.IDManufacturer = A.IDManufacturer
		  GROUP BY C.MANUFACTURER_NAME,A.MODEL_NAME
		  ORDER BY AVG(A.Unit_price) DESC


/*Q6--    List the names of the customers and the average amount spent in 2009,
          where the average is higher than 500.*/


		  SELECT A.CUSTOMER_NAME, AVG(B.TOTALPRICE)AS AVG_AMOUNT
		  FROM DIM_CUSTOMER A 
		  INNER JOIN FACT_TRANSACTIONS B
		  ON A.IDCustomer = B.IDCustomer
		  WHERE YEAR(DATE) LIKE '%2009%'
		  GROUP BY A.CUSTOMER_NAME
		  HAVING AVG(B.TOTALPRICE)>500


/*Q7--    List if there is any model that was in the top 5 in terms of quantity,
          simultaneously in 2008, 2009 and 2010.*/

          SELECT * FROM
		  ( SELECT TOP 5 T2.Model_Name 
		    FROM FACT_TRANSACTIONS as T1 INNER JOIN
              DIM_MODEL AS T2 ON T1.IDModel=T2.IDModel
            WHERE YEAR(T1.Date) = '2008'
            GROUP BY T2.Model_Name
            ORDER BY SUM(T1.Quantity) DESC

			INTERSECT

			SELECT TOP 5 T2.Model_Name 
			FROM FACT_TRANSACTIONS as T1 INNER JOIN
               DIM_MODEL AS T2 ON T1.IDModel=T2.IDModel
            WHERE YEAR(T1.Date) = '2009'
            GROUP BY T2.Model_Name
            ORDER BY SUM(T1.Quantity) DESC

			INTERSECT

			SELECT TOP 5 T2.Model_Name
			FROM FACT_TRANSACTIONS as T1 INNER JOIN
              DIM_MODEL AS T2 ON T1.IDModel=T2.IDModel
            WHERE YEAR(T1.Date) = '2010'
            GROUP BY T2.Model_Name
            ORDER BY SUM(T1.Quantity) DESC ) AS CTE


/*Q8--    Show the manufacturer with the 2nd top sales in the year of 2009 and the
          manufacturer with the 2nd top sales in the year of 2010.*/


		SELECT X.MANUFACTURER_NAME, YEAR_ FROM 
		    ( SELECT C.MANUFACTURER_NAME, YEAR(B.DATE) AS YEAR_,
			  DENSE_RANK() OVER (ORDER BY SUM(B.TOTALPRICE) DESC) AS RNK,
			  SUM(TOTALPRICE) AS SALES
			  FROM DIM_MODEL A 
		      INNER JOIN FACT_TRANSACTIONS B ON A.IDModel = B.IDModel
		      INNER JOIN DIM_MANUFACTURER C ON C.IDManufacturer = A.IDManufacturer
			  WHERE YEAR(B.DATE)='2009' 
			  GROUP BY C.MANUFACTURER_NAME,YEAR(B.DATE) )X
			  WHERE RNK = 2
			  UNION ALL
		SELECT Y.MANUFACTURER_NAME, YEAR_  FROM
		    ( SELECT C.MANUFACTURER_NAME, YEAR(B.DATE) AS YEAR_,
			  DENSE_RANK() OVER (ORDER BY SUM(B.TOTALPRICE) DESC) AS RNK,
			  SUM(TOTALPRICE) AS SALES
			  FROM DIM_MODEL A 
		      INNER JOIN FACT_TRANSACTIONS B ON A.IDModel = B.IDModel
		      INNER JOIN DIM_MANUFACTURER C ON C.IDManufacturer = A.IDManufacturer
			  WHERE YEAR(B.DATE)='2010' 
			  GROUP BY C.MANUFACTURER_NAME, YEAR(B.DATE) )Y
			  WHERE RNK=2
			  
/*Q9--   Show the manufacturers that sold cellphones in 2010 but did not in 2009.*/
       
	     SELECT A.MANUFACTURER_NAME FROM DIM_MANUFACTURER A
		 INNER JOIN DIM_MODEL B ON A.IDManufacturer = B.IDManufacturer
		 INNER JOIN FACT_TRANSACTIONS C ON C.IDModel = B.IDModel
		 WHERE YEAR(C.DATE) IN ('2010')
		
		 EXCEPT
		
	     SELECT A.MANUFACTURER_NAME FROM DIM_MANUFACTURER A
		 INNER JOIN DIM_MODEL B ON A.IDManufacturer = B.IDManufacturer
		 INNER JOIN FACT_TRANSACTIONS C ON C.IDModel = B.IDModel
		 WHERE YEAR(C.DATE) IN ('2009')
		

/*Q10--  Find top 100 customers and their average spend, average quantity by each
         year. Also find the percentage of change in their spend on YOY basis.*/
        
		 WITH TOP_CUST AS 
		 (  
		  SELECT TOP 100 CUSTOMER_NAME, B.IDCustomer, SUM(B.TOTALPRICE) AS TOT_SPEND 
		 FROM DIM_CUSTOMER A 
		 INNER JOIN FACT_TRANSACTIONS B ON A.IDCustomer = B.IDCustomer
		 GROUP BY A.CUSTOMER_NAME, B.IDCustomer
		 ORDER BY TOT_SPEND  DESC)
		 ,
		 AVERAGE AS 
		 ( 
		  SELECT CUSTOMER_NAME, B.IDCustomer, YEAR(A.DATE) AS YEAR_, 
		  AVG(A.QUANTITY) AS AVG_QTY,
		  AVG(A.TOTALPRICE) AS AVG_SPEND
		  FROM FACT_TRANSACTIONS A INNER JOIN TOP_CUST B
		  ON B.IDCustomer = A.IDCustomer
		  GROUP BY CUSTOMER_NAME, B.IDCustomer, YEAR(A.DATE))

		  SELECT CUSTOMER_NAME, YEAR_, AVG_SPEND, AVG_QTY,
		  ((AVG_SPEND-LAG(AVG_SPEND) OVER ( PARTITION BY CUSTOMER_NAME ORDER BY YEAR_ ASC))/AVG_SPEND)*100 AS PER_CHANGE
		  FROM AVERAGE
		  
  		   
		  


						
			      


          
















