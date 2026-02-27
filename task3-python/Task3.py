#importing all necessary libraries for code to work
import os #allows for seeing files and reading / writing
import shutil #allows for moving files
import zlib #allows for hashing, used for checking duplicate content
from datetime import datetime, timedelta # used in timestamps and log ins within 60 seconds

#defines all files and paths into variables for easy implementation
log_file = "submisions.log"
user_file = "valid_users.txt"
passwords_file = "passwords.txt"
not_submitted_dir = "submissions/not_submitted"
submitted_dir = "submissions/submitted"

#creates dictionaries for failed attempts locked account and the timestamps for last attempts
failed_attempts = {}
locked_accounts = {}
last_attempt_time = {}

#function to create logs using timestamps and custom message
def log_action(message):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(log_file, "a") as log:
        log.write(f"{timestamp} {message}\n")

#function to load userdata for use in larger functions
def load_userdata(file):
    with open(file, "r") as f:
        return [line.strip() for line in f]

#function that specifically checks the password
def check_password(username, password):
    #loads in both users and passwords
    users = load_userdata(user_file)
    passwords = load_userdata(passwords_file)

    #checks for username existence then checks if password matches the password in the file associated with username
    if username in users:
        index = users.index(username)
        return passwords[index] == password
    
    return False

#function for simulating log in while doing all checks and locking accounts and warning for repeated attempts within 60 seconds
def login():
    #valid set to false to ensure while loop continues
    valid = False
    #debugging line below due to error with not finding files
    #print("Current working directory:", os.getcwd())

    #starts log in system to user
    print("Welcome to CCCU submission portal")

    while valid == False:
        #.strip() is used to remove leading and trailing whitespace (stops code from assuming wrong password due to whitespace)
        username = input("Enter Username: ").strip()
        password = input("Enter Password: ").strip()

        #captures current time using datetime library
        current_time = datetime.now()

        #loads user data
        users = load_userdata(user_file)

        #checks to see if username exists
        if username not in users:
            print("Invalid Username.")
            log_action(f"Invalid log in attempt (unknown user): {username}")
            continue #allows loops to continue
        
        #checks if username is in the locked accounts dictionary
        if username in locked_accounts:
            print("Account is locked.")
            log_action(f"Login attempt on locked account: {username}")
            continue
        
        #checks to see if username is in last attemp dict, if yes compares the times using timedelta of 60 seconds, if true generates warning in log file
        if username in last_attempt_time:
            if current_time - last_attempt_time[username] < timedelta(seconds=60):
                log_action(f"Repeated login attempt within 60 seconds: {username}")

        #creates/overwrites an entry for the username with the current time for log in attempt
        last_attempt_time[username] = current_time

        #checks password using check_password function
        if check_password(username, password):
            print("Login Successful.")
            log_action(f"Login Successful: {username}")
            failed_attempts[username] = 0 #sets attempts to 0
            valid = True #stops while loop
            continue #skips rest of code inside the loop
        else:
            #otherwise notify user of wrong password and log
            print("Incorrect password.")
            log_action(f"Failed login attempt: {username}")

            #increase count in failed_attempts dict
            failed_attempts[username] = failed_attempts.get(username, 0) + 1

            #checks failed attempts dict to see if it is more than or equal to 3, if true locks account with the locked accounts dict being set to true for the specific username
            if failed_attempts[username] >= 3:
                locked_accounts[username] = True
                print("Account locked due to 3 failed attempts.")
                log_action(f"Account locked: {username}")

    #if all checks pass and while loop is stopped calls main() for the user to see the menu
    print("Logging you in...")
    main_menu()

#calculates checksum of given filepath to be used when checking content
def calculate_checksum(filepath):
    checksum = 0
    with open(filepath, "rb") as f: #opens file as binary for checksum
        #keeps calling function until f.read returns an empty byte as seen with b""
        for chunk in iter(lambda: f.read(4096), b""): #reads file in chunks of 4096 bytes which are common memory page sizes
            checksum = zlib.crc32(chunk, checksum) #updates checksum value with checksum of current chunk
    return checksum # returns the checksum for comparison

