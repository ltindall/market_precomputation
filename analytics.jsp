<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, javax.sql.*, javax.naming.*, java.text.DecimalFormat, java.util.*"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">
<title>CSE135 Project</title>
<%-- <link href="css/style.css" rel="stylesheet"> --%>
</head>

<%
    long startJsp =  System.currentTimeMillis();
	Connection conn = null;
	try {
		Class.forName("org.postgresql.Driver");
		String url = "jdbc:postgresql://159.203.253.157/marketPA3";
                String admin = "ltindall";
	        String password = "P3anutNJ3lly";
                conn = DriverManager.getConnection(url, admin, password);
	}
	catch (Exception e) {}
	if ("POST".equalsIgnoreCase(request.getMethod())) {
		String action = request.getParameter("submit");
		if (action != null && action.equals("insert")) {
			int queries_num = Integer.parseInt(request.getParameter("queries_num"));
			Random rand = new Random();
			int random_num = rand.nextInt(1) + 30;
			if (queries_num < random_num) random_num = queries_num;
			Statement stmt = conn.createStatement();
			stmt.executeQuery("SELECT proc_insert_orders(" + queries_num + "," + random_num + ")");
			out.println("<script>alert('" + queries_num + " orders are inserted!');</script>");
		}
		else if (action != null && action.equals("refresh")) {
			//Need to implement.
		}
	}

        int category = 0;
        int userPageStart = 0;
        int prodPageStart = 0;
        ResultSet rs = null;
        boolean hideForm = false;
        long startTime = -1;
        long endTime = -1;
	if ("POST".equalsIgnoreCase(request.getMethod())) {
            // category id for query, if all categories then it equals 0
            try{
            	category = Integer.parseInt(request.getParameter("category"));


                if(request.getParameter("userPageStart") != null && !request.getParameter("userPageStart").isEmpty()) {
                  userPageStart = Integer.parseInt(request.getParameter("userPageStart"));
                }

                if(request.getParameter("prodPageStart") != null && !request.getParameter("prodPageStart").isEmpty()) {
                  prodPageStart = Integer.parseInt(request.getParameter("prodPageStart"));
                }
            }catch(NumberFormatException e){
            	//e.printStackTrace();
            }
            

            if(userPageStart > 0 || prodPageStart > 0 ){
                hideForm = true;
            }

            Statement stmt = conn.createStatement(
              ResultSet.TYPE_SCROLL_INSENSITIVE,
              ResultSet.TYPE_SCROLL_INSENSITIVE
            );
          	// ResultSet rs = stmt.executeQuery("SELECT p.id, p.name, p.sku, p.price, c.name as category_name" +
          	// 	" FROM products p, categories c where is_delete = false and c.id = p.category_id");

          	//Query to get Top-K users and results, may need to do other queries for row/column headers otherwise merge giant tuple
          	/*
          	WITH topProducts AS (SELECT product_id FROM orders GROUP BY product_id ORDER BY SUM(price*quantity) DESC LIMIT 10),
          	topUsers AS (SELECT user_id,SUM(price*quantity) as sum FROM orders WHERE product_id IN (SELECT product_id FROM topProducts) GROUP BY user_id ORDER BY sum DESC LIMIT 20)
			SELECT users.name AS customer,products.name AS product, SUM(orders.price*orders.quantity) FROM orders JOIN users ON user_id=users.id JOIN products ON product_id=products.id
			WHERE user_id IN (SELECT user_id FROM topUsers) AND product_id IN (SELECT product_id FROM topProducts) GROUP BY users.name, products.name ORDER BY users.name, products.name;


                EDIT by Lucas(I think be incorrect to limit topUsers to people who have purchases in topProducts, as
                a topUser does not have to have any purchases in topProducts. I think I modified the query to correct that
                as well as have the sum of purchases for that user.)
                2nd EDIT: Fixed the query, now the order is correct and results match up with my modification on Ryan's for top-K
                Some things in the WHERE may be redundant

                WITH
                topProducts AS (SELECT product_id,SUM(price*quantity) as topProductSum FROM orders GROUP BY product_id ORDER BY SUM(price*quantity) DESC LIMIT 10),
                topUsers AS (SELECT user_id,SUM(price*quantity) as sum FROM orders GROUP BY user_id Order by sum DESC LIMIT 20)
                SELECT users.id as id,users.name AS customer,products.name AS product, topUsers.sum as topSum, topProducts.topProductSum, SUM(orders.price*orders.quantity)
                FROM orders JOIN users ON user_id=users.id JOIN products ON product_id=products.id JOIN topUsers on orders.user_id = topUsers.user_id JOIN topProducts on topProducts.product_id = orders.product_id
                WHERE orders.user_id IN (SELECT user_id FROM topUsers) AND orders.product_id IN (SELECT product_id FROM topProducts)
                GROUP BY users.id,users.name,products.name, topSum, topProducts.topProductSum
                ORDER BY topSum DESC, topProducts.topProductSum DESC, users.name, products.name
          	*/



            // I think some of the following would be useful indices
            // If I have time I'll start testing
            // Indices can be added/removed by running the following sql
            //CREATE INDEX students_first_name ON students(first_name)
            //DROP INDEX students_first_name
            //orders.is_cart
            //products.category_id
            //products.name
            //users.name
            //users.state
            //orders.user_id
            //orders.product_id
            String analyticsQuery = "";
            /*analyticsQuery += "SELECT k.stateid AS userid, k.state AS username, k.totalState AS totaluser, k.prodid, k.prodname, k.totalprod, COALESCE(SUM(o.price * o.quantity),0) AS spent " +
                "FROM (SELECT p.id AS prodId, p.name AS prodName, p.totalprod, u.id AS stateid, u.state AS state, u.totalstate " +
                	"FROM (SELECT * FROM ( " +
                    	"SELECT p3.id, p3.name, COALESCE(SUM(o.price * o.quantity),0) AS totalProd " +
                        "FROM Products p3 LEFT JOIN Orders o ON p3.id = o.product_id " +
                        "WHERE (o.is_cart = false OR o.is_cart IS NULL) ";*/
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
            /*analyticsQuery += "GROUP BY p3.id, p3.name ORDER BY totalprod DESC " +
                  ") p2 OFFSET " + prodPageStart + " ROWS FETCH NEXT 11 ROWS ONLY) p, " +
                         "(SELECT * FROM ( " +
                             "SELECT MAX(u3.id) as id, u3.state, COALESCE(SUM(o.price * o.quantity),0) AS totalState " +
                             "FROM Users u3 LEFT JOIN Orders o ON u3.id = o.user_id " +
                             "WHERE o.is_cart = false OR o.is_cart IS NULL " +
                             "GROUP BY u3.state " +
                             "ORDER BY totalstate DESC " +
                  ") u2 OFFSET " + userPageStart + " ROWS FETCH NEXT 21 ROWS ONLY) u " +
                  ") k  JOIN Users u4 ON u4.state = k.state LEFT JOIN (SELECT * FROM Orders o2 WHERE o2.is_cart = false) o ON u4.id = o.user_id AND k.prodid = o.product_id " +
                  "GROUP BY k.state, k.totalState, k.prodid, k.prodname, k.totalprod, k.stateid " +
                  "ORDER BY k.totalstate DESC, k.totalprod DESC ";*/
            analyticsQuery += 
            "GROUP BY p3.id, p3.name ORDER BY totalprod DESC ) " +
            "p2 OFFSET " + prodPageStart + " ROWS FETCH NEXT 11 ROWS ONLY) p, " +
            	"(SELECT * FROM " +
            		"( SELECT MAX(s.id) as id, s.name, COALESCE(SUM(o.price * o.quantity),0) " +
            		"AS totalState FROM Users u3 LEFT JOIN Orders o ON u3.id = o.user_id LEFT JOIN States s ON u3.state_id = s.id WHERE " +
            		"o.is_cart = false OR o.is_cart IS NULL GROUP BY s.name ORDER BY totalstate DESC ) " +
             		"u2 OFFSET " + userPageStart + " ROWS FETCH NEXT 21 ROWS ONLY) u ) k  JOIN Users u4 ON u4.state_id = k.stateid LEFT JOIN " +
            	"(SELECT * FROM Orders o2 WHERE o2.is_cart = false) o ON u4.id = o.user_id AND " +
            	"k.prodid = o.product_id GROUP BY k.state, k.totalState, k.prodid, k.prodname, k.totalprod, " +
            	"k.stateid ORDER BY k.totalstate DESC, k.totalprod DESC;";
                  //rs = stmt.executeQuery(analyticsQuery);
            if(!analyticsQuery.equals("")){
            	startTime = System.currentTimeMillis();
                rs = stmt.executeQuery(analyticsQuery);
                endTime = System.currentTimeMillis();
            }
	}
    Statement catStmt = conn.createStatement();
    ResultSet categories = catStmt.executeQuery("SELECT c.id,c.name FROM categories c");
    DecimalFormat df = new DecimalFormat("#.00");
