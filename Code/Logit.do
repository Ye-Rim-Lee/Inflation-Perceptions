/* 
	Title: Simple logit model evaluation of survey results
	Date: 03/17/2025
*/
**# - Settings
set scheme s


**# - Import Survey Data
gl path1 "C:\Users\Yerim Lee\OneDrive - Michigan State University\1. MSU AFRE PhD\4. Research\231214 Rural Inflation\MAPPR\SOSS"
cd "$path1"
//use "$path1/infrographics.dta" 	// raw data
use "$path1/logit.dta"			// processed data

**# 1. Data preprocessing

**# - (Y) Dependent Variables
tab Q5years_1 // Price change -- Restaurant food
tab Q5years_2 // Price change -- Groceries
tab Q5years_3 // Price change -- Costs for your home (rent, mortgage, taxes)
tab Q5years_4 // Price change -- Gasoline
tab Q5years_5 // Price change -- Overall prices you pay

tab Q5a		  // Inheritance

	**# - Remove "Don't know/not sure" options
	replace Q5years_1 = . if Q5years_1 == 5
	replace Q5years_2 = . if Q5years_2 == 5
	replace Q5years_3 = . if Q5years_3 == 5
	replace Q5years_4 = . if Q5years_4 == 5
	replace Q5years_5 = . if Q5years_5 == 5
	
	**# - Robustness Checks - 3 category in dependent variables
	recode Q5years_5 (1/2=1) (3=2) (4=3), gen(Q5years_5r)
	label define Q5years_5r_labels 1 "Lower or The same" ///
								   2 "A little higher"   ///
								   3 "A lot higher"
	label values Q5years_5r Q5years_5r_labels
	codebook Q5years_5r
	

	

**# - (X) Demographics

* Gender
rename CD1 gender
tab Q5years_5 gender

* Political Affiliation
rename CD7 polaff
tab Q5years_5 polaff 			// generally speaking, 4 options
tab Q5years_5 partyid, column 	// 7 point party identification
codebook polaff 				// check numeric tab

	* Collapse to 3 category
	gen polaff3 = .
	replace polaff3 = 1 if polaff == 4 | polaff == 10
	replace polaff3 = 2 if polaff == 1
	replace polaff3 = 3 if polaff == 7
	
	label define polaff3_labels 1 "Independent & Others" ///
								2 "Republican"			 ///
								3 "Democrat"
	label values polaff3 polaff3_labels
	tab polaff3

	

* RUCA
tab Q5years_5 RUCA4

* Age
gen age = 2024 - CD2 	// CD2(Birth Year)
summarize age 		 	// min 20, max 94

	* Create age groups (4)
	gen age4 = .
	replace age4 = 1 if age <= 24
	replace age4 = 2 if age >= 25 & age <= 34
	replace age4 = 3 if age >= 35 & age <= 64
	replace age4 = 4 if age >= 65
	
	label define age4_labels 1 "20-24" 2 "25-34" 3 "35-64" 4 "65-94"
	label values age4 age4_labels
	tab Q5years_5 age4
	
	* Create age groups (3)
	gen age3 = .
	replace age3 = 1 if age <= 34
	replace age3 = 2 if age >= 35 & age <= 64
	replace age3 = 3 if age >= 65
	
	label define age3_labels 1 "20-34" 2 "35-64" 3 "65-94"
	label values age3 age3_labels
	tab Q5years_5 age3

	
	* RUCA X AGE
	tab RUCA4 age4, row
	tab RUCA4 age3, row

* Household Annual Income 
rename inc income
tab income Q5years_5

	* Create income groups (4)
	recode income (1/3=1) (4/6=2) (7/10=3) (11/12=4), gen(income4)
	label define income4_labels 1 "Below $30K" ///
								2 "$30K-$59K"  ///
								3 "$60K-$99K"  ///
								4 "$100K or more"
	label values income4 income4_labels
	tab income income4
	
* Other variables
* Education
	gen educ = .

	replace educ = 1 if inlist(CD3, "Did not go to school", "Did not graduate high school")

	replace educ = 2 if inlist(CD3, "High school graduate or GED holder")

	replace educ = 3 if inlist(CD3, "1st year college", "2nd year college", "3rd year college", "Technical/junior college graduate")

	replace educ = 4 if inlist(CD3, "College graduate (four years)", "Some post graduate", "Graduate degree")


