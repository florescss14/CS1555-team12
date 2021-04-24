//run this with: java -cp "postgresql-42.2.18.jar;." team12.java abc1 password
import java.sql.*;
import java.sql.Types;
import java.io.*;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Properties;
import java.util.Scanner;

public class team12 {
	static PreparedStatement statement;
	static String userLogin;
    public static void main(String args[]) throws
        SQLException, ClassNotFoundException, IOException {
        Class.forName("org.postgresql.Driver");
        String url = "jdbc:postgresql://class3.cs.pitt.edu:5432/";
        Properties props = new Properties();
        props.setProperty("user", args[0]);
        
        
        Scanner reader = new Scanner(System.in);
        
        //CHANGE PW (2nd arg)
        props.setProperty("password", args[1]);
        
        Connection conn = DriverManager.getConnection(url, props);

        Statement st = conn.createStatement();
        boolean operatingFlag = true;
    	boolean isAdmin = askAboutAdmin(reader);

		conn.setAutoCommit(false);
		userLogin = checkForPassword(st, conn, isAdmin, reader);

        try {
            while(operatingFlag) {
            	
            	boolean validInput = false;
            	int in=0;
            	while(!validInput) {
            		printChoices(isAdmin);
            		try {
            			in = Integer.parseInt(input(reader));
            			if(in >=0 && (isAdmin&&in<8)||((!isAdmin)&&in<13))
            				validInput = true;
            			else
            				throw new Exception();
            		}catch(Exception e){
            			print("Invalid input. try again");
            		}
            	}
            	if(in==0) {
            		operatingFlag=false;
            	}else {
            		interpretSelection(in, isAdmin, st, reader, conn);
            		conn.commit();
            	}
            	
            }
            
        } catch (Exception e1) {
            try {
                conn.rollback();
            } catch (Exception e2) {
                System.out.println(e2.toString());
            }
        }
        reader.close();
    }
    
    private static void interpretSelection(int in, boolean isAdmin, Statement st, Scanner reader, Connection conn) throws IOException {
		if(isAdmin) {
			if(in==1) {
				eraseDatabase(st, conn, reader);
			}
			if(in==2) {
				addCustomer(st, conn, reader);
			}
			if(in==3) {
				addFund(st, conn, reader);
			}
			if(in==4) {
				updateQuote(st, conn, reader);
			}
			if(in==5) {
				showCategories(st, conn, reader);
			}
			if(in==6) {
				rankInvestors(st, conn, reader);
			}
			if(in==7) {
				updateTimestamp(st, conn, reader);
			}
		}else {
			if(in==1) {
				showCustomer(st,conn,reader);
			}
			if(in==2) {
				showFundsByName(st,conn,reader);
			}
			if(in==3) {
				showFundsByPrice(st,conn,reader);
			}
			if(in==4) {
				searchForFund(st,conn,reader);
			}
			if(in==5) {
				depositAmount(st,conn,reader);
			}
			if(in==6) {
				buyShares(st,conn,reader);
			}
			if(in==7) {
				sellShares(st,conn,reader);
			}
			if(in==8) {
				showROI(st,conn,reader);
			}
			if(in==9) {
				predict(st,conn,reader);
			}
			if(in==10) {
				changePreference(st,conn,reader);
			}
			if(in==11) {
				rankAllocations(st,conn,reader);
			}
			if(in==12) {
				showPortfolio(st,conn,reader);
			}
			
		}
	}
    
    private static void showPortfolio(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		
	}

	private static void rankAllocations(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		
	}

	private static void changePreference(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		
	}

	private static void predict(Statement st, Connection conn, Scanner reader) {
				try {

			statement = conn.prepareStatement("select * from predicted where login = ?;");
			statement.setString(1, userLogin);
			ResultSet ROI = statement.executeQuery();
			while(ROI.next()){
				String a = ROI.getString(2);
				int b = (int) Double.parseDouble(ROI.getString(3));
				
				int c = Integer.parseInt(ROI.getString(4));
				
				if(a.equals("buy")) {
					if(b<0) {
						System.out.println("Difference: " + b + " Predicted: " + c + " Status: loss");
					}else if(b>0){
						System.out.println("Difference: " + b + " Predicted: " + c + " Status: profit");
					}else{
						System.out.println("Difference: " + b + " Predicted: " + c + " Status: hold");
					}
				}else if(a.equals("sell")) {
					if(b<0) {
						System.out.println("Difference: " + b + " Predicted: " + c + " Status: profit");
					}else if(b>0){
						System.out.println("Difference: " + b + " Predicted: " + c + " Status: loss");
					}else{
						System.out.println("Difference: " + b + " Predicted: " + c + " Status: hold");
					}
				}else {
					System.out.println("Unexpected error");
				}
			}
		} catch (SQLException e) {
			System.out.println("Unexpected error");
			e.printStackTrace();
		}
	}

