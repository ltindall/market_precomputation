<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, javax.sql.*, javax.naming.*, java.text.DecimalFormat, java.util.*, org.json.*"%>
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
			int random_num = rand.nextInt(30) + 1;
			if (queries_num < random_num) random_num = queries_num;
			Statement stmt = conn.createStatement();
			//replaced random_num with 100 as it wasn't working
			stmt.executeQuery("SELECT proc_insert_orders(" + queries_num + ", 100)");
			out.println("<script>alert('" + queries_num + " orders are inserted!');</script>");
		}
		else if (action != null && action.equals("refresh")) {
			//Need to implement.
		}
	}

        int category = 0;
        ResultSet rs = null;
        long startTime = -1;
        long endTime = -1;
	if ("POST".equalsIgnoreCase(request.getMethod())) {
            // category id for query, if all categories then it equals 0
            try{
            	category = Integer.parseInt(request.getParameter("category"));
            }catch(NumberFormatException e){
            	//e.printStackTrace();
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
            if(!analyticsQuery.equals("")){
            	startTime = System.currentTimeMillis();
                rs = stmt.executeQuery(analyticsQuery);
                endTime = System.currentTimeMillis();
            }
	}
    Statement catStmt = conn.createStatement();
    ResultSet categories = catStmt.executeQuery("SELECT c.id,c.name FROM categories c");
    Statement orderStmt = conn.createStatement();
    ResultSet ordersMaxId = orderStmt.executeQuery("SELECT MAX(id) AS maxOrderId FROM orders");
    ordersMaxId.next();
    int maxOrderId = ordersMaxId.getInt("maxOrderId");

    DecimalFormat df = new DecimalFormat("#0.00");
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
            <input class="btn btn-primary" type="submit" name="query" value="Run Query"/>
        </form>
    </div>
</div>
  <% if ("POST".equalsIgnoreCase(request.getMethod())) { %>
  <div>
    <table id="resultTable" class="table table-striped">
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
              <td id="<%= "-1," + rs.getInt("prodid")%>" class="columnHeader" style="font-weight: bold"><%= rs.getString("prodname") %> (<%= df.format(rs.getDouble("totalProd")) %>)</td>
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
    	          <td id="<%= rs.getInt("userid") + ",-1"%>" style="font-weight: bold"><%=rs.getString("username") %> (<%= df.format(rs.getDouble("totalUser")) %>)</td>
    	          <td id="<%= rs.getInt("userid") + "," + rs.getInt("prodid")%>"><%= df.format(rs.getDouble("spent")) %></td>
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
    	          <td id="<%= rs.getInt("userid") + ",-1"%>" style="font-weight: bold"><%=rs.getString("username") %> (<%= df.format(rs.getDouble("totalUser")) %>)</td>
    	          <td id="<%= rs.getInt("userid") + "," + rs.getInt("prodid")%>"><%= df.format(rs.getDouble("spent")) %></td>
    	        <% } else { /* just another column */
    	            if(prodCount >= 50){
    	                continue;
    	            }
    	        %>
    	          <td id="<%= rs.getInt("userid") + "," + rs.getInt("prodid")%>"><%= df.format(rs.getDouble("spent")) %></td>
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
<%
    long endJsp =  System.currentTimeMillis();
    out.print("<p>Query time: "+((double)(endTime - startTime))/1000+" seconds</p>");
    out.print("<p>JSP load time: "+((double)(endJsp - startJsp))/1000+" seconds</p>");
%>
<!--<form action="analytics.jsp" method="POST">-->
	<label># of queries to insert</label>
	<input type="number" name="queries_num" id="queries_num">
	<button class="btn btn-primary"  onclick='insertOrders()'>Insert </button>
<!--</form>-->
	<button onclick='refreshData(<%= category %>, <%= maxOrderId %>)'>Refresh</button>
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>

</body>
<script type="text/javascript">
function insertOrders2(){
    var queries_num = document.getElementById('queries_num').value;
    /*
    var keyvals = {"action":"insert","queries_num":queries_num};
    $.ajax({
        type: "POST",
        url: "analyticsOrder.jsp",
        data: keyvals,
        dataType: "text",
        success: function(result){
            alert("success");
        }
    });
    */
    var ordersRequest = null;
    try{
        ordersRequest = new XMLHttpRequest();
    }
    catch(exception){}
    ordersRequest.onreadystatechange = function(){
		if(ordersRequest.readyState == XMLHttpRequest.DONE){

		}
    }
    ordersRequest.open("POST", "analyticsOrder.jsp", true);
    //ordersRequest.setRequestHeader("Content-type", "text/html");
    ordersRequest.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    ordersRequest.send("action=insert?queries_num="+queries_num);
    //ordersRequest.send();

}
function insertOrders() {
        var queries_num = document.getElementById('queries_num').value;
	var request = null;
	try{
		request = new XMLHttpRequest();
	}catch(execpion){}
	request.onreadystatechange = function(){
		if(request.readyState == XMLHttpRequest.DONE){
            //			updateTable(request.responseText);
		}
	}
        console.log("hi");
	request.open("POST", "analyticsOrder.jsp", true);
        request.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        request.send("submit=insert&queries_num="+queries_num);
}
function refreshData(category, maxOrderId) {
  console.log("max order id = " + maxOrderId);
	var request = null;
	try{
		request = new XMLHttpRequest();
	}catch(execpion){}
	request.onreadystatechange = function(){
		if(request.readyState == XMLHttpRequest.DONE){
			updateTable(request.responseText);
		}
	}
	request.open("POST", "analyticsRefreshGenerator.jsp", true);
  request.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
	request.send("category=" + category + "&maxOrderId=" + maxOrderId);
}

function updateTable(newData) {
  var base = JSON.parse(newData);
  console.log(base);
  var redCell = null;
  var topLevel = base.topProducts; //build JSON object
  var columns = document.getElementsByClassName("columnHeader"); //get current columns
  var columnIds = [];
  for(var i = 0; i < columns.length; ++i){ //scrape column IDs off
  	columnIds[i] = columns[i].id;
  }
  //find all columns in current set not in latest top 50
  var purpleColumns = []; 
  purpleColumns = columnIds.filter(function(x) { return Object.keys(topLevel).indexOf(x) > 0; });
  var newColumns = Object.keys(topLevel).filter(function(x) { return columnIds.indexOf(x) < 0; });
  Object.keys(purpleColumns).forEach(function(key) {
	  var elements = document.querySelectorAll('[id$=\''+ purpleColumns[key].substring(3) + '\']');
	  Object.keys(elements).forEach(function(key1) {
	  		elements[key1].style.color = "purple";
	  });
  });
  /*
  for(var i = 0; i < purpleColumns.length; ++i){
  	var elements = document.querySelectorAll('[id$=\''+ purpleColumns[i] + '\']');
  	for(var j = 0; j < elements.length; ++j){
  		elements[i].style.color = "purple";
  	}
  }*/
  for (var key in base.newOrders) {
    redCell = document.getElementById(key);
    if(redCell != null) {
      // console.log(key);
      redCell.style.color = "red";
      redCell.innerHTML = Number(base.newOrders[key]).toFixed(2);
      //redCell.style.backgroundColor = "red";
      //redCell.innerHTML = (parseInt(redCell.innerHTML) + parseInt(base.newOrders[key]));
    }
  }


	// var table = document.getElementById('resultTable');
	// if(table){
	// 	try{
	// 		var topLevel = JSON.parse(newData); //build JSON object
	// 		var columns = document.getElementsByClassName("columnHeader"); //get current columns
	// 		var columnIds;
	// 		for(var i = 0; i < columns.length; ++i){ //scrape column IDs off
	// 			columnIds[i] = columns[i].id;
	// 		}
	// 		//find all columns in current set not in latest top 50
	// 		var purpleColumns = columnIds.filter(function(x) { return Object.keys(topLevel).indexOf(x) < 0; });
	// 		var newColumns = Object.keys(topLevel).filter(function(x) { return columnIds.indexOf(x) < 0; });
	// 		for(var i = 0; i < purpleColumns.length; ++i){
	// 			var elements = document.querySelectorAll('[id$=,'+ purpleColumns[i] + ']');
	// 			for(var j = 0; j < elements.length; ++j){
	// 				elements[i].style.color = "purple";
	// 			}
	// 		}
	// 		Object.keys(topLevel).forEach(function(key) {
	// 		    console.log(key, topLevel[key]);
	// 		});
	// 		window.alert("success");
	// 	}catch(exception){
	// 		console.log(newData);
	// 	}
	// }
}
</script>
</html>
