//////////MSc student Ruchika Breast cancer patients 1995 - 2018*////////////////
cap log close
log using "D:\Users\MSc_students_2022_2023\Ruchika\publication\cleaning", replace text
display "$S_TIME  $S_DATE"
global ncras "D:\Data\PHE\Cancer_registry\All_cancers_2018"
global rtds "D:\Data\PHE\RTDS\All_cancers\2018_RTDS_1995_2018"
global hes "D:\Data\PHE\HES\All_cancers"
cd "D:\Users\MSc_students_2022_2023\Ruchika\publication"
set seed 20231017
import delimited "$ncras\OfficialSensitive_2018_TUMOUR_TABLE\2018_TUMOUR_TABLE.csv", clear stringcols(1)
keep pseudo_patientid pseudo_tumourid site_icd10_o2 site_coded diagnosisdate* morph* 
keep if strpos(site_icd10_o2, "C") > 0 
drop if strpos(site_icd10_o2, "C44") >0
tempfile allcancers
save `allcancers', replace

use "$ncras\Data\Patient&Tumour_clean2.dta", clear
rename diagmdy diagdate
drop if cancer == "breast" & behav !=3
gen r = rnormal()
sort pseudo_patientid diagdate cancer r
bysort pseudo_patientid: gen n = _n 
tab n, m
keep if cancer == "breast" & n == 1  

foreach s in t n m stage {
	foreach t in img path best {
		tab `s'_`t', m
		egen `s'_`t'1 = sieve(`s'_`t'), keep(numeric) /*keep numeric characters in staging info*/
		replace `s'_`t'1 = substr(`s'_`t'1, 1, 1)  /*assume the first numeric character representing stage*/
		destring `s'_`t'1, replace
		replace `s'_`t'1 = . if `s'_`t'1>4 /*assume number > 4 is missing stage*/
		replace `s'_`t'1 = 1 if inlist(`s'_`t', "a", "A") /*assume coded with "A" is stage 1*/
		replace `s'_`t'1 = 0 if inlist(`s'_`t', "is", "IS", "Is", "iS") | strpos(`s'_`t',"is") /*assume coded with "IS" is in situ*/
		tab `s'_`t' `s'_`t'1, m
	}
	/*pathology first, then img, then best (derived)*/
	gen `s'_stage = 0 if `s'_path1 == 0 & `s'_img1 == 0 & `s'_best1 == 0
	replace `s'_stage = `s'_path1 if `s'_path1 != . & `s'_stage == .
	replace `s'_stage = `s'_img1  if `s'_img1 != .  & `s'_stage == .
	replace `s'_stage = `s'_best1 if `s'_best1 != . & `s'_stage == .
	tab `s'_stage, m
}

tab t_stage, m
tab n_stage, m
tab m_stage, m
tab stage_stage, m
/*generate stages*/
gen tnm_stage = 4 if (m_stage>0 & m_stage!=.)  /*metastases*/
replace tnm_stage = 3 if (m_stage == 0) & ///
((n_stage >=3 & n_stage !=.) | ///
(t_stage == 4 & n_stage < 3 & n_stage != .) | ///
(t_stage == 3 & n_stage >=0 & n_stage <= 2) | ///
(n_stage == 2 & t_stage >=0 & t_stage <= 2))

replace tnm_stage = 2 if (m_stage == 0) & ///
((t_stage == 2 & n_stage == 1) | ///
( t_stage == 3 & n_stage == 0) | ///
( t_stage == 2 & n_stage == 0) | ///
( t_stage >=0 & t_stage <=1 & n_stage == 0))

replace tnm_stage = 1 if (m_stage == 0) & ///
(strpos(n_img, "1mi") >0 | strpos(n_path, "1mi") >0 | strpos(n_path, "1mi") >0) & ///
(t_stage >= 0 & t_stage <= 1) 

tab tnm_stage, m
replace tnm_stage = stage_stage if (tnm_stage==. & stage_stage!=.) | (tnm_stage < stage_stage & tnm_stage!=. & stage_stage!=.) /* if missing or smaller than NCRAS, use NCRAS derived*/
tab tnm_stage, m
count if tnm_stage==. & m_stage ==. & n_stage==. & t_stage==. & stage_stage==.
replace tnm_stage = 5 if tnm_stage == .
label define stage 1 "I" 2 "II" 3 "III" 4 "IV" 5 "Missing"
label values tnm_stage stage	
label var tnm_stage "Stage"
distinct pseudo_patientid /*Initial number: first primary malignant breast cancer */
tab sitestr, m
tab sex, m
drop if ydiag < 2000 
drop if diagdate + 183 >= date("31/12/2018", "DMY") 
/*patients who diagnosed after June 2018 don't have follow-up info for SPC*/
drop if tnm_stage == 0
distinct pseudo_patientid
tempfile breast
save `breast', replace

keep pseudo_patientid diagdate
merge 1:m pseudo_patientid using `allcancers', nogen keep(mat)
gen cancer2nddate = date(diagnosisdatebest, "DMY")
tab diagnosisdateflag, m
format cancer2nddate %td

