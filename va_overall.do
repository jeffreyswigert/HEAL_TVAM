/******************************************************************
This do-file computes and analyzes combined measures of therapist value added, from each of the six
om_scale_id's we evaluated them on. 

		 "Measuring Therapist Value-Added: Evidence from an Online Therapy Platform"

Coded by: Mitchell Zufelt


***********************************************************************
***********************************************************************
*********************************************************************
*********************************************************************/
clear
cd $analysis

global X_1 i.client_edu_lvl i.missing_edu i.client_gender i.missing_gender i.client_ethnicity i.missing_ethnicity i.client_marital_status i.missing_marrital i.client_age i.missing_age i.client_country i.client_state
global p_char b2.therapist_license_type i.therapist_pro_degree i.therapist_dbt i.therapist_cbt i.therapist_mbct i.therapist_mi i.therapist_ptsd i.therapist_relational i.therapist_emotionally i.therapist_psychoanalytic i.therapist_gender b4.therapist_experience t_age
global interaction_char time_to_complete_total media_total_duration_secs_audio media_total_duration_secs_photo media_total_duration_secs_video
global match_char i.gender_match i.age_match firstscore 

*****1: Create combined measures of therapist value-added (weighted average across each om_scale_id)*****

foreach i of numlist 1,2,3,4,5,47 {
	
	use "working_om_`i'.dta", clear

	bysort therapist_id : gen client_count = _N

	drop if therapist_id == therapist_id[_n-1]

	save "summary_om_`i'.dta", replace
	}

use "summary_om_1.dta", clear
foreach k of numlist 2,3,4,5,47 {
    append using "summary_om_`k'"
	}

save "summary_placehold.dta", replace //Saving this so it can be used in later reporting of summary statistics.
keep therapist_id therapist_effect client_count 

bys therapist_id : egen wgt_therapist_effect = wtmean(therapist_effect), weight(client_count)
drop if therapist_id == therapist_id[_n-1]
keep therapist_id wgt_therapist_effect

cd $data
save "va_overall.dta", replace

*****2: Analyze and Report*****

cd $reporting

**2.1: Histogram of VA Distribution

histogram wgt_therapist_effect, bin(50) fcolor(navy) xscale(range(-3 3)) title(Therapist VA Distribution) xtitle(Therapist Value-Added)
graph save "Graph" "VA_distribution_overall.gph", replace

sum wgt_therapist_effect, detail
scalar outlier = 1.5* (r(p75)-r(p25))
drop if wgt_therapist_effect > (r(p75)+outlier) | wgt_therapist_effect < (r(p25)- outlier)

histogram wgt_therapist_effect, bin(25) fcolor(navy) xtitle(Therapist Value-Added) xscale(range(-3 3)) title("Therapist VA Distribution (Outliers Omitted)")
graph save "Graph" "VA_distribution_nooutliers_overall.gph", replace


**2.2: Mean Gain Scores

cd $data
use "va_overall.dta", clear
cd $reporting

xtile quartile = wgt_therapist_effect, nq(4)
cibar wgt_therapist_effect , over(quartile) level(95) bargap(5) 
graph save "Graph" "mean_VA_by_quartile_overall.gph", replace

**2.3 Therapist Descriptives
//and self reported specialties
cd $analysis
use "summary_placehold.dta", clear

sort therapist_id
drop if therapist_id == therapist_id[_n-1]
keep therapist_*

cd $reporting

clear matrix
forvalues i=1/3 {
	mat A`i' = J(9,1,.)
}

estpost tab therapist_license_type
mat x = e(b)
mat y = e(pct)
mat z = e(cumpct)

forvalues i = 1/9 {
	scalar x`i' = x[1,`i']
	scalar y`i' = y[1,`i']
}

