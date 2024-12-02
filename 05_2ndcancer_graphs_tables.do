cap log close
log using "D:\Users\MSc_students_2022_2023\Ruchika\publication\analysis", replace text
display "$S_TIME  $S_DATE"
cd "D:\Users\MSc_students_2022_2023\Ruchika\publication"
global res "C:\Users\lshsl7\OneDrive - London School of Hygiene and Tropical Medicine\Breast_2ndcancer_RG\results"
**# Table crude rate
/*
import excel "Tables.xlsx", sheet("Table2_cancer2nd") firstrow clear
label define out1 0 "Censored" 1 "Second primary cancer" 2 "Dead"
label values cancer2nd out1
cap rename cancer2ndgrp cancer2nd
tempfile all
save `all', replace

import excel "Tables.xlsx", sheet("Table2_cancer2ndgrp") firstrow clear
label define out2 0 "Censored" 1 "Second breast cancer" 2 "Second cancer female genital organs" ///
3 "Second cancer of digestive organs" 4 "Second cancer of respiratory and intrathoracic organs" ///
5 "Other second cancers" 6 "Dead"
label values cancer2nd out2
append using `all'

foreach var of varlist rate lb ub {
	tostring `var', gen(`var'1) force format(%4.1f)
}
gen rates = rate1 + " (" + lb1 + ", " + ub1 + ")" 

decode cancer2nd, gen(Outcome)
decode cancer2nd, gen(Outcome1)
replace Outcome = Outcome1 if Outcome == ""
keep ptime failures rates Outcome
duplicates drop
sort Outcome
label var Outcome "Outcome"
label var ptime "Person-years"
label var failures "Number of events"
label var rates "Crude rate (95% CI)"
gsort -failures
export excel using "$res/Tables.xlsx", sheet("Table2_rates") sheetreplace firstrow(varlabels)


clear
use npci1, clear
gen cancer2nd = 1
append using npci2
replace cancer2nd = 2 if cancer2nd ==. 
gen cancer2nd_grp = .
tempfile npci
save `npci', replace

forvalues k = 1(1)5 {
	use `npci', clear
	append using npci_grp`k'
	replace cancer2nd_grp = `k' if cancer2nd ==. & cancer2nd_grp ==.
	save `npci', replace
}
*/
use npci, clear
drop survivor std lb ub
reshape wide at_risk fail, i(incomequintile2015 time) j(cancer2ndgrp)
rename at_risk1 atrisk
drop at_risk*
reshape wide atrisk fail*, i(time) j(incomequintile2015)
label var atrisk1 "Number at risk"
label var atrisk5 "Number at risk"
label var fail21 "  Second breast cancer"
label var fail25 "  Second breast cancer"
label var fail31 "  Second cancer of female genital organs"
label var fail35 "  Second cancer of female genital organs"
label var fail41 "  Second cancer of digestive organs"
label var fail45 "  Second cancer of digestive organs"
label var fail51 "  Second cancer of respiratory and intrathoracic organs"
label var fail55 "  Second cancer of respiratory and intrathoracic organs"
label var fail61 "  Other second cancers"
label var fail65 "  Other second cancers"
label var fail11 "Second primary cancer"
label var fail15 "Second primary cancer"
label var fail71 "Death"
label var fail75 "Death"
replace time = time +0.5
export excel using "$res/Tables.xlsx", sheet("F1_atrisk") sheetreplace firstrow(varlabels)

/*update on 02/12/2024 for final submission*/
use npci, clear
drop survivor std lb ub
replace time = time +0.5 if time > 0
preserve
drop at_risk
reshape wide fail, i(incomequintile2015 cancer2ndgrp) j(time)
tempfile fail
save `fail', replace
restore

preserve
drop fail
rename at_risk fail
reshape wide fail, i(incomequintile2015 cancer2ndgrp) j(time)
bysort incomequintile2015: keep if _n == 1
replace cancer2nd = 0
tempfile at_risk
save `at_risk', replace
restore
use `fail', clear
append using `at_risk'
label define out 0 "Number at risk", modify
sort incomequintile2015 cancer2ndgrp
label variable fail0 "0.5"
forvalues i = 1(1)18 {
	label variable fail`i' "`i'"
}
export excel using "$res/Tables.xlsx", sheet("F1_atrisk_new") sheetreplace firstrow(varlabels)


import excel "$res/Tables.xlsx", sheet(F1_npci_1) clear 
renames A B C D E F G \ SES at ObsTime CumInc UCI LCI Outcome
destring SES, replace
destring at, replace
destring Outcome, replace
destring ObsTime, replace
destring CumInc, replace
destring UCI, replace
destring LCI, replace

