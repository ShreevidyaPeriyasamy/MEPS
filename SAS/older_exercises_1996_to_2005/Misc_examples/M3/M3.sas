/**********************************************************************\

PROGRAM:       C:\MEPS\PROG\M3.SAS

DESCRIPTION:	THIS EXAMPLE SHOWS THE USE OF ID VARIABLES ON DIFFERENT
              MEPS PUBLIC-USE FILES (PUFs) AND HOW TO USE THESE ID
              VARIABLES TO MERGE MEPS FILES. 
		         
		         	THIS EXAMPLE SHOWS PRINTS OF PERSON-LEVEL AND CONDITION-
		         	LEVEL FILES TO SHOW THE USE OF THE ID VARIABLES. 
               
             	DUPERSID (HC-097) IS A PERSON-LEVEL IDENTIFIER.                                  
             	CONDIDX (HC-096) IS A PERSON-CONDITION-LEVEL IDENTIFIER.  

              NOTE THAT THE MERGES USING DUPERSID ALSO USE PANEL, THAT IS, 
              MERGE BY DUPERSID PANEL.  WHILE NOT NECESSARY WHEN PROCESSING 
              ONLY ONE YEAR OF MEPS DATA, AS IN THIS EXAMPLE, IT IS GOOD
              PROGRAMMING PRACTICE TO ADD PANEL TO MERGES BECAUSE 
              WHEN PROCESSING DATA ACROSS SEVERAL MEPS YEARS, DUPERSID (AND
              OTHER IDS) MAY NOT BE UNIQUE. SPECIFICALLY, STARTING WITH MEPS 2004,
              PANEL 9, IDS DUPLICATE EARLIER YEARS.                       

INPUT FILE:  	(1) C:\MEPS\DATA\H97.SAS7BDAT (2005 FULL-YEAR DATA FILE)                           
              (2) C:\MEPS\DATA\H96.SAS7BDAT (2005 CONDITIONS FILE)                              

\**********************************************************************/

FOOTNOTE 'PROGRAM: C:\MEPS\PROG\M3.SAS';

LIBNAME CDATA 'C:\MEPS\DATA';

TITLE1 'AHRQ MEPS DATA USERS WORKSHOP -- SEPTEMBER 2008';
TITLE2 'ILLUSTRATING THE USE OF ID VARIABLES (DUPERSID, CONDIDX)';

PROC FORMAT;
   VALUE YESNO
   -9 = '-9 NOT ASCERTAINED'
   -1 = '-1 INAPPLICABLE'
   1 = '1 YES'
   2 = '2 NO';
   VALUE SEXF
   1 = '1 MALE'
   2 = '2 FEMALE';   
RUN;
 
/***** GET DUPERSID AND OTHER VARIABLES FROM HC-097 *****/                                   

* READ 2005 CONSOLIDATED FULL YEAR FILE;
PROC SORT DATA= CDATA.H97 (KEEP= DUID PID DUPERSID PANEL AGE05X SEX PERWT05F                       
                                    VARSTR VARPSU)                                           
            OUT= FY2005;                                                                     
   BY DUPERSID PANEL;
RUN;

TITLE3 'PRINT OF SELECTED HC-097 (2005 FULL-YEAR FILE) RECORDS TO SHOW DUPERSID';                  

PROC PRINT DATA= FY2005 (FIRSTOBS=40 OBS= 90);                                                           
   VAR DUID PID DUPERSID PANEL AGE05X SEX ;                                                        
   FORMAT SEX SEXF. ;
RUN;

/***** GET DUPERSID, CONDIDX AND OTHER VARIABLES FROM HC-096 *****/                         

*READ 2005 CONDITIONS FILE;
PROC SORT DATA= CDATA.H96 (KEEP= DUPERSID PANEL CONDN CONDIDX INJURY ICD9CODX)                    
            OUT= COND2005;                                                                   
   BY DUPERSID PANEL CONDIDX;
RUN;

TITLE3 'PRINT OF SELECTED HC-096 (2005 CONDITIONS FILE) RECORDS TO SHOW';                          
TITLE4 'DUPERSID AND CONDIDX';

PROC PRINT DATA= COND2005 (FIRSTOBS=140 OBS=190);                                                        
   VAR DUPERSID PANEL CONDN CONDIDX INJURY ICD9CODX;
   FORMAT INJURY YESNO. ;
RUN;

/***** MERGE FILES TO CONNECT PERSON INFO WITH CONDITION INFO.  *****/
/***** THE MERGE MATCHES RECORDS USING THE DUPERSID VARIABLE *****/

DATA CONDINFO;
   MERGE FY2005 COND2005;                                                                  
   BY DUPERSID PANEL;
RUN;

TITLE3 'PRINT OF SELECTED RECORDS FROM MERGED, CONDITION-LEVEL, FILE';

PROC PRINT DATA= CONDINFO (FIRSTOBS=140 OBS=190);
   VAR DUPERSID PANEL CONDIDX AGE05X SEX INJURY ICD9CODX;                                        
   FORMAT SEX SEXF. INJURY YESNO. ;
RUN;

/***** MERGE FILES BUT NOW ONLY KEEP MATCHING RECORDS *****/

DATA CONDINFO_B;
   MERGE FY2005 (IN= A) COND2005 (IN= B);                                                  
   BY DUPERSID PANEL;
   IF A AND B;
RUN;

TITLE3 'PRINT OF SELECTED RECORDS FROM MERGED, CONDITION-LEVEL, FILE';
TITLE4 'WHERE ONLY MATCHED RECORDS WERE KEPT';

PROC PRINT DATA= CONDINFO_B (FIRSTOBS=140 OBS=190);
   VAR DUPERSID PANEL CONDIDX AGE05X SEX INJURY ICD9CODX;                                         
   FORMAT SEX SEXF. INJURY YESNO. ;
RUN;
   



