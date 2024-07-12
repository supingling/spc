cap log close
log using "D:\Users\MSc_students_2022_2023\Ruchika\publication\analysis_MI", replace text
display "$S_TIME  $S_DATE"
cd "D:\Users\MSc_students_2022_2023\Ruchika\publication"
set seed 20240322

**#Multiple imputation	
use db0, clear
replace tnm_stage = . if tnm_stage == 5
rcsgen agediag, gen(ages) orthog knots(5 35 65 95)

local u = 10

mi set mlong
mi register imputed ethnic tnm_stage
mi impute chained (ologit) tnm_stage (mlogit) ethnic = ///
i.incomequintile2015 ages1 ages2 ages3 i.ydiag_grp ///
curative_surg radiotherapy chemotherapy hormonetherapy cci ///
,add(`u')

local u = 10
forvalues j = 0(1)`u' {
	preserve
	mi extract `j', clear
	
	foreach var of varlist ethnic ydiag_grp incomequintile2015 tnm_stage {
		tab `var', gen(`var')
		}
		
	tempfile db`j'
	save `db`j'', replace
	restore
}
/*
**#check results if follow up 1/3/5/10/15 years
preserve
clear
tempfile hr
save `hr', emptyok replace
restore

forvalues j = 0/`u' {
	
	use `db`j'', clear
	foreach k in 1 3 5 10 15 {
		gen time`k' = `k' if time > `k'
		replace time`k' = time if time <=`k'
		gen cancer2nd`k' = cancer2nd
		replace cancer2nd`k' = 0 if cancer2nd > 0 & time > `k'
	
		forvalues i=1(1)2 {
			stset time`k', id(pseudo_patientid) f(cancer2nd`k' == `i')

			stpm2 incomequintile20152-incomequintile20155 ///
			ages1-ages3 ///
			ethnic2-ethnic4 ///
			ydiag_grp2-ydiag_grp5 ///
			cci ///
			tnm_stage2-tnm_stage4 ///
			curative_surg radiotherapy chemotherapy hormonetherapy ///
			, scale(h) df(4)
			
			preserve
			parmest, fast eform
			keep parm estimate min95 max95
			gen cancer2nd = `i'
			gen db = `j'
			gen analysis = "Fup `k' years - MI"
			append using `hr'
			save `hr', replace
			restore
		}
	}
}
preserve
use `hr', clear
save hr_censored, replace
restore

**#MI main analysis	
preserve
clear
tempfile hr
save `hr', emptyok replace
restore