/*drop if patients had a cancer diagnosis on or before*/
distinct pseudo_patientid if cancer2nddate <= diagdate
drop if cancer2nddate == diagdate & strpos(site_icd10_o2, "C50")>0 
distinct pseudo_patientid if cancer2nddate <= diagdate
keep if cancer2nddate <= diagdate
keep pseudo_patientid
duplicates drop
distinct pseudo_patientid
merge 1:1 pseudo_patientid using `breast', nogen keep(using)
save `breast', replace

keep if sex == 2 /*Step 1: female only*/
tab diagnosisdateflag, m 
drop if diagnosisdateflag > 1 /*Step 2: drop missing diagnosis year/month*/
tab ydiag, m
tab dco, m
keep if dco == "N" /*Step 3: drop diagnosed via death certificate*/

tab behav, m
keep if behav == 3 /*Step 4: Malignant only*/
tab stage_best, m 
tab stage_best ydiag, m

count if ((finmdy < diagdate) & finmdy!=.)
count if ((finmdy == diagdate) & finmdy!=.)
count if ((diagdate<=birthmdy) & birthmdy !=.)
count if finmdy == .
count if birthmdy ==.
drop if finmdy == . | birthmdy == . /*Step 5: invalid entries for follow-up/birth*/
/*Step 6: keep certain ages only*/
drop if agediag >= 100 | agediag <18

drop ///
mob yob vitalstatusdate embarkation embarkationdate deathcausecode_2 ///
deathcausecode_1c deathcausecode_1b deathcausecode_1a deathlocationcode ///
deathlocationdesc sitecodeofdeath postmortem tumourcount bigtumourcount ///
dob flag_birth_month flag_birth_year dov mov yov flag_vital_date flag_vital ///
flag_embark_date diagnosisdate_earliest diagnosisdate_latest diagnosisdatebest ///
diagnosisdateflag basisofdiagnosis dco ///
dukes diagnosisprovider_code-screeningstatusfull_code trustcode_first_event ///
trustname_first_event trustcode_first_surgery trustname_first_surgery embarkation* ///
creg_code creg_name route_code nodesexcised nodesinvolved diagnosisdate_*   ///
diagnosisdatebest *exc* n flag_sex flag_diag_day flag_diag_month firstsurgmdy ///
chcancer cancer date_first_event date_first_surgery nmal
distinct
save `breast', replace

keep pseudo_patientid diagdate
merge 1:m pseudo_patientid using `allcancers', nogen keep(mat)
gen cancer2nddate = date(diagnosisdatebest, "DMY")
tab diagnosisdateflag, m
format cancer2nddate %td
merge m:1 pseudo_patientid using `breast', nogen keep(mat) keepusing(pseudo_patientid sitestr)
keep if cancer2nddate > diagdate
count if cancer2nddate > diagdate + 60
count if cancer2nddate > diagdate + 183
drop if cancer2nddate <= diagdate + 183
drop if site_icd10_o2 == sitestr

preserve
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

*keep only non-breast cancer as the outcome
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


distinct oacode
rename oacode oa11cd
merge m:1 oa11cd using "D:\Data\Data Dictionaries\Output_Area_to_Lower_Layer_Super_Output_Area_to_Middle_Layer_Super_Output_Area_2011.dta", keepusing(lsoa11cd) nogen keep(mat mas)
rename lsoa11cd lsoa11 
foreach y in 2015 2019 {
	merge m:1 lsoa11 using "D:\Data\Extracts\IMD\IMD`y'.dta" , keep(mat mas) nogen keepusing(incomedecile`y')
}
save `breast', replace


import delimited "$ncras\OfficialSensitive_2018_TREATMENT_TABLE\2018_TREATMENT_TABLE.csv", clear stringcols(1)
merge m:1 pseudo_patientid using `breast', keepusing(diagdate) keep(mat) nogen
tab eventdesc, m
gen curative_surg = 1 if eventcode == "01a"
gen chemotherapy = 1 if eventcode == "14" | eventcode == "02" | eventcode == "CTX"
gen radiotherapy = 1 if strpos(eventdesc, "RT - ")
gen hormonetherapy = 1 if eventcode == "03"
gen immunotherapy = 1 if eventcode == "15"
keep if curative_surg == 1 | chemotherapy == 1 |  radiotherapy == 1 | ///
 hormonetherapy == 1 |  immunotherapy == 1
 