replace Outcome = Outcome + 5
tempfile npci
save `npci', replace
import excel "$res/Tables.xlsx", sheet("F1_npci_2") clear
renames A B C D E F G \ SES at ObsTime CumInc UCI LCI Outcome
destring SES, replace
destring at, replace
destring Outcome, replace

append using `npci'
foreach var in CumInc UCI LCI{
	tostring `var', gen(`var'1) force format(%5.4f)
}
gen fail = CumInc1 + " (" + LCI1 + ", " + UCI1 + ")"
keep SES at fail Outcome
reshape wide fail, i(SES at) j(Outcome)
reshape wide fail*, i(at) j(SES)
label var fail11 "  Second breast cancer"
label var fail15 "  Second breast cancer"
label var fail21 "  Second cancer of female genital organs"
label var fail25 "  Second cancer of female genital organs"
label var fail31 "  Second cancer of digestive organs"
label var fail35 "  Second cancer of digestive organs"
label var fail41 "  Second cancer of respiratory and intrathoracic organs"
label var fail45 "  Second cancer of respiratory and intrathoracic organs"
label var fail51 "  Other second cancers"
label var fail55 "  Other second cancers"
label var fail61 "Second primary cancer"
label var fail65 "Second primary cancer"
label var fail71 "Death"
label var fail75 "Death"
order fail61, before(fail11)
order fail65, before(fail15)
export excel using "$res/Tables.xlsx", sheet("F1_npci") sheetreplace firstrow(varlabels)

preserve
clear
tempfile rates
save `rates', replace emptyok
restore
forvalues i=0(1)6 {
	import excel "Tables.xlsx", sheet("Table2_`i'") firstrow clear
	xpose, clear
	drop if _n == 1
	rename v1 pys
	rename v2 events
	rename v3 rate
	rename v4 lb
	rename v5 ub
	gen outcome = `i'
	gen ses = _n - 1
	append using `rates'
	save `rates', replace
}
use `rates', clear
label define spc 0 "Overall second primary cancer" 1 "Second breast cancer" ///
2 "Second cancer female genital organs" 3 "Second cancer of digestive organs" ///
4 "Second cancer of respiratory and intrat" 5 " Other second cancers" 6 "Death"
label values outcome spc
foreach var of varlist rate lb ub {
	tostring `var', gen(`var'1) force format(%4.2f)
}
gen rates = rate1 + " (" + lb1 + ", " + ub1 + ")" 
keep pys events outcome ses rates
reshape wide pys events rates, i(outcome) j(ses)
label var rates0 "Overall"
label var rates1 "The least deprived"
label var rates2 "2"
label var rates3 "3"
label var rates4 "4"
label var rates5 "The most deprived"
export excel using "$res/Tables.xlsx", sheet("Table2_rates_TableS2") sheetreplace firstrow(varlabels)

**# HR tables
///*Rubin's rules from MI analysis*/
use hr_mi, clear
drop if db == 0
gen ln_es=ln(estimate)
gen ln_lb=ln(min95)
gen ln_ub=ln(max95)
gen se = (ln_ub - ln_lb)/3.92
bysort cancer2nd parm: egen mean_es=mean(ln_es) /*mean risk of 10 imputed db*/
gen u1 = (se)^2 /*se variance within each db*/
bysort cancer2nd parm: egen meanu=mean(u1) /*average variance within each db*/
gen b1 = (ln_es - mean_es)^2 /*variance across imputed dbs*/
bysort cancer2nd parm: egen totalb=total(b1) /*total variance across dbs*/
bysort cancer2nd parm: gen b= totalb /(10-1) /*between imputation variance = total / (m-1) where m is imputed times*/
bysort cancer2nd parm: gen ta= meanu + (1+1/10) * b /*total variance considering within and between imputed*/
bysort cancer2nd parm: gen tase= (ta)^0.5 /*combined standard error for risk*/
gen uci= mean_es + 1.96 * (tase)
gen lci= mean_es - 1.96 * (tase)
keep cancer2nd parm mean_es lci uci analysis
duplicates drop
gen estimate = exp(mean_es)
gen min95 = exp(lci)
gen max95 = exp(uci)
keep cancer2nd parm estimate min95 max95 analysis
tempfile hr_mi
save `hr_mi', replace

use hr_nonbreast, clear
drop if db == 0
gen ln_es=ln(estimate)
gen ln_lb=ln(min95)
gen ln_ub=ln(max95)
gen se = (ln_ub - ln_lb)/3.92
bysort cancer2nd parm: egen mean_es=mean(ln_es) /*mean risk of 10 imputed db*/
gen u1 = (se)^2 /*se variance within each db*/
bysort cancer2nd parm: egen meanu=mean(u1) /*average variance within each db*/
gen b1 = (ln_es - mean_es)^2 /*variance across imputed dbs*/
bysort cancer2nd parm: egen totalb=total(b1) /*total variance across dbs*/
bysort cancer2nd parm: gen b= totalb /(10-1) /*between imputation variance = total / (m-1) where m is imputed times*/
bysort cancer2nd parm: gen ta= meanu + (1+1/10) * b /*total variance considering within and between imputed*/
bysort cancer2nd parm: gen tase= (ta)^0.5 /*combined standard error for risk*/
gen uci= mean_es + 1.96 * (tase)
gen lci= mean_es - 1.96 * (tase)
keep cancer2nd parm mean_es lci uci analysis
duplicates drop
gen estimate = exp(mean_es)
gen min95 = exp(lci)
gen max95 = exp(uci)
keep cancer2nd parm estimate min95 max95 analysis
tempfile hr_nonbreast
replace analysis = analysis + " non-breast"
save `hr_nonbreast', replace

