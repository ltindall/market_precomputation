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
			stmt.executeQuery("SELECT proc_insert_orders(" + queries_num + ", "+random_num+")");
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


            int maxOrderIdOld;

            try{
              maxOrderIdOld = (Integer)application.getAttribute("maxOrderId");
            }catch(Exception e){
                    maxOrderIdOld = 0;

            }

            //out.print(maxOrderId);
            // out.print("running proceesing");
            //conn.setAutoCommit(false);
            ResultSet newPurchasesByProduct = null;
            ResultSet newPurchasesByState  = null;
            Statement purchasesStmt = conn.createStatement(
                ResultSet.TYPE_SCROLL_INSENSITIVE,
                ResultSet.TYPE_SCROLL_INSENSITIVE
              );
            Statement purchasesStmt2 = conn.createStatement(
                ResultSet.TYPE_SCROLL_INSENSITIVE,
                ResultSet.TYPE_SCROLL_INSENSITIVE
              );
            newPurchasesByProduct = purchasesStmt.executeQuery("SELECT o.product_id, o.price  FROM orders o  WHERE  o.id > "+maxOrderIdOld+" GROUP BY o.product_id, o.price");

            newPurchasesByState = purchasesStmt2.executeQuery("SELECT u.state_id, o.price  FROM orders o, users u  WHERE o.user_id = u.id and o.id > "+maxOrderIdOld+" GROUP BY u.state_id, o.price");
            PreparedStatement prodTot = null;
            prodTot  = conn.prepareStatement("UPDATE productTotals SET total = total + ? where product_id = ?");

           while(newPurchasesByProduct.next()){
                prodTot.setDouble(1,newPurchasesByProduct.getDouble("price"));
                prodTot.setInt(2,newPurchasesByProduct.getInt("product_id"));
                prodTot.executeUpdate();

            }
            //conn.commit();

            newPurchasesByProduct.beforeFirst();


            PreparedStatement stateTot = null;
            stateTot = conn.prepareStatement("UPDATE statetotals set total = total + ? where stateId = ?");
            //out.print("there");
            while(newPurchasesByState.next()){
                stateTot.setDouble(1,newPurchasesByState.getDouble("price"));
                stateTot.setInt(2, newPurchasesByState.getInt("state_id"));
                stateTot.executeUpdate();
            }
            //conn.commit();
            conn.setAutoCommit(true);


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
            		"(SELECT * FROM ( SELECT product_id as id, product_name as name, MAX(total) AS " +
            		"totalProd FROM producttotals ";
            if(category != 0){
            	analyticsQuery += "WHERE category_id = "+category+" ";
            }
            analyticsQuery +=
            "GROUP BY id, name ORDER BY totalprod DESC ) " +
            "p2 LIMIT 50) p, " +
            	"(SELECT * FROM " +
            		"( SELECT t.stateid as id, s.name, total " +
            		"AS totalState FROM stateTotals t, States s  WHERE t.stateid = s.id " +
            		"ORDER BY totalstate DESC ) " +
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
    application.setAttribute("maxOrderId", maxOrderId);
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
    <h3>Global max order id: <%=application.getAttribute("maxOrderId")%></h3>
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
    <div class="row" id="unseenProductsDiv" style="display: none;">
      <br>
      <div id="unseenProducts" class="well">
        <strong>The top 50 products have changed, these products are currently not shown: </strong>
      </div>
    </div>
