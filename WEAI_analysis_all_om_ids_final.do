/*********************************************************************
This performs VA analysis on the subsection of vam_analysis_sample.dta where om_scale_id == 4.

For "Measuring Therapist Value-Added: Evidence from an Online Therapy Platform"

Coded by: Dr. Jeff Swigert

Inputs: 
	- vam_analysis_sample.dta
*********************************************************************/

clear
set more off
global jeff1 "/Users/jeffreyswigert/OneDrive/HEAL_TVAM"
cd $jeff1

use "WEAI_analysis_sample.dta", clear

// client demographics categorical variables

global X patient_ed_* missing_edu patient_female patient_other_gender patient_missing_gender /// 
		patient_ethnicity_* patient_missing_ethnicity ///
		patient_mar_status_* ///
		patient_missing_mar_stat patient_age_* ///
		patient_missing_age client_demo_state ///
		client_demo_primary_condition 

global X_1 patient_ed_1 patient_ed_2 missing_edu patient_female patient_other_gender patient_missing_gender /// 
		patient_ethnicity_2 - patient_ethnicity_5 patient_missing_ethnicity ///
		patient_mar_status_1-patient_mar_status_6 patient_mar_status_8 ///
		patient_missing_mar_stat patient_age_1-patient_age_2 ///
		patient_age_4-patient_age_6 patient_missing_age patient_state_2-patient_state_52 ///
		

cap drop  patient_missing_edu	
gen patient_missing_edu = client_edu_lvl == 99
gen patient_edu = ""
replace patient_edu = "< H.S." if client_edu_lvl < 12
replace patient_edu = "B.S. or Higher" if client_edu_lvl <= 16 & client_edu_lvl > 12 
replace patient_edu = "Missing" if client_edu_lvl == 99
tab patient_edu, gen(patient_ed_)	


gen patient_female = client_gender == 1
replace patient_female = 99 if client_gender == 8 
gen patient_other_gender = client_gender == 3

gen patient_missing_gender = patient_female == 99

//patient age

gen patient_missing_age = client_demo_age_customer == "NA"
tab client_demo_age_customer, gen(patient_age_)

// patient marital status

gen patient_missing_mar_stat = client_demo_marital_status == "NA"
tab client_demo_marital_status, gen(patient_mar_status_)  // referent is single people


// patient ethnicity
rename missing_ethnicity patient_missing_ethnicity
tab client_ethnicity, gen(patient_ethnicity_) // referent is white people


// therapist demographics categorical variables	
cap drop t_age	
egen t_age = cut(therapist_age), at(20, 30, 40, 50, 60, 70, 80) icodes label
table t_age, contents(min therapist_age max therapist_age) 
gen t_age_missing = missing(t_age)

global T t_age t_age_missing t_lic_type_* ///  
		therapist_dbt  therapist_mi therapist_ptsd therapist_pyschodynamic therapist_demo_mbct /// THESE AREN'T M.Exclusive
		therapist_relational therapist_emotionally therapist_demo_psychoanalytic therapist_female ///
		therapist_gender_missing therapist_exp_* ///
		
global T_1 i.t_age t_age_missing t_lic_type_1-t_lic_type_6 t_lic_type_8 t_lic_type_9 ///  
		therapist_dbt  therapist_mi therapist_ptsd therapist_pyschodynamic therapist_demo_mbct /// THESE AREN'T M.Exclusive
		therapist_relational therapist_emotionally therapist_demo_psychoanalytic therapist_female ///
		therapist_gender_missing therapist_exp_1 therapist_exp_2 therapist_exp_4 ///
		
		
		

// License_type 
replace therapist_demo_license_type = "LPC" if regexm(therapist_demo_license_type, "LPC") 
replace therapist_demo_license_type = "LCSW" if regexm(therapist_demo_license_type, "LCSW")
tab therapist_demo_license_type, sort 

