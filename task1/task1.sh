#!/bin/sh

#the log action function allows for easy logs to be created with a timestamp and a custom message
log_action(){
    #Checks for log file and either creates a new one or appends existing
    if [ ! -f "$LOGFILE" ]; then
        touch "$LOGFILE"
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

#code below defines the logfile variable as the file system_monitor.log
#it only makes a new file if it doesn't detect a file with the same filename in the directory that this code sits
LOGFILE="system_monitor.log"
if [ ! -f "$LOGFILE" ]; then
    touch "$LOGFILE"
    log_action "Log File created on script start"
fi

#basic function that reads the current active log file in the directory of the code
Read_Log(){
    if [ ! -f "$LOGFILE" ]; then
        touch "$LOGFILE"
        echo "No log file found"
        log_action "Log file missing - created new log file"
        return
    fi

    echo "------ Current Log File ------"
    cat "$LOGFILE"
    echo "------------------------------"

    log_action "User Viewed the log file"

}

#display_CPUMEM shows the top ten processes for both CPU usage and memory giving two different lists
Display_CPUMEM(){
    echo "Processes by CPU Usage:"
    #using ps -eo is used to get a more readable output by only showing the necessary information which is CPU and Mem usages, it also allows for the sorting by usage
    ps -eo pid,user,%cpu,%mem --sort=-%cpu | head -n 11
    echo "Processes by Memory Usage:"
    ps -eo pid,user,%cpu,%mem --sort=-%mem | head -n 11
    #ps - eo is used to only show the selected attributes such as PID, user and the cpu and mem usage
    log_action "Displayed CPU and Memory Usage"
}

kill_process(){
    echo "Enter PID of process you wish to terminate"
    read pid

    log_action "User attempted to terminate PID $pid"

    echo "Are you sure you want to terminate PID: $pid (Y/N) "
    read confirm

    #first condition is to confirm user wants to kill process
    if [ "$confirm" != "Y" ] && [ "$confirm" != "y" ]; then
        echo "Termination Cancelled."
        log_action "Termination of PID: $pid cancelled by user"
        return
    fi

    #second condition is to check if the process is actually the running script
    if [ "$pid" -eq "$$" ]; then
        echo "Error: Cannot terminate Management System script itself"
        echo "Please use BYE command on Main Menu to terminate this program"
        log_action "KILL BLOCKED: PID $pid was script"
        return
    fi

    #third condition is to check that the process is not a kernel thread
    KNT=$(ps -p "$pid" -o comm=)
    if [[ "$KNT" =~ ^\[.*\]$ ]]; then
        echo "Error: Kernal Threads/Processes cannot be terminated"
        log_action "KILL BLOCKED: PID $pid was critical Kernel process/thread"
        return
    fi

    #fourth condition is to ensure PID isnt 1 as this is a system process that will cause a crash
    if [ "$pid" -eq 1 ]; then
        echo "Error: PID 1 is a critical system process that cannot be terminated"
        log_action "KILL_BLOCKED: PID $pid is critical system process and cannot be terminated without crashing system"
        return
    fi

    #fifth condition checks if the process is for the shell in which the code is running
    shell_pid=$(ps -p $$ -o ppid=)
    if [ "$pid" -eq "$shell_pid" ]; then
        echo "Error: Cannot terminate shell."
        log_action "KILL_BLOCKED: cannot terminate shell"
        return
    fi

    #finally kills command
    kill "$pid" 2>/dev/null
    #checks if command is successfully killed using the 0 (success) or 1 (fail) output from kill command
    if [ $? -eq 0 ]; then
        echo "Process $pid terminated successfully."
        log_action "Process $pid was terminated succesfully"
    else
        echo "Failed to terminate process $pid"
        log_action "Process $pid failed to terminate due to kill command protection"
    fi

    return
}

#disk inspect performs all actions in relation to directorys and content and outputs key information about the desired directory
Disk_Inspect(){
    echo "Enter Directory for inspection:"
    read dir

    #checks to see if entered directory exists
    if [ ! -d "$dir" ]; then
        echo "Error: Directory not found."
        log_action "Directory not found: $dir"
        return
    fi
    log_action "User attempted to inspect directory: $dir"

    #shows the size of the directory in a human readable format
    du -sh "$dir"

    large_logs=$(find "$dir" -type f -name "*.log" -size +50M)

    if [ -z "$large_logs" ]; then
        echo "No log files larger than 50MB found."
        log_action "No large log files found in $dir"
    else
        echo "$large_logs"
        log_action "large log files detected in $dir"
    fi

    if [ ! -d ArchiveLogs ]; then
        mkdir ArchiveLogs
        log_action "Directory ArchiveLogs created"
    fi

    echo "Do you wish to Archive Large Log Files? (Y/N)"
    read confirm
    #confirms if user wants to archive any large logs
    if [ "$confirm" != "Y" ] && [ "$confirm" != "y" ]; then
        log_action "User cancels archiving"
        return
    fi
    log_action "User archived large log files"

    #for loop to move compress large log files and move to the archive while maintaining a timestamp that concatenates on the file name
    for file in $(find "$dir" -type f -name "*.log" -size +50M); do
        timestamp=$(date +"%Y%m%d_%H%M%S")
        gzip -c "$file" > "ArchiveLogs/$(basename "$file")_$timestamp.gz"
        log_action "$file archived to ArchiveLogs"
    done

    #gets size of archive logs directory
    archive_size=$(du -s ArchiveLogs | awk '{print $1}')

    #based on conditions gives warning about size of directory
    if [ "$archive_size" -gt 1000000 ]; then
        echo "WARNING: Archivelogs directory exceeds 1GB"
        log_action "ArchiveLogs exceeded 1GB (size: ${archive_size}KB)"
    else
        log_action "ArchiveLogs size OK (size: ${archive_size}KB)"
    fi

}

while true
do
    echo "--------------------------------------------------------"
    echo "Main Menu"
    echo ""
    echo ""
    echo "1. Display top ten processes by CPU and Memory usage"
    echo "2. Inspect a directory and archive"
    echo "3. Terminate a process"
    echo "4. Check logs"
    echo "5. Bye"
    echo "--------------------------------------------------------"
    read choice
    #case statement to determine choice and to control incorrect/invalid inputs
    case $choice in
        1)
            log_action "User Selected: Display CPU/MEM"
            Display_CPUMEM
            ;;
        2)
            log_action "User Selected: Disk Inspection"
            Disk_Inspect
            ;;
        3)
            log_action "User Selected: Terminate Process"
            kill_process
            ;;
        4)
            log_action "User Selected: View Log File"
            Read_Log
            ;;
        5|bye|Bye|BYE)
            echo "Are you sure you want to exit (Y/N)"
            read confirm
            #confirmation of closing program
            if [ "$confirm" = "Y" ] || [ "$confirm" = "y" ]; then
                log_action "User exited script via Bye command"
                echo "Bye"
                exit
            else
                log_action "User Cancelled exit"
            fi
            ;;
        *)
            echo "Invalid Choice"
            log_action "Invalid menu choice: $choice"
            ;;
    esac
done