forvalues i = 1/9 {
	if `i' < 9 {
		scalar z`i' = z[1,`i']
	}
	else {
		scalar z`i' = .
	}
} 

local n 1
forvalues i = 1/9 {
	mat A1[`n',1]= x`i'
	mat A2[`n',1]= y`i'
	mat A3[`n',1]= z`i'
	local ++n
}
scalar drop _all

matrix rownames A1= "LCSW" "Psychologist" "LPC" "LMFT" "LMHC" "LCPC" "LPCC" "Other" "Total"
frmttable, statmat(A1) replace sdec(0) title("License Type") ctitles("","N")
frmttable, statmat(A2) replace sdec(2) merge ctitles("Pct")
frmttable, statmat(A3) replace sdec(2) merge ctitles("Cum Pct")
frmttable using "t_descriptives_overall.doc" , replay replace

///////////////
clear matrix
forvalues i=1/3 {
	mat A`i' = J(8,1,.)
}

estpost tab therapist_pro_degree
mat x = e(b)
mat y = e(pct)
mat z = e(cumpct)

forvalues i = 1/8 {
	scalar x`i' = x[1,`i']
	scalar y`i' = y[1,`i']
}

forvalues i = 1/8 {
	if `i' < 8 {
		scalar z`i' = z[1,`i']
	}
	else {
		scalar z`i' = .
	}
} 

local n 1
forvalues i = 1/8 {
	mat A1[`n',1]= x`i'
	mat A2[`n',1]= y`i'
	mat A3[`n',1]= z`i'
	local ++n
}
scalar drop _all

matrix rownames A1= "M Social Work" "M Counseling" "M Counseling Psychology" "M Marriage and FT" "M Psychology" "PhD or PsyD" "Other" "Total"
frmttable, statmat(A1) replace sdec(0) title("Professional Degree") ctitles("","N")
frmttable, statmat(A2) replace sdec(2) merge ctitles("Pct")
frmttable, statmat(A3) replace sdec(2) merge ctitles("Cum Pct")
frmttable using "t_descriptives_overall.doc" , addtable replace

///////////////
clear matrix
forvalues i=1/3 {
	mat A`i' = J(5,1,.)
}

estpost tab therapist_experience
mat x = e(b)
mat y = e(pct)
mat z = e(cumpct)

forvalues i = 1/5 {
	scalar x`i' = x[1,`i']
	scalar y`i' = y[1,`i']
}

forvalues i = 1/5 {
	if `i' < 5 {
		scalar z`i' = z[1,`i']
	}
	else {
		scalar z`i' = .
	}
} 

local n 1
forvalues i = 1/5 {
	mat A1[`n',1]= x`i'
	mat A2[`n',1]= y`i'
	mat A3[`n',1]= z`i'
	local ++n
}
scalar drop _all

matrix rownames A1= "No Real Exp Yet" "Less Than 5 Yrs" "5-10 Yrs" "More Than 10 Yrs" "Total"
frmttable, statmat(A1) replace sdec(0) title("Experience") ctitles("","N")
frmttable, statmat(A2) replace sdec(2) merge ctitles("Pct")
frmttable, statmat(A3) replace sdec(2) merge ctitles("Cum Pct")
frmttable using "t_descriptives_overall.doc" , addtable replace

///////////////
clear matrix
forvalues i=1/3 {
	mat A`i' = J(4,1,.)
}

estpost tab therapist_pro_degree
mat x = e(b)
mat y = e(pct)
mat z = e(cumpct)

forvalues i = 1/4 {
	scalar x`i' = x[1,`i']
	scalar y`i' = y[1,`i']
}

forvalues i = 1/4 {
	if `i' < 4 {
		scalar z`i' = z[1,`i']
	}
	else {
		scalar z`i' = .
	}
} 

local n 1
forvalues i = 1/4 {
	mat A1[`n',1]= x`i'
	mat A2[`n',1]= y`i'
	mat A3[`n',1]= z`i'
	local ++n
}
scalar drop _all

matrix rownames A1= "Female" "Male" "Other" "Total"
frmttable, statmat(A1) replace sdec(0) title("Gender") ctitles("","N")
frmttable, statmat(A2) replace sdec(2) merge ctitles("Pct")
frmttable, statmat(A3) replace sdec(2) merge ctitles("Cum Pct")
frmttable using "t_descriptives_overall.doc" , addtable replace

///////////////
clear matrix
forvalues i=1/3 {
	mat A`i' = J(6,1,.)
}

estpost tab therapist_pro_degree
mat x = e(b)
mat y = e(pct)
mat z = e(cumpct)

forvalues i = 1/6 {
	scalar x`i' = x[1,`i']
	scalar y`i' = y[1,`i']
}

forvalues i = 1/6 {
	if `i' < 6 {
		scalar z`i' = z[1,`i']
	}
	else {
		scalar z`i' = .
	}
} 

local n 1
forvalues i = 1/6 {
	mat A1[`n',1]= x`i'
	mat A2[`n',1]= y`i'
	mat A3[`n',1]= z`i'
	local ++n
}
scalar drop _all

matrix rownames A1= "missing" "18-25" "26-35" "36-49" "50+" "Total"
frmttable, statmat(A1) replace sdec(0) title("Age") ctitles("","N")
frmttable, statmat(A2) replace sdec(2) merge ctitles("Pct")
frmttable, statmat(A3) replace sdec(2) merge ctitles("Cum Pct")
frmttable using "t_descriptives_overall.doc" , addtable replace

////Self-Reported Specialties
clear matrix
forvalues i=1/2 {
	mat A`i' = J(8,1,.)
}

qui sum therapist_cbt
scalar allobs=r(N)
local specialties therapist_dbt therapist_cbt therapist_mbct therapist_mi therapist_ptsd therapist_relational therapist_emotionally therapist_psychoanalytic
local n 1
foreach var of local specialties {
	count if `var'
	mat A1[`n',1]=r(N)
	mat A2[`n',1]=((r(N)/allobs)*100)
	local ++n
} 

matrix rownames A1 = "DBT" "CBT" "MBCT" "MI" "PTSD" "Relational" "Emotional" "Psychoanalytic"
frmttable, statmat(A1) replace sdec(0) title("Therapist Specialties") ctitles(" ", "Count") 
frmttable, statmat(A2) replace sdec(2) merge ctitles("pct")
frmttable using "specialties_overall.doc", replay replace


**2.4 Client Descriptives 
cd $data
use "vam_analysis_sample.dta", clear
keep if om_scale_id == 1 | om_scale_id == 2 | om_scale_id == 3 | om_scale_id == 4 | om_scale_id == 5 | om_scale_id == 47
keep client_demo_user_id client_edu_lvl client_gender client_ethnicity client_marital_status client_age client_country
sort client_demo_user_id
drop if client_demo_user_id == client_demo_user_id[_n-1]

cd $reporting

clear matrix
forvalues i=1/3 {
	mat A`i' = J(10,1,.)
}


estpost tab client_edu_lvl
mat x = e(b)
mat y = e(pct)
mat z = e(cumpct)

forvalues i = 1/10 {
	scalar x`i' = x[1,`i']
	scalar y`i' = y[1,`i']
}

forvalues i = 1/10 {
	if `i' < 10 {
		scalar z`i' = z[1,`i']
	}
	else {
		scalar z`i' = .
	}
} 

local n 1
forvalues i = 1/10 {
	mat A1[`n',1]= x`i'
	mat A2[`n',1]= y`i'
	mat A3[`n',1]= z`i'
	local ++n
}
scalar drop _all

matrix rownames A1= "3" "4" "5" "6" "7" "8" "High School" "Bachelor Degree or Higher" "NA" "Total"
frmttable, statmat(A1) replace sdec(0) title("Education Level") ctitles("","N")
frmttable, statmat(A2) replace sdec(2) merge ctitles("Pct")
frmttable, statmat(A3) replace sdec(2) merge ctitles("Cum Pct")
frmttable using "c_descriptives_overall.doc" , replay replace

///////////////
clear matrix
forvalues i=1/3 {
	mat A`i' = J(9,1,.)
}

estpost tab client_gender
mat x = e(b)
mat y = e(pct)
mat z = e(cumpct)

forvalues i = 1/9 {
	scalar x`i' = x[1,`i']
	scalar y`i' = y[1,`i']
}

forvalues i = 1/9 {
	if `i' < 9 {
		scalar z`i' = z[1,`i']
	}
	else {
		scalar z`i' = .
	}
} 

local n 1
forvalues i = 1/9 {
	mat A1[`n',1]= x`i'
	mat A2[`n',1]= y`i'
	mat A3[`n',1]= z`i'
	local ++n
}
scalar drop _all

matrix rownames A1= "Female" "Male" "Other" "Queer" "Non-Binary" "Transgender Female" "Transgender Male" "NA" "Total"
frmttable, statmat(A1) replace sdec(0) title("Gender") ctitles("","N")
frmttable, statmat(A2) replace sdec(2) merge ctitles("Pct")
frmttable, statmat(A3) replace sdec(2) merge ctitles("Cum Pct")
frmttable using "c_descriptives_overall.doc" , addtable replace

///////////////
clear matrix
forvalues i=1/3 {
	mat A`i' = J(9,1,.)
}

estpost tab client_ethnicity
mat x = e(b)
mat y = e(pct)
mat z = e(cumpct)

forvalues i = 1/9 {
	scalar x`i' = x[1,`i']
	scalar y`i' = y[1,`i']
}

forvalues i = 1/9 {
	if `i' < 9 {
		scalar z`i' = z[1,`i']
	}
	else {
		scalar z`i' = .
	}
} 

local n 1
forvalues i = 1/9 {
	mat A1[`n',1]= x`i'
	mat A2[`n',1]= y`i'
	mat A3[`n',1]= z`i'
	local ++n
}
scalar drop _all

matrix rownames A1= "Caucasian" "Black" "Asian" "Hispanic" "Native American" "Other" "Declined" "NA" "Total"
frmttable, statmat(A1) replace sdec(0) title("Ethnicity") ctitles("","N")
frmttable, statmat(A2) replace sdec(2) merge ctitles("Pct")
frmttable, statmat(A3) replace sdec(2) merge ctitles("Cum Pct")
frmttable using "c_descriptives_overall.doc" , addtable replace

///////////////
clear matrix
forvalues i=1/3 {
	mat A`i' = J(9,1,.)
}

estpost tab client_marital_status
mat x = e(b)
mat y = e(pct)
mat z = e(cumpct)

forvalues i = 1/9 {
	scalar x`i' = x[1,`i']
	scalar y`i' = y[1,`i']
}

forvalues i = 1/9 {
	if `i' < 9 {
		scalar z`i' = z[1,`i']
	}
	else {
		scalar z`i' = .
	}
} 

local n 1
forvalues i = 1/9 {
	mat A1[`n',1]= x`i'
	mat A2[`n',1]= y`i'
	mat A3[`n',1]= z`i'
	local ++n
}
scalar drop _all

matrix rownames A1= "Single" "Married" "Living w/ Partner" "In a Relationship" "Divorced" "Separated" "Widowed" "NA" "Total"
frmttable, statmat(A1) replace sdec(0) title("Marital Status") ctitles("","N")
frmttable, statmat(A2) replace sdec(2) merge ctitles("Pct")
frmttable, statmat(A3) replace sdec(2) merge ctitles("Cum Pct")
frmttable using "c_descriptives_overall.doc" , addtable replace

///////////////
clear matrix
forvalues i=1/3 {
	mat A`i' = J(7,1,.)
}

estpost tab client_age
mat x = e(b)
mat y = e(pct)
mat z = e(cumpct)

forvalues i = 1/7 {
	scalar x`i' = x[1,`i']
	scalar y`i' = y[1,`i']
}

forvalues i = 1/7 {
	if `i' < 7 {
		scalar z`i' = z[1,`i']
	}
	else {
		scalar z`i' = .
	}
} 

local n 1
forvalues i = 1/7 {
	mat A1[`n',1]= x`i'
	mat A2[`n',1]= y`i'
	mat A3[`n',1]= z`i'
	local ++n
}
scalar drop _all

matrix rownames A1= "0-17" "18-25" "26-35" "36-49" "50+" "NA" "Total"
frmttable, statmat(A1) replace sdec(0) title("Age") ctitles("","N")
frmttable, statmat(A2) replace sdec(2) merge ctitles("Pct")
frmttable, statmat(A3) replace sdec(2) merge ctitles("Cum Pct")
frmttable using "c_descriptives_overall.doc" , addtable replace

///////////////
clear matrix
forvalues i=1/3 {
	mat A`i' = J(5,1,.)
}

estpost tab client_country
mat x = e(b)
mat y = e(pct)
mat z = e(cumpct)

forvalues i = 1/5 {
	scalar x`i' = x[1,`i']
	scalar y`i' = y[1,`i']
}

forvalues i = 1/5 {
	if `i' < 5 {
		scalar z`i' = z[1,`i']
	}
	else {
		scalar z`i' = .
	}
} 

local n 1
forvalues i = 1/5 {
	mat A1[`n',1]= x`i'
	mat A2[`n',1]= y`i'
	mat A3[`n',1]= z`i'
	local ++n
}
scalar drop _all

matrix rownames A1= "US" "CA" "GB" "Other" "Total"
frmttable, statmat(A1) replace sdec(0) title("Country") ctitles("","N")
frmttable, statmat(A2) replace sdec(2) merge ctitles("Pct")
frmttable, statmat(A3) replace sdec(2) merge ctitles("Cum Pct")
frmttable using "c_descriptives_overall.doc" , addtable replace

**2.5 Therapist VA Descriptives
cd $data 
use "va_overall.dta", clear
xtile quartile = wgt_therapist_effect, nq(4)

cd $reporting 

clear matrix
forvalues i=1/6 {
	mat A`i' = J(5,1,.)
}

qui sum wgt_therapist_effect 
mat A1[1,1]=r(N)
mat A2[1,1]=r(mean)
mat A3[1,1]=r(sd)
mat A4[1,1]=r(min)
mat A5[1,1]=r(max)
mat A6[1,1]=(r(max)-r(min))

local n 2
forvalues k = 1/4 {
	qui sum wgt_therapist_effect if quartile == `k'
	mat A1[`n',1]=r(N)
	mat A2[`n',1]=r(mean)
	mat A3[`n',1]=r(sd)
	mat A4[`n',1]=r(min)
	mat A5[`n',1]=r(max)
	mat A6[`n',1]=(r(max)-r(min))
	local ++n
}

matrix rownames A1= "Total" "1st Quartile" "2nd Quartile" "3rd Quartile" "4th Quartile"
frmttable, statmat(A1) replace sdec(0) title("Therapist Value-Added") ctitles(" ", "N")
frmttable, statmat(A2) replace sdec(3) merge ctitles("Mean")
frmttable, statmat(A3) replace sdec(3) merge ctitles("Std. Dev.")
frmttable, statmat(A4) replace sdec(3) merge ctitles("Min")
frmttable, statmat(A5) replace sdec(3) merge ctitles("Max")
frmttable, statmat(A6) replace sdec(3) merge ctitles("Range")
frmttable using "VA_summary_overall.doc" , replay replace


**2.6 Causal effect of therapist VA on client outcomes

/*
cd $analysis
use "working_om_1.dta", clear
foreach i of numlist 2,3,4,5,47 {
    append using "working_om_`i'.dta"
}

sort therapist_id om_scale_id
drop client_specific zclient_specific zoverall_improvement


bys therapist_id : gen total = sum(overall_improvement)

order therapist_id overall_improvement total

by therapist_id : replace total = total[_N]

by therapist_id : gen tcount = _N
order therapist_id overall_improvement total tcount

gen client_specific = (total-overall_improvement)/(tcount-1)
order therapist_id overall_improvement total tcount client_specific

drop total tcount 
egen zclient_specific = std(client_specific)


qui reg overall_improvement zclient_specific 
outreg2 using va_effect_overall, replace excel dec(3) label

qui reg overall_improvement zclient_specific $X_1 
outreg2 using va_effect_overall, append excel dec(3) label

qui reg overall_improvement zclient_specific $X_1 $match_char
outreg2 using va_effect_overall, append excel dec(3) label

***Basically, the effect of a therapist's avg effect on clients on any specific client (ie, if you're assigned to a therapist w such-and-such an average effect on his clients (zclient_specific), what can you expect your outcome to be (in terms of overall_improvement)?))
*/



cd $analysis
use "working_om_1.dta", clear
foreach i of numlist 2,3,4,5,47 {
    append using "working_om_`i'.dta"
}

sort therapist_id om_scale_id
drop client_specific zclient_specific zoverall_improvement

cd $data
merge m:1 therapist_id using "va_overall.dta"
order therapist_id wgt_therapist_effect overall_improvement 

cd $reporting

qui reg overall_improvement wgt_therapist_effect
outreg2 using va_effect_overall, replace excel dec(3) label

qui reg overall_improvement wgt_therapist_effect $X_1
outreg2 using va_effect_overall, append excel dec(3) label

qui reg overall_improvement wgt_therapist_effect $X_1 $match_char
outreg2 using va_effect_overall, append excel dec(3) label

**Basically, the effect of therapist VA score on client overall improvement. Really solid results, but the exogeneity check below makes me nervous. 

**2.7: Exploring exogeneity of therapist assignment

qui reg wgt_therapist_effect $X_1
eststo sprite
outreg2 sprite using exogenous_assignment_overall.xls, replace title("Regression of Therapist VA on Client Characteristics") label