</div>
  <% if ("POST".equalsIgnoreCase(request.getMethod())) { %>
  <div style="margin-left: 20px;">
    <button onclick='refreshData(<%= category %>, <%= maxOrderId %>)'>Refresh</button>
  </div>
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
        <td><button onclick='refreshData(<%= category %>, <%= maxOrderId %>)'>Refresh</button></td>
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
    	          <td id="<%= rs.getInt("userid") + ",-1"%>" class="rowHeader" style="font-weight: bold"><%=rs.getString("username") %> (<%= df.format(rs.getDouble("totalUser")) %>)</td>
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
    	          <td id="<%= rs.getInt("userid") + ",-1"%>" class="rowHeader" style="font-weight: bold"><%=rs.getString("username") %> (<%= df.format(rs.getDouble("totalUser")) %>)</td>
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
       <td><button onclick='refreshData(<%= category %>, <%= maxOrderId %>)'>Refresh</button></td>
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
        <p id="testing"></p>
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

var newMaxOrderId = 0;
function refreshData(category, maxOrderId) {
        if(newMaxOrderId > maxOrderId){
            console.log("max reset");
            maxOrderId = newMaxOrderId;
        }
        console.log("max should be = "+newMaxOrderId);
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
  newMaxOrderId = 0+ base.newMaxOrderId;
  var topLevel = base.topProducts; //build JSON object
  var columns = document.getElementsByClassName("columnHeader"); //get current columns
  var columnIds = [];
  for(var i = 0; i < columns.length; ++i){ //scrape column IDs off
  	columnIds[i] = columns[i].id;
    columns[i].style.color="black";
  }
  var rows = document.getElementsByClassName("rowHeader");
  var rowIds = [];
  for(var i = 0; i < rows.length; ++i){
      rowIds[i] = rows[i].id;
  }
  //find all columns in current set not in latest top 50
  var purpleColumns = [];
  purpleColumns = columnIds.filter(function(x) {
	  var keys = Object.keys(topLevel);
	  for(var i = 0; i < keys.length; ++i){
	  	if(topLevel[keys[i]].prodId == x.substring(3)){
			return false;
		}
	  }
	  return true;
  });

  var unseenStart = true;
  var element = null;
  var unseen = document.getElementById("unseenProducts");
  var unseenStr = "";
  for(var key in topLevel) {
    element = document.getElementById("-1,"+topLevel[key].prodId);

    if(element == null) {

      if(!unseenStart) {
        unseen.innerHTML += ", ";
      }

      unseenStr = topLevel[key].prodName + " (" + topLevel[key].totalProd + ")";
      unseen.innerHTML += unseenStr;
      unseenStart = false;
    }
  }
  if(!unseenStart) {
    document.getElementById("unseenProductsDiv").style.display = "";
  }
  //var newColumns = Object.keys(topLevel).filter(function(x) { return columnIds.indexOf(x) < 0; });
  //set all cells in purple columns to have purple text
  Object.keys(purpleColumns).forEach(function(key) {
	  var elements = document.querySelectorAll('[id$=\''+ purpleColumns[key].substring(3) + '\']');
	  Object.keys(elements).forEach(function(key1) {
		  //console.log("elements", elements[key1].id);
	  		elements[key1].style.color = "purple";
	  });
  });

  //update column headers to be red or black.
  /*
  Object.keys(topLevel).forEach(function(key) {
	  var element = document.getElementById("-1,"+topLevel[key].prodId);
	  if(element != null){
		  var number = element.innerHTML.substring(element.innerHTML.indexOf("(")+1, element.innerHTML.length-1);
		  if(number != Number(topLevel[key].totalProd).toFixed(2)){
			  element.innerHTML = element.innerHTML.replace(number, Number(topLevel[key].totalProd).toFixed(2));
			  element.style.color="red";
		  }else if(element.style.color != "purple"){
			  element.style.color="black";
		  }
	  }
  });*/

  //update all red cells NOT COLUMN HEADERS
  for(i = 0; i< rowIds.length; ++i ){
    document.getElementById(rowIds[i]).style.color = "black";
    for(j = 0; j < columnIds.length; ++j ){
        if(!((rowIds[i][0])+","+(columnIds[j][1]) in base.newOrders)){
            var currentElement = document.getElementById((rowIds[i].substring(0,rowIds[i].length-3))+","+(columnIds[j].substring(3)));
            if(currentElement.style.color == "red"){
            	currentElement.style.color = "black";
            }
        }
    }
  }
  var rowsToUpdate = [];
  for (var key in base.newOrders) {
    //console.log(key.substring(0,key.indexOf(",")));
    //console.log(key);
    rowsToUpdate.push(key.substring(0,key.indexOf(","))+",-1");

    rowHeader = document.getElementById(key.substring(0,key.indexOf(","))+",-1");
    if(rowHeader != null){
        rowHeader.innerHTML = rowHeader.innerHTML.substring(0,rowHeader.innerHTML.indexOf("("))+ " ("+ (parseFloat(rowHeader.innerHTML.substring(rowHeader.innerHTML.indexOf("(")+1,rowHeader.innerHTML.length -1)) + parseFloat(base.newOrders[key])) +")";
        rowHeader.style.color = "red";
        redCell = document.getElementById(key);
    }
    if(redCell != null) {
      redCell.style.color = "red";
      redCell.innerHTML = Number(parseInt(redCell.innerHTML) + parseInt(base.newOrders[key])).toFixed(2);
      var element = document.getElementById("-1" + redCell.id.substring(redCell.id.indexOf(",")));
      if(element != null){
		  var number = element.innerHTML.substring(element.innerHTML.indexOf("(")+1, element.innerHTML.length-1);
		  element.innerHTML = element.innerHTML.replace(number, Number(number + Number(redCell.innerHTML)).toFixed(2));
		  element.style.color="red";
	    }
      // updating each index column (leftmost and topmost)
      // splitKey = key.split(",");
      // var stateCell = document.getElementById(splitKey[0] + ",-1");
      // var prodCell = document.getElementById("-1," + splitKey[1]);
      //
      // stateCell.style.color = "red";
      // prodCell.style.color = "red";
      //
      // updateIndexCell(stateCell, parseFloat(base.newOrders[key]));
      // updateIndexCell(prodCell, parseFloat(base.newOrders[key]));
    }
  }

  /*
  for(i = 0; i< rowIds.length; ++i ){
    if(rowsToUpdate.indexOf(rowIds[i]) == -1){
        console.log("turned row header black");
        document.getElementById(rowIds[i]).style.color = "black";
    }
  }
  */

  function updateIndexCell(indexCell, updateVal) {
    var str = indexCell.innerHTML;
    var statePart = str.substring(0, str.indexOf("("));
    var num = parseFloat(str.substring(str.indexOf("(") + 1, str.indexOf(")")));

    indexCell.innerHTML = statePart + "(" + (num + updateVal).toFixed(2) + ")";
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
