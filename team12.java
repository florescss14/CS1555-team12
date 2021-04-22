
import java.sql.*;
import java.io.*;
import java.util.ArrayList;
import java.util.Properties;
import java.util.Scanner;

public class team12 {
    public static void main(String args[]) throws
        SQLException, ClassNotFoundException, IOException {
        Class.forName("org.postgresql.Driver");
        String url = "jdbc:postgresql://localhost:5432/";
        Properties props = new Properties();
        props.setProperty("user", "postgres");
        
        
        Scanner reader = new Scanner(System.in);
        
        //CHANGE PW (2nd arg)
        props.setProperty("password", "pass");
        
        Connection conn = DriverManager.getConnection(url, props);

        Statement st = conn.createStatement();
        boolean operatingFlag = true;
    	boolean isAdmin = askAboutAdmin(reader);

        try {
			conn.setAutoCommit(false);
        	//Not exactly sure what this does but it was stopping the code
            //st.executeUpdate("delete from RESERVATION_DETAIL");
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
		// TODO Auto-generated method stub
		
	}

	private static void showROI(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		
	}

	private static void sellShares(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		
	}

	private static void buyShares(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		
	}

	private static void depositAmount(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		
	}

	private static void searchForFund(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		
	}

	private static void showFundsByPrice(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		
	}

	private static void showFundsByName(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		
	}

	private static void showCustomer(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		
	}

	private static void updateTimestamp(Statement st, Connection conn, Scanner reader) {
		print("Enter date to update date to (DD-MM-YYYY):");
		String date = reader.nextLine();
		try {
			st.executeUpdate("CALL set_current_date(TO_DATE(\'" + date + "\', \'DD-MM-YYYY\'));");
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
			ResultSet res = st.executeQuery("SELECT * From show_k_highest_volume_categories("+ k +");");
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
			st.executeUpdate("call new_mutual_fund(\'" + symbol + "\', \'" + name + "\', \'"+ description +"\', \'"+ category +"\', TO_DATE(\'"+ c_date +"\', \'DD-MON-YY\'));");
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
		if(values.length == 5){
            balance = values[4];
        }else{
            balance = "null";
        }
		
		
		try {
			st.executeUpdate("call add_customer(\'" + login + "\', \'" + name + "\', \'" + email + "\', \'null\', \'"+ password +"\', "+ balance +");");
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
			print("1: Show the customer’s balance and total number of shares");
			print("2: Show mutual funds sorted by name");
			print("3: Show mutual funds sorted by prices on a date");
			print("4: Search for a mutual fund");
			print("5: Deposit an amount for investment");
			print("6: Buy shares");
			print("7: Sell shares");
			print("8: Show ROI (return of investment)");
			print("9: Predict the gain or loss of the customer’s transactions");
			print("10: Change allocation preference");
			print("11: Rank the customer’s allocations");
			print("12: Show portfolio [proc]");
    	}
    	print("0: Exit");
    	print("Enter selection:");
    }
}