replace therapist_demo_license_type = "Other" if regexm(therapist_demo_license_type, "LISW-S") | ///
								regexm(therapist_demo_license_type, "Matching Agent") | ///
								regexm(therapist_demo_license_type, "LISW") | ///
								regexm(therapist_demo_license_type, "LCMHC") | ///
								regexm(therapist_demo_license_type, "LSCSW") | ///
								regexm(therapist_demo_license_type, "LIMHP") | ///
								regexm(therapist_demo_license_type, "LCMFT") | ///
								regexm(therapist_demo_license_type, "CSW-PIP") | ///
								regexm(therapist_demo_license_type, "LISW-CP") | ///
								regexm(therapist_demo_license_type, "LCAT") | ///
								regexm(therapist_demo_license_type, "LMHP") | ///
								regexm(therapist_demo_license_type, "LSW") | ///
								regexm(therapist_demo_license_type, "Psychiatrist") | ///
								regexm(therapist_demo_license_type, "LIMFT") 

								
								
								
gen therapist_mbct = therapist_demo_mbct == "True"	
gen therapist_relational = therapist_demo_relational == "True"
gen therapist_emotionally = therapist_demo_emotionally == "True"	
gen therapist_psychoanalytic = therapist_demo_psychoanalytic == "True"
gen therapist_female = therapist_gender == 1
gen therapist_male = therapist_gender == 2
gen therapist_gender_missing = therapist_gender == 99 
tab therapist_experience, gen(therapist_exp_)
						
// Referents: the for license type referent is LPC; the referent for method is CBT, therapist_exp_3 = 5-10 years
// Males are referent




								
tab therapist_demo_license_type, sort
cap drop t_lic_type_*								
tab therapist_demo_license_type, gen(t_lic_type_)
		


cap mkdir WEAI_output
cap mkdir tvam_4
*cd tvam_4
*cap mkdir reporting_4
save "WEAI_analysis_sample2.dta", replace
use "WEAI_analysis_sample2.dta", clear



sort therapist_id room_id svy_count
preserve
collapse (firstnm) f_svy_year = svy_year f_svy_cmp_time = svy_cmp_time ///
		f_svy_count = svy_count f_svy_week = svy_week f_moy = moy f_dow = dow f_dom = dom f_tod = tod $X $T ///
		(lastnm) l_svy_year = svy_year l_svy_cmp_time = svy_cmp_time ///
		l_svy_count = svy_count l_svy_week = svy_week l_moy = moy l_dow = dow ///
		l_dom = dom  l_tod = tod, by(therapist_id room_id)
save covariates_to_merge_va_reg.dta, replace
restore



// How many therapists? [Abstract, p1]
count if therapist_id ~= therapist_id[_n-1]

// How many patients?
sort room_id
count if room_id ~= room_id[_n-1]
  
// What years?

tab svy_year

// Patterns in Survey Response (and non-response)

* By day of the week


tab dow

preserve
use WEAI_analysis_sample.dta, clear
collapse (mean) scale_score (semean) score_se = scale_score ///
		 (firstnm) svy_year (count) N_score = scale_score ///
		 , by(dow om_scale_id)

set scheme uncluttered
levelsof om_scale_id, local(om_id_local)
foreach om_id in `om_id_local' {
	
	serrbar scale_score score_se dow if om_scale_id == `om_id', ///
			mvop(msize(medium) mcolor(red)) lcolor(blue%30) msize(medium) ///
			xlabel(0 "Sun" 1 "Mon" 2 "Tue" 3 "Wed" 4 "Thurs" 5 "Fri" 6 "Sat") ///
			xtitle("Day of Week", size(small)) yline(10) ///
			ytitle("Mean Assessment `om_id' Score", size(small)) ///
			title("Psychometric Assessment (#`om_id') Scores by Day of the Week", size(medium)) ///
			note("Notes: Red dots indicate mean assessment score with 95%CI bars in light blue. Sample is from patients of a large U.S. mental health care provider." "Questions? Contact me via email: jeffreyswigert@suu.edu", size(vsmall))
	graph export "WEAI_output/dow_`om_id'_all_years.png", replace
}	
restore


* By month of the years
tab moy 

preserve
use WEAI_analysis_sample.dta, clear
collapse (mean) scale_score (semean) score_se = scale_score ///
		 (firstnm) svy_year (count) N_score = scale_score ///
		 , by(moy om_scale_id)

