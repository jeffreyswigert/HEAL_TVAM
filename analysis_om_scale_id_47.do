/******************************************************************
This performs VA analysis on the subsection of vam_analysis_sample.dta where om_scale_id == 47. 

		For "Measuring Therapist Value-Added: Evidence from an Online Therapy Platform"

Coded by: Mitchell Zufelt


INPUTS: 
		- vam_analysis_sample.dta
	
***********************************************************************
***********************************************************************
*********************************************************************
*********************************************************************/
clear
set more off

use "vam_analysis_sample.dta"
cap mkdir tvam_47
cd tvam_47
cap mkdir reporting_47

keep if om_scale_id == 47

//Create room_id_by_p, which identifies each unique client-therapist interaction. (Some of the room_id's have multiple "count's" for the om_scale_id (meaning they have more than one assessment marked as the first time taking it, or the second, or third). This is because the count restarts when a client switches therapists, but the room_id does not.)
gen room_id_placehold = 1, after(room_id)
replace room_id_placehold = 2 if therapist_id != therapist_id[_n-1] & room_id == room_id[_n-1]  
replace room_id_placehold = 2 if room_id_placehold[_n-1] == 2 & room_id == room_id[_n-1]
replace room_id_placehold = 3 if room_id_placehold[_n-1] == 2 & therapist_id != therapist_id[_n-1] & room_id == room_id[_n-1] 
replace room_id_placehold = 3 if room_id_placehold[_n-1] == 3 & room_id == room_id[_n-1]
replace room_id_placehold = 4 if room_id_placehold[_n-1] == 3 & therapist_id != therapist_id[_n-1] & room_id == room_id[_n-1] 
replace room_id_placehold = 4 if room_id_placehold[_n-1] == 4 & room_id == room_id[_n-1]

gen room_id_by_p = (room_id + room_id_placehold), after(room_id_placehold) 
label var room_id_by_p "Each unique client/therapist pairing." 
drop room_id_placehold

replace scale_score = 21-scale_score


/*Declare time series of COUNT*/
xtset room_id_by_p count
save "om_scale_id_47_analysis.dta", replace

****************************BEGIN ANALYSIS***********************************

keep room_id room_id_by_p client_demo_user_id therapist_id om_scale_id scale_score count time_to_complete_days time_to_complete_total therapist_dbt therapist_cbt therapist_mbct therapist_mi therapist_ptsd therapist_relational therapist_emotionally therapist_psychoanalytic missing* client* therapist_license_type therapist_pro_degree therapist_gender therapist_experience media_total_duration_secs_audio media_total_duration_secs_photo media_total_duration_secs_video therapist_demo_date_of_birth
drop client_demo*


**********STEP 1: Isolate therapist fixed effects.**********

xtreg scale_score, fe //sigma_u is composed of both therapist and client fixed effects. We need to break it up in order to isolate just therapist fixed effects.

**1.1 in each unique client-therapist interaction (room_id_by_p), keep only the first and last assessment score
by room_id_by_p (count), sort: gen byte first = sum(count) == 1
gen ncount = -count
by room_id_by_p (ncount), sort: egen mincount = min(ncount)
by room_id_by_p (ncount): gen byte last = 1 if sum(ncount) == mincount  

keep if first == 1 | last == 1
drop first ncount mincount last

**1.2 for each room_id_by_p, generate a variable representing the overall improvement in that client's assessment score.
by room_id_by_p (count), sort: gen frank = scale_score if count == 1
by room_id_by_p (count) : egen firstscore = min(frank)
drop frank

by room_id_by_p (count): drop if room_id_by_p == room_id_by_p[_n+1]
by room_id_by_p (count): gen overall_improvement = scale_score - firstscore

** 1.3 Regress each client's overall improvement (from first assessment score to last assessment score) on controls for client characteristics, with fixed effects for each therapist. We are interested in those therapist fixed effects.
sort therapist_id room_id_by_p
xtset therapist_id room_id_by_p

global X_1 i.client_edu_lvl i.missing_edu i.client_gender i.missing_gender i.client_ethnicity i.missing_ethnicity i.client_marital_status i.missing_marrital i.client_age i.missing_age i.client_country i.client_state

xtreg overall_improvement $X_1, fe 
eststo tvam_model

**1.4 The therapist's fixed effect is equal to:
predict therapist_effect, u
//br therapist_id therapist_effect


**********STEP 2: Explore Fixed Effects.**********

