import java.sql.*;
import java.util.Scanner;
import java.util.ArrayList;

public class App {
	//STATIC VARIABLES MUST BE CHANGED ACCORDING TO THE USER
	//SINCE THE APP IS USING LOCALHOST, OTHERWISE THE APP WON'T WORK!!!.

	public static final String URL = "jdbc:postgresql://localhost:5432/newbase001";
	public static final String USERNAME = "postgres";
    public static final String PASSWORD = "12345";
	private static Connection connection;

	public static void main(String[] args) throws SQLException {
		connect();
	    Scanner input = new Scanner(System.in);

	    while (true) {
	    	
	        printMenu();     
	        int choice = input.nextInt();

            switch (choice) {
                case 1:                
                    getStudentGrade();
                    break;
                case 2:
                	updateStudentGrade();
                    break;
                case 3:
                    searchPerson();
                    break;
                case 4:
                	getStudentFinalGrades();
                    break;
                case 5:
                    System.out.println("Exiting...");
                    disconnect();
                    return;
                default:
                    System.out.println("Invalid choice. Please try again.");
                    break;
            }
	    }
	}

	public static void printMenu() {
		System.out.println("\n\n----------- Menu --------------");
		System.out.println("| 1. Show grade of student.   |");
		System.out.println("| 2. Update grade of student. |");
		System.out.println("| 3. Search in 'Person'.      |");
		System.out.println("| 4. Show detailed grading.   |");
		System.out.println("| 5. Exit.                    |");
		System.out.println("-------------------------------");
		System.out.println("Enter option: ");
	}
	
