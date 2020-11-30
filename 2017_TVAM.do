/*************************
Analyses for 2017
**************************/

use vam_analysis_sample1.dta, clear


keep if completed_at == "2017"

cd junk
save vam_analysis_sample2017.dta, replace


keep if om_scale_id == 1

*****************1. PRELIMINARY DATA PREP*************************
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

xtset room_id_by_p count

keep room_id room_id_by_p client_demo_user_id therapist_id om_scale_id scale_score count time_to_complete_days time_to_complete_total therapist_dbt therapist_cbt therapist_mbct therapist_mi therapist_ptsd therapist_relational therapist_emotionally therapist_psychoanalytic missing* client* therapist_license_type therapist_pro_degree therapist_gender therapist_experience media_total_duration_secs_audio media_total_duration_secs_photo media_total_duration_secs_video therapist_demo_date_of_birth
drop client_demo*


**NOTE: the fixed effects from the below regression are composed of both therapist and client fixed effects. Thus, the remainder of the data prep section serves to enable us to isolate therapist effects only. 
xtreg scale_score, fe 

**in each unique client-therapist interaction (room_id_by_p), keep only the first and last assessment score
by room_id_by_p (count), sort: gen byte first = sum(count) == 1
gen ncount = -count
by room_id_by_p (ncount), sort: egen mincount = min(ncount)
by room_id_by_p (ncount): gen byte last = 1 if sum(ncount) == mincount  

keep if first == 1 | last == 1
drop first ncount mincount last

**for each room_id_by_p, generate a variable representing the overall improvement in that client's assessment score.
by room_id_by_p (count), sort: gen frank = scale_score if count == 1
by room_id_by_p (count) : egen firstscore = min(frank)
drop frank

by room_id_by_p (count): drop if room_id_by_p == room_id_by_p[_n+1]
by room_id_by_p (count): gen overall_improvement = scale_score - firstscore

**set panel
sort therapist_id room_id_by_p
xtset therapist_id room_id_by_p 



*****************2. MODELING AND ANALYSIS*************************

global X_1 i.client_edu_lvl i.missing_edu i.client_gender i.missing_gender i.client_ethnicity i.missing_ethnicity i.client_marital_status i.missing_marrital i.client_age i.missing_age i.client_country i.client_state firstscore

xtreg overall_improvement $X_1, fe vce(robust) //WHAT THIS PRODUCES is an estimate of therapist fixed effects, or what is essentially the effect of being assigned to a particular therapist, on a client's overall_improvement. this regression holds client characteristics constant. 

***Now run the same regression, but broken into separate panels (broken up on the basis of how many times the therapist met with the client)
xtreg overall_improvement $X_1 if count == 2, fe vce(robust)
predict therapist_residual, u


forvalues i = 3/7 {
	qui: xtreg overall_improvement $X_1 if count == `i', fe vce(robust)
	predict t_res, u
	replace therapist_residual = t_res if therapist_residual == . 
	drop t_res
}

drop if count == 1 | count >= 8  //NOTE: I only included therapist/client pairings that had 2-8 interactions, as anything outside of this didn't have enough data to be very meaningful.


***Now I create a weighted average of each therapist's effect. (I'm sure there's an easier way to find a weighted average in STATA, but I decided doing it manually would be less work then googling it. I was probably wrong.)
by therapist_id: egen t_total = count(therapist_id)

forvalues i = 2/7 {
	gen hold = 0
	replace hold = 1 if count == `i' 
	by therapist_id: gen madhold = sum(hold)
	by therapist_id: egen heckahold = max(madhold)
	gen weight`i' = heckahold/t_total
	drop hold madhold heckahold 
}

drop t_total

forvalues i = 2/7 {
	gen yup`i' = 0
	replace yup`i' = therapist_residual if count == `i'
	by therapist_id: egen effect`i' = max(yup`i')	
}


gen wa_therapist_effect_1 = .
by therapist_id : replace wa_therapist_effect_1 = ((effect2*weight2)+(effect3*weight3)+(effect4*weight4)+(effect5*weight5)+(effect6*weight6)+(effect7*weight7))/6

drop effect* yup* weight* 

by therapist_id: egen count_om_1 = max(count)
drop if therapist_id == therapist_id[_n-1]

keep therapist_id wa_therapist_effect_1 count_om_1
save om1_2017.dta, replace

/*************************************************************************
OM_ID 2
**************************************************************************/

use vam_analysis_sample2017, clear


keep if om_scale_id == 2

*****************1. PRELIMINARY DATA PREP*************************

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

xtset room_id_by_p count

