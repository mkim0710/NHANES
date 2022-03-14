*************************************************************************************************
* Example code to download/import NHANES data files (SAS transport .XPT files) as a dataset     *
* For Stata                                                                                     *
*************************************************************************************************

** Note to tutorial users: you must update some lines of code (e.g. file paths) 
**    to run this code yourself. Search for comments labeled "TutorialUser"

***************************************************************************
** Example 1: import SAS transport file that is saved on your hard drive **
***************************************************************************

* First, download the NHANES 2015-2016 Demographics file and save it to your hard drive *
* from: https://wwwn.cdc.gov/nchs/nhanes/search/datapage.aspx?Component=Demographics&CycleBeginYear=2015 *
* You may need to right-click the link to the data file and select "Save target as..." *;

** TutorialUser: update this path to reference the directory on your hard drive where you have saved the file(s) **
cd "C:\NHANES\DATA"

import sasxport "DEMO_I.xpt", clear

* to save as a Stata dataset *
** TutorialUser: update this path to a directory on your hard drive **
save "C:\NHANES\MYPROJECT\DEMO_I.dta", replace


****************************************************************************
** Example 2: Download the transport file through Stata and then import it *
****************************************************************************
import sasxport "https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/DEMO_I.XPT", clear

* to save as a Stata dataset *
** TutorialUser: update this path to a directory on your hard drive **
save "C:\NHANES\MYPROJECT\DEMO_I.dta", replace

** Note: some older Stata code may include the fdause command 
* this command was renamed to "import sasxport" (though fdause still works)