set scheme uncluttered
levelsof om_scale_id, local(om_id_local)
foreach om_id in `om_id_local' {
	serrbar scale_score score_se moy if om_scale_id == `om_id', ///
		mvop(msize(medium) mcolor(red)) lcolor(blue%30) msize(medium) ///
		xlabel(1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" ///
			8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec") ///
		xtitle("Month of the Year", size(small)) yline(10) ///
		ytitle("Mean assessment (#`om_id') Score", size(small)) ///
		title("Psychometric Assessment (#`om_id') Scores by Month of the Year", size(medium)) ///
		note("Notes: Red dots indicate mean assessment score with 95% CI bars in light blue. Sample from patients of a large U.S. mental health care provider." "Questions? Contact me via email: jeffreyswigert@suu.edu", size(vsmall))
graph export "WEAI_output/moy_`om_id'_all_years.png", replace
}
restore

// Patterns in health assessment scores by time of day

tab dom 

preserve
use WEAI_analysis_sample.dta, clear
collapse (mean) scale_score (semean) score_se = scale_score ///
		 (firstnm) svy_year (count) N_score = scale_score ///
		 , by(dom om_scale_id)

set scheme uncluttered
levelsof om_scale_id, local(om_id_local)
foreach om_id in `om_id_local' {
serrbar scale_score score_se dom if om_scale_id == `om_id', ///
		mvop(msize(medium) mcolor(red)) lcolor(blue%30) msize(medium) ///
		xtitle("Day of month", size(small)) yline(10) ///
		ytitle("Mean Assessment (`om_id') Score", size(small)) ///
		title("Psychometric Assessment (#`om_id') Scores by Day of the Month", size(medium)) ///
		note("Notes: Red dots indicate mean assessment score with 95% CI bars in light blue. Sample is from patients from a large U.S. mental health care provider." "Questions? Contact me via email: jeffreyswigert@suu.edu", size(vsmall))
graph export "WEAI_output/dom_`om_id'_all_years.png", replace
}
restore


// Patterns in health assessment scores by time of day

tab tod 

preserve
use WEAI_analysis_sample.dta, clear
collapse (mean) scale_score (semean) score_se = scale_score ///
		 (firstnm) svy_year (count) N_score = scale_score ///
		 , by(tod om_scale_id)

set scheme uncluttered
levelsof om_scale_id, local(om_id_local)
foreach om_id in `om_id_local' {
serrbar scale_score score_se tod if om_scale_id == `om_id', ///
		mvop(msize(medium) mcolor(red)) lcolor(blue%30) msize(medium) ///
		xlabel(0 "Midnight" 1 "1AM" 2 "2AM" 3 "3AM" 4 "4AM" 5 "5AM" 6 "6AM" 7 "7AM" ///
				   8 "8AM" 9 "9AM" 10 "10AM" 11 "11AM" 12 "Noon" ///
				   13 "1PM" 14 "2PM" 15 "3PM" 16 "4PM" 17 "5PM" 18 "6PM" 19 "7PM" ///
				   20 "8PM" 21 "9PM" 22 "10PM" 23 "11PM", angle(45) labs(vsmall)) ///
		xtitle("Time of Day", size(small)) yline(10) ///
		ytitle("Mean Assessment (`om_id') Score", size(small)) ///
		title("Psychometric Assessment (#`om_id') Scores by Time of Day", size(medium)) ///
		note("Notes: Red dots indicate mean GAD7 score with 95% CI bars in light blue. Sample is from patients from a large U.S. mental health care provider." "Questions? Contact me via email: jeffreyswigert@suu.edu", size(vsmall))
graph export "WEAI_output/tod_`om_id'_all_years.png", replace
}
restore




  
// Restrict to Anxiety Frequency GAD7

preserve
use WEAI_analysis_sample.dta, clear
collapse (mean) scale_score (semean) score_se = scale_score ///
		 (firstnm) svy_year (count) N_score = scale_score ///
		 , by(svy_week om_scale_id)

set scheme uncluttered
serrbar scale_score score_se svy_week if om_scale_id == 4, ///
		mvop(msize(tiny) mcolor(red)) lcolor(blue%30) msize(tiny) ///
		xtitle("Week", size(small)) yline(10) ///
		ytitle("Weekly Mean GAD7 Score", size(small)) ///
		title("General Anxiety Disorder 7 Scores (Jan. 2016 - Jun. 2020)", size(medium)) ///
		note("Note: Red dots indicate weekly mean GAD7 score with 95%CI bars in light blue. Scores above 10 are classified as clinically" "moderate levels of anxiety. Sample is of 70,486 patients from a large U.S. mental health care provider." "Questions? Contact me via email: jeffreyswigert@suu.edu", size(vsmall))
