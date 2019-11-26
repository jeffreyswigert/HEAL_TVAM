/*
This .do file performs data clearning and prep to generate the analysis sample for 
"Measuring the impacts of therapists: evidence from a value-added approach on an online therapy platform"


*/



clear
set more off, perm
cd "/Users/jeffreyswigert/Desktop/TalkSpace/Data/"

import delimited "client_demographics.csv", clear varn(1)
rename user_id client_id  //THIS WILL BE IMPORTANT
global date_revised "20191121.dta"



rename gender client_gender
rename age client_age
rename marital_status client_marital_status
rename country client_country
rename state client_state
rename acuity client_acuity
rename primary_condition client_primary_condition
sort room_id

replace client_primary_condition = "Relationship, Stress" if room_id == 111170
duplicates drop
save client_dems_primary_condition.dta, replace

import delimited "counts_of_live_video.csv", delim(",") clear varn(1)
save ts_video.dta, replace

import delimited "counts_of_media_messaging.csv",  delim(",") clear varn(1) // What is mm_count?
save ts_media_stats.dta, replace

import delimited "outcome_survey_results.csv",  delim(",") clear varn(1)
save ts_survey_results.dta, replace 
 
import delimited "total_engage_metrics.csv",  delim(",") clear varn(1)
save ts_tot_engage.dta, replace 

import delimited "therapist_states_of_license2019-11-20",  delim(",") clear varn(1)
sort therapist_id
//TODO: need to reshape so that therapist_id uniquely identifies observations

save ts_therapist_licences.dta, replace 


import excel "therapist_demographics.xlsx", clear first
drop A
save ts_therapist_dems.dta, replace

// MERGE to Create Pilot Sample

use ts_therapist_dems.dta, clear
sort therapist_id
drop if therapist_id == .
global t_variables "platform_join_date therapist_type date_of_birth professional_degree gender license_type expertise DBT CBT MBCT MI PTSD Psychodynamic Relational Emotionally Psychoanalytic States_of_Licensure"
foreach x in $t_variables {
	rename `x' therapist_`x'
}
drop U
save ts_therapist_dems.dta, replace

use ts_survey_results.dta, clear

//Survey Results

sort therapist_id
save ts_survey_results.dta, replace 


merge m:1 therapist_id using ts_therapist_dems.dta, sorted
keep if _merge==3
drop _merge

//Clean up ïroom_id from varname
cap rename ïroom_id room_id
sort room_id

// Client demographics
merge m:1 room_id using client_dems_primary_condition.dta, sorted
drop if _merge ~=3
drop _merge

// Format/Convert dates, clean up the data

gen date_survey_completed = date(completed_date, "MD20Y")
format date_survey_completed %td
duplicates drop

rename education_level client_education_level
rename first_time_in_therapy client_first_time_in_therapy


// Add in licensure data
merge m:1 therapist_id using "ts_therapist_licences.dta"

// Add in identifier for consulting therapists

gen consulting_therapist = inlist(therapist_id, 77818,	1076,	136956,	70996,	109975,	109977,	109979,	83200,	125625,	96847,	44499,	35074,	60601,	184459,	76600,	171759,	66956,	48523,	70969,	37102,	33617,	946680,	887264,	232158,	167218,	1218443,	20707,	52460,	11814)
// TODO:  The initial surveys are administered, a lot of the time, by the consulting therapist, it appears
//        Baseline for whatever therapist they end up with should be the consulting therapists om_scale_id scores.



save TVAM_analysis_sample_$date_revised , replace


// SUMMARY STATS
* How many clients do we observe?

sort client_id therapist_id
count if client_id ~= client_id[_n-1] //11,571

* How many therapists do we have?

sort therapist_id
count if therapist_id != therapist_id[_n-1]  // 1,920 therapists

* Number of clients who have a therapist that is not their gender
count if client_gender ~= therapist_gender
  // 45,814


  
  
  
  
  
* How many clients does a given therapist have?
/*
preserve
collapse client_gender client_education_level client_age client_marital_status client_state client_first_time_in_therapy client_acuity client_primary_condition  , by(client_id therapist_id)
restore
*/
* How many therapists does a given client end up having?


// What is the distribution of therapists across states?
/*
use ts_therapist_licences.dta, clear
collapse (firstnm) licence_type = therapist_license_type (percent) percent_ts_therapists = therapist_id, by(therapist_license_state) 
rename therapist_license_state state
/*
maptile percent_ts_therapists, geo(state) fcolor(Blues2) ///
	twopt(title("Talkspace Therapist Distribution across the U.S.") ///
	legend(title("Percent of all TS Therapists", size(vsmall)))) ///
	savegraph(therapist_dist_US_3.png)
*/
sort state
save ts_supply_of_therapy.dta, replace	
	
// What is the distribution of clients across the US?	
use client_dems_primary_condition.dta, clear
rename client_state state
collapse (percent) percent_ts_clients = client_id, by(state) 
/*
maptile percent_ts_clients, geo(state) fcolor(Greens2) ///
	twopt(title("Talkspace Client Distribution across the U.S.") ///
	legend(title("Percent of all TS Clients", size(vsmall)))) ///
	savegraph(client_dist_US_3.png)
*/
sort state

save ts_demand_for_therapy.dta, replace	

merge 1:1 state using ts_supply_of_therapy.dta, sorted
drop _merge

gen mkt_surplus = percent_ts_therapists - percent_ts_clients
maptile mkt_surplus, geo(state) fcolor(PuBuGn) ///
	twopt(title("Talkspace Supply - Demand across the U.S.") ///
	legend(title("Percent market surplus (deficit)", size(vsmall)))) ///
	savegraph(mkt_mismatch_6.png)


	