preserve
clear
tempfile cif
save `cif', emptyok replace
restore

forvalues j = 0/`u' {
	use `db`j'', clear
	
	forvalues i=1(1)2 {
		stset time, id(pseudo_patientid) f(cancer2nd == `i')
		
		stpm2 incomequintile20152-incomequintile20155 ///
		ages1-ages3 ///
		ethnic2-ethnic4 ///
		ydiag_grp2-ydiag_grp5 ///
		cci ///
		tnm_stage2-tnm_stage4 ///
		curative_surg radiotherapy chemotherapy hormonetherapy ///
		, scale(h) df(4)
		preserve
		parmest, fast eform
		keep parm estimate min95 max95
		gen cancer2nd = `i'
		gen db = `j'
		gen analysis = "Fully-adjusted MI"
		append using `hr'
		save `hr', replace
		restore
		
		estimate store cancer2nd`i'
	}

	range tt 0 15 31
	
	preserve
	standsurv if ethnic2!=. & tnm_stage2!=., crmodels(cancer2nd1 cancer2nd2) contrast(difference) ///
	contrastvar(dif) ci	cif timevar(tt) verbose ///
	atvar(dep1 dep5) ///
	at1(incomequintile20151 1) ///
	at2(incomequintile20155 1)

	keep tt dep* dif*
	drop if tt ==.
	gen db = `j'
	append using `cif'
	save `cif', replace
	restore
}

preserve
use `hr', clear
save hr_mi, replace
restore

preserve
use `cif', clear
save cancer2nd_mi, replace
restore
*/

**###only non-breast cancer as the outcome
preserve
clear
tempfile hr
save `hr', emptyok replace
restore

preserve
clear
tempfile cif
save `cif', emptyok replace
restore

forvalues j = 0/`u' {
	use `db`j'', clear
	
	forvalues i=1(1)2 {
		stset time_nonbreast, id(pseudo_patientid) f(cancer2nd_nonbreast == `i')
		
		stpm2 incomequintile20152-incomequintile20155 ///
		ages1-ages3 ///
		ethnic2-ethnic4 ///
		ydiag_grp2-ydiag_grp5 ///
		cci ///
		tnm_stage2-tnm_stage4 ///
		curative_surg radiotherapy chemotherapy hormonetherapy ///
		, scale(h) df(4)
		
		preserve
		parmest, fast eform
		keep parm estimate min95 max95
		gen cancer2nd_nonbreast = `i'
		gen db = `j'
		gen analysis = "Fully-adjusted MI"
		append using `hr'
		save `hr', replace
		restore
		
		estimate store cancer2nd`i'
	}

	range tt 0 15 31
	
	preserve
	standsurv if ethnic2!=. & tnm_stage2!=., crmodels(cancer2nd1 cancer2nd2) contrast(difference) ///
	contrastvar(dif) ci	cif timevar(tt) verbose ///
	atvar(dep1 dep5) ///
	at1(incomequintile20151 1) ///
	at2(incomequintile20155 1)

	keep tt dep* dif*
	drop if tt ==.
	gen db = `j'
	append using `cif'
	save `cif', replace
	restore
}


preserve
use `hr', clear
save hr_nonbreast, replace
restore

preserve
use `cif', clear
save cif_nonbreast, replace
restore
/*
**#////test MI before and after 2012 and by age
preserve
clear
tempfile hr
save `hr', emptyok replace
restore

use db0, clear
replace tnm_stage = . if tnm_stage == 5

gen before2012 = 1 if ydiag <2012
replace before2012 = 0 if ydiag >= 2012
tab before2012, m

gen older55 = 1 if agediag >=55
replace older55 = 0 if agediag <55
tab older55, m
tempfile db
save `db', replace

foreach strata in older55 before2012 {
	
	forvalues y =0(1)1 {
		
		use `db', clear
		keep if `strata' == `y'
		gen strata1 = "`strata'"
		tempfile db0`strata'`y'
		save `db0`strata'`y'', replace
		
	}

	forvalues y = 0(1)1 {	
		use `db0`strata'`y'', clear
		
		rcsgen agediag, gen(ages) orthog knots(5 35 65 95)

		local u = 10

		mi set mlong
		mi register imputed ethnic tnm_stage
		mi impute chained (ologit) tnm_stage (mlogit) ethnic = ///
		i.incomequintile2015 ages1 ages2 ages3 i.ydiag_grp ///
		curative_surg radiotherapy chemotherapy hormonetherapy cci ///
		,add(`u')

		local u = 10
		forvalues j = 0(1)`u' {
			preserve
			mi extract `j', clear
			tempfile db`j'
			save `db`strata'`y'`j'', replace
			restore
		}

		forvalues j = 0/`u' {
			use `db`strata'`y'`j'', clear
			foreach var of varlist ethnic ydiag_grp incomequintile2015 tnm_stage {
			tab `var', gen(`var')
			}
			forvalues i=1(1)2 {
				stset time, id(pseudo_patientid) f(cancer2nd == `i')
				stpm2 incomequintile20152-incomequintile20155 ///
				ages1-ages3 ///
				, scale(h) df(4)
				
				preserve
				parmest, fast eform
				keep parm estimate min95 max95
				gen cancer2nd = `i'
				gen db = `j'
				gen `strata' = `y'
				gen analysis = "Age-adjusted MI"
				append using `hr'
				save `hr', replace
				restore
				
				if strata1 == "before2012" {
					if `y' == 1 {
						stpm2 incomequintile20152-incomequintile20155 ///
						ages1-ages3 ///
						ethnic2-ethnic4 ///
						ydiag_grp2 ydiag_grp3 ///
						cci ///
						tnm_stage2-tnm_stage4 ///
						curative_surg radiotherapy chemotherapy hormonetherapy ///
						, scale(h) df(4)
						}
					
					if `y' == 0 {
						stpm2 incomequintile20152-incomequintile20155 ///
						ages1-ages3 ///
						ethnic2-ethnic4 ///
						ydiag_grp2 ///
						cci ///
						tnm_stage2-tnm_stage4 ///
						curative_surg radiotherapy chemotherapy hormonetherapy ///
						, scale(h) df(4)	
					}
				}
				if strata1 == "older55"  {
					stpm2 incomequintile20152-incomequintile20155 ///
					ages1-ages3 ///
					ethnic2-ethnic4 ///
					ydiag_grp2-ydiag_grp5 ///
					cci ///
					tnm_stage2-tnm_stage4 ///
					curative_surg radiotherapy chemotherapy hormonetherapy ///
					, scale(h) df(4)		
				}
				
				preserve
				parmest, fast eform
				keep parm estimate min95 max95
				gen cancer2nd = `i'
				gen db = `j'
				gen `strata' = `y'
				gen analysis = "Fully-adjusted MI"
				append using `hr'
				save `hr', replace
				restore
			}
		}
	}
}
preserve
use `hr', clear
save hr_stratified, replace
restore

display "$S_TIME  $S_DATE"

log close