use hr_cc, clear
sort analysis
replace analysis = analysis + "hr_cc"
append using `hr_mi'
append using `hr_nonbreast'
sort cancer2nd parm analysis
gen analysis1 = 1 if analysis == "Age-adjustedhr_cc"
replace analysis1 = 2 if analysis == "Fully-adjusted MI"
replace analysis1 = 3 if analysis == "Fully-adjusted_cc1hr_cc"
replace analysis1 = 4 if analysis == "Fully-adjusted_cc2hr_cc"
replace analysis1 = 5 if analysis == "Fully-adjusted MI non-breast"
label define analysis 1 "Age-adjusted" 2 "Main analysis (Fully-adjusted MI)" ///
3 "Sensitivity analysis 1"  4 "Sensitivity analysis 2" 5 "Sensitivity analysis 3"
label values analysis1 analysis
label define out 1 "Second primary cancer incidence" 2 "Death"
label values cancer2nd out
replace cancer2nd = cancer2nd_nonbreast if cancer2nd == .
drop cancer2nd_nonbreast
drop if strpos(parm, "_rcs")>0 | strpos(parm, "ages")>0 | strpos(parm, "_cons")>0


preserve
keep if strpos(parm, "income")>0
gen Variable = "Income quintile"
gen Levels = substr(parm, -1, 1)
destring Levels, replace
label define dep 2 "2nd quintile" 3 "3rd quintile" 4 "4th quintile" 5 "The most deprived"
label values Levels dep
tab analysis, m
forvalues i = 1/2 {
	metan estimate min95 max95 if cancer2nd == `i' , ///
	xlabel(1.0 1.2 1.5, format(%4.1f)) nulloff nowt ///
	diamopt(lwidth(vvthin)) ciopt(lwidth(vthin)) boxopt(mcolor(none)) pointopt(msymbol(smcircle)) ///
	effect(CSHR) ///
	lcols(Levels) by(analysis1) nosubgroup nooverall name(f`i', replace)
}
graph combine f1 f2, rows(1) xsize(11.75) ysize(8.25)
graph export "$res/F2.svg", as(svg) replace
restore

gen variable = substr( parm, 1, strlen(parm) - 1) if strpos(parm, "income")>0 |  strpos(parm, "ethnic")>0 |  strpos(parm, "ydiag")>0 | strpos(parm, "tnm")>0 
gen level = substr(parm,-1,1) if variable !=""
replace level = "1" if variable == ""
replace variable = parm if variable == ""
sort analysis
drop if strpos(variable,"income")>0
sort cancer2nd parm
replace variable = proper(variable)
replace variable = "Comorbidity" if variable == "Cci"
replace variable = "Curative Surgery" if variable == "Curative_Surg"
replace variable = "Ethnicity" if variable == "Ethnic"
replace level = "Asian" if variable == "Ethnicity"  & level == "2"
replace level = "Black" if variable == "Ethnicity"  & level == "3"
replace level = "Other" if variable == "Ethnicity"  & level == "4"
replace variable = "TNM stage" if variable == "Tnm_Stage"
replace level = "Missing" if variable == "TNM stage"  & level == "5"
replace variable = "Year of diagnosis group" if variable == "Ydiag_Grp"
label define ydiag_grp 1 "2000-2003" 2 "2004-2007" 3 "2008-2011" 4 "2012-2014" 5 "2015-2018"
replace level = "2004-2007" if variable == "Year of diagnosis group"  & level == "2"
replace level = "2008-2011" if variable == "Year of diagnosis group"  & level == "3"
replace level = "2012-2014" if variable == "Year of diagnosis group"  & level == "4"
replace level = "2015-2018" if variable == "Year of diagnosis group"  & level == "5"

