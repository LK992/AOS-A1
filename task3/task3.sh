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