label define educ_label ///
    1 "No School or Did Not Graduate HS" ///
    2 "High School Graduate/GED" ///
    3 "Some College/Technical" ///
    4 "College Graduate or Higher"
label values educ educ_label
tab educ




**# - Save processed data
save "$path1/logit.dta", replace



**# 2. Ordered Logit
* Overall Inflation Perception
ologit Q5years_5 i.age3 i.RUCA4 i.income i.polaff i.gender, or 
// "or" - odds ratio, OR > 1 variable increases likelihood of selecting a higher category
est store model_lo1

ologit Q5years_5 age i.RUCA4 i.income4 i.polaff3 i.gender, or baselevels 
* using Democrat as baseline
ologit Q5years_5 age i.RUCA4 i.income4 ib3.polaff3 i.gender, or baselevels 
// use ib3. to change baseline
ologit Q5years_5r age i.RUCA4 i.income4 i.polaff3 i.gender 
// robustness check
stepwise, pr(0.2): ologit Q5years_5 age i.RUCA4 i.income4 i.polaff3 i.gender, or baselevels

* Other political
tab ippsr120p Q5years_5
tab PO1 Q5years_5
tab polaff3 PO1
ologit Q5years_5 age i.RUCA4 i.income4 i.gender i.polaff3 i.PO1, or baselevels 

stepwise, pr(0.2): ologit Q5years_5 age i.RUCA4 i.income4 i.polaff3 i.gender i.CC1 ib5.CC6 i.CD15 i.CD5 i.UN1 i.educ, or baselevels
estat esize
ologit Q5years_5 age i.RUCA4 i.income4 i.polaff3 i.gender i.CC1 ib5.CC6 i.educ, or baselevels
ologit Q5years_5r age i.RUCA4 i.income4 i.polaff3 i.gender i.CC1 ib5.CC6 i.educ, or baselevels

fvset, show

	* Predicted Probability to choose "A lot higher(4)"
	margins, predict(outcome(4))
	margins age3, predict(outcome(4))
	margins polaff3, predict(outcome(4))
	marginsplot, title("Predicted Probability by Age Group")

	margins age4 RUCA4, predict(outcome(4))


* Interaction: RUCA X AGE
ologit Q5years_5 i.age3##i.RUCA4 i.polaff3 i.gender, or baselevels
margins, predict(outcome(4))
	margins age3#RUCA4, predict(outcome(4))
	marginsplot, xdimension(age3) by(RUCA4) ///
		//title("Predicted Probability by Age & RUCA") ///
		//xlabel(1 "20-24" 2 "25-34" 3 "35-64" 4 "65-94") ///
		legend(pos(6))



**# 3. Ordered Probit
oprobit Q5years_5 i.age4 i.RUCA4 i.income i.polaff i.gender
est store model_pr1
	margins age4, predict(outcome(4))

**# 2024 MAPPR report
ologit Q5years_1 age i.RUCA4 i.income4 i.polaff3 i.gender, or baselevels
est store model_o1
ologit Q5years_2 age i.RUCA4 i.income4 i.polaff3 i.gender, or baselevels 
est store model_o2
ologit Q5years_3 age i.RUCA4 i.income4 i.polaff3 i.gender, or baselevels 
est store model_o3
ologit Q5years_4 age i.RUCA4 i.income4 i.polaff3 i.gender, or baselevels 
est store model_o4

putexcel set Overall_Prices_odds
ologit Q5years_5 age i.RUCA4 i.income4 i.polaff3 i.gender, or baselevels 
putexcel (A1) = etable

putexcel set Overall_Prices, replace
ologit Q5years_5 age i.RUCA4 i.income4 i.polaff3 i.gender, baselevels 
putexcel (A1) = etable

	
	
**# 999. Format Results
esttab model_lo1 model_pr1 using results.html, ///
      stats(N ll chi2 p) ///
      b(%9.3f) se(%9.3f) ///
      star(* 0.10 ** 0.05 *** 0.01) ///
      label replace

outreg2 using results.doc, replace word ///
         addstat(Pseudo R2, e(r2_p)) ///
         label
		 
		 
		 - beta correlation
		 - which one is the strongest ANOVA check
		 - special issue Jon Eguia or
		 - public perceptions journal, elections public opinion (2.59) journal
		 - applied economics perspective and policy (ag econ journal) 
		 - Impact Factors compare , abstract, keywords
		 