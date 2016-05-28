<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, javax.sql.*, javax.naming.*"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">
<title>CSE135 Project</title>
</head>
<%
	Connection conn = null;
	try {
		Class.forName("org.postgresql.Driver");
    String url = "jdbc:postgresql:cse135";
    String admin = "moojin";
    String password = "pwd";
    conn = DriverManager.getConnection(url, admin, password);
	}
	catch (Exception e) {}
	
	Statement stmt = conn.createStatement();
	ResultSet rs = stmt.executeQuery("SELECT p.name as product_name, o.quantity, o.price " + 
		" FROM orders o, products p where o.is_cart = false and o.product_id = p.id and " +
		" o.user_id = " + session.getAttribute("user_id"));
%>
<body>
<div class="collapse navbar-collapse">
	<ul class="nav navbar-nav">
		<li><a href="index.jsp">Home</a></li>
		<li><a href="browsing.jsp">Product Browsing</a></li>
		<li><a href="carts.jsp">Carts</a></li>
		<li><a href="purchases.jsp">Purchases</a></li>
		<li><a href="login.jsp">Logout</a></li>
	</ul>
</div>
<table class="table table-striped">
	<th>Product Name</th>
	<th>Quantity</th>
	<th>Total Price</th>
<% while (rs.next()) { %>
	<tr>
		<td><%=rs.getString("product_name")%></td>
		<td><%=rs.getInt("quantity")%></td>
		<td><%=rs.getFloat("price")%></td>
	</tr>
<% } %>
</table>
</body>
</html>