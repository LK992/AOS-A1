#!/bin/sh

#assigns log file and then checks for existence and creates a file if not
LOGFILE="submission.log"
if [ ! -f "$LOGFILE" ]; then
    touch "$LOGFILE"
    log_action "Log file created on script start"
fi

#function to allow for easy logs to be created with timestamps
log_action(){
    #checks for log file and either creates a new one or appends existing
    if [ ! -f "$LOGFILE" ]; then
        touch "$LOGFILE"
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

#assigns valid_users.txt and locked_accounts.txt a variable for easy access
valid_users_file="valid_users.txt"
locked_accounts_file="locked_accounts.txt"

#function that checks if a specific file has already been submitted
check_submitted(){

    SUBMITTED="submissions/submitted"

    echo "Enter filename to check:"
    read filename

    #case statement ensures only filename is entered and not a path
    case "$filename" in
        */*)
            echo "Invalid Filename."
            return 1
            ;;
    esac

    #condition checks path created using hardcoded path and the filename and outputs appropriate message if true or false
    if [ -f "$SUBMITTED/$filename" ]; then
        echo "File has already been submitted."
        return 0
    else
        echo "File has NOT been submitted."
        return 1
    fi
}

#function to list all submissions within the submitted directory with their submitted timestamp
list_submissions(){

    SUBMITTED="submissions/submitted"

    echo "Submitted Assignments:"
    echo "----------------------"

    #for loop that removes unnecessary information and outputs file name and submission date
    for file in "$SUBMITTED"/*
    do
        [ -f "$file" ] || continue
        filename=$(basename "$file")
        date=$(ls -l "$file" | awk '{print $6, $7, $8}')
        echo "$filename - Submitted on: $date"
    done
}

#function that allows for submission of files while performing all checks to ensure compliance
submit_assignment(){
    #initialise variables and filepaths
    NOT_SUBMITTED="submissions/not_submitted"
    SUBMITTED="submissions/submitted"
    #outputs available files
    echo "Files available for submission:"
    echo "-------------------------------"
    ls "$NOT_SUBMITTED"
    echo ""

    echo "Enter filename exactly as shown:"
    read filename

    #concatenates filename and directory path
    filepath="$NOT_SUBMITTED/$filename"

    #check File Exists
    if [ ! -f "$filepath" ]; then
        echo "File does not exist."
        log_action "Submission failed: file not found ($filename)"
        return 1
    fi


    #validates Extension (.pdf or .docx)
    case "$filename" in
        *.pdf|*.docx)
            ;;
        *)
            echo "Invalid file type. Only PDF and DOCX allowed."
            log_action "Submission rejected (invalid type): $filename"
            return 1
            ;;
    esac


    #captures filesize using wc -c which counts bytes
    filesize=$(wc -c < "$filepath")

    #checks file size with max of 5MB
    if [ "$filesize" -gt 5242880 ]; then
        echo "File size exceeds 5MB limit."
        log_action "Submission rejected (file too large): $filename"
        return 1
    fi

    #checks for Duplicate Filename
    # -f checks if file already exists if so it rejects
    if [ -f "$SUBMITTED/$filename" ]; then
        echo "Duplicate filename detected."
        log_action "Submission rejected (duplicate filename): $filename"
        return 1
    fi

    #checks for Duplicate Content
    #creates checksum for the file which user wants to submit
    new_sum=$(cksum "$filepath" | awk '{print $1}')

    #for loop goes through all submissions within the submitted directory
    #creates checksums for each file and compares, if checksum is the same it is flagged as duplicate
    for existing in "$SUBMITTED"/*
    do
        [ -f "$existing" ] || continue #check if it is a regular file to ensure directories or invalid entries are not hashed

        existing_sum=$(cksum "$existing" | awk '{print $1}') #creates checksum for existing file

        if [ "$new_sum" -eq "$existing_sum" ]; then
            echo "Duplicate content detected."
            log_action "Submission rejected (duplicate content): $filename"
            return 1
        fi
    done


    #if all successful accepts submission

    #moves file to submitted directory
    mv "$filepath" "$SUBMITTED/"

    echo "Submission successful."
    log_action "Submission successful: $filename"

    return 0
}

#main_menu function simply produces a menu with the required case statement that allows for easy selection
main_menu(){
    while true
    do
        echo "--------------------------------------"
        echo "Main Menu"
        echo ""
        echo "1. Submit Assignment"
        echo "2. Check Submission"
        echo "3. List All submissions"
        echo "4. Bye"
        echo "--------------------------------------"
        read choice
        case $choice in
            1)
                submit_assignment
                ;;
            2)
                check_submitted
                ;;
            3)
                list_submissions
                ;;

            4|bye|Bye|BYE)
                echo "Are you sure you want to exit (Y/N)"
                read confirm

                if [ "$confirm" = "Y" ] || [ "$confirm" = "y" ]; then
                    echo "Bye"
                    exit
                fi
                ;;
            *)
                echo "Invalid Choice"
                ;;
        
        esac

        echo ""
    done
}

#login function simulates logging into the system as a student and performs checks and locks accounts based on too many entries
log_in(){
    #variable used to allow entry into system
    valid=0

    echo "Welcome to CCCU submission portal"

    #while loop continually runs until valid becomes 1
    while [ $valid -eq 0 ]
    do
        echo "Enter Username"
        read name

        echo "Enter Password"
        read -s pword

        #captures current time for use with the warning for repeated log ins within 60 seconds
        CURRENT_TIME=$(date +%s)

        # checks to see if username matches the a username within valid_users_file
        if ! grep -q "^${naame}$" "$valid_users_file"; then
            log_action "invalid username input attempt: $name"
            echo "Invalid username"
            continue
        fi

        #checks if account is locked first to stop log in on locked accounts
        if grep -q "^${name}$" "$locked_accounts_file" 2>/dev/null; then
            log_action "Locked account loging attempt: $name"
            echo "Account is locked"
            continue
        fi

        # Detect Repeated Attempts within 60 seconds
        #using awk to go through log files and capture when a log contains failed for the username and then takes the timestamp
        RECENT_ATTEMPTS=$(awk -v user="$name" -v now="$CURRENT_TIME" '
        {
            # Check if log contains username and failed login message using regex with ~ operator
            if ($0 ~ user && $0 ~ "failed") {
                
                #Reconstructs timestamp from log format.
                log_time_str = $1 " " $2
                
                #converts human readable time into unix timestamp for calculations
                cmd="date -d \"" logtime_str "\" +%s"
                #tells awk to execute the command and store result in logtime
                cmd | getline log_time
                #closes command to ensure there arent too many open processes
                close(cmd)
                
                #finally does comparison by checking if difference between unix timestamps are below 60
                if ((now - log_time) <= 60)
                    count++ # increments count
                fi
            }
        }
        END { print count } #prints count to recent_attempts which is used for comparison
        ' "$LOGFILE" 2>/dev/null) #tells code where to look for log file and suppresess errors for clean outputs

        #checks to see if recent_attempts is empty, if not checks if number is greater than 0
        if [ -n "$RECENT_ATTEMPTS" ] && [ "$RECENT_ATTEMPTS" -gt 0 ]; then
            #logs warning into the log file
            log_action "Repeated login attempt within 60 seconds for $name"
        fi


        # Password Validation using index of passwords in the passwords.list file
        # using grep captures line numbers for th entered username in valid users file
        LINE_NUM=$(grep -n "^${name}$" "$valid_users_file" | cut -d: -f1)

        #uses line number to find associated password
        STORED_PASS=$(sed -n "${LINE_NUM}p" "passwords.list" 2>/dev/null)

        #checks if passwords match
        if [ "$pword" = "$STORED_PASS" ]; then
            #changes valid to 1 and logs action before breaking loop
            valid=1
            log_action "Student $name successfully logged in"

            break
        
        else

            #otherwise logs a failed attempt
            log_action "log in attempt failed with credentials $name"

            #counts the amount of failures from the log file using grep -c and string matching from the logs
            FAIL_COUNT=$(grep -c "log in attempt failed with credentials $name" "$LOGFILE")

            #checks how many failed logs there are
            if [ "$FAIL_COUNT" -ge 3 ]; then
                #if equal or greater than 3 then the account is moved to the locked accounts file
                echo "$name" >> "$locked_accounts_file"
                #a log is created
                log_action "Account locked after 3 failed attempts: $name"
                #tells user the account if locked
                echo "Account locked"
            else
                #shows user message for a failed entry into system
                echo "Incorrect credentials try again"
            fi

        fi

        echo ""
        echo ""
    done

    #if all checks are passed and while is broken then notify user and then call main_menu function
    echo "Logging you in..."
    sleep 2
    main_menu
}

#call to log in function to start program
log_in