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
			String sql = "DELETE FROM categories where id = " + id;
			try {
				stmt.executeUpdate(sql);
			}
			catch(Exception e) {out.println("<script>alert('can not delete!');</script>");}
		}
		else if (action.equals("update")) {
			int id = Integer.parseInt(request.getParameter("id"));
			String name = request.getParameter("name");
			String description = request.getParameter("description");
			Statement stmt = conn.createStatement();
			String sql = "UPDATE categories SET name = '" + name +
					"', description = '" + description + "' where id = " + id;
			int result = stmt.executeUpdate(sql);
			if (result == 1) out.println("<script>alert('update category sucess!');</script>");
		    else out.println("<script>alert('update category fail!');</script>");
		}
		else if (action.equals("insert")) {
			String name = request.getParameter("name");
			String description = request.getParameter("description");
			Statement stmt = conn.createStatement();
			String sql = "INSERT into categories(name, description) values('" + name +
					"', '" + description + "')";
			int result = stmt.executeUpdate(sql);
			if (result == 1) out.println("<script>alert('insert into category sucess!');</script>");
		    else out.println("<script>alert('insert into category fail!');</script>");
		}
	}
	
	Statement stmt = conn.createStatement();
	ResultSet rs = stmt.executeQuery("SELECT * FROM categories");
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
	<th>Category Name</th>
	<th>Description</th>
	<th>Insert/Update</th>
	<th>Delete</th>
	<tr>
	<form action="categories.jsp" method="POST">
		<td><input name="name"/></td>
		<td><input name="description" size="60"/></td>
		<td><input class="btn btn-primary" type="submit" name="submit" value="insert"/></td>
	</form>
	</tr>
<% while (rs.next()) { %>
	<tr>
	<form action="categories.jsp" method="POST">
		<td><input value="<%=rs.getString("name")%>" name="name"/></td>
		<td><input value="<%=rs.getString("description")%>" name="description" size="60"/></td>
		<input type="hidden" value="<%=rs.getInt("id")%>" name="id"/>
		<td><input class="btn btn-success" type="submit" name="submit" value="update"/></td>
	</form>
	<form action="categories.jsp" method="POST">
    	<input type="hidden" value="<%=rs.getInt("id")%>" name="id"/>
    	<td><input class="btn btn-danger" type="submit" name="submit" value="delete"/></td>
    </form>
	</tr>
<% } %>
</table>

</body>
</html>