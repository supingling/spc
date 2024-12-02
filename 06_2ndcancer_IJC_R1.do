display "$S_TIME  $S_DATE"
global ncras "D:\Data\PHE\Cancer_registry\All_cancers_2018"
global rtds "D:\Data\PHE\RTDS\All_cancers\2018_RTDS_1995_2018"
global hes "D:\Data\PHE\HES\All_cancers"
global res "C:\Users\lshsl7\OneDrive - London School of Hygiene and Tropical Medicine\Breast_2ndcancer_RG\manuscript\submissions\IJC\R1"
cd "D:\Users\MSc_students_2022_2023\Ruchika\publication"
**#explore definition of SPC
import delimited "$ncras\OfficialSensitive_2018_TUMOUR_TABLE\2018_TUMOUR_TABLE.csv", clear stringcols(1)
keep pseudo_patientid pseudo_tumourid site_icd10_o2 site_coded diagnosisdate* morph* laterality
keep if strpos(site_icd10_o2, "C") > 0 
drop if strpos(site_icd10_o2, "C44") >0
tempfile allcancers
save `allcancers', replace

use db, clear
keep pseudo_patientid diagdate laterality sitestr
rename laterality pbc_laterality
merge 1:m pseudo_patientid using `allcancers', nogen keep(mat)
gen cancer2nddate = date(diagnosisdatebest, "DMY")
tab diagnosisdateflag, m
format cancer2nddate %td
keep if cancer2nddate > diagdate
count if cancer2nddate > diagdate + 60
count if cancer2nddate > diagdate + 183
drop if cancer2nddate <= diagdate + 183

/*1. original definition*/
/*
preserve
drop if site_icd10_o2 == sitestr
tab diagnosisdateflag, m
sort pseudo_patientid cancer2nddate site_icd10_o2
by pseudo_patientid: gen n = _n 
keep if n == 1
keep pseudo_patientid site_icd10_o2 cancer2nddate diagnosisdateflag morph_coded
rename site_icd10_o2 cancer2ndsite
rename diagnosisdateflag cancer2nd_diagnosisdateflag
rename morph_coded cancer2nd_morphcode
merge 1:1 pseudo_patientid using `breast', nogen
save `breast', replace
restore
*/

/*2. no restriction, trust NCRAS*/
preserve
tab diagnosisdateflag, m
sort pseudo_patientid cancer2nddate site_icd10_o2
by pseudo_patientid: gen n = _n 
keep if n == 1
keep pseudo_patientid cancer2nddate site_icd10_o2
rename cancer2nddate cancer2nddate_any
gen spc_breast_any = 1 if strpos(site_icd10_o2, "C50")>0
merge 1:1 pseudo_patientid using db, nogen
save db_R1, replace
restore

/*3. contralateral breast cancer only*/
preserve
drop if (laterality == pbc_laterality & pbc_laterality != "9") ///
| laterality == "B" | pbc_laterality == "B"
/*if bilateral in PBC or SPC, consider as ipsilateral */
tab diagnosisdateflag, m
sort pseudo_patientid cancer2nddate site_icd10_o2
by pseudo_patientid: gen n = _n 
keep if n == 1
keep pseudo_patientid site_icd10_o2 cancer2nddate 
gen spc_breast_contralat= 1 if strpos(site_icd10_o2, "C50")>0
rename cancer2nddate cancer2nddate_contralat
merge 1:1 pseudo_patientid using db_R1, nogen
save db_R1, replace
restore

/*4. contralateral or different site breast cancer only*/
preserve
drop if (site_icd10_o2 == sitestr) & ///
((laterality == pbc_laterality & pbc_laterality != "9") ///
| laterality == "B" | pbc_laterality == "B")
tab diagnosisdateflag, m
sort pseudo_patientid cancer2nddate site_icd10_o2
by pseudo_patientid: gen n = _n 
keep if n == 1
keep pseudo_patientid site_icd10_o2 cancer2nddate 
gen spc_breast_contralat_difsite = 1 if strpos(site_icd10_o2, "C50")>0
rename cancer2nddate cancer2nddate_contralat_difsite
merge 1:1 pseudo_patientid using db_R1, nogen
save db_R1, replace
restore
/*
5. *keep only non-breast cancer as the outcome
drop if strpos(site_icd10_o2,"C50")>0
tab diagnosisdateflag, m
sort pseudo_patientid cancer2nddate site_icd10_o2
by pseudo_patientid: gen n = _n 
keep if n == 1
keep pseudo_patientid site_icd10_o2 cancer2nddate 
rename site_icd10_o2 cancer2ndsite_nonbreast
rename cancer2nddate cancer2nddate_nonbreast
merge 1:1 pseudo_patientid using `breast', nogen
save `breast', replace
*/