keep room_id room_id_by_p client_demo_user_id therapist_id om_scale_id scale_score count time_to_complete_days time_to_complete_total therapist_dbt therapist_cbt therapist_mbct therapist_mi therapist_ptsd therapist_relational therapist_emotionally therapist_psychoanalytic missing* client* therapist_license_type therapist_pro_degree therapist_gender therapist_experience media_total_duration_secs_audio media_total_duration_secs_photo media_total_duration_secs_video therapist_demo_date_of_birth
drop client_demo*

**in each unique client-therapist interaction (room_id_by_p), keep only the first and last assessment score
by room_id_by_p (count), sort: gen byte first = sum(count) == 1
gen ncount = -count
by room_id_by_p (ncount), sort: egen mincount = min(ncount)
by room_id_by_p (ncount): gen byte last = 1 if sum(ncount) == mincount  

keep if first == 1 | last == 1
drop first ncount mincount last

**for each room_id_by_p, generate a variable representing the overall improvement in that client's assessment score.
by room_id_by_p (count), sort: gen frank = scale_score if count == 1
by room_id_by_p (count) : egen firstscore = min(frank)
drop frank

by room_id_by_p (count): drop if room_id_by_p == room_id_by_p[_n+1]
by room_id_by_p (count): gen overall_improvement = scale_score - firstscore

**set panel
sort therapist_id room_id_by_p
xtset therapist_id room_id_by_p 

*****************2. MODELING AND ANALYSIS*************************

global X_1 i.client_edu_lvl i.missing_edu i.client_gender i.missing_gender i.client_ethnicity i.missing_ethnicity i.client_marital_status i.missing_marrital i.client_age i.missing_age i.client_country i.client_state firstscore

xtreg overall_improvement $X_1 if count == 2, fe vce(robust)
predict therapist_residual, u

forvalues i = 3/7 {
	qui: xtreg overall_improvement $X_1 if count == `i', fe vce(robust)
	predict t_res, u
	replace therapist_residual = t_res if therapist_residual == . 
	drop t_res
}

drop if count == 1 | count >= 8 

***Now I create a weighted average of each therapist's effect. 
by therapist_id: egen t_total = count(therapist_id)

forvalues i = 2/7 {
	gen hold = 0
	replace hold = 1 if count == `i' 
	by therapist_id: gen madhold = sum(hold)
	by therapist_id: egen heckahold = max(madhold)
	gen weight`i' = heckahold/t_total
	drop hold madhold heckahold 
}

drop t_total

forvalues i = 2/7 {
	gen yup`i' = 0
	replace yup`i' = therapist_residual if count == `i'
	by therapist_id: egen effect`i' = max(yup`i')	
}


gen wa_therapist_effect_2 = .
by therapist_id : replace wa_therapist_effect_2 = ((effect2*weight2)+(effect3*weight3)+(effect4*weight4)+(effect5*weight5)+(effect6*weight6)+(effect7*weight7))/6

drop effect* yup* weight* 

by therapist_id: egen count_om_2 = max(count) 
drop if therapist_id == therapist_id[_n-1]

keep therapist_id wa_therapist_effect_2 count_om_2
save om2_2017.dta, replace

/*************************************************************************
OM_ID 3
**************************************************************************/

use vam_analysis_sample2017, clear


keep if om_scale_id == 3

*****************1. PRELIMINARY DATA PREP*************************

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

xtset room_id_by_p count

keep room_id room_id_by_p client_demo_user_id therapist_id om_scale_id scale_score count time_to_complete_days time_to_complete_total therapist_dbt therapist_cbt therapist_mbct therapist_mi therapist_ptsd therapist_relational therapist_emotionally therapist_psychoanalytic missing* client* therapist_license_type therapist_pro_degree therapist_gender therapist_experience media_total_duration_secs_audio media_total_duration_secs_photo media_total_duration_secs_video therapist_demo_date_of_birth
drop client_demo*

**in each unique client-therapist interaction (room_id_by_p), keep only the first and last assessment score
by room_id_by_p (count), sort: gen byte first = sum(count) == 1
gen ncount = -count
by room_id_by_p (ncount), sort: egen mincount = min(ncount)
by room_id_by_p (ncount): gen byte last = 1 if sum(ncount) == mincount  

keep if first == 1 | last == 1
drop first ncount mincount last

**for each room_id_by_p, generate a variable representing the overall improvement in that client's assessment score.
by room_id_by_p (count), sort: gen frank = scale_score if count == 1
by room_id_by_p (count) : egen firstscore = min(frank)
drop frank

by room_id_by_p (count): drop if room_id_by_p == room_id_by_p[_n+1]
by room_id_by_p (count): gen overall_improvement = scale_score - firstscore

**set panel
sort therapist_id room_id_by_p
xtset therapist_id room_id_by_p 