foreach var of varlist estimate min95 max95 {
	tostring `var', gen(`var'1) force format(%4.2f)
}
gen HR = estimate1 + " (" + min951 + ", " + max951 + ")" 

keep parm variable level HR cancer2nd analysis1
reshape wide HR, i(parm variable level cancer2nd) j(analysis)
drop parm
sort cancer2nd variable level
label var HR2 "Fully-adjusted MI"
label var HR3 "Sensitivity analysis 1"
label var HR4 "Sensitivity analysis 2"
label var HR5 "Sensitivity analysis 3"
reshape wide HR*, i(variable level) j(cancer2nd)
order variable level HR21 HR22 HR31 HR32 HR41 HR42 HR51 HR52
export excel using "$res/Tables.xlsx", sheet("TableS3_HR_other_covar") sheetreplace firstrow(varlabels)

/*
	preserve
	renames estimate min95 max95, prefix(`f'_)
	sort analysis parm
	sencode analysis
	reshape wide *estimate *min95 *max95, i(parm cancer2nd) j(analysis)
	tempfile `f'
	save ``f'', replace
	restore

	foreach var of varlist estimate min95 max95 {
		tostring `var', gen(`var'1) force format(%4.2f)
	}
	gen HR = estimate1 + " (" + min951 + ", " + max951 + ")" 
	keep parm HR analysis cancer2nd
	gen variable = substr( parm, 1, strlen(parm) - 1) if strpos(parm, "income")>0 |  strpos(parm, "ethnic")>0 |  strpos(parm, "ydiag")>0 | strpos(parm, "tnm")>0 
	gen level = substr(parm,-1,1) if variable !=""
	replace level = "1" if variable == ""
	replace variable = parm if variable == ""
	reshape wide HR, i(parm variable level analysis) j(cancer2nd)
	label var HR1 "Second primary cancer - HR (95% CI)"
	label var HR2 "Death - HR (95% CI)"

	preserve
	keep if analysis == "Age-adjusted"
	keep variable level HR1 HR2
	export excel using "$res/Tables.xlsx", sheet("Table3_1_HR_age_`f'") sheetreplace firstrow(varlabels)
	restore

	preserve
	keep if analysis == "Fully-adjusted"
	keep if strpos(parm,"income")>0
	keep variable level HR1 HR2
	export excel using "$res/Tables.xlsx", sheet("Table3_3_HR_fully_adjusted_CC_`f'") sheetreplace firstrow(varlabels)
	restore

	preserve
	keep if analysis == "Fully-adjusted"
	drop if strpos(parm,"income")>0
	keep variable level HR1 HR2
	export excel using "$res/Tables.xlsx", sheet("TableS2_HR_CC_others_`f'") sheetreplace firstrow(varlabels)
	restore
*/

use hr_stratified, clear
drop if db == 0
gen ln_es=ln(estimate)
gen ln_lb=ln(min95)
gen ln_ub=ln(max95)
gen se = (ln_ub - ln_lb)/3.92
bysort cancer2nd parm analysis before2012 older55: egen mean_es=mean(ln_es) /*mean risk of 10 imputed db*/
gen u1 = (se)^2 /*se variance within each db*/
bysort cancer2nd parm analysis before2012 older55: egen meanu=mean(u1) /*average variance within each db*/
gen b1 = (ln_es - mean_es)^2 /*variance across imputed dbs*/
bysort cancer2nd parm analysis before2012 older55: egen totalb=total(b1) /*total variance across dbs*/
bysort cancer2nd parm analysis before2012 older55: gen b= totalb /(10-1) /*between imputation variance = total / (m-1) where m is imputed times*/
bysort cancer2nd parm analysis before2012 older55: gen ta= meanu + (1+1/10) * b /*total variance considering within and between imputed*/
bysort cancer2nd parm analysis before2012 older55: gen tase= (ta)^0.5 /*combined standard error for risk*/
gen uci= mean_es + 1.96 * (tase)
gen lci= mean_es - 1.96 * (tase)
keep cancer2nd parm mean_es lci uci before2012 older55 analysis
duplicates drop
gen estimate = exp(mean_es)
gen min95 = exp(lci)
gen max95 = exp(uci)
keep if strpos(parm, "incomequintile2015")>0
sort analysis
sencode analysis, replace
table analysis, m
drop mean_es lci uci
	foreach var of varlist estimate min95 max95 {
		tostring `var', gen(`var'1) force format(%4.2f)
	}