foreach t in curative_surg chemotherapy radiotherapy hormonetherapy immunotherapy {
    preserve
	keep if `t' == 1
	gen `t'_date = date(eventdate, "DMY", 2020)
	format `t'_date %td
	drop if `t'_date == .
	gen dif = `t'_date - diagdate
	distplot dif
	keep if `t'_date > diagdate - 31 & `t'_date < diagdate + 183
	keep pseudo_patientid `t'*
	sort pseudo_patientid `t'_date
	duplicates drop pseudo_patientid, force
	merge 1:1 pseudo_patientid using `breast', nogen
	save `breast', replace
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
merge m:1 pseudo_patientid using `breast', keepusing(diagdate) keep(mat) nogen
keep if radiotherapy_date_sact > diagdate - 31 & radiotherapy_date_sact < diagdate + 183
gen radiotherapy_rtds = 1
sort pseudo_patientid radiotherapy_date_sact
duplicates drop pseudo_patientid, force
merge 1:1 pseudo_patientid using `breast', nogen
save `breast', replace

use `breast', clear
drop _merge
gen index = diagdate + 183
format index %td
count if finmdy <=index
count if dead == 1 &  finmdy <=index
drop if finmdy <=index
save db, replace

import delimited "$hes/HES_INPATIENT_00_21/2018_HES_APC_DIAG_TABLE_00_21_new.csv", encoding(UTF-8) stringcols(1 2 5 6) clear
merge m:1 pseudo_patientid using db, keepusing(index) keep(mat) nogen
tempfile hesdiag
save `hesdiag', replace 

import delimited "$hes/HES_INPATIENT_00_21/2018_HES_APC_TABLE_00_21_new.csv", encoding(UTF-8) stringcols(1 2 19 20 62 63) clear
merge m:1 pseudo_patientid using db, keepusing(index) keep(mat) nogen
keep pseudo_patientid admidate epistart epiend pseudo_epikeyanon index
duplicates drop
distinct pseudo_epikeyanon pseudo_patientid, joint
tempfile hesepi
save `hesepi', replace
use `hesdiag', clear
preserve
*Myocardial infarction
keep if inlist(substr(diag_4,1,3), "I21", "I22") | diag_4=="I252" 
tempfile mi
save `mi', replace
restore

preserve 
* Congestive heart failure
keep if inlist(diag_4,"I099","I110","I130","I132","I255","I420","I425","I426","I427") | inlist(diag_4,"I428","I429","P290") | inlist(substr(diag_4,1,3),"I43", "I50") 
tempfile hf
save `hf', replace
restore

preserve 
* Peripheral vascular disease
keep if inlist(diag_4, "I731","I738","I739","I771","I790","I792","K551","K558","K559") | inlist(diag_4,"Z958","Z959") | inlist(substr(diag_4,1,3), "I70","I71")  
tempfile pvd
save `pvd', replace
restore

preserve
* Cerebrovascular disease
keep if diag_4=="H340" | inlist(substr(diag_4,1,3),"I45","I46") | substr(diag_4, 1,2) == "I6"
tempfile cva
save `cva', replace
restore

preserve
* Dementia
keep if diag_4=="G311" | inlist(substr(diag_4,1,3),"F00","F01","F02","F03","G30")
tempfile dementia
save `dementia', replace
restore

preserve
* Chronic pulmonary disease
keep if inlist(diag_4, "I278","I279","J701","J703","J684") | ///
		inlist(substr(diag_4,1,3),"J40","J41","J42","J43","J44","J45","J46","J47") | ///
		inlist(substr(diag_4,1,3),"J60","J61","J62","J63","J64","J65","J66","J67")  
tempfile pulmonary
save `pulmonary', replace
restore

preserve	
* Connective tissue disease
keep if inlist(diag_4,"M315","M351","M353","M360") |  ///
		inlist(substr(diag_4,1,3),"M05","M06","M32","M33","M34")
tempfile tissue
save `tissue', replace
restore

preserve	
* Ulcer disease
keep if inlist(substr(diag_4,1,3),"K25","K26","K27","K28")
tempfile ulcer
save `ulcer', replace
restore

preserve
* Mild liver disease
keep if inlist(diag_4,"K700","K701","K702","K703","K709","K713","K714","K715","K717") | ///
		inlist(diag_4,"K760","K762","K763","K764","K768","K769","Z944") |  ///
		inlist(substr(diag_4,1,3),"B18","K73","K74")
tempfile mliver
save `mliver', replace
restore		

preserve
* Diabetes mellitus without chronic complication
keep if inlist(diag_4,"E100","E101","E106","E108","E109","E110","E111","E116","E118") | ///
		inlist(diag_4,"E119","E120","E121","E126","E128","E129","E130","E131","E136") | ///
		inlist(diag_4,"E138","E139","E140","E141","E146","E148","E149")		
tempfile dm
save `dm', replace
restore		

preserve
* Diabetes mellitus with chronic complications
keep if inlist(diag_4,"E102","E103","E104","E105","E107","E112","E113","E114","E115") | ///
		inlist(diag_4,"E117","E122","E123","E124","E125","E127","E132","E133","E134") | ///
		inlist(diag_4,"E135","E137","E142","E143","E144","E145","E147")		
tempfile dmc
save `dmc', replace
restore		

preserve
* Hemiplegia or paraplegia
keep if inlist(diag_4,"G041","G114","G801","G802","G830","G831","G832","G833","G834") | ///
		inlist(diag_4,"G839") |  ///
substr(diag_4,1,3)=="G81" | substr(diag_4,1,3)=="G82" 
tempfile plegia
save `plegia', replace
restore	
		
preserve
* Renal disease
keep if inlist(diag_4,"I120","I131","N032","N033","N034","N035","N036","N037","N052") | ///
		inlist(diag_4,"N053","N054","N055","N056","N057","N250","Z490","Z491","Z492") | ///
		inlist(diag_4,"Z940","Z992") | inlist(substr(diag_4,1,3),"N18","N19") 
tempfile renal
save `renal', replace
restore	
		
preserve
* Moderate/severe liver disease
keep if inlist(diag_4,"I850","I859","I864","I982","K704","K711","K721","K729","K765") | ///
		inlist(diag_4,"K766","K767")
tempfile sliver
save `sliver', replace
restore		

preserve
* AIDS/HIV No one had AIDS in this database re-check everytime
keep if inlist(substr(diag_4,1,3),"B20","B21","B22","B24")
tempfile hiv
save `hiv', replace
restore			
	
preserve
* Obesity
keep if substr(diag_4,1,3)=="E66" 
tempfile obese
save `obese', replace
restore	

foreach t in mi hf pvd cva dementia pulmonary tissue ulcer mliver dm dmc plegia renal sliver hiv obese {
	use ``t'', clear
	merge m:1 pseudo_patientid pseudo_epikeyanon using `hesepi', keep(master mat) nogen
	gen `t'_date = date(epistart, "DMY")
	keep if `t'_date >= index - (365.24*6) & `t'_date <= index - (365.24*1)

	if _N !=0 {
	keep pseudo_patientid
	duplicates drop
	}	
	gen `t'_p = 1
	merge 1:1 pseudo_patientid using db, nogen
	replace `t'_p = 0 if `t'_p == .
	save db, replace
}