**2.1 Preliminary Data Set-up
//Create a variable for therapist age.
gen int date_of_birth = date(therapist_demo_date_of_birth, "YMD")
format date_of_birth %td
gen current = date("01jan2016", "DMY")
format current %td
gen t_age = (current - date_of_birth)/365.25
drop date_of_birth current
drop if t_age < 0 //Looks like some therapist's birth dates are in years > 2020, which is impossible
gen therapist_age = .
replace therapist_age = 1 if t_age <= 17 
replace therapist_age = 2 if t_age >= 18 & t_age <= 25
replace therapist_age = 3 if t_age >= 26 & t_age <= 35
replace therapist_age = 4 if t_age >= 36 & t_age <= 49
replace therapist_age = 5 if t_age >= 50 & t_age <= 110
//Significant amount of missing therapist_age's. Not sure how best to handle
label define t_age1 1 "missing" 2 "18-25" 3 "26-35" 4 "36-49" 5 "50+" 
label values therapist_age t_age1

//Create variables to explore characteristics of the client/therapist match
gen gender_match = .
label variable gender_match "client/therapist gender is the same"
replace gender_match = 1 if client_gender==therapist_gender
replace gender_match = 0 if gender_match != 1 

gen age_match = 0
label variable age_match "characterstic of client/therapist age match"
replace age_match = 1 if therapist_age > client_age
replace age_match = 2 if therapist_age < client_age
label define q 0 "same age" 1 "therapist is older" 2 "therapist is younger"
label values age_match q

**Macros for therapist characteristics and interaction characteristics
global p_char b2.therapist_license_type i.therapist_pro_degree i.therapist_dbt i.therapist_cbt i.therapist_mbct i.therapist_mi i.therapist_ptsd i.therapist_relational i.therapist_emotionally i.therapist_psychoanalytic i.therapist_gender b4.therapist_experience t_age
global interaction_char time_to_complete_total media_total_duration_secs_audio media_total_duration_secs_photo media_total_duration_secs_video
global match_char i.gender_match i.age_match firstscore 

**2.2 What explains therapist_effect?
cd reporting_47
//Naive: How a therapist's fixed characteristics affect his therapist_effect
reg therapist_effect $p_char , vce(robust)
outreg2 using explain_va_47, replace excel dec(3) label

//Include effect of therapist/client match characteristics
reg therapist_effect $p_char $match_char, vce(robust)
outreg2 using explain_va_47, append excel dec(3) label


//Include all client/interaction characteristics
reg therapist_effect $p_char $match_char $X_1 $interaction_char , vce(robust)


/*
//Table displaying estimates of the first two models
esttab m1 m2 , b(3) se(3) star r2(3) ar2(3) label mtitles("Model 1" "Model 2") coef(_const constant) nobase noomitted

//Table displaying estimates of third model; it's very busy w/out adding much useful information
esttab m1 m2 m3 , b(3) se(3) star r2(3) ar2(3) label mtitles("Model 1" "Model 2" "Model 3") coef(_const constant) nogaps nobase drop(media*) noomitted
*/

/*
//After accounting for client/interaction characteristics, what is the true therapist effect? Perhaps the difference between therapist_effect and predicted therapist_effect (based on client/interaction characteristics).
qui: reg therapist_effect $match_char $X_1 $interaction_char, vce(robust)
predict yhat
gen adjtherapist_effect = therapist_effect - yhat
*/


**********STEP 3: Individual effects on clients.**********

cd ..

**3.1 Generate client_specific improvement variable (nonparametric)
gen byte nonmissing = !missing(overall_improvement)  

bysort nonmissing therapist_id : gen total = sum(overall_improvement) if nonmissing
by nonmissing therapist_id : replace total = total[_N]

by nonmissing therapist_id : gen nmcount = _N if nonmissing

gen client_specific = (total - overall_improvement) / (nmcount - 1) //In words, this is the avg of a therapist's effect (in terms of overall_improvement) for each of his clients, excluding the current observation.
drop nonmissing total nmcount


**3.2 CAUSAL EFFECT OF THERAPIST VA ON CLIENT OUTCOMES

egen zclient_specific = std(client_specific)
egen zoverall_improvement = std(overall_improvement)
save "working_om_47.dta", replace
/*
reg overall_improvement client_specific
reg overall_improvement client_specific $X_1

reg overall_improvement zclient_specific 
reg overall_improvement zclient_specific $X_1 
reg overall_improvement zclient_specific $X_1 $match_char

reg zoverall_improvement zclient_specific $X_1
*/

*********STEP 4: Robustness checks and Alternative specifications.**********
cd reporting_47
cap mkdir experimental_47
cd experimental_47

**4.1 Exploring exogeneity of therapist assignment
reg therapist_effect $X_1
 eststo sprite
