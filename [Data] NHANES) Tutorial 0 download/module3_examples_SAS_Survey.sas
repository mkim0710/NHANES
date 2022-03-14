
options linesize=150;

***************************************************************************;
** Module 3 examples - SAS Survey code                                    *;
** Examples illustrating the over-sampling of some demographic            *; 
* groups and demonstrating the importance of using weights in analyses    *;
***************************************************************************;

options nocenter nodate nonumber pagesize=max ;
options FORMCHAR="|----|+|---+=|-/\<>*";


*******************;
** Download data **;
*******************;
** Paths to 2015-2016 data files on the NHANES website *;
* DEMO demographic *;
filename demo_i url 'https://wwwn.cdc.gov/nchs/nhanes/2015-2016/demo_i.xpt'; 
libname demo_i xport;

* BPX blood pressure exam *;
filename bpx_i url 'https://wwwn.cdc.gov/nchs/nhanes/2015-2016/bpx_i.xpt'; 
libname bpx_i xport;

* BPQ blood pressure questionnaire *;
filename bpq_i url 'https://wwwn.cdc.gov/nchs/nhanes/2015-2016/bpq_i.xpt'; 
libname bpq_i xport;

* Download SAS transport files and create temporary SAS datasets *;
data demo;
  set demo_i.demo_i(keep=seqn riagendr ridageyr ridreth3 sdmvstra sdmvpsu wtmec2yr wtint2yr ridexprg );  
run;

data bpx_i;
  set bpx_i.bpx_i;
run;

data bpq_i;
  set bpq_i.bpq_i;
run;

** Prepare dataset for hypertension example **;
data bpdata; 
  merge demo
        bpx_i (keep = seqn bpxsy1-bpxsy4 bpxdi1-bpxdi4)
        bpq_i (keep = seqn bpq050a);
  by seqn;
  **Hypertension prevalence**;
  ** Count Number of Nonmissing SBPs & DBPs **;
  n_sbp = n(of bpxsy1-bpxsy4);
  n_dbp = n(of bpxdi1-bpxdi4);
  ** Set DBP Values Of 0 To Missing For Calculating Average **;
  array _DBP bpxdi1-bpxdi4;
  do over _DBP;
    if (_DBP = 0) then _DBP = .;
  end;  
  ** Calculate Mean Systolic and Diastolic **;
  mean_sbp = mean(of bpxsy1-bpxsy4);
  mean_dbp = mean(of bpxdi1-bpxdi4);

  ** "Old" Hypertensive Category variable: taking medication or measured BP > 140/90 **;
  * as used in NCHS Data Brief No. 289 *;
  * variable bpq050a: now taking prescribed medicine for hypertension *;
  if (mean_sbp >= 140 or mean_dbp >= 90 or bpq050a = 1) then HTN_old = 100;  
  else if (n_sbp > 0 and n_dbp > 0) then HTN_old = 0;

  ** Create Hypertensive Category Variable: "new" definition based on taking medication or measured BP > 130/80 **;
  ** From 2017 ACC/AHA hypertension guidelines **;
  * Not used in Data Brief No. 289 - provided for reference *;
  if (mean_sbp >= 130 or mean_dbp >= 80 or bpq050a = 1) then HTN_new = 100;  
  else if (n_sbp > 0 and n_dbp > 0) then HTN_new = 0;

  * race and Hispanic origin categories for hypertension analysis - generate new variable named raceEthCat *;
  select (ridreth3);
    when (1,2) raceEthCat=4; * Hispanic ;
    when (3) raceEthCat=1; * Non-Hispanic white ;
    when (4) raceEthCat=2; * Non-Hispanic black ;
    when (6) raceEthCat=3; * Non-Hispanic Asian ;
    when (7) raceEthCat=5; * Non-Hispanic other race or Non-Hispanic persons of multiple races *;
    otherwise;
  end;

  * age categories for adults aged 18 and over *;
  if 18<=ridageyr<40 then ageCat_18=1;
  else if 40 <=ridageyr<60 then ageCat_18=2;
  else if 60 <=ridageyr then ageCat_18=3;

  * Define subpopulation of interest: non-pregnant adults aged 18 and over who have at least 1 valid systolic OR diastolic BP measure *;
  inAnalysis = (ridageyr >=18 and ridexprg ne 1 and (n_sbp ne 0 or n_dbp ne 0)) ;

  drop bpxsy1-bpxsy4 bpxdi1-bpxdi4;
