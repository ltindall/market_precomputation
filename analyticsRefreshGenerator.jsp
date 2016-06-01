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
	
	ResultSet rs = null;
	Statement stmt = conn.createStatement(
            ResultSet.TYPE_SCROLL_INSENSITIVE,
            ResultSet.TYPE_SCROLL_INSENSITIVE
          );
          String analyticsQuery = "";
          analyticsQuery += 
          "SELECT k.stateid AS userid, k.state AS username, k.totalState AS totaluser, " +
          "k.prodid, k.prodname, k.totalprod, COALESCE(SUM(o.price * o.quantity),0) AS spent FROM " +
          	"(SELECT p.id AS prodId, p.name AS prodName, p.totalprod, " +
          	"u.id AS stateid, u.name AS state, u.totalstate FROM " +
          		"(SELECT * FROM ( SELECT p3.id, p3.name, COALESCE(SUM(o.price * o.quantity),0) AS " +
          		"totalProd FROM Products p3 LEFT JOIN Orders o ON p3.id = o.product_id WHERE " +
          		"(o.is_cart = false OR o.is_cart IS NULL)";
          if(category != 0){
          	analyticsQuery += "AND category_id = "+category+" ";
          }
          analyticsQuery += 
          "GROUP BY p3.id, p3.name ORDER BY totalprod DESC ) " +
          "p2 LIMIT 50) p, " +
          	"(SELECT * FROM " +
          		"( SELECT MAX(s.id) as id, s.name, COALESCE(SUM(o.price * o.quantity),0) " +
          		"AS totalState FROM Users u3 LEFT JOIN Orders o ON u3.id = o.user_id LEFT JOIN States s ON u3.state_id = s.id WHERE " +
          		"o.is_cart = false OR o.is_cart IS NULL GROUP BY s.name ORDER BY totalstate DESC ) " +
           		"u2 LIMIT 50) u ) k  JOIN Users u4 ON u4.state_id = k.stateid LEFT JOIN " +
          	"(SELECT * FROM Orders o2 WHERE o2.is_cart = false) o ON u4.id = o.user_id AND " +
          	"k.prodid = o.product_id GROUP BY k.prodid, k.prodname, k.totalprod, k.state, k.totalState, " +
          	"k.stateid ORDER BY k.totalprod DESC, k.totalstate DESC;";
          if(!analyticsQuery.equals("")){
              rs = stmt.executeQuery(analyticsQuery);
          }
          int currId = -1;
          int newId = -1;
          JSONObject topLevel = new JSONObject();
          JSONObject holder = new JSONObject();
          if(rs != null){
        	  while(rs.next()){ //loop through results ordered by productId
        	  	newId = rs.getInt("prodId");
      	        if(currId == -1) { //if the very first product
      	      		currId = newId;
      	      	}else if(currId != newId){ //if a new product
      	      		topLevel.put("-1," + currId, holder);
      	      		currId = newId;
      	      		holder = new JSONObject();
      	      	}
      	      	holder.put(rs.getInt("userId") + "," + rs.getInt("prodId"), rs.getInt("spent"));
              }
          }
          out.print(topLevel.toString());
%>