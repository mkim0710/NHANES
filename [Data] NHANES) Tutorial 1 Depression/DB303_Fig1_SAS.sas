* redirect output *;
%let outputFname=Data Brief 303 - Figure 1 SAS Survey;
%let outputPath = \\cdc.gov\private\M728\odb4\Web Tutorial\Code examples - for review\code pieces;

* redirect output *;
ods html file="&outputPath.\&outputFName._LST(HTML).html";

* redirect log *;
filename logOut "&outputPath.\&outputFName._LOG.log";
proc printto log=logOut;
run;

* DELETE CODE BLOCK ABOVE THIS LINE *;
****************************************;
options linesize=150;

**********************************************************************************************************************;
** Example SAS Survey code to replicate NCHS Data Brief No. 303, Figure 1                                           **;
** Figure 1.  Percentage of persons aged 20 and over with depression, by age and sex: United States, 2013–2016      **;
**                                                                                                                  **;
** Brody DJ, Pratt LA, Hughes J. Prevalence of depression among adults aged 20 and over: United States, 2013–2016.  **;
** NCHS Data Brief, no 303. Hyattsville, MD: National Center for Health Statistics. 2018.                           **;
**********************************************************************************************************************;

options nocenter nodate nonumber pagesize=max linesize=150;
options FORMCHAR="|----|+|---+=|-/\<>*";

** print SAS version to log **;
%put NOTE: Run in SAS &sysver (maintenance release and release year: &sysvlong4);

* Define paths to Demographic (DEMO) and Mental Health - Depression Screener (DPQ) data *;
filename demo_h url 'https://wwwn.cdc.gov/nchs/nhanes/2013-2014/demo_h.xpt'; libname demo_h xport;
filename demo_i url 'https://wwwn.cdc.gov/nchs/nhanes/2015-2016/demo_i.xpt'; libname demo_i xport;
filename dpq_h url 'https://wwwn.cdc.gov/nchs/nhanes/2013-2014/dpq_h.xpt'; libname dpq_h xport;
filename dpq_i url 'https://wwwn.cdc.gov/nchs/nhanes/2015-2016/dpq_i.xpt'; libname dpq_i xport;

* Read in SAS transport files using a data step and append across survey cycles - Demographic files *;
data demo;
  set demo_h.demo_h(keep=seqn riagendr ridageyr sdmvstra sdmvpsu wtmec2yr)
      demo_i.demo_i(keep=seqn riagendr ridageyr sdmvstra sdmvpsu wtmec2yr);
run;

* Read in SAS transport files and append  across survey cycles - Mental Health - Depression Screener files *;
data dpq;
  set dpq_h.dpq_h
      dpq_i.dpq_i;

  ** Set Refused/Don't Know To Missing (for all variable names starting with "dpq") **;
  array _dpq dpq:;
  do over _dpq;
    if (_dpq >= 7) then call missing(_dpq);
  end;

  ** Create Depression Score (score will be missing if any of the items are missing) **;
  Depression_Score = dpq010+dpq020+dpq030+dpq040+dpq050+dpq060+dpq070+dpq080+dpq090;

  ** Create binary depression indicator as 0/100 variable, to calculate the prevalence of depression **; 
  if (0 <= Depression_Score < 10) then Depression_Indicator = 0;
  else if (Depression_Score >= 10) then Depression_Indicator = 100;

  keep seqn Depression_Score Depression_Indicator;
run;

* Merge component files to produce analysis dataset *;
data one;
  merge demo
        dpq;
  by seqn;

  ** Create Selection Variable For Subpopulation Of Interest **;
  if (ridageyr >= 20) then Select = 1;

  ** Calculate MEC weight for 4-year data *;
  ** Use the MEC exam weights, per the analytic notes in the DPQ documentation file **;
  ** Although the outcome of interest is derived from a questionnaire, these questions were asked at the MEC and so only MEC participants were eligible *; 
  WTMEC4YR = 1/2 * WTMEC2YR;
run;

* Labels for categorized variables *;
proc format;
  value genf
    .='Both Sexes' 1='Men' 2='Women';
  value agef
    .='20 and over' 0-19='<20' 20-39='20-39' 40-59='40-59' 60-high='60 or more';
run;


************************************************************;
** Calculate proportions                                  **;
************************************************************;