	private static void showROI(Statement st, Connection conn, Scanner reader, String userLogin) {
		try {
			statement = conn.prepareStatement("select show_roi(?);");
			statement.setString(1, userLogin);
			ResultSet ROI = statement.executeQuery();
			while(ROI.next()){
				String a = ROI.getString(1);
				if(a.length()==0)
					print("You have no investments!");
				else
					print("\n"+a+"\n");
			}
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
	}

	private static void showROI(Statement st, Connection conn, Scanner reader) {
		try {
			statement = conn.prepareStatement( "select show_roi(?);");
			statement.setString(1, userLogin);
			ResultSet ROI = statement.executeQuery();
			while(ROI.next()){
				String a = ROI.getString(1);
				if(a.length()==0)
					print("You have no investments!");
				else
					print("\n"+a+"\n");
			}
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	private static void sellShares(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		print("Enter symbol of fund to sell: ");
		String sym = reader.nextLine();
		print("Enter the number of shares to sell: ");
		int n = reader.nextInt();

		try{
			statement = conn.prepareStatement("select sell_shares(?, ?, ?)");
			statement.setString(1, userLogin);
			statement.setString(2, sym);
			statement.setInt(3, n);
			ResultSet res = statement.executeQuery();
			if(res.next()){
				print("\n Successfully sold " + n + " shares.");
			} else{
				print("\n Error selling shares. Are you sure you have enough shares to sell?");
			}
		}catch (SQLException e){
			e.printStackTrace();
		}
	}

	private static void buyShares(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		print("Enter symbol of fund to buy: ");
		String sym = reader.nextLine();
		print("Enter the number of shares to buy: ");
		int n = reader.nextInt();
		try{
			statement = conn.prepareStatement("select buy_shares(?, ?, ?)");
			statement.setString(1, userLogin);
			statement.setString(2, sym);
			statement.setInt(3, n);
			ResultSet res = statement.executeQuery();
			if(res.next()){
				print("\n Successfully bought " + n + " shares.");
			}else{
				print("\n Error buying shares. Check your balance?");
			}
		}catch(SQLException e){
			e.printStackTrace();
		}
	}

	private static void depositAmount(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		print("Enter dollar amount to deposit in the form XXXX.XX: ");
		Double amt = Double.parseDouble(reader.nextLine());
		BigDecimal amtd = new BigDecimal(amt);
		try{
			statement = conn.prepareStatement("call deposit_for_investment(?, ?)");
			statement.setString(1, userLogin);
			statement.setBigDecimal(2, amtd);
			statement.executeUpdate();
			conn.commit();
			print("Successfully deposited " + amt);
		}catch (SQLException e){
			e.printStackTrace();
		}

	}

	private static void searchForFund(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		print("Enter a keyword to search for: ");
		String k1 = reader.nextLine();
		print("Enter a second keyword (optional, or just press enter): ");
		String k2 = reader.nextLine();

		try{
			ResultSet funds;
			if(k2.length() > 1){
				statement = conn.prepareStatement("select search_funds(?, ?)");
				statement.setString(1, k1);
				statement.setString(2, k2);
				funds = statement.executeQuery();
				conn.commit();
			}else{
				statement = conn.prepareStatement("select search_funds(?)");
				statement.setString(1, k1);
				funds = statement.executeQuery();
				conn.commit();
			}
			//print funds
			print("Funds matching your query: ");
			while(funds.next()){
				print(funds.getString(1));
			}
			print("");
		} catch (SQLException e){
			e.printStackTrace();
		}
	}

	private static void showFundsByPrice(Statement st, Connection conn, Scanner reader) {
		print("Enter date (DD-MM-YYYY):");
		String date = reader.nextLine();
		
		try {
			statement = conn.prepareStatement("select * from mutual_funds_on_date(to_date(?,\'DD-MM-YY\'), ?);");
			statement.setString(1, date);
			statement.setString(2, userLogin);
			ResultSet funds_on_date = statement.executeQuery();
			conn.commit();
			print("Currently Owned stocks will appear with a star (*) next to them");
			print("Symbol, Name, Description, Category, c_date:");
			while(funds_on_date.next()){
				if(funds_on_date.getString("owned") != null){
					System.out.print("* ");
				}else{
					System.out.print("  ");
				}
				System.out.print(funds_on_date.getString(1) + ", ");    //First Column
				System.out.print(funds_on_date.getString(2) + ", ");    //First Column
				System.out.print(funds_on_date.getString(3) + ", ");    //First Column
				System.out.print(funds_on_date.getString(4) + ", ");    //First Column
				System.out.println(funds_on_date.getString(5));    //First Column
			}
			
			
		} catch (SQLException e) {
			
			e.printStackTrace();
		}
		
	}

	private static void showFundsByName(Statement st, Connection conn, Scanner reader) {
		try {
			statement = conn.prepareStatement("select * from customer_balance_and_shares();");
			ResultSet res = statement.executeQuery();
			conn.commit();
			print("Symbol, Name, Description, Category, Date Founded:");
			while(res.next()){
				System.out.print(res.getString(1) + ", ");    //First Column
				System.out.print(res.getString(2) + ", ");    //Second Column
				System.out.print(res.getString(3) + ", ");    //Third Column
				System.out.print(res.getString(4) + ", ");    //Fourth Column
				System.out.println(res.getString(5));    //Fifth Column
			}
			System.out.println();
			
		} catch (SQLException e) {
			
			e.printStackTrace();
		}
		
	}

	private static void showCustomer(Statement st, Connection conn, Scanner reader) {
			
		try {
			statement = conn.prepareStatement("select * from customer_balance_and_shares(?);");
			statement.setString(1, userLogin);
			ResultSet res = statement.executeQuery();
			conn.commit();
			print("Name, Balance, Shares");
			while(res.next()){
				System.out.print(res.getString(1) + ", ");    //First Column
				System.out.print(res.getString(2) + ", ");    //First Column
				System.out.println(res.getString(3));    //First Column
			}
			
		} catch (SQLException e) {
			
			e.printStackTrace();
		}
		
	}

	private static void updateTimestamp(Statement st, Connection conn, Scanner reader) {
		print("Enter date to update date to (DD-MM-YYYY):");
		String date = reader.nextLine();
		try {
			statement = conn.prepareStatement("CALL set_current_date(TO_DATE(?, \'DD-MM-YYYY\'));");
			statement.setString(1, date);
			print(statement.toString());
			statement.executeUpdate();
			conn.commit();
			
		} catch (SQLException e) {
			
			e.printStackTrace();
		}
		
	}

	private static void rankInvestors(Statement st, Connection conn, Scanner reader) {
		print("Ranking all investors");
		try{
			ResultSet res = st.executeQuery("select * From rank_all_investors();");
			conn.commit();
			print("login, wealth, rank:");
			while(res.next()){
				System.out.print(res.getString(1) + ", ");    //First Column
				System.out.print(res.getString(2) + ", ");    //First Column
				System.out.println(res.getString(3));    //First Column
			}
		}catch (SQLException e) {
			
			e.printStackTrace();
		}
		
		
	}

	private static void showCategories(Statement st, Connection conn, Scanner reader) {
		print("Enter value(integer) for top k categories");
		String k = reader.nextLine();
		
		try {
			statement = conn.prepareStatement("SELECT * From show_k_highest_volume_categories(?);");
			statement.setInt(1, Integer.parseInt(k));
			ResultSet res = statement.executeQuery();
			conn.commit();
			print("Categories:");
			while(res.next()){
					System.out.println(res.getString(1));    //First Column
			}
			
		} catch (SQLException e) {
			
			e.printStackTrace();
		}
		
	}

	private static void updateQuote(Statement st, Connection conn, Scanner reader) throws FileNotFoundException {
		print("Please specify the file name of your Mutual Funds ex. Sample.txt");
		String fileName = reader.nextLine();
		File myObj = new File(fileName);
		Scanner fileReader = new Scanner(myObj);
		ArrayList<String> myList = new ArrayList<String>();
		String delimeters = ", |,";
		String line[];
		while(fileReader.hasNextLine()){
			line = fileReader.nextLine().split(delimeters);
			myList.add(line[0]);
			myList.add(line[1]);
		}
		StringBuilder sqlCall = new StringBuilder();
		
		sqlCall.append("call update_share_quotes(\'{");
		for(int i = 0; i < myList.size(); i++){
			sqlCall.append(myList.get(i));
			if(i + 1 != myList.size()){
				sqlCall.append(", ");
			}
		}
		sqlCall.append("}\');");
		
		try {
			st.executeUpdate(sqlCall.toString());
			conn.commit();
			
		} catch (SQLException e) {
			
			e.printStackTrace();
		}
	}

	private static void addFund(Statement st, Connection conn, Scanner reader) {
		print("Please input Mutual Fund as follows: Symbol, Name, Description, Category, Current_Date(DD-MON-YY)");
		String input = reader.nextLine();
		String delimiters = ", |,";
		String values[] = input.split(delimiters);
		
		String symbol = values[0];
		String name = values[1];
		String description = values[2];
		String category = values[3];
		String c_date = values[4];

		try {
			statement = conn.prepareStatement("call new_mutual_fund(?, ?, ?, ?, TO_DATE(?, \'DD-MON-YY\'));");
			statement.setString(1, symbol);
			statement.setString(2, name);
			statement.setString(3, description);
			statement.setString(4, category);
			statement.setString(5, c_date);
			statement.executeUpdate();
			
			conn.commit();
			
		} catch (SQLException e) {
			
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		
	}

	private static void addCustomer(Statement st, Connection conn, Scanner reader) {
		print("Please input Customer as follows: Login, Name, Email, Password, Initial Balance (optional)");
		String input = reader.nextLine();
		String delimiters = ", |,";
		String values[] = input.split(delimiters);

		String login = values[0];
        String name = values[1];
        String email = values[2];
		String password = values[3];
		String balance;
		
		
		try {
			statement = conn.prepareStatement("call add_customer(?, ?, ?, \'null\', ?, ?);");
			statement.setString(1, login);
			statement.setString(2, name);
			statement.setString(3, email);
			statement.setString(4, password);
			if(values.length == 5){
				balance = values[4];
				statement.setString(5, balance);
			}else{
				statement.setNull(5, Types.DECIMAL);
			}
			print(statement.toString());
			statement.executeUpdate();
			conn.commit();
			
		} catch (SQLException e) {
			
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public static void eraseDatabase(Statement st, Connection conn, Scanner reader) throws IOException{
    	print("Are you sure? (y/n)");
		if(input(reader).toLowerCase().charAt(0) != 'y'){
			return;
		}
		
		try {
			st.executeUpdate("call erase_database()");
			conn.commit();
			
		} catch (SQLException e) {
			
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

    	
    }
	public static boolean askAboutAdmin(Scanner reader) throws IOException {
    	print("Are you a an admin? (y/n)");
    	if (input(reader).toLowerCase().charAt(0)=='y')
    		return true;
    	return false;
    }
	
	//Will return the checked login of the user
	public static String checkForPassword(Statement st, Connection conn, boolean isAdmin, Scanner reader){
		while(true){
			print("Enter your login:");
			String login = reader.nextLine();
			print("Enter your password:");
			String password = reader.nextLine();
			String table;
			if(isAdmin){
				table = "administrator";
			}else{
				table = "customer";
			}
			try {
				//table login password
				statement = conn.prepareStatement("SELECT EXISTS(select * from " + table + " where login = ? and password = ?);");
				statement.setString(1, login);
				statement.setString(2, password); 
				ResultSet rs = statement.executeQuery();
				conn.commit();
				rs.next();
				if(rs.getString(1).equalsIgnoreCase("t")){
					return login;
				}
			} catch (SQLException e) {
				e.printStackTrace();
			}
			print("Incorrect Password Try Again");
		
		}
	}
    public static String input(Scanner reader) throws IOException {
    	String line="";
    	//while(line!=null&&line.length()>0) {
    		line = reader.nextLine().trim();
    	//}
    	return line;
    	
    }
    public static void print(String in) {
    	System.out.println(in);
    }
    public static void printChoices(boolean admin) {
    	if(admin) {
    		print("Administrator interface:");
			print("1: Erase the database");
			print("2: Add a customer");
			print("3: Add new mutual fund");
			print("4: Update share quotes for a day");
			print("5: Show top-k highest volume categories");
			print("6: Rank all the investors");
			print("7: Update the current date (i.e., the \"pseudo\" date)");
    	}else {
    		print("Customer interface:");
			print("1: Show the customer\'s balance and total number of shares");
			print("2: Show mutual funds sorted by name");
			print("3: Show mutual funds sorted by prices on a date");
			print("4: Search for a mutual fund");
			print("5: Deposit an amount for investment");
			print("6: Buy shares");
			print("7: Sell shares");
			print("8: Show ROI (return of investment)");
			print("9: Predict the gain or loss of the customer\'s transactions");
			print("10: Change allocation preference");
			print("11: Rank the customer\'s allocations");
			print("12: Show portfolio [proc]");
    	}
    	print("0: Exit");
    	print("Enter selection:");
    }
}