	public static void connect() {   
        try {
            App.connection = DriverManager.getConnection(URL, USERNAME, PASSWORD);

            if (connection != null) {
                System.out.println("Connection established!");
                System.out.println("Proceeding with the program...");           
            } else {
                System.out.println("Connection failed!");
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
	
	public static void disconnect() {
        if (connection != null) {
            try {
                connection.close();
                System.out.println("Disconnected from the database.");
            } catch (SQLException e) {
                System.err.println("Error occurred while disconnecting from the database: " + e.getMessage());
            }
        }
    }
		
	public static void getStudentGrade() throws SQLException {
        Scanner scan1 = new Scanner(System.in);
        String stram;
        String strcourse;

        System.out.println("Enter Student's AM:");
        stram = scan1.nextLine();
        System.out.println("Enter Course Code");
        strcourse = scan1.nextLine();

        String query = "SELECT r.final_grade\r\n"
        		+ "FROM \"Register\" r\r\n"
        		+ "JOIN \"Student\" s ON s.amka = r.amka\r\n"
        		+ "WHERE s.am = '"+stram+"'\r\n"
        		+ "  AND r.course_code = '"+strcourse+"';";

        try (Statement statement = connection.createStatement();
             ResultSet resultSet = statement.executeQuery(query)) {

            // Print the final grade
            if (resultSet.next()) {
                double finalGrade = resultSet.getDouble("final_grade");
                System.out.println("\nFinal Grade: " + finalGrade + " for Student: " + stram);
            } else {
                System.out.println("No grade found for the specified student and course.");
            }
        }   
    }
	
	public static void updateStudentGrade() throws SQLException {
		Scanner scan = new Scanner(System.in);
		
		String studentAm; // Replace with the student's am
	    String courseCode; // Replace with the course code
	    int serialNumber; // Replace with the serial number
	    double newFinalGrade; // Replace with the new final grade
	    
	    System.out.println("Enter Student's AM: ");
	    studentAm = scan.nextLine();

	    System.out.println("Enter Course Code: ");
	    courseCode = scan.nextLine();
	    
	    System.out.println("Enter Serial Number: ");
	    serialNumber = scan.nextInt();
	    
	    System.out.println("Enter new grade: ");
	    newFinalGrade = scan.nextDouble();
		
		
		String query = "UPDATE \"Register\"\r\n"
				+ "SET final_grade = "+ newFinalGrade +"\r\n"
				+ "FROM \"Student\"\r\n"
				+ "WHERE \"Register\".amka = \"Student\".amka\r\n"
				+ "  AND \"Student\".am = '"+ studentAm +"'\r\n"
				+ "  AND \"Register\".course_code = '"+ courseCode +"'\r\n"
				+ "  AND \"Register\".serial_number = "+ serialNumber +";";
		
		PreparedStatement statement = connection.prepareStatement(query);
		
        int rowsAffected = statement.executeUpdate();
        System.out.println("Rows affected: " + rowsAffected);
	}
	
	public static void searchPerson() throws SQLException {
		ArrayList<String> list = new ArrayList<String>();
		
		Scanner scan = new Scanner(System.in);
        String stram;
        
        System.out.print("Enter initials: ");
        stram= scan.nextLine();
		
		String query = "SELECT p.*\r\n"
				+ "FROM \"Person\" p\r\n"
				+ "LEFT JOIN \"Student\" s ON p.amka = s.amka\r\n"
				+ "LEFT JOIN \"Professor\" prof ON p.amka = prof.amka\r\n"
				+ "LEFT JOIN \"LabTeacher\" lt ON p.amka = lt.amka\r\n"
				+ "WHERE p.surname LIKE '"+stram+"%' AND (s.amka IS NOT NULL OR prof.amka IS NOT NULL OR lt.amka IS NOT NULL)\r\n"
				+ "ORDER BY p.surname ASC;";
		
		try (Statement statement = connection.createStatement();
	         ResultSet resultSet = statement.executeQuery(query)) {
					           
	            while(resultSet.next()) {
	            	String amka = resultSet.getString("AMKA");
	            	String sname = resultSet.getString("surname");
	            	String name = resultSet.getString("name");
	            	
	            	list.add("AMKA: " + amka + " " + sname + " " + name);
	              //System.out.println("\n"+"AMKA: " + amka + " " + sname + " " + name);
	            }
	    }  
		
		System.out.println("People found matching initials: " + list.size()+"\n");
        
		if(list.size()==0) {
		    System.out.println("Nothing found!");    
		    return;    
		}
		    
		int pageSize = 5;
		int totalPages = (int) Math.ceil((double) list.size() / pageSize);

		int currentPage = 1;
		boolean exit = false;

		while (!exit) {
		    System.out.println("Page " + currentPage + ":");
		    int startIndex = (currentPage - 1) * pageSize;
		    int endIndex = Math.min(startIndex + pageSize, list.size());

		    for (int i = startIndex; i < endIndex; i++) {
		        System.out.println(list.get(i));
		    }

		    System.out.println("\nSelect an option:");
		    System.out.println("1. Select a specific page");
		    System.out.println("2. Go to the next page");
		    System.out.println("3. Exit");

		    System.out.print("Enter your choice: ");
		    int choice = scan.nextInt();

		     switch (choice) {
		          case 1:
		                    System.out.print("\nEnter the page number (1-" + totalPages + "): ");
		                    int pageNumber = scan.nextInt();
		                    if (pageNumber >= 1 && pageNumber <= totalPages) {
		                        currentPage = pageNumber;
		                    } else {
		                        System.out.println("\nInvalid page number. Please try again.");
		                    }
		                    break;
		          case 2:
		                    if (currentPage < totalPages) {
		                        currentPage++;
		                    } else {
		                        System.out.println("\nAlready on the last page!");
		                    }
		                    break;
		          case 3:
		                    System.out.println("\nExiting...");
		                    exit = true;
		                    break;
		          default:
		                    System.out.println("\nInvalid choice. Please try again.");
		                    break;
		            }
		        System.out.println();
		    }
	}
	
	public static void getStudentFinalGrades() {
		Scanner scan = new Scanner(System.in);
		String studentAm;
		
		System.out.println("Enter Student's AM: ");
		studentAm = scan.nextLine();
		
		String query = "SELECT r.course_code, r.final_grade " +
                "FROM \"Student\" s " +
                "JOIN \"Register\" r ON s.amka = r.amka " +
                "JOIN \"CourseRun\" cr ON r.serial_number = cr.serial_number " +
                "JOIN \"Semester\" sem ON cr.semesterrunsin = sem.semester_id " +
                "WHERE s.am = ? AND r.course_code = cr.course_code " +
                "ORDER BY sem.semester_id ASC";

        try (PreparedStatement statement = connection.prepareStatement(query)) {
            statement.setString(1, studentAm);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    String courseCode = resultSet.getString("course_code");
                    double finalGrade = resultSet.getDouble("final_grade");
                    System.out.println("\n" +courseCode + ", Final Grade: " + finalGrade);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
