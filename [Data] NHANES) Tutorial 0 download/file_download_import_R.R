#################################################################################################
# Example code to download/import NHANES data files (SAS transport .XPT files) as a dataset     #
# For R                                                                                         #
#################################################################################################
  
## Note to tutorial users: you must update some lines of code (e.g. file paths) 
##  to run this code yourself. Search for comments labeled "TutorialUser"

# Include Foreign Package To Read SAS Transport Files
library(foreign)

###########################################################################
## Example 1: import SAS transport file that is saved on your hard drive ##
###########################################################################
  
# First, download the NHANES 2015-2016 Demographics file and save it to your hard drive #
# from: https://wwwn.cdc.gov/nchs/nhanes/search/datapage.aspx?Component=Demographics&CycleBeginYear=2015 #
# You may need to right-click the link to the data file and select "Save target as..." #
    
# Create data frame from saved XPT file
# TutorialUser: update the file path here
# for Windows users, be sure to change the slashes between directories to a forward slash / (as on Mac or Unix) 
#  or to double backslashes \\

DEMO_I <- read.xport("C:\\NHANES\\DATA\\DEMO_I.xpt")
DEMO_I2 <- read.xport("C:/NHANES/DATA/DEMO_I.xpt")

# this code with typical Windows single backslashes between directories will throw an error
#DEMO_I <- read.xport("C:\NHANES\DATA\DEMO_I.xpt")

# save as an R data frame
# TutorialUser: update the file path here to a directory where you want to save the data frame 
saveRDS(DEMO_I, file="C:\\NHANES\\DATA\\DEMO_I.rds")


############################################################################
## Example 2: Download and import the transport file through R             #
############################################################################

# Download NHANES 2015-2016 to temporary file    
download.file("https://wwwn.cdc.gov/nchs/nhanes/2015-2016/DEMO_I.XPT", tf <- tempfile(), mode="wb")

# Create Data Frame From Temporary File
DEMO_I3 <- foreign::read.xport(tf)
    
# save as an R data frame
# TutorialUser: update the file path here to a directory where you want to save the data frame 
saveRDS(DEMO_I3, file="C:\\NHANES\\DATA\\DEMO_I.rds")    
    
    
