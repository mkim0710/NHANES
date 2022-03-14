**********************************************************************************************************************
** Example Stata code to replicate NCHS Data Brief No. 303, Figure 1                                                **
** Figure 1.  Percentage of persons aged 20 and over with depression, by age and sex: United States, 2013–2016      **
**                                                                                                                  **
** Brody DJ, Pratt LA, Hughes J. Prevalence of depression among adults aged 20 and over: United States, 2013–2016.  **
** NCHS Data Brief, no 303. Hyattsville, MD: National Center for Health Statistics. 2018.                           **
**********************************************************************************************************************
** Note to tutorial users: you must update some lines of code (e.g. file paths) 
**    to run this code yourself. Search for comments labeled "TutorialUser"


** Display Stata Version Number **
version

* Change working directory to a directory where we can save temporary files *
* TutorialUser: Update this path to a valid location on your computer!
cd "C:\Stata_workspace\"

** Download Demographic (DEMO) Data and Keep Variables Of Interest **
import sasxport "https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/DEMO_H.XPT", clear
keep seqn riagendr ridageyr sdmvstra sdmvpsu wtmec2yr
save "DEMO_H.dta", replace

import sasxport "https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/DEMO_I.XPT", clear
keep seqn riagendr ridageyr sdmvstra sdmvpsu wtmec2yr

** Append Files **
append using "DEMO_H.dta"
save "DEMO.dta", replace

** Download Mental Health - Depression Screener (DPQ) Data **
import sasxport "https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/DPQ_H.XPT", clear
save "DPQ_H.dta", replace

import sasxport "https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/DPQ_I.XPT", clear

** Append Files **
append using "DPQ_H.dta"

** Merge Files **
merge 1:1 seqn using "DEMO.dta"

** Set Refused/Don't Know To Missing (for all variables that start with prefix dpq) **
recode dpq* (7/9 = .)

** Create Binary Depression Indicator as 0/100 variable **
** note that the score will be missing if any of the items are missing **
gen Depression_Score = dpq010+dpq020+dpq030+dpq040+dpq050+dpq060+dpq070+dpq080+dpq090
recode Depression_Score (0/9 = 0) (10/27 = 100), generate(Depression_Indicator)

** Create a new variable with age categories: 20-39, 40-59, 60 and over ** 
recode ridageyr (0/19 = .) (20/39 = 1) (40/59 = 2) (60/80 = 3), generate(Age_Group)

** Labels for categorized variables **
label define Gender_Labels 1 "Male" 2 "Female"
label values riagendr Gender_Labels
label define Age_Labels 1 "20-39" 2 "40-59" 3 "60+"
label values Age_Group Age_Labels

** Define analysis population: adults age 20 and over with a non-missing depression score
gen inAnalysis=0
replace inAnalysis=1 if ridageyr >=20 & !missing(Depression_Indicator)

** Specify survey design variables and request Taylor linearized variance estimation **
** Note: using the MEC Exam Weights (WTMEC2YR), per the analytic notes on the 
**       Mental Health - Depression Screener (DPQ_H) documentation
**  Divide weight by 2 because we are appending 2 survey cycles for 2013-2014 and 2015-2016
gen wtmec4yr = wtmec2yr / 2
svyset [w=wtmec4yr], psu(sdmvpsu) strata(sdmvstra) vce(linearized)

** Sample Size (unweighted) by sex and age for analysis population **
tab riagendr Age_Group if inAnalysis

** Prevalence of depression **
svy, subpop(inAnalysis): mean Depression_Indicator

** Prevalence of depression by gender **
svy, subpop(inAnalysis): mean Depression_Indicator, over(riagendr)
** Compare prevalence of depression between men and women **
lincom [Depression_Indicator]Male - [Depression_Indicator]Female

** Prevalence of depression by age group **
svy, subpop(inAnalysis): mean Depression_Indicator, over(Age_Group)
** Pairwise Comparison Of Age Groups **
lincom [Depression_Indicator]_subpop_1 - [Depression_Indicator]_subpop_2  // 20-39 vs. 40-59
lincom [Depression_Indicator]_subpop_1 - [Depression_Indicator]_subpop_3  // 20-39 vs. 60 and over
lincom [Depression_Indicator]_subpop_2 - [Depression_Indicator]_subpop_3  // 40-59 vs. 60 and over

** Prevalence By Gender And Age Group **
svy, subpop(inAnalysis): mean Depression_Indicator, over(riagendr Age_Group)
** Compare Prevalence Between Men And Women By Age Group **
lincom [Depression_Indicator]_subpop_1 - [Depression_Indicator]_subpop_4 // men vs. women: aged 20-39
lincom [Depression_Indicator]_subpop_2 - [Depression_Indicator]_subpop_5 // men vs. women: aged 40-59
lincom [Depression_Indicator]_subpop_3 - [Depression_Indicator]_subpop_6 // men vs. women: aged 60 and over
** Pairwise Comparison of Age Groups By Gender **
lincom [Depression_Indicator]_subpop_1 - [Depression_Indicator]_subpop_2 // 20-39 vs. 40-59       : men
lincom [Depression_Indicator]_subpop_1 - [Depression_Indicator]_subpop_3 // 20-39 vs. 60 and over : men
lincom [Depression_Indicator]_subpop_2 - [Depression_Indicator]_subpop_3 // 40-59 vs. 60 and over : men
lincom [Depression_Indicator]_subpop_4 - [Depression_Indicator]_subpop_5 // 20-39 vs. 40-59       : women
lincom [Depression_Indicator]_subpop_4 - [Depression_Indicator]_subpop_6 // 20-39 vs. 60 and over : women
lincom [Depression_Indicator]_subpop_5 - [Depression_Indicator]_subpop_6 // 40-59 vs. 60 and over : women

************************************************************

** Alternative method of testing: pairwise comparisons on a "cell means model" from the reg command **

** Prevalence By Gender And Age Group **
* specify ibn. for each factor variable and the noconstant option to include all levels of categorical variables in the model *
svy, subpop(inAnalysis): reg Depression_Indicator ibn.Age_Group#ibn.riagendr, noconstant

** Pairwise comparison of age groups, among men (riagendr=1) and women (riagendr=2) **
pwcompare Age_Group#1.riagendr, pveffects
pwcompare Age_Group#2.riagendr, pveffects

** Pairwise comparison by gender, for each age group *;
pwcompare riagendr#1.Age_Group, pveffects
pwcompare riagendr#2.Age_Group, pveffects
pwcompare riagendr#3.Age_Group, pveffects















