<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, javax.sql.*, javax.naming.*, org.json.*"%>
<%

	Connection conn = null;
	try {
		Class.forName("org.postgresql.Driver");
		String url = "jdbc:postgresql://159.203.253.157/marketPA3";
        String admin = "ltindall";
        String password = "P3anutNJ3lly";
        conn = DriverManager.getConnection(url, admin, password);
	}
	catch (Exception e) {}
	int category;
	try{
		category = Integer.parseInt(request.getParameter("category"));
	}catch(Exception e){
		category = 0;
	}

        int maxOrderId;
        int maxOrderIdOriginal = 0; 
        try{
		maxOrderId = Integer.parseInt(request.getParameter("maxOrderId"));
                maxOrderIdOriginal = Integer.parseInt(request.getParameter("maxOrderId")); 
                if(maxOrderId < (Integer)application.getAttribute("maxOrderId")){
                    maxOrderId = (Integer)application.getAttribute("maxOrderId"); 
                } 
                application.setAttribute("maxOrderId", maxOrderId); 
            
	}catch(Exception e){
		maxOrderId = 0;
	}

        //out.print(maxOrderId); 
        // out.print("running proceesing");
        //conn.setAutoCommit(false);
        ResultSet newPurchasesByProduct = null;
        ResultSet newPurchasesByState  = null;
        Statement purchasesStmt = conn.createStatement(
            ResultSet.TYPE_SCROLL_INSENSITIVE,
            ResultSet.TYPE_SCROLL_INSENSITIVE
          );
        Statement purchasesStmt2 = conn.createStatement(
            ResultSet.TYPE_SCROLL_INSENSITIVE,
            ResultSet.TYPE_SCROLL_INSENSITIVE
          );
        newPurchasesByProduct = purchasesStmt.executeQuery("SELECT o.product_id, o.price  FROM orders o  WHERE  o.id > "+maxOrderId+" GROUP BY o.product_id, o.price");

        newPurchasesByState = purchasesStmt2.executeQuery("SELECT u.state_id, o.price  FROM orders o, users u  WHERE o.user_id = u.id and o.id > "+maxOrderId+" GROUP BY u.state_id, o.price");
        PreparedStatement prodTot = null;
        prodTot  = conn.prepareStatement("UPDATE productTotals SET total = total + ? where productId = ?");

       /* while(newPurchasesByProduct.next()){
        
          
       
            prodTot.setDouble(1,newPurchasesByProduct.getDouble("price"));
            prodTot.setInt(2,newPurchasesByProduct.getInt("product_id"));
            prodTot.executeUpdate();
           
        }*/
        //conn.commit();
      
        newPurchasesByProduct.beforeFirst();


        PreparedStatement stateTot = null;
        stateTot = conn.prepareStatement("UPDATE statetotals set total = total + ? where stateId = ?");
        //out.print("there");
        /*while(newPurchasesByState.next()){
            stateTot.setDouble(1,newPurchasesByState.getDouble("price"));
            stateTot.setInt(2, newPurchasesByState.getInt("state_id"));
            stateTot.executeUpdate();
        }*/
        //conn.commit();
        conn.setAutoCommit(true);
  

        /*
        sql to fill precompute tables with initial data
        insert into stateTotals (stateId, total)
        select u.state_id , sum(o.price) from orders o, users u
        where o.user_id = u.id
        group by u.state_id

        insert into productTotals (productId, total)
        select o.product_id, sum(o.price) from orders o
        group by o.product_id
        */

        //out.print("down here");
        ResultSet newOrdersRS = null;
	Statement newOrderStmt = conn.createStatement(
            ResultSet.TYPE_SCROLL_INSENSITIVE,
            ResultSet.TYPE_SCROLL_INSENSITIVE
          );

  String newOrdersQuery = "SELECT u.state_id AS stateId, o.product_id AS prodId, SUM(o.quantity * o.price) AS spent " +
                          "FROM orders o JOIN users u ON u.id = o.user_id " +
                          "WHERE o.id > " + maxOrderIdOriginal + " " +
                          "GROUP BY state_id, product_id;";
  newOrdersRS = newOrderStmt.executeQuery(newOrdersQuery);

  ResultSet top50rs = null;
	Statement topStmt = conn.createStatement(
            ResultSet.TYPE_SCROLL_INSENSITIVE,
            ResultSet.TYPE_SCROLL_INSENSITIVE
          );

	String top50Query = "SELECT product_id as prodId, product_name as prodName, MAX(total) as totalProd FROM producttotals ";
  /*String top50Query = "SELECT p3.id AS prodId, p3.name AS prodName, COALESCE(SUM(o.price * o.quantity),0) AS totalProd " +
             "FROM Products p3 LEFT JOIN Orders o ON p3.id = o.product_id " +
             "WHERE (o.is_cart = false OR o.is_cart IS NULL) ";*/
  if(category != 0) {
      top50Query += "WHERE categoryId = " + category + " ";
  }
  top50Query += "GROUP BY prodId, prodName " +
             "ORDER BY totalProd DESC " +
             "LIMIT 50;";
  top50rs = topStmt.executeQuery(top50Query);

  // populate json opjects with results
  JSONObject newOrdersJson = new JSONObject();

  if(newOrdersRS != null) {
    while(newOrdersRS.next()) {
     
      newOrdersJson.put(newOrdersRS.getInt("stateId") + "," + newOrdersRS.getInt("prodId"), newOrdersRS.getDouble("spent"));
    }
  }

  JSONObject top50json = new JSONObject();
  JSONObject top50holder = new JSONObject();
  if(top50rs != null) {
    while(top50rs.next()) {
      top50holder = new JSONObject();
      top50holder.put("prodName", top50rs.getString("prodName"));
      top50holder.put("prodId", top50rs.getString("prodId"));
      top50holder.put("totalProd", top50rs.getDouble("totalProd"));
      top50json.put("" + top50rs.getInt("prodId"), top50holder);
    }
  }

  // getting the new max order id for next time
  Statement maxOrderStmt = conn.createStatement();
  ResultSet ordersMaxId = maxOrderStmt.executeQuery("SELECT MAX(id) AS maxOrderId FROM orders;");
  ordersMaxId.next();
  int newMaxOrderId = ordersMaxId.getInt("maxOrderId");

  // output json
  JSONObject output = new JSONObject();
  output.put("newOrders", newOrdersJson);
  output.put("topProducts", top50json);
  output.put("newMaxOrderId", newMaxOrderId);

  out.print(output.toString());
%>