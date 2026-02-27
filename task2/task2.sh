#!/bin/sh

#This is the priority scheduling system
# High priority = 1 and low priority = 10

#confirming log file and storing in variable
LOGFILE="scheduler.log"
if [ ! -f "$LOGFILE" ]; then
    touch "$LOGFILE"
    echo "Log file created on script start" >> "$LOGFILE"
fi


#function to log actions with a timestamp and custom message
log_action(){
    #checks for log file and either creates a new one or appends existing
    if [ ! -f "$LOGFILE" ]; then
        touch "$LOGFILE"
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

#function that displays all pending jobs with information about job
View_Pend_Jobs(){
    #while loop that uses | as the IFS/deliminator for the file and stores the information into the variables that the files
    #tail -n +2 ensures the header of the file isnt displayed and only the information is read
    tail -n +2 pending_jobs.txt | while IFS='|' read -r S_id name estim_time priority
    do
        echo "ID: $S_id"
        echo "Name: $name"
        echo "Estimated Time: $estim_time"
        echo "Priority: $priority"
        echo "-----------------------------"
    done
    log_action "User viewed pending jobs"

}

#submit_job function allows user to input necessary information for a job and then does necessary checks before appending onto the pending_jobs.txt file
Submit_Job(){
    echo "Enter Student ID: "
    read student_id

    echo "Enter Job Name: "
    read job_name

    echo "Enter Estimated Execution Time: "
    read job_time

    echo "Enter Job Priority 1(high) - 10(low): "
    read job_priority

    #performs all necessary checks, running the check, then if check is true add job
    [ -z "$student_id" ] && echo "ID cannot be empty" && return
    [ -z "$job_name" ] && echo "Job name cannot be empty" && return
    [ -z "$job_time" ] && echo "Estimated time cannot be empty" && return
    [ -z "$job_priority" ] && echo "Priority cannot be empty" && return

    #another check to ensure that job time is correct and is a number
    case $job_time in
        ''|*[!0-9]*)
            echo "Error:Estimated Execution Time must be a number"
            return
            ;;
    esac

    #a check to see that job priority has been entered as a number too
    case $job_priority in
        ''|*[!0-9]*)
            echo "Error: Job Priority must be a number"
            return
            ;;
    esac

    #after passing all checks, appends job into pending jobs using the vertical bar deliminator to ensure it can be read properly by other functions
    echo "$student_id|$job_name|$job_time|$job_priority" >> pending_jobs.txt
    log_action "Job \'$job_name\' submitted by student ID: $student_id"
    echo "Job added successfully"

}    