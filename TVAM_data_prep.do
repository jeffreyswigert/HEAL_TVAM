/******************************************************************
DATA CLEANING AND PREP FOR "Measuring the Impacts of Therapists: A Value-Added Approach Using Evidence from an Online Therapy Platform"

Coded by: Mitchell Zufelt and Jeff Swigert

Last Updated: 02-27-2020

INPUTS:
		- TalkSpace_Base.csv
*****************************************************************/

clear all
set more off, perm
cd "E:/"

// Load base data
import delimited TalkSpace_Base.csv, varn(1) bindquote(strict) clear


//keep only variables that are meaningful to our analysis
keep user_room_survey_id room_id therapist_id om_scale_id scale_score count time_to_complete_days time_to_complete_total client_demo_user_id client_demo_gender_customer client_demo_education_level client_demo_ethnicity client_demo_marital_status client_demo_country client_demo_state client_demo_age_customer therapist_demo_platform_join_dat therapist_demo_date_of_birth therapist_demo_professional_degr therapist_demo_gender therapist_demo_therapist_experie therapist_demo_license_type therapist_demo_dbt therapist_demo_cbt therapist_demo_mbct therapist_demo_mi therapist_demo_ptsd therapist_demo_psychodynamic therapist_demo_relational therapist_demo_emotionally therapist_demo_psychoanalytic media_total_duration_secs_audio media_total_duration_secs_photo media_total_duration_secs_video therapist_demo_date_of_birth
//save vam_analysis_sample.dta, replace

**Variables that I elected not to keep, but that may be valuable: client_demo_plan_type_id; client_demo_plan_name; client_demo_primary_condition; therapist_demo_expertise 

//TODO: we have therapist birthdate--would it be worthwhile to (using that) code up a variable for therapist age? How would this var affect our analysis?


//change all of the therapist type vars to 1 & 0 (not true or false)
gen therapist_dbt = 1 if therapist_demo_dbt == "True"
replace therapist_dbt = 0 if therapist_dbt != 1
drop therapist_demo_dbt

gen therapist_cbt = 1 if therapist_demo_cbt == "True"
replace therapist_cbt = 0 if therapist_cbt != 1
drop therapist_demo_cbt

gen therapist_mbct = 1 if therapist_demo_mbct == "True"
replace therapist_mbct = 0 if therapist_mbct != 1
drop therapist_demo_mbct

gen therapist_mi = 1 if therapist_demo_mi == "True"
replace therapist_mi = 0 if therapist_mi != 1
drop therapist_demo_mi

gen therapist_ptsd = 1 if therapist_demo_ptsd == "True"
replace therapist_ptsd = 0 if therapist_ptsd != 1
drop therapist_demo_ptsd

gen therapist_pyschodynamic = 1 if therapist_demo_psychodynamic == "True"
replace therapist_pyschodynamic = 0 if therapist_pyschodynamic != 1
drop therapist_demo_psychodynamic

gen therapist_relational = 1 if therapist_demo_relational == "True"
replace therapist_relational = 0 if therapist_relational != 1
drop therapist_demo_relational

gen therapist_emotionally = 1 if therapist_demo_emotionally == "True"
replace therapist_emotionally = 0 if therapist_emotionally != 1
drop therapist_demo_emotionally

gen therapist_psychoanalytic = 1 if therapist_demo_psychoanalytic == "True"
replace therapist_psychoanalytic = 0 if therapist_psychoanalytic != 1
drop therapist_demo_psychoanalytic	


//the following two lines insure that the difference between any two neighboring room_id's is never less than two (because it would mess with our computations otherwise).// 
replace room_id = room_id + 1 if room_id[_n-1] == room_id - 1 
replace room_id = room_id + 1 if room_id[_n-1] == room_id + 1


order user_room_survey_id room_id client_demo_user_id therapist_id 

//Generate factor variables

gen missing_edu = client_demo_education_level=="NA"

gen client_edu_lvl = . 
replace client_edu_lvl = 3 if client_demo_education_level == "3"
replace client_edu_lvl = 4 if client_demo_education_level == "4"
replace client_edu_lvl = 5 if client_demo_education_level == "5"
replace client_edu_lvl = 6 if client_demo_education_level == "6"
replace client_edu_lvl = 7 if client_demo_education_level == "7"
replace client_edu_lvl = 8 if client_demo_education_level == "8"
replace client_edu_lvl = 12 if client_demo_education_level == "High School"
replace client_edu_lvl = 16 if client_demo_education_level == "Bachelor Degree or Higher"
replace client_edu_lvl = 17 if client_demo_education_level == "NA"

label variable client_edu_lvl "Client Education Level"
label define c_edu 12 "High School" 16 "Bachelor Degree or Higher" 17 "NA", replace
label values client_edu_lvl c_edu
***********************************************************
gen missing_gender = client_demo_gender_customer=="NA"