graph export "WEAI_output/weekly_gad7_all_years.png", replace
restore

/******************************************************************************
						Overall Therapy Gains Analysis
This visuals illustrate how progress in therapy relates to duration of therapy.

NOTE: There is systematic attrition in this sample, so we can't go so far as 
to say that there are diminishing marginal returns to therapy over time. 

TODO: Plot residual variation in gains after controlling for patient and therapist_id
characteristics.  Binscatter can do this with absorb
*******************************************************************************/

use "WEAI_analysis_sample2.dta", clear

sort room_therapist svy_count 
order room_therapist svy_count scale_score

//TODO: include patient and therapist time-invariant characteristics
collapse (firstnm) patient_female first_cmp_time = svy_cmp_time therapist_id room_id ///
				   first_score = scale_score ///
		 (lastnm) last_cmp_time = svy_cmp_time last_score = scale_score ///
		 (count) num_assessments = scale_score ///
			, by(room_therapist om_scale_id)
keep if num_assessments > 1
gen score_change = first_score - last_score
gen therapy_duration = dofC(last_cmp_time) - dofC(first_cmp_time) 
label variable therapy_duration "Therapy Duration (days)"
sum therapy_duration if therapy_duration<=546 & therapy_duration >0, det
drop if therapy_duration < 0

save temp_clientlong_merge.dta, replace
use temp_clientlong_merge.dta, clear
drop if om_scale_id >= 52 | om_scale_id == 35 // Omit the Big 5 given they are administered 1 time
gen minus_transform = 1
replace minus_transform = -1 if om_scale_id == 19 | om_scale_id == 20 | om_scale_id == 19 ///
		| om_scale_id == 36  

replace score_change = score_change*minus_transform
drop minus_transform

levelsof om_scale_id, local(om_id_local)
local omlabel: value label om_scale_id
foreach om_id in `om_id_local' {
	// if inlist(`om_id', 1, 2, 3, 4, 5, 36, 47, 19, 20, 21, 6, 7, 8, 9) {
		local om_label: label `omlabel' `om_id'
		hist score_change if om_scale_id == `om_id', xline(0) width(.5) ytitle("Frequency") xtitle("Score Change: `om_label'")
		graph export "WEAI_output/hist_score_change_`om_id'.png", replace
		binscatter score_change therapy_duration if om_scale_id==`om_id' & patient_female ~= 99 ///
												& therapy_duration<=100 & therapy_duration >0, ///
		/// these cuttoffs correspond to 99% of the data.  There are a hand full of extreme outliers
					line(qfit) xtitle("Therapy Duration (Days)") ytitle("Change in `om_label'", size(small))
		graph export "WEAI_output/binscat_`om_id'.png", replace
		binscatter score_change therapy_duration if om_scale_id==`om_id' & patient_female ~= 99 ///
												& therapy_duration<=100 & therapy_duration >0, ///
												by(patient_female) ///
		legend(lab(1 "Female") lab(2 "Male")) /// these cuttoffs correspond to 99% of the data.  There are a hand full of extreme outliers
		line(qfit) msymbols(O T) xtitle("Therapy Duration (Days)") ytitle("Change in `om_label' by Female (Red Triangles)", size(vsmall))
		graph export "WEAI_output/binscat_by_female_`om_id'.png", replace
		dis "T-test for Gender Difference in Gains ID(`om_id')"
		ttest score_change if om_scale_id == `om_id' & patient_female ~= 99 ///
			& therapy_duration<=100 & therapy_duration >0 ///
		, by(patient_female)
	/* }
	else {
		continue
	}
	*/
}
save WEAI_collapsed_room_therapist.dta, replace

/******************************************************************************
						Value-Added Analysis
						
The essentially random assignment of therapists to patients allows us to compute
direct estimates for therapist value-added with respect to the average gains that
patients of a given therapist obtain.  Really just the mean changes are the VA score.

Later parametric models can be used to account for client and therapist characteristics, 
but selection isn't really an issue.


*******************************************************************************/
use "WEAI_collapsed_room_therapist.dta", clear

collapse (mean) therapist_va = score_change therapy_duration (sum) sum_score_chg = score_change (count) num_clients = score_change, by(therapist_id om_scale_id)


// TODO: Generate a composite VA score based on a weighted average of the standardized VA scores for each metric

// Multiply some scores by -1 because they are opposite in the less severe direction than other om_scale_ids
gen minus_transform = 1
replace minus_transform = -1 if om_scale_id == 19 | om_scale_id == 20 | om_scale_id == 19 ///
		| om_scale_id == 36  

replace therapist_va = therapist_va*minus_transform
drop minus_transform

save WEAI_collapsed_therapist_va_om_id.dta, replace


preserve
reshape wide therapist_va therapy_duration sum_score_chg num_clients, i(therapist_id) j(om_scale_id)

egen sum_clients = rowtotal(num_clients*)

save temp_merge_tvawide_1.dta, replace
//Standardize the VA scores for each om_scale_id

forvalues f=1/13 {
egen therapist_va_z_`f' = std(therapist_va`f')
replace therapist_va_z_`f' = 0 if therapist_va_z_`f' == .
}

