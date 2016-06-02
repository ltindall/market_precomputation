<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%@ page import="java.sql.*, javax.sql.*, javax.naming.*, java.util.*, org.json.*"%>

<%
out.print("we made it"); 

       
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
                out.print(action); 
                //out.print(Integer.parseInt(request.getParamter("queries_num"))); 
                if (action.equals("insert")) {
                        int queries_num = Integer.parseInt(request.getParameter("queries_num"));
                        Random rand = new Random();
                        int random_num = rand.nextInt(1) + 30;
                        if (queries_num < random_num) random_num = queries_num;
                        Statement stmt = conn.createStatement();
                        stmt.executeQuery("SELECT proc_insert_orders(" + queries_num + "," + random_num + ")");
                        out.println("<script>alert('" + queries_num + " orders are inserted!');</script>");
                }
                else if (action.equals("refresh")) {
                        //Need to implement.
                }

        }

%>

