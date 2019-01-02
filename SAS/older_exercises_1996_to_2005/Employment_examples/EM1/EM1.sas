/****************************************************************\

PROGRAM:       C:\MEPS\PROG\EXAMPLE_EM1.SAS

DESCRIPTION:  	THIS EXAMPLE SHOWS HOW TO BUILD AN ANALYTIC FILE
               AND CREATE NEW VARIABLES TO EXAMINE THE
               RELATIONSHIP BETWEEN PERCEIVED HEALTH STATUS
               AND A PERSON'S WEEKLY EARNINGS, WHERE WEEKLY 
               EARNINGS ARE THOSE OF THE CURRENT MAIN JOB. 
               
               PERSON-LEVEL RECORDS ARE DIVIDED INTO QUARTILES
               BASED ON WEEKLY EARNINGS AND PERSON-LEVEL WEIGHTS.
               THE RESULT IS 4 EQUALLY WEIGHTED QUARTILES FOR
               WEEKLY EARNINGS. 

INPUT FILE:  	C:\MEPS\DATA\H62.SAS7BDAT (2002 FULL-YEAR POPULATION)
                     -- PERSON-LEVEL FILE

\****************************************************************/

LIBNAME CMEPS V8 'C:\MEPS\DATA' ;

FOOTNOTE 'PROGRAM: C:\MEPS\PROG\EXAMPLE_EM1.SAS';

TITLE1 'AHRQ MEPS DATA USERS WORKSHOP (EMPLOYMENT) -- NOV/DEC 2004';
TITLE2 'PERCEIVED HEALTH STATUS AND WEEKLY EARNINGS - 2002 DATA';
TITLE3 ' ';

PROC FORMAT;
   VALUE GTZF
   -10 = '-10'
   0<-HIGH = '>0';
   VALUE HLTHF
   1 = '1 EXCELLENT'
   2 = '2 VERY GOOD'
   3 = '3 GOOD'
   4 = '4 FAIR'
   5 = '5 POOR';
   VALUE QUARTF
   1 = '   1 LOWEST '
   2 = '   2        '
   3 = '   3        '
   4 = '   4 HIGHEST';
   VALUE WKLYF
   0.13-<49.99 = '    0.13 -  49.99'
   50-499.99 =   '   50.00 - 499.99'
   500-999.99 =  '  500.00 - 999.99'
   1000-HIGH =   '1,000.00+        ';
RUN;

/***** THIS DATA STEP READS IN THE REQUIRED VARIABLES FROM THE *****/
/***** FULL-YEAR POPULATION FILE (HC-062).                     *****/

/***** THE 'WHERE' STATEMENT SUBSETS TO THE DESIRED SUBSET OF  *****/
/***** PERSONS: THOSE WITH A CURRENT MAIN JOB (CMJ) IN ROUNDS  *****/
/***** 4/2 THAT REPORTED EARNINGS, WEEKLY HOURS AND PERCEIVED  *****/
/***** HEALTH STATUS.                                          *****/

/***** A VALUE OF "-2" FOR THE '42' VARIABLES INDICATES THAT   *****/
/***** THE ACTUAL VALUE CAN BE OBTAINED FROM THE PRIOR ROUND,  *****/
/***** THE '31' VARIABLES.                                     *****/

/***** A WEEKLY EARNINGS VARIABLE "WKLYEARN' IS CREATED AS     *****/
/***** THE PRODUCE OF HOURLY WAGE ("HRLYWAGE") TIMES NUMBER    *****/
/***** OF WEEKLY WORK HOURS ("HOURS").                         *****/

