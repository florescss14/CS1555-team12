
import java.sql.*;
import java.io.*;
import java.util.Properties;
import java.util.Scanner;

public class team23 {
    public static void main(String args[]) throws
        SQLException, ClassNotFoundException, IOException {
        Class.forName("org.postgresql.Driver");
        String url = "jdbc:postgresql://localhost:5432/";
        Properties props = new Properties();
        props.setProperty("user", "postgres");
        
        
        Scanner reader = new Scanner(System.in);
        
        //CHANGE PW (2nd arg)
        props.setProperty("password", "CHANGE_PASSWORD");
        
        Connection conn = DriverManager.getConnection(url, props);

        Statement st = conn.createStatement();
        
        boolean operatingFlag = true;
    	boolean isAdmin = askAboutAdmin(reader);

        try {
        	
            conn.setAutoCommit(false);
            st.executeUpdate("delete from RESERVATION_DETAIL");
			
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
    
    private static void interpretSelection(int in, boolean isAdmin, Statement st, Scanner reader, Connection conn) {
		if(isAdmin) {
			if(in==1) {
				eraseDatabase(st, conn);
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
		// TODO Auto-generated method stub
		
	}

	private static void rankInvestors(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		
	}

	private static void showCategories(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		
	}

	private static void updateQuote(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		
	}

	private static void addFund(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		
	}

	private static void addCustomer(Statement st, Connection conn, Scanner reader) {
		// TODO Auto-generated method stub
		
	}

	public static void eraseDatabase(Statement st, Connection conn){
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
    	}else {
    		print("Customer interface:");
    	}
    	print("0: Exit");
    	print("Enter selection:");
    }
}
