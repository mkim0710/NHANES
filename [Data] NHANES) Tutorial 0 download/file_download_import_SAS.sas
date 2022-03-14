*************************************************************************************************;
* Example code to download/import NHANES data files (SAS transport .XPT files) as a dataset     *;
* For SAS and SAS-callable SUDAAN                                                               *;
*************************************************************************************************;

***************************************************************************;
** Example 1: import SAS transport file that is saved on your hard drive **;
***************************************************************************;

* First, download the NHANES 2015-2016 Demographics file and save it to your hard drive *;
* from: https://wwwn.cdc.gov/nchs/nhanes/search/datapage.aspx?Component=Demographics&CycleBeginYear=2015 *;
* You may need to right-click the link to the data file and select "Save target as..." *;

** TutorialUser: update this libname to reference the directory on your hard drive where you have saved the files **;
* note that the libref points to the .xpt file, NOT the directory it is saved in (unlike a typical libname) *;
libname XP xport "C:\NHANES\DATA\DEMO_I.xpt";

* Import the xpt file and save as a temporary SAS dataset in your work directory *;
* using Proc COPY *;
proc copy in=xp out=work;
run;

* or using a data step *;
data demo_i;
  set xp.demo_i;
run;

* To save a permanent SAS dataset *;
** TutorialUser: update this libname to reference a directory on your hard drive where you want to save the dataset **;
libname mydata "C:\TutorialFiles";

data mydata.demo_i;
  set xpt.demo_i;
run;


***************************************************************************;
** Example 2: use a filename statement to download the transport file     *;
*   through SAS and then import it as a SAS data set                      *;
***************************************************************************;
* note that the libref points to the .xpt file, NOT the directory it is saved in *;

filename xptIn url "https://wwwn.cdc.gov/nchs/nhanes/2015-2016/DEMO_I.xpt"; 
libname xptIn xport;

* Download and inport the xpt file and save as a temporary SAS dataset in your work directory *;
* using Proc COPY *;
proc copy in=xptIN out=work;
run;

* or using a data step *;
data demo_i;
  set xptIn.demo_i;
run;

* To save a permanent SAS dataset *;
** TutorialUser: update this libname to reference a directory on your hard drive where you want to save the dataset **;
libname mydata "C:\TutorialFiles";

data mydata.demo_i;
  set xptIn.demo_i;
run;
