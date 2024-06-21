import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.PreparedStatement;
public class ecommesta {

    // The JDBC driver to be used
    private static final String Driver = "org.postgresql.Driver";

    // The URL of the database to be accessed
    private static final String Database = "jdbc:postgresql://localhost:5432/Mercadone";

    // Username for accessing the database
    private static final String User = "postgres";

    // Password for accessing the database
    private static final String Password = "ecommesta";

    public static void main(String[] args) {

        // Connection to the DBMS
        Connection con = null;

        // Statements to be executed
        Statement st1 = null; // do we need prepared one, or just statement would be fine?
        Statement st2 = null;

        // Results of the statements
        ResultSet resset1 = null;
        ResultSet resset2 = null;

        // Start and end times of a statement
        long start;
        long end;

        try {
            // Register the JDBC driver
            Class.forName(Driver);
            System.out.printf("Driver %s is successfully registered. %n", Driver);

        } catch (ClassNotFoundException e) {
            System.out.printf("Driver %s not found : %s.%n", Driver, e.getMessage());
            // terminate with a generic error code
            System.exit(-1);
        }
        try {
            // Connect to the database
            start = System.currentTimeMillis();
            con = DriverManager.getConnection(Database, User, Password);
            end = System.currentTimeMillis();
            System.out.printf("Connection to database %s successfully established in %,d milliseconds .%n", Database, end - start);

            // Create first statement to execute the first query
            start = System.currentTimeMillis();
            st1 = con.createStatement();
            end = System.currentTimeMillis();
            System.out.printf("%nStatement 1 Description: For each cashier, get their surname and name, the id of the store they work for %nand how many times has a customer used the loyalty program when they were attending at the register, %nand how many of them were unique customers. %n");
            System.out.printf("%nStatement 1 successfully created in %,d milliseconds.", end - start);

            // Execute the query and get the results
            String sqlqr1 =
                    "SELECT storeid, surname, name, total_receipts, unique_customers\n" +
                    "    FROM (SELECT e.surname, e.name, e.storeid, COUNT(r.receiptid) AS total_receipts,\n" +
                    "    COUNT(DISTINCT b.email) AS unique_customers\n" +
                    "            FROM Employee AS e INNER JOIN Receipt AS r\n" +
                    "                ON e.employeeid = r.employeeid\n" +
                    "            LEFT JOIN BelongsTo AS b\n" +
                    "                ON r.receiptid = b.receiptid\n" +
                    "            WHERE e.position = 'Cashier'\n" +
                    "            GROUP BY e.surname, e.name, e.storeid)\n" +
                    "ORDER BY storeid;";
            start = System.currentTimeMillis();
            resset1 = st1.executeQuery(sqlqr1);
            end = System.currentTimeMillis();

            System.out.printf("%nQUERY1: Query successfully executed %,d milliseconds.%n", end - start);
            System.out.printf("Query 1 Results: %n");
            System.out.printf("-----------------------------------------------------------------------%n");
            System.out.printf("| %-7s | %-8s | %-9s | %-14s | %-16s |%n", "StoreID", "Surname", "Name", "Total Receipts", "Unique Customers");
            System.out.printf("-----------------------------------------------------------------------%n");
            int storeid;
            String surname;
            String name;
            int total_receipts;
            int unique_customers;

            // print the results via a loop
            while (resset1.next()) {
                storeid = resset1.getInt("storeid");
                surname = resset1.getString("surname");
                name = resset1.getString("name");
                total_receipts = resset1.getInt("total_receipts");
                unique_customers = resset1.getInt("unique_customers");
                System.out.printf("| %-7s | %-8s | %-9s |       %-7s  |        %-9s |%n", storeid, surname, name, total_receipts, unique_customers);
            }

            // Create second statement to execute the second query
            String sqlqr2 =
                    "SELECT store_id, category_name, ROUND(100*category_quantity/total_quantity,2) AS percentage\n" +
                    "    FROM (SELECT s.storeid AS store_id, c.categoryname AS category_name,\n" +
                    "    SUM(COALESCE(co.quantity, 0)) AS category_quantity,\n" +
                    "    SUM(SUM(COALESCE(co.quantity, 0))) OVER (PARTITION BY s.storeid) AS total_quantity\n" +
                    "            FROM Category AS c LEFT JOIN Product AS p\n" +
                    "                ON c.categoryname = p.category\n" +
                    "            LEFT JOIN Contains AS co\n" +
                    "                ON p.productid = co.productid\n" +
                    "            LEFT JOIN Receipt AS r\n" +
                    "                ON co.receiptid = r.receiptid\n" +
                    "            LEFT JOIN Store AS s\n" +
                    "                ON r.storeid = s.storeid\n" +
                    "            WHERE DATE_TRUNC('month', r.date) = DATE_TRUNC('month', CURRENT_DATE)\n" +
                    "            GROUP BY s.storeid, c.categoryname);";
            start = System.currentTimeMillis();
            st2 = con.createStatement();
            end = System.currentTimeMillis();
            System.out.printf("%nStatement 2 Description: For each store, get its id and the percentage of products %nbought ordered by category during the current month. %n");
            System.out.printf("%nStatement 2 successfully created in %,d milliseconds.", end - start);

            // Execute second query
            start = System.currentTimeMillis();
            resset2 = st2.executeQuery(sqlqr2);
            end = System.currentTimeMillis();
            System.out.printf("%nQUERY2: Query successfully executed %,d milliseconds.%n", end - start);

            System.out.printf("Query 2 Results: %n");
            System.out.printf("-----------------------------------------------------------%n");
            System.out.printf("| %-7s | %-32s | %-10s |%n", "StoreID", "Category Name", "Percentage");
            System.out.printf("-----------------------------------------------------------%n");
            int storeid2;
            String category_name;
            double percentage;

            while (resset2.next()) {
                storeid2 = resset2.getInt("store_id");
                category_name = resset2.getString("category_name");
                percentage = resset2.getDouble("percentage");

                System.out.printf("| %-7s | %-32s | %-10s |%n", storeid2, category_name, percentage);
            }

        } catch (SQLException e) {
            System.out.printf("Database access error: %n");
            // cycle in the exception chain
            while (e != null) {
                //e. printStackTrace();
                System.out.printf("-Message: %s", e.getMessage());
                System.out.printf("-SQL status code: %s", e.getSQLState());
                System.out.printf("-SQL error code: %s", e.getErrorCode());
                System.out.printf("%n");
                e = e.getNextException();
            }
        }

        finally {
            try {
                if (resset1 != null || resset2 != null) {
                    start = System.currentTimeMillis();
                    resset1.close();
                    resset2.close();
                    end = System.currentTimeMillis();
                    System.out.printf("%nResult sets are successfully closed in final block in %,d milliseconds.", end - start );
                }
                if (st1 != null || st2 != null) {
                    start = System.currentTimeMillis();
                    st1.close();
                    st2.close();
                    end = System.currentTimeMillis();
                    System.out.printf("%nStatements are successfully closed in final block in %,d milliseconds.", end - start);
                }
                if (con != null) {
                    start = System.currentTimeMillis();
                    con.close();
                    end = System.currentTimeMillis();
                    System.out.printf("%nConnection successfully closed in final block in %,d milliseconds. %n", end - start);
                }

            } catch (SQLException e) {
                System.out.printf("Error while releasing resources: %s", e.getMessage());
                while (e != null) {
                    //e.printStackTrace();
                    System.out.printf("-Message: %s", e.getMessage());
                    System.out.printf("-SQL status code: %s", e.getSQLState());
                    System.out.printf("-SQL error code: %s", e.getErrorCode());
                    System.out.printf("%n");
                    e = e.getNextException();
                }

            } finally{
                resset1 = null;
                resset2 = null;
                st2 = null;
                st1 = null;
                con = null;
                System.out.printf("Resources are released to the garbage collector. %n");
            }
        }
        System.out.printf("Program ended. %n");
    }
}

