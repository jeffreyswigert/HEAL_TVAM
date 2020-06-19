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

********1: Create combined measures of therapist value-added (weighted average across each om_scale_id)********

**1.1 Combine datasets, add mean gains (in terms of raw score) and a standardized version of mean gains

cd $analysis
use "working_om_1.dta", clear
foreach i of numlist 2,3,4,5,47 {
    append using "working_om_`i'.dta"
}

sort therapist_id om_scale_id
drop client_specific zclient_specific zoverall_improvement


bys therapist_id : gen total = sum(overall_improvement)
by therapist_id : replace total = total[_N]
by therapist_id : gen tcount = _N

gen client_specific = (total-overall_improvement)/(tcount-1)

drop total tcount 
egen zclient_specific = std(client_specific)

bys therapist_id : egen meangains = mean(client_specific)
egen zmeangains = std(meangains)

save "overall_placehold.dta", replace

**1.2 Created a weighted average of each therapist's effect (weighted by # of clients per om_scale_id)
bysort therapist_id : gen client_count = _N
drop if therapist_id == therapist_id[_n-1]
by therapist_id : egen wgt_therapist_effect = wtmean(therapist_effect), weight(client_count)
egen zwgt_therapist_effect = std(wgt_therapist_effect)

**1.3 Create va_overall.dta, which contains overall VA measures for each therapist
keep therapist_id wgt_therapist_effect zwgt_therapist_effect meangains zmeangains
cd $data
save "va_overall.dta", replace

**1.4 Create va_overall_raw.dta, which has all VA vars, and all client/therapist characteristics
cd $analysis
merge 1:m therapist_id using "overall_placehold.dta", nogen
order room_id_by_p therapist_id wgt_therapist_effect zwgt_therapist_effect clin_sig_imp sig_dec meangains zmeangains client_specific zclient_specific
cd $data
save "va_overall_raw.dta" , replace 



*******************************2: Analyze and Report******************************

**2.1 Causal effect of therapist VA on client outcomes 
use "va_overall_raw.dta" , clear
cd $reporting

qui reg overall_improvement zwgt_therapist_effect
outreg2 using va_effect_overall, replace excel dec(3) label

qui reg overall_improvement zwgt_therapist_effect $X_1
outreg2 using va_effect_overall, append excel dec(3) label

qui reg overall_improvement zwgt_therapist_effect $X_1 $match_char
outreg2 using va_effect_overall, append excel dec(3) label
***
qui reg overall_improvement zmeangains
outreg2 using va_effect_overall, append excel dec(3) label

qui reg overall_improvement zmeangains $X_1
outreg2 using va_effect_overall, append excel dec(3) label

qui reg overall_improvement zmeangains $X_1 $match_char
outreg2 using va_effect_overall, append excel dec(3) label
***
qui reg overall_improvement zclient_specific 
outreg2 using va_effect_overall, append excel dec(3) label

qui reg overall_improvement zclient_specific $X_1 
outreg2 using va_effect_overall, append excel dec(3) label

qui reg overall_improvement zclient_specific $X_1 $match_char
outreg2 using va_effect_overall, append excel dec(3) label

//We can see that being assigned to a high-VA therapist is highly predictive of improved outcomes.

**2.2: Exploring exogeneity of therapist assignment
qui reg zwgt_therapist_effect $X_1
eststo sprite
outreg2 sprite using exogenous_assignment_overall.xls, replace title("Regression of Therapist VA on Client Characteristics") label
qui reg zmeangains $X_1
eststo sprite
outreg2 sprite using exogenous_assignment_overall.xls, append title("Regression of Therapist VA on Client Characteristics") label
qui reg zclient_specific $X_1
eststo sprite
outreg2 sprite using exogenous_assignment_overall.xls, append title("Regression of Therapist VA on Client Characteristics") label

