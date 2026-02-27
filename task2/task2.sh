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

#function to simulate priority scheduling based on the jobs inside pending_jobs.txt
Process_Queue(){
    scheduled_jobs_file=$(mktemp) #creates a temporary file to store the sorted jobs
    tail -n +2 pending_jobs.txt | sort -t '|' -k4 -n > "$scheduled_jobs_file" #sorts job by priority, -k4 is looking at column 4 for priority which is where the sort function works

    echo "Executing jobs by priority..."
    echo "------------------------------"

    #while loop for "running" jobs reading all job information
    while IFS='|' read -r S_id name estim_time priority
    do
        #outputs "currently running job"
        echo "Running job: $name for Student: $S_id"
        echo "Priority: $priority"
        echo "Estimated time: $estim_time"
        echo "------------------------------"
        sleep "$estim_time" #sleeps for the estimated time to simulate the job running

        #copies job to completed jobs.txt
        echo "$S_id|$name|$estim_time|$priority" >> completed_jobs.txt
        #assigns job and information into line variable
        line="$S_id|$name|$estim_time|$priority"

        #this command block, moves all existing not run jobs into a file called temp.txt and recreates the header

        {
            echo "S_id|name|estim_time|priority"

            tail -n +2 pending_jobs.txt | grep -v -F "$line" #header is recreated because we skip the header from being read in pending_jobs.txt here

        } > temp.txt #this temp.txt now has all jobs except the one just processed with the header

        mv temp.txt pending_jobs.txt #now pending_jobs gets overwritten with the informaiton from temp.txt

        log_action "Job: $S_id $name $priority executed using Priority Scheduling"

    done < "$scheduled_jobs_file" #feeds the sorted job list into the while loop
    #removes the temporary file used to store the sorted jobs
    rm "$scheduled_jobs_file"

    #<(printf "%s\n" "$scheduled_jobs") converts sorted job list intoa line by line stream for the while loop
    #a problem arose here originally the while had code < pending_jobs.txt however that broke due to the code changing the file previously,
    #this then led to the ccode reading the old file description and not moving the files correctly over to completed_jobs because the loop exits early
    #for the next job in the sequence, this printf line fixed all them problems.
    echo "All jobs completed."

}

#basic function that outputs all completed jobs within completed_jobs.txt, ignoring the header.
View_Comp_Jobs(){
    tail -n +2 completed_jobs.txt | while IFS='|' read -r S_id name estim_time priority
    do
        echo "ID: $S_id"
        echo "Name: $name"
        echo "Time: $estim_time"
        echo "Priority: $priority"
        echo "-----------------------------"
    done
}

#a basic while loop menu system which allows for easy navigation using a case statement
# and confirms if user wants to exit the system.
while true
do
    echo "--------------------------------------------------------"
    echo "Main Menu"
    echo ""
    echo "1. View Pending Jobs"
    echo "2. Submit Job Request"
    echo "3. Process Jobs Queue"
    echo "4. View Completed Jobs"
    echo "5. Bye"
    echo "--------------------------------------------------------"
    read choice
    #case statement handles invalid inputs and confirming if user wants to exit
    case $choice in
        1)
            View_Pend_Jobs
            ;;
        2)
            Submit_Job
            ;;
        3)
            Process_Queue
            ;;
        4)
            View_Comp_Jobs
            ;;
        5|bye|Bye|BYE)
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
