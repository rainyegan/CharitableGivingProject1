*******************************************************
* Project: [Project Name]
* File: master.do
* Purpose: Full pipeline: DataClean → 1 Paradox of Choice 9_AY, v2 → 2 4_Analysis_v2 → 3 4_Analysis_OnlyGraphs_v2 → 4 Default 1_AY, v2

* Author: Cahal Moran and Atiyeh Yeganloo
* Date: 2026-01-14
* Stata: version 17
* Inputs: data\raw\*.csv
* Outputs: (1) tabs\*.tex, (2) figs\*.png, (3) data\ (4)logs

/*
** use MainMainData2.dta
** MainMainData2: 159 vars and 8642 obs
** I cannot find how MainMainData2 is genereated.

** MainMainData3 == MainMainData2 mereg MainMainData (in 2_merge)
** Definition of Donors is wrong in MainMainData3 except for Donors == 0
** the variable donors is only correct for NoCategort group
** MainMainData4: Saves the new info about the donors 
** Atiyeh.dta: a data file after running cahal's do file _6
*/


/* Libraries
**ssc install violinplot, replace
**ssc install dstat, replace
**ssc install moremata, replace
**ssc install palettes, replace
**ssc install colrspace, replace
**ssc install catplot
*/

** Analysis: mainly on signalling effect, 
** and creating descriptive summary statsistics.

*******************************************************

version 18
clear all


global drive = "C:\Users\AtiyehYeganloo\OneDrive - Judge Business School\_U of Cambridge\_Research Projects\0_Donation, choice overload\Data Analysis\Shared DataAnalysis"


cd "$drive\logs"

set more off
capture log close _all
log using "master_log_1 Paradox of Choice 9_AY_v4`c(current_date)'.smcl", replace

cd "$drive\data"


u "mergefile.dta"
sort code round_number

*******************************************************
ren task1playerdonation_total taskplayerdonation_total1
ren task2playerdonation_total taskplayerdonation_total2
reshape long taskplayerdonation_total, i(id) j(round)

ren taskplayerdonation_total donation

order round RoundNumberCostum round_number
sort code round RoundNumberCostum round_number
br

* drop round_number


ta donation
*******************************************************
**# TODO:
* [Done] separate round 1 from round 2
* [Done] adding leavers as the robustness checks
* [Done]  Adding round and treatment interactions
* importance treatment and donation analysis for round 1

*******************************************************
** Covariates
*******************************************************


ren etnithityO ethnicityO

foreach var in education ethnicity marital employment religion income age male {
	
encode `var'O, gen(`var')

	
}

gen white = ethnicity==14
label variable white "White"
gen employed = (employment==7 | employment==8)
label variable employment "Employed"
gen atheist = religion==6
label variable atheist "Atheist"
gen maledum = male==2
replace maledum = . if male==3 | male==4
label variable maledum "Male"

recode age (1=21.5) (2=29.5) (3=37.5) (4=45.5) (5=53.5) (6=61.5) (7=69.5) (8=77.5) (9=85.5) (10=90), gen(agecon)

*******************************************************
** Welbeing
*******************************************************

*Satisfaction variables

*Satsified with choice? (higher = more satisfied)
*I was very satisfied with the experience of deciding which charity to choose

foreach var in satisfactionD1 satisfactionL1  {

    * Create a new numeric variable to temporarily hold the recoded values
    gen `var'_temp_num = .
    
    * Recode the values
    replace `var'_temp_num = 5 if `var' == "Extremely dissatisfied"
    replace `var'_temp_num = 4 if `var' == "Somewhat dissatisfied"
    replace `var'_temp_num = 3 if `var' == "Neither satisfied nor dissatisfied"
    replace `var'_temp_num = 2 if `var' == "Somewhat satisfied"
    replace `var'_temp_num = 1 if `var' == "Extremely satisfied"
    
    * Label the new numeric variable
    label define `var'_temp_num_lbl 1 "Extremely dissatisfied" ///
                                     2 "Somewhat dissatisfied" ///
                                     3 "Neither satisfied nor dissatisfied" ///
                                     4 "Somewhat satisfied" ///
                                     5 "Extremely satisfied"
									 
    label values `var'_temp_num `var'_temp_num_lbl
	
	rename `var'_temp_num `var'_temp
}


*I found the process of deciding which charity to choose frustrating. (Reverse Coded)

foreach var in satisfactionD2 satisfactionL2  {
	
    gen `var'_temp_num = .
    replace `var'_temp_num = 1 if `var' == "Strongly agree"
	replace `var'_temp_num = 2 if `var' == "Somewhat agree"
	replace `var'_temp_num = 3 if `var' == "Neither agree nor disagree"
    replace `var'_temp_num = 4 if `var' == "Somewhat disagree"   
    replace `var'_temp_num = 5 if `var' == "Strongly disagree"
    
    label define `var'_temp_num_lbl 1 "Strongly agree" ///
                                     2 "Somewhat agree" ///
                                     3 "Neither agree nor disagree" ///
                                     4 "Somewhat disagree" ///
                                     5 "Strongly disagree"
									 
    label values `var'_temp_num `var'_temp_num_lbl
    
    rename `var'_temp_num `var'_temp
}


*Several good charities were available for me to choose between
*I thought the choice selection of charities was good
*I would be happy to choose from the same set of charities the next time I choose to donate money
*I found the process of deciding which charity to choose interesting

foreach var in satisfactionD3 satisfactionD4 satisfactionD5 satisfactionD6 satisfactionL3 satisfactionL4 satisfactionL5 satisfactionL6 {

    gen `var'_temp_num = .
     replace `var'_temp_num = 1 if `var' == "Strongly disagree"
	 replace `var'_temp_num = 2 if `var' == "Somewhat disagree"
	 replace `var'_temp_num = 3 if `var' == "Neither agree nor disagree"
    replace `var'_temp_num = 4 if `var' == "Somewhat agree"    
    replace `var'_temp_num = 5 if `var' == "Strongly agree"
   
    
    label define `var'_temp_num_lbl 5 "Strongly agree" ///
                                     4 "Somewhat agree" ///
                                     3 "Neither agree nor disagree" ///
                                     2 "Somewhat disagree" ///
                                     1 "Strongly disagree"
									 
    label values `var'_temp_num `var'_temp_num_lbl
    
    rename `var'_temp_num `var'_temp
}


*-------------------------------------------------------------------------------
* Fix (May 2026): satisfactionD1_temp and satisfactionL1_temp are reverse-coded
* relative to the other five items (D2-D6 / L2-L6) because the temp_num mapping
* assigns 5 to "Extremely dissatisfied" and 1 to "Extremely satisfied" (see lines
* 117-124), whereas D2/L2 (frustrating, reverse) and D3-D6/L3-L6 (positive) all
* end up with 5 = more satisfied. Stata's `alpha , std item` auto-flips reversed
* items when standardising, so the reported Cronbach alpha is correct, but the
* manually constructed mean scale did not get that flip. We therefore reverse
* satisfactionD1_temp and satisfactionL1_temp here before averaging.
*-------------------------------------------------------------------------------

gen satisL = ((6 - satisfactionL1_temp) + satisfactionL2_temp + satisfactionL3_temp + satisfactionL4_temp + satisfactionL5_temp + satisfactionL6_temp)/6

gen satisD = ((6 - satisfactionD1_temp) + satisfactionD2_temp + satisfactionD3_temp + satisfactionD4_temp + satisfactionD5_temp + satisfactionD6_temp)/6


*Regret (higher = less regret)

*Do you regret your choices?
*Do you think that a different charity from that assortment would have been better than the ones you chose?
*regretL1 has no answers under 'definitely yes'
foreach var in regretD1 regretD2 regretL1 regretL2 {

    gen `var'_temp_num = .
    replace `var'_temp_num = 1 if `var' == "Definitely yes"
	replace `var'_temp_num = 2 if `var' == "Probably yes"
	replace `var'_temp_num = 3 if `var' == "Might or might not"
    replace `var'_temp_num = 4 if `var' == "Probably not"    
    replace `var'_temp_num = 5 if `var' == "Definitely not"
    
    
    label define `var'_temp_num_lbl 2 "Probably yes" ///
                                     4 "Probably not" ///
                                     3 "Might or might not" ///
                                     5 "Definitely not" ///
                                     1 "Definitely yes"
									 
    label values `var'_temp_num `var'_temp_num_lbl
    
    rename `var'_temp_num `var'_temp
}


*If you could repeat the choice, would you choose the same charitable organisation(s) again? (Reverse Coded)

foreach var in regretD3 regretL3 {

    gen `var'_temp_num = .   
	replace `var'_temp_num = 1 if `var' == "Definitely not"
    replace `var'_temp_num = 2 if `var' == "Probably not"
	replace `var'_temp_num = 3 if `var' == "Might or might not"
    replace `var'_temp_num = 4 if `var' == "Probably yes"  
    replace `var'_temp_num = 5 if `var' == "Definitely yes"
    
    label define `var'_temp_num_lbl 1 "Definitely not" ///
                                     2 "Probably not" ///
                                     3 "Might or might not" ///
                                     4 "Probably yes" ///
                                     5 "Definitely yes"
									 
    label values `var'_temp_num `var'_temp_num_lbl
    
    rename `var'_temp_num `var'_temp
}


gen regrD = (regretD1_temp + regretD2_temp + regretD3_temp)/3

gen regrL = (regretL1_temp + regretL2_temp + regretL3_temp)/3

*Difficulty: higher = more difficult
*How would you rate the level of difficulty you experienced when making the choices?

foreach var in difficulty1 {

   gen `var'_temp_num = .
    replace `var'_temp_num = 1 if `var' == "Extremely easy"
	replace `var'_temp_num = 2 if `var' == "Somewhat easy"
	replace `var'_temp_num = 3 if `var' == "Neither easy nor difficult"    
    replace `var'_temp_num = 4 if `var' == "Somewhat difficult"
    replace `var'_temp_num = 5 if `var' == "Extremely difficult"
    
    label define `var'_temp_num_lbl 1 "Extremely easy" ///
                                    2 "Somewhat easy" ///
                                    3 "Neither easy nor difficult" ///
                                    4 "Somewhat difficult" ///
                                    5 "Extremely difficult"
									 
    label values `var'_temp_num `var'_temp_num_lbl
    
    rename `var'_temp_num `var'_temp

}

*How would you rate the amount of effort it took for you to make your choices?
foreach var in difficulty2 {

   gen `var'_temp_num = .
    replace `var'_temp_num = 1 if `var' == "Extremely effortless"
	replace `var'_temp_num = 2 if `var' == "Somewhat effortless"
	replace `var'_temp_num = 3 if `var' == "Neither effortless nor effortful"    
    replace `var'_temp_num = 4 if `var' == "Somewhat effortful"
    replace `var'_temp_num = 5 if `var' == "Extremely effortful"
    
    label define `var'_temp_num_lbl 1 "Extremely effortless" ///
                                    2 "Somewhat effortless" ///
                                    3 "Neither effortless nor effortful" ///
                                    4 "Somewhat effortful" ///
                                    5 "Extremely effortful"
									 
    label values `var'_temp_num `var'_temp_num_lbl
    
    rename `var'_temp_num `var'_temp

}

*How would you rate the amount of time it took you to make your choices?
foreach var in difficulty3 {

   gen `var'_temp_num = .
    replace `var'_temp_num = 1 if `var' == "No time at all"
	replace `var'_temp_num = 2 if `var' == "A little time"
	replace `var'_temp_num = 3 if `var' == "A moderate amount of time"    
    replace `var'_temp_num = 4 if `var' == "A lot of time"
    replace `var'_temp_num = 5 if `var' == "A great deal of time"
    
    label define `var'_temp_num_lbl 1 "No time at all" ///
                                    2 "A little time" ///
                                    3 "A moderate amount of time" ///
                                    4 "A lot of time" ///
                                    5 "A great deal of time"
									 
    label values `var'_temp_num `var'_temp_num_lbl
    
    rename `var'_temp_num `var'_temp

}

*How would you rate the amount of thought you had to put into making your choices?
foreach var in difficulty4 {

   gen `var'_temp_num = .
    replace `var'_temp_num = 1 if `var' == "No thought at all"
	replace `var'_temp_num = 2 if `var' == "A little "
	replace `var'_temp_num = 3 if `var' == "A moderate amount"    
    replace `var'_temp_num = 4 if `var' == "A lot"
    replace `var'_temp_num = 5 if `var' == "A great deal"
    
    label define `var'_temp_num_lbl 1 "No thought at all" ///
                                    2 "A little" ///
                                    3 "A moderate amount" ///
                                    4 "A lot" ///
                                    5 "A great deal"
									 
    label values `var'_temp_num `var'_temp_num_lbl
    
    rename `var'_temp_num `var'_temp

}


gen diffic = (difficulty1_temp + difficulty2_temp + difficulty3_temp + difficulty4_temp)/4

*Familiarity: higher = more familiar
*How familiar do you consider yourself to be with the listed charities?

foreach var in familiarityD1 familiarityL1 {

   gen `var'_temp_num = .
    replace `var'_temp_num = 1 if `var' == "Not familiar at all (none)"
	replace `var'_temp_num = 2 if `var' == "Slightly familiar (about a quarter)"
	replace `var'_temp_num = 3 if `var' == "Moderately familiar (about half)"    
    replace `var'_temp_num = 4 if `var' == "Very familiar (about three quarters)"
    replace `var'_temp_num = 5 if `var' == "Extremely familiar (all)"
    
    label define `var'_temp_num_lbl 1 "Not familiar at all (none)" ///
                                    2 "Slightly familiar (about a quarter)" ///
                                    3 "Moderately familiar (about half)" ///
                                    4 "Very familiar (about three quarters)" ///
                                    5 "Extremely familiar (all)"
									 
    label values `var'_temp_num `var'_temp_num_lbl
    
    rename `var'_temp_num `var'_temp

}

*Deliberation: higher = more deliberation/slower decision
*How much did you deliberate about your choices?

foreach var in deliberationD1 deliberationL1 {

   gen `var'_temp_num = .
    replace `var'_temp_num = 5 if `var' == "A great deal"
	replace `var'_temp_num = 4 if `var' == "A lot"
	replace `var'_temp_num = 3 if `var' == "A moderate amount"    
    replace `var'_temp_num = 2 if `var' == "A little"
    replace `var'_temp_num = 1 if `var' == "Not at all"
    
    label define `var'_temp_num_lbl 5 "A great deal" ///
                                    4 "A lot" ///
                                    3 "A moderate amount" ///
                                    2 "A little" ///
                                    1 "Not at all"
									 
    label values `var'_temp_num `var'_temp_num_lbl
    
    rename `var'_temp_num `var'_temp

}


*Altruism: higher = more altruistic 
*In the past, I have helped carry a strangers belongings (e.g., books, parcels, etc.).,
*In the past, I have allowed someone to go ahead of me in a line (e.g., supermarket, copying machine, etc.).,
*"In the past, I have let a neighbour whom I didnt know too well borrow an item of some value (e.g., tools, a dish, etc.).,"
*I have, before being asked, voluntarily looked after a neighbours pets or children without being paid for it.
*"In the past, I have offered to help people with disabilities or elderly strangers.", across a street

foreach var in SRA1 SRA2 SRA3 SRA4 SRA5 {

   gen `var'_temp_num = .
    replace `var'_temp_num = 1 if `var' == "Never"
	replace `var'_temp_num = 2 if `var' == "Once"
	replace `var'_temp_num = 3 if `var' == "More than Once"    
    replace `var'_temp_num = 4 if `var' == "Often"
    replace `var'_temp_num = 5 if `var' == "Very Often"
    
    label define `var'_temp_num_lbl 1 "Never" ///
                                    2 "Once" ///
                                    3 "More than Once" ///
                                    4 "Often" ///
                                    5 "Very Often"
									 
    label values `var'_temp_num `var'_temp_num_lbl
    
    rename `var'_temp_num `var'_temp

}


gen SRA = (SRA1_temp + SRA2_temp + SRA3_temp + SRA4_temp + SRA5_temp)/5

*Avoidant decisions: higher = more avoidant
*I avoid making important decisions until the pressure is on.
*I postpone decision making whenever possible.
*I often procrastinate when it comes to making important decisions.
*I generally make important decisions at the last minute.
*I put off making many decisions because thinking about them makes me uneasy.

foreach var in avoid1 avoid2 avoid3 avoid4 avoid5 {

  gen `var'_temp_num = .
    replace `var'_temp_num = 1 if `var' == "Strongly disagree"
	replace `var'_temp_num = 2 if `var' == "Somewhat disagree"
	replace `var'_temp_num = 3 if `var' == "Neither agree nor disagree"
    replace `var'_temp_num = 4 if `var' == "Somewhat agree"    
    replace `var'_temp_num = 5 if `var' == "Strongly agree"
   
    
    label define `var'_temp_num_lbl 5 "Strongly agree" ///
                                     4 "Somewhat agree" ///
                                     3 "Neither agree nor disagree" ///
                                     2 "Somewhat disagree" ///
                                     1 "Strongly disagree"
									 
    label values `var'_temp_num `var'_temp_num_lbl
    
    rename `var'_temp_num `var'_temp
}

gen avoid = (avoid1_temp +  avoid2_temp +  avoid3_temp +  avoid4_temp +  avoid5_temp)/5

*Maximiser/satisficer: higher = maximiser
*When I am in the car listening to the radio (or podcast or similar), I often check other stations to see if something better is playing, even if I am relatively satisfied with what Im listening to.
*"No matter how satisfied I am with my job (work or daily chores), its only right for me to be on the lookout for better opportunities.,"
*I often find it difficult to shop for a gift for a friend.,
*"Finding a new series or movie (on Netflix or similar platforms) is really difficult. 
*Im always struggling to pick the best one.,"
*No matter what I do, I have the highest standards for myself.
*I never settle for second best.

foreach var in max1 max2 max3 max4 max5 max6 {

 gen `var'_temp_num = .
    replace `var'_temp_num = 1 if `var' == "Strongly disagree"
	replace `var'_temp_num = 2 if `var' == "Somewhat disagree"
	replace `var'_temp_num = 3 if `var' == "Neither agree nor disagree"
    replace `var'_temp_num = 4 if `var' == "Somewhat agree"    
    replace `var'_temp_num = 5 if `var' == "Strongly agree"
   
    
    label define `var'_temp_num_lbl  5 "Strongly agree" ///
                                     4 "Somewhat agree" ///
                                     3 "Neither agree nor disagree" ///
                                     2 "Somewhat disagree" ///
                                     1 "Strongly disagree"
									 
    label values `var'_temp_num `var'_temp_num_lbl
    
    rename `var'_temp_num `var'_temp
}


gen max = (max1_temp +  max2_temp +  max3_temp +  max4_temp +  max5_temp + max6_temp)/6


foreach var in satisfaction {
forvalues i = 1/6 {
	
	gen `var'`i'= .
	
	replace `var'`i' = `var'D`i'_temp if `var'L`i'_temp==.
	
	replace `var'`i' = `var'L`i'_temp if `var'D`i'_temp==.
	
	replace `var'`i' = . if round==1
	
}

}

foreach var in regret {
forvalues i = 1/3 {
	
	gen `var'`i'= .
	
	replace `var'`i' = `var'D`i'_temp if `var'L`i'_temp==.
	
	replace `var'`i' = `var'L`i'_temp if `var'D`i'_temp==.
	
	replace `var'`i' = . if round==1
	
}

}


ta  Treatments Donors, m



**# Bookmark #1
*** Cronbach's alpha: see 4_Analysis v2


**# Bookmark #2
*** Perceived importance wing: : see 4_Analysis v2
gen schoice = 0
replace schoice = 1 if Treatments<=16 & Treatments>=12