run;


**********************************************************************************************;
** Estimates for graph - Distribution of race and Hispanic origin, NHANES 2015-2016          *;
* Module 3, Examples Demonstrating the Importance of Using Weights in Your Analyses          *;
* Section "Adjusting for oversampling"                                                       *;
**********************************************************************************************;

proc format;
  * format to combine and reorder the levels of race and Hispanic origin variable ridreth3 *;
  value r3ordf
  1,2="3 Hispanic"
  3,7="4 Non-Hispanic white and other"
  4="1 Non-Hispanic black"
  6="2 Non-Hispanic Asian"
  ;
run;

* Unweighted interview sample *;
proc freq data = demo order=formatted;
  tables ridreth3 / nocum;
  format ridreth3 r3ordf. ;
  title "Percent of 2015-2016 sample, by race and Hispanic origin";
  title2 "Unweighted interview sample"; 
  footnote "Non-Hispanic other includes non-Hispanic persons who reported a race other than white, black, or Asian or who reported multiple races.";
  label ridreth3 ="Race and Hispanic origin";
run;

* Weighted with interview sample weight *;
proc freq data = demo order=formatted;
  tables ridreth3 / nocum ;
  weight wtint2yr;
  format ridreth3 r3ordf. ;
  title "Percent of 2015-2016 sample, by race and Hispanic origin";
  title2 "Weighted with interview weight"; 
  footnote "Non-Hispanic other includes non-Hispanic persons who reported a race other than white, black, or Asian or who reported multiple races.";
  label ridreth3 ="Race and Hispanic origin";
run;

* Population totals from the American Community Survey, 2015-2016 *;
* available on the NHANES website: https://wwwn.cdc.gov/nchs/nhanes/responserates.aspx#population-totals *;
* counts from tab "Both" (for both genders), total row (for all ages) *;
data acs_totals;
  infile datalines delimiter=",";
  input group :$20. population ;
  datalines;
  Non-Hispanic white,194849491  
  Non-Hispanic Black,38418696
  Non-Hispanic Asian,17018259
  Other Non-Hispanic,10444206
  Total Hispanic,55750392
  ;
run;

proc format;
  * format to combine and reorder the race and Hispanic origin groups from ACS totals *;
  value $ acsgrpf
  "Non-Hispanic white", "Other Non-Hispanic" = "4 Non-Hispanic white and other"
  "Non-Hispanic Black" = "1 Non-Hispanic black"
  "Non-Hispanic Asian"="2 Non-Hispanic Asian"
  "Total Hispanic"="3 Hispanic"
  ;
run;

proc freq data=acs_totals order=formatted;
  tables group /nocum;
  weight population;
  format group $acsgrpf.;
  title "Percent of 2015-2016 sample, by race and Hispanic origin";
  title2 "ACS Population Totals";
  footnote "Non-Hispanic other includes non-Hispanic persons who reported a race other than white, black, or Asian or who reported multiple races.";
run;

footnote;
title;

**********************************************************************************************;
** Comparison of weighted and unweighed estimates for hypertension, NHANES 2015-2016         *;
* Module 3, Examples Demonstrating the Importance of Using Weights in Your Analyses          *;
* Section "Why weight?"                                                                      *;
**********************************************************************************************;

proc format;
  * labels for race and Hispanic origin groups, for HTN analysis *;
  value raceLabels
  1="Non-Hispanic white"
  2="Non-Hispanic black"
  3="Non-Hispanic Asian"
  4="Hispanic"
  5="NH Other / multiple races"
  .="Overall adults"
  ;
run;

** Prevalence of hypertension among adults aged 18 and over, overall and by race and Hispanic origin group **;
* using dataset "bpdata", created above *;

** Unweighted estimate - for adults aged 18 and over **;
proc means data = bpdata (where = (inAnalysis=1)) n mean maxdec=1;
  var HTN_old;  
  title "Unweighted (crude) prevalence of hypertension among adults aged 18 and over, 2015-2016";
run;

** Unweighted estimate - for Hispanic adults aged 18 and over **;
proc means data = bpdata (where = (inAnalysis=1 and ridreth3 in (1,2) )) mean maxdec=1;
  var HTN_old;  
  class raceEthCat;
  format raceEthCat raceLabels.;
  title "Unweighted (crude) prevalence of hypertension among Hispanic adults aged 18 and over, 2015-2016";
