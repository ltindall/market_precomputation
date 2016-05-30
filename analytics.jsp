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
        if(rs != null){
        	while(rs.next()) {
                //get first id
                if(count == 0) {
                  firstId = rs.getInt("userId");
                }
                if(count >= 50 && rs.getInt("userId") == firstId){
                    break;
                }
                //only get 50 products or only get as many products as available if less than 50
                if(count >= 50 || rs.getInt("userId") != firstId) {
                  break;
                } %>
              <td style="font-weight: bold"><%= rs.getString("prodname") %> (<%= df.format(rs.getDouble("totalProd")) %>)</td>
              <% count++;
              } //end while
              rs.beforeFirst();
        }%>
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
    	          if(userCount > 50){
    	            break;
    	          }
    	          currId = newId;
    	          prodCount = 1;%>
    	        </tr>
    	        <tr>
    	          <td style="font-weight: bold"><%=rs.getString("username") %> (<%= df.format(rs.getDouble("totalUser")) %>)</td>
    	          <td><%= df.format(rs.getDouble("spent")) %></td>
    	        <% } else { /* just another column */
    	            if(prodCount >= 50){
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
  userPageStart.value = parseInt(userPageStart.value) + 50;
  document.getElementById("queryForm").submit();
}
function nextProdPages() {
  var prodPageStart = document.getElementById("prodPageStart");
  prodPageStart.value = parseInt(prodPageStart.value) + 50;
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