outreg2 sprite using exogenous_assignment_47.xls, replace title("Regression of Therapist VA on Client Characteristics") label

**4.2 Breaking up unbalanced panel by 'count'
//really not sure how useful this is. Just exploring it
forvalues i = 1/13 {
	qui: xtreg overall_improvement $X_1 if count ==`i', fe
	scalar r2_`i' = e(r2_o)
	predict t_va_`i', u
	qui: sum t_va_`i', detail
	scalar sd_`i' = r(sd)
}

qui: xtreg overall_improvement $X_1 if count > 13, fe
scalar r2_14 = e(r2_o)
predict t_va_14up, u
qui: sum t_va_14up, detail
scalar sd_14 = r(sd)

clear matrix
forvalues i=1/2 {
	mat A`i' = J(14,1,.)
}

local n 1
forvalues k = 1/14 {
	mat A1[`n',1]= r2_`k'
	mat A2[`n',1]= sd_`k'
	local ++n
}

matrix rownames A1= "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14+" 
frmttable, statmat(A1) replace sdec(3) title("Breaking Up Unbalanced Panel by 'Count'") ctitles(" ", "Reg. R2")
frmttable, statmat(A2) replace sdec(3) merge ctitles("Std. Dev. of Predicted Vals")
frmttable using "count_breakdown_47.doc" , replay replace

drop t_va_*

**************************************************************************
********************************REPORTING*********************************
**************************************************************************

cd ..

**Fig. 1: Histogram of VA distribution
histogram therapist_effect, bin(100) fcolor(navy) xscale(range(-3 3)) title(Therapist VA Distribution) xtitle(Therapist Value-Added)
graph save "Graph" "VA_distribution_47.gph", replace

sum therapist_effect, detail
scalar outlier = 1.5* (r(p75)-r(p25))
drop if therapist_effect > (r(p75)+outlier) | therapist_effect < (r(p25)- outlier)

histogram therapist_effect, bin(50) fcolor(navy) xtitle(Therapist Value-Added) xscale(range(-3 3)) title("Therapist VA Distribution (Outliers Omitted)")
graph save "Graph" "VA_distribution_nooutliers_47.gph", replace


**Fig. 2: Mean Gain Scores
cd ..
use "working_om_47.dta", clear
cd reporting_47

xtile quartile = therapist_effect, nq(4)
cibar therapist_effect , over(quartile) level(95) bargap(5) 
graph save "Graph" "mean_VA_by_quartile_47.gph", replace


**Fig. 3: Descriptive Statistics

//First table: therapist descriptives
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
frmttable using "t_descriptives_47.doc" , replay replace

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
frmttable using "t_descriptives_47.doc" , addtable replace

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
frmttable using "t_descriptives_47.doc" , addtable replace

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
frmttable using "t_descriptives_47.doc" , addtable replace

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
frmttable using "t_descriptives_47.doc" , addtable replace


//Second table: therapist self-reported specialties
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
frmttable using "specialties_47.doc", replay replace

//Third table: client descriptives
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
frmttable using "c_descriptives_47.doc" , replay replace

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
frmttable using "c_descriptives_47.doc" , addtable replace

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
frmttable using "c_descriptives_47.doc" , addtable replace

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
frmttable using "c_descriptives_47.doc" , addtable replace

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
frmttable using "c_descriptives_47.doc" , addtable replace

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
frmttable using "c_descriptives_47.doc" , addtable replace

//Fourth table: Therapist VA descriptives
clear matrix
forvalues i=1/6 {
	mat A`i' = J(5,1,.)
}

qui sum therapist_effect 
mat A1[1,1]=r(N)
mat A2[1,1]=r(mean)
mat A3[1,1]=r(sd)
mat A4[1,1]=r(min)
mat A5[1,1]=r(max)
mat A6[1,1]=(r(max)-r(min))

local n 2
forvalues k = 1/4 {
	qui sum therapist_effect if quartile == `k'
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
frmttable using "VA_summary_47.doc" , replay replace


**Fig. 4: Explanation of Therapist VA : Regression Output

//already done in section 2.2


**Fig. 5: Causal Effect of Therapist VA on Individual Client Outcomes

qui reg overall_improvement zclient_specific 
outreg2 using va_effect_47, replace excel dec(3) label

qui reg overall_improvement zclient_specific $X_1 
outreg2 using va_effect_47, append excel dec(3) label

qui reg overall_improvement zclient_specific $X_1 $match_char
outreg2 using va_effect_47, append excel dec(3) label

cd ..
cd ..