forvalues f=19/34 {
egen therapist_va_z_`f' = std(therapist_va`f')
replace therapist_va_z_`f' = 0 if therapist_va_z_`f' == .

}

forvalues f=36/51 {
egen therapist_va_z_`f' = std(therapist_va`f')
replace therapist_va_z_`f' = 0 if therapist_va_z_`f' == .
}

save wide_collapsed_va_by_om_sc.dta, replace


restore


/************************
Composite VA Scores
*************************/


forvalues f=1/13 {
gen frac_`f' = num_clients`f'/sum_clients
replace frac_`f' = 0 if frac_`f' == .
}

forvalues f=19/34 {
gen frac_`f' = num_clients`f'/sum_clients
replace frac_`f' = 0 if frac_`f' == .
}

forvalues f=36/51 {
gen frac_`f' = num_clients`f'/sum_clients
replace frac_`f' = 0 if frac_`f' == .
}





// Now to multiply the standardized scores together ... EXCEPT, wait .. we need 
// Figure out which ones need to be multiplied by -1 because of their frame


// now we take the weighted average:
gen therapist_m_weighted_va = .


replace therapist_m_weighted_va = frac_1*therapist_va_z_1 + ///
								frac_2*therapist_va_z_2 + ///
								frac_3*therapist_va_z_3 + ///
								frac_4*therapist_va_z_4 + ///
								frac_5*therapist_va_z_5 + ///
								frac_6*therapist_va_z_6 + ///
								frac_7*therapist_va_z_7 + ///
								frac_8*therapist_va_z_8 + ///
								frac_9*therapist_va_z_9 + ///
								frac_10*therapist_va_z_10 + ///								
								frac_11*therapist_va_z_11 + ///
								frac_12*therapist_va_z_12 + ///
								frac_13*therapist_va_z_13 + ///								
								frac_19*therapist_va_z_19 + ///
								frac_20*therapist_va_z_20 + ///
								frac_21*therapist_va_z_21 + ///
								frac_22*therapist_va_z_22 + ///
								frac_23*therapist_va_z_23 + ///
								frac_24*therapist_va_z_24 + ///
								frac_25*therapist_va_z_25 + ///
								frac_26*therapist_va_z_26 + ///
								frac_27*therapist_va_z_27 + ///
								frac_28*therapist_va_z_28 + ///
								frac_29*therapist_va_z_29 + ///
								frac_30*therapist_va_z_30 + ///
								frac_31*therapist_va_z_31 + ///
								frac_32*therapist_va_z_32 + ///
								frac_33*therapist_va_z_33 + ///
								frac_34*therapist_va_z_34 + ///
								frac_36*therapist_va_z_36 + ///
								frac_37*therapist_va_z_37 + ///
								frac_38*therapist_va_z_38 + ///
								frac_39*therapist_va_z_39 + ///
								frac_40*therapist_va_z_40 + ///
								frac_41*therapist_va_z_41 + ///
								frac_42*therapist_va_z_42 + ///
								frac_43*therapist_va_z_43 + ///
								frac_44*therapist_va_z_44 + ///
								frac_45*therapist_va_z_45 + ///
								frac_46*therapist_va_z_46 + ///
								frac_47*therapist_va_z_47 + ///
								frac_48*therapist_va_z_48 + ///
								frac_49*therapist_va_z_49 + ///
								frac_50*therapist_va_z_50 + ///
								frac_51*therapist_va_z_51
								
								
								
 // Hist between the 1% and 99% cuttoffs to make the histogram look a bit less sensitive to some suspect outliers