#allows for submission while doing necessary checks for compliance
def submit_assignment():
    #prints available files for submission for easy usability
    print("Files available for submission:")
    print("-------------------------------")
    for file in os.listdir(not_submitted_dir):
        path = os.path.join(not_submitted_dir, file)
        if os.path.isfile(path):
            size = os.path.getsize(path)
            print(f"{file} | {size} bytes")
    
    #takes user input ensuring they know to enter the filename as shown in the text they see above this message
    filename = input("Enter Filename exactly as shown: ")
    #creates filepath as python works with filepaths and not just filenames
    filepath = os.path.join(not_submitted_dir, filename)

    #checks if file exists and logs failure if necessary
    if not os.path.isfile(filepath):
        print("File not found.")
        log_action(f"Submission failed: file not found ({filename})")
        return
    
    #checks filetype using .endswith and outputs correct error message
    if not filename.endswith(".pdf") or filename.endswith(".docx"):
        print("Invalid File type. Only PDF and DOCX allowed.")
        log_action(f"Submission rejected (invalid type): {filename}")
        return
    
    #checks file size (max 5MB) using .getsize from os
    if os.path.getsize(filepath) > 5242880:
        print("File exceeds 5MB limit")
        log_action(f"Submission rejected (file too large): {filename}")
        return
    
    #checks for duplicate filename using os .exists on the submitted directory
    #creates filepath for submitted directory
    submitted_path = os.path.join(submitted_dir, filename)
    if os.path.exists(submitted_path):
        #if the path already exists then reject submission
        print("Duplicate filename detected")
        log_action(f"Submission rejected (duplicate filename): {filename}")
        return
    
    #creates a checksum for the file which is wanted to be submitted
    new_checksum = calculate_checksum(filepath)

    #for loop that checks existing files within submitted directory and creates the file paths
    #after file paths are created it creates a checksum for existing file and then compares
    for existing in os.listdir(submitted_dir):
        existing_path = os.path.join(submitted_dir, existing)

        if os.path.isfile(existing_path):
            if calculate_checksum(existing_path) == new_checksum:
                #rejects submission is checksum matches
                print("Duplicate content detected")
                log_action(f"Submission rejected (duplicate cotent): {filename}")
                return
            
    #all conditions have been met therefore move current filepath to new submitted filepath and log
    shutil.move(filepath, submitted_path)
    print("Submission successful")
    log_action(f"Submission successful: {filename}")


#function to list all submissions within submitted directory
def list_submissions():
    print("Submitted Assignments:")
    print("----------------------")

    #loops through all files in submitted directory and outputs the file and its size in bytes
    for file in os.listdir(submitted_dir):
        path = os.path.join(submitted_dir, file)
        #checks if file is a file and then captures size and finally outputs
        if os.path.isfile(path):
            size = os.path.getsize(path)
            print(f"{file} | {size} bytes")

#function to check a specific submission
def check_submission():
    filename = input("Enter filename to check: ").strip()

    path = os.path.join(submitted_dir, filename)
    #checks if a file exists and outputs its already submitted
    if os.path.exists(path):
        print("File already submitted")
    else:
        #else output not submitted
        print("File has Not been submitted")

#main_menu function for menu selection system
def main_menu():
    while True:
        print("Main Menu\n\n")
        print("1. Submit Assignment")
        print("2. Check Submission")
        print("3. List Submissions")
        print("4. Exit")

        choice = input("Select Option: ")
        if choice == "1":
            submit_assignment()
        elif choice == "2":
            check_submission()
        elif choice == "3":
            list_submissions()
        #allowing choice to be 4 or bye using casefold to ignore the case of the bye message
        elif choice == "4" or choice.casefold() == "bye":
            confirm = input("Are you sure you wish to exit (Y/N): ")
            #again using casefold to ignore case on user input
            if confirm.casefold() == "y":
                print("Goodbye")
                break
        else:
            print("Invalid option")

#function call to start program
login()