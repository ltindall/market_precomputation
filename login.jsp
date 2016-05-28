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
		String name = request.getParameter("name");
    String role = request.getParameter("role");
    int age = Integer.parseInt(request.getParameter("age"));
    String state = request.getParameter("state");
    
    Statement stmt = conn.createStatement();
    int result = stmt.executeUpdate(
    		"INSERT INTO users (name,role,age,state) VALUES ('"+name+"', '"+role+"', '"+age+"', '"+state+"')");
		if (result == 0) {out.println("<script>alert('sign up fail!');</script>");}
	}
%>

<body>
<div class="collapse navbar-collapse">
	<ul class="nav navbar-nav">
		<li><a href="login.jsp">LOGIN</a></li>
		<li><a href="signup.jsp">SIGN UP</a></li>
	</ul>
</div>
<div>
  <form action="index.jsp" method="POST">
	  <div class="form-group">
	  	<label for="name">Name</label>
	  	<input type="text" class="form-control" id="name" name="name"/>
	  </div>
	  <div class="form-group">
	  	<input class="btn btn-primary" type="submit" value="Login">
	  </div>
  </form>
 </div>
</body>
</html>