gen HR = estimate1 + " (" + min951 + ", " + max951 + ")" 
keep parm cancer2nd before2012 older55 HR analysis
gen strat = 1 if before2012 !=.
replace strat = 2 if older55 !=.
label define strat 1 "before2012" 2 "older55"
label values strat  strat
gen levels = before2012
replace levels = older55 if levels ==.
reshape wide HR, i(parm analysis levels strat before2012 older55) j(cancer2nd)
sort before2012 older55 analysis
sort before older55 parm
drop before2012 older55
reshape wide HR*, i(parm strat analysis) j(levels)
sort strat analysis parm

label variable HR10 "SPC, strat0"
label variable HR20 "Death, strat0"
label variable HR11 "SPC, strat1"
label variable HR21 "Death, strat1"
export excel using "$res/Tables.xlsx", sheet("TableS4_HR_MI_stratified") sheetreplace firstrow(varlabels)

**#/////HR for censoring at different years
use hr_censored, clear
drop if db == 0
gen ln_es=ln(estimate)
gen ln_lb=ln(min95)
gen ln_ub=ln(max95)
gen se = (ln_ub - ln_lb)/3.92
bysort cancer2nd parm analysis: egen mean_es=mean(ln_es) /*mean risk of 10 imputed db*/
gen u1 = (se)^2 /*se variance within each db*/
bysort cancer2nd parm: egen meanu=mean(u1) /*average variance within each db*/
gen b1 = (ln_es - mean_es)^2 /*variance across imputed dbs*/
bysort cancer2nd parm analysis: egen totalb=total(b1) /*total variance across dbs*/
bysort cancer2nd parm analysis: gen b= totalb /(10-1) /*between imputation variance = total / (m-1) where m is imputed times*/
bysort cancer2nd parm analysis: gen ta= meanu + (1+1/10) * b /*total variance considering within and between imputed*/
bysort cancer2nd parm analysis: gen tase= (ta)^0.5 /*combined standard error for risk*/
gen uci= mean_es + 1.96 * (tase)
gen lci= mean_es - 1.96 * (tase)
keep cancer2nd parm mean_es lci uci analysis
duplicates drop
gen estimate = exp(mean_es)
gen min95 = exp(lci)
gen max95 = exp(uci)
keep cancer2nd parm estimate min95 max95 analysis
drop if strpos(parm, "_rcs")>0 | strpos(parm, "ages")>0 | strpos(parm, "_cons")>0
foreach var of varlist estimate min95 max95 {
	tostring `var', gen(`var'1) force format(%4.2f)
}
gen HR = estimate1 + " (" + min951 + ", " + max951 + ")" 
keep parm HR cancer2nd analysis
gen variable = substr( parm, 1, strlen(parm) - 1) if strpos(parm, "income")>0 |  strpos(parm, "ethnic")>0 |  strpos(parm, "ydiag")>0 | strpos(parm, "tnm")>0 
gen level = substr(parm,-1,1) if variable !=""
replace level = "1" if variable == ""
replace variable = parm if variable == ""
egen censored_year = sieve(analysis), keep(numeric)
tab censored_year, m
destring censored_year, replace
drop analysis
reshape wide HR, i(parm variable level cancer2nd) j(censored_year)
drop parm
label define out 1 "Second primary cancer" 2 "Death"
label values cancer2nd out
sort cancer2nd variable level
export excel using "$res/Tables.xlsx", sheet("TableS5_HR_censoring") sheetreplace firstrow(varlabels)

