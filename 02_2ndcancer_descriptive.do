//////////MSc student Ruchika Breast cancer patients 1995 - 2018*////////////////
cap log close
log using "D:\Users\MSc_students_2022_2023\Ruchika\publication\analysis_descriptive", replace text
display "$S_TIME  $S_DATE"
cd "D:\Users\MSc_students_2022_2023\Ruchika\publication"
global res "C:\Users\lshsl7\OneDrive - London School of Hygiene and Tropical Medicine\Breast_2ndcancer_RG\results"

set seed 54627
use db, clear
keep pseudo_patientid diagdate radiotherapy chemotherapy curative_surg ///
hormonetherapy ydiag agediag index incomequintile2015 age_grp ethnic tnm_stage ///
ydiag_grp cancer2nd* end_date* cancer2nd_grp time *_p cci cancer2ndsite
replace cci = 1 if cci >0
egen float missing1 = rowmiss(agediag incomequintile2015 ydiag ethnic curative_surg ///
radiotherapy chemotherapy hormonetherapy cci)
tab missing1, m
egen float missing2 = rowmiss(agediag incomequintile2015 ydiag ethnic curative_surg ///
radiotherapy chemotherapy hormonetherapy cci tnm_stage)
replace missing2 = 1 if tnm_stage == 5
replace missing2 = 1 if missing2 >0
tab missing2,m

gen treatment = 1 if curative_surg == 1 & radiotherapy == 0 & chemotherapy == 0
replace treatment = 2 if curative_surg == 1 & radiotherapy == 1 & chemotherapy == 0
replace treatment = 3 if curative_surg == 1 & radiotherapy == 0 & chemotherapy == 1
replace treatment = 4 if curative_surg == 1 & radiotherapy == 1 & chemotherapy == 1
replace treatment = 5 if curative_surg == 0 & radiotherapy == 1 & chemotherapy == 0
replace treatment = 6 if curative_surg == 0 & radiotherapy == 0 & chemotherapy == 1
replace treatment = 7 if curative_surg == 0 & radiotherapy == 1 & chemotherapy == 1
replace treatment = 8 if curative_surg == 0 & radiotherapy == 0 & chemotherapy == 0

label define trt 1 "Curative surgery only" 2 "Curative surgery with radiotherapy" ///
3 "Curative surgery with chemotherapy" 4 "Curative surgery with radiotherapy and chemotherapy"  ///
5 "Radiotherapy only"  6 "Chemotherapy only" 7 "Radiotherapy and chemotherapy" ///
8 "No cancer-directed treatment"
label values treatment trt
tab treatment, m
tab treatment hormonetherapy, m

**#////Baseline characteristics by missing of ethnicity
table1_mc, by(missing1) total(after) ///
vars(ydiag_grp cat\ agediag conts %4.1f\ age_grp cat\ ethnic cat\ ///
tnm_stage cat\ cci cat\ curative_surg cat\ radiotherapy cat\ chemotherapy cat\ ///
hormonetherapy cat\ treatment cat\) one miss nospace ///
saving("$res/Tables.xlsx", sheet("TableS1_1", replace))

**#////Baseline characteristics by missing of ethnicity and stage
table1_mc, by(missing2) total(after) ///
vars(ydiag_grp cat\ agediag conts %4.1f\ age_grp cat\ ethnic cat\ ///
tnm_stage cat\ cci cat\ curative_surg cat\ radiotherapy cat\ chemotherapy cat\ ///
hormonetherapy cat\ treatment cat\) one miss nospace ///
saving("$res/Tables.xlsx", sheet("TableS1_2", replace))

**#////Table 1 baseline characteristics
table1_mc, by(incomequintile2015) total(after) ///
vars(ydiag_grp cat\ agediag conts %4.1f\ age_grp cat\ ethnic cat\ ///
tnm_stage cat\ cci cat\ curative_surg cat\ radiotherapy cat\ chemotherapy cat\ ///
hormonetherapy cat\ treatment cat\) one miss nospace ///
saving("$res/Tables.xlsx", sheet("Table1", replace))
save db0, replace