** Use Proc Surveymeans To Calculate Prevalences **;
* to get correct variance estimates, you MUST specify option nomcar -- treat missing values as not missing completely at random (NOMCAR) for Taylor series variance estimation *;
proc surveymeans data=one nomcar nobs mean stderr;
  * specify survey design variables in the strata, cluster, and weight statements *;
  strata sdmvstra;
  cluster sdmvpsu;
  weight WTMEC4YR;
  * specify your subpopulation(s) of interest in the domain statement *;
  domain Select Select*riagendr Select*ridageyr Select*riagendr*ridageyr;
  var Depression_Indicator;
  * ODS SELECT statement chooses which output to write to results window *;
  * ODS OUTPUT statement writes specified output to an output dataset *;
  ods select Domain ;
  ods output domain=work.fig1_domain;
  format riagendr genf. ridageyr agef. ;
  title "Percentage of persons aged 20 and over with depression, by age and sex: United States, 2013–2016";
run;


**********************************;
** Prepare and print data table **;
**********************************;
proc sort data = fig1_domain;
  by riagendr ridageyr;
run;

proc print data = fig1_domain noobs;
  var riagendr ridageyr n mean stderr ;
  format n comma8. mean 5.1 stderr 5.1;
  title "Data table: Percentage of persons aged 20 and over with depression, by age and sex: United States, 2013–2016";
  footnote "NOTES: Depression was defined as a score greater than or equal to 10 on the Patient Health Questionnaire.";
  footnote2 "SOURCE: NCHS, National Health and Nutrition Examination Survey, 2013–2016.";
run;

* clear footnote statements *;
footnote;

************************************************************;
** T-testing                                              **;
************************************************************;

** Use proc surveyreg to test for differences between men and women, overall and by age group **;
** can request the test using either an ESTIMATE statement or an LSMEANS statement **;

* option 1: use estimate statement to conduct the hypothesis test *;
proc surveyreg data=one nomcar;
  strata sdmvstra;
  cluster sdmvpsu;
  weight WTMEC4YR;
  * DOMAIN statement: request comparisons for the overall analysis population (i.e. where Select=1) and by agewithin the analysis population (Select*ridageyr) *;
  * Note that ridageyr is a continuous variable but is formatted to create age groups 20-39, 40-59, and 60 and over *;
  domain Select Select*ridageyr;
  * CLASS statement: indicate that riagendr should be treated as a categorical variable instead of a continous variable *;
  class riagendr;
  * Options on MODEL statement: noint request no intercept in the model (so the parameter estimates are the age-specific means) *;
  *          solution requests the parameter estimates be printed (not printed by default if a class statement is used) *;
  *          vadjust specifies whether to use an adjustment for degrees of freedom in the variance estimation. *;
  *                  vadjust=none produces variance estimates that match the default options in proc surveymeans *;
  model Depression_Indicator = riagendr /noint solution vadjust=none;
  * ESTIMATE statement: produce the contrast as the mean value of Depression_Indicator for men minus the mean value of Depression_Indicator for women *;
  estimate 'Men vs Women' riagendr 1 -1;
  ods select Estimates ParameterEstimates;
  ods output estimates = estimates_gender;
  * FORMAT statement: apply a format to create categories from the continuous age variable ridageyr and to apply meaningful labels to the values of riagendr *;
  format riagendr genf. ridageyr agef.;
  title "Test for differences between men and women: Percentage of persons aged 20 and over with depression, by age and sex: United States, 2013–2016";
  title2 "Using an ESTIMATE statement";
run;

* option 2: use lsmeans statement to conduct the hypothesis test *;
proc surveyreg data=one nomcar;
  strata sdmvstra;
  cluster sdmvpsu;
  weight WTMEC4YR;
  domain Select Select*ridageyr;
  class riagendr;
  model Depression_Indicator = riagendr /noint solution vadjust=none;
  lsmeans riagendr /diff;
  ods select Diffs ;
  ods output Diffs=diffs_gender;
  format riagendr genf. ridageyr agef.;
  title "Test for differences between men and women: Percentage of persons aged 20 and over with depression, by age and sex: United States, 2013–2016";
  title2 "Using an LSMEANS statement";
run;

** Pairwise Comparisons Of Age Groups, overall and for each sex **;
proc surveyreg data=one nomcar;
  strata sdmvstra;
  cluster sdmvpsu;
  weight WTMEC4YR;
  domain Select Select*riagendr;
  class ridageyr;
  model Depression_Indicator = ridageyr /noint solution vadjust=none;
  estimate '20-39 vs 40-59' ridageyr 1 -1 0,
           '20-39 vs 60 or more' ridageyr 1 0 -1,
           '40-59 vs 60 or more' ridageyr 0 1 -1;
  ods select Estimates;
  format riagendr genf. ridageyr agef.;
  title "Test for differences between age groups: Percentage of persons aged 20 and over with depression, by age and sex: United States, 2013–2016";
run;