*****************2. MODELING AND ANALYSIS*************************

global X_1 i.client_edu_lvl i.missing_edu i.client_gender i.missing_gender i.client_ethnicity i.missing_ethnicity i.client_marital_status i.missing_marrital i.client_age i.missing_age i.client_country i.client_state firstscore

xtreg overall_improvement $X_1 if count == 2, fe vce(robust)
predict therapist_residual, u

forvalues i = 3/7 {
	qui: xtreg overall_improvement $X_1 if count == `i', fe vce(robust)
	predict t_res, u
	replace therapist_residual = t_res if therapist_residual == . 
	drop t_res
}

drop if count == 1 | count >= 8 

***Now I create a weighted average of each therapist's effect. 
by therapist_id: egen t_total = count(therapist_id)

forvalues i = 2/7 {
	gen hold = 0
	replace hold = 1 if count == `i' 
	by therapist_id: gen madhold = sum(hold)
	by therapist_id: egen heckahold = max(madhold)
	gen weight`i' = heckahold/t_total
	drop hold madhold heckahold 
}

drop t_total

forvalues i = 2/7 {
	gen yup`i' = 0
	replace yup`i' = therapist_residual if count == `i'
	by therapist_id: egen effect`i' = max(yup`i')	
}


gen wa_therapist_effect_3 = .
by therapist_id : replace wa_therapist_effect_3 = ((effect2*weight2)+(effect3*weight3)+(effect4*weight4)+(effect5*weight5)+(effect6*weight6)+(effect7*weight7))/6

drop effect* yup* weight* 

by therapist_id: egen count_om_3 = max(count) 
drop if therapist_id == therapist_id[_n-1]

keep therapist_id wa_therapist_effect_3 count_om_3
save om3_2017.dta, replace

/*************************************************************************
OM_ID 4
**************************************************************************/

use vam_analysis_sample2017, clear


keep if om_scale_id == 4

*****************1. PRELIMINARY DATA PREP*************************

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

xtset room_id_by_p count

keep room_id room_id_by_p client_demo_user_id therapist_id om_scale_id scale_score count time_to_complete_days time_to_complete_total therapist_dbt therapist_cbt therapist_mbct therapist_mi therapist_ptsd therapist_relational therapist_emotionally therapist_psychoanalytic missing* client* therapist_license_type therapist_pro_degree therapist_gender therapist_experience media_total_duration_secs_audio media_total_duration_secs_photo media_total_duration_secs_video therapist_demo_date_of_birth
drop client_demo*

**in each unique client-therapist interaction (room_id_by_p), keep only the first and last assessment score
by room_id_by_p (count), sort: gen byte first = sum(count) == 1
gen ncount = -count
by room_id_by_p (ncount), sort: egen mincount = min(ncount)
by room_id_by_p (ncount): gen byte last = 1 if sum(ncount) == mincount  

keep if first == 1 | last == 1
drop first ncount mincount last

**for each room_id_by_p, generate a variable representing the overall improvement in that client's assessment score.
by room_id_by_p (count), sort: gen frank = scale_score if count == 1
by room_id_by_p (count) : egen firstscore = min(frank)
drop frank

by room_id_by_p (count): drop if room_id_by_p == room_id_by_p[_n+1]
by room_id_by_p (count): gen overall_improvement = scale_score - firstscore

**set panel
sort therapist_id room_id_by_p
xtset therapist_id room_id_by_p 

*****************2. MODELING AND ANALYSIS*************************

xtreg overall_improvement $X_1 if count == 2, fe vce(robust)
predict therapist_residual, u

forvalues i = 3/8 {
	qui: xtreg overall_improvement $X_1 if count == `i', fe vce(robust)
	predict t_res, u
	replace therapist_residual = t_res if therapist_residual == . 
	drop t_res
}

drop if count == 1 | count >= 9 

***Now I create a weighted average of each therapist's effect. 
by therapist_id: egen t_total = count(therapist_id)

forvalues i = 2/8 {
	gen hold = 0
	replace hold = 1 if count == `i' 
	by therapist_id: gen madhold = sum(hold)
	by therapist_id: egen heckahold = max(madhold)
	gen weight`i' = heckahold/t_total
	drop hold madhold heckahold 
}

drop t_total

forvalues i = 2/8 {
	gen yup`i' = 0
	replace yup`i' = therapist_residual if count == `i'
	by therapist_id: egen effect`i' = max(yup`i')	
}


gen wa_therapist_effect_4 = .
by therapist_id : replace wa_therapist_effect_4 = ((effect2*weight2)+(effect3*weight3)+(effect4*weight4)+(effect5*weight5)+(effect6*weight6)+(effect7*weight7)+(effect8*weight8))/7

