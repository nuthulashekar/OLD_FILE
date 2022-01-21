#!/bin/bash
# Uncomment line below for debugging
#set -xv
delete_oldest(){
     # reads a line from stdin, extracts file inode number
     # and deletes file to which inode belongs
     # !!! VERY IMPORTANT !!!
     # The actual command to delete file is commented out.
     # Once you verify correct execution, feel free to remove
     # leading # to uncomment it
     read timestamp file_inode
     find "$directory" -type f -inum "$file_inode"  -printf "Deleted %f\n" 
     # find "$directory" -type f -inum "$file_inode"  -printf "Deleted %f\n"  -delete
}

get_files(){
    # Wrapper function around get files. Ensures we're working
    # with files and only on one specific level of directory tree
    find "$directory" -maxdepth 1 -type f  -printf "%Ts\t%i\n" 
}

filecount_above_limit(){
    # This function counts number of files obtained
    # by get_files function. Returns true if file
    # count is greater than what user specified as max
    # value 
    num_files=$(wc -l <<< "$file_inodes"  )
    if [ $num_files -gt "$max_files" ];
    then
        return 0
    else
        return 1
    fi
}

exit_error(){
    # Print error string and quit
    printf ">>> Error: %s\n"  "$1" > /dev/stderr 
    exit 1
}

main(){
    # Entry point of the program. 
    local directory=$2
    local max_files=$1

    # If directory is not given
    if [ "x$directory" == "x"  ]; then
        directory="."
    fi

    # check arguments for errors
    [ $# -lt 1  ] && exit_error "Must at least have max number of files"
    printf "%d" $max_files &>/dev/null || exit_error "Argument 1 not numeric"
    readlink -e "$directory" || exit_error "Argument 2, path doesn't exist"

    # This is where actual work is being done
    # We traverse directory once, store files into variable.
    # If number of lines (representing file count) in that variable
    # is above max value, we sort numerically the inodes and pass them
    # to delete_oldest, which removes topmost entry from the sorted list
    # of lines.
    local file_inodes=$(get_files)
    if filecount_above_limit 
    then
        printf  "@@@ File count in %s is above %d." "$directory" $max_files
        printf "Will delete oldest\n"
        sort -k1 -n <<< "$file_inodes" | delete_oldest
    else
        printf "@@@ File count in %s is below %d."  "$directory" $max_files
        printf "Exiting normally"
    fi
}

