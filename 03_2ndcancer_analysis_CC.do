//////////MSc student Ruchika Breast cancer patients 1995 - 2018*////////////////
cap log close
log using "D:\Users\MSc_students_2022_2023\Ruchika\publication\analysis_CC", replace text
display "$S_TIME  $S_DATE"
cd "D:\Users\MSc_students_2022_2023\Ruchika\publication"
global res "C:\Users\lshsl7\OneDrive - London School of Hygiene and Tropical Medicine\Breast_2ndcancer_RG\results"
set seed 54627

preserve
clear
tempfile hr
save `hr', emptyok replace
restore

use db0, clear
**#age-adjusted model
rcsgen agediag, gen(ages) orthog knots(5 35 65 95)
global Kage `r(knots)'
matrix Mage = r(R)
foreach var of varlist ethnic ydiag_grp incomequintile2015 tnm_stage {
	tab `var', gen(`var')
}



forvalues i=1(1)2 {
	stset time, id(pseudo_patientid) f(cancer2nd == `i')

	stpm2 incomequintile20152 incomequintile20153 incomequintile20154 incomequintile20155 ///
	ages1 ages2 ages3, scale(h) df(4)
	preserve
	parmest, fast eform
	keep parm estimate min95 max95
	gen cancer2nd = `i'
	gen analysis = "Age-adjusted"
	append using `hr'
	save `hr', replace
	restore
}

**#fully-adjusted model: complete case analysis 1 & 2
forvalues c = 1/2 {
	use db0, clear
	keep if missing`c' == 0 
	rcsgen agediag, gen(ages) orthog knots(5 35 65 95)
	global Kage `r(knots)'
	matrix Mage = r(R)

	foreach var of varlist ethnic ydiag_grp incomequintile2015 tnm_stage {
		tab `var', gen(`var')
	}

	forvalues i=1(1)2 {
		local x = 6 - `c'
		stset time, id(pseudo_patientid) f(cancer2nd == `i')

		stpm2 incomequintile20152-incomequintile20155 ///
			ages1-ages3 ///
			ethnic2-ethnic4 ///
			ydiag_grp2-ydiag_grp5 ///
			cci ///
			tnm_stage2-tnm_stage`x' ///
			curative_surg radiotherapy chemotherapy hormonetherapy ///
			, scale(h) df(4)
			preserve
			parmest, fast eform
			keep parm estimate min95 max95
			gen cancer2nd = `i'
			gen analysis = "Fully-adjusted_cc`c'"
			append using `hr'
			save `hr', replace
			restore
			
			estimate store cancer2nd`i'
	}
	
	range tt 0 15 31
	preserve
	standsurv, crmodels(cancer2nd1 cancer2nd2) contrast(difference) ///
	contrastvar(dif) ci	cif timevar(tt) verbose ///
	atvar(dep1 dep5) ///
	at1(incomequintile20151 1) ///
	at2(incomequintile20155 1)
	
	keep tt dep* dif*
	drop if tt ==.
	gen out = "cancer2nd_c`c'"
	save cancer2nd`c', replace
	restore
	
	
}
use `hr', clear
save hr_cc, replace

display "$S_TIME  $S_DATE"
log close