run;


/*
*** WARNING ***
The following step using Proc Means is intended to demonstrate the importance of using the sample weight in your analyses.
The weighted estimate produces the correct POINT ESTIMATES for the prevalence of hypertension.
However, the Means procedure does not account for the complex survey design of NHANES (e.g. stratification and clustering), 
  so the STANDARD ERRORS (and confidence intervals, statistical tests, etc.) are INCORRECT.
Do NOT use this step as a model for producing your own analyses!
See the NHANES tutorial Module 4: Variance Estimation for a complete explanation of how to properly account for the complex survey design
  using SAS Survey procedures such as Proc Surveymeans 
*/

** Weighted estimate using examination sample weight (produces correct point estimate, but standard errors are incorrect and are not displayed) **;
proc means data = bpdata (where = (inAnalysis=1)) n mean maxdec=1;
  var HTN_old;
  weight wtmec2yr;
  title "Weighted (crude) prevalence of hypertension among adults aged 18 and over, 2015-2016";
run;

proc means data = bpdata (where = (inAnalysis=1 and ridreth3 in (1,2))) mean maxdec=1;
  var HTN_old;
  weight wtmec2yr;
  class raceEthCat;
  types raceEthCat;
  format raceEthCat raceLabels.;
  title "Weighted (crude) prevalence of hypertension among Hispanic adults aged 18 and over, 2015-2016";
run;


* Code using Proc Surveymeans to estimate the prevalence of hypertension, with standard errors *;
* See Module 4: Variance Estimation for details *;
proc format;
  * highlight the subpopulation of interest in results *;
  value domainflag
  0="xxx ignore these rows xxx"
  1="**Analysis population**";
  ;
run;

proc surveymeans data=bpdata nomcar nobs mean ;
  * specify survey design variables in the strata, cluster, and weight statements *;
  strata sdmvstra;
  cluster sdmvpsu;
  weight wtmec2yr;
  var HTN_old;
  * specify subdomains of interest in the domain statement *;
  domain inAnalysis inAnalysis*raceEthCat;
  format inAnalysis domainflag. raceEthCat raceLabels.;
  ods select  Domain ;
  ods output domain=htn_domains;
  title "Weighted (crude) prevalence of hypertension among adults aged 18 and over, 2015-2016";
  title2 "Using Proc Surveymeans to correctly estimate the standard errors";
run;

* Print only the estimates of interest from the output dataset *;
proc print data = htn_domains (where = (inAnalysis=1 and raceEthCat in (.,4))) noobs label;
  var raceEthCat n mean stderr ;
  format n comma8. mean stderr 5.1;
  label raceEthCat="Subpopulation"
        mean="Prevalence (%)"
        stderr = "Standard Error";
  title "Weighted (crude) prevalence of hypertension among adults aged 18 and over, 2015-2016";
  title2 "Using Proc Surveymeans to correctly estimate the standard errors";
run;

****************************************************************************;

** Age distribution among Hispanic adults, weighted and unweighted **;
* statement in tutorial text that the unweighted estimate over-represents Hispanic adults aged 60 and over, compared with their actual share of the Hispanic adult population *;

* format for age groups *;
proc format;
  value agef
  0-<18="0-17"
  18-<40="18-39"
  40-<60="40-60"
  60-high="60 and over"
  ;
run;

** Unweighted age distribution among Hispanic adults in the analysis  **;
proc freq data = bpdata (where = (inAnalysis=1 and ridreth3 in (1,2) ))  order=formatted;
  tables ridageyr ;
  format ridageyr agef. ;
  title "Percent of 2015-2016 sample by age, among Hispanic adults aged 20 and over";
  title2 "Unweighted sample size"; 
run;
* Unweighted, Hispanic adults aged 60 and over comprise 33% of Hispanic adults in the analysis sample. *;

** weighted age distribution among Hispanic adults in the analysis population **;
proc freq data = bpdata (where = (inAnalysis=1 and ridreth3 in (1,2) )) order=formatted;
  tables ridageyr ;
  weight wtmec2yr;
  format ridageyr agef. ;
  title "Age distribution of Hispanic adults aged 20 and over, 2015-2016";
  title2 "Weighted by MEC examination sample weight"; 
run;

* When properly weighted, Hispanic adults aged 60 and over comprise 15% of Hispanic adults *; 
