/******************************************************************
This performs VA analysis on the subsection of vam_analysis_sample.dta where om_scale_id == 4. 

		For "Measuring Therapist Value-Added: Evidence from an Online Therapy Platform"

Coded by: Mitchell Zufelt

Last Updated: 05-13-2020

INPUTS: 
		- vam_analysis_sample.dta
	
***********************************************************************
***********************************************************************
*********************************************************************
*********************************************************************/
clear
set more off

use "E:\vam_analysis_sample.dta"

keep if om_scale_id == 4

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
save "E:\om_scale_id_4_analysis.dta", replace

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
eststo te_model

**1.4 The therapist's fixed effect is equal to:
predict therapist_effect, u
br therapist_id therapist_effect


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

//Naive: How a therapist's fixed characteristics affect his therapist_effect
reg therapist_effect $p_char , vce(robust)
outreg2 using explain_va, replace excel dec(3) label

//Include effect of therapist/client match characteristics
reg therapist_effect $p_char $match_char, vce(robust)
outreg2 using explain_va, append excel dec(3) label


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

**3.1 Generate client_specific improvement variable (nonparametric)
gen byte nonmissing = !missing(overall_improvement)  

bysort nonmissing therapist_id : gen total = sum(overall_improvement) if nonmissing
by nonmissing therapist_id : replace total = total[_N]

by nonmissing therapist_id : gen nmcount = _N if nonmissing

gen client_specific = (total - overall_improvement) / (nmcount - 1) //In words, this is the avg of a therapist's effect (in terms of overall_improvement) for each of his clients, excluding the current observation.
drop nonmissing total nmcount

save "working_om_4.dta", replace

**3.2 CAUSAL EFFECT OF THERAPIST VA ON CLIENT OUTCOMES

egen zclient_specific = std(client_specific)
egen zoverall_improvement = std(overall_improvement)

reg overall_improvement client_specific
reg overall_improvement client_specific $X_1

reg overall_improvement zclient_specific 
reg overall_improvement zclient_specific $X_1 
reg overall_improvement zclient_specific $X_1 $match_char

reg zoverall_improvement zclient_specific $X_1
 

**************************************************************************
********************************REPORTING*********************************
**************************************************************************

mkdir reporting
cd reporting
mkdir tables
mkdir figures


**Fig. 1: Histogram of VA distribution
histogram therapist_effect, bin(100) fcolor(navy) xscale(range(-3 3)) title(Therapist VA Distribution) xtitle(Therapist Value-Added)
graph save "Graph" "E:\reporting\figures\VA_distribution.gph", replace

scalar iqr = .527091 + .57836
scalar outlier = 1.5*iqr
count if therapist_effect > (.527091+outlier) | therapist_effect < (-.57836 - outlier)
drop if therapist_effect > (.527091+outlier) | therapist_effect < (-.57836 - outlier)

histogram therapist_effect, bin(50) fcolor(navy) xtitle(Therapist Value-Added) xscale(range(-3 3)) title("Therapist VA Distribution (Outliers Omitted)")
graph save "Graph" "E:\reporting\figures\VA_distribution_nooutliers.gph", replace


**Fig. 2: Mean Gain Scores

use "E:\working_om_4.dta", clear

//TODO: Make this section replicable for other om_scale_id's; I suggest using estpost codebook and saving the quartiles from that as scalars
scalar one = -.57836
scalar two = -.046796
scalar three = .527091
scalar four = 14.688753
gen quartile = 1
replace quartile = 2 if therapist_effect > one & therapist_effect <= two
replace quartile = 3 if therapist_effect > two & therapist_effect <= three
replace quartile = 4 if therapist_effect > three & therapist_effect <= four
//scalar ci = 1.96*(1.035406/sqrt(54973))
cibar therapist_effect , over(quartile) level(95) bargap(5) 
graph save "Graph" "E:\reporting\figures\mean_VA_by_quartile.gph", replace


**Fig. 3: Summary Statistics

cd "E:\reporting\tables"


//I need to learn a better way of making tables. I used this and did a ton of copy/pasting in order to fill out a table.

tab therapist_license_type, sort matcell(freq) matrow(label)
putexcel A1=("Therapist License Type") B2=("Freq.") C2=("Percent")
putexcel A3=matrix(label) B3=matrix(freq) C3=matrix(freq/r(N))



**Fig. 4: Explanation of Therapist VA : Regression Output

//already done in lines 126-131


**Fig. 5: Causal Effect of Therapist VA on Individual Client Outcomes

reg overall_improvement zclient_specific 
outreg2 using va_effect, replace excel dec(3) label

reg overall_improvement zclient_specific $X_1 
outreg2 using va_effect, append excel dec(3) label

reg overall_improvement zclient_specific $X_1 $match_char
outreg2 using va_effect, append excel dec(3) label
