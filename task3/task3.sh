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