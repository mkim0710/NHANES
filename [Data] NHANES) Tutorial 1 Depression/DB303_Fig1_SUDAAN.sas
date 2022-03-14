*************************************************************************************************;
** Example SUDAAN code to replicate NCHS Data Brief No. 303, Figure 1                          **;
** Figure 1.  Percentage of persons aged 20 and over with depression, by age and sex:          **;
** United States, 2013–2016                                                                    **;
**                                                                                             **;
** Brody DJ, Pratt LA, Hughes J. Prevalence of depression among adults aged 20 and over:       **;
** United States, 2013–2016. NCHS Data Brief, no 303. Hyattsville, MD: National Center for     **;
** Health Statistics. 2018.                                                                    **;
*************************************************************************************************;

options nodate nonumber pagesize=100 linesize=150 nocenter;

** print SAS version to log **;
%put Run in SAS &sysver (maintenance release and release year: &sysvlong4) 
 and SUDAAN Release 11.0.1 (SAS-Callable, 32 bit version);

* Define paths to Demographic (DEMO) and Mental Health - Depression Screener (DPQ) data *;
filename demo_h url 'https://wwwn.cdc.gov/nchs/nhanes/2013-2014/demo_h.xpt'; libname demo_h xport;
filename demo_i url 'https://wwwn.cdc.gov/nchs/nhanes/2015-2016/demo_i.xpt'; libname demo_i xport;
filename dpq_h url 'https://wwwn.cdc.gov/nchs/nhanes/2013-2014/dpq_h.xpt'; libname dpq_h xport;
filename dpq_i url 'https://wwwn.cdc.gov/nchs/nhanes/2015-2016/dpq_i.xpt'; libname dpq_i xport;

* Read in SAS transport files and append across survey cycles - Demographic files *;
data demo;
  set demo_h.demo_h(keep=seqn riagendr ridageyr sdmvstra sdmvpsu wtmec2yr)
      demo_i.demo_i(keep=seqn riagendr ridageyr sdmvstra sdmvpsu wtmec2yr);
run;

* Read in SAS transport files and append across survey cycles - Mental Health - Depression Screener files *;
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

* Define formats *; 
proc format;
  * format to categorize age *;
  value ageCatF
  low-<20=" "
  20-39="1"
  40-59="2"
  60-high="3"
  ;
  *Labels for categorized variables *;
  value genf
    1='Men' 2='Women';
  value agef
    1='20-39' 2='40-59' 3='60 and over';
  value depf
    0='0-9' 1='10 or more';
run;

* Merge component files to produce analysis dataset *;
data one;
  merge demo
        dpq;
  by seqn;
  ** Create Selection Variable For Subpopulation Of Interest **;
  if (ridageyr >= 20) then Select = 1;

  ** Categorize age (apply format, then convert to numeric variable) **;
  ageCat=input(put( ridageyr, ageCatF.), best8.); 

  ** Calculate MEC weight for 4-year data *;
  ** use the MEC exam weights, per the analytic notes in the DPQ documentation file **;
  WTMEC4YR = 1/2 * WTMEC2YR;
run;

* Sort the analysis dataset by the survey design variables before running SUDAAN procedures *;
proc sort data=one;
  by sdmvstra sdmvpsu;
run;

************************************************************;
** Calculate proportions                                  **;
************************************************************;

** Use Proc Descript To Calculate Prevalences **;
proc descript data=one design=wr;
  nest sdmvstra sdmvpsu; * specify survey design variables *;
  weight WTMEC4YR; * specify sampling weight *;
  subpopx Select = 1; * analyze the subpopulation of interest *;
  class riagendr ageCat /nofreq;
  * var and catlevel statements: treat Depression_Score as a categorical variable, and analyze the proportion with Depression_Indicator = 100 *;
  var Depression_Indicator;
  catlevel 100; 
  table riagendr*ageCat;
  print nsum percent sepercent/style=nchs nohead notime nodate percentfmt=f8.1 sepercentfmt=f8.1;
  rtitle "Percentage of adults aged 20 and over with depression, by age and sex: United States, 2013–2016";
  rformat riagendr genf.;
  rformat ageCat agef.;
run;

** Use Proc Descript To Calculate Prevalences -- alternative example demonstrating the RECODE statement **;
** Note that SUDAAN does not allow use of an RFORMAT statement to categorize a continuous variable (i.e. age) **;
** Instead, use the RECODE statement if you wish to categorize continuous variables within the DESCRIPT procedure *;
proc descript data=one design=wr;
  nest sdmvstra sdmvpsu; * specify survey design variables *;
  weight WTMEC4YR; * specify sampling weight *;
  subpopx Select = 1; * analyze the subpopulation of interest *;
  class riagendr ridageyr/nofreq;
  * the recode statement replaces these variables with recoded (categorized) values before other statements are executed *;
  * recoded: ridageyr<20 = 0, 20<=ridageyr<40 = 1, 40<=ridageyr<60 = 2, ridageyr>=60 = 3 *;
  *          Depression_Score<10 = 0,  Depression_Score>=10 = 1 *;
  recode ridageyr = (20 40 60)
         Depression_Score = (10);
  * var and catlevel statements: treat Depression_Score as a categorical variable, and analyze the proportion with (recoded) Depression_Score = 1 *;
  var Depression_Score;
  catlevel 1; 
  table riagendr*ridageyr;
  print nsum percent sepercent/style=nchs nohead notime nodate percentfmt=f8.1 sepercentfmt=f8.1;
  rtitle "Percentage of adults aged 20 and over with depression, by age and sex: United States, 2013–2016";
  rtitle "Alternative method demonstrating the RECODE statement";
  rformat riagendr genf.;
  rformat ridageyr agef.;
run;

************************************************************;
** T-testing                                              **;
************************************************************;

** Use Contrasts For Statistical Testing Between Men And Women (among age groups 20-39, 40-59, 60 and over, and total aged 20 and over) **;
proc descript data=one design=wr;
  nest sdmvstra sdmvpsu;
  weight WTMEC4YR;
  subpopx Select = 1;
  class riagendr ageCat /nofreq;
  var Depression_Indicator;
  catlevel 100;
  table ageCat;
  pairwise riagendr;
  setenv labwidth=28;
  print nsum t_pct P_pct/style=nchs nohead notime nodate;
  rtitle "Test for differences between men and women: Percentage of adults aged 20 and over with depression, by age and sex: United States, 2013–2016";
  rformat riagendr genf.;
  rformat ageCat agef.;
run;

** Use Contrasts For Statistical Testing Between Age Groups (among men, women, and total) **;
proc descript data=one design=wr;
  nest sdmvstra sdmvpsu;
  weight WTMEC4YR;
  subpopx Select = 1;
  class riagendr ageCat/nofreq;
  var Depression_Indicator;
  catlevel 100;
  table riagendr;
  pairwise ageCat;
  setenv labwidth=34;
  print nsum t_pct P_pct/style=nchs;
  rtitle "Test for differences between age groups: Percentage of adults aged 20 and over with depression, by age and sex: United States, 2013–2016";
  rformat riagendr genf.;
  rformat ageCat agef.;
run;

