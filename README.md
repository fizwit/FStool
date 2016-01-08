### FStool ###

    FStool is a suite of tools for collecting and reporting 
    on file system meta data. File system information is based on files. File based 
    tools offer more fine grained information that tools for working on 
    file system volumes. fsdata has three major componets. Collection process, 
    Database import and Reporting scripts. This repoistiroy are the import and Reporting
    Tools.
    
    Collection process is performed by a program called pwalk. pwalk takes
    file system volume names as input. The output of pwalk is a complete
    inode data from every file in the file system volume. Output of pwalk
    is CSV formated flat files. A load script needs to be run after each 
    walk to load the data into a MySQL DB.

### Author ####
John Dey john@fuzzdog.com