gen client_gender = .
replace client_gender = 1 if client_demo_gender_customer == "Female"
replace client_gender = 2 if client_demo_gender_customer == "Male"
replace client_gender = 3 if client_demo_gender_customer == "Gender Other"
replace client_gender = 4 if client_demo_gender_customer == "Gender Queer"
replace client_gender = 5 if client_demo_gender_customer == "Non-binary"
replace client_gender = 6 if client_demo_gender_customer == "Transgender Female"
replace client_gender = 7 if client_demo_gender_customer == "Transgender Male"
replace client_gender = 8 if client_demo_gender_customer == "NA"

label variable client_gender "Client Gender"
label define c_gender 1 "Female" 2 "Male" 3 "Gender Other" 4 "Gender Queer" 5 "Non-binary" 6 "Transgender Female" 7 "Transgender Male" 8 "NA"
label values client_gender c_gender
***********************************************************
gen missing_ethnicity = client_demo_ethnicity=="NA"

gen client_ethnicity = .
replace client_ethnicity = 1 if client_demo_ethnicity == "Caucasian"
replace client_ethnicity = 2 if client_demo_ethnicity == "African American"
replace client_ethnicity = 3 if client_demo_ethnicity == "Asian"
replace client_ethnicity = 4 if client_demo_ethnicity == "Hispanic"
replace client_ethnicity = 5 if client_demo_ethnicity == "Native American"
replace client_ethnicity = 6 if client_demo_ethnicity == "Other"
replace client_ethnicity = 7 if client_demo_ethnicity == "Declined"
replace client_ethnicity = 8 if client_demo_ethnicity == "NA"

label variable client_ethnicity "Client Ethnicity"
label define c_ethnicity 1 "Caucasian" 2 "African American" 3 "Asian" 4 "Hispanic" 5 "Native American" 6 "Other" 7 "Declined" 8 "NA"
label values client_ethnicity c_ethnicity
***********************************************************
gen missing_marrital = client_demo_marital_status=="NA"

gen client_marital_status = .
replace client_marital_status = 1 if client_demo_marital_status == "single"
replace client_marital_status = 2 if client_demo_marital_status == "married"
replace client_marital_status = 3 if client_demo_marital_status == "living with a partner"
replace client_marital_status = 4 if client_demo_marital_status == "in a relationship"
replace client_marital_status = 5 if client_demo_marital_status == "divorced"
replace client_marital_status = 6 if client_demo_marital_status == "separated"
replace client_marital_status = 7 if client_demo_marital_status == "widowed"
replace client_marital_status = 8 if client_demo_marital_status == "NA"

label variable client_marital_status "Client Marital Status"
label define c_marital 1 "single" 2 "married" 3 "living with a partner" 4 "in a relationship" 5 "divorced" 6 "separated" 7 "widowed" 8 "NA"
label values client_marital_status c_marital
************************************************************
gen missing_age = client_demo_age_customer=="NA"

gen client_age = .
replace client_age = 1 if client_demo_age_customer == "0-17"
replace client_age = 2 if client_demo_age_customer == "18-25"
replace client_age = 3 if client_demo_age_customer == "26-35"
replace client_age = 4 if client_demo_age_customer == "36-49"
replace client_age = 5 if client_demo_age_customer == "50+"
replace client_age = 6 if client_demo_age_customer == "NA"

label variable client_age "Client Age"
label define c_age 1 "0-17" 2 "18-25" 3 "26-35" 4 "36-49" 5 "50+" 6 "NA"
label values client_age c_age
*************************************************************
gen therapist_gender = .
replace therapist_gender = 1 if therapist_demo_gender == "Female"
replace therapist_gender = 2 if therapist_demo_gender == "Male"
replace therapist_gender = 3 if therapist_demo_gender == "0"

label variable therapist_gender "Therapist Gender"
label define t_gender 1 "Female" 2 "Male" 3 "0"
label values therapist_gender t_gender
**************************************************************
gen therapist_experience = .
replace therapist_experience = 1 if therapist_demo_therapist_experie == "no real experience yet"
replace therapist_experience = 2 if therapist_demo_therapist_experie == "less than 5 years"
replace therapist_experience = 3 if therapist_demo_therapist_experie == "5-10 years"
replace therapist_experience = 4 if therapist_demo_therapist_experie == "more than 10 years"

label variable therapist_experience "Therapist Experience"
label define t_exp 1 "no real experience yet" 2 "less than 5 years" 3 "5-10 years" 4 "more than 10 years"
label values therapist_experience t_exp
***************************************************************
//There are an overwhelming amount of options for "country," but only the top three (US, CA, and GB) have more than 1% of the sample data. Any observation not from one of those three countries is given value "4"
gen client_country = 4 
replace client_country = 1 if client_demo_country == "US"
replace client_country = 2 if client_demo_country == "CA"
replace client_country = 3 if client_demo_country == "GB"