use db_R1, clear
gen cancer2nd_contralat_difsite = 1 if cancer2nddate_contralat_difsite !=.
replace cancer2nd_contralat_difsite = 2 if dead == 1 & cancer2nd_contralat_difsite ==. & finmdy <= censored
egen end_date_contralat_difsite = rowmin(censored cancer2nddate_contralat_difsite finmdy)
replace cancer2nd_contralat_difsite = 0 if cancer2nd_contralat_difsite == .
replace spc_breast_contralat_difsite = 0 if cancer2nd_contralat_difsite == 0
replace spc_breast_contralat_difsite = 2 if cancer2nd_contralat_difsite == 1 & spc_breast_contralat_difsite != 1
replace spc_breast_contralat_difsite = 3 if cancer2nd_contralat_difsite == 2
label define out6 0 "Censored" 1 "Second primary breast cancer (excluding ipsilateral and same site)" 2 "Second primary non-breast cancer" 3 "Dead", modify
label values spc_breast_contralat_difsite out6
tab spc_breast_contralat_difsite, m

gen cancer2nd_contralat = 1 if cancer2nddate_contralat !=.
replace cancer2nd_contralat = 2 if dead == 1 & cancer2nd_contralat ==. & finmdy <= censored
egen end_date_contralat = rowmin(censored cancer2nddate_contralat finmdy)
replace cancer2nd_contralat = 0 if cancer2nd_contralat == .
replace spc_breast_contralat = 0 if cancer2nd_contralat == 0
replace spc_breast_contralat = 2 if cancer2nd_contralat == 1 & spc_breast_contralat != 1
replace spc_breast_contralat = 3 if cancer2nd_contralat == 2
label define out4 0 "Censored" 1 "Second primary breast cancer (excluding ipsilateral)" 2 "Second primary non-breast cancer" 3 "Dead", modify
label values spc_breast_contralat out4
tab spc_breast_contralat, m

gen cancer2nd_any = 1 if cancer2nddate_any !=.
replace cancer2nd_any = 2 if dead == 1 & cancer2nd_any ==. & finmdy <= censored
egen end_date_any = rowmin(censored cancer2nddate_any finmdy)
replace cancer2nd_any = 0 if cancer2nd_any == .
replace spc_breast_any = 0 if cancer2nd_any == 0
replace spc_breast_any = 2 if cancer2nd_any == 1 & spc_breast_any != 1
replace spc_breast_any = 3 if cancer2nd_any == 2
label define out5 0 "Censored" 1 "Second primary breast cancer (any)" 2 "Second primary non-breast cancer" 3 "Dead", modify
label values spc_breast_any out5
tab spc_breast_any, m

gen spc_breast = 1 if strpos(cancer2ndsite, "C50")>0
replace spc_breast = 2 if spc_breast !=1 & cancer2nd == 1
replace spc_breast = 3 if cancer2nd == 2
replace spc_breast = 0 if cancer2nd == 0
label define out7 0 "Censored" 1 "Second primary breast cancer (excluding same site)" 2 "Second primary non-breast cancer" 3 "Dead", modify
label values spc_breast out7
tab spc_breast, m
label define out2 0 "Censored" 1 "Second non-breast primary cancer" 2 "Dead", modify
label values cancer2nd_nonbreast out2
save db_R1, replace

import delimited "$ncras\OfficialSensitive_2018_TREATMENT_TABLE\2018_TREATMENT_TABLE.csv", clear stringcols(1)
merge m:1 pseudo_patientid using db_R1, keepusing(diagdate) keep(mat) nogen
tab eventdesc, m
gen curative_surg_1y = 1 if eventcode == "01a"
gen chemotherapy_1y = 1 if eventcode == "14" | eventcode == "02" | eventcode == "CTX"
gen radiotherapy_1y = 1 if strpos(eventdesc, "RT - ")
gen hormonetherapy_1y = 1 if eventcode == "03"
gen immunotherapy_1y = 1 if eventcode == "15"
keep if curative_surg_1y == 1 | chemotherapy_1y == 1 |  radiotherapy_1y == 1 | ///
 hormonetherapy_1y == 1 |  immunotherapy_1y == 1
 
