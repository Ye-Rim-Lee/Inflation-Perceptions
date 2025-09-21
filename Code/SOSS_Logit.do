/* 
	Title: Simple logit model evaluation of survey results
	Date: 03/17/2025
*/



**# - Import Survey Data
gl path1 "/Users/YerimLee/Documents/GitHub/Inflation-Perceptions/Data"
cd "$path1"
use "$path1/logit.dta", clear			// processed data
set more off


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


**# JEPOP
local outcomes   Q5years_1 Q5years_2 Q5years_3 Q5years_4 Q5years_5
local flagship   Q5years_5          
local age        age
local ruca       RUCA4
local income     income4
local educ       educ
local party      polaff3
local gender     gender
local home       home

* Nice labels for outcomes (for figures)
local lab_Q5years_1 "Grocery"
local lab_Q5years_2 "Gas"
local lab_Q5years_3 "Home"
local lab_Q5years_4 "Restaurant"
local lab_Q5years_5 "Overall"


**# ========= 1) Fit models 
* Try one model first to confirm it runs
ologit Q5years_5 c.age##c.age i.RUCA4 i.income4 i.educ ib3.polaff3 i.gender ib2.home, or baselevels vce(robust)
estimates store m_Q5years_5

* If the single model works, run all five:
foreach y in Q5years_1 Q5years_2 Q5years_3 Q5years_4 Q5years_5 {
    quietly ologit `y' c.age##c.age i.RUCA4 i.income4 i.educ ib3.polaff3 i.gender ib2.home, or baselevels vce(robust)
    estimates store m_`y'
}

* Verify
estimates dir

**# ========= 2) Main Table (flagship)
cap which esttab
if _rc di as error "esttab not found. Install with: ssc install estout"

esttab m_Q5years_5 using "table_main_overall.tex", replace label ///
    eform b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) compress ///
    title("Determinants of Perceived Inflation (Overall, Ordered Logit)")

**# ========= 3) FIGURE A: Homeownership across five domains
tempfile home_pp
tempname PH
postfile `PH' str20 outcome str40 home_lbl double p lci uci using `home_pp', replace

foreach y of local outcomes {
    estimates restore m_`y'
    quietly margins `home', pr(outcome(5))
    matrix M = r(table)
    levelsof `home', local(hlist)
    local j = 0
    foreach h of local hlist {
        local ++j
        local hlab : label (`home') `h'
        if `"`hlab'"' == "" local hlab "home=`h'"
        post `PH' ("`y'") ("`hlab'") (M[1,`j']) (M[5,`j']) (M[6,`j'])
    }
}
postclose `PH'
use `home_pp', clear

* Replace DV codes with nice labels for plotting
foreach y of local outcomes {
    local nice = `lab_`y''
    replace outcome = "`nice'" if outcome=="`y'"
}

encode outcome, gen(outcome_id)
encode home_lbl, gen(home_id)

twoway ///
 (rcap uci lci outcome_id if home_id==home_id[1]) ///
 (rcap uci lci outcome_id if home_id==home_id[2]) ///
 (connected p outcome_id if home_id==home_id[1], msymbol(circle)) ///
 (connected p outcome_id if home_id==home_id[2], msymbol(triangle)), ///
 legend(order(3 "`=home_lbl[1]'" 4 "`=home_lbl[2]'") pos(6) ring(0)) ///
 ytitle("Adjusted probability, outcome=5") ///
 xtitle("Price domain") xlabel(, valuelabel angle(0)) ///
 title("Homeownership and perceived inflation across domains")
graph export "fig_homeowner_across_domains.png", width(2000) replace	
	
**# ========= 4) FIGURE B: Party differences across five domains
preserve
tempfile party_pp
tempname PP
postfile `PP' str20 outcome str40 party_lbl double p lci uci using `party_pp', replace