**# Main figure competing risk standsurv
///*Rubin's rules from MI analysis*/
foreach c in cancer2nd_mi cif_nonbreast {
	
	use `c', clear
	drop if db == 0
	tab db, m
	foreach t in dep1 dep5 dif {
		foreach o in cancer2nd1 cancer2nd2 {
			gen se_`t'_`o'=(`t'_`o'_uci - `t'_`o'_lci) / 3.92 /*standard error for each imputed db*/
			bysort tt: egen mean_`t'_`o'=mean(`t'_`o') /*mean risk of 10 imputed db*/
			gen u1_`t'_`o' = (se_`t'_`o')^2 /*se variance within each db*/
			bysort tt: egen meanu_`t'_`o'=mean(u1_`t'_`o') /*average variance within each db*/
			gen b1_`t'_`o' = (`t'_`o'-mean_`t'_`o')^2 /*variance across imputed dbs*/
			bysort tt: egen totalb_`t'_`o'=total(b1_`t'_`o') /*total variance across dbs*/
			bysort tt: gen b_`t'_`o'= totalb_`t'_`o' /(10-1) /*between imputation variance = total / (m-1) where m is imputed times*/
			bysort tt: gen ta_`t'_`o'= meanu_`t'_`o' + (1+1/10) * b_`t'_`o' /*total variance considering within and between imputed*/
			bysort tt: gen tase_`t'_`o'= (ta_`t'_`o')^0.5 /*combined standard error for risk*/
			gen uci_`t'_`o'= mean_`t'_`o' + 1.96 * (tase_`t'_`o')
			gen lci_`t'_`o'= mean_`t'_`o' - 1.96 * (tase_`t'_`o')
		}
	}
	keep tt mean_* lci* uci*
	duplicates drop
	rename mean_* *
	rename uci_* *_uci
	rename lci_* *_lci
	save `c'1, replace
}
use cancer2nd_mi1, clear
foreach var of varlist dep1_cancer2nd1-dif_cancer2nd2_lci {
	replace `var' = `var'*100
}

preserve
foreach var of varlist dep1_cancer2nd1-dif_cancer2nd2_lci {
	tostring `var', gen(`var'1) force format(%4.1f)
}

foreach v in dep1 dep5 dif {
	forvalues i=1(1)2 {
		gen `v'_out`i' = `v'_cancer2nd`i'1 + " (" + `v'_cancer2nd`i'_lci1 + ", " + `v'_cancer2nd`i'_uci1 + ")"
	}
}

replace tt = tt + 0.5
keep tt *out*
label var dep1_out1 "The least deprived: Second primary cancer"
label var dep5_out1 "The most deprived: Second primary cancer"
label var dep1_out2 "The least deprived: Death"
label var dep5_out2 "The most deprived: Death"
label var dif_out1 "Difference: Second primary cancer"
label var dif_out2 "Difference: Death"
label var tt "Time since primary breast cancer diagnosis"
order tt dep1_out1 dep5_out1 dif_out1 dep1_out2 dep5_out2 dif_out2
keep if tt == 1 | tt == 3 | tt == 5 | tt == 10
export excel using "$res/Tables.xlsx", sheet("TableS6_cif_MI") sheetreplace firstrow(varlabels)
restore

replace tt = tt + 0.5
drop if tt>10
twoway ///
(line dep1_cancer2nd1 tt, sort lcolor(red) lwidth(vthin)) ///
(line dep5_cancer2nd1 tt, sort lcolor(red) lpattern(dash) lwidth(vvthin)) ///
(line dep1_cancer2nd2 tt, sort lcolor(black) lwidth(vthin)) ///
(line dep5_cancer2nd2 tt, sort lcolor(black) lpattern(dash) lwidth(vthin)) ///
(rarea dep1_cancer2nd1_lci dep1_cancer2nd1_uci tt, sort fcolor(red%50) lcolor(red%20)) ///
(rarea dep5_cancer2nd1_lci dep5_cancer2nd1_uci tt, sort fcolor(red%20) lcolor(red%10)) ///
(rarea dep1_cancer2nd2_lci dep1_cancer2nd2_uci tt, sort fcolor(black%50) lcolor(black%20)) ///
(rarea dep5_cancer2nd2_lci dep5_cancer2nd2_uci tt, sort fcolor(black%20) lcolor(black%10)) ///
,  legend(on ring(0) pos(11)) legend(order(5 "Least deprived: second primary cancer" 6 "Most deprived: second primary cancer" ///
7 "Least deprived: death" 8 "Most deprived: death") size(small)) ///
ylabel(0(5)45, ang(h)) ytitle("Probablity, %", size(small)) ///
xlabel(0(0.5)10, labsize(small) format(%4.1f)) xtitle("Time since primary breast cancer diagnosis, years", size(small)) ///
xsize(5.875) ysize(4.125) name(prob, replace)

twoway ///
(line dif_cancer2nd1 tt, sort lcolor(red) lwidth(vthin)) ///
(line dif_cancer2nd2 tt, sort lcolor(black) lwidth(vthin)) ///
(rarea dif_cancer2nd1_lci dif_cancer2nd1_uci tt, sort fcolor(red%50) lcolor(red%20)) ///
(rarea dif_cancer2nd2_lci dif_cancer2nd2_uci tt, sort fcolor(black%20) lcolor(black%20)) ///
,  legend(on ring(0) pos(11)) legend(order(3 "Second primary cancer" 4 "Death") size(small)) ///
ylabel(0(1)6, ang(h)) ytitle("Difference in probablity (The most vs. least deprived), %", size(small)) ///
xlabel(0(0.5)10, format(%4.1f) labsize(small)) xtitle("Time since primary breast cancer diagnosis, years", size(small)) ///
xsize(5.875) ysize(4.125) name(dif, replace)

graph combine prob dif, rows(1) xsize(11.75) ysize(4.125) name("`c'", replace)
graph export "$res/F3.svg", as(svg) replace

cap erase cancer2nd3.dta
shell ren "cif_nonbreast1.dta" "cancer2nd3.dta"
forvalues f=1/3 {
	use cancer2nd`f', clear
	cap order dif_cancer2nd2_lci, before(dif_cancer2nd2_uci)
	foreach var of varlist dep1_cancer2nd1-dif_cancer2nd2_uci {
		replace `var' = `var'*100
	}
/*
preserve
foreach var of varlist dep1_cancer2nd1-dif_cancer2nd2_uci {
	tostring `var', gen(`var'1) force format(%4.1f)
}

foreach v in dep1 dep5 dif {
	forvalues i=1(1)2 {
		gen `v'_out`i' = `v'_cancer2nd`i'1 + " (" + `v'_cancer2nd`i'_lci1 + ", " + `v'_cancer2nd`i'_uci1 + ")"
	}
}

keep tt *out*
drop out
label var dep1_out1 "The least deprived: Second primary cancer"
label var dep5_out1 "The most deprived: Second primary cancer"
label var dep1_out2 "The least deprived: Death"
label var dep5_out2 "The most deprived: Death"
label var dif_out1 "Difference: Second primary cancer"
label var dif_out2 "Difference: Death"
label var tt "Time since 6 months after breast cancer diagnosis"
order tt dep1_out1 dep5_out1 dif_out1 dep1_out2 dep5_out2 dif_out2
export excel using "Tables.xlsx", sheet("Table4_cif") sheetreplace firstrow(varlabels)
restore
*/
	replace tt = tt + 0.5
	drop if tt>10
	twoway ///
	(line dep1_cancer2nd1 tt, sort lcolor(red) lwidth(vthin)) ///
	(line dep5_cancer2nd1 tt, sort lcolor(red) lpattern(dash) lwidth(vvthin)) ///
	(line dep1_cancer2nd2 tt, sort lcolor(black) lwidth(vthin)) ///
	(line dep5_cancer2nd2 tt, sort lcolor(black) lpattern(dash) lwidth(vthin)) ///
	(rarea dep1_cancer2nd1_lci dep1_cancer2nd1_uci tt, sort fcolor(red%50) lcolor(red%20)) ///
	(rarea dep5_cancer2nd1_lci dep5_cancer2nd1_uci tt, sort fcolor(red%20) lcolor(red%10)) ///
	(rarea dep1_cancer2nd2_lci dep1_cancer2nd2_uci tt, sort fcolor(black%50) lcolor(black%20)) ///
	(rarea dep5_cancer2nd2_lci dep5_cancer2nd2_uci tt, sort fcolor(black%20) lcolor(black%10)) ///
	,  legend(on ring(0) pos(11)) legend(order(5 "Least deprived: second primary cancer" 6 "Most deprived: second primary cancer" ///
	7 "Least deprived: death" 8 "Most deprived: death") size(small)) ///
	ylabel(0(5)45, ang(h)) ytitle("Probablity, %", size(vsmall)) ///
	xlabel(0(0.5)10, ang(45) format(%4.1f) labsize(small)) xtitle("Time since primary breast cancer diagnosis, years", size(small)) ///
	xsize(5.875) ysize(4.125) name(prob_`f', replace)

	twoway ///
	(line dif_cancer2nd1 tt, sort lcolor(red) lwidth(vthin)) ///
	(line dif_cancer2nd2 tt, sort lcolor(black) lwidth(vthin)) ///
	(rarea dif_cancer2nd1_lci dif_cancer2nd1_uci tt, sort fcolor(red%50) lcolor(red%20)) ///
	(rarea dif_cancer2nd2_lci dif_cancer2nd2_uci tt, sort fcolor(black%20) lcolor(black%20)) ///
	,  legend(on ring(0) pos(11)) legend(order(3 "Second primary cancer" 4 "Death") size(small)) ///
	ylabel(0(1)6, ang(h)) ytitle("Difference in probablity (The most vs. least deprived), %", size(vsmall)) ///
	xlabel(0(0.5)10, format(%4.1f) ang(45) labsize(small)) xtitle("Time since primary breast cancer diagnosis, years", size(small)) ///
	xsize(5.875) ysize(4.125) name(dif_`f', replace)
}

graph combine prob_1 dif_1, ///
title("Analysis excluding women with missing data on ethnicity", size(small)) ///
rows(1) xsize(8.25) ysize(3.91) imargin(tiny) name(cancer2nd, replace)

graph combine prob_2 dif_2, ///
title("Analysis excluding women with missing data on ethnicity and stage", size(small)) ///
rows(1) xsize(8.25) ysize(3.91) imargin(tiny)  name(cancer2nd_cc, replace)

graph combine prob_3 dif_3, ///
title("Second primary non-breast cancer - Multiple imputation", size(small)) ///
rows(1) xsize(8.25) ysize(3.91) imargin(tiny)  name(cancer2nd_nonbreast, replace)

graph combine cancer2nd cancer2nd_cc cancer2nd_nonbreast, rows(3) imargin(tiny)  xsize(8.25) ysize(11.75)
graph export "$res/FS2.svg", as(svg) replace
/*
**# sensitivity analysis: 2012 onwards competing risk standsurv
use cancer2nd_2012, clear
append using cancer2nd
replace out = subinstr(out, "cancer2nd","",.)
replace out = subinstr(out, "_","",.)
replace out = "Main analysis" if out == ""
replace out = "Sensitivity analysis: 2012 onwards" if out == "2012"


foreach var of varlist dep1_cancer2nd1-dif_cancer2nd2_uci {
	replace `var' = `var'*100
}
drop if tt > 7

twoway ///
(line dep1_cancer2nd1 tt, sort lcolor(red) lwidth(vthin)) ///
(line dep5_cancer2nd1 tt, sort lcolor(red) lpattern(dash) lwidth(vvthin)) ///
(line dep1_cancer2nd2 tt, sort lcolor(black) lwidth(vthin)) ///
(line dep5_cancer2nd2 tt, sort lcolor(black) lpattern(dash) lwidth(vthin)) ///
(rarea dep1_cancer2nd1_lci dep1_cancer2nd1_uci tt, sort fcolor(red%50) lcolor(red%20)) ///
(rarea dep5_cancer2nd1_lci dep5_cancer2nd1_uci tt, sort fcolor(red%20) lcolor(red%10)) ///
(rarea dep1_cancer2nd2_lci dep1_cancer2nd2_uci tt, sort fcolor(black%50) lcolor(black%20)) ///
(rarea dep5_cancer2nd2_lci dep5_cancer2nd2_uci tt, sort fcolor(black%20) lcolor(black%10)) ///
, by(out, legend(on ring(0) pos(11))) ///
legend(order(5 "Least deprived: second primary cancer" 6 "Most deprived: second primary cancer" ///
7 "Least deprived: death" 8 "Most deprived: death") size(small)) ///
ylabel(0(5)45, ang(h)) ytitle("Probablity, %", size(small)) ///
xlabel(0(1)7, labsize(small)) xtitle("Time since 6 months after breast cancer diagnosis, years", size(small)) ///
xsize(5.875) ysize(4.125) name(prob, replace)

twoway ///
(line dif_cancer2nd1 tt, sort lcolor(red) lwidth(vthin)) ///
(line dif_cancer2nd2 tt, sort lcolor(black) lwidth(vthin)) ///
(rarea dif_cancer2nd1_lci dif_cancer2nd1_uci tt, sort fcolor(red%50) lcolor(red%20)) ///
(rarea dif_cancer2nd2_lci dif_cancer2nd2_uci tt, sort fcolor(black%20) lcolor(black%20)) ///
,  by(out, legend(on ring(0) pos(11))) legend(order(3 "Second primary cancer" 4 "Death") size(small)) ///
ylabel(0(1)6, ang(h)) ytitle("Difference in probablity (The most vs. least deprived), %", size(small)) ///
xlabel(0(1)7, labsize(small)) xtitle("Time since 6 months after breast cancer diagnosis, years", size(small)) ///
xsize(5.875) ysize(4.125) name(dif, replace)

graph combine prob dif, rows(1) xsize(11.75) ysize(4.125)
graph export "standsurv_2012.svg", as(svg) replace