use db0, clear
*##////Table 2 Events, Rates by income 
putexcel set "Tables.xlsx", sheet(Table2_0, replace) modify
stset time, f(cancer2nd==1) id(pseudo_patientid)
stptime
putexcel B2 = `r(ptime)', nformat(number_sep) 
putexcel B3 = `r(failures)', nformat(number_sep)  
putexcel B4 = `r(rate)'*1000, nformat(number_d2)  
putexcel B5 = `r(lb)'*1000, nformat(number_d2) 
putexcel B6 = `r(ub)'*1000, nformat(number_d2) 
di "`c(ALPHA)'"
tokenize "`c(ALPHA)'"
forvalues i = 1(1)5 {
	local j = `i' + 2
	stptime if incomequintile2015 == `i'
	putexcel ``j''2 = `r(ptime)', nformat(number_sep) 
	putexcel ``j''3 = `r(failures)', nformat(number_sep)
	putexcel ``j''4 = `r(rate)'*1000, nformat(number_d2)  
	putexcel ``j''5 = `r(lb)'*1000, nformat(number_d2) 
	putexcel ``j''6 = `r(ub)'*1000, nformat(number_d2) 
}
putexcel A2 = "Person-years" A3 = "Events" A4 = "Rate" A5 = "LCI" A6 = "UCI" ///
B1 = "Total" c1 = "The least deprived" d1 = "2" e1 = "3" f1 ="4" g1 = "The most deprived"

forvalues m = 1(1)6 {
	putexcel set "Tables.xlsx", sheet(Table2_`m', replace) modify
	stset time, f(cancer2nd_grp==`m') id(pseudo_patientid)
	stptime
	putexcel B2 = `r(ptime)', nformat(number_sep) 
	putexcel B3 = `r(failures)', nformat(number_sep)  
	putexcel B4 = `r(rate)'*1000, nformat(number_d2)  
	putexcel B5 = `r(lb)'*1000, nformat(number_d2) 
	putexcel B6 = `r(ub)'*1000, nformat(number_d2) 
	di "`c(ALPHA)'"
	tokenize "`c(ALPHA)'"
	forvalues i = 1(1)5 {
		local j = `i' + 2
		stptime if incomequintile2015 == `i'
		putexcel ``j''2 = `r(ptime)', nformat(number_sep) 
		putexcel ``j''3 = `r(failures)', nformat(number_sep)
		putexcel ``j''4 = `r(rate)'*1000, nformat(number_d2)  
		putexcel ``j''5 = `r(lb)'*1000, nformat(number_d2) 
		putexcel ``j''6 = `r(ub)'*1000, nformat(number_d2) 
	}
	putexcel A2 = "Person-years" A3 = "Events" A4 = "Rate" A5 = "LCI" A6 = "UCI" ///
	B1 = "Total" c1 = "The least deprived" d1 = "2" e1 = "3" f1 ="4" g1 = "The most deprived"
}

*##////Figure 1 cummulative incidence competing risk (stcompet)
forval j = 1(1)7 {
	preserve
	clear
	tempfile npci`j' 
	save `npci`j'', replace emptyok
	restore
}

drop if incomequintile2015>1 & incomequintile2015<5
stset time, f(cancer2nd==1) id(pseudo_patientid)
sts list, risktable(0.5(1)17.5) by(incomequintile2015) atrisk0 saving(`npci1', replace)

stcompet SPCcuminc=ci high = hi low = lo, compet1(2) by(incomequintile2015)
replace _t = _t + 0.5
twoway ///
(line SPCcuminc _t if cancer2nd == 1 & incomequintile2015 == 1, sort lcolor(red)) ///
(line SPCcuminc _t if cancer2nd == 2 & incomequintile2015 == 1, sort lcolor(black)) ///
(line SPCcuminc _t if cancer2nd == 1 & incomequintile2015 == 5, sort lcolor(red%50) lpattern(dash)) ///
(line SPCcuminc _t if cancer2nd == 2 & incomequintile2015 == 5, sort lcolor(black%50) lpattern(dash)) ///
/*(rarea high low _t if cancer2nd == 1 & incomequintile2015 == 1, sort fcolor(red%70) lcolor(none)) ///
(rarea high low _t if cancer2nd == 2 & incomequintile2015 == 1, sort fcolor(black%50) lcolor(none)) ///
(rarea high low _t if cancer2nd == 1 & incomequintile2015 == 5, sort fcolor(red%30) lcolor(none)) ///
(rarea high low _t if cancer2nd == 2 & incomequintile2015 == 5, sort fcolor(black%10) lcolor(none)) ///
*/, legend(order(1 "Second primary cancer - The least deprived" 2 "Death - The least deprived" 3 "The most deprived" 4 "The most deprived") ///
rows(2) size(vsmall) pos(11) ring(0) colfirst) ///
xlabel(0(1)20, ang(45) labsize(small)) ///
xtitle("Time since primary breast cancer diagnosis, Years", size(small)) ///
ylabel(0(0.05)0.5, labsize(small) ang(h) format(%4.2f)) ///
ytitle("Cummulative incidence", size(small)) name(all, replace)

stset time, f(cancer2nd==2) id(pseudo_patientid)
sts list, risktable(0.5(1)17.5) by(incomequintile2015) atrisk0 saving(`npci7', replace)


forvalues i = 1(1)5 {
	local j = `i' + 1
	gen cancer2nd_grp`i' = 1 if cancer2nd_grp == `i'
	replace cancer2nd_grp`i' = 0 if cancer2nd_grp == 0
	replace cancer2nd_grp`i' = 2 if cancer2nd_grp > 0 & cancer2nd_grp!= `i'
	stset time, f(cancer2nd_grp`i' == 1) id(pseudo_patientid)
	*sts list, risktable(0.5(1)17.5) by(incomequintile2015) atrisk0 saving(`npci`j'', replace)
	stcompet spcgroup`i' = ci /*grp`i'_high = hi grp`i'_low = lo*/, compet1(2) by(incomequintile2015)

}

replace _t = _t + 0.5
twoway ///
(line spcgroup1 _t if cancer2nd_grp == 1 & incomequintile2015 == 1, connect(step) sort lcolor("255 175 204")) ///
(line spcgroup5 _t if cancer2nd_grp == 5 & incomequintile2015 == 1, connect(step) sort lcolor("255 191 105")) ///
(line spcgroup1 _t if cancer2nd_grp == 1 & incomequintile2015 == 5, connect(step) sort lpattern(dash)  lcolor("255 175 204")) ///
(line spcgroup5 _t if cancer2nd_grp == 5 & incomequintile2015 == 5, connect(step) sort lpattern(dash)  lcolor("255 191 105")) ///
/*(rarea high2 low2 _t if cancer2nd_grp == 1 & incomequintile2015 == 1, lcolor(none) sort fcolor("196 255 249")) ///
(rarea high2 low2 _t if cancer2nd_grp == 2 & incomequintile2015 == 1, lcolor(none) sort fcolor("156 234 239")) ///
(rarea high2 low2 _t if cancer2nd_grp == 3 & incomequintile2015 == 1, lcolor(none) sort fcolor("104 216 214")) ///
(rarea high2 low2 _t if cancer2nd_grp == 4 & incomequintile2015 == 1, lcolor(none) sort fcolor("61 204 199")) ///
(rarea high2 low2 _t if cancer2nd_grp == 5 & incomequintile2015 == 1, lcolor(none) sort fcolor("7 190 184")) ///
(rarea high2 low2 _t if cancer2nd_grp == 1 & incomequintile2015 == 5, lcolor(none) sort fcolor("255 227 224")) ///
(rarea high2 low2 _t if cancer2nd_grp == 2 & incomequintile2015 == 5, lcolor(none) sort fcolor("251 195 188")) ///
(rarea high2 low2 _t if cancer2nd_grp == 3 & incomequintile2015 == 5, lcolor(none) sort fcolor("247 163 153")) ///
(rarea high2 low2 _t if cancer2nd_grp == 4 & incomequintile2015 == 5, lcolor(none) sort fcolor("243 131 117")) ///
(rarea high2 low2 _t if cancer2nd_grp == 5 & incomequintile2015 == 5, lcolor(none) sort fcolor("239 99 81")) ///
*/, legend(order(1 "Breast cancer - The least deprived" 2 "Other cancers - The least deprived" ///
3 "The most deprived" 4 "The most deprived") ///
size(vsmall) cols(2) colfirst pos(11) ring(0)) ///
xlabel(0(1)20, ang(45) labsize(small)) ///
xtitle("Time primary breast cancer diagnosis, Years", size(small)) ///
ylabel(0(0.01)0.04, labsize(small) ang(h) format(%4.2f)) ///
ytitle("Cummulative incidence", size(small)) name(specific1, replace)

twoway ///
(line spcgroup2 _t if cancer2nd_grp == 2 & incomequintile2015 == 1, connect(step) sort lcolor("88 129 87")) ///
(line spcgroup3 _t if cancer2nd_grp == 3 & incomequintile2015 == 1, connect(step) sort lcolor("blue%50")) ///
(line spcgroup4 _t if cancer2nd_grp == 4 & incomequintile2015 == 1, connect(step) sort lcolor("181 23 158")) ///
(line spcgroup2 _t if cancer2nd_grp == 2 & incomequintile2015 == 5, connect(step) sort lpattern(dash)  lcolor("88 129 87")) ///
(line spcgroup3 _t if cancer2nd_grp == 3 & incomequintile2015 == 5, connect(step) sort lpattern(dash)  lcolor("blue%50")) ///
(line spcgroup4 _t if cancer2nd_grp == 4 & incomequintile2015 == 5, connect(step) sort lpattern(dash)  lcolor("181 23 158")) ///
/*(rarea high2 low2 _t if cancer2nd_grp == 1 & incomequintile2015 == 1, lcolor(none) sort fcolor("196 255 249")) ///
(rarea high2 low2 _t if cancer2nd_grp == 2 & incomequintile2015 == 1, lcolor(none) sort fcolor("156 234 239")) ///
(rarea high2 low2 _t if cancer2nd_grp == 3 & incomequintile2015 == 1, lcolor(none) sort fcolor("104 216 214")) ///
(rarea high2 low2 _t if cancer2nd_grp == 4 & incomequintile2015 == 1, lcolor(none) sort fcolor("61 204 199")) ///
(rarea high2 low2 _t if cancer2nd_grp == 5 & incomequintile2015 == 1, lcolor(none) sort fcolor("7 190 184")) ///
(rarea high2 low2 _t if cancer2nd_grp == 1 & incomequintile2015 == 5, lcolor(none) sort fcolor("255 227 224")) ///
(rarea high2 low2 _t if cancer2nd_grp == 2 & incomequintile2015 == 5, lcolor(none) sort fcolor("251 195 188")) ///
(rarea high2 low2 _t if cancer2nd_grp == 3 & incomequintile2015 == 5, lcolor(none) sort fcolor("247 163 153")) ///
(rarea high2 low2 _t if cancer2nd_grp == 4 & incomequintile2015 == 5, lcolor(none) sort fcolor("243 131 117")) ///
(rarea high2 low2 _t if cancer2nd_grp == 5 & incomequintile2015 == 5, lcolor(none) sort fcolor("239 99 81")) ///
*/, legend(order(1 "Cancer of female genital organs - The least deprived" ///
2 "Cancer of digestive organs - The least deprived" 3 "Cancer of respiratory and intrathoracic organs - The least deprived" ///
4 "The most deprived" ///
5 "The most deprived" 6 "The most deprived") ///
size(vsmall) cols(2) colfirst pos(11) ring(0)) ///
xlabel(0(1)20, ang(45) labsize(small)) ///
xtitle("Time primary breast cancer diagnosis, Years", size(small)) ///
ylabel(0(0.01)0.04, labsize(small) ang(h) format(%4.2f)) ///
ytitle("Cummulative incidence", size(small)) name(specific2, replace)

foreach var of varlist spcgroup* {
	replace `var' = `var'*100
}
twoway ///
(line spcgroup1 _t if cancer2nd_grp == 1 & incomequintile2015 == 1, connect(step) sort lcolor("255 175 204")) ///
(line spcgroup5 _t if cancer2nd_grp == 5 & incomequintile2015 == 1, connect(step) sort lcolor("255 191 105")) ///
(line spcgroup1 _t if cancer2nd_grp == 1 & incomequintile2015 == 5, connect(step) sort lpattern(dash)  lcolor("255 175 204")) ///
(line spcgroup5 _t if cancer2nd_grp == 5 & incomequintile2015 == 5, connect(step) sort lpattern(dash)  lcolor("255 191 105")) ///
/*(rarea high2 low2 _t if cancer2nd_grp == 1 & incomequintile2015 == 1, lcolor(none) sort fcolor("196 255 249")) ///
(rarea high2 low2 _t if cancer2nd_grp == 2 & incomequintile2015 == 1, lcolor(none) sort fcolor("156 234 239")) ///
(rarea high2 low2 _t if cancer2nd_grp == 3 & incomequintile2015 == 1, lcolor(none) sort fcolor("104 216 214")) ///
(rarea high2 low2 _t if cancer2nd_grp == 4 & incomequintile2015 == 1, lcolor(none) sort fcolor("61 204 199")) ///
(rarea high2 low2 _t if cancer2nd_grp == 5 & incomequintile2015 == 1, lcolor(none) sort fcolor("7 190 184")) ///
(rarea high2 low2 _t if cancer2nd_grp == 1 & incomequintile2015 == 5, lcolor(none) sort fcolor("255 227 224")) ///
(rarea high2 low2 _t if cancer2nd_grp == 2 & incomequintile2015 == 5, lcolor(none) sort fcolor("251 195 188")) ///
(rarea high2 low2 _t if cancer2nd_grp == 3 & incomequintile2015 == 5, lcolor(none) sort fcolor("247 163 153")) ///
(rarea high2 low2 _t if cancer2nd_grp == 4 & incomequintile2015 == 5, lcolor(none) sort fcolor("243 131 117")) ///
(rarea high2 low2 _t if cancer2nd_grp == 5 & incomequintile2015 == 5, lcolor(none) sort fcolor("239 99 81")) ///
*/, legend(order(1 "Breast cancer - The least deprived" 2 "Other cancers - The least deprived" ///
3 "The most deprived" 4 "The most deprived") ///
size(small) cols(2) colfirst pos(11) ring(0)) ///
xlabel(0(1)20, ang(45) labsize(small)) ///
xtitle("Time primary breast cancer diagnosis, Years", size(small)) ///
ylabel(0(1)4, labsize(small) ang(h) format(%4.0f)) ///
ytitle("Probability, %", size(small)) name(specific11, replace)

twoway ///
(line spcgroup2 _t if cancer2nd_grp == 2 & incomequintile2015 == 1, connect(step) sort lcolor("88 129 87")) ///
(line spcgroup3 _t if cancer2nd_grp == 3 & incomequintile2015 == 1, connect(step) sort lcolor("0 255 84")) ///
(line spcgroup4 _t if cancer2nd_grp == 4 & incomequintile2015 == 1, connect(step) sort lcolor("181 23 158")) ///
(line spcgroup2 _t if cancer2nd_grp == 2 & incomequintile2015 == 5, connect(step) sort lpattern(dash)  lcolor("88 129 87")) ///
(line spcgroup3 _t if cancer2nd_grp == 3 & incomequintile2015 == 5, connect(step) sort lpattern(dash)  lcolor("0 255 84")) ///
(line spcgroup4 _t if cancer2nd_grp == 4 & incomequintile2015 == 5, connect(step) sort lpattern(dash)  lcolor("181 23 158")) ///
/*(rarea high2 low2 _t if cancer2nd_grp == 1 & incomequintile2015 == 1, lcolor(none) sort fcolor("196 255 249")) ///
(rarea high2 low2 _t if cancer2nd_grp == 2 & incomequintile2015 == 1, lcolor(none) sort fcolor("156 234 239")) ///
(rarea high2 low2 _t if cancer2nd_grp == 3 & incomequintile2015 == 1, lcolor(none) sort fcolor("104 216 214")) ///
(rarea high2 low2 _t if cancer2nd_grp == 4 & incomequintile2015 == 1, lcolor(none) sort fcolor("61 204 199")) ///
(rarea high2 low2 _t if cancer2nd_grp == 5 & incomequintile2015 == 1, lcolor(none) sort fcolor("7 190 184")) ///
(rarea high2 low2 _t if cancer2nd_grp == 1 & incomequintile2015 == 5, lcolor(none) sort fcolor("255 227 224")) ///
(rarea high2 low2 _t if cancer2nd_grp == 2 & incomequintile2015 == 5, lcolor(none) sort fcolor("251 195 188")) ///
(rarea high2 low2 _t if cancer2nd_grp == 3 & incomequintile2015 == 5, lcolor(none) sort fcolor("247 163 153")) ///
(rarea high2 low2 _t if cancer2nd_grp == 4 & incomequintile2015 == 5, lcolor(none) sort fcolor("243 131 117")) ///
(rarea high2 low2 _t if cancer2nd_grp == 5 & incomequintile2015 == 5, lcolor(none) sort fcolor("239 99 81")) ///
*/, legend(order(1 "Cancer of female genital organs - The least deprived" ///
2 "Cancer of digestive organs - The least deprived" 3 "Cancer of respiratory and intrathoracic organs - The least deprived" ///
4 "The most deprived" ///
5 "The most deprived" 6 "The most deprived") ///
size(small) cols(2) colfirst pos(11) ring(0)) ///
xlabel(0(1)20, ang(45) labsize(small)) ///
xtitle("Time primary breast cancer diagnosis, Years", size(small)) ///
ylabel(0(1)4, labsize(small) ang(h) format(%4.0f)) ///
ytitle("Probability, %", size(small)) name(specific22, replace)
graph combine specific22 specific11, rows(1) xsize(11.75) ysize(5)
graph export "C:\Users\lshsl7\OneDrive - London School of Hygiene and Tropical Medicine\Breast_2ndcancer_RG\UICC\specific.svg", as(svg) name("Graph") replace

graph combine all specific2 specific1, rows(1) xsize(11.75) ysize(5)
graph export "$res/F1.svg", as(svg) replace

save npcummi, replace

putexcel set "$res/Tables.xlsx", sheet(F1_npci_1, replace) modify
putexcel A1 = "SES" B1 = "at" C1 = "ObsTime" D1 = "CumInc" ///
E1 = "UCI" F1 = "LCI" G1 = "Outcome"

local x = 2
forval k = 1(1)2 {
	forval j = 1(4)5 {
		forval i = 1(1)19 {
			display `x'
			putexcel A`x' = "`j'"
			putexcel B`x' = "`i'"
			qui su _t if _t<=`i' 		& incomequintile2015 == `j' & cancer2nd_grp`k' == 1
			putexcel C`x' = `r(max)'
			qui su spcgroup`k' if _t<=`i' & incomequintile2015 == `j' & cancer2nd_grp`k' == 1
			putexcel D`x' = `r(max)'
			qui su grp`k'_high if _t <= `i' 	& incomequintile2015 == `j' & cancer2nd_grp`k' == 1
			putexcel E`x' = `r(max)'
			qui su grp`k'_low if _t <= `i' 	& incomequintile2015 == `j' & cancer2nd_grp`k' == 1
			putexcel F`x' = `r(max)'
			putexcel G`x' = "`k'"
			local ++x
		}
	}
}

putexcel set "$res/Tables.xlsx", sheet(F1_npci_2, replace) modify
putexcel A1 = "SES" B1 = "at" C1 = "ObsTime" D1 = "CumInc" ///
E1 = "UCI" F1 = "LCI" G1 = "Outcome"

local x = 2
forval k = 1(1)5 {
	forval j = 1(4)5 {
		forval i = 1(1)19 {
			display `x'
			putexcel A`x' = "`j'"
			putexcel B`x' = "`i'"
			qui su _t if _t<=`i' 		& incomequintile2015 == `j' & cancer2nd_grp`k' == 1
			putexcel C`x' = `r(max)'
			qui su spcgroup`k' if _t<=`i' & incomequintile2015 == `j' & cancer2nd_grp`k' == 1
			putexcel D`x' = `r(max)'
			qui su grp`k'_high if _t <= `i' 	& incomequintile2015 == `j' & cancer2nd_grp`k' == 1
			putexcel E`x' = `r(max)'
			qui su grp`k'_low if _t <= `i' 	& incomequintile2015 == `j' & cancer2nd_grp`k' == 1
			putexcel F`x' = `r(max)'
			putexcel G`x' = "`k'"
			local ++x
		}
	}
}

tab cancer2ndsite  if cancer2nd_grp==5 & incomequintile2015 == 5, sort
tab cancer2ndsite  if cancer2nd_grp==5 & incomequintile2015 == 1, sort

use `npci1', clear
gen cancer2ndgrp = 1
forval j = 2(1)7 {
	append using `npci`j''
	replace cancer2ndgrp = `j' if cancer2ndgrp==.
}
label define out 1 "Overall SPC" 2  "Second breast cancer" ///
3 "Second cancer of female genital organs" 4 "Second cancer of digestive organs" ///
5 "Second cancer of respiratory and intrathoracic organs" ///
6 "Other second cancers" 7 "Death"
label values cancer2ndgrp out
save npci, replace
/*
**#////Figure 1 period analysis after project meeting discussion////
stset end_date, fail(cancer2nd==1) origin(time index) enter(time mdy(1, 1, 2018)) exit(time mdy(12, 31, 2018))
replace _t = ((_t - 0.5) / 365.24) + 0.5
sts list, risktable(0.5(1)18.5) by(incomequintile2015) atrisk0 saving(npci1, replace)
stcompet SPCcuminc=ci high = hi low = lo, compet1(2) by(incomequintile2015)
twoway ///
(line SPCcuminc _t if cancer2nd == 1 & incomequintile2015 == 1, sort lcolor(red)) ///
(line SPCcuminc _t if cancer2nd == 2 & incomequintile2015 == 1, sort lcolor(black)) ///
(line SPCcuminc _t if cancer2nd == 1 & incomequintile2015 == 5, sort lcolor(red%50) lpattern(dash)) ///
(line SPCcuminc _t if cancer2nd == 2 & incomequintile2015 == 5, sort lcolor(black%50) lpattern(dash)) ///
/*(rarea high low _t if cancer2nd == 1 & incomequintile2015 == 1, sort fcolor(red%70) lcolor(none)) ///
(rarea high low _t if cancer2nd == 2 & incomequintile2015 == 1, sort fcolor(black%50) lcolor(none)) ///
(rarea high low _t if cancer2nd == 1 & incomequintile2015 == 5, sort fcolor(red%30) lcolor(none)) ///
(rarea high low _t if cancer2nd == 2 & incomequintile2015 == 5, sort fcolor(black%10) lcolor(none)) ///
*/, legend(order(1 "Second primary cancer - The least deprived" 2 "Death - The least deprived" 3 "Second primary cancer - The most deprived" 4 "Death - The most deprived") ///
rows(2) size(vsmall) pos(11) ring(0) colfirst) ///
xlabel(0(1)20, ang(45) labsize(small)) ///
xtitle("Time since primary breast cancer diagnosis, Years", size(small)) ///
ylabel(0(0.05)0.5, labsize(small) ang(h) format(%4.2f)) ///
ytitle("Cummulative incidence", size(small)) name(all, replace)
stset time, f(cancer2nd==2) id(pseudo_patientid)
sts list, risktable(0.5(1)18.5) by(incomequintile2015) atrisk0 saving(npci2, replace)


forvalues i = 1(1)5 {
	gen cancer2nd_grp`i' = 1 if cancer2nd_grp == `i'
	replace cancer2nd_grp`i' = 0 if cancer2nd_grp == 0
	replace cancer2nd_grp`i' = 2 if cancer2nd_grp > 0 & cancer2nd_grp!= `i'
	stset end_date, f(cancer2nd_grp`i' == 1) id(pseudo_patientid) origin(time index) enter(time mdy(1, 1, 2018)) exit(time mdy(12, 31, 2018))
	sts list, risktable(0.5(1)18.5) by( incomequintile2015) atrisk0 saving(npci_grp`k', replace)
	stcompet spcgroup`i' = ci grp`i'_high = hi grp`i'_low = lo, compet1(2) by(incomequintile2015)

}
replace _t = _t + 0.5
twoway ///
(line spcgroup1 _t if cancer2nd_grp == 1 & incomequintile2015 == 1, connect(step) sort lcolor("188 57 8")) ///
(line spcgroup2 _t if cancer2nd_grp == 2 & incomequintile2015 == 1, connect(step) sort lcolor("255 218 185")) ///
(line spcgroup3 _t if cancer2nd_grp == 3 & incomequintile2015 == 1, connect(step) sort lcolor("240 128 128")) ///
(line spcgroup4 _t if cancer2nd_grp == 4 & incomequintile2015 == 1, connect(step) sort lcolor(blue%50)) ///
(line spcgroup5 _t if cancer2nd_grp == 5 & incomequintile2015 == 1, connect(step) sort lcolor("98 23 8")) ///
(line spcgroup1 _t if cancer2nd_grp == 1 & incomequintile2015 == 5, connect(step) sort lpattern(dash)  lcolor("188 57 8")) ///
(line spcgroup2 _t if cancer2nd_grp == 2 & incomequintile2015 == 5, connect(step) sort lpattern(dash)  lcolor("255 218 185")) ///
(line spcgroup3 _t if cancer2nd_grp == 3 & incomequintile2015 == 5, connect(step) sort lpattern(dash)  lcolor("240 128 128")) ///
(line spcgroup4 _t if cancer2nd_grp == 4 & incomequintile2015 == 5, connect(step) sort lpattern(dash)  lcolor("blue%50")) ///
(line spcgroup5 _t if cancer2nd_grp == 5 & incomequintile2015 == 5, connect(step) sort lpattern(dash)  lcolor("98 23 8")) ///
/*(rarea high2 low2 _t if cancer2nd_grp == 1 & incomequintile2015 == 1, lcolor(none) sort fcolor("196 255 249")) ///
(rarea high2 low2 _t if cancer2nd_grp == 2 & incomequintile2015 == 1, lcolor(none) sort fcolor("156 234 239")) ///
(rarea high2 low2 _t if cancer2nd_grp == 3 & incomequintile2015 == 1, lcolor(none) sort fcolor("104 216 214")) ///
(rarea high2 low2 _t if cancer2nd_grp == 4 & incomequintile2015 == 1, lcolor(none) sort fcolor("61 204 199")) ///
(rarea high2 low2 _t if cancer2nd_grp == 5 & incomequintile2015 == 1, lcolor(none) sort fcolor("7 190 184")) ///
(rarea high2 low2 _t if cancer2nd_grp == 1 & incomequintile2015 == 5, lcolor(none) sort fcolor("255 227 224")) ///
(rarea high2 low2 _t if cancer2nd_grp == 2 & incomequintile2015 == 5, lcolor(none) sort fcolor("251 195 188")) ///
(rarea high2 low2 _t if cancer2nd_grp == 3 & incomequintile2015 == 5, lcolor(none) sort fcolor("247 163 153")) ///
(rarea high2 low2 _t if cancer2nd_grp == 4 & incomequintile2015 == 5, lcolor(none) sort fcolor("243 131 117")) ///
(rarea high2 low2 _t if cancer2nd_grp == 5 & incomequintile2015 == 5, lcolor(none) sort fcolor("239 99 81")) ///
*/, legend(order(1 "Breast cancer - The least deprived" 2 "Cancer of female genital organs - The least deprived" ///
3 "Cancer of digestive organs - The least deprived" 4 "Cancer of respiratory and intrathoracic organs - The least deprived" ///
5 "Other cancers - The least deprived" 6 "Breast cancer - The most deprived" 7 "Cancer of female genital organs - The most deprived" ///
8 "Cancer of digestive organs - The most deprived" 9 "Cancer of respiratory and intrathoracic organs - The most deprived" ///
10 "Other cancers - The most deprived") size(vsmall) cols(2) colfirst pos(11) ring(0)) ///
xlabel(0(1)20, ang(45) labsize(small)) ///
xtitle("Time primary breast cancer diagnosis, Years", size(small)) ///
ylabel(0(0.01)0.03, labsize(small) ang(h) format(%4.2f)) ///
ytitle("Cummulative incidence", size(small)) name(specific, replace)

graph combine all specific, rows(1) xsize(11.75) ysize(5)
graph export "$res/F1_period.svg", as(svg) replace

forval k = 1(1)2 {
	*stset time, f(cancer2nd==`k') id(pseudo_patientid)
	forval j = 1(4)5 {
		forval i = 1(1)19 {
			qui su _t if _t<=`i' 		& incomequintile2015 == `j' & cancer2nd == `k'
			local tobs = `r(max)'
			qui su SPCcuminc if _t<=`i' & incomequintile2015 == `j' & cancer2nd == `k'
			local ciat = `r(max)'
			qui su high if _t <= `i' 	& incomequintile2015 == `j' & cancer2nd == `k'
			local uciat = `r(max)'
			qui su low if _t <= `i' 	& incomequintile2015 == `j' & cancer2nd == `k'
			local lciat = `r(max)'
			if `i'== 1 di _col(1) "SES" _col(5) "at" _col(10) "Obs Time" _col(23) "Cum Inc" _col(36) "UCI" _col(49) "LCI" _col(62) "Outcome"
			di _col(1) `j' _col(5) `i' _col(10) `tobs' _col(23) `ciat' _col(36) `uciat' _col(49) `lciat' _col(62) `k'
		}
	}
}

forval k = 1(1)5 {
	*stset time, f(cancer2nd_grp`k'==1) id(pseudo_patientid)
	*sts list, risktable(0.5(1)18.5) by(incomequintile2015) atrisk0 saving(npci_grp`k', replace)
	*replace _t = _t +0.5
	forval j = 1(4)5 {
		forval i = 1(1)19 {
			qui su _t if _t<=`i' 		& incomequintile2015 == `j' & cancer2nd_grp`k' == 1
			local tobs = `r(max)'
			qui su spcgroup`k' if _t<=`i' & incomequintile2015 == `j' & cancer2nd_grp`k' == 1
			local ciat = `r(max)'
			qui su grp`k'_high if _t <= `i' 	& incomequintile2015 == `j' & cancer2nd_grp`k' == 1
			local uciat = `r(max)'
			qui su grp`k'_low if _t <= `i' 	& incomequintile2015 == `j' & cancer2nd_grp`k' == 1
			local lciat = `r(max)'
			if `i'== 1 di _col(1) "SES" _col(5) "at" _col(10) "Obs Time" _col(23) "Cum Inc" _col(36) "UCI" _col(49) "LCI" _col(62) "Outcome"
			di _col(1) `j' _col(5) `i' _col(10) `tobs' _col(23) `ciat' _col(36) `uciat' _col(49) `lciat' _col(62) `k'
		}
	}
}
*/
display "$S_TIME  $S_DATE"
log close