gen liver_p = mliver_p
replace liver_p = 0 if mliver_p==1 & sliver_p ==1

gen dm0_p = dm_p
replace dm0_p=0 if dm_p==1 & dmc_p==1
gen cci = 1*(dm0_p + liver_p + ulcer_p + tissue_p + pulmonary_p + dementia_p + cva_p + pvd_p + hf_p + mi_p) + 2*(dmc_p + renal_p + plegia_p) + 3*(sliver_p) + 6*(hiv_p)
label variable cci "Charlson Comorbidity Index (6m - 6y before diagnosis)"
save db, replace

use db, clear
tab incomedecile2015, m
recode incomedecile2015 (1/2=5) (3/4=4) (5/6=3) (7/8=2) (9/10=1), gen(incomequintile2015)
label define income 1 "The least deprived" 5 "The most deprived"
label values incomequintile2015 income
tab incomequintile2015, m
label var incomequintile2015 "Income deprivation 2015, Quintiles"
codebook agediag
sum agediag, d
recode agediag (min/45=1) (45/55=2) (55/65=3) (65/75=4) (75/max=5), gen(age_grp)
bysort age_grp: sum agediag, d
label variable agediag "Age at diagnosis, years"
label variable age_grp "Age at diagnosis group, years"
label define age_grp 1 "18.0-44.9" 2 "45.0-54.9" 3 "55.0-64.9" 4 "65.0-74.9" 5 "75.0-99.9"
label values age_grp age_grp
tab ethnicity, m
gen ethnic = 1 if inlist(ethnicity, "A","B","C")
replace ethnic = 4 if inlist(ethnicity, "D","E","F","G","S","8")
replace ethnic = 2 if inlist(ethnicity, "H","J","K","L","R")
replace ethnic = 3 if inlist(ethnicity, "M","N","P")
tab ethnicity ethnic, m
label define ethnic 1 "White" 4 "Other" 2 "Asian" 3 "Black"
label values ethnic ethnic
label var ethnic "Ethnicity"
tab ethnicityname ethnic, m
tab ethnic, m