label variable client_country "Client Country"
label define c_country 1 "US" 2 "CA" 3 "GB" 4 "Other"
label values client_country c_country 
***************************************************************
//US is divided into 6 geographic regions; these have been decided arbitrarily. TODO: if important, revise this variable.
gen client_state = 1
replace client_state = 2 if client_demo_state == "CO" | client_demo_state == "ND" | client_demo_state == "SD" | client_demo_state == "NE" | client_demo_state == "KS" | client_demo_state == "OK" | client_demo_state == "TX" | client_demo_state == "AR" | client_demo_state == "MO"
replace client_state = 3 if client_demo_state == "MN" | client_demo_state == "WI" | client_demo_state == "IA" | client_demo_state == "IL" | client_demo_state == "IN" | client_demo_state == "MI" | client_demo_state == "OH" | client_demo_state == "KY" | client_demo_state == "TN" | client_demo_state == "WV"
replace client_state = 4 if client_demo_state == "LA" | client_demo_state == "MS" | client_demo_state == "AL" | client_demo_state == "GA" | client_demo_state == "FL" | client_demo_state == "NC" | client_demo_state == "SC" | client_demo_state == "VA" | client_demo_state == "MD"
replace client_state = 5 if client_demo_state == "DE" | client_demo_state == "PA" | client_demo_state == "NJ" | client_demo_state == "NY" | client_demo_state == "CT" | client_demo_state == "RI" | client_demo_state == "MA" | client_demo_state == "VT" | client_demo_state == "NH" | client_demo_state == "ME" | client_demo_state == "DC"
replace client_state = 6 if client_demo_state == "AK" | client_demo_state == "HI" 

label variable client_state "Client's home state, where the US has been divided into six geographic regions"
*******************************************************
//This one also puts all those license types representative of less than 1% of sampled therapists into the "Other" group
gen therapist_license_type = .
replace therapist_license_type = 1 if therapist_demo_license_type == "LCSW" | therapist_demo_license_type == "LICSW" | therapist_demo_license_type == "LCSW-R" | therapist_demo_license_type == "LCSW-C" | therapist_demo_license_type == "LSMW"
replace therapist_license_type = 2 if therapist_demo_license_type == "Psychologist"
replace therapist_license_type = 3 if therapist_demo_license_type == "LPC" | therapist_demo_license_type == "LPC-S"
replace therapist_license_type = 4 if therapist_demo_license_type == "LMFT"
replace therapist_license_type = 5 if therapist_demo_license_type == "LMHC"
replace therapist_license_type = 6 if therapist_demo_license_type == "LCPC" 
replace therapist_license_type = 7 if therapist_demo_license_type == "LPCC"
replace therapist_license_type = 8 if therapist_license_type == . 

label variable therapist_license_type "Therapist License Type"
label define t_lic 1 "LCSW" 2 "Psychologist" 3 "LPC" 4 "LMFT" 5 "LMHC" 6 "LCPC" 7 "LPCC" 8 "Other"
label values therapist_license_type t_lic 
*******************************************************
//Again, all identifiers with less than 1% of the sample placed into "Other" group
gen therapist_pro_degree = .
replace therapist_pro_degree = 1 if therapist_demo_professional_degr == "Masters in Social Work" | therapist_demo_professional_degr == "Masters of Science in Social Work"
replace therapist_pro_degree = 2 if therapist_demo_professional_degr == "Masters in Counseling" | therapist_demo_professional_degr == "Masters in Mental Health Counseling" | therapist_demo_professional_degr == "Masters in Clinical Mental Health Counseling"
replace therapist_pro_degree = 3 if therapist_demo_professional_degr == "Masters in Counseling Psychology"
replace therapist_pro_degree = 4 if therapist_demo_professional_degr == "Masters in Marriage and family therapy"
replace therapist_pro_degree = 5 if therapist_demo_professional_degr == "Masters in Psychology"
replace therapist_pro_degree = 6 if therapist_demo_professional_degr == "Doctorate in Psychology (PhD)" | therapist_demo_professional_degr == "Psychology Doctor (PsyD)"
replace therapist_pro_degree = 7 if therapist_pro_degree==.

label variable therapist_pro_degree "Therapist Professional Degree"
label define t_pro 1 "Masters in Social Work" 2 "Masters in Counseling" 3  "Masters in Counseling Psychology" 4 "Masters in Marriage and Family Therapy" 5 "Masters in Psychology"  6 "Doctorate in Psychology (PhD or PsyD)" 7 "Other" 
label values therapist_pro_degree t_pro

label variable time_to_complete_days "The length of time, in days, that the most recent assessment score took to complete"
label variable time_to_complete_total "length of time from start to final assessment score"

replace media_total_duration_secs_audio = "0" if media_total_duration_secs_audio == "NA"
replace media_total_duration_secs_photo = "0" if media_total_duration_secs_photo == "NA"
replace media_total_duration_secs_video = "0" if media_total_duration_secs_video == "NA"


destring media_total_duration_secs_audio, float replace
destring media_total_duration_secs_photo, float replace
destring media_total_duration_secs_video, float replace

/*//Generate therapist_age -- having trouble w/ missing vals
gen int date_of_birth = date(therapist_demo_date_of_birth, "YMD")
format date_of_birth %td
gen current = date("01jan2016", "DMY")
format current %td
gen therapist_age = (current - date_of_birth)/365.25
drop date_of_birth current */


save "E:\vam_analysis_sample.dta", replace 

**********************************************************************
	