//We do see some potential endogeneity in assignment to "high VA" therapists. Geographic region, age, and some aspects of gender are predictive of VA. 
//Geographic region makes sense, as clients are assigned to therapists within the same state and that would affect the availability of high VA therapists to assign them to.
//Age: it seems like being in the youngest group (under 18) is predictive of receiving a lower VA therapist. Maybe kids in this age range are harder to work with, and that decreases therapists' effectiveness with them.
//Being male or non-gender-binary are predictive of receiving lower therapist VA.


**2.3: Exploring clinically significant impacts (positive and negative).

*2.31 Likelihood of positive impact, as predictied by therapist_effect
qui reg clin_sig_imp zwgt_therapist_effect $p_char $match_char, vce(robust)
outreg2 using likelihood_sig_imp_overall, replace excel dec(3) label
qui reg clin_sig_imp zmeangains $p_char $match_char, vce(robust)
outreg2 using likelihood_sig_imp_overall, append excel dec(3) label
qui reg clin_sig_imp zclient_specific $p_char $match_char, vce(robust)
outreg2 using likelihood_sig_imp_overall, append excel dec(3) label


*2.32 Likelihood of negative impact, as predictied by therapist_effect
qui reg sig_dec zwgt_therapist_effect $p_char $match_char, vce(robust)
outreg2 using likelihood_sig_dec_overall, replace excel dec(3) label
qui reg sig_dec zmeangains $p_char $match_char, vce(robust)
outreg2 using likelihood_sig_dec_overall, append excel dec(3) label
qui reg sig_dec zclient_specific $p_char $match_char, vce(robust)
outreg2 using likelihood_sig_dec_overall, append excel dec(3) label

*2.33 Descriptives, positive 
clear matrix
forvalues i=1/3 {
	mat A`i' = J(3,1,.)
}

estpost tab clin_sig_imp
mat x = e(b)
mat y = e(pct)
mat z = e(cumpct)

forvalues i = 1/3 {
	scalar x`i' = x[1,`i']
	scalar y`i' = y[1,`i']
}

