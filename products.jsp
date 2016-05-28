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
		if (action.equals("delete")) {
			int id = Integer.parseInt(request.getParameter("id"));
			Statement stmt = conn.createStatement();
			String sql = "UPDATE products SET is_delete = true where id = " + id;
			try {
				stmt.executeUpdate(sql);
			}
			catch(Exception e) {out.println("<script>alert('can not delete!');</script>");}
		}
		else if (action.equals("update")) {
			int id = Integer.parseInt(request.getParameter("id"));
			String name = request.getParameter("name");
			String sku = request.getParameter("sku");
			Float price = Float.parseFloat(request.getParameter("price"));
			Statement stmt = conn.createStatement();
			String sql = "UPDATE products SET name = '" + name +
					"', sku = '" + sku + "', price = " + price + " where id = " + id;
			int result = stmt.executeUpdate(sql);
			if (result == 1) out.println("<script>alert('update product sucess!');</script>");
		    else out.println("<script>alert('update product fail!');</script>");
		}
		else if (action.equals("insert")) {
			String name = request.getParameter("name");
			String category_name = request.getParameter("category_name");
			String sku = request.getParameter("sku");
			Float price = Float.parseFloat(request.getParameter("price"));
			Statement stmt1 = conn.createStatement();
			ResultSet rs1 = stmt1.executeQuery("SELECT id from categories where name = '" + category_name + "'");
			if (rs1.next()) {
				int category_id = rs1.getInt(1);
				Statement stmt2 = conn.createStatement();
				String sql = "INSERT into products(name, category_id, sku, price, is_delete) values('" + name +
						"', '" + category_id + "', '" + sku + "', '" + price + "', false)";
				int result = stmt2.executeUpdate(sql);
				if (result == 1) out.println("<script>alert('insert into product sucess!');</script>");
			    else out.println("<script>alert('insert into product fail!');</script>");
			}
			else {out.println("<script>alert('category does not exist!');</script>");}
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
		<li><a href="categories.jsp">Categories</a></li>
		<li><a href="products.jsp">Products</a></li>
		<li><a href="orders.jsp">Orders</a></li>
		<li><a href="login.jsp">Logout</a></li>
	</ul>
</div>
<table class="table table-striped">
	<th>Product Name</th>
	<th>Category Name</th>
	<th>SKU</th>
	<th>Price</th>
	<th>Update</th>
	<th>Delete</th>
	<tr>
	<form action="products.jsp" method="POST">
		<td><input name="name"/></td>
		<td><input name="category_name"/></td>
		<td><input name="sku" size="30"/></td>
		<td><input name="price" size="30"/></td>
		<td><input class="btn btn-primary" type="submit" name="submit" value="insert"/></td>
	</form>
	</tr>
<% while (rs.next()) { %>
	<tr>
	<form action="products.jsp" method="POST">
		<td><input value="<%=rs.getString("name")%>" name="name" size="15"/>
		<td><%=rs.getString("category_name")%></td>
		<td><input value="<%=rs.getString("sku")%>" name="sku" size="30"/></td>
		<td><input value="<%=rs.getFloat("price")%>" name="price" size="30"/></td>
		<input type="hidden" value="<%=rs.getInt("id")%>" name="id"/>
		<td><input class="btn btn-success" type="submit" name="submit" value="update"/></td>
	</form>
	<form action="products.jsp" method="POST">
    	<input type="hidden" value="<%=rs.getInt("id")%>" name="id"/>
    	<td><input class="btn btn-danger" type="submit" name="submit" value="delete"/></td>
    </form>
	</tr>
<% } %>
</table>

</body>
</html>