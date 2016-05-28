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
	
	if ("POST".equalsIgnoreCase(request.getMethod())) {
		String action = request.getParameter("submit");
		if (action.equals("cart")) {
			int product_id = Integer.parseInt(request.getParameter("id"));
			int user_id = (Integer) session.getAttribute("user_id");
			Float price = Float.parseFloat(request.getParameter("price"));
			int quantity = Integer.parseInt(request.getParameter("quantity"));
		    if (quantity > 0) {
		    	Statement stmt = conn.createStatement();
			    String sql = "INSERT INTO orders (user_id,product_id,quantity,price,is_cart) " +
			    	"VALUES ('"+user_id+"', '"+product_id+"', '"+quantity+"', '"+price*quantity+"', true)";
			    int result = stmt.executeUpdate(sql);
			    if (result == 1) out.println("<script>alert('insert into cart success');</script>");
			    else out.println("<script>alert('insert into cart fail');</script>");
		    }
		    else {out.println("<script>alert('? quantity = 0.');</script>");}
		}
		else if (action.equals("purchase")) {
		    Statement stmt = conn.createStatement();
		    String sql = "UPDATE orders SET is_cart = false where user_id = " + session.getAttribute("user_id") +
		    		" and is_cart = true";
		    int result = stmt.executeUpdate(sql);
		    if (result == 1) out.println("<script>alert('purchase sucess!');</script>");
		    else out.println("<script>alert('purchase fail!');</script>");
		}
	}
	Statement stmt = conn.createStatement();
	ResultSet rs = stmt.executeQuery("SELECT p.id, p.name, p.sku, p.price, c.name as category_name" + 
		" FROM products p, categories c where is_delete = false and c.id = p.category_id");
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
	<th>Category Name</th>
	<th>SKU</th>
	<th>Price</th>
	<th>Quantity</th>
	<th>Cart</th>
<% while (rs.next()) { %>
	<tr>
		<td><input value="<%=rs.getString("name")%>" name="name" size="15"/>
		<td><input value="<%=rs.getString("category_name")%>" name="category_name" size="30"/></td>
		<td><input value="<%=rs.getString("sku")%>" name="sku" size="30"/></td>
	<form action="browsing.jsp" method="POST">
		<td><input value="<%=rs.getFloat("price")%>" name="price" size="30"/></td>
		<td><input value="0" name="quantity" size="30"/></td>
    	<input type="hidden" value="<%=rs.getInt("id")%>" name="id"/>
    	<td><input class="btn btn-primary" type="submit" name="submit" value="cart"/></td>
    </form>
	</tr>
<% } %>
</table>
</body>

</html>