forvalues i = 1/3 {
	if `i' < 3 {
		scalar z`i' = z[1,`i']
	}
	else {
		scalar z`i' = .
	}
} 

local n 1
forvalues i = 1/3 {
	mat A1[`n',1]= x`i'
	mat A2[`n',1]= y`i'
	mat A3[`n',1]= z`i'
	local ++n
}
scalar drop _all

matrix rownames A1= "Not significant" "Significant" "Total"
frmttable, statmat(A1) replace sdec(0) title("Clinically Significant Positive Impact, by Client/Therapist Interaction") ctitles("","N")
frmttable, statmat(A2) replace sdec(2) merge ctitles("Pct")
frmttable, statmat(A3) replace sdec(2) merge ctitles("Cum Pct")
frmttable using "clin_sig_imp_overall.doc" , replay replace

*2.34 Descriptives, negative
clear matrix
forvalues i=1/3 {
	mat A`i' = J(3,1,.)
}

estpost tab sig_dec
mat x = e(b)
mat y = e(pct)
mat z = e(cumpct)

forvalues i = 1/3 {
	scalar x`i' = x[1,`i']
	scalar y`i' = y[1,`i']
}

forvalues i = 1/3 {
	if `i' < 3 {
		scalar z`i' = z[1,`i']
	}
	else {
		scalar z`i' = .
	}
} 

local n 1
forvalues i = 1/3 {
	mat A1[`n',1]= x`i'
	mat A2[`n',1]= y`i'
	mat A3[`n',1]= z`i'
	local ++n
}
scalar drop _all

matrix rownames A1= "Not significant" "Significant" "Total"
frmttable, statmat(A1) replace sdec(0) title("Significant Negative Impact, by Client/Therapist Interaction") ctitles("","N")
frmttable, statmat(A2) replace sdec(2) merge ctitles("Pct")
frmttable, statmat(A3) replace sdec(2) merge ctitles("Cum Pct")
frmttable using "sig_dec_overall.doc" , replay replace



*******************************3: Descriptive Statistics******************************

**3.1: Histogram of VA Distribution
cd $data
use "va_overall", clear
cd $reporting

histogram wgt_therapist_effect, bin(50) fcolor(navy) xscale(range(-3 3)) title(Therapist VA Distribution) xtitle(Therapist Value-Added)
graph save "Graph" "VA_distribution_overall.gph", replace

sum wgt_therapist_effect, detail
scalar outlier = 1.5* (r(p75)-r(p25))
drop if wgt_therapist_effect > (r(p75)+outlier) | wgt_therapist_effect < (r(p25)- outlier)

histogram wgt_therapist_effect, bin(25) fcolor(navy) xtitle(Therapist Value-Added) xscale(range(-3 3)) title("Therapist VA Distribution (Outliers Omitted)")
graph save "Graph" "VA_distribution_nooutliers_overall.gph", replace

cd $data
use "va_overall", clear
cd $reporting

histogram meangains, bin(50) fcolor(navy) xscale(range(-3 3)) title("Therapist VA Distribution, in Mean Gains") xtitle(Mean Client Gains) 
graph save "Graph" "MeanGain_distribution_overall.gph", replace

sum meangains, detail
scalar outlier = 1.5* (r(p75)-r(p25))
drop if meangains > (r(p75)+outlier) | meangains < (r(p25)- outlier)

histogram meangains, bin(25) fcolor(navy) xscale(range(-3 3)) title("Therapist VA Distribution, in Mean Gains (Outliers Omitted)") xtitle(Mean Client Gains) 
graph save "Graph" "MeanGain_distribution_nooutliers_overall.gph", replace


**3.2: Mean Gain Scores

cd $data
use "va_overall.dta", clear
cd $reporting

xtile quartile = wgt_therapist_effect, nq(4)
cibar wgt_therapist_effect , over(quartile) level(95) bargap(5) 
graph save "Graph" "mean_VA_by_quartile_overall.gph", replace

drop quartile
xtile quartile = meangains, nq(4)
cibar meangains, over(quartile) level(95) bargap(5)
graph save "Graph" "mean_gains_by_quartile_overall.gph", replace


**3.3 Therapist Descriptives and self reported specialties
cd $data
use "va_overall_raw", clear

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


**3.4 Client Descriptives 
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

**3.5 Therapist VA Descriptives
*3.51 wgt_therapist_effect descriptives
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

*3.52 meangains descriptives
xtile mgquartile = meangains, nq(4)

clear matrix
forvalues i=1/6 {
	mat A`i' = J(5,1,.)
}

qui sum meangains 
mat A1[1,1]=r(N)
mat A2[1,1]=r(mean)
mat A3[1,1]=r(sd)
mat A4[1,1]=r(min)
mat A5[1,1]=r(max)
mat A6[1,1]=(r(max)-r(min))

local n 2
forvalues k = 1/4 {
	qui sum meangains if quartile == `k'
	mat A1[`n',1]=r(N)
	mat A2[`n',1]=r(mean)
	mat A3[`n',1]=r(sd)
	mat A4[`n',1]=r(min)
	mat A5[`n',1]=r(max)
	mat A6[`n',1]=(r(max)-r(min))
	local ++n
}

matrix rownames A1= "Total" "1st Quartile" "2nd Quartile" "3rd Quartile" "4th Quartile"
frmttable, statmat(A1) replace sdec(0) title("Mean Client Gains per Therapist") ctitles(" ", "N")
frmttable, statmat(A2) replace sdec(3) merge ctitles("Mean")
frmttable, statmat(A3) replace sdec(3) merge ctitles("Std. Dev.")
frmttable, statmat(A4) replace sdec(3) merge ctitles("Min")
frmttable, statmat(A5) replace sdec(3) merge ctitles("Max")
frmttable, statmat(A6) replace sdec(3) merge ctitles("Range")
frmttable using "meangain_summary_overall.doc" , replay replace