tab ydiag, m
tab ydiag stage_best, m
tab ydiag tnm_stage, m row /*from 2012 (or even 2014), the stage recording gets better*/
tab radiotherapy, m
replace radiotherapy = 0 if radiotherapy == .
replace radiotherapy = 1 if radiotherapy_rtds == 1
tab ydiag radiotherapy, m row
label var radiotherapy "Radiotherapy"
tab chemotherapy, m
replace chemotherapy = 0 if chemotherapy == .
tab ydiag chemotherapy, m row
label var chemotherapy "Chemotherapy"
tab curative_surg, m
replace curative_surg = 0 if curative_surg == .
tab ydiag curative_surg, m row
label var curative_surg "Curative surgery"
tab hormonetherapy, m
replace hormonetherapy = 0 if hormonetherapy == .
tab ydiag hormonetherapy, m row
label var hormonetherapy "Hormone therapy"
recode ydiag (2000/2003=1) (2004/2007=2) (2008/2011=3) (2012/2014=4) (2015/2018=5), gen(ydiag_grp)
label define ydiag_grp 1 "2000-2003" 2 "2004-2007" 3 "2008-2011" 4 "2012-2014" 5 "2015-2018"
label values ydiag_grp ydiag_grp
label var ydiag_grp "Year of diagnosis"
tab ydiag_grp, m

codebook cancer2nddate
gen censored = date("31/12/2018", "DMY")
gen cancer2nd = 1 if cancer2nddate!=.
replace cancer2nd = 2 if dead == 1 & cancer2nd==. & finmdy <= censored
egen end_date = rowmin(censored cancer2nddate finmdy)
replace cancer2nd = 0 if cancer2nd == .
label define out1 0 "Censored" 1 "Second primary cancer" 2 "Dead"
label values cancer2nd out1
tab cancer2nd, m

gen cancer2nd_nonbreast = 1 if cancer2nddate_nonbreast !=.
replace cancer2nd_nonbreast = 2 if dead == 1 & cancer2nd_nonbreast ==. & finmdy <= censored
egen end_date_nonbreast = rowmin(censored cancer2nddate_nonbreast finmdy)
replace cancer2nd_nonbreast = 0 if cancer2nd_nonbreast == .
label define out2 0 "Censored" 1 "Second non-breast primary cancer" 2 "Dead"
label values cancer2nd_nonbreast out2
tab cancer2nd_nonbreast, m

gen site = substr(cancer2ndsite, 2,2)
destring site, replace
tab site, m
gen cancer2nd_grp = 1 if site == 50
replace cancer2nd_grp = 2 if site>=51 & site<=58
replace cancer2nd_grp = 3 if site>=15 & site<=26
replace cancer2nd_grp = 4 if site>=30 & site<=39
replace cancer2nd_grp = 5 if cancer2nd == 1 & cancer2nd_grp == .
replace cancer2nd_grp = 6 if cancer2nd == 2
replace cancer2nd_grp = 0 if cancer2nd == 0
label define out2 0 "Censored" 1 "Second breast cancer" 2 "Second cancer female genital organs" ///
3 "Second cancer of digestive organs" 4 "Second cancer of respiratory and intrathoracic organs" ///
5 "Other second cancers" 6 "Dead", modify
label values cancer2nd_grp out2
tab cancer2nd_grp, m
gen time = (end_date - index) /365.24
label variable time "Follow-up time, Years"
gen time_nonbreast = (end_date_nonbreast - index) /365.24
label variable time_nonbreast "Follow-up time (non-breast), Years"
save db, replace

display "$S_TIME  $S_DATE"
log close