foreach t in curative_surg chemotherapy radiotherapy hormonetherapy immunotherapy {

   preserve
	keep if `t'_1y == 1
	gen `t'_date = date(eventdate, "DMY", 2020)
	format `t'_date %td
	drop if `t'_date == .
	gen dif = `t'_date - diagdate
	distplot dif
	keep if `t'_date > diagdate - 31 & `t'_date < diagdate + 365
	keep pseudo_patientid `t'*
	sort pseudo_patientid `t'_date
	duplicates drop pseudo_patientid, force
	merge 1:1 pseudo_patientid using db_R1, nogen
	replace `t'_1y = 0 if `t'_1y == .
	save db_R1, replace
	restore
}

import delimited "$rtds\2018_RTDS_1995_2018_OLD\2018_RTDS_1995_2018_OLD_NEW.csv", stringcols(1 2) bindquote(strict) encoding(UTF-8) clear
keep pseudo_patientid treatmentstartdate
tempfile old
save `old', replace

import delimited "$rtds\2018_RTDS_1995_2018_NEW\2018_RTDS_1995_2018_NEW_NEW.csv", stringcols(1 2) bindquote(strict) encoding(UTF-8) clear
keep pseudo_patientid treatmentstartdate
append using `old'
gen radiotherapy_date_sact = date(treatmentstartdate, "DM20Y")
keep pseudo_patientid radiotherapy_date_sact
duplicates drop
merge m:1 pseudo_patientid using db_R1, keepusing(diagdate) keep(mat) nogen
keep if radiotherapy_date_sact > diagdate - 31 & radiotherapy_date_sact < diagdate + 365
gen radiotherapy_rtds_1y = 1
sort pseudo_patientid radiotherapy_date_sact
duplicates drop pseudo_patientid, force
merge 1:1 pseudo_patientid using db_R1, nogen
replace radiotherapy_1y = 0 if radiotherapy_1y == .
replace radiotherapy_1y = 1 if radiotherapy_rtds_1y == 1
save db_R1, replace

use db_R1, clear
**#////list crude cummulative incidence for SPC and second primary breast cancer
table1_mc, by(incomequintile2015) ///
vars(spc_breast_any cat\ spc_breast_contralat cat\ ///
spc_breast_contralat_difsite cat\ spc_breast cat\ ///
cancer2nd_nonbreast cat\ ///
) one miss nospace ///
saving("$res\Tables.xlsx", sheet("SPC_definition", replace))

foreach o in any contralat contralat_difsite {
	cap drop time_`o'
	gen time_`o' = (end_date_`o' - index)/365.24
	stset time_`o', f(cancer2nd_`o'==1) id(pseudo_patientid)
	cap drop spcCI_`o'
	stcompet spcCI_`o'=ci, compet1(2) by(incomequintile2015)
	
	replace spc_breast_`o' = 2 if spc_breast_`o' >=2 
	stset time_`o', f(spc_breast_`o' ==1) id(pseudo_patientid)
	cap drop spcCI_breast_`o'
	stcompet spcCI_breast_`o'=ci, compet1(2) by(incomequintile2015)
	sort _t
	list _t spcCI_`o' if cancer2nd_`o' == 1 & incomequintile2015 == 1 & (_t>9.49 & _t<9.51)
	list _t spcCI_`o' if cancer2nd_`o' == 1 & incomequintile2015 == 5 & (_t>9.49 & _t<9.51)
	list _t spcCI_breast_`o' if spc_breast_`o' == 1 & incomequintile2015 == 1 & (_t>9.49 & _t<9.51)
	list _t spcCI_breast_`o' if spc_breast_`o' == 1 & incomequintile2015 == 5 & (_t>9.49 & _t<9.51)
}

stset time, f(cancer2nd==1) id(pseudo_patientid)
stcompet spcCI=ci, compet1(2) by(incomequintile2015)

replace spc_breast = 2 if spc_breast>=2
stset time, f(spc_breast == 1) id(pseudo_patientid)
stcompet spcCI_breast = ci, compet1(2) by(incomequintile2015)
list _t spcCI if cancer2nd == 1 & incomequintile2015 == 1 & (_t>9.49 & _t<9.51)
list _t spcCI if cancer2nd == 1 & incomequintile2015 == 5 & (_t>9.49 & _t<9.51)
list _t spcCI_breast if spc_breast == 1 & incomequintile2015 == 1 & (_t>9.49 & _t<9.51)
list _t spcCI_breast if spc_breast == 1 & incomequintile2015 == 5 & (_t>9.49 & _t<9.51)