tw (hist therapist_m_weighted_va if therapist_m_weighted_va <= 2.22 /// 
								& therapist_m_weighted_va >= -1.788 ///
								,  ytitle("Density") xtitle("Therapist Composite Value Added Distribution")) , note("Notes: N=3,125 therapists and VA scores are constructed as weighted average of all standardized psychometric assessment score " "gains scaled by proportion of a therapists clients who take a given assessment.", size(vsmall)) 
graph export "WEAI_output/therapist_m_weighted_va_z.png", replace


reg score_change therapist_va first_score, robust



save composite_va_therapist_by_om_scale_id_all.dta, replace
		
// Merge correct data together with needed variables
use temp_clientlong_merge.dta, clear
sort therapist_id om_scale_id
merge m:1 therapist_id using temp_merge_tvawide_1.dta
order therapist_id room_id room_therapist first_score score_change therapist_va* sum_score_chg* sum_clients*
sort therapist_id room_id

save TVAM_va_plus_client_outcomes_jeffkenzi.dta, replace
use TVAM_va_plus_client_outcomes_jeffkenzi.dta, clear
// Construct LOO VA
drop if om_scale_id == 35  
levelsof om_scale_id, local(om_id_local)
foreach om_id in `om_id_local' {
	if `om_id' < 52 {
		gen therapist_va_ps_loo_`om_id' = (sum_score_chg`om_id' - score_change)/(num_clients`om_id'-1) /// 
		if om_scale_id == `om_id'
	}
	else {
		continue
	}
}
save temp_clientlong_merge_2.dta, replace 
// Bring in all the patient covariates
use temp_clientlong_merge_2.dta, clear
cap drop _merge
duplicates report
merge m:1 room_id therapist_id using covariates_to_merge_va_reg.dta
keep if _merge == 3
drop _merge
save va_regression_sample.dta, replace
// Estimate the causal effect of getting a higher VA therapist on client improvement
use va_regression_sample.dta, clear
tab client_demo_state, sort gen(patient_state_) // NA is international peeps.  Referent is CA

cap drop clin_sig_improvement
gen clin_sig_improvement = .
replace clin_sig_improvement = 0 if om_scale_id == 1 | om_scale_id == 2 | om_scale_id == 3 | om_scale_id == 4 | om_scale_id == 5


gen clin_meaningful_imp = score_change >= 5
sum clin_meaningful_imp



replace clin_sig_improvement = 1 if first_score >= 10 & last_score < 10 & (om_scale_id == 1 | om_scale_id == 2 | om_scale_id == 3 | om_scale_id == 4 | om_scale_id ==5)

levelsof om_scale_id, local(om_id_local)
foreach om_id in `om_id_local' {
	// if `om_id' < 6 {
		sum therapist_va_ps_loo_`om_id', det
		preserve
		keep if inrange(therapist_va_ps_loo_`om_id', r(p1), r(p99))
		hist therapist_va_ps_loo_`om_id'
		graph export th_va_loo_`om_id'.png, replace
		restore
