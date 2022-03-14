***************************************************************************
** Module 3 examples - Stata code                                         *
** Examples illustrating the over-sampling of some demographic            * 
* groups and demonstrating the importance of using weights in analyses    *
***************************************************************************
** Note to tutorial users: you must update some lines of code (e.g. file paths) 
**    to run this code yourself. Search for comments labeled "TutorialUser"


* Change working directory to a directory where we can save temporary files *
* TutorialUser: Update this path to a valid location on your computer!
cd "C:\Stata_workspace\"

*******************************************************************
** Download data files from NHANES website and import into Stata **
*******************************************************************

* DEMO demographic *
import sasxport "https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/DEMO_I.XPT", clear
save "DEMO_I.dta", replace

* BPX blood pressure exam *
import sasxport "https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/BPX_I.XPT", clear
save "BPX_I.dta", replace

* BPQ blood pressure questionnaire *
import sasxport "https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/BPQ_I.XPT", clear
save "BPQ_I.dta", replace

**********************
** Merge data files **
**********************
use "DEMO_I.dta", clear
merge 1:1 seqn using "BPX_I.dta", nogenerate keepusing(seqn bpxsy1-bpxsy4 bpxdi1-bpxdi4)
merge 1:1 seqn using "BPQ_I.dta", nogenerate keepusing(seqn bpq050a)

*********************************
** Generate analysis variables **
*********************************
**Hypertension prevalence**
** Count Number of Nonmissing SBPs & DBPs **
egen n_sbp=rownonmiss( bpxsy1 bpxsy2 bpxsy3 bpxsy4)
egen n_dbp=rownonmiss( bpxdi1 bpxdi2 bpxdi3 bpxdi4)

** Set DBP Values Of 0 To Missing For Calculating Average **
mvdecode bpxdi1-bpxdi4, mv(0)

** Calculate Mean Systolic and Diastolic (over non-missing values) **
egen mean_sbp=rowmean(bpxsy1 bpxsy2 bpxsy3 bpxsy4)
egen mean_dbp=rowmean(bpxdi1 bpxdi2 bpxdi3 bpxdi4)

** Create 0/100 indicator for Hypertension **
* "Old" Hypertensive Category variable: taking medication or measured BP > 140/90 *
* as used in NCHS Data Brief No. 289 *
* variable bpq050a: now taking prescribed medicine for hypertension, 1 = yes *
* need to explicitly check that mean_dbp is not missing because missing values are representated as large values ("positive infinity") in Stata *
gen HTN_old=100 if ( (mean_sbp>=140 & !missing(mean_sbp)) | (mean_dbp >= 90 & !missing(mean_dbp))| bpq050a == 1) 
replace HTN_old = 0 if  (HTN_old==. & n_sbp > 0 & n_dbp > 0)
label define htnLabel 0 "No" 100 "Yes"
label values HTN_old htnLabel

/*
** For reference: "new" definition of hypertension prevalence, based on taking medication or measured BP > 130/80 **
** From 2017 ACC/AHA hypertension guidelines **
* Not used in Data Brief No. 289 - provided for reference *
gen HTN_new=100 if ( (mean_sbp>=130 & !missing(mean_sbp)) | (mean_dbp >= 80 & !missing(mean_dbp)) | bpq050a == 1) 
replace HTN_new = 0 if  (missing(HTN_new) & n_sbp > 0 & n_dbp > 0)
*/

* Create race and Hispanic ethnicity categories for oversampling analysis *
* combined Non-Hispanic white and Non-Hispanic other and multiple races, to approximate the sampling domains *
recode ridreth3 (3 7 = 4) (4 = 1) (1/2=3) (6 = 2), generate(race1)
label define racelabels1 1 "Non-Hispanic black" 2 "Non-Hispanic Asian" 3"Hispanic" 4 "Non-Hispanic white and other"
label values race1 racelabels1

* Create race and Hispanic ethnicity categories for hypertension analysis *
recode ridreth3 (3 = 1) (4 = 2) (1/2=4) (6=3) (7 = 5), generate(raceEthCat)
label define raceEthnicity_Labels 1 "Non-Hispanic white" 2 "Non-Hispanic black" 3"Non-Hispanic Asian" 4 "Hispanic" 5 "NH other race or multiple races"
label values raceEthCat raceEthnicity_Labels