stset time_nonbreast, f(cancer2nd_nonbreast==1) id(pseudo_patientid)
stcompet spcCI_nonbreast = ci, compet1(2) by(incomequintile2015)
list _t spcCI_nonbreast if cancer2nd_nonbreast == 1 & incomequintile2015 == 1 & (_t>9.49 & _t<9.51)
list _t spcCI_nonbreast if cancer2nd_nonbreast == 1 & incomequintile2015 == 5 & (_t>9.49 & _t<9.51)

**#///list cummulative risk for selected cancer
use db_R1, clear
gen spc_lung = 1 if strpos(cancer2ndsite, "C34")>0
gen spc_crc = 1 if strpos(cancer2ndsite, "C18")>0 | strpos(cancer2ndsite, "C19")>0 | strpos(cancer2ndsite, "C20")>0
gen spc_cervical = 1 if strpos(cancer2ndsite, "C53")>0
cap drop spc_breast
gen spc_breast = 1 if strpos(cancer2ndsite, "C50")>0

foreach c in breast lung crc cervical {
	replace spc_`c' = 2 if cancer2nd >0 & spc_`c' == .
	replace spc_`c' = 0 if cancer2nd == 0
	tab spc_`c', m
	stset time, f(spc_`c' == 1) id(pseudo_patientid)
	stcompet spcCI_`c' = ci, compet1(2) by(incomequintile2015)
}

replace _t = _t + 0.5
twoway ///
(line spcCI_breast _t if spc_breast == 1 & incomequintile2015 == 5,lpattern(dash) sort lcolor(pink%30)) ///
(line spcCI_breast _t if spc_breast == 1 & incomequintile2015 == 1, sort lcolor(pink%80)) ///
(line spcCI_crc _t if spc_crc == 1 & incomequintile2015 == 5, sort lpattern(dash)  lcolor(blue%30)) ///
(line spcCI_crc _t if spc_crc == 1 & incomequintile2015 == 1, sort lcolor(blue%80)) ///
(line spcCI_lung _t if spc_lung == 1 & incomequintile2015 == 5, sort lcolor(green%30) lpattern(dash)) ///
(line spcCI_lung _t if spc_lung == 1 & incomequintile2015 == 1, sort lcolor(green%80)) ///
(line spcCI_cervical _t if spc_cervical == 1 & incomequintile2015 == 5, sort lpattern(dash)  lcolor(gold%80)) ///
(line spcCI_cervical _t if spc_cervical == 1 & incomequintile2015 == 1, sort lcolor(gold%80)) ///
, legend(order(2 " " 4 " " 6 " " 8 " " 1 "Breast cancer" 3 "Colorectal cancer" ///
5 "Lung cancer" 7 "Cervical cancer") ///
size(vsmall) cols(2) colfirst pos(11) ring(0)) ///
xlabel(0(1)20, ang(45) labsize(small)) ///
xtitle("Time since primary breast cancer diagnosis, Years", size(small)) ///
ylabel(0(0.01)0.04, labsize(small) ang(h) format(%4.2f)) ///
ytitle("Cummulative incidence", size(small)) name(specific1, replace)
graph export "$res/specific_cancer.svg", as(svg) replace

**#///treatment data update to 1 year
table1_mc, total(after) by(incomequintile2015) ///
vars(curative_surg bin\ curative_surg_1y bin\ ///
radiotherapy bin\ radiotherapy_1y bin\ ///
chemotherapy bin\ chemotherapy_1y bin\ ///
hormonetherapy bin\  hormonetherapy_1y bin\ ) ///
one miss nospace ///
saving("$res\Tables.xlsx", sheet("treatment_1y", replace))

use db_R1, clear
replace tnm_stage = . if tnm_stage == 5
rcsgen agediag, gen(ages) orthog knots(5 35 65 95)

local u = 10

mi set mlong
mi register imputed ethnic tnm_stage
mi impute chained (ologit) tnm_stage (mlogit) ethnic = ///
i.incomequintile2015 ages1 ages2 ages3 i.ydiag_grp ///
curative_surg_1y radiotherapy_1y chemotherapy_1y hormonetherapy_1y cci ///
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

preserve
clear
tempfile hr
save `hr', emptyok replace
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
		curative_surg_1y radiotherapy_1y chemotherapy_1y hormonetherapy_1y ///
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
	}
}

preserve
use `hr', clear
save hr_mi_1ytreatment, replace
restore

use hr_mi_1ytreatment, clear
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
foreach var of varlist estimate min95 max95 {
	tostring `var', gen(`var'1) force format(%4.2f)
}
gen HR = estimate1 + " (" + min951 + ", " + max951 + ")" 