DATA H62A;
   SET CMEPS.H62 (KEEP= DUPERSID PERWT02P VARSTR VARPSU EMPST42
                     SELFCM42 SELFCM31 HRWG42X HRWG31X HOUR42 HOUR31
                     RTHLTH42 TEMPJB42 AGE42X);
   WHERE    (EMPST42 IN (1,2)) AND 
            (SELFCM42 = 2 OR (SELFCM42 = -2 AND SELFCM31 = 2)) AND
            ((HRWG42X = -10) OR (HRWG42X > 0) OR 
               (HRWG42X = -2 AND (HRWG31X = -10 OR HRWG31X > 0))) AND
            (HOUR42 > 0 OR (HOUR42 = -2 AND HOUR31 > 0)) AND
            (RTHLTH42 IN (1,2,3,4,5)) AND
            (TEMPJB42 = 2) AND
            (AGE42X > 24);
   IF HRWG42X = -2
      THEN HRLYWAGE = HRWG31X;
   ELSE HRLYWAGE = HRWG42X;
   IF HRLYWAGE = -10
      THEN HRLYWAGE = 61.98; 
   IF HOUR42 > 0
      THEN HOURS = HOUR42;
   ELSE IF HOUR42 = -2
      THEN HOURS = HOUR31;
   WKLYEARN = HRLYWAGE*HOURS;
RUN;

PROC SORT DATA= H62A;
   BY WKLYEARN  ;
RUN;

/***** THIS DATA STEP READS IN H62A TWICE. THE FIRST TIME IS   *****/
/***** TO COMPUTE THE TOTAL SUM OF PERWT02P (THE PERSON-LEVEL  *****/
/***** WEIGHT VARIABLE). THE SECOND TIME IS TO CREATE 4 GROUPS *****/
/***** OF EQUAL WEIGHT: QUARTILE = 1-4. SEE THE TABLE ON LST   *****/
/***** P. 5.                                                   *****/


DATA H62B (KEEP= RTHLTH42 WKLYEARN QUARTILE PERWT02P VARSTR VARPSU);
   SET H62A (IN= A) H62A ;
   IF A
      THEN TOT_WT+PERWT02P;
   ELSE DO;
      SUM_WT+PERWT02P;
      IF SUM_WT <= TOT_WT*0.25
         THEN QUARTILE = 1;
      ELSE IF SUM_WT <= TOT_WT*0.5
         THEN QUARTILE = 2;
      ELSE IF SUM_WT <= TOT_WT*0.75
         THEN QUARTILE = 3;
      ELSE QUARTILE = 4;
      OUTPUT;
   END;
   LABEL    QUARTILE = 'WEEKLY EARNINGS QUARTILE'
            WKLYEARN = 'WEEKLY EARNINGS';
RUN;

TITLE4 'H62B: WEIGHTED FREQUENCY OF QUARTILES AND WKLYEARN';

PROC FREQ DATA= H62B;
   TABLES QUARTILE WKLYEARN;
   WEIGHT PERWT02P;
   FORMAT WKLYEARN WKLYF. ;
RUN;

TITLE4 'H62B: UNWEIGHTED FREQUENCY OF WKLYEARN';

PROC FREQ DATA= H62B;
   TABLES WKLYEARN;
   FORMAT WKLYEARN WKLYF. ;
RUN;

TITLE4 ' ';

PROC FREQ DATA= H62B;
   TABLES QUARTILE*RTHLTH42
            / LIST MISSING ;
   FORMAT RTHLTH42 HLTHF. ;
RUN;

PROC TABULATE DATA= H62B;
   CLASS QUARTILE RTHLTH42;
   TABLE QUARTILE,RTHLTH42*(PCTN<RTHLTH42>);
   FORMAT QUARTILE QUARTF. RTHLTH42 HLTHF. ;
   FREQ PERWT02P;
   WEIGHT PERWT02P;
RUN;

TITLE4 'MEAN REPORTED HEALTH STATUS BY WEEKLY EARNINGS QUARTILE';
TITLE5 '1=EXCELLENT, 2=VERY GOOD, 3=GOOD, 4=FAIR, 5=POOR';

PROC SURVEYMEANS DATA= H62B NOBS SUMWGT MEAN STDERR;
   VAR RTHLTH42;
   STRATA VARSTR;
   CLUSTER VARPSU;
   WEIGHT PERWT02P;
   DOMAIN QUARTILE;
   FORMAT QUARTILE QUARTF. ;
RUN;