drop effect* yup* weight* 

by therapist_id: egen count_om_4 = max(count) 
drop if therapist_id == therapist_id[_n-1]

keep therapist_id wa_therapist_effect_4 count_om_4
save om4_2017.dta, replace

/*************************************************************************
OM_ID 5
**************************************************************************/

use vam_analysis_sample2017, clear


keep if om_scale_id == 5

*****************1. PRELIMINARY DATA PREP*************************

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

xtset room_id_by_p count

keep room_id room_id_by_p client_demo_user_id therapist_id om_scale_id scale_score count time_to_complete_days time_to_complete_total therapist_dbt therapist_cbt therapist_mbct therapist_mi therapist_ptsd therapist_relational therapist_emotionally therapist_psychoanalytic missing* client* therapist_license_type therapist_pro_degree therapist_gender therapist_experience media_total_duration_secs_audio media_total_duration_secs_photo media_total_duration_secs_video therapist_demo_date_of_birth
drop client_demo*

**in each unique client-therapist interaction (room_id_by_p), keep only the first and last assessment score
by room_id_by_p (count), sort: gen byte first = sum(count) == 1
gen ncount = -count
by room_id_by_p (ncount), sort: egen mincount = min(ncount)
by room_id_by_p (ncount): gen byte last = 1 if sum(ncount) == mincount  

keep if first == 1 | last == 1
drop first ncount mincount last

**for each room_id_by_p, generate a variable representing the overall improvement in that client's assessment score.
by room_id_by_p (count), sort: gen frank = scale_score if count == 1
by room_id_by_p (count) : egen firstscore = min(frank)
drop frank

by room_id_by_p (count): drop if room_id_by_p == room_id_by_p[_n+1]
by room_id_by_p (count): gen overall_improvement = scale_score - firstscore

**set panel
sort therapist_id room_id_by_p
xtset therapist_id room_id_by_p 

*****************2. MODELING AND ANALYSIS*************************

xtreg overall_improvement $X_1 if count == 2, fe vce(robust)
predict therapist_residual, u

forvalues i = 3/8 {
	qui: xtreg overall_improvement $X_1 if count == `i', fe vce(robust)
	predict t_res, u
	replace therapist_residual = t_res if therapist_residual == . 
	drop t_res
}

drop if count == 1 | count >= 9 

***Now I create a weighted average of each therapist's effect. 
by therapist_id: egen t_total = count(therapist_id)

forvalues i = 2/8 {
	gen hold = 0
	replace hold = 1 if count == `i' 
	by therapist_id: gen madhold = sum(hold)
	by therapist_id: egen heckahold = max(madhold)
	gen weight`i' = heckahold/t_total
	drop hold madhold heckahold 
}

drop t_total

forvalues i = 2/8 {
	gen yup`i' = 0
	replace yup`i' = therapist_residual if count == `i'
	by therapist_id: egen effect`i' = max(yup`i')	
}


gen wa_therapist_effect_5 = .
by therapist_id : replace wa_therapist_effect_5 = ((effect2*weight2)+(effect3*weight3)+(effect4*weight4)+(effect5*weight5)+(effect6*weight6)+(effect7*weight7)+(effect8*weight8))/7

drop effect* yup* weight* 

by therapist_id: egen count_om_5 = max(count) 
drop if therapist_id == therapist_id[_n-1]

keep therapist_id wa_therapist_effect_5 count_om_5
save om5_2017.dta, replace


/************************************************************************
2017 OVERALL
*************************************************************************/

use om1_2017.dta, clear

merge 1:1 therapist_id using om2_2017.dta, nogen
merge 1:1 therapist_id using om3_2017.dta, nogen
merge 1:1 therapist_id using om4_2017.dta, nogen
merge 1:1 therapist_id using om5_2017.dta, nogen

foreach i in wa_therapist_effect_1 wa_therapist_effect_2 wa_therapist_effect_3 wa_therapist_effect_4 wa_therapist_effect_5 count_om_1 count_om_2 count_om_3 count_om_4 count_om_5 {
	replace `i' = 0 if (`i' >= .) 
}
gen total_count = count_om_1+count_om_2+count_om_3+count_om_4+count_om_5

gen wa_therapist_effect_2017 = ((wa_therapist_effect_1*(count_om_1/total_count))+(wa_therapist_effect_2*(count_om_2/total_count))+(wa_therapist_effect_3*(count_om_3/total_count))+(wa_therapist_effect_4*(count_om_4/total_count))+(wa_therapist_effect_5*(count_om_5/total_count)))

rename total_count total_count_2017
keep therapist_id total_count_2017 wa_therapist_effect_2017

cd ..
save va_2017.dta, replace