/*
		reg score_change therapist_va_ps_loo_`om_id' patient_female ///
			patient_missing_gender i.l_dow i.l_moy if om_scale_id == `om_id', vce(cluster therapist_id)  
			outreg2 therapist_va_ps_loo_`om_id' patient_female patient_age* patient_ed_* /// 
			using WEAI_output/va_reg_1_`om_id', bdec(3) replace br(se) word
		reg clin_sig_improvement therapist_va_ps_loo_`om_id'  patient_female ///
			patient_missing_gender i.l_dow i.l_moy if om_scale_id == `om_id', vce(cluster therapist_id)
			outreg2 therapist_va_ps_loo_`om_id' patient_female patient_age_* patient_ed_* /// 
			using WEAI_output/va_reg_1_clin_sig_`om_id', bdec(3) append br(se) word	
		reg clin_meaningful_imp therapist_va_ps_loo_`om_id' patient_female ///
			patient_missing_gender  i.l_dow i.l_moy if om_scale_id == `om_id', vce(cluster therapist_id)
			outreg2 therapist_va_ps_loo_`om_id' patient_female patient_age_* patient_ed_* /// 
			using WEAI_output/va_reg_1_clin_sig_`om_id', bdec(3) append br(se) word
		
		// With Duration added
		reg score_change therapist_va_ps_loo_`om_id' patient_female ///
			patient_missing_gender  i.l_dow i.l_moy therapy_duration`om_id' ///
			if om_scale_id == `om_id', vce(cluster therapist_id) 
			outreg2 therapist_va_ps_loo_`om_id' patient_female patient_age_`om_id' patient_ed_* /// 
			using WEAI_output/va_reg_1_`om_id', bdec(3) append br(se) word
		reg clin_sig_improvement therapist_va_ps_loo_`om_id'  patient_female ///
			patient_missing_gender   i.l_dow i.l_moy if om_scale_id == `om_id', vce(cluster therapist_id)
			outreg2 therapist_va_ps_loo_`om_id' patient_female patient_age_* patient_ed_* /// 
			using WEAI_output/va_reg_1_clin_sig_`om_id', bdec(3) append br(se) word	
		reg clin_meaningful_imp therapist_va_ps_loo_`om_id' patient_female ///
			patient_missing_gender   i.l_dow i.l_moy if om_scale_id == `om_id', vce(cluster therapist_id)
			outreg2 therapist_va_ps_loo_`om_id' patient_female patient_age_* patient_ed_* /// 
			using WEAI_output/va_reg_1_clin_sig_`om_id', bdec(3) append br(se) word
*/			
		// With patient_age and first_score added

		reg score_change therapist_va_ps_loo_`om_id' patient_female ///
			patient_missing_gender  i.l_dow i.l_moy i.patient_age_`om_id' first_score if om_scale_id == `om_id' ///
			, vce(cluster therapist_id) 
			outreg2 therapist_va_ps_loo_`om_id' patient_female patient_age_* patient_ed_* /// 
			using WEAI_output/va_pref_spec_`om_id', bdec(3) replace br(se) excel
		cap reg clin_sig_improvement therapist_va_ps_loo_`om_id'  patient_female ///
			patient_missing_gender   i.l_dow i.l_moy i.patient_age_`om_id'  first_score if om_scale_id == `om_id' ///
			, vce(cluster therapist_id)
			outreg2 therapist_va_ps_loo_`om_id' patient_female patient_age_* patient_ed_* /// 
			using WEAI_output/va_pref_spec_`om_id', bdec(3) append br(se) excel	
		cap reg clin_meaningful_imp therapist_va_ps_loo_`om_id' patient_female ///
			patient_missing_gender   i.l_dow i.l_moy i.patient_age_`om_id' first_score  if om_scale_id == `om_id'  ///
			, vce(cluster therapist_id)
			outreg2 therapist_va_ps_loo_`om_id' patient_female patient_age_* patient_ed_* /// 
			using WEAI_output/va_pref_spec_`om_id', bdec(3) append br(se) excel
			
			
		egen t_va_lo_z_`om_id' = std(therapist_va_ps_loo_`om_id') // va_zscore
		reg score_change t_va_lo_z_`om_id' patient_female ///
			patient_missing_gender  i.l_dow i.l_moy i.patient_age_`om_id' first_score if om_scale_id == `om_id' ///
			, vce(cluster therapist_id) 
			outreg2 t_va_lo_z_`om_id' patient_female patient_age_* patient_ed_* /// 
			using WEAI_output/va_pref_spec_`om_id', bdec(3) append br(se) excel
		cap reg clin_sig_improvement t_va_lo_z_`om_id'  patient_female ///
			patient_missing_gender   i.l_dow i.l_moy i.patient_age_`om_id'  first_score if om_scale_id == `om_id' ///
			, vce(cluster therapist_id)
			outreg2 t_va_lo_z_`om_id' patient_female patient_age_* patient_ed_* /// 
			using WEAI_output/va_pref_spec_`om_id', bdec(3) append br(se) excel	
		cap reg clin_meaningful_imp t_va_lo_z_`om_id' patient_female ///
			patient_missing_gender   i.l_dow i.l_moy i.patient_age_`om_id' first_score  if om_scale_id == `om_id'  ///
			, vce(cluster therapist_id)
			outreg2 t_va_lo_z_`om_id' patient_female patient_age_* patient_ed_* /// 
			using WEAI_output/va_pref_spec_`om_id', bdec(3) append br(se) excel