*******************************************************
*H1 & H2 for Singnals 
*******************************************************
gen temp_no_signal = .
replace temp_no_signal = 0 if Treatments <13 & nvals == 1 
replace temp_no_signal = 1 if Treatments > 12 & nvals == 1 

label values temp dttemp
label def dttemp 0 "NoSignal", modify

gen temp_4h = .
replace temp_4h = 0 if Treatments !=13 & nvals == 1 
replace temp_4h = 1 if Treatments ==13 & nvals == 1 

gen temp_4l = .
replace temp_4l = 0 if Treatments !=14 & nvals == 1 
replace temp_4l = 1 if Treatments ==14 & nvals == 1 

gen temp_1L3H = .
replace temp_1L3H = 0 if Treatments !=15 & nvals == 1 
replace temp_1L3H = 1 if Treatments ==15 & nvals == 1 

gen temp_1H3L = .
replace temp_1H3L = 0 if Treatments !=16 & nvals == 1 
replace temp_1H3L = 1 if Treatments ==16 & nvals == 1 

bys Category: su(donation) if Treatments > 13

table Treatments Category, statistic(mean donation) ///
    nototal nformat(%9.2f), if Treatments > 12

gen temp_donation_cat1 = donation if Category == 1
gen temp_donation_cat2 = donation if Category == 2
gen temp_donation_cat3 = donation if Category == 3
gen temp_donation_cat4 = donation if Category == 4

eststo clear

eststo: reg donation temp_4h temp_4l temp_1L3H temp_1H3L, cluster(id), if TreatmentChoice < 2 & round == 1
estadd local hascon = "No"

eststo: reg donation temp_4h temp_4l temp_1L3H temp_1H3L i.Category, cluster(id), if TreatmentChoice < 2 & round == 1
estadd local hascon = "No"
estadd scalar cat2 = _b[2.Category]
estadd scalar cat3 = _b[3.Category]
estadd scalar cat4 = _b[4.Category]

eststo: reg donation temp_4h temp_4l temp_1L3H temp_1H3L i.Category ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentChoice < 2 & round == 1
estadd local hascon = "Yes"

eststo: reg temp_donation_cat1 temp_4h temp_4l temp_1L3H temp_1H3L, cluster(id), if TreatmentChoice < 2 & round == 1
estadd local hascon = "No"

esttab using "$drive\tabs\DonationCategory.tex", se star(* 0.10 ** 0.05 *** 0.01) keep(temp_4h temp_4l temp_1L3H temp_1H3L 2.Category 3.Category 4.Category) ///
    scalars("hasfe Fixed Effect" "hascon Controls") nomtitles mgroups("Donation" "Donation to Animals", pattern(1 0 0 0 1)) ///
    nonotes addnote("ADD.") ///
    alignment(c) label replace ///
    b(3) se(3) ///
    title(Effect of Treatments on Donations in Round 1 \label{DonationCategory})
	




reg temp_donation_cat2 temp_4h temp_4l temp_1L3H temp_1H3L, cluster(id), if TreatmentChoice < 2 & round == 1
estadd local hasfe = "No"
estadd local hascon = "No"


reg temp_donation_cat3 temp_4h temp_4l temp_1L3H temp_1H3L, cluster(id), if TreatmentChoice < 2 & round == 1
estadd local hasfe = "No"
estadd local hascon = "No"

reg temp_donation_cat4 temp_4h temp_4l temp_1L3H temp_1H3L, cluster(id), if TreatmentChoice < 2 & round == 1
estadd local hasfe = "No"
estadd local hascon = "No"


*Include people who do not donate in one of the rounds, but not those who opt out at the start ('selfish' people)
recode donation (.=0) if Donors!=0

*Options treatment - defined for whole sample
gen hchoice = .
replace hchoice = 1 if Treatments<=3 & round==2
replace hchoice = 1 if Treatments<=6 & Treatments>3 & round==1
replace hchoice = 1 if Treatments<=12 & Treatments>9 
replace hchoice = 0 if Treatments<=3 & round==1
replace hchoice = 0 if Treatments<=6 & Treatments>3 & round==2
replace hchoice = 0 if Treatments<=9 & Treatments>6 
replace hchoice = 1 if Treatments==13
replace hchoice = 0 if Treatments==14
replace hchoice = 0 if Category==1 & Treatments==15
replace hchoice = 1 if Category>1 & Category!=. & Treatments==15
replace hchoice = 0 if Category>1 & Category!=. & Treatments==16
replace hchoice = 0 if Category==1 & Treatments==16


*ESTIMATIONS FOR 1 VERSUS MANY CHOICES (Missing for default and importance arms)
gen mchoice = .
replace mchoice = 0 if Treatments==1 | Treatments == 4 | Treatments == 7 | Treatments == 10 
replace mchoice = 1 if Treatments==3 | Treatments == 6 |  Treatments == 9 | Treatments == 12 

*ESTIMATIONS FOR DEFAULT VERSUS NON DEFAULT (Missing for mchoice and importance arms)
gen dchoice = .
replace dchoice = 0 if Treatments==1 | Treatments == 4 | Treatments == 7 | Treatments == 10 
replace dchoice = 1 if Treatments==2 | Treatments == 5 |  Treatments == 8 | Treatments == 11 

label variable hchoice "Options"
label variable mchoice "Choices"
label variable dchoice "Default"
label variable schoice "Select"
label variable round "Round" 


*Four main hypotheses 

gen hmchoice = hchoice*mchoice
label variable hmchoice "Options * Choices "

gen hdchoice = hchoice*dchoice
label variable hdchoice "Options * Default"

gen hschoice = hchoice*schoice
label variable hschoice "Options * Select"

gen temp_round = round - 1
label variable temp_round "Round"

gen hrchoice = hchoice*temp_round
label variable hrchoice "Options * Round "

gen mrchoice = mchoice*temp_round
label variable mrchoice "Choice * Round"

gen hmrchoice = hchoice*mchoice*temp_round
label variable hmrchoice "Options * Choice * Round"


label define hchoicel 0 "Low" 1 "High"

label values hchoice hchoicel

label define mchoicel 0 "One" 1 "Many"

label values mchoice mchoicel

label define dchoicel 0 "No Default" 1 "Default"

label values dchoice dchoicel

label define schoicel 0 "Not Selected" 1 "Selected"

label values schoice schoicel


*******************************************************
cd "$drive\tabs\"
*******************************************************

**# Bookmark #4: Analysis

*******************************************************
*H1 & H2
*******************************************************
eststo clear

eststo: reg donation hchoice temp_round, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 
estadd local hasfe = "No"
estadd local hascon = "No"

eststo: reg donation hchoice temp_round ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "No"
estadd local hascon = "Yes"

eststo: xtreg donation hchoice temp_round, i(id) cluster(id) fe, if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "Yes"
estadd local hascon = "No"

eststo: reg donation hchoice mchoice temp_round , cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "No"
estadd local hascon = "No"

eststo: reg donation hchoice mchoice temp_round  ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "No"
estadd local hascon = "Yes"

