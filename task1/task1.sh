#!/bin/sh

#code below defines the logfile variable as the file system_monitor.log
#it only makes a new file if it doesn't detect a file with the same filename in the directory that this code sits
LOGFILE="system_monitor.log"
if [ ! -f "$LOGFILE" ]; then
    touch "$LOGFILE"
    log_action "Log File created on script start"
fi

#the log action function allows for easy logs to be created with a timestamp and a custom message
log_action(){
    #Checks for log file and either creates a new one or appends existing
    if [ ! -f "$LOGFILE" ]; then
        touch "$LOGFILE"
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

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