%>
<body>
<div class="collapse navbar-collapse">
	<ul class="nav navbar-nav">
		<li><a href="index.jsp">Home</a></li>
		<li><a href="categories.jsp">Categories</a></li>
		<li><a href="products.jsp">Products</a></li>
		<li><a href="orders.jsp">Orders</a></li>
		<li><a href="login.jsp">Logout</a></li>
	</ul>
</div>
<div class="container">
    <div class="row">
        <form  class="form-inline" action="analytics.jsp" method="POST" id="queryForm">
            <div class="form-group">
                <label for="row">Category</label>
                <select class="form-control" id="category" name="category">
                    <option value="0"> All Categories </option>
                    <%  while(categories.next()){
                            if(categories.getInt("id") == category){
                    %>
                            <option value="<%=categories.getInt("id")%>" selected><%=categories.getString("name")%></option>
                    <%
                            }
                            else{
                    %>
                            <option value="<%=categories.getInt("id")%>"><%=categories.getString("name")%></option>
                    <%
                            }
                        }
                    %>
                </select>
            </div>
            <% if(request.getParameter("userPageStart") != null && !request.getParameter("userPageStart").isEmpty()) { %>
            <input type="number" name="userPageStart" id="userPageStart" style="display: none" value="<%=request.getParameter("userPageStart") %>">
            <input type="number" name="prodPageStart" id="prodPageStart" style="display: none" value="<%=request.getParameter("prodPageStart") %>">
            <% } else { %>
            <input type="number" name="userPageStart" id="userPageStart" style="display: none" value="0">
            <input type="number" name="prodPageStart" id="prodPageStart" style="display: none" value="0">
            <% } %>
            <input class="btn btn-primary" type="submit" name="query" value="Run Query"/>

        </form>
    </div>