esttab using "$drive\tabs\Table1.tex",  star(* 0.10 ** 0.05 *** 0.01) se keep(hchoice mchoice temp_round   ) scalars("hasfe Fixed Effect" "hascon Controls") nomtitles mgroups("Hypothesis 1" "Hypothesis 2", pattern(1 0 0 1 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("Add" ) ///
 alignment(c) label replace ///
      title (Effect of Treatments on Donations \label{Table1})	

*******************************************************
*Interactions between treatments
*******************************************************
eststo clear

eststo: reg donation hchoice mchoice temp_round, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 
estadd local hasfe = "No"
estadd local hascon = "No"
	  
eststo: reg donation hchoice  mchoice hmchoice temp_round hrchoice mrchoice hmrchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2    
estadd local hasfe = "No"
estadd local hascon = "No"

eststo: reg donation hchoice  mchoice hmchoice temp_round hrchoice mrchoice hmrchoice ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2    
estadd local hasfe = "No"
estadd local hascon = "Yes"

eststo: xtreg donation hchoice  mchoice hmchoice temp_round hrchoice mrchoice hmrchoice, i(id) cluster(id) fe, if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "Yes"
estadd local hascon = "No"

esttab using "$drive\tabs\Table1a.tex",  star(* 0.10 ** 0.05 *** 0.01) se keep(hchoice  mchoice hmchoice temp_round hrchoice mrchoice hmrchoice) scalars("hasfe Fixed Effect" "hascon Controls") nomtitles mgroups("Donations (Tokens)", pattern(1 0)   ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("ADD" ) ///
 alignment(c) label replace ///
      title (Effect of Treatments on Donations (Interactions) \label{Table1a})	


** round 1
eststo clear

eststo: reg donation hchoice mchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 & temp_round == 0
estadd local hascon = "No"
	  
eststo: reg donation hchoice  mchoice hmchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  & temp_round == 0  
estadd local hascon = "No"

eststo: reg donation hchoice  mchoice hmchoice ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2    & temp_round == 0
estadd local hascon = "Yes"

esttab using "$drive\tabs\Table1aRound1.tex",  star(* 0.10 ** 0.05 *** 0.01) se keep(hchoice  mchoice hmchoice    ) scalars("hascon Controls") nomtitles mgroups("Donations (Tokens)", pattern(1 0)   ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("ADD" ) ///
 alignment(c) label replace ///
      title (Effect of Treatments on Donations (Interactions) \label{Table1aRound1})	

	  
*******************************************************
*Interactions between rounds
*******************************************************


xtset id round


gen donation_lag = L.donation
gen hchoice_lag = L.hchoice

order id Treatments round donation hchoice donation_lag   hchoice_lag


eststo clear

eststo m1: reg donation hchoice ///
    if TreatmentSignal==0 & TreatmentChoice!=2 & TreatmentChoice!=3, ///
    vce(cluster id)

estadd local hascon "No"


eststo m2: reg donation donation_lag hchoice hchoice_lag ///
    if TreatmentSignal==0 & TreatmentChoice!=2 & TreatmentChoice!=3 & round==2, ///
    vce(cluster id)
estadd local hascon "No"

* Linear combinations (use lincom to grab estimate, SE, p-val)
* HH = _cons + hchoice + hchoice_lag
* HL = _cons + hchoice_lag
* LH = _cons + hchoice
* LL = _cons

test (_cons + hchoice + hchoice_lag) = (_cons ) //HH
test (_cons + hchoice_lag) = (_cons ) // HL
test (_cons + hchoice) = (_cons ) // LH


eststo m3: reg donation donation_lag hchoice hchoice_lag ///
    ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ///
    ib2.income age ib2.male ///
    if TreatmentSignal==0 & TreatmentChoice!=2 & TreatmentChoice!=3 & round==2, ///
    vce(cluster id)

estadd local hascon "Yes"


test (_cons + hchoice + hchoice_lag) = (_cons ) //HH
test (_cons + hchoice_lag) = (_cons ) // HL
test (_cons + hchoice) = (_cons ) // LH

*---------------------------------------
* Export table
*---------------------------------------
* Show coefficients of interest in rows; show HH/HL/LH/LL in the scalars block.
* You can label the scalars however you like. Below I also add the p-values.
esttab m1 m2 m3 using "$drive/tabs/Table1bnew.tex", ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(donation_lag hchoice hchoice_lag) ///
    scalars( ///
        "hascon Controls" ///
    ) ///
    nomtitles ///
    mgroups("Donations (Tokens)", pattern(1 0), ///
       ) ///
    nonotes addnote("Add") alignment(c) label replace ///
    title("Effect of Options Treatment on Donations, with Lags \label{Table1bnew}")


*******************************************************
* Interactions between rounds (old)
*******************************************************

gen lhchoice = L.hchoice
label variable lhchoice "Options (Lagged)"

gen hlhchoice = hchoice*lhchoice
label variable hlhchoice "Options * Options (Lagged)"

ta Treatments hchoice  if TreatmentSignal==0 & TreatmentChoice!=2 & TreatmentChoice!=3 

ta Treatments lhchoice  if TreatmentSignal==0 & TreatmentChoice!=2 & TreatmentChoice!=3 

ta Treatments hlhchoice  if TreatmentSignal==0 & TreatmentChoice!=2 & TreatmentChoice!=3   

eststo clear

eststo: reg donation hchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 & TreatmentChoice!=3  
estadd local hascon = "No"

** eststo: reg donation hchoice lhchoice hlhchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 & TreatmentChoice!=3    
** estadd local hascon = "No"
** test hchoice + lhchoice + hlhchoice = 0

eststo: reg donation lhchoice hlhchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 & TreatmentChoice!=3 
estadd local hascon = "No"
test lhchoice + hlhchoice = 0

eststo: reg donation lhchoice hlhchoice ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 & TreatmentChoice!=3    
estadd local hascon = "Yes"
test lhchoice + hlhchoice = 0

esttab using "$drive\tabs\Table1b.tex",  star(* 0.10 ** 0.05 *** 0.01) se keep(hchoice lhchoice hlhchoice) scalars("hascon Controls") nomtitles mgroups("Donations (Tokens)", pattern(1 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the total number of tokens donated on two treatment variables, Options and Choices. Columns (2) and (5) add covariate,s while column (3) adds fixed effects. Each regression controls for round effects. Standard errors are clustered at the participant level.") ///
 alignment(c) label replace ///
      title (Effect of Options Treatment on Donations, with Lags \label{Table1b})


** adding Mchoice
eststo clear

eststo: reg donation hchoice mchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2
estadd local hascon = "No"

eststo: reg donation hchoice lhchoice hlhchoice mchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 
estadd local hascon = "No"
test hchoice + lhchoice + hlhchoice = 0

eststo: reg donation hchoice lhchoice hlhchoice mchoice ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 
estadd local hascon = "Yes"
test hchoice + lhchoice + hlhchoice = 0

esttab using "$drive\tabs\Table1bwithmchoice.tex", se keep(hchoice lhchoice hlhchoice mchoice) scalars("hascon Controls") nomtitles mgroups("Donations (Tokens)", pattern(1 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the total number of tokens donated on two treatment variables, Options and Choices. Columns (2) and (5) add covariate,s while column (3) adds fixed effects. Each regression controls for round effects. Standard errors are clustered at the participant level.") ///
 alignment(c) label replace ///
      title (Effect of Options Treatment on Donations, with Lags \label{Table1bwithmchoice})

	  
*******************************************************
*H1 & H2 in round 1 only
*******************************************************

eststo clear

eststo: reg donation hchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 & round == 1
estadd local hasfe = "No"
estadd local hascon = "No"

eststo: reg donation hchoice ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  & round == 1
estadd local hasfe = "No"
estadd local hascon = "Yes"

eststo: reg donation hchoice mchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  & round == 1
estadd local hasfe = "No"
estadd local hascon = "No"

eststo: reg donation hchoice mchoice ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  & round == 1
estadd local hasfe = "No"
estadd local hascon = "Yes"

esttab using "$drive\tabs\Table1Round1.tex", se keep(hchoice mchoice) scalars("hasfe Fixed Effect" "hascon Controls") nomtitles mgroups("Hypothesis 1" "Hypothesis 2", pattern(1 0 0 1 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the total number of tokens donated on two treatment variables, Options and Choices. Columns (2) and (5) add covariate,s while column (3) adds fixed effects. Each regression controls for round effects. Standard errors are clustered at the participant level." ) ///
 alignment(c) label replace ///
 b(3) se(3) ///
      title (Effect of Treatments on Donations in Round 1 \label{Table1Round1})	
	
*******************************************************
*Interactions between treatments  in round 1 only
*******************************************************

eststo clear

eststo: reg donation hchoice mchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 & round == 1
estadd local hasfe = "No"
estadd local hascon = "No"
	  
eststo: reg donation hchoice mchoice hmchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2   & round == 1  
estadd local hasfe = "No"
estadd local hascon = "No"

eststo: reg donation hchoice mchoice hmchoice  ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2   & round == 1  
estadd local hasfe = "No"
estadd local hascon = "Yes"


esttab using "$drive\tabs\Table1aRound1.tex", se keep(hchoice mchoice hmchoice) scalars("hasfe Fixed Effect" "hascon Controls") nomtitles mgroups("Donations (Tokens)", pattern(1 0)   ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the amount experimental participants donated to charity on two treatment variables: the Options variable measures whether they could see 40 charities versus 5; the Choices variable measures whether they could select multiple charities to donate to versus just one. Individual fixed effects can be included for the Options treatment because there is within-participant variation in the number of charities seen, but the Choices treatment is between-participant. Regressions exclude the default treatment, which measures whether the participant has a pre-selected donation option, and perceived importance treatment which measures whether the participant can see the number of charities devoted to a cause before selecting that cause. Covariates include education level, race, marital status, employment status, religion, income, age, and gender." "Standard errors in parentheses, clustered by individual." "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)" ) ///
 alignment(c) label replace ///
  b(3) se(3) ///
      title (Effect of Treatments on Donations (Interaction) Round 1\label{Table1aRound1})	

	  
*******************************************************
*H1 & H2 in round 2 only
*******************************************************

eststo clear

eststo: reg donation hchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 & round == 2
estadd local hasfe = "No"
estadd local hascon = "No"

eststo: reg donation hchoice ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  & round == 2
estadd local hasfe = "No"
estadd local hascon = "Yes"

eststo: reg donation hchoice mchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  & round == 2
estadd local hasfe = "No"
estadd local hascon = "No"

eststo: reg donation hchoice mchoice ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  & round == 2
estadd local hasfe = "No"
estadd local hascon = "Yes"

esttab using "$drive\tabs\Table1Round2.tex", se keep(hchoice mchoice) scalars("hasfe Fixed Effect" "hascon Controls") nomtitles mgroups("Hypothesis 1" "Hypothesis 2", pattern(1 0 0 1 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the total number of tokens donated on two treatment variables, Options and Choices. Columns (2) and (5) add covariate,s while column (3) adds fixed effects. Each regression controls for round effects. Standard errors are clustered at the participant level." ) ///
 alignment(c) label replace ///
 b(3) se(3) ///
      title (Effect of Treatments on Donations in Round 2 \label{Table1Round2})	

*******************************************************
*Interactions between treatments in round 2 only
*******************************************************
eststo clear

eststo: reg donation hchoice mchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 & round == 2
estadd local hasfe = "No"
estadd local hascon = "No"
	  
eststo: reg donation hchoice mchoice hmchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2   & round == 2 
estadd local hasfe = "No"
estadd local hascon = "No"

eststo: reg donation hchoice mchoice hmchoice  ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2   & round == 2  
estadd local hasfe = "No"
estadd local hascon = "Yes"


esttab using "$drive\tabs\Table1aRound2.tex", se keep(hchoice mchoice hmchoice) scalars("hasfe Fixed Effect" "hascon Controls") nomtitles mgroups("Donations (Tokens)", pattern(1 0)   ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the amount experimental participants donated to charity on two treatment variables: the Options variable measures whether they could see 40 charities versus 5; the Choices variable measures whether they could select multiple charities to donate to versus just one. Individual fixed effects can be included for the Options treatment because there is within-participant variation in the number of charities seen, but the Choices treatment is between-participant. Regressions exclude the default treatment, which measures whether the participant has a pre-selected donation option, and perceived importance treatment which measures whether the participant can see the number of charities devoted to a cause before selecting that cause. Covariates include education level, race, marital status, employment status, religion, income, age, and gender." "Standard errors in parentheses, clustered by individual." "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)" ) ///
 alignment(c) label replace ///
  b(3) se(3) ///
      title (Effect of Treatments on Donations (Interaction) Round 2 \label{Table1aRound2})	
	  
	  
*******************************************************	  
*H3	  Default
*******************************************************	  
eststo clear

eststo: reg donation dchoice, cluster(id)
estadd local hasfe = "No"
estadd local hascon = "No"	

eststo: reg donation dchoice hchoice, cluster(id)
estadd local hasfe = "No"
estadd local hascon = "No"	

eststo: reg donation dchoice hchoice hdchoice, cluster(id)
estadd local hasfe = "No"
estadd local hascon = "No"	

eststo: reg donation dchoice hchoice hdchoice ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id)
estadd local hasfe = "No"
estadd local hascon = "Yes"	

eststo: xtreg donation dchoice hchoice hdchoice, cluster(id) i(id) fe
estadd local hasfe = "Yes"
estadd local hascon = "No"	

esttab using "$drive\tabs\Table2.tex", se keep(dchoice hchoice hdchoice) scalars("hasfe Fixed Effect" "hascon Controls") nomtitles mgroups("Hypothesis 3", pattern(1 0 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the amount experimental participants donated to charity on two treatment variables: the Options variable measures whether they could see 40 charities versus 5; the Default variable measures whether they had access to a pre-selected charity to donate to, meaning they did not had to make a decision. Individual fixed effects can be included for the Options treatment because there is within-participant variation in the number of charities seen, but the Default treatment is between-participant. Covariates include education level, race, marital status, employment status, religion, income, age, and gender." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Effect of Default Treatment on Donations \label{Table2})
	  

*******************************************************
*H4 Imortance 
*******************************************************
gen reveal = 0
replace reveal = 1 if (Treatments>12 & Treatments!=.)
label variable reveal "Reveal"

*Participant reveal hchoice

gen rhchoice = 0
replace rhchoice = 1 if Treatments==13
replace rhchoice = 1 if Treatments==15 &  Category > 1 & Category !=.0
replace rhchoice = 1 if Treatments==16 &  Category==1 

label variable rhchoice "Options * Reveal"

*Participant reveal low

gen rlow = 0
replace rlow  = 1 if Treatments==14
replace rlow = 1 if Treatments==15 &  Category==1 
replace rlow = 1 if Treatments==16 &  Category>1 & Category !=.0

label variable rlow "Reveal * Low"  


gen temp = .
replace temp = 1 if Treatments <13 & nvals == 1 
replace temp = 0 if Treatments >12 & Treatments<. & nvals == 1 
ksmirnov Category, by(temp)
ksmirnov Category, by(temp) exact

	
*Alternative specification:	 

gen animal = (Category==1)
label variable animal "Animal Welfare"

eststo clear

local i = 1
foreach x in HHHH LLLL LHHH HLLL {
	

	gen `x' = (Treatments==(12+`i'))
	
	replace `x' = . if Treatments<12
	
	gen animal`x' = animal*`x'
	
	label variable `x' "`x'"
	
	label variable animal`x' "Animal Welfare * `x'"
	
		
	local i = `i'+1
	
}


eststo clear

eststo: reg animal LHHH HLLL LLLL, cluster(id)
estadd local hascon = "No"	
eststo: reg animal LHHH HLLL LLLL ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id)
estadd local hascon = "Yes"	

esttab using "$drive\tabs\Table4.tex", se keep(LHHH HLLL LLLL)  scalars("hascon Controls") nomtitles mgroups("Hypothesis 4", pattern(1) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of a dummy measuring whether or not experimental participants donated to an animal welfare charity on three treatment dummies. In the base category, animal welfare and the other three charitable causes (children and young people; housing and hunger; health and medicine) all have 40 charities devoted to them. In the LHHH treatment, animal welfare has 5 charities and the others all have 40. In the HLLL treatment, animal welfare has 40 charities and the others all have 5. In the LLLL treatment, all causes have 5 charities devote devoted to them. Covariates include education level, race, marital status, employment status, religion, income, age, and gender." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Effect of Number of Charities on Chosen Cause \label{Table4})
	


	
*******************************************************
** extensive margin
*******************************************************

** r*Q: rate * Quantity // Q: = sum of amount := Extensive margin
** r*Q: rate * Quantity // r: = rate := fraction := Intensive

drop temp* 

ta Donors
ta Donors, nolabel 
ta Donors round

gen temp_donors = . 
replace temp_donors = 1 if Donors == 1 & round == 1
replace temp_donors = 0 if Donors == 1 & round == 2
replace temp_donors = 1 if Donors == 2 & round == 2
replace temp_donors = 0 if Donors == 2 & round == 1
replace temp_donors = 0 if Donors == 3 & round == 1
replace temp_donors = 0 if Donors == 3 & round == 2
replace temp_donors = 1 if Donors == 4 & round == 1
replace temp_donors = 1 if Donors == 4 & round == 2

ta temp_donors round if TreatmentSignal == 0 & TreatmentChoice != 2
ta temp_donors Donors if round == 1
ta temp_donors Donors if round == 2
ta temp_donors Donors if TreatmentSignal == 0 & TreatmentChoice != 2

ta temp_donors Donors

ta Treatments
ta Treatments, nolabel

*******************************************************
* is round 1 low? y = 0, n = 1 
gen temp_options1 = . 
replace temp_options1 = 0 if Treatments == 1 & round == 1
replace temp_options1 = 0 if Treatments == 3 & round == 1
replace temp_options1 = 0 if Treatments == 7 & round == 1
replace temp_options1 = 0 if Treatments == 9 & round == 1 
*
replace temp_options1 = 1 if Treatments == 4 & round == 1 
replace temp_options1 = 1 if Treatments == 6 & round == 1 
replace temp_options1 = 1 if Treatments == 10 & round == 1 
replace temp_options1 = 1 if Treatments == 12  & round == 1

* is round 2 low? y = 0, n = 1 
replace temp_options1 = 1 if Treatments == 1 & round == 2 
replace temp_options1 = 1 if Treatments == 3 & round == 2 
replace temp_options1 = 0 if Treatments == 7 & round == 2 
replace temp_options1 = 0 if Treatments == 9 & round == 2  
*
replace temp_options1 = 0 if Treatments == 4 & round == 2  
replace temp_options1 = 0 if Treatments == 6 & round == 2  
replace temp_options1 = 1 if Treatments == 10 & round == 2  
replace temp_options1 = 1 if Treatments == 12 & round == 2  

ta temp_options1 Treatments
ta temp_options1 temp_donors
ta hchoice temp_options1

gen temp_choice = . 
replace temp_choice = 0 if Treatments == 1
replace temp_choice = 1 if Treatments == 3
replace temp_choice = 0 if Treatments == 4
replace temp_choice = 1 if Treatments == 6
replace temp_choice = 0 if Treatments == 7
replace temp_choice = 1 if Treatments == 9
replace temp_choice = 0 if Treatments == 10
replace temp_choice = 1 if Treatments == 12

ta temp_choice Treatments
ta temp_donors Treatments

gen temp_options1_choice = temp_options1 * temp_choice

ta temp_options1_choice 

ta temp_options1 temp_choice if round == 1
ta temp_options1 temp_donors if round == 1


gen temp_round = round - 1

gen temp_options1_choice_round = temp_options1 * temp_choice * temp_round

gen temp_options1_round = temp_options1 * temp_round

gen temp_choice_round = temp_choice * temp_round


eststo clear
			
eststo: reg temp_donors temp_options1  ///
			temp_round temp_options1_round   /// 
			if TreatmentChoice == 1, cluster(id)
			estadd local hasfe = "No"
			estadd local hascon = "No"


eststo: xtreg temp_donors temp_options1  ///
			temp_round temp_options1_round   /// 
			, i(id) cluster(id) fe ///
			, if TreatmentChoice == 1 
			estadd local hasfe = "Yes"
			estadd local hascon = "No"

eststo: reg temp_donors temp_options1  ///
			temp_round temp_options1_round   /// 
			ib1.education ib14.ethnicity ib5.marital ///
			ib7.employment ib6.religion ib2.income age ib2.male ///
			if TreatmentChoice == 1, cluster(id) 
			estadd local hasfe = "No"
			estadd local hascon = "Yes"

eststo: reg  temp_donors temp_choice  temp_choice_round ///
			if TreatmentChoice != 2  , cluster(id) 
			estadd local hasfe = "No"
			estadd local hascon = "No"

eststo: reg  temp_donors temp_choice temp_choice_round ///
			ib1.education ib14.ethnicity ib5.marital ///
			ib7.employment ib6.religion ib2.income age ib2.male ///
			if TreatmentChoice != 2  , cluster(id)
			estadd local hasfe = "No"
			estadd local hascon = "Yes"
			
eststo: reg temp_donors temp_options1  ///
			temp_round temp_options1_round   /// 
			temp_choice temp_choice_round ///
			temp_options1_choice_round  ///
			temp_options1_choice ///
			if TreatmentChoice != 2  , cluster(id) 
			estadd local hasfe = "No"
			estadd local hascon = "No"
			
eststo: reg temp_donors temp_options1  ///
			temp_round temp_options1_round   /// 
			temp_choice temp_choice_round ///
			temp_options1_choice_round  ///
			temp_options1_choice ///
			ib1.education ib14.ethnicity ib5.marital ///
			ib7.employment ib6.religion ib2.income age ib2.male ///
			if TreatmentChoice != 2  , cluster(id) 
			estadd local hasfe = "No"
			estadd local hascon = "Yes"
			

label variable temp_options1 "Options"
label variable temp_round "Round"
label variable temp_options1_round "Options times Round"
label variable temp_choice "Choice"
label variable temp_choice_round "Choice times Round"
label variable temp_options1_choice_round "Options times Choice times Round"


esttab using "$drive\tabs\Extensivenew.tex", ///
    star(* 0.10 ** 0.05 *** 0.01) se ///
    keep(temp_options1 temp_options1_choice temp_round temp_options1_round temp_choice temp_choice_round temp_options1_choice_round ) ///
    scalars("hasfe Fixed Effect" "hascon Controls") nomtitles ///
    mgroups("Hypothesis 1" "Hypothesis 2", pattern(1 0 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
    nonotes addnote("TEXT", ///
    "Standard errors in parentheses, clustered by individual.", ///
    "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
    alignment(c) label replace ///
    b(3) se(3) ///
    title(Effect of Treatments on Donations \label{TableExtensivenew})


*******************************************************
** only in round 1:

drop temp* 

ta Donors
ta Donors, nolabel 
ta Donors round

gen temp_donors = . 
replace temp_donors = 1 if Donors == 1 & round == 1
replace temp_donors = 0 if Donors == 2 & round == 1
replace temp_donors = 0 if Donors == 3 & round == 1
replace temp_donors = 1 if Donors == 4 & round == 1

ta temp_donors round if TreatmentSignal == 0 & TreatmentChoice != 2
ta temp_donors Donors if round == 1
ta temp_donors Donors if round == 2
ta temp_donors Donors if TreatmentSignal == 0 & TreatmentChoice != 2

ta temp_donors Donors

ta Treatments
ta Treatments, nolabel

* is round 1 low? y = 0, n = 1 
gen temp_options1 = . 
replace temp_options1 = 0 if Treatments == 1 & round == 1
replace temp_options1 = 0 if Treatments == 3 & round == 1
replace temp_options1 = 0 if Treatments == 7 & round == 1
replace temp_options1 = 0 if Treatments == 9 & round == 1 
*
replace temp_options1 = 1 if Treatments == 4 & round == 1 
replace temp_options1 = 1 if Treatments == 6 & round == 1 
replace temp_options1 = 1 if Treatments == 10 & round == 1 
replace temp_options1 = 1 if Treatments == 12  & round == 1


ta temp_options1 Treatments
ta temp_options1 temp_donors
ta hchoice temp_options1

gen temp_choice = . 
replace temp_choice = 0 if Treatments == 1
replace temp_choice = 1 if Treatments == 3
replace temp_choice = 0 if Treatments == 4
replace temp_choice = 1 if Treatments == 6
replace temp_choice = 0 if Treatments == 7
replace temp_choice = 1 if Treatments == 9
replace temp_choice = 0 if Treatments == 10
replace temp_choice = 1 if Treatments == 12

ta temp_choice Treatments
ta temp_donors Treatments

gen temp_options1_choice = temp_options1 * temp_choice

ta temp_options1_choice 

ta temp_options1 temp_choice if round == 1
ta temp_options1 temp_donors if round == 1



eststo clear
			
eststo: reg temp_donors temp_options1  /// 
			if TreatmentChoice == 1, cluster(id)
			estadd local hasfe = "No"
			estadd local hascon = "No"

eststo: reg temp_donors temp_options1  ///
			ib1.education ib14.ethnicity ib5.marital ///
			ib7.employment ib6.religion ib2.income age ib2.male ///
			if TreatmentChoice == 1, cluster(id)
			estadd local hasfe = "No"
			estadd local hascon = "Yes"

eststo: reg  temp_donors temp_choice  ///
			, cluster(id)
			estadd local hasfe = "No"
			estadd local hascon = "No"

eststo: reg  temp_donors temp_choice ///
			ib1.education ib14.ethnicity ib5.marital ///
			ib7.employment ib6.religion ib2.income age ib2.male ///
			, cluster(id)
			estadd local hasfe = "No"
			estadd local hascon = "Yes"
			
eststo: reg temp_donors temp_options1  ///
			temp_choice temp_options1_choice ///
			, cluster(id)
			estadd local hasfe = "No"
			estadd local hascon = "No"
			
eststo: reg temp_donors temp_options1  ///
			temp_choice temp_options1_choice ///
			ib1.education ib14.ethnicity ib5.marital ///
			ib7.employment ib6.religion ib2.income age ib2.male ///
			, cluster(id)
			estadd local hasfe = "No"
			estadd local hascon = "Yes"
			

label variable temp_options1 "Options"
label variable temp_choice "Choice"
label variable temp_options1_choice "Options times Choice"



* Exporting results using esttab
esttab using "$drive\tabs\TableExtensivenewRound1.tex", star(* 0.10 ** 0.05 *** 0.01) se keep(temp_options1  temp_choice temp_options1_choice  ) ///
    scalars("hasfe Fixed Effect" "hascon Controls") nomtitles mgroups("Hypothesis 1" "Hypothesis 2", pattern(1 0 0 1 0) ///
    prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
    nonotes addnote("TEXT", ///
    "Standard errors in parentheses, clustered by individual.", ///
    "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)" ) ///
	b(3) se(3) ///
    alignment(c) label replace ///
    title(Effect of Treatments on Donations \label{TableExtensivenewRound1})

	
	

*******************************************************
* Mediator regressions: 
** does adding satisfacton, regret etc. eliminate significance of treatment?
** Defining the Vars
*******************************************************

drop nvals 
by code, sort: gen nvals = _n == 1 
count if nvals
ta nvals

*Options treatment - defined for whole sample
**drop temp*

gen temp_donation = total_donation *80
label variable donation "Donation Amount (Tokens)"

gen temp_hchoice_subset_r1 = .
replace temp_hchoice_subset_r1 = 0 if Treatments ==7 & nvals==1
replace temp_hchoice_subset_r1 = 0 if Treatments ==8 & nvals==1
replace temp_hchoice_subset_r1 = 0 if Treatments ==9 & nvals==1
replace temp_hchoice_subset_r1 = 1 if Treatments ==10 & nvals==1
replace temp_hchoice_subset_r1 = 1 if Treatments ==11 & nvals==1
replace temp_hchoice_subset_r1 = 1 if Treatments ==12 & nvals==1

ta temp_hchoice_subset_r1 Treatments

gen temp_mchoice_subset = .
replace temp_mchoice_subset = 0 if Treatments ==7 & nvals==1
replace temp_mchoice_subset = 0 if Treatments ==10 & nvals==1
replace temp_mchoice_subset = 1 if Treatments ==9 & nvals==1
replace temp_mchoice_subset = 1 if Treatments ==12 & nvals==1

ta temp_mchoice_subset Treatments

gen temp_dchoice_subset = .
replace temp_dchoice_subset = 0 if Treatments ==7 & nvals==1
replace temp_dchoice_subset = 0 if Treatments ==10 & nvals==1
replace temp_dchoice_subset = 1 if Treatments ==8 & nvals==1
replace temp_dchoice_subset = 1 if Treatments ==11 & nvals==1

ta temp_dchoice_subset Treatments

gen temp_hmchoice_subset = temp_hchoice_subset_r1 * temp_mchoice_subset
gen temp_hdchoice_subset = temp_hchoice_subset_r1 * temp_dchoice_subset

ta temp_hmchoice_subset Treatments
ta temp_hdchoice_subset Treatments

ta temp_donation if TreatmentChoice == 1 & temp_hchoice_subset_r1 != .


label variable temp_hchoice_subset_r1 "Options"  

label variable temp_mchoice_subset "Choice"  

label variable temp_hmchoice_subset "Options $\times$ Choice"

label variable temp_donation "Amount of Donation"


*******************************************************
*Extensive margin (Cahal)

gen extdon = .
replace extdon = 0 if donation == 0
replace extdon = 1 if donation > 1 & donation!=.

eststo clear

eststo: reg extdon hchoice round, cluster(id), if TreatmentSignal==0 & TreatmentChoice==1
estadd local hasfe = "No"
estadd local hascon = "No"

eststo: reg extdon hchoice round ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "No"
estadd local hascon = "Yes"

eststo: xtreg extdon hchoice round, i(id) cluster(id) fe, if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "Yes"
estadd local hascon = "N/A"

eststo: reg extdon hchoice mchoice round, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "No"
estadd local hascon = "No"

eststo: reg extdon hchoice mchoice round ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "No"
estadd local hascon = "Yes"

esttab using "$drive\tabs\Extensive1.tex", se keep(hchoice mchoice round) scalars("hasfe Fixed Effect" "hascon Controls") nomtitles mgroups("Hypothesis 1" "Hypothesis 2", pattern(1 0 0 1 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("Linear OLS regressions using a binary measure for whetehr or not a participant donated at all as a dependent variable. There are two treatment variables: the Options variable measures whether they could see 40 charities versus 5; the Choices variable measures whether they could select multiple charities to donate to versus just one. Individual fixed effects can be included for the Options treatment because there is within-participant variation in the number of charities seen, but the Choices treatment is between-participant. Regressions exclude the default arm of the experiment, which measures whether the participant has a pre-selected donation option, and the perceived importance arm, which measures whether the participant can see the number of charities devoted to a cause before selecting that cause. Covariates include education level, race, marital status, employment status, religion, income, age, and gender." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)" ) ///
 alignment(c) label replace ///
      title (Effect of Treatments on Donations \label{TableExtensive1})	

	  
	  
	  
**# Bookmark #1
*******************************************************
*** # 1 Satisfaction : H/L and 1/Many
*******************************************************

alpha satisfactionD1_temp satisfactionD2_temp satisfactionD3_temp satisfactionD4_temp satisfactionD5_temp  satisfactionD6_temp, std item, if TreatmentChoice != 2

eststo clear

eststo: reg satisD temp_hchoice_subset_r1, cluster(id), if TreatmentChoice == 1 

eststo: reg satisD temp_hchoice_subset_r1 temp_donation,  cluster(id), if TreatmentChoice == 1 

eststo: reg satisD temp_mchoice_subset, cluster(id), if TreatmentChoice !=2 

eststo: reg satisD temp_mchoice_subset temp_donation, cluster(id), if TreatmentChoice !=2 

eststo: reg satisD temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset , cluster(id)

eststo: reg satisD temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset temp_donation, cluster(id)


esttab using "$drive\tabs\Table5new.tex", star(* 0.10 ** 0.05 *** 0.01) se keep(temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset temp_donation) nomtitles mgroups("Choice Satisfaction", pattern(1 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions using a dependent variable measuring the satisfaction experimental participants reported after donating to charity. The Options variable measures whether they could see 40 charities versus 5; the Choices variable measures whether they could choose only one charity versus multiple charities. Columns (2) and (4)include the tokens donated by participants as a mediator variable." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of the Effect of Treatments On Satisfaction \label{Table5new})

** satisD
mediate (temp_donation) (satisD) (temp_hchoice_subset_r1), nie nde te, if TreatmentChoice == 1
mediate (temp_donation) (satisD) (temp_mchoice_subset), nie nde te, if TreatmentChoice != 2
mediate (temp_donation) (satisD) (temp_hmchoice_subset), nie nde te, if TreatmentChoice != 2

** a
regress satisD temp_hchoice_subset_r1 if TreatmentChoice == 1
regress satisD temp_mchoice_subset if TreatmentChoice != 2
regress satisD temp_hmchoice_subset if TreatmentChoice != 2

** b
regress temp_donation satisD temp_hchoice_subset_r1 if TreatmentChoice == 1
regress temp_donation satisD temp_mchoice_subset if TreatmentChoice != 2
regress temp_donation satisD temp_hmchoice_subset if TreatmentChoice != 2

** c'
regress temp_donation satisD temp_hchoice_subset_r1 if TreatmentChoice == 1
regress temp_donation satisD temp_mchoice_subset if TreatmentChoice != 2
regress temp_donation satisD temp_hmchoice_subset if TreatmentChoice != 2


** regrD
mediate (temp_donation) (regrD) (temp_hchoice_subset_r1), nie nde te, if TreatmentChoice == 1
mediate (temp_donation) (regrD) (temp_mchoice_subset), nie nde te, if TreatmentChoice != 2
mediate (temp_donation) (regrD) (temp_hmchoice_subset), nie nde te, if TreatmentChoice != 2

** a
regress regrD temp_hchoice_subset_r1 if TreatmentChoice == 1
regress regrD temp_mchoice_subset if TreatmentChoice != 2
regress regrD temp_hmchoice_subset if TreatmentChoice != 2

** b
regress temp_donation regrD temp_hchoice_subset_r1 if TreatmentChoice == 1
regress temp_donation regrD temp_mchoice_subset if TreatmentChoice != 2
regress temp_donation regrD temp_hmchoice_subset if TreatmentChoice != 2

** c'
regress temp_donation regrD temp_hchoice_subset_r1 if TreatmentChoice == 1
regress temp_donation regrD temp_mchoice_subset if TreatmentChoice != 2
regress temp_donation regrD temp_hmchoice_subset if TreatmentChoice != 2

*******************************************************
*** # 2 Regret : H/L and 1/Many
*******************************************************

alpha regretD1_temp regretD2_temp regretD3_temp, std item, if TreatmentChoice != 2

eststo clear

eststo: reg regrD temp_hchoice_subset_r1, cluster(id), if TreatmentChoice == 1 

eststo: reg regrD temp_hchoice_subset_r1 temp_donation,  cluster(id), if TreatmentChoice == 1 

eststo: reg regrD temp_mchoice_subset, cluster(id), if TreatmentChoice !=2 

eststo: reg regrD temp_mchoice_subset temp_donation, cluster(id), if TreatmentChoice !=2 

eststo: reg regrD temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset , cluster(id)

eststo: reg regrD temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset temp_donation, cluster(id)

esttab using "$drive\tabs\Table6new.tex", star(* 0.10 ** 0.05 *** 0.01) se keep(temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset temp_donation) nomtitles mgroups("Choice Regret", pattern(1 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions using a dependent variable measuring the regret experimental participants reported after donating to charity. The Options variable measures whether they could see 40 charities versus 5 and the Choices variable measures whether they could choose only one charity versus multiple charities. Columns (2) and (4) include the tokens donated by participants as a mediator variable." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of the Effect of Treatments On Regret \label{Table6new})
	  
*******************************************************
*** # 3 Satisfaction : H/L and default
*******************************************************
gen temp_round = round - 1
  
alpha satisfactionD1_temp satisfactionD2_temp satisfactionD3_temp satisfactionD4_temp satisfactionD5_temp  satisfactionD6_temp, std item, if TreatmentChoice == 2

eststo clear

eststo: reg satisD temp_hchoice_subset_r1  , cluster(id), if TreatmentChoice == 1 

eststo: reg satisD temp_hchoice_subset_r1 temp_donation,  cluster(id), if TreatmentChoice == 1 

eststo: reg satisD temp_hchoice_subset_r1 temp_dchoice_subset temp_hdchoice_subset temp_donation, cluster(id)

esttab using "$drive\tabs\Table5newD.tex", star(* 0.10 ** 0.05 *** 0.01) se keep(temp_hchoice_subset_r1 temp_dchoice_subset temp_hdchoice_subset temp_donation) nomtitles mgroups("Choice Satisfaction", pattern(1 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions using a dependent variable measuring the satisfaction experimental participants reported after donating to charity. The Options variable measures whether they could see 40 charities versus 5; the Choices variable measures whether they could defaul and 1choice." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of the Effect of Treatments On Satisfaction \label{Table5newD})

*******************************************************
*** # 4 Regret : H/L and default
*******************************************************


alpha regretD1_temp regretD2_temp regretD3_temp, std item, if TreatmentChoice == 2

eststo clear

eststo: reg regrD temp_hchoice_subset_r1, cluster(id), if TreatmentChoice == 1 

eststo: reg regrD temp_hchoice_subset_r1 temp_donation,  cluster(id), if TreatmentChoice == 1 

** eststo: reg regrD temp_mchoice_subset,  cluster(id) // not infomative since high and low are mixed here
** eststo: reg regrD temp_mchoice_subset temp_donation,  cluster(id) // not infomative since high and low are mixed here

eststo: reg regrD temp_hchoice_subset_r1 temp_dchoice_subset temp_hdchoice_subset temp_donation, cluster(id)

esttab using "$drive\tabs\Table6newD.tex", star(* 0.10 ** 0.05 *** 0.01) se keep(temp_hchoice_subset_r1 temp_dchoice_subset temp_hdchoice_subset temp_donation) nomtitles mgroups("Choice Regret", pattern(1 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions using a dependent variable measuring the regret experimental participants reported after donating to charity. The Options variable measures whether they could see 40 charities versus 5 and the Choices variable measures whether they could could defaul and 1choic" "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of the Effect of Treatments On Regret \label{Table6newD})


*******************************************************
* Interactions between rounds using satisfaction and regret
*******************************************************

xtset id round

eststo clear

eststo m1: reg satisD hchoice ///
    if TreatmentSignal==0 & TreatmentChoice!=2 & TreatmentChoice!=3, ///
    vce(cluster id)

estadd local hascon "No"


eststo m2: reg satisD donation hchoice hchoice_lag ///
    if TreatmentSignal==0 & TreatmentChoice!=2 & TreatmentChoice!=3 & round==2, ///
    vce(cluster id)
estadd local hascon "No"

* Linear combinations (use lincom to grab estimate, SE, p-val)
* HH = _cons + hchoice + hchoice_lag
* HL = _cons + hchoice_lag
* LH = _cons + hchoice
* LL = _cons

test (_cons + hchoice + hchoice_lag) = (_cons ) //HH
test (_cons + hchoice_lag) = (_cons ) // HL
test (_cons + hchoice) = (_cons ) // LH


eststo m3: reg satisD donation hchoice hchoice_lag ///
    ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ///
    ib2.income age ib2.male ///
    if TreatmentSignal==0 & TreatmentChoice!=2 & TreatmentChoice!=3 & round==2, ///
    vce(cluster id)

estadd local hascon "Yes"


test (_cons + hchoice + hchoice_lag) = (_cons ) //HH
test (_cons + hchoice_lag) = (_cons ) // HL
test (_cons + hchoice) = (_cons ) // LH

*---------------------------------------
* Export table
*---------------------------------------
* Show coefficients of interest in rows; show HH/HL/LH/LL in the scalars block.
* You can label the scalars however you like. Below I also add the p-values.
esttab m1 m2 m3 using "$drive/tabs/Table1bSatis.tex", ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(donation hchoice hchoice_lag) ///
    scalars( ///
        "hascon Controls" ///
    ) ///
    nomtitles ///
    mgroups("Donations (Tokens)", pattern(1 0), ///
       ) ///
    nonotes addnote("Add") alignment(c) label replace ///
    title("Effect of Options Treatment on Donations, with Lags \label{Table1bSatis}")

	
xtset id round

eststo clear

eststo m1: reg regrD hchoice ///
    if TreatmentSignal==0 & TreatmentChoice!=2 & TreatmentChoice!=3, ///
    vce(cluster id)

estadd local hascon "No"


eststo m2: reg regrD donation hchoice hchoice_lag ///
    if TreatmentSignal==0 & TreatmentChoice!=2 & TreatmentChoice!=3 & round==2, ///
    vce(cluster id)
estadd local hascon "No"

* Linear combinations (use lincom to grab estimate, SE, p-val)
* HH = _cons + hchoice + hchoice_lag
* HL = _cons + hchoice_lag
* LH = _cons + hchoice
* LL = _cons

test (_cons + hchoice + hchoice_lag) = (_cons ) //HH
test (_cons + hchoice_lag) = (_cons ) // HL
test (_cons + hchoice) = (_cons ) // LH


eststo m3: reg regrD donation hchoice hchoice_lag ///
    ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ///
    ib2.income age ib2.male ///
    if TreatmentSignal==0 & TreatmentChoice!=2 & TreatmentChoice!=3 & round==2, ///
    vce(cluster id)

estadd local hascon "Yes"


test (_cons + hchoice + hchoice_lag) = (_cons ) //HH
test (_cons + hchoice_lag) = (_cons ) // HL
test (_cons + hchoice) = (_cons ) // LH


reg satisD ib3.TreatmentOptions  ///
	if TreatmentSignal==0 & TreatmentChoice!=2 & TreatmentChoice!=3 & round==2, ///
    vce(cluster id)


*---------------------------------------
* Export table
*---------------------------------------
* Show coefficients of interest in rows; show HH/HL/LH/LL in the scalars block.
* You can label the scalars however you like. Below I also add the p-values.
esttab m1 m2 m3 using "$drive/tabs/Table1bregrD.tex", ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(donation hchoice hchoice_lag) ///
    scalars( ///
        "hascon Controls" ///
    ) ///
    nomtitles ///
    mgroups("regrD", pattern(1 0), ///
       ) ///
    nonotes addnote("Add") alignment(c) label replace ///
    title("Effect of Options Treatment on Donations, with Lags \label{Table1bregrDs}")

	

**********************
gen temp_LL = .  
replace temp_LL = 1 if Treatments == 7 
replace temp_LL = 0 if Treatments != 7 

gen temp_LH = .  
replace temp_LH = 1 if Treatments == 1 
replace temp_LH = 0 if Treatments == 7 

gen temp_HL = .  
replace temp_HL = 1 if Treatments == 4 
replace temp_HL = 0 if Treatments == 7 

gen temp_HH = .  
replace temp_HH = 1 if Treatments == 10 
replace temp_HH = 0 if Treatments == 7 

ta Treatments temp_LH
ta Treatments temp_HL
ta Treatments temp_HH

** drop temp_LL temp_LH temp_HL temp_HH
eststo clear

eststo: reg satisD temp_LH if round ==1,  cluster(id)
eststo: reg satisD temp_HL if round ==1,  cluster(id)
eststo: reg satisD temp_HH if round ==1,  cluster(id)

eststo: reg satisD temp_LH donation if round ==1,  cluster(id)
eststo: reg satisD temp_HL donation if round ==1,  cluster(id)
eststo: reg satisD temp_HH donation if round ==1,  cluster(id)


eststo: reg regrD temp_LH if round ==1,  cluster(id)
eststo: reg regrD temp_HL if round ==1,  cluster(id)
eststo: reg regrD temp_HH if round ==1,  cluster(id)

eststo: reg donation satisD temp_LH if round ==1,  cluster(id)
eststo: reg donation satisD temp_HL if round ==1,  cluster(id)
eststo: reg donation satisD temp_HH if round ==1,  cluster(id)

eststo: reg donation regrD temp_LH if round ==1,  cluster(id)
eststo: reg donation regrD temp_HL if round ==1,  cluster(id)
eststo: reg donation regrD temp_HH if round ==1,  cluster(id)

gen temp_satis_treatment = . 
replace temp_satis_treatment = 1 if Treatments == 7 
replace temp_satis_treatment = 2 if Treatments == 1 
replace temp_satis_treatment = 3 if Treatments == 4 
replace temp_satis_treatment = 4 if Treatments == 10 

label values temp_satis_treatment dttemp_satis_treatment
label def dttemp_satis_treatment 1 "Low-Low", modify
label def dttemp_satis_treatment 2 "Low-High", modify
label def dttemp_satis_treatment 3 "High-Low", modify
label def dttemp_satis_treatment 4 "High-High", modify


gen temp_satisD_OptionLL = satisD if (Treatments == 7 )
gen temp_satisD_OptionHH = satisD if (Treatments == 10)
gen temp_satisD_OptionHL = satisD if (Treatments == 4 )
gen temp_satisD_OptionLH = satisD if (Treatments == 1)

gen temp_satisD_Option = satisD if (Treatments == 7 | Treatments == 10 | Treatments == 4 | Treatments == 1)

summarize temp_satisD_Option if Treatments == 7 , d
local meanL=r(mean)
local medianL=r(p50) 

summarize temp_satisD_Option if Treatments == 10 , d
local meanH=r(mean)
local medianH=r(p50) 

summarize temp_satisD_Option if Treatments == 4 , d
local meanHL=r(mean)
local medianHL=r(p50) 

summarize temp_satisD_Option if Treatments == 1 , d
local meanLH=r(mean)
local medianLH=r(p50) 


twoway ///
	(histogram temp_satisD_OptionLL, discrete, if nvals == 1, percent lcolor(gs10) fcolor(gs10)  ) ///        
    (histogram temp_satisD_OptionHH, discrete, if nvals == 1,  percent fcolor(red%60) lcolor(red%60) fintensity(inten10)) ///
	(histogram temp_satisD_OptionHL, discrete, if nvals == 1, percent lcolor(blue) fcolor(gs10)  ) ///        
    (histogram temp_satisD_OptionLH, discrete, if nvals == 1,  percent fcolor(black) lcolor(red%60) fintensity(inten10))	
	
	
twoway ///
    (kdensity temp_satisD_OptionLL if nvals == 1, lcolor(gs10) ) ///
    (kdensity temp_satisD_OptionHH if nvals == 1, lcolor(red%60)) ///
    (kdensity temp_satisD_OptionHL if nvals == 1, lcolor(blue)) ///
    (kdensity temp_satisD_OptionLH if nvals == 1, lcolor(black)) 

	
	
	  
*******************************************************
*** # 5 Other vars: H/L 1/Many
*******************************************************

** 1 diffic
label variable diffic "Difficulty of Choices"

mediate (temp_donation) (diffic) (temp_hchoice_subset_r1) if TreatmentChoice==1 

mediate (temp_donation) (diffic) (temp_hchoice_subset_r1), nie nde te, if TreatmentChoice == 1
mediate (temp_donation) (diffic) (temp_mchoice_subset), nie nde te, if TreatmentChoice != 2
mediate (temp_donation) (diffic) (temp_hmchoice_subset), nie nde te, if TreatmentChoice != 2

** a
regress diffic temp_hchoice_subset_r1 if TreatmentChoice == 1
regress diffic temp_mchoice_subset if TreatmentChoice != 2
regress diffic temp_hmchoice_subset if TreatmentChoice != 2

** b
regress temp_donation diffic temp_hchoice_subset_r1 if TreatmentChoice == 1
regress temp_donation diffic temp_mchoice_subset if TreatmentChoice != 2
regress temp_donation diffic temp_hmchoice_subset if TreatmentChoice != 2

** c'
regress temp_donation diffic temp_hchoice_subset_r1 if TreatmentChoice == 1
regress temp_donation diffic temp_mchoice_subset if TreatmentChoice != 2
regress temp_donation diffic temp_hmchoice_subset if TreatmentChoice != 2


eststo clear

eststo: reg diffic temp_hchoice_subset_r1, cluster(id), if TreatmentChoice == 1 

eststo: reg diffic temp_hchoice_subset_r1 temp_donation,  cluster(id), if TreatmentChoice == 1 

eststo: reg diffic temp_mchoice_subset, cluster(id), if TreatmentChoice !=2 

eststo: reg diffic temp_mchoice_subset temp_donation, cluster(id), if TreatmentChoice !=2 

eststo: reg diffic temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset , cluster(id)

eststo: reg diffic temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset temp_donation, cluster(id)

esttab using "$drive\tabs\Table6newDiffic.tex", star(* 0.10 ** 0.05 *** 0.01) se keep(temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset temp_donation) nomtitles mgroups("Choice Difficulty", pattern(1 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions using a dependent variable measuring the regret experimental participants reported after donating to charity. The Options variable measures whether they could see 40 charities versus 5 and the Choices variable measures whether they could choose only one charity versus multiple charities. Columns (2) and (4) include the tokens donated by participants as a mediator variable." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of the Effect of Treatments On Regret \label{Table6newDiffic})



** 2 familiarityD1_temp
label variable familiarityD1_temp "Familiarity with Charities"  

mediate (temp_donation) (familiarityD1_temp) (temp_hchoice_subset_r1) if TreatmentChoice==1 



mediate (temp_donation) (familiarityD1_temp) (temp_hchoice_subset_r1), nie nde te, if TreatmentChoice == 1
mediate (temp_donation) (familiarityD1_temp) (temp_mchoice_subset), nie nde te, if TreatmentChoice != 2
mediate (temp_donation) (familiarityD1_temp) (temp_hmchoice_subset), nie nde te, if TreatmentChoice != 2

** a
regress familiarityD1_temp temp_hchoice_subset_r1 if TreatmentChoice == 1
regress familiarityD1_temp temp_mchoice_subset if TreatmentChoice != 2
regress familiarityD1_temp temp_hmchoice_subset if TreatmentChoice != 2

** b
regress temp_donation familiarityD1_temp temp_hchoice_subset_r1 if TreatmentChoice == 1
regress temp_donation familiarityD1_temp temp_mchoice_subset if TreatmentChoice != 2
regress temp_donation familiarityD1_temp temp_hmchoice_subset if TreatmentChoice != 2

** c'
regress temp_donation familiarityD1_temp temp_hchoice_subset_r1 if TreatmentChoice == 1
regress temp_donation familiarityD1_temp temp_mchoice_subset if TreatmentChoice != 2
regress temp_donation familiarityD1_temp temp_hmchoice_subset if TreatmentChoice != 2

eststo clear

eststo: reg familiarityD1_temp temp_hchoice_subset_r1, cluster(id), if TreatmentChoice == 1 

eststo: reg familiarityD1_temp temp_hchoice_subset_r1 temp_donation,  cluster(id), if TreatmentChoice == 1 

eststo: reg familiarityD1_temp temp_mchoice_subset, cluster(id), if TreatmentChoice !=2 

eststo: reg familiarityD1_temp temp_mchoice_subset temp_donation, cluster(id), if TreatmentChoice !=2 

eststo: reg familiarityD1_temp temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset , cluster(id)

eststo: reg familiarityD1_temp temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset temp_donation, cluster(id)

esttab using "$drive\tabs\Table6newfamiliarityD1_temp.tex", star(* 0.10 ** 0.05 *** 0.01) se keep(temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset temp_donation) nomtitles mgroups("Choice familiarityD1_tempulty", pattern(1 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions using a dependent variable measuring the regret experimental participants reported after donating to charity. The Options variable measures whether they could see 40 charities versus 5 and the Choices variable measures whether they could choose only one charity versus multiple charities. Columns (2) and (4) include the tokens donated by participants as a mediator variable." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of the Effect of Treatments On Regret \label{Table6newfamiliarityD1_temp})
	  
	  
** 3 Deliberation
label variable deliberationD1_temp "Deliberation over Choices"  
mediate (temp_donation) (deliberationD1_temp) (temp_hchoice_subset_r1) if TreatmentChoice==1 

pwcorr diffic deliberationD1_temp familiarityD1_temp, sig, if TreatmentChoice != 2


mediate (temp_donation) (deliberationD1_temp) (temp_hchoice_subset_r1), nie nde te, if TreatmentChoice == 1
mediate (temp_donation) (deliberationD1_temp) (temp_mchoice_subset), nie nde te, if TreatmentChoice != 2
mediate (temp_donation) (deliberationD1_temp) (temp_hmchoice_subset), nie nde te, if TreatmentChoice != 2

** a
regress deliberationD1_temp temp_hchoice_subset_r1 if TreatmentChoice == 1
regress deliberationD1_temp temp_mchoice_subset if TreatmentChoice != 2
regress deliberationD1_temp temp_hmchoice_subset if TreatmentChoice != 2

** b
regress deliberationD1_temp familiarityD1_temp temp_hchoice_subset_r1 if TreatmentChoice == 1
regress deliberationD1_temp familiarityD1_temp temp_mchoice_subset if TreatmentChoice != 2
regress deliberationD1_temp familiarityD1_temp temp_hmchoice_subset if TreatmentChoice != 2

** c'
regress deliberationD1_temp familiarityD1_temp temp_hchoice_subset_r1 if TreatmentChoice == 1
regress deliberationD1_temp familiarityD1_temp temp_mchoice_subset if TreatmentChoice != 2
regress deliberationD1_temp familiarityD1_temp temp_hmchoice_subset if TreatmentChoice != 2

eststo clear

eststo: reg deliberationD1_temp temp_hchoice_subset_r1, cluster(id), if TreatmentChoice == 1 

eststo: reg deliberationD1_temp temp_hchoice_subset_r1 temp_donation,  cluster(id), if TreatmentChoice == 1 

eststo: reg deliberationD1_temp temp_mchoice_subset, cluster(id), if TreatmentChoice !=2 

eststo: reg deliberationD1_temp temp_mchoice_subset temp_donation, cluster(id), if TreatmentChoice !=2 

eststo: reg deliberationD1_temp temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset , cluster(id)

eststo: reg deliberationD1_temp temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset temp_donation, cluster(id)

esttab using "$drive\tabs\Table6newdeliberationD1_temp.tex", star(* 0.10 ** 0.05 *** 0.01) se keep(temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset temp_donation) nomtitles mgroups("Deliberation over Choices", pattern(1 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions using a dependent variable measuring the regret experimental participants reported after donating to charity. The Options variable measures whether they could see 40 charities versus 5 and the Choices variable measures whether they could choose only one charity versus multiple charities. Columns (2) and (4) include the tokens donated by participants as a mediator variable." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of the Effect of Treatments On Regret \label{Table6newfamiliarityD1_temp})
	  


	  	  
** 4 avoid

ta avoid Donors

ta Donors
ta Donors, nolabel

reg avoid ib4.Donors if Donors != 0 & nvals == 1
reg avoid ib3.Donors if Donors != 0 & nvals == 1

tabstat avoid, by(Donors) stat(mean sd n)
table Donors TreatmentChoice, statistic(mean avoid)
table Donors Treatments, statistic(mean avoid) statistic(count avoid), if Treatments < 13
table Donors TreatmentChoice, statistic(mean avoid), if Treatments < 13

graph bar (mean) avoid if Treatments < 5, over(Donors) over(Treatments) ///
    blabel(bar, format(%2.2f)) ///
    bar(1, color(navy)) bar(2, color(maroon)) bar(3, color(forest_green)) bar(4, color(orange)) ///
    legend(order(1 "Only1" 2 "Only2" 3 "None" 4 "Donors")) ///
    ylabel(1(0.5)5) ///
    ytitle("Mean Avoidance Score") ///
    title("Mean Avoidance by Donor Type and Treatment")

ta Donors
ta Donors, nolabel

gen temp_donor_avoid = .
replace temp_donor_avoid = . if Donors == 0
replace temp_donor_avoid = 10 if Donors == 1
replace temp_donor_avoid = 10 if Donors == 2
replace temp_donor_avoid = 11 if Donors == 3
replace temp_donor_avoid = 12 if Donors == 4

ta temp_donor_avoid if Treatments < 13 & nvals == 1

ta Donors temp_donor_avoid

scatter temp_donor_avoid  avoid 
ta  avoid temp_donor_avoid if Treatments < 13 & nvals == 1

separate avoid, by(temp_donor_avoid)
twoway ///
(histogram avoid10 , color(blue%40)) ///
(histogram avoid11 , color(red%40) ) ///
(histogram avoid12 , color(black) )

bys temp_donor_avoid: su avoid if Treatments < 13 & nvals == 1

summarize avoid10 if Treatments < 13 & nvals == 1, d

local m10 = r(mean)
local sd10 = r(p50)

summarize avoid11 if Treatments < 13 & nvals == 1, d

local m11 = r(mean)
local sd11 = r(p50)

summarize avoid12 if Treatments < 13 & nvals == 1, d

local m12 = r(mean)
local sd12 = r(p50)

display "`m10'" "`sd10'" "`m11'" "`sd11'" "`m12'" "`sd12'"

twoway ///
(histogram avoid10 if Treatments < 13 & nvals == 1, color(blue%40) width(1) percent ///
    legend(label(1 "Only1 Only2"))) ///
(kdensity avoid10 if Treatments < 13 & nvals == 1, lcolor(blue) lpattern(solid) legend(off)) ///
(histogram avoid11 if Treatments < 13 & nvals == 1, color(red%40) width(1) percent ///
    legend(label(2 "Neither round"))) ///
(kdensity avoid11 if Treatments < 13 & nvals == 1, lcolor(red) lpattern(solid) legend(off)) ///
(histogram avoid12 if Treatments < 13 & nvals == 1, color(black%40) width(1) percent ///
    legend(label(3 "Both Rounds"))) ///
(kdensity avoid12 if Treatments < 13 & nvals == 1, lcolor(black) lpattern(solid) legend(off)), ///
xline(`m10', lc(blue%40) lpattern(shortdash_dot)) ///
xline(`sd10', lc(blue%40) lpattern(shortdash_dot)) ///
xline(`m11', lc(red%40)) ///
xline(`sd11', lc(red%40)) ///
xline(`m12', lc(black)) ///
xline(`sd12', lc(black)) ///
legend(on order(1 2 3) ring(0) position(1) rows(1)) ///
xtitle("Decision Avoidance Score") ///
ytitle("Percent") ///
ylabel(0(10)50, grid) ///
title("Distribution of Avoidance Scores by Donors' Behaviour")


hist avoid10, lcolor(blue) 
kdensity avoid10, lcolor(blue) bwidth(0.3)

graph bar (count), over(temp_donor_avoid, gap(0)) over(avoid) asyvars stack, if Treatments < 13 & nvals == 1

tabulate avoid temp_donor_avoid, chi2, if Treatments < 13 & nvals == 1

ktau avoid temp_donor_avoid  // Kendall's tau

pwcorr temp_donor_avoid  avoid if Treatments < 13 & nvals == 1 & TreatmentChoice == 1, sig
pwcorr temp_donor_avoid  avoid if Treatments < 13 & nvals == 1 & TreatmentChoice == 2, sig
pwcorr temp_donor_avoid  avoid if Treatments < 13 & nvals == 1 & TreatmentChoice == 3, sig

reg avoid temp_donor_avoid if Treatments < 13 & nvals == 1
reg avoid temp_donor_avoid temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset temp_donation, cluster(id)


*** 5 Decision Avoidance

label variable avoid "Decision Avoidance"
sum avoid if TreatmentChoice == 1 
sum avoid if TreatmentChoice != 2 

gen temp_interacth = temp_hchoice_subset_r1*avoid
gen temp_interactm = temp_mchoice_subset*avoid
gen temp_interacthm = temp_hmchoice_subset*avoid
label variable temp_interacth "Options*Avoidance"
label variable temp_interactm "Choice*Avoidance"
label variable temp_interacthm "Choice*Options*Avoidance"


eststo clear

eststo: reg avoid temp_hchoice_subset_r1, cluster(id), if TreatmentChoice == 1 

eststo: reg avoid temp_hchoice_subset_r1 temp_donation,  cluster(id), if TreatmentChoice == 1 

eststo: reg avoid temp_mchoice_subset, cluster(id), if TreatmentChoice !=2 

eststo: reg avoid temp_mchoice_subset temp_donation, cluster(id), if TreatmentChoice !=2 

eststo: reg avoid temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset , cluster(id)

eststo: reg avoid temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset temp_donation, cluster(id)

esttab using "$drive\tabs\Table6avoid.tex", star(* 0.10 ** 0.05 *** 0.01) se keep(temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset temp_donation) nomtitles mgroups("Decision Avoidance ", pattern(1 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions using a dependent variable measuring the regret experimental participants reported after donating to charity. The Options variable measures whether they could see 40 charities versus 5 and the Choices variable measures whether they could choose only one charity versus multiple charities. Columns (2) and (4) include the tokens donated by participants as a mediator variable." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of the Effect of Treatments On Decision Avoidance \label{Table6newfamiliarityD1_temp})
	  

eststo clear

eststo: reg temp_donation avoid temp_hchoice_subset_r1 temp_donor_avoid, cluster(id), if TreatmentChoice == 1 

eststo: reg temp_donation avoid temp_hchoice_subset_r1 temp_donor_avoid,  cluster(id), if TreatmentChoice == 1 

eststo: reg temp_donation avoid temp_mchoice_subset temp_donor_avoid, cluster(id), if TreatmentChoice !=2 

eststo: reg temp_donation avoid temp_mchoice_subset temp_donor_avoid , cluster(id), if TreatmentChoice !=2 

eststo: reg temp_donation avoid temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset temp_donor_avoid , cluster(id)

eststo: reg temp_donation avoid temp_hchoice_subset_r1 temp_mchoice_subset temp_hmchoice_subset temp_donor_avoid, cluster(id)


*******************************************************
*** # 5 Other vars: H/L Default
*******************************************************


ta temp_dchoice_subset Treatments

ta temp_dchoice_subset temp_hchoice_subset_r1

gen temp_fam_option = familiarityD1_temp * temp_hchoice_subset_r1
gen temp_del_option = deliberationD1_temp * temp_hchoice_subset_r1
gen temp_diff_option = diffic * temp_hchoice_subset_r1

gen temp_fam_def = familiarityD1_temp * temp_dchoice_subset
gen temp_del_def = deliberationD1_temp * temp_dchoice_subset
gen temp_diff_def = diffic * temp_dchoice_subset

gen temp_fam_option_def = familiarityD1_temp * temp_hchoice_subset_r1 * temp_dchoice_subset
gen temp_del_option_def = deliberationD1_temp * temp_hchoice_subset_r1 * temp_dchoice_subset
gen temp_diff_option_def = diffic * temp_hchoice_subset_r1 * temp_dchoice_subset

label variable temp_hchoice_subset_r1 "Options"  

label variable temp_dchoice_subset "Default"  

label variable temp_hdchoice_subset "Default $times$ Options"  


label variable temp_fam_option "Familiarity $times$ Options"  

label variable temp_del_option "Deliberation $times$ Options"  

label variable temp_diff_option "Difficulty $times$ Options"  

label variable temp_fam_def "Familiarity $times$ Default"  

label variable temp_del_def "Deliberation $times$ Default"  

label variable temp_diff_def "Difficulty $times$ Default"  

label variable temp_fam_option_def "Familiarity $times$ Default $times$ Options"   

label variable temp_del_option_def "Deliberation $times$ Default $times$ Options"   

label variable temp_diff_option_def "Difficulty $times$ Default $times$ Options"   


** diffic
eststo clear

eststo: reg temp_donation temp_hchoice_subset_r1 temp_dchoice_subset temp_hdchoice_subset diffic ///
			, cluster(id), if TreatmentChoice != 3
			
eststo: reg temp_donation temp_hchoice_subset_r1 temp_dchoice_subset temp_hdchoice_subset diffic ///
			temp_diff_option temp_diff_def temp_diff_option_def /// 
			, cluster(id), if TreatmentChoice != 3

eststo: reg temp_donation temp_hchoice_subset_r1 temp_dchoice_subset temp_hdchoice_subset ///
			deliberationD1_temp ///	
			, cluster(id), if TreatmentChoice != 3
			
eststo: reg temp_donation temp_hchoice_subset_r1 temp_dchoice_subset temp_hdchoice_subset ///
			deliberationD1_temp ///
			temp_del_option  temp_del_def temp_del_option_def ///			
			, cluster(id), if TreatmentChoice != 3

eststo: reg temp_donation temp_hchoice_subset_r1 temp_dchoice_subset temp_hdchoice_subset ///
			temp_fam_option temp_fam_def temp_fam_option_def ///
			familiarityD1_temp, cluster(id), if TreatmentChoice != 3
			
eststo: reg temp_donation temp_hchoice_subset_r1 temp_dchoice_subset temp_hdchoice_subset ///
			diffic ///
			temp_diff_option temp_diff_def temp_diff_option_def /// 
			deliberationD1_temp ///
			temp_del_option  temp_del_def temp_del_option_def ///
			familiarityD1_temp ///
			temp_fam_option temp_fam_def temp_fam_option_def ///
			, cluster(id), if TreatmentChoice != 3			


esttab using "$drive\tabs\Table8newInteractions.tex", star(* 0.10 ** 0.05 *** 0.01) se keep(temp_hchoice_subset_r1 temp_dchoice_subset temp_hdchoice_subset diffic temp_diff_option temp_diff_def temp_diff_option_def temp_del_option  temp_del_def temp_del_option_def familiarityD1_temp temp_fam_option temp_fam_def temp_fam_option_def ) nomtitles mgroups("Donations (Tokens)", pattern(1 0 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the donations to charity in our experiment on the Options treatment, which measures whether participants could see 40 charities versus 5. The regressions add three potential mediators: how difficult participants reported finding the choices, how long they deliberated over them, and how familiar they were with the listed charities." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of Options Treatment on Donations \label{Table8newInteractions})

pwcorr diffic deliberationD1_temp familiarityD1_temp, sig, if TreatmentChoice != 3


eststo clear

eststo: reg temp_donation temp_hchoice_subset_r1 temp_dchoice_subset temp_hdchoice_subset diffic ///
			, cluster(id), if TreatmentChoice != 3
			
eststo: reg temp_donation temp_hchoice_subset_r1 temp_dchoice_subset temp_hdchoice_subset ///
			deliberationD1_temp ///	
			, cluster(id), if TreatmentChoice != 3
			
eststo: reg temp_donation temp_hchoice_subset_r1 temp_dchoice_subset temp_hdchoice_subset ///
			 familiarityD1_temp ///
			, cluster(id), if TreatmentChoice != 3
			
eststo: reg temp_donation temp_hchoice_subset_r1 temp_dchoice_subset temp_hdchoice_subset ///
			diffic deliberationD1_temp familiarityD1_temp ///
			, cluster(id), if TreatmentChoice != 3

			
eststo: reg temp_donation temp_hchoice_subset_r1 temp_dchoice_subset temp_hdchoice_subset ///
			difficulty1_temp difficulty2_temp difficulty3_temp difficulty4_temp ///
			, cluster(id), if TreatmentChoice != 3


			
esttab using "$drive\tabs\Table8newInteractions.tex", star(* 0.10 ** 0.05 *** 0.01) se keep( temp_hchoice_subset_r1 temp_dchoice_subset temp_hdchoice_subset diffic deliberationD1_temp familiarityD1_temp diffic difficulty1_temp difficulty2_temp difficulty3_temp difficulty4_temp) nomtitles mgroups("Donations (Tokens)", pattern(1 0 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the donations to charity in our experiment on the Options treatment, which measures whether participants could see 40 charities versus 5. The regressions add three potential mediators: how difficult participants reported finding the choices, how long they deliberated over them, and how familiar they were with the listed charities." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of Options Treatment on Donations \label{Table8newInteractions})

		  
**-----	  
eststo clear

eststo: reg donation dchoice, cluster(id)

eststo: reg donation dchoice diffic, cluster(id)

eststo: reg donation dchoice deliberationD1_temp, cluster(id)

eststo: reg donation dchoice familiarityD1_temp, cluster(id)

eststo: reg donation dchoice diffic deliberationD1_temp familiarityD1_temp, cluster(id)

eststo: reg donation dchoice difficulty1_temp difficulty2_temp difficulty3_temp difficulty4_temp deliberationD1_temp familiarityD1_temp, cluster(id)


esttab using "$drive\tabs\Table9.tex", se keep(dchoice diffic deliberationD1_temp familiarityD1_temp) nomtitles mgroups("Donations (Tokens)", pattern(1 0 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the donations to charity in our experiment on the Default treatment, which measures whether participants had a pre-selected default donation option available. The regressions add three potential mediators: how difficult participants reported finding the choices, how long they deliberated over them, and how familiar they were with the listed charities." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of Default Treatment on Donations \label{Table9})

**# Bookmark #2 Warm Glow
*******************************************************
* Warm Glow
*******************************************************

alpha satisfactionD1_temp satisfactionD2_temp satisfactionD3_temp satisfactionD4_temp satisfactionD5_temp  satisfactionD6_temp, std item, if TreatmentChoice != 2

su temp_donation // this is over two rounds 

*drop temp_donation 
*gen temp_donation = donation // this is in round 1 only

gen temp_amount_mchoice = temp_donation* temp_mchoice_subset
gen temp_amount_hchoice = temp_donation* temp_hchoice_subset_r1
gen temp_amount_mhchoice = temp_donation* temp_hchoice_subset_r1*temp_mchoice_subset

ta temp_amount_mchoice
ta temp_amount_hchoice
ta temp_amount_mhchoice

eststo clear

eststo: reg satisD ///
    temp_hchoice_subset_r1 ///
    temp_donation ///
    temp_mchoice_subset ///
    if TreatmentChoice != 2 & round == 1, cluster(id)
estadd local hascon "No"

eststo: reg satisD ///
    temp_hchoice_subset_r1 ///
    temp_donation ///
    temp_mchoice_subset ///
    temp_amount_mchoice ///
    temp_amount_hchoice ///
    temp_amount_mhchoice ///
    if TreatmentChoice != 2 & round == 1, cluster(id)
estadd local hascon "No"


eststo: reg satisD ///
    temp_hchoice_subset_r1 ///
    temp_donation ///
    temp_mchoice_subset ///
    temp_amount_mchoice ///
    temp_amount_hchoice ///
    temp_amount_mhchoice ///
    ib1.education ///
    ib14.ethnicity ///
    ib5.marital ///
    ib7.employment ///
    ib6.religion ///
    ib2.income ///
    age ///
    ib2.male ///
    if TreatmentChoice != 2 & round == 1, cluster(id)
estadd local hascon "Yes"

esttab using "$drive\tabs\warmglow.tex", star(* 0.10 ** 0.05 *** 0.01 **** 0.001) se keep( temp_hchoice_subset_r1 temp_donation temp_mchoice_subset temp_amount_mchoice temp_amount_hchoice temp_amount_mhchoice) scalars("hascon Controls")  nomtitles mgroups("Choice Satisfaction", pattern(1 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("ADD") ///
 alignment(c) label replace ///
 b(4) se(4) ///
      title (Mediation of the Effect of Treatments On Satisfaction Round 1 donation  \label{warmglow})  


** using regret
eststo clear

eststo: reg regrD ///
    temp_hchoice_subset_r1 ///
    temp_donation ///
    temp_mchoice_subset ///
    if TreatmentChoice != 2 & round == 1, cluster(id)
estadd local hascon "No"

eststo: reg regrD ///
    temp_hchoice_subset_r1 ///
    temp_donation ///
    temp_mchoice_subset ///
    temp_amount_mchoice ///
    temp_amount_hchoice ///
    temp_amount_mhchoice ///
    if TreatmentChoice != 2 & round == 1, cluster(id)
estadd local hascon "No"


eststo: reg regrD ///
    temp_hchoice_subset_r1 ///
    temp_donation ///
    temp_mchoice_subset ///
    temp_amount_mchoice ///
    temp_amount_hchoice ///
    temp_amount_mhchoice ///
    ib1.education ///
    ib14.ethnicity ///
    ib5.marital ///
    ib7.employment ///
    ib6.religion ///
    ib2.income ///
    age ///
    ib2.male ///
    if TreatmentChoice != 2 & round == 1, cluster(id)
estadd local hascon "Yes"

esttab using "$drive\tabs\warmglow2.tex", star(* 0.10 ** 0.05 *** 0.01 **** 0.001) se keep( temp_hchoice_subset_r1 temp_donation temp_mchoice_subset temp_amount_mchoice temp_amount_hchoice temp_amount_mhchoice) scalars("hascon Controls")  nomtitles mgroups("Choice Satisfaction", pattern(1 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("ADD") ///
 alignment(c) label replace ///
 b(4) se(3) ///
      title (Mediation of the Effect of Treatments On regrD donation  \label{warmglow2})  
	  
*** 
** 
**--------------------
** Warm glow, different dependent var
**--------------------

gen temp_donated = . 
replace temp_donated = 1 if temp_donation > 1 
replace temp_donated = 0 if temp_donation < 2 

gen temp_donated_mchoice = temp_donated* temp_mchoice_subset
gen temp_donated_hchoice = temp_donated* temp_hchoice_subset_r1
gen temp_donated_mhchoice = temp_donated* temp_hchoice_subset_r1*temp_mchoice_subset


eststo clear

eststo: reg satisD ///
    temp_hchoice_subset_r1 ///
    temp_donated ///
    temp_mchoice_subset ///
    if TreatmentChoice != 2 & round == 1, cluster(id)
estadd local hascon "No"

eststo: reg satisD ///
    temp_hchoice_subset_r1 ///
    temp_donated ///
    temp_mchoice_subset ///
    temp_donated_mchoice ///
    temp_donated_hchoice ///
    temp_donated_mhchoice ///
    if TreatmentChoice != 2 & round == 1, cluster(id)
estadd local hascon "No"


eststo: reg satisD ///
    temp_hchoice_subset_r1 ///
    temp_donated ///
    temp_mchoice_subset ///
    temp_donated_mchoice ///
    temp_donated_hchoice ///
    temp_donated_mhchoice ///
    ib1.education ///
    ib14.ethnicity ///
    ib5.marital ///
    ib7.employment ///
    ib6.religion ///
    ib2.income ///
    age ///
    ib2.male ///
    if TreatmentChoice != 2 & round == 1, cluster(id)
estadd local hascon "Yes"

esttab using "$drive\tabs\warmglow3.tex", star(* 0.10 ** 0.05 *** 0.01 **** 0.001) se keep( temp_hchoice_subset_r1 temp_donated temp_mchoice_subset temp_donated_mchoice temp_donated_hchoice temp_donated_mhchoice) scalars("hascon Controls")  nomtitles mgroups("Choice Satisfaction", pattern(1 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("ADD") ///
 alignment(c) label replace ///
 b(4) se(3) ///
      title (Mediation of the Effect of Treatments On satisD donation  \label{warmglow3})  
	  

su temp_donation // this is over two rounds 

gen temp_amount_mchoice2 = temp_donation* mchoice
gen temp_amount_hchoice2 = temp_donation* hchoice
gen temp_amount_mhchoice2 = temp_donation* mchoice*hchoice


eststo clear

eststo: reg satisD ///
    hchoice ///
    temp_donation ///
    mchoice ///
    if TreatmentChoice != 2 & round == 1, cluster(id)
estadd local hascon "No"

eststo: reg satisD ///
    hchoice ///
    temp_donation ///
    mchoice ///
    temp_amount_mchoice2 ///
    temp_amount_hchoice2 ///
    temp_amount_mhchoice2 ///
    if TreatmentChoice != 2 & round == 1, cluster(id)
estadd local hascon "No"


eststo: reg satisD ///
    hchoice ///
    temp_donation ///
    mchoice ///
    temp_amount_mchoice2 ///
    temp_amount_hchoice2 ///
    temp_amount_mhchoice2 ///
    ib1.education ///
    ib14.ethnicity ///
    ib5.marital ///
    ib7.employment ///
    ib6.religion ///
    ib2.income ///
    age ///
    ib2.male ///
    if TreatmentChoice != 2 & round == 1, cluster(id)
estadd local hascon "Yes"

esttab using "$drive\tabs\warmglow4.tex", star(* 0.10 ** 0.05 *** 0.01 **** 0.001) se keep(hchoice temp_donation mchoice temp_amount_mchoice2 temp_amount_hchoice2 temp_amount_mhchoice2) scalars("hascon Controls")  nomtitles mgroups("Choice Satisfaction", pattern(1 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("ADD") ///
 alignment(c) label replace ///
 b(4) se(3) ///
      title (Mediation of the Effect of Treatments On regrD donation  \label{warmglow4})  

*******************************************************
* Robustness: extensive margin
*******************************************************
** Adding leavers to the analysis

ta otree_option Donors
ta TreatmentsOandC Treatments, m

gen temp_TreatmentsOandC_leavers = otree_option + otree_choice
ta temp_TreatmentsOandC_leavers
ta temp_TreatmentsOandC_leavers, nolabel

gen temp_treatments_leavers	=.						
replace temp_treatments_leavers = 	1	if	temp_TreatmentsOandC_leavers	==	"O1C1"
replace temp_treatments_leavers = 	4	if	temp_TreatmentsOandC_leavers	==	"O2C1"		
replace temp_treatments_leavers = 	7	if	temp_TreatmentsOandC_leavers	==	"O3C1"		
replace temp_treatments_leavers = 	10	if	temp_TreatmentsOandC_leavers	==	"O4C1"		
							
replace temp_treatments_leavers = 	2	if	temp_TreatmentsOandC_leavers	==	"O1C2"		
replace temp_treatments_leavers = 	5	if	temp_TreatmentsOandC_leavers	==	"O2C2"		
replace temp_treatments_leavers = 	8	if	temp_TreatmentsOandC_leavers	==	"O3C2"		
replace temp_treatments_leavers = 	11	if	temp_TreatmentsOandC_leavers	==	"O4C2"		
							
replace temp_treatments_leavers = 	3	if	temp_TreatmentsOandC_leavers	==	"O1C3"		
replace temp_treatments_leavers = 	6	if	temp_TreatmentsOandC_leavers	==	"O2C3"		
replace temp_treatments_leavers = 	9	if	temp_TreatmentsOandC_leavers	==	"O3C3"
replace temp_treatments_leavers = 	12	if	temp_TreatmentsOandC_leavers	==	"O4C3"		
							
replace temp_treatments_leavers = 	13	if	otree_signal	==	"S1"		
replace temp_treatments_leavers = 	14	if	otree_signal	==	"S2"		
replace temp_treatments_leavers = 	15	if	otree_signal	==	"S3"		
replace temp_treatments_leavers = 	16	if	otree_signal	==	"S4"		

replace Treatments = temp_treatments_leavers if Treatments == .

ta TreatmentOption
ta TreatmentOption, nolabel
**
replace	TreatmentOption	=	1	if	temp_TreatmentsOandC_leavers	==	"O1C1"
replace	TreatmentOption	=	1	if	temp_TreatmentsOandC_leavers	==	"O1C2"
replace	TreatmentOption	=	1	if	temp_TreatmentsOandC_leavers	==	"O1C3"
							
replace	TreatmentOption	=	2	if	temp_TreatmentsOandC_leavers	==	"O2C1"
replace	TreatmentOption	=	2	if	temp_TreatmentsOandC_leavers	==	"O2C2"
replace	TreatmentOption	=	2	if	temp_TreatmentsOandC_leavers	==	"O2C3"
							
replace	TreatmentOption	=	3	if	temp_TreatmentsOandC_leavers	==	"O3C1"
replace	TreatmentOption	=	3	if	temp_TreatmentsOandC_leavers	==	"O3C2"
replace	TreatmentOption	=	3	if	temp_TreatmentsOandC_leavers	==	"O3C3"
							
replace	TreatmentOption	=	4	if	temp_TreatmentsOandC_leavers	==	"O4C1"
replace	TreatmentOption	=	4	if	temp_TreatmentsOandC_leavers	==	"O4C2"
replace	TreatmentOption	=	4	if	temp_TreatmentsOandC_leavers	==	"O4C3"
	
ta TreatmentChoice
ta TreatmentChoice, nolabel

replace	TreatmentChoice	=	1	if	temp_TreatmentsOandC_leavers	==	"O1C1"
replace	TreatmentChoice	=	1	if	temp_TreatmentsOandC_leavers	==	"O2C1"
replace	TreatmentChoice	=	1	if	temp_TreatmentsOandC_leavers	==	"O3C1"
replace	TreatmentChoice	=   1	if	temp_TreatmentsOandC_leavers	==	"O4C1"
							
replace	TreatmentChoice	=	2	if	temp_TreatmentsOandC_leavers	==	"O1C2"
replace	TreatmentChoice	=	2	if	temp_TreatmentsOandC_leavers	==	"O2C2"
replace	TreatmentChoice	=	2	if	temp_TreatmentsOandC_leavers	==	"O3C2"
replace	TreatmentChoice	=	2	if	temp_TreatmentsOandC_leavers	==	"O4C2"
							
replace	TreatmentChoice	=	3	if	temp_TreatmentsOandC_leavers	==	"O1C3"
replace	TreatmentChoice	=	3	if	temp_TreatmentsOandC_leavers	==	"O2C3"
replace	TreatmentChoice	=	3	if	temp_TreatmentsOandC_leavers	==	"O3C3"
replace	TreatmentChoice	=	3	if	temp_TreatmentsOandC_leavers	==	"O4C3"

ta  Treatments Donors, m

drop temp* 


** filling the gap for leavers
gen temp_total_donation = total_donation *80
label variable donation "Donation Amount (Tokens)"

gen temp_hchoice = .
replace temp_hchoice = 1 if Treatments<=3 & round==2
replace temp_hchoice = 1 if Treatments<=6 & Treatments>3 & round==1
replace temp_hchoice = 1 if Treatments<=12 & Treatments>9 
replace temp_hchoice = 0 if Treatments<=3 & round==1
replace temp_hchoice = 0 if Treatments<=6 & Treatments>3 & round==2
replace temp_hchoice = 0 if Treatments<=9 & Treatments>6 
replace temp_hchoice = 1 if Treatments==13
replace temp_hchoice = 0 if Treatments==14
replace temp_hchoice = 0 if Category==1 & Treatments==15
replace temp_hchoice = 1 if Category>1 & Category!=. & Treatments==15
replace temp_hchoice = 0 if Category>1 & Category!=. & Treatments==16
replace temp_hchoice = 0 if Category==1 & Treatments==16

label variable temp_hchoice "Options"

gen temp_mchoice = .
replace temp_mchoice = 0 if Treatments==1 | Treatments == 4 | Treatments == 7 | Treatments == 10 
replace temp_mchoice = 1 if Treatments==3 | Treatments == 6 |  Treatments == 9 | Treatments == 12 

label variable temp_mchoice "Choice"

gen temp_dchoice = .
replace temp_dchoice = 0 if Treatments==1 | Treatments == 4 | Treatments == 7 | Treatments == 10 
replace temp_dchoice = 1 if Treatments==2 | Treatments == 5 |  Treatments == 8 | Treatments == 11 

label variable temp_dchoice "Deafult"


ta Donors, nolabel
ta Donors

gen temp_round = round - 1

label variable temp_round "Round"


gen temp_hmchoice = temp_hchoice*temp_mchoice

label variable temp_hmchoice "mchoice*hchoice"

gen temp_hdchoice = temp_hchoice*temp_dchoice
label variable temp_hdchoice "hchoice*dchoice"


bysort Donors: su temp_total_donation
order Treatments total_donation otree_* TreatmentChoice TreatmentOption donation temp_hchoice temp_round Donors


*******************************************************
** H1 and H2
eststo clear

eststo: reg temp_total_donation temp_hchoice, cluster(id), if TreatmentChoice==1 & round == 1
estadd local hascon = "No"

eststo: reg temp_total_donation temp_hchoice  ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2   & round == 1
estadd local hascon = "Yes"

eststo: reg temp_total_donation temp_mchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 & round == 1
estadd local hascon = "No"

eststo: reg temp_total_donation temp_hchoice temp_mchoice temp_hmchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 & round == 1
estadd local hascon = "No"

eststo: reg temp_total_donation temp_hchoice temp_mchoice temp_hmchoice ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  & round == 1
estadd local hascon = "Yes"

esttab using "$drive\tabs\Table1RobustRound1.tex", se keep(temp_hchoice temp_mchoice temp_hmchoice ) scalars("hascon Controls") nomtitles mgroups("Hypothesis 1" "Hypothesis 2", pattern(1 0 0 1 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("ADD") ///
 alignment(c) label replace ///
     b(3) se(3) ///
      title (Effect of Treatments on Donations Robustness in round 1\label{Table1RobustRound1})	
	  
*H3	  
	  
eststo clear

eststo: reg temp_total_donation temp_dchoice, cluster(id), if round == 1
estadd local hascon = "No"	

eststo: reg temp_total_donation temp_dchoice ///
			ib1.education ib14.ethnicity ib5.marital ///
			ib7.employment ib6.religion ib2.income age ib2.male ///
			, cluster(id), if round == 1
estadd local hascon = "Yes"	

eststo: reg temp_total_donation temp_dchoice temp_hchoice temp_hdchoice, cluster(id), if round == 1
estadd local hascon = "No"	

eststo: reg temp_total_donation temp_dchoice temp_hchoice temp_hdchoice ///
			ib1.education ib14.ethnicity ib5.marital ///
			ib7.employment ib6.religion ib2.income age ib2.male ///
			, cluster(id), if round == 1
estadd local hascon = "Yes"	

esttab using "$drive\tabs\Table2RobustRound1D.tex", se keep(temp_hchoice temp_dchoice temp_hdchoice) scalars("hascon Controls") nomtitles mgroups("Hypothesis 3", pattern(1 0 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote(" ADD ") ///
 alignment(c) label replace ///
      b(3) se(3) ///
      title (Effect of Default Treatment on Donations Robustness in round 1 default \label{Table2RobustRound1D})
	  

	  


**--------------------
*Mechanisms
**--------------------

gen donated = .
replace donated = 0 if donation==0
replace donated = 1 if donation>0 & donation!=.


	  
** Avoid 
ta avoid
hist avoid
	  
 
*Effect of Treatments on Mediators
	  
eststo clear

eststo: reg diffic hchoice, cluster(id)

eststo: reg diffic mchoice, cluster(id)

eststo: reg diffic dchoice, cluster(id)

eststo: reg deliberationD1_temp hchoice, cluster(id)

eststo: reg deliberationD1_temp mchoice, cluster(id)

eststo: reg deliberationD1_temp dchoice, cluster(id)

eststo: reg familiarityD1_temp hchoice, cluster(id)

eststo: reg familiarityD1_temp mchoice, cluster(id)

eststo: reg familiarityD1_temp dchoice, cluster(id)

esttab using "$drive\tabs\Table10.tex", se keep(hchoice mchoice dchoice) nomtitles mgroups("Choice Difficulty" "Choice Deliberation" "Choice Familiarity", pattern(1 0 0 1 0 0 1 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("Nine OLS regressions of three subjective variables on three treatments. The subjective variables are: how difficult participants reported finding the choices; how long they deliberated over them; and how familiar they were with the listed charities. The treatments are: the options treatment, which measures whether participants had 40 versus 5 charities to choose from; the choices treatment, which measures whether participants could donate to multiple versus just one charity; and the default treatment, which measures whether they could use a pre-selected default donation option instead of choosing manually." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Effect of Treatment on Subjective Variables \label{Table10})	  
	  


	  
*Charitable Giving

*How much donated
encode charitablegiving, gen(charitablegiving_temp)
recode charitablegiving_temp (1=150) (2=350) (3=.) (4=62.5) (5=1000) (6=87.5), gen(give)
label variable give "Money Donated"

    replace charitablegiving_temp = 1 if charitablegiving == "£50-£75"
	replace charitablegiving_temp = 2 if charitablegiving == "£75-£100"
	replace charitablegiving_temp = 3 if charitablegiving == "£101-£200"
    replace charitablegiving_temp = 4 if charitablegiving == "£201-£500"    
    replace charitablegiving_temp = 5 if charitablegiving == "£501+"
      replace charitablegiving_temp = . if charitablegiving == "£201-£500, £101-£200"
   
    
    label define charitablegiving_temp_lbl  5 "£501+" ///
                                     4 "£201-£500" ///
                                     3 "£101-£200" ///
                                     2 "£75-£100" ///
                                     1 "£50-£75"
									 
    label values charitablegiving_temp charitablegiving_temp_lbl
    


encode PreferenceGiving, gen(PreferenceGiving_temp)
gen vol = (PreferenceGiving_temp==3)
gen mon = (PreferenceGiving_temp==2)
label variable vol "Prefers Volunteering"
label variable mon "Prefers Donating"

*Personality varibles moderators
gen hchoiceSRA = SRA*hchoice
gen hchoiceavoid = avoid*hchoice
gen hchoicemax = max*hchoice
gen hchoicegive = give*hchoice
gen hchoicevol = vol*hchoice
gen hchoicemon = mon*hchoice
label variable hchoiceSRA "Options * Altruism"
label variable hchoiceavoid "Options * Avoidance"
label variable hchoicemax "Options * Maximiser"
label variable hchoicegive "Options * Money Donated"
label variable hchoicevol "Options * Prefers Volunteering"
label variable hchoicemon "Options * Prefers Donating"

gen mchoiceSRA = SRA*mchoice
gen mchoiceavoid = avoid*mchoice
gen mchoicemax = max*mchoice
gen mchoicegive = give*mchoice
gen mchoicevol = vol*mchoice
gen mchoicemon = mon*mchoice
label variable mchoiceSRA "Choices * Altruism"
label variable mchoiceavoid "Choices * Avoidance"
label variable mchoicemax "Choices * Maximiser"
label variable mchoicegive "Choices * Money Donated"
label variable mchoicevol "Choices * Prefers Volunteering"
label variable mchoicemon "Choices * Prefers Donating"

gen dchoiceSRA = SRA*dchoice
gen dchoiceavoid = avoid*dchoice
gen dchoicemax = max*dchoice
gen dchoicegive = give*dchoice
gen dchoicevol = vol*dchoice
gen dchoicemon = mon*dchoice
label variable dchoiceSRA "Default * Altruism"
label variable dchoiceavoid "Default * Avoidance"
label variable dchoicemax "Default * Maximiser"
label variable dchoicegive "Default * Money Donated"
label variable dchoicevol "Default * Prefers Volunteering"
label variable dchoicemon "Default * Prefers Donating"

gen revealSRA = SRA*reveal
gen revealavoid = avoid*reveal
gen revealmax = max*reveal
gen revealgive = give*reveal
gen revealvol = vol*reveal
gen revealmon = mon*reveal
label variable revealSRA "Reveal * Altruism"
label variable revealavoid "Reveal * Avoidance"
label variable revealmax "Reveal * Maximiser"
label variable revealgive "Reveal * Money Donated"
label variable revealvol "Reveal * Prefers Volunteering"
label variable revealmon "Reveal * Prefers Donating"

label variable avoid "Avoidance"
label variable max "Maximiser"
label variable SRA "Altruism (SRA)"


foreach var in hchoice mchoice {
	
	eststo clear
	
	eststo: reg donation `var', cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

foreach x in SRA avoid max give {

eststo: reg donation `x' `var' `var'`x', cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

}


eststo: reg donation `var' vol mon `var'vol `var'mon, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

esttab using "$drive\tabs\Table`var'.tex", se  star(* 0.10 ** 0.05 *** 0.01) keep(`var' SRA avoid max give vol mon `var'SRA `var'avoid `var'max `var'give `var'vol `var'mon) nomtitles mgroups("Donations (Tokens)", pattern(1 0 0 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the amount experimental participants donated to on the treatment variable using six moderator variables: altruism; avoidant decision-making; maximising versus satisficing behaviour; and prior involvement in charitable giving, both volunteering and donations." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Effect of `var' Treatment on Donations Using Selected Moderators \label{Table`var'})

	  }	 
	  
 
*H Choice with fixed effects 
	
eststo clear
	
eststo: xtreg donation hchoice, cluster(id) i(id) fe, if TreatmentSignal==0 & TreatmentChoice!=2

foreach x in SRA avoid max give {

eststo: xtreg donation `x' hchoice hchoice`x', cluster(id) i(id) fe, if TreatmentSignal==0 & TreatmentChoice!=2

}


eststo: xtreg donation hchoice vol mon hchoicevol hchoicemon, cluster(id) i(id) fe, if TreatmentSignal==0 & TreatmentChoice!=2


 
esttab using "$drive\tabs\TablehchoiceFE.tex", se keep(hchoice SRA avoid max give vol mon hchoiceSRA hchoiceavoid hchoicemax hchoicegive hchoicevol hchoicemon) nomtitles mgroups("Donations (Tokens)", pattern(1 0 0 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the amount experimental participants donated to on the treatment variable using six moderator variables: altruism; avoidant decision-making; maximising versus satisficing behaviour; and prior involvement in charitable giving, both volunteering and donations." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Effect of `var' on Donations Using Selected Moderators \label{TablehchoiceFE})

	  *Moderators Together
	  
eststo clear

eststo: reg donation hchoice SRA hchoiceSRA avoid hchoiceavoid max hchoicemax give hchoicegive vol hchoicevol mon hchoicemon, cluster(id)

eststo: xtreg donation hchoice SRA hchoiceSRA avoid hchoiceavoid max hchoicemax give hchoicegive vol hchoicevol mon hchoicemon, cluster(id) i(id) fe

eststo: reg donation mchoice SRA mchoiceSRA avoid mchoiceavoid max mchoicemax give mchoicegive vol mchoicevol mon mchoicemon, cluster(id)

eststo: reg donation dchoice SRA dchoiceSRA avoid dchoiceavoid max dchoicemax give dchoicegive vol dchoicevol mon dchoicemon, cluster(id)

*eststo: reg donation schoice SRA schoiceSRA avoid schoiceavoid max schoicemax give schoicegive vol schoicevol mon schoicemon, cluster(id)

esttab using "$drive\tabs\Tablemods.tex", se keep(hchoice SRA hchoiceSRA avoid hchoiceavoid max hchoicemax give hchoicegive vol hchoicevol hchoicemon mchoice mchoiceSRA mchoiceavoid mchoicemax mchoicegive mchoicevol mchoicemon dchoice dchoiceSRA dchoiceavoid dchoicemax dchoicegive dchoicevol dchoicemon) nomtitles mgroups("Donations (Tokens)", pattern(1 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the amount experimental participants donated to on the four treatment variables: the options treatment; the choices treatment; the default treatment; the signal treatment. Each regressions also includes six moderator variables and their interactions with the treatments: altruism; avoidant decision-making; maximising versus satisficing behaviour; and prior involvement in charitable giving, both volunteering and donations." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Effect of Treatments on Donations Using Selected Moderators \label{Tablemods})


*Demographic variables

gen marr = .
replace marr = 1 if marital==4
replace marr = 0 if marital==5
label variable marr "Married"

gen degree = .
replace degree = 1 if education==1 | education==5 | education==6
replace degree = 0 if education==3 | education==2
label variable degree "Degree or Higher"

recode income (1=.) (2=10000) (3=200000) (4=30000) (5=50000) (6=70000) (7=90000), gen(inc)
label variable inc "Income"

label variable age "Age"

label variable employed "Employed"

gen hchoicedegree = hchoice*degree
gen hchoicewhite = hchoice*white
gen hchoicemarr = hchoice*marr	
gen hchoiceemployed = hchoice*employed  
gen hchoiceatheist = hchoice*atheist
gen hchoiceinc = hchoice*inc
gen hchoiceage = hchoice*age
gen hchoicemaledum = hchoice*maledum

label variable hchoicedegree "Options * Degree"
label variable hchoicewhite "Options * White"
label variable hchoicemarr "Options * Married"
label variable hchoiceemployed "Options * Employed"
label variable hchoiceatheist "Options * Atheist"
label variable hchoiceinc "Options * Income"
label variable hchoiceage "Options * Age"
label variable hchoicemaledum "Options * Male"

gen mchoicedegree = mchoice*degree
gen mchoicewhite = mchoice*white
gen mchoicemarr = mchoice*marr	
gen mchoiceemployed = mchoice*employed  
gen mchoiceatheist = mchoice*atheist
gen mchoiceinc = mchoice*inc
gen mchoiceage = mchoice*age
gen mchoicemaledum = mchoice*maledum

label variable mchoicedegree "Choices * Degree"
label variable mchoicewhite "Choices * White"
label variable mchoicemarr "Choices * Married"
label variable mchoiceemployed "Choices * Employed"
label variable mchoiceatheist "Choices * Atheist"
label variable mchoiceinc "Choices * Income"
label variable mchoiceage "Choices * Age"
label variable mchoicemaledum "Choices * Male"

gen dchoicedegree = dchoice*degree
gen dchoicewhite = dchoice*white
gen dchoicemarr = dchoice*marr	
gen dchoiceemployed = dchoice*employed  
gen dchoiceatheist = dchoice*atheist
gen dchoiceinc = dchoice*inc
gen dchoiceage = dchoice*age
gen dchoicemaledum = dchoice*maledum

label variable dchoicedegree "Default * Degree"
label variable dchoicewhite "Default * White"
label variable dchoicemarr "Default * Married"
label variable dchoiceemployed "Default * Employed"
label variable dchoiceatheist "Default * Atheist"
label variable dchoiceinc "Default * Income"
label variable dchoiceage "Default * Age"
label variable dchoicemaledum "Default * Male"

gen revealdegree = reveal*degree
gen revealwhite = reveal*white
gen revealmarr = reveal*marr	
gen revealemployed = reveal*employed  
gen revealatheist = reveal*atheist
gen revealinc = reveal*inc
gen revealage = reveal*age
gen revealmaledum = reveal*maledum

label variable revealdegree "Reveal * Degree"
label variable revealwhite "Reveal * White"
label variable revealmarr "Reveal * Married"
label variable revealemployed "Reveal * Employed"
label variable revealatheist "Reveal * Atheist"
label variable revealinc "Reveal * Income"
label variable revealage "Reveal * Age"
label variable revealmaledum "Reveal * Male"

foreach var in hchoice mchoice dchoice  {
	
	eststo clear
	
	eststo: reg donation `var' if TreatmentSignal==0 , cluster(id)

foreach x in degree white marr employed atheist inc age maledum {

eststo: reg donation `x' `var' `var'`x' if TreatmentSignal==0  , cluster(id)

}


esttab using "$drive\tabs\Table`var'covs.tex", se  star(* 0.10 ** 0.05 *** 0.01) keep(`var' degree white marr employed atheist inc age maledum `var'degree `var'white `var'marr `var'employed `var'atheist `var'inc `var'age `var'maledum) nomtitles mgroups("Donations (Tokens)", pattern(1 0 0 0 0 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the amount experimental participants donated to on the treatment variable using eight demographic variables as moderators: whether participant has a bachelor's degree or higher (versus high school or less); whether they are White British (versus all other ethnicities); whether they are employed (part-time or full-time versus out of employment for any reason); whether they are married (versus never married); whether they are an atheist (versus any religion); their income; their age; and whether they are male (versus female). In columns (2), (4), and (7), some data is lost as ambiguous categories are coded as missing to facilitate a clear interpretation of the dummy variable." "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Effect of `var' on Donations Using Demographic Moderators \label{Table`var'covs})

	  }

	  
drop temp*	  

*Choice model (Atiyeh) Table4

*My initial analysis says that the addition of the labels distorts the distribution. With the addition of the number of charities, Animals become less likely to be chosen.
*i.e., comparing No Signal and Signal treatments and using Animals as the base group.
gen temp = .
replace temp = 0 if Treatments <13 & nvals == 1
replace temp = 1 if Treatments >12 & nvals == 1
mlogit Category temp, base(2) robust // default by stata
drop temp

*Comparing HHHH (all 40) and HLLL (only 40) shows that Animal is less likely to be chosen (negative coefficient), but not significant, indicating weak choice overload. 
gen temp = .
replace temp = 0 if Treatments ==13 & nvals == 1
replace temp = 1 if Treatments ==16 & nvals == 1
mlogit Category temp, base(2) robust // default base
drop temp

*Comparing LLLL (all 5) and LHHH (only 5) shows that Animal is less likely to be chosen (positive coefficient), but not significant, indicating weak choice deprivation. 
gen temp = .
replace temp = 0 if Treatments ==14 & nvals == 1
replace temp = 1 if Treatments ==15 & nvals == 1
mlogit Category temp, base(2) robust // default base
drop temp

*Comparing only 5 and only 40 shows that the Animal is less likely to be chosen (negative coefficient), but not significant, indicating weak choice deprivation. 
gen temp = .
replace temp = 0 if Treatments ==15 & nvals == 1
replace temp = 1 if Treatments ==16 & nvals == 1
mlogit Category temp, base(2) robust // default base
drop temp


TheEnd
/*

2106
**--------------------
** extensive margin
**--------------------

** r*Q: rate * Quantity // Q: = sum of amount := Extensive margin
** r*Q: rate * Quantity // r: = rate := fraction := Intensive

** share of donors * amount of donation

ta Donors TreatmentChoice if nvals == 1

** Donors dummy: base no donation in two rounds

ta Donors
ta Donors, nolabel

gen donors_dummy = .
replace donors_dummy = 1 if Donors == 4
replace donors_dummy = 1 if Donors == 1 & round_number == 1
replace donors_dummy = 1 if Donors == 2 & round_number == 2
replace donors_dummy = 0 if Donors == 3
replace donors_dummy = 0 if Donors == 1 & round_number == 2
replace donors_dummy = 1 if Donors == 2 & round_number == 1

ta donors_dummy Donors if nvals == 1


** Round dummey: base round 1
gen round_number_dummy = round_number - 1
ta round_number, m
ta round_number_dummy, m

** Treatment options dummy: base teatment 3, 55
ta TreatmentOption, m
ta TreatmentOption, nolabel m
tabulate TreatmentOption, generate(TreatmentOption)

gen TreatmentOption1_round = TreatmentOption1*round_number_dummy
gen TreatmentOption2_round = TreatmentOption2*round_number_dummy
gen TreatmentOption3_round = TreatmentOption3*round_number_dummy
gen TreatmentOption4_round = TreatmentOption4*round_number_dummy

** Treatment choices dummy: base teatment 1, 1choice
ta TreatmentChoice, m
ta TreatmentChoice, nolabel m
tabulate TreatmentChoice, generate(TreatmentChoice)

gen TreatmentChoice1_round = TreatmentChoice1*round_number_dummy
gen TreatmentChoice2_round = TreatmentChoice2*round_number_dummy
gen TreatmentChoice3_round = TreatmentChoice3*round_number_dummy

ta round_number, m
su TreatmentOption TreatmentChoice round_number

ta TreatmentChoice round_number


** LPM
* base none or only 1 round

reg donors_dummy TreatmentOption1 TreatmentOption2 TreatmentOption4 TreatmentOption1_round TreatmentOption2_round TreatmentOption4_round round_number_dummy

reg donors_dummy TreatmentOption1 TreatmentOption2 TreatmentOption4 TreatmentOption1_round TreatmentOption2_round TreatmentOption4_round round_number_dummy ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id)

reg donors_dummy TreatmentOption1 TreatmentOption2 TreatmentOption4 TreatmentOption1_round TreatmentOption2_round TreatmentOption4_round round_number_dummy, cluster(id)

reg donors_dummy TreatmentChoice2 TreatmentChoice3  TreatmentChoice1_round TreatmentChoice3_round round_number_dummy , cluster(id)

reg donors_dummy TreatmentChoice2 TreatmentChoice3 TreatmentChoice2_round TreatmentChoice3_round  round_number_dummy b1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id)

   
** for the overleaf:
eststo clear
eststo: reg donors_dummy TreatmentOption1 TreatmentOption2 TreatmentOption4 TreatmentOption1_round TreatmentOption2_round TreatmentOption4_round round_number_dummy, cluster(id)
estadd local hascon = "No"       
eststo: reg donors_dummy TreatmentOption1 TreatmentOption2 TreatmentOption4 TreatmentOption1_round TreatmentOption2_round TreatmentOption4_round round_number_dummy ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id)
estadd local hascon = "Yes"
eststo: reg donors_dummy TreatmentChoice2 TreatmentChoice3 TreatmentChoice2_round TreatmentChoice3_round round_number_dummy, cluster(id)
estadd local hascon = "No"   
eststo: reg donors_dummy TreatmentChoice2 TreatmentChoice3 TreatmentChoice2_round TreatmentChoice3_round  round_number_dummy ib1.education ib14.ethnicity ib5.marital ib7.employment  ib6.religion ib2.income age ib2.male, cluster(id)
estadd local hascon = "Yes"

esttab using "$drive\tabs\extensive.tex", se keep(_cons TreatmentOption1 TreatmentOption2 TreatmentOption4 TreatmentOption1_round TreatmentOption2_round TreatmentOption4_round TreatmentChoice2 TreatmentChoice3 TreatmentChoice3_round round_number_dummy) varlabels(_cons Base_group TreatmentOption1 LH TreatmentOption2 HL TreatmentOption4 HH TreatmentOption1_round LH_round2 TreatmentOption2_round HL_round2 TreatmentOption4 HH TreatmentOption1_round 1ChoiceDefault_round2 TreatmentChoice3_round MChoice TreatmentChoice3_round MChoice_round2 round_number_dummy) scalars("hascon Controls") nomtitles mgroups("Decision to Donate", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) nonotes addnote("LPM regressions of the decision to donate (=1) two treatment variables: the Options variable measures whether they could see 40 charities versus 5; the Choices variable measures whether they could select multiple charities to donate to versus just one. Regressions exclude perceived importance treatment which measures whether the participant can see the number of charities devoted to a cause before selecting that cause. Covariates include education level, race, marital status, employment status, religion, income, age, and gender." "Standard errors in parentheses, clustered by individual." "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") alignment(c) label replace title (Participants decision to donate \label{tab:extensive})



gen intdon = .
replace intdon = 0 if donors_dummy==0
replace intdon = donation if donors_dummy==1

eststo clear

eststo: reg intdon hchoice round, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 
estadd local hasfe = "No"
estadd local hascon = "No"

eststo: reg intdon hchoice round ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "No"
estadd local hascon = "Yes"

eststo: xtreg intdon hchoice round, i(id) cluster(id) fe, if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "Yes"
estadd local hascon = "No"

eststo: reg intdon hchoice mchoice round, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "No"
estadd local hascon = "No"

eststo: reg intdon hchoice mchoice round ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "No"
estadd local hascon = "Yes"

esttab using "$drive\tabs\Intensive1.tex", se keep(hchoice mchoice round) scalars("hasfe Fixed Effect" "hascon Controls") nomtitles mgroups("Hypothesis 1" "Hypothesis 2", pattern(1 0 0 1 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions using the amount experimental participants donated to charity, conditional on donating at all, as a dependent variable. There are two treatment variables: the Options variable measures whether they could see 40 charities versus 5; the Choices variable measures whether they could select multiple charities to donate to versus just one. Individual fixed effects can be included for the Options treatment because there is within-participant variation in the number of charities seen, but the Choices treatment is between-participant. Regressions exclude the default treatment, which measures whether the participant has a pre-selected donation option, and perceived importance treatment which measures whether the participant can see the number of charities devoted to a cause before selecting that cause. Covariates include education level, race, marital status, employment status, religion, income, age, and gender." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)" ) ///
 alignment(c) label replace ///
      title (Effect of Treatments on Donations \label{TableIntensive1})		
*/	
	

	
	
	
	
// old codes
	  
*Mediator regressions: does adding satisfacton, regret etc. eliminate significance of treatment?

label variable donation "Donation Amount (Tokens)"

eststo clear

eststo: reg satisD hchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg satisD hchoice donation, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg satisD mchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg satisD mchoice donation, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

esttab using "$drive\tabs\Table5.tex", se  star(* 0.10 ** 0.05 *** 0.01) keep(hchoice mchoice donation) nomtitles mgroups("Choice Satisfaction", pattern(1 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions using a dependent variable measuring the satisfaction experimental participants reported after donating to charity. The Options variable measures whether they could see 40 charities versus 5; the Choices variable measures whether they could choose only one charity versus multiple charities. Columns (2) and (4)include the tokens donated by participants as a mediator variable." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of the Effect of Treatments On Satisfaction \label{Table5})
	  
	  
  
eststo clear

eststo: reg regrD hchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg regrD hchoice donation, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg regrD mchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg regrD mchoice donation, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

esttab using "$drive\tabs\Table6.tex", se keep(hchoice mchoice donation) nomtitles mgroups("Choice Regret", pattern(1 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions using a dependent variable measuring the regret experimental participants reported after donating to charity. The Options variable measures whether they could see 40 charities versus 5 and the Choices variable measures whether they could choose only one charity versus multiple charities. Columns (2) and (4) include the tokens donated by participants as a mediator variable." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of the Effect of Treatments On Regret \label{Table6})

label variable familiarityD1_temp "Familiarity with Charities"  

label variable deliberationD1_temp "Deliberation over Choices"  

label variable diffic "Difficulty of Choices"

	  
eststo clear

eststo: reg donation hchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg donation hchoice diffic, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg donation hchoice deliberationD1_temp, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg donation hchoice familiarityD1_temp, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg donation hchoice diffic deliberationD1_temp familiarityD1_temp, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

esttab using "$drive\tabs\Table7.tex", se keep(hchoice diffic deliberationD1_temp familiarityD1_temp) nomtitles mgroups("Donations (Tokens)", pattern(1 0 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the donations to charity in our experiment on the Options treatment, which measures whether participants could see 40 charities versus 5. The regressions add three potential mediators: how difficult participants reported finding the choices, how long they deliberated over them, and how familiar they were with the listed charities." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of Options Treatment on Donations \label{Table7})


	  
eststo clear

eststo: reg donation mchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg donation mchoice diffic, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg donation mchoice deliberationD1_temp, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg donation mchoice familiarityD1_temp, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg donation mchoice diffic deliberationD1_temp familiarityD1_temp, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

esttab using "$drive\tabs\Table8.tex", se keep(mchoice diffic deliberationD1_temp familiarityD1_temp) nomtitles mgroups("Donations (Tokens)", pattern(1 0 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the donations to charity in our experiment on the Choices treatment, which measures whether participants could donate to multiple charities versus just one. The regressions add three potential mediators: how difficult participants reported finding the choices, how long they deliberated over them, and how familiar they were with the listed charities." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of Choices Treatment on Donations \label{Table8})
	  
*Choices and options together, with only difficulty 
  
eststo clear
 
eststo: reg donation hchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg donation hchoice diffic, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg donation mchoice, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg donation mchoice diffic, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

esttab using "$drive\tabs\Table89.tex", se keep(hchoice mchoice diffic) nomtitles mgroups("Donations (Tokens)", pattern(1 0 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the donations to charity in our experiment on the Options treatment, which measures whether participants could see 40 charities versus 5; and the Choices treatment, which measures whether participants could donate to multiple charities versus just one. The regressions include a mediator measuring how difficult participants reported finding the choices." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of Treatments on Donations \label{Table89})

eststo clear

eststo: reg donation dchoice, cluster(id)

eststo: reg donation dchoice diffic, cluster(id)

eststo: reg donation dchoice deliberationD1_temp, cluster(id)

eststo: reg donation dchoice familiarityD1_temp, cluster(id)

eststo: reg donation dchoice diffic deliberationD1_temp familiarityD1_temp, cluster(id)

esttab using "$drive\tabs\Table9.tex", se keep(dchoice diffic deliberationD1_temp familiarityD1_temp) nomtitles mgroups("Donations (Tokens)", pattern(1 0 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the donations to charity in our experiment on the Default treatment, which measures whether participants had a pre-selected default donation option available. The regressions add three potential mediators: how difficult participants reported finding the choices, how long they deliberated over them, and how familiar they were with the listed charities." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of Default Treatment on Donations \label{Table9})

*Disentangling difficulty

label variable difficulty1_temp "How would you rate the level of difficulty you experienced when making the choices?"

label variable difficulty2_temp "How would you rate the amount of effort it took for you to make your choices?"

label variable difficulty3_temp "How would you rate the amount of time it took you to make your choices?"

label variable difficulty4_temp "How would you rate the amount of thought you had to put into making your choices?"

eststo clear

eststo: reg donation hchoice diffic, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg donation hchoice difficulty1_temp difficulty2_temp difficulty3_temp difficulty4_temp, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg donation mchoice diffic, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

eststo: reg donation mchoice difficulty1_temp difficulty2_temp difficulty3_temp difficulty4_temp, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

esttab using "$drive\tabs\Table9a.tex", se keep(hchoice mchoice diffic difficulty1_temp difficulty2_temp difficulty3_temp difficulty4_temp) nomtitles mgroups("Donations (Tokens)", pattern(1 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the donations to charity in our experiment on the Options treatment, which measures whether participants could see 40 charities versus 5; and the Choices treatment, which measures whether participants could donate to multiple charities versus just one. The regressions include a mediator measuring how difficult participants reported finding the choices. In columns (2) and (4), the difficulty questionnaire is split up into the individual questions." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Mediation of Difficulty Questions \label{Table9a})
	  


ta Donors
ta Donors, nolabel

gen donors_dummy = .
replace donors_dummy = 1 if Donors == 4
replace donors_dummy = 1 if Donors == 1 & round == 1
replace donors_dummy = 1 if Donors == 2 & round == 2
replace donors_dummy = 0 if Donors == 3
replace donors_dummy = 0 if Donors == 1 & round == 2
replace donors_dummy = 1 if Donors == 2 & round == 1


gen intdon = .
replace intdon = . if donors_dummy==0
replace intdon = donation if round==1

eststo clear

eststo: reg intdon hchoice round, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 
estadd local hasfe = "No"
estadd local hascon = "No"

eststo: reg intdon hchoice round ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "No"
estadd local hascon = "Yes"

eststo: xtreg intdon hchoice round, i(id) cluster(id) fe, if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "Yes"
estadd local hascon = "N/A"

eststo: reg intdon hchoice mchoice round, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "No"
estadd local hascon = "No"

eststo: reg intdon hchoice mchoice round ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "No"
estadd local hascon = "Yes"

esttab using "$drive\tabs\Intensive1.tex", se keep(hchoice mchoice round) scalars("hasfe Fixed Effect" "hascon Controls") nomtitles mgroups("Hypothesis 1" "Hypothesis 2", pattern(1 0 0 1 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions using the amount experimental participants donated to charity, conditional on donating at all, as a dependent variable. There are two treatment variables: the Options variable measures whether they could see 40 charities versus 5; the Choices variable measures whether they could select multiple charities to donate to versus just one. Individual fixed effects can be included for the Options treatment because there is within-participant variation in the number of charities seen, but the Choices treatment is between-participant. Regressions exclude the default arm of the experiment, which measures whether the participant has a pre-selected donation option, and the perceived importance arm, which measures whether the participant can see the number of charities devoted to a cause before selecting that cause. Covariates include education level, race, marital status, employment status, religion, income, age, and gender." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)" ) ///
 alignment(c) label replace ///
      title (Effect of Treatments on Donations \label{TableIntensive1})	
	  
*Extensive margin (Cahal)
drop extdon
gen extdon = .
replace extdon = 0 if donation == 0
replace extdon = 1 if donation > 1 & donation!=.

eststo clear

eststo: reg extdon hchoice round, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2 
estadd local hasfe = "No"
estadd local hascon = "No"

eststo: reg extdon hchoice round ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "No"
estadd local hascon = "Yes"

eststo: xtreg extdon hchoice round, i(id) cluster(id) fe, if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "Yes"
estadd local hascon = "N/A"

eststo: reg extdon hchoice mchoice round, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "No"
estadd local hascon = "No"

eststo: reg extdon hchoice mchoice round ib1.education ib14.ethnicity ib5.marital ib7.employment ib6.religion ib2.income age ib2.male, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2  
estadd local hasfe = "No"
estadd local hascon = "Yes"

esttab using "$drive\tabs\Extensive1.tex", se keep(hchoice mchoice round) scalars("hasfe Fixed Effect" "hascon Controls") nomtitles mgroups("Hypothesis 1" "Hypothesis 2", pattern(1 0 0 1 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("Linear OLS regressions using a binary measure for whetehr or not a participant donated at all as a dependent variable. There are two treatment variables: the Options variable measures whether they could see 40 charities versus 5; the Choices variable measures whether they could select multiple charities to donate to versus just one. Individual fixed effects can be included for the Options treatment because there is within-participant variation in the number of charities seen, but the Choices treatment is between-participant. Regressions exclude the default arm of the experiment, which measures whether the participant has a pre-selected donation option, and the perceived importance arm, which measures whether the participant can see the number of charities devoted to a cause before selecting that cause. Covariates include education level, race, marital status, employment status, religion, income, age, and gender." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)" ) ///
 alignment(c) label replace ///
      title (Effect of Treatments on Donations \label{TableExtensive1})	


	  *Effect of Treatments on Mediators
	  
eststo clear

eststo: reg diffic hchoice, cluster(id)

eststo: reg diffic mchoice, cluster(id)

eststo: reg diffic dchoice, cluster(id)

eststo: reg deliberationD1_temp hchoice, cluster(id)

eststo: reg deliberationD1_temp mchoice, cluster(id)

eststo: reg deliberationD1_temp dchoice, cluster(id)

eststo: reg familiarityD1_temp hchoice, cluster(id)

eststo: reg familiarityD1_temp mchoice, cluster(id)

eststo: reg familiarityD1_temp dchoice, cluster(id)

esttab using "$drive\tabs\Table10.tex", se keep(hchoice mchoice dchoice) nomtitles mgroups("Choice Difficulty" "Choice Deliberation" "Choice Familiarity", pattern(1 0 0 1 0 0 1 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("Nine OLS regressions of three subjective variables on three treatments. The subjective variables are: how difficult participants reported finding the choices; how long they deliberated over them; and how familiar they were with the listed charities. The treatments are: the options treatment, which measures whether participants had 40 versus 5 charities to choose from; the choices treatment, which measures whether participants could donate to multiple versus just one charity; and the default treatment, which measures whether they could use a pre-selected default donation option instead of choosing manually." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Effect of Treatment on Subjective Variables \label{Table10})	  
	  


*Charitable Giving

*How much donated
encode charitablegiving, gen(charitablegiving_temp)
recode charitablegiving_temp (1=150) (2=350) (3=.) (4=62.5) (5=1000) (6=87.5), gen(give)
label variable give "Money Donated"

    replace charitablegiving_temp = 1 if charitablegiving == "£50-£75"
	replace charitablegiving_temp = 2 if charitablegiving == "£75-£100"
	replace charitablegiving_temp = 3 if charitablegiving == "£101-£200"
    replace charitablegiving_temp = 4 if charitablegiving == "£201-£500"    
    replace charitablegiving_temp = 5 if charitablegiving == "£501+"
      replace charitablegiving_temp = . if charitablegiving == "£201-£500, £101-£200"
   
    
    label define charitablegiving_temp_lbl  5 "£501+" ///
                                     4 "£201-£500" ///
                                     3 "£101-£200" ///
                                     2 "£75-£100" ///
                                     1 "£50-£75"
									 
    label values charitablegiving_temp charitablegiving_temp_lbl
    


encode PreferenceGiving, gen(PreferenceGiving_temp)
gen vol = (PreferenceGiving_temp==3)
gen mon = (PreferenceGiving_temp==2)
label variable vol "Prefers Volunteering"
label variable mon "Prefers Donating"

*Personality varibles moderators
gen hchoiceSRA = SRA*hchoice
gen hchoiceavoid = avoid*hchoice
gen hchoicemax = max*hchoice
gen hchoicegive = give*hchoice
gen hchoicevol = vol*hchoice
gen hchoicemon = mon*hchoice
label variable hchoiceSRA "Options * Altruism"
label variable hchoiceavoid "Options * Avoidance"
label variable hchoicemax "Options * Maximiser"
label variable hchoicegive "Options * Money Donated"
label variable hchoicevol "Options * Prefers Volunteering"
label variable hchoicemon "Options * Prefers Donating"

gen mchoiceSRA = SRA*mchoice
gen mchoiceavoid = avoid*mchoice
gen mchoicemax = max*mchoice
gen mchoicegive = give*mchoice
gen mchoicevol = vol*mchoice
gen mchoicemon = mon*mchoice
label variable mchoiceSRA "Choices * Altruism"
label variable mchoiceavoid "Choices * Avoidance"
label variable mchoicemax "Choices * Maximiser"
label variable mchoicegive "Choices * Money Donated"
label variable mchoicevol "Choices * Prefers Volunteering"
label variable mchoicemon "Choices * Prefers Donating"

gen dchoiceSRA = SRA*dchoice
gen dchoiceavoid = avoid*dchoice
gen dchoicemax = max*dchoice
gen dchoicegive = give*dchoice
gen dchoicevol = vol*dchoice
gen dchoicemon = mon*dchoice
label variable dchoiceSRA "Default * Altruism"
label variable dchoiceavoid "Default * Avoidance"
label variable dchoicemax "Default * Maximiser"
label variable dchoicegive "Default * Money Donated"
label variable dchoicevol "Default * Prefers Volunteering"
label variable dchoicemon "Default * Prefers Donating"

gen revealSRA = SRA*reveal
gen revealavoid = avoid*reveal
gen revealmax = max*reveal
gen revealgive = give*reveal
gen revealvol = vol*reveal
gen revealmon = mon*reveal
label variable revealSRA "Reveal * Altruism"
label variable revealavoid "Reveal * Avoidance"
label variable revealmax "Reveal * Maximiser"
label variable revealgive "Reveal * Money Donated"
label variable revealvol "Reveal * Prefers Volunteering"
label variable revealmon "Reveal * Prefers Donating"

label variable avoid "Avoidance"
label variable max "Maximiser"
label variable SRA "Altruism (SRA)"

		
foreach var in hchoice mchoice {
	
	eststo clear
	
	eststo: reg donation `var', cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

foreach x in SRA avoid max give {

eststo: reg donation `x' `var' `var'`x', cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

}


eststo: reg donation `var' vol mon `var'vol `var'mon, cluster(id), if TreatmentSignal==0 & TreatmentChoice!=2

esttab using "$drive\tabs\Table`var'.tex", se keep(`var' SRA avoid max give vol mon `var'SRA `var'avoid `var'max `var'give `var'vol `var'mon) nomtitles mgroups("Donations (Tokens)", pattern(1 0 0 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the amount experimental participants donated to on the treatment variable using six moderator variables: altruism; avoidant decision-making; maximising versus satisficing behaviour; and prior involvement in charitable giving, both volunteering and donations." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Effect of `var' Treatment on Donations Using Selected Moderators \label{Table`var'})

	  }	 
	  
 
*H Choice with fixed effects	  
	  
	  
	
	eststo clear
	
	eststo: xtreg donation hchoice, cluster(id) i(id) fe, if TreatmentSignal==0 & TreatmentChoice!=2

foreach x in SRA avoid max give {

eststo: xtreg donation `x' hchoice hchoice`x', cluster(id) i(id) fe, if TreatmentSignal==0 & TreatmentChoice!=2

}


eststo: xtreg donation hchoice vol mon hchoicevol hchoicemon, cluster(id) i(id) fe, if TreatmentSignal==0 & TreatmentChoice!=2


 
	  
	  esttab using "$drive\tabs\TablehchoiceFE.tex", se keep(hchoice SRA avoid max give vol mon hchoiceSRA hchoiceavoid hchoicemax hchoicegive hchoicevol hchoicemon) nomtitles mgroups("Donations (Tokens)", pattern(1 0 0 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the amount experimental participants donated to on the treatment variable using six moderator variables: altruism; avoidant decision-making; maximising versus satisficing behaviour; and prior involvement in charitable giving, both volunteering and donations." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Effect of `var' on Donations Using Selected Moderators \label{TablehchoiceFE})

	  *Moderators Together
	  
eststo clear

eststo: reg donation hchoice SRA hchoiceSRA avoid hchoiceavoid max hchoicemax give hchoicegive vol hchoicevol mon hchoicemon, cluster(id)

eststo: xtreg donation hchoice SRA hchoiceSRA avoid hchoiceavoid max hchoicemax give hchoicegive vol hchoicevol mon hchoicemon, cluster(id) i(id) fe

eststo: reg donation mchoice SRA mchoiceSRA avoid mchoiceavoid max mchoicemax give mchoicegive vol mchoicevol mon mchoicemon, cluster(id)

eststo: reg donation dchoice SRA dchoiceSRA avoid dchoiceavoid max dchoicemax give dchoicegive vol dchoicevol mon dchoicemon, cluster(id)

*eststo: reg donation schoice SRA schoiceSRA avoid schoiceavoid max schoicemax give schoicegive vol schoicevol mon schoicemon, cluster(id)

esttab using "$drive\tabs\Tablemods.tex", se keep(hchoice SRA hchoiceSRA avoid hchoiceavoid max hchoicemax give hchoicegive vol hchoicevol hchoicemon mchoice mchoiceSRA mchoiceavoid mchoicemax mchoicegive mchoicevol mchoicemon dchoice dchoiceSRA dchoiceavoid dchoicemax dchoicegive dchoicevol dchoicemon) nomtitles mgroups("Donations (Tokens)", pattern(1 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the amount experimental participants donated to on the four treatment variables: the options treatment; the choices treatment; the default treatment; the signal treatment. Each regressions also includes six moderator variables and their interactions with the treatments: altruism; avoidant decision-making; maximising versus satisficing behaviour; and prior involvement in charitable giving, both volunteering and donations." "Standard errors in parentheses, clustered by individual" "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Effect of Treatments on Donations Using Selected Moderators \label{Tablemods})


*Demographic variables

gen marr = .
replace marr = 1 if marital==4
replace marr = 0 if marital==5
label variable marr "Married"

gen degree = .
replace degree = 1 if education==1 | education==5 | education==6
replace degree = 0 if education==3 | education==2
label variable degree "Degree or Higher"

recode income (1=.) (2=10000) (3=200000) (4=30000) (5=50000) (6=70000) (7=90000), gen(inc)
label variable inc "Income"

label variable age "Age"

label variable employed "Employed"

gen hchoicedegree = hchoice*degree
gen hchoicewhite = hchoice*white
gen hchoicemarr = hchoice*marr	
gen hchoiceemployed = hchoice*employed  
gen hchoiceatheist = hchoice*atheist
gen hchoiceinc = hchoice*inc
gen hchoiceage = hchoice*age
gen hchoicemaledum = hchoice*maledum

label variable hchoicedegree "Options * Degree"
label variable hchoicewhite "Options * White"
label variable hchoicemarr "Options * Married"
label variable hchoiceemployed "Options * Employed"
label variable hchoiceatheist "Options * Atheist"
label variable hchoiceinc "Options * Income"
label variable hchoiceage "Options * Age"
label variable hchoicemaledum "Options * Male"

gen mchoicedegree = mchoice*degree
gen mchoicewhite = mchoice*white
gen mchoicemarr = mchoice*marr	
gen mchoiceemployed = mchoice*employed  
gen mchoiceatheist = mchoice*atheist
gen mchoiceinc = mchoice*inc
gen mchoiceage = mchoice*age
gen mchoicemaledum = mchoice*maledum

label variable mchoicedegree "Choices * Degree"
label variable mchoicewhite "Choices * White"
label variable mchoicemarr "Choices * Married"
label variable mchoiceemployed "Choices * Employed"
label variable mchoiceatheist "Choices * Atheist"
label variable mchoiceinc "Choices * Income"
label variable mchoiceage "Choices * Age"
label variable mchoicemaledum "Choices * Male"

gen dchoicedegree = dchoice*degree
gen dchoicewhite = dchoice*white
gen dchoicemarr = dchoice*marr	
gen dchoiceemployed = dchoice*employed  
gen dchoiceatheist = dchoice*atheist
gen dchoiceinc = dchoice*inc
gen dchoiceage = dchoice*age
gen dchoicemaledum = dchoice*maledum

label variable dchoicedegree "Default * Degree"
label variable dchoicewhite "Default * White"
label variable dchoicemarr "Default * Married"
label variable dchoiceemployed "Default * Employed"
label variable dchoiceatheist "Default * Atheist"
label variable dchoiceinc "Default * Income"
label variable dchoiceage "Default * Age"
label variable dchoicemaledum "Default * Male"

gen revealdegree = reveal*degree
gen revealwhite = reveal*white
gen revealmarr = reveal*marr	
gen revealemployed = reveal*employed  
gen revealatheist = reveal*atheist
gen revealinc = reveal*inc
gen revealage = reveal*age
gen revealmaledum = reveal*maledum

label variable revealdegree "Reveal * Degree"
label variable revealwhite "Reveal * White"
label variable revealmarr "Reveal * Married"
label variable revealemployed "Reveal * Employed"
label variable revealatheist "Reveal * Atheist"
label variable revealinc "Reveal * Income"
label variable revealage "Reveal * Age"
label variable revealmaledum "Reveal * Male"

foreach var in hchoice mchoice dchoice reveal {
	
	eststo clear
	
	eststo: reg donation `var', cluster(id)

foreach x in degree white marr employed atheist inc age maledum {

eststo: reg donation `x' `var' `var'`x', cluster(id)

}


esttab using "$drive\tabs\Table`var'covs.tex", se  star(* 0.10 ** 0.05 *** 0.01) keep(`var' degree white marr employed atheist inc age maledum `var'degree `var'white `var'marr `var'employed `var'atheist `var'inc `var'age `var'maledum) nomtitles mgroups("Donations (Tokens)", pattern(1 0 0 0 0 0 0 0) ///
  prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
       nonotes addnote("OLS regressions of the amount experimental participants donated to on the treatment variable using eight demographic variables as moderators: whether participant has a bachelor's degree or higher (versus high school or less); whether they are White British (versus all other ethnicities); whether they are employed (part-time or full-time versus out of employment for any reason); whether they are married (versus never married); whether they are an atheist (versus any religion); their income; their age; and whether they are male (versus female). In columns (2), (4), and (7), some data is lost as ambiguous categories are coded as missing to facilitate a clear interpretation of the dummy variable." "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)") ///
 alignment(c) label replace ///
      title (Effect of `var' on Donations Using Demographic Moderators \label{Table`var'covs})

	  }