levelsof `party', local(plist)
foreach y of local outcomes {
    estimates restore m_`y'
    quietly margins `party', pr(outcome(5))
    matrix M = r(table)
    local j = 0
    foreach lvl of local plist {
        local ++j
        local plab : label (`party') `lvl'
        if `"`plab'"'=="" local plab "party=`lvl'"
        post `PP' ("`y'") ("`plab'") (M[1,`j']) (M[5,`j']) (M[6,`j'])
    }
}
postclose `PP'
use `party_pp', clear

* Replace DV codes with nice labels for plotting
foreach y of local outcomes {
    local nice = `lab_`y''
    replace outcome = "`nice'" if outcome=="`y'"
}

encode outcome, gen(outcome_id)
encode party_lbl, gen(party_id)

graph bar (mean) p, over(party_id, label(angle(30))) over(outcome_id) ///
    blabel(bar, format(%4.2f)) ///
    ytitle("Adjusted probability, outcome=5") ///
    title("Partisanship and perceived inflation across domains") legend(off)
graph export "fig_party_across_domains.png", width(2000) replace
restore

**# ========= APPENDIX TABLE: all five outcomes side-by-side (ORs)
esttab m_Q5years_1 m_Q5years_2 m_Q5years_3 m_Q5years_4 m_Q5years_5 using "appendix_all5.tex", replace ///
    eform b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) compress label ///
    title("Determinants of Perceived Inflation across Five Domains (Ordered Logit)") ///
    mtitles("Grocery" "Gas" "Home" "Restaurant" "Overall")
	
	
**# ========= key covariates only (cleaner appendix)
esttab m_Q5years_1 m_Q5years_2 m_Q5years_3 m_Q5years_4 m_Q5years_5 using "appendix_keycovars.tex", replace ///
    eform b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) compress label ///
    title("Key Covariates across Five Domains") mtitles("Grocery" "Gas" "Home" "Restaurant" "Overall") ///
    keep( ///
        c.`age' c.`age'#c.`age' ///
        i.`ruca' ///
        i.`income' ///
        i.`educ' ///
        ib3.`party' ///
        i.`gender' ///
        ib2.`home' ///
    )

**# Temp

tab PO1 

putexcel set Q5_approval_odd, replace
ologit Q5years_5 age i.RUCA4 i.income4 i.PO1 i.gender, or baselevels 
putexcel (A1) = etable

putexcel set Q5_approval, replace
ologit Q5years_5 age i.RUCA4 i.income4 i.PO1 i.gender, baselevels 
putexcel (A1) = etable

putexcel set Q5_vote_odd, replace
ologit Q5years_5 age i.RUCA4 i.income4 i.ippsr120p i.gender, or baselevels 
putexcel (A1) = etable

putexcel set Q5_vote, replace
ologit Q5years_5 age i.RUCA4 i.income4 i.ippsr120p i.gender, baselevels 
putexcel (A1) = etable

// house owner
tab home
tab homeyear

ologit Q5years_5 age i.RUCA4 i.income4 ib3.polaff3 i.gender, or baselevels 
ologit Q5years_5 age i.RUCA4 i.income4 ib3.polaff3 i.gender i.home, or baselevels 

ologit Q5years_1 age i.RUCA4 i.income4 ib3.polaff3 i.gender ib2.home, or baselevels 
ologit Q5years_2 age i.RUCA4 i.income4 ib3.polaff3 i.gender ib2.home, or baselevels 
ologit Q5years_3 age i.RUCA4 i.income4 ib3.polaff3 i.gender ib2.home, or baselevels 
ologit Q5years_4 age i.RUCA4 i.income4 ib3.polaff3 i.gender ib2.home, or baselevels 
ologit Q5years_5 age i.RUCA4 i.income4 ib3.polaff3 i.gender ib2.home, or baselevels 


ologit Q5years_3 age i.RUCA4 i.income4 ib3.polaff3 i.gender ib2.home, or baselevels 
margins RUCA4, dydx(home) predict(outcome(4))
marginsplot

ologit Q5years_3 age i.RUCA4 i.income4 ib3.polaff3 i.gender ib2.home, or baselevels 
margins polaff3, dydx(home) predict(outcome(4))
marginsplot
	
	
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
		 