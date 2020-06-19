/*******************************************************************************
Do-file to produce summary numbers for 
			"Measuring the Impact of Therapists"
			
Coded by Mitch Z

Inputs:
	- vam_analysis_sample.dta
	
*******************************************************************************/
global main "C:\Users\mitch\OneDrive\Desktop\TVAM\HEAL_TVAM"
global data "C:\Users\mitch\OneDrive\Desktop\TVAM\data"
global analysis "C:\Users\mitch\OneDrive\Desktop\TVAM\analysis"


cd $analysis
use "om_scale_id_1_analysis", clear
foreach k of numlist 2,3,4,5,47 {
	append using "om_scale_id_`k'_analysis"
}

sort therapist_id

unique client_demo_user_id
scalar u_clients = r(unique)

unique therapist_id
scalar u_therapists = r(unique)

unique user_room_survey_id
scalar u_assessments = r(unique)

clear 

****************************************************
display "Number of patients: " u_clients 
display "Number of therapists: " u_therapists
display "Number of periodic assessments: " u_assessments
****************************************************