/*			
		// Now with therapist stuff
		reg score_change t_va_lo_z_`om_id' patient_female ///
			patient_missing_gender  i.l_dow i.l_moy i.patient_age_`om_id' first_score ///
			i.t_age t_age_missing t_lic_type_1-t_lic_type_6 t_lic_type_8 t_lic_type_9 ///  
			therapist_dbt  therapist_mi therapist_ptsd therapist_pyschodynamic therapist_demo_mbct /// THESE AREN'T M.Exclusive
			therapist_relational therapist_emotionally therapist_demo_psychoanalytic therapist_female ///
			therapist_gender_missing therapist_exp_1 therapist_exp_2 therapist_exp_4 ///
			if om_scale_id == `om_id' ///
			, vce(cluster therapist_id) 
			outreg2 t_va_lo_z_`om_id' patient_female patient_age_* patient_ed_* /// 
			using WEAI_output/va_pref_spec_`om_id', bdec(3) append br(se) excel
		reg clin_sig_improvement t_va_lo_z_`om_id'  patient_female ///
			patient_missing_gender   i.l_dow i.l_moy i.patient_age_`om_id'  first_score ///
			i.t_age t_age_missing t_lic_type_1-t_lic_type_6 t_lic_type_8 t_lic_type_9 ///  
			therapist_dbt  therapist_mi therapist_ptsd therapist_pyschodynamic therapist_demo_mbct ///
			therapist_relational therapist_emotionally therapist_demo_psychoanalytic therapist_female ///
			therapist_gender_missing therapist_exp_1 therapist_exp_2 therapist_exp_4 ///
			if om_scale_id == `om_id' ///
			, vce(cluster therapist_id)
			outreg2 t_va_lo_z_`om_id' patient_female patient_age_* patient_ed_* /// 
			using WEAI_output/va_pref_spec_`om_id', bdec(3) append br(se) excel	
		reg clin_meaningful_imp t_va_lo_z_`om_id' patient_female ///
			patient_missing_gender   i.l_dow i.l_moy i.patient_age_`om_id' first_score ///
			i.t_age t_age_missing t_lic_type_1-t_lic_type_6 t_lic_type_8 t_lic_type_9 ///  
			therapist_dbt  therapist_mi therapist_ptsd therapist_pyschodynamic therapist_demo_mbct /// 
			therapist_relational therapist_emotionally therapist_demo_psychoanalytic therapist_female ///
			therapist_gender_missing therapist_exp_1 therapist_exp_2 therapist_exp_4 ///
			if om_scale_id == `om_id'
			outreg2 t_va_lo_z_`om_id' patient_female patient_age_* patient_ed_* /// 
			using WEAI_output/va_pref_spec_`om_id', bdec(3) append br(se) excel
*/		
	// }
	// else {
//		continue
//	}
}




reg clin_sig_improvement therapist_va_ps_loo_4 patient_female ///
			patient_missing_gender first_score  if om_scale_id == 4
*restore

/*
*For later: https://blog.stata.com/2018/10/02/scheming-your-way-to-your-favorite-graph-style/
*This has some cool graphs
set scheme uncluttered 
twoway scatter observed1 observed2 day, color(%8 %8)    ||
         line    ols ar1 day            ,                 ||
         rarea   ul ll day              , color(gray%20)
         title(Seasonal Adjustment Factor) 

*Perhaps for some COVID related queries:
tsset svy_week, weekly



gen at_least_2_obs = svy_count >= 2
replace at_least_2_obs = 1 if room_therapist == room_therapist[_n+1] & at_least_2_obs[_n+1]==1
keep if at_least_2_obs
order at_least_2_obs room_therapist svy_count


levelsof om_scale_id, local(om_id_local)
foreach om_id in `om_id_local' {
preserve
keep if om_scale_id == 4 //`om_id'
** Declare time series: svy_count

xtset room_therapist svy_count
xtreg scale_score i.therapist_id, fe
** We will restrict to just those with more than 
restore	
} 

cap drop covid

gen covid = tin(2019w49, 2020w16)	
twoway (area covid svy_week,   color(gs14) yscale(r(5 15))) ///
		(tsline scale_score, lcolor(blue) lwidth(medthin)  cmissing(n)) ///
		, yscale(range(5(1)12)) ///
		xtitle("Week", size(small)) ///
		ytitle("Weekly Mean GAD7 Score", size(small)) ///
		title("General Anxiety Disorder 7 Scores over Sample Period", size(medium))
		 
*/
