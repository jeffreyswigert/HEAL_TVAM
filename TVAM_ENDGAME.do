/****************************************
This do-file starts with "vam_analysis_sample.dta" and estimates therapist effects on overall client improvement for om_scale_id_1. 
It does this by breaking the data into separate panels (based on the # of meetings a therapist has had with her client), then by running a fixed effects regression for each of these panels of overall_improvement on a vector of controls for client characteristics. The fixed effect of therapist is then predicted. A weighted average therapist effect (denoted wa_therapist_effect) is then calculated for each therapist.
Coded by: Mitch Zufelt
Date: 10/8/2020
INPUTS:
	-vam_analysis_sample.dta
***************************************/


clear
set more off

use "vam_analysis_sample.dta"


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

replace scale_score = 21-scale_score
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
//Check for significance/correct interpretation on this. 

***Now run the same regression, but broken into separate panels (broken up on the basis of how many times the therapist met with the client)
xtreg overall_improvement $X_1 if count == 2, fe vce(robust)
predict therapist_effect, u

forvalues i = 3/8 {
	qui: xtreg overall_improvement $X_1 if count == `i', fe vce(robust)
	predict t_eff, u
	replace therapist_effect = t_eff if therapist_effect == . 
	drop t_eff
}

drop if count == 1 | count >= 9  //NOTE: I only included therapist/client pairings that had 2-8 interactions, as anything outside of this didn't have enough data to be very meaningful.


***Now I create a weighted average of each therapist's effect. (I'm sure there's an easier way to find a weighted average in STATA, but I decided doing it manually would be less work then googling it. I was probably wrong.)
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
	replace yup`i' = therapist_effect if count == `i'
	by therapist_id: egen effect`i' = max(yup`i')	
}


gen wa_therapist_effect = .
by therapist_id : replace wa_therapist_effect = ((effect2*weight2)+(effect3*weight3)+(effect4*weight4)+(effect5*weight5)+(effect6*weight6)+(effect7*weight7)+(effect8*weight8))/7

drop effect* yup* weight* 

br therapist_id count therapist_effect wa_therapist_effect

save "tvam_effects_om1.dta", replace








*****************************************UNUSED STUFF*******************************
/*
**4.2 Breaking up unbalanced panel by 'count'
//really not sure how useful this is. Just exploring it
forvalues i = 2/8 {
	qui: xtreg overall_improvement $X_1 if count ==`i', fe vce(robust)
	scalar r2_`i' = e(r2_o)
	predict t_va_`i', u
	qui: sum t_va_`i', detail
	scalar sd_`i' = r(sd)
}
/* CREATE A TABLE W/ RELEVANT INFO
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
frmttable using "count_breakdown_1.doc" , replay replace
drop t_va_*
*/
**xtreg *whatever_metric* $vector_of_client_chars&base_score if count.... fe
**let's do all this for om_id_1 and if that's good, then we'll replicate for all om_id's
