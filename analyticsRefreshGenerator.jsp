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
  try{
		maxOrderId = Integer.parseInt(request.getParameter("maxOrderId"));
	}catch(Exception e){
		maxOrderId = 0;
	}


        // out.print("running proceesing");
        conn.setAutoCommit(false);
        ResultSet newPurchases = null;
        Statement purchasesStmt = conn.createStatement(
            ResultSet.TYPE_SCROLL_INSENSITIVE,
            ResultSet.TYPE_SCROLL_INSENSITIVE
          );
        newPurchases = purchasesStmt.executeQuery("SELECT u.state_id, o.product_id, o.price  FROM orders o, users u  WHERE o.user_id = u.id and o.id > "+maxOrderId+" GROUP BY u.state_id, o.product_id, o.price");

        PreparedStatement prodTot = null;
        prodTot  = conn.prepareStatement("UPDATE productTotals SET total = total + ? where productId = ?");

        while(newPurchases.next()){
            prodTot.setDouble(1,newPurchases.getDouble("price"));
            prodTot.setInt(2,newPurchases.getInt("product_id"));
            prodTot.executeUpdate();
        }
        conn.commit();

        newPurchases.beforeFirst();

        PreparedStatement stateTot = null;
        stateTot = conn.prepareStatement("UPDATE statetotals set total = total + ? where stateId = ?");

        while(newPurchases.next()){
            stateTot.setDouble(1,newPurchases.getDouble("price"));
            stateTot.setInt(2, newPurchases.getInt("state_id"));
            stateTot.executeUpdate();
        }
        conn.commit();
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

  ResultSet newOrdersRS = null;
	Statement newOrderStmt = conn.createStatement(
            ResultSet.TYPE_SCROLL_INSENSITIVE,
            ResultSet.TYPE_SCROLL_INSENSITIVE
          );

  String newOrdersQuery = "SELECT user_id AS userId, product_id AS prodId, SUM(quantity * price) AS spent " +
                          "FROM orders " +
                          "WHERE id > " + (maxOrderId - 10) + " " +
                          "GROUP BY user_id, product_id;";
  newOrdersRS = newOrderStmt.executeQuery(newOrdersQuery);

  ResultSet top50rs = null;
	Statement topStmt = conn.createStatement(
            ResultSet.TYPE_SCROLL_INSENSITIVE,
            ResultSet.TYPE_SCROLL_INSENSITIVE
          );

  String top50Query = "SELECT p3.id AS prodId, p3.name AS prodName, COALESCE(SUM(o.price * o.quantity),0) AS totalProd " +
             "FROM Products p3 LEFT JOIN Orders o ON p3.id = o.product_id " +
             "WHERE (o.is_cart = false OR o.is_cart IS NULL) ";
  if(category != 0) {
      top50Query += "AND category_id = " + category + " ";
  }
  top50Query += "GROUP BY p3.id, p3.name " +
             "ORDER BY totalProd DESC " +
             "LIMIT 50;";
  top50rs = topStmt.executeQuery(top50Query);

  // populate json opjects with results
  JSONObject newOrdersJson = new JSONObject();
  if(newOrdersRS != null) {
    while(newOrdersRS.next()) {
      newOrdersJson.put(newOrdersRS.getInt("userId") + "," + newOrdersRS.getInt("prodId"), newOrdersRS.getDouble("spent"));
    }
  }

  JSONObject top50json = new JSONObject();
  JSONObject top50holder = new JSONObject();
  if(top50rs != null) {
    while(top50rs.next()) {
      top50holder = new JSONObject();
      top50holder.put("prodName", top50rs.getString("prodName"));
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

          // int currId = -1;
          // int newId = -1;
          // JSONObject topLevel = new JSONObject();
          // JSONObject holder = new JSONObject();
          // if(rs != null){
        	//   while(rs.next()){ //loop through results ordered by productId
        	//   	newId = rs.getInt("prodId");
      	  //       if(currId == -1) { //if the very first product
      	  //     		currId = newId;
      	  //     	}else if(currId != newId){ //if a new product
      	  //     		topLevel.put("-1," + currId, holder);
      	  //     		currId = newId;
      	  //     		holder = new JSONObject();
      	  //     	}
      	  //     	holder.put(rs.getInt("userId") + "," + rs.getInt("prodId"), rs.getInt("spent"));
          //     }
          // }
          // out.print(topLevel.toString());

          // ResultSet rs = null;
        	// Statement stmt = conn.createStatement(
          //           ResultSet.TYPE_SCROLL_INSENSITIVE,
          //           ResultSet.TYPE_SCROLL_INSENSITIVE
          //         );
          //         String analyticsQuery = "";
          //         analyticsQuery +=
          //         "SELECT k.stateid AS userid, k.state AS username, k.totalState AS totaluser, " +
          //         "k.prodid, k.prodname, k.totalprod, COALESCE(SUM(o.price * o.quantity),0) AS spent FROM " +
          //         	"(SELECT p.id AS prodId, p.name AS prodName, p.totalprod, " +
          //         	"u.id AS stateid, u.name AS state, u.totalstate FROM " +
          //         		"(SELECT * FROM ( SELECT p3.id, p3.name, COALESCE(SUM(o.price * o.quantity),0) AS " +
          //         		"totalProd FROM Products p3 LEFT JOIN Orders o ON p3.id = o.product_id WHERE " +
          //         		"(o.is_cart = false OR o.is_cart IS NULL)";
          //         if(category != 0){
          //         	analyticsQuery += "AND category_id = "+category+" ";
          //         }
          //         analyticsQuery +=
          //         "GROUP BY p3.id, p3.name ORDER BY totalprod DESC ) " +
          //         "p2 LIMIT 50) p, " +
          //         	"(SELECT * FROM " +
          //         		"( SELECT MAX(s.id) as id, s.name, COALESCE(SUM(o.price * o.quantity),0) " +
          //         		"AS totalState FROM Users u3 LEFT JOIN Orders o ON u3.id = o.user_id LEFT JOIN States s ON u3.state_id = s.id WHERE " +
          //         		"o.is_cart = false OR o.is_cart IS NULL GROUP BY s.name ORDER BY totalstate DESC ) " +
          //          		"u2 LIMIT 50) u ) k  JOIN Users u4 ON u4.state_id = k.stateid LEFT JOIN " +
          //         	"(SELECT * FROM Orders o2 WHERE o2.is_cart = false) o ON u4.id = o.user_id AND " +
          //         	"k.prodid = o.product_id GROUP BY k.prodid, k.prodname, k.totalprod, k.state, k.totalState, " +
          //         	"k.stateid ORDER BY k.totalprod DESC, k.totalstate DESC;";
          //         if(!analyticsQuery.equals("")){
          //             rs = stmt.executeQuery(analyticsQuery);
          //         }
%>