</div>
  <% if ("POST".equalsIgnoreCase(request.getMethod())) { %>
  <div>
    <table class="table table-striped">
      <tr>
        <td></td>
        <% int count = 0;
        int firstId = -1;
        boolean moreProducts = false;
        if(rs != null){
        	while(rs.next()) {
                //get first id
                if(count == 0) {
                  firstId = rs.getInt("userId");
                }
                if(count >= 10 && rs.getInt("userId") == firstId){
                    moreProducts = true;
                    break;
                }
                //only get 10 products or only get as many products as available if less than 10
                if(count >= 10 || rs.getInt("userId") != firstId) {
                  break;
                } %>
              <td style="font-weight: bold"><%= rs.getString("prodname") %> (<%= df.format(rs.getDouble("totalProd")) %>)</td>
              <% count++;
              } //end while
              rs.beforeFirst();
        }%>
        
        <%
            if(moreProducts){
        %>
                <td><button class="btn btn-link" onclick="nextProdPages()">Next 10 products</button></td>
        <%
            }
        %>
      </tr>
      <tr>
      <%
      int currId = -1;
      int newId = -1;
      int userCount = 1;
      int prodCount = 0;
      if(rs != null){
    	  while(rs.next()) {
    	        newId = rs.getInt("userId");
    	        if(currId == -1) {
    	          currId = newId;
    	          prodCount = 1;%>
    	          <td style="font-weight: bold"><%=rs.getString("username") %> (<%= df.format(rs.getDouble("totalUser")) %>)</td>
    	          <td><%= df.format(rs.getDouble("spent")) %></td>
    	        <% }
    	        else if(currId != newId) { //new user found, end old row make new one
    	          userCount += 1;
    	          if(userCount > 20){
    	            break;
    	          }
    	          currId = newId;
    	          prodCount = 1;%>
    	        </tr>
    	        <tr>
    	          <td style="font-weight: bold"><%=rs.getString("username") %> (<%= df.format(rs.getDouble("totalUser")) %>)</td>
    	          <td><%= df.format(rs.getDouble("spent")) %></td>
    	        <% } else { /* just another column */
    	            if(prodCount >= 10){
    	                continue;
    	            }
    	        %>
    	          <td><%= df.format(rs.getDouble("spent")) %></td>
    	        <%
    	            prodCount += 1;
    	            } /* end ifelse */ %>
    	      <% } /* end while */
      }
       %>
      </tr>
      <%
        if(userCount > 20){
      %>
        <tr><td><button class="btn btn-link" onclick="nextUserPages()">Next 20 users</button></td></tr>
      <%
        }
      %>
    </table>
  </div>
  <% } /* endif */ %>

<script>
window.onload = function(){
    if(<%= hideForm %> == true){
        var queryForm = document.getElementById('queryForm');
        queryForm.style.visibility = 'hidden';
    }
}
function nextUserPages() {
  var userPageStart = document.getElementById("userPageStart");
  userPageStart.value = parseInt(userPageStart.value) + 20;
  document.getElementById("queryForm").submit();
}
function nextProdPages() {
  var prodPageStart = document.getElementById("prodPageStart");
  prodPageStart.value = parseInt(prodPageStart.value) + 10;
  document.getElementById("queryForm").submit();
}
</script>
<%

    long endJsp =  System.currentTimeMillis();
    out.print("<p>Query time: "+((double)(endTime - startTime))/1000+" seconds</p>");
    out.print("<p>JSP load time: "+((double)(endJsp - startJsp))/1000+" seconds</p>");
%>
<form action="analytics.jsp" method="POST">
	<label># of queries to insert</label>
	<input type="number" name="queries_num">
	<input class="btn btn-primary"  type="submit" name="submit" value="insert"/>
</form>
<form action="analytics.jsp" method="POST">
	<input class="btn btn-success"  type="submit" name="submit" value="refresh"/>
</form>
</body>
</html>