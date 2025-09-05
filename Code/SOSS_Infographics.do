* ---------------------------------------------------------------------------- *
* Infographics 
* 19/12/24 by Fernanda
* ---------------------------------------------------------------------------- *
gl path1 "/Users/YerimLee/Documents/GitHub/Inflation-Perceptions/Data"
gl path2 "/Users/YerimLee/Documents/GitHub/Inflation-Perceptions/Output"
* ---------------------------------------------------------------------------- *
**# Cleaning

	* RUCA Codes data
	import  excel "$path1/Cross Tables/RUCA2010zipcode.xlsx", sheet("Data") firstrow clear /* 41.164 */
	keep if STATE == "MI"														/* 1.158 */
	
	gen 	ruca4 =.
	replace ruca4 = 1 if RUCA1 == 1 | RUCA1 == 2 | RUCA1 == 3
	replace ruca4 = 2 if RUCA1 == 4 | RUCA1 == 5 | RUCA1 == 6
	replace ruca4 = 3 if RUCA1 == 7 | RUCA1 == 8 | RUCA1 == 9
	replace ruca4 = 4 if RUCA1 == 10
	
	label define ruca 1 "Metropolitan" 2 "Micropolitan" 3 "Small Town" 4 "Rural" 
	label values ruca4 ruca
	
	rename 	 ZIP_CODE inputzip
	destring inputzip, replace
	
	save "$path1/ruca4_zip", replace
	
	* Data - SPSS format
	import spss using "$path1/WEIGHTED SOSS 90.sav", clear						/* 1.000 */
	
	merge m:1 inputzip using "$path1/ruca4_zip", keepusing(ruca4 RUCA1) keep(match) nogen
	
	save "$path1/infrographics.dta", replace
* ---------------------------------------------------------------------------- *
* Descriptives
* ---------------------------------------------------------------------------- *
	* Where do you live?
	tab X1 ruca4
	
	label define labels81 1 "Lower" 2 "The same" 3 "A little higher" 4 "A lot higher" 5 "Not sure" 8 "skipped" 9 "not asked", replace
	


	
	
**# Bookmark #1
use "$path1/infrographics.dta", clear
	
* Overall Price Change
graph pie, over(Q5years_5) name(p1, replace)								///
		by(RUCA4)																///
		by(, title("Price Change Perception in the Last Five Years")) 			///
		by(, legend(position(6))) legend(cols(5) size(small)) 					///
		by(, note(" ", size(tiny)))

// graph export "$path2/overall price change .pdf", as(pdf) name("p1") replace	
					
	
												 
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
* ---------------------------------------------------------------------------- *
* Numbers Don't match 9 obs of differences. We will create matrices with Scott's
* distribution for now, to have the same information.
* ---------------------------------------------------------------------------- *
	clear
	mat 	 a1 = J(5,6,.)
	
	mat a1[1,1] = 11
	mat a1[2,1] = 0
	mat a1[3,1] = 0
	mat a1[4,1] = 0
	mat a1[5,1] = 11
	
	mat a1[1,2] = 24
	mat a1[2,2] = 0
	mat a1[3,2] = 2
	mat a1[4,2] = 0
	mat a1[5,2] = 26
	
	mat a1[1,3] = 204
	mat a1[2,3] = 18
	mat a1[3,3] = 8
	mat a1[4,3] = 5
	mat a1[5,3] = 235
	
	mat a1[1,4] = 576
	mat a1[2,4] = 52
	mat a1[3,4] = 32
	mat a1[4,4] = 43
	mat a1[5,4] = 703
	
	mat a1[1,5] = 21
	mat a1[2,5] = 1
	mat a1[3,5] = 2
	mat a1[4,5] = 0
	mat a1[5,5] = 24
	
	mat a1[1,6] = 836
	mat a1[2,6] = 71
	mat a1[3,6] = 44
	mat a1[4,6] = 48
	mat a1[5,6] = 999

	matlist a1
	svmat   a1, names(col)

	gen str var7 = `"Metropolitan"' in 1
	replace var7 = `"Micropolitan"' in 2
	replace var7 = `"Small Town"'   in 3
	replace var7 = `"Rural"' 		in 4
	replace var7 = `"Total"' 		in 5
	
	rename (c1-c6 var7) (Lower The_Same A_Little_Higher A_Lot_Higher Not_Sure Total ruca4)