* Create age categories for adults aged 18 and over: ages 18-39, 40-59, 60 and over *
recode ridageyr (0/17 = .) (18/39 = 1) (40/59 = 2) (60/80 = 3), generate(ageCat_18)
label define Age_Labels 1 "18-39" 2 "40-59" 3 "60 and over"
label values ageCat_18 Age_Labels

* Define subpopulation of interest: non-pregnant adults aged 18 and over who have at least 1 valid systolic OR diastolic BP measure *
generate inAnalysis = 1 if (ridageyr >=18 & ridexprg ~= 1 & (n_sbp > 0 | n_dbp > 0))


**********************************************************************************************
** Estimates for graph - Distribution of race and Hispanic origin, NHANES 2015-2016          *
* Module 3, Examples Demonstrating the Importance of Using Weights in Your Analyses          *
* Section "Adjusting for oversampling"                                                       *
**********************************************************************************************

* Proportion of unweighted interview sample *
tab race1

* Proportion, weighted with interview weight *
tab race1 [iweight=wtint2yr]

* Proportion of US population *
* Input population totals from the American Community Survey, 2015-2016 *
* available on the NHANES website: https://wwwn.cdc.gov/nchs/nhanes/responserates.aspx#population-totals *
* counts from tab "Both" (for both genders), total row (for all ages) *

scalar NH_White_Other=194849491+10444206
scalar NH_Black=38418696
scalar NH_Asian=17018259
scalar Hispanic=55750392
scalar acsTotal= NH_White_Other + NH_Black + NH_Asian + Hispanic

* use display command as a "hand calculator" to display the proportion comprised by each group *
foreach group in NH_Black NH_Asian Hispanic NH_White_Other {
	display "`group' " %5.1f `group'/acsTotal*100
}


**********************************************************************************************
** Comparison of weighted and unweighed estimates for hypertension, NHANES 2015-2016         *
* Module 3, Examples Demonstrating the Importance of Using Weights in Your Analyses          *
* Section "Why weight?"                                                                      *
**********************************************************************************************

** Prevalence of hypertension among adults aged 18 and over, overall and by race and Hispanic origin group **

* Unweighted estimate - for adults aged 18 and over *
tab HTN_old if inAnalysis==1

* Unweighted estimate - for adults aged 18 and over, by race and Hispanic origin *
tab raceEthCat HTN_old if inAnalysis==1 , row 

* Weighted estimates * 

*** WARNING ***
* The following commands using the tab statement are intended to demonstrate the importance of using the sample weight in your analyses.
* The weighted estimate produces the correct POINT ESTIMATES for the prevalence of hypertension.
* However, your analysis must account for the complex survey design of NHANES (e.g. stratification and clustering), 
*   in order to produce correct STANDARD ERRORS (and confidence intervals, statistical tests, etc.).
* Do NOT use this step as a model for producing your own analyses!
* See the Continuous NHANES tutorial Module 4: Variance Estimation for a complete explanation of how to properly account 
*    for the complex survey design using Stata survey commands with the svy: prefix

* Weighted estimates - for adults aged 18 and over *
tab HTN_old [iweight=wtmec2yr] if inAnalysis==1

* Weighted estimates - for adults aged 18 and over, by race and Hispanic origin *
tab raceEthCat HTN_old  [iweight=wtmec2yr] if inAnalysis==1 , row

** Code using Stata svy commands to estimate the prevalence of hypertension, with correct standard errors) ** 
* See Module 4: Variance Estimation for details *
svyset [w=wtmec2yr], psu(sdmvpsu) strata(sdmvstra) vce(linearized)
* overall adults aged 18 and over *
svy, subpop(inAnalysis): mean HTN_old , cformat(%5.1f)
* adults aged 18 and over, by race and Hispanic origin *
svy, subpop(inAnalysis): mean HTN_old , over(raceEthCat) cformat(%5.1f)


************************

** Age distribution among Hispanic adults, weighted and unweighted **
* statement in tutorial text that the unweighted estimate over-represents Hispanic adults aged 60 and over,
*  compared with their actual share of the Hispanic adult population *

* Unweighted age distribution among Hispanic adults in the analysis  *
tab ageCat_18 if inAnalysis==1 & raceEthCat==4
* Unweighted, Hispanic adults aged 60 and over comprise 33% of Hispanic adults in the analysis sample. *

* weighted age distribution among Hispanic adults in the analysis population *
tab ageCat_18 [iweight=wtmec2yr] if inAnalysis==1 & raceEthCat==4
* When properly weighted, Hispanic adults aged 60 and over comprise 15% of Hispanic adults in the US non-institutionalized civilian population * 
























