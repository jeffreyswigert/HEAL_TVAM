/******************************************************************
This do-file computes and analyzes combined measures of therapist value added, from each of the six
om_scale_id's we evaluated them on. 

		 "Measuring Therapist Value-Added: Evidence from an Online Therapy Platform"

Coded by: Mitchell Zufelt


INPUTS: 
	
***********************************************************************
***********************************************************************
*********************************************************************
*********************************************************************/
clear
cd $analysis

foreach i of numlist 1,2,3,4,5,47 {
	
	use "working_om_`i'.dta", clear

	bysort therapist_id : gen client_count = _N

	//by therapist_id: egen maxcount = max(count)
	//by therapist_id : keep if count==maxcount
	drop if therapist_id == therapist_id[_n-1]

	keep therapist_id therapist_effect client_count

	save "summary_om_`i'.dta", replace
	}

use "summary_om_1.dta", clear
foreach k of numlist 2,3,4,5,47 {
    append using "summary_om_`k'"
	}

bys therapist_id : egen wgt_therapist_effect = wtmean(therapist_effect), weight(client_count)
drop if therapist_id == therapist_id[_n-1]
keep therapist_id wgt_therapist_effect

cd $data
save "va_overall.dta", replace

sum wgt_therapist_effect, detail
