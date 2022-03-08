--------------------------------------------------------------------------------
-- Purpose: Populate job tables with data for SZPSABL job (Student Attribute Batch Load).
-- Author:  Kevin Klob
-- Date:    10/18/2021
-- Notes:   Run as BANINST1
--------------------------------------------------------------------------------

-- Allow DBMS_OUTPUT
SET SERVEROUTPUT ON

-- Disables variable substitution (treats ampersand like data)
SET DEFINE OFF

DECLARE
    job_name       VARCHAR2(7)    := 'SZPSABL';
    job_title      VARCHAR2(30)   := 'Student Attribute Batch Load';
    job_desc       VARCHAR2(80)   := 'Batch load student attributes into Banner using a PopSel';
BEGIN
    -----------------------------------------------------------------------------
    -- GZBJOBS - Callback procedure
    -----------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('GZBJOBS');

    DELETE FROM general.gzbjobs WHERE gzbjobs_name = job_name;

    INSERT INTO GENERAL.GZBJOBS (
        GZBJOBS_NAME,
        GZBJOBS_TITLE,
        GZBJOBS_ACTIVITY_DATE,
        GZBJOBS_SYSI_CODE,
        GZBJOBS_PROC_NAME)
    SELECT
        job_name    AS GZBJOBS_NAME,
        job_title   AS GZBJOBS_TITLE,
        SYSDATE     AS GZBJOBS_ACTIVITY_DATE,
        'S'         AS GZBJOBS_SYSI_CODE, -- H=Payroll, F=Finance, T=AcctRecv, S=Student
        'BANINST1.SZ_SZPSABL.P_PROCESS' 
                    AS GZBJOBS_PROC_NAME -- Stored procedure name to run
    FROM DUAL;

    -----------------------------------------------------------------------------
    -- GJBJOBS - Job definition
    -----------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('GJBJOBS');

    DELETE FROM general.gjbjobs WHERE gjbjobs_name = job_name;

    INSERT INTO GENERAL.GJBJOBS (
        GJBJOBS_NAME,
        GJBJOBS_TITLE,
        GJBJOBS_ACTIVITY_DATE,
        GJBJOBS_SYSI_CODE,
        GJBJOBS_JOB_TYPE_IND,
        GJBJOBS_DESC,
        GJBJOBS_PRNT_CODE,
        GJBJOBS_LINE_COUNT)
    SELECT 
        job_name    as GJBJOBS_NAME,
        job_title   as GJBJOBS_TITLE,
        SYSDATE     as GJBJOBS_ACTIVITY_DATE,
        'S'         as GJBJOBS_SYSI_CODE, -- H=HR(Payroll), F=Finance, T=AcctRecv, S=Student
        'S'         as GJBJOBS_JOB_TYPE_IND, -- (S)tored Procedure, Scri(P)t, Pro*(C), (E)xecutable, (R)eport, (J)ava
        job_desc    as GJBJOBS_DESC,
        'DATABASE'  as GJBJOBS_PRNT_CODE, -- Default printer code (usually DATABASE)
        60          as GJBJOBS_LINE_COUNT -- Lines per page
    FROM DUAL;

    -----------------------------------------------------------------------------
    -- GUBOBJS - Job object
    -----------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('GUBOBJS');

    DELETE FROM general.gubobjs WHERE gubobjs_name = job_name;

    INSERT INTO GENERAL.GUBOBJS (
        GUBOBJS_NAME,
        GUBOBJS_DESC,
        GUBOBJS_OBJT_CODE,
        GUBOBJS_SYSI_CODE,
        GUBOBJS_USER_ID,
        GUBOBJS_ACTIVITY_DATE,
        GUBOBJS_HELP_IND,
        GUBOBJS_EXTRACT_ENABLED_IND,
        GUBOBJS_UI_VERSION,
        GUBOBJS_INTEGRATED_MENU_IND,
        GUBOBJS_PERSIST_PROFILE_IND)
    SELECT 
        job_name    AS GUBOBJS_NAME,
        job_desc    AS GUBOBJS_DESC,
        'JOBS'      AS GUBOBJS_OBJT_CODE,
        'S'         AS GUBOBJS_SYSI_CODE,   -- F=Finance, S=Student, R=Financial Aid, H=HR/Payroll, T=AcctRecv
        'LOCAL'     AS GUBOBJS_USER_ID,
        SYSDATE     AS GUBOBJS_ACTIVITY_DATE,
        'N'         AS GUBOBJS_HELP_IND, -- Help Files (Y/N)
        'N'         AS GUBOBJS_EXTRACT_ENABLED_IND, -- Extract to CSV: (D)ata block only, (B)oth key block and data block, (N)ot available
        'B'         AS GUBOBJS_UI_VERSION, -- B=Banner (as opposed to Horizon)
        'Y'         AS GUBOBJS_INTEGRATED_MENU_IND, -- Y=Put it on the Application Navigator menu (defaults to N)
        'N'         AS GUBOBJS_PERSIST_PROFILE_IND  -- Y=User Preference Functionality is ON (defaults to N)
    FROM DUAL;

    -----------------------------------------------------------------------------
    -- GURAOBJ - Current version number of Job Object
    -----------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('GURAOBJ');

    DELETE FROM bansecr.guraobj WHERE guraobj_object = job_name;
    
    INSERT INTO BANSECR.GURAOBJ (
        GURAOBJ_OBJECT,
        GURAOBJ_DEFAULT_ROLE,
        GURAOBJ_CURRENT_VERSION,
        GURAOBJ_SYSI_CODE,
        GURAOBJ_ACTIVITY_DATE)
    SELECT
        job_name          as GURAOBJ_OBJECT,
        'BAN_DEFAULT_M'   as GURAOBJ_DEFAULT_ROLE,
        '8.0'             as GURAOBJ_CURRENT_VERSION, -- Major Banner Revision
        'T'               as GURAOBJ_SYSI_CODE,  -- (F)inance, H=HR/Payroll, T=AcctRecv
        SYSDATE           as GURAOBJ_ACTIVITY_DATE
    FROM DUAL;

    -----------------------------------------------------------------------------
    -- GURUOBJ - Security class
    -----------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('GURUBOJ');

    DELETE FROM bansecr.guruobj WHERE guruobj_object = job_name;

    INSERT INTO BANSECR.GURUOBJ (
        GURUOBJ_OBJECT,
        GURUOBJ_ROLE,
        GURUOBJ_USERID,
        GURUOBJ_ACTIVITY_DATE)
    SELECT 
        job_name          as GURUOBJ_OBJECT,
        'BAN_DEFAULT_M'   as GURUOBJ_ROLE,
        'BAN_GENERAL_C'   as GURUOBJ_USERID, -- Class of users that can run this job: BAN_GENERAL_C, BAN_PAYROLL_C
        SYSDATE           as GURUOBJ_ACTIVITY_DATE
    FROM DUAL;

    -----------------------------------------------------------------------------
    -- GJBPDEF - Job parameters; one row per parameter
    -----------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('GJBPDEF');

    DELETE FROM general.gjbpdef WHERE gjbpdef_job = job_name;

    DBMS_OUTPUT.PUT_LINE('GJBPDEF - Parameter 01: Popsel Selection Identifier');
    INSERT INTO GENERAL.GJBPDEF (
        GJBPDEF_JOB,
        GJBPDEF_NUMBER,
        GJBPDEF_DESC,
        GJBPDEF_LENGTH,
        GJBPDEF_TYPE_IND,
        GJBPDEF_OPTIONAL_IND,
        GJBPDEF_SINGLE_IND,
        GJBPDEF_ACTIVITY_DATE,
        GJBPDEF_LOW_RANGE,
        GJBPDEF_HIGH_RANGE,
        GJBPDEF_HELP_TEXT,
        GJBPDEF_VALIDATION,
        GJBPDEF_LIST_VALUES)
    SELECT
        job_name        AS GJBPDEF_JOB,
        '01'            AS GJBPDEF_NUMBER,
        'Popsel Selection ID' AS GJBPDEF_DESC,     -- Description of parameter (30 chars max)
        30              AS GJBPDEF_LENGTH,         -- Maximum length of parameter value
        'C'             AS GJBPDEF_TYPE_IND,       -- (C)haracter, (D)ate, (I)nteger or (N)umber
        'R'             AS GJBPDEF_OPTIONAL_IND,   -- (O)ptional or (R)equired
        'S'             AS GJBPDEF_SINGLE_IND,     -- (S)ingle or (M)ultiple times
        SYSDATE         AS GJBPDEF_ACTIVITY_DATE,  -- Date this row was created/updated
        NULL            AS GJBPDEF_LOW_RANGE,      -- Low range boundry for this parameter
        NULL            AS GJBPDEF_HIGH_RANGE,     -- High range boundry for this parameter
        'Name of the Popsel'
                        AS GJBPDEF_HELP_TEXT,      -- Long description (78 char max)
        NULL            AS GJBPDEF_VALIDATION,     -- Parameter level validation label to be performed when job is submitted through the Job Submission system.
        NULL            AS GJBPDEF_LIST_VALUES     -- Name of form to call for List of Values (LOV)
    FROM DUAL;

    DBMS_OUTPUT.PUT_LINE('GJBPDEF - Parameter 02: Popsel Application Code');
    INSERT INTO GENERAL.GJBPDEF (
        GJBPDEF_JOB,
        GJBPDEF_NUMBER,
        GJBPDEF_DESC,
        GJBPDEF_LENGTH,
        GJBPDEF_TYPE_IND,
        GJBPDEF_OPTIONAL_IND,
        GJBPDEF_SINGLE_IND,
        GJBPDEF_ACTIVITY_DATE,
        GJBPDEF_LOW_RANGE,
        GJBPDEF_HIGH_RANGE,
        GJBPDEF_HELP_TEXT,
        GJBPDEF_VALIDATION,
        GJBPDEF_LIST_VALUES)
    SELECT
        job_name        AS GJBPDEF_JOB,
        '02'            AS GJBPDEF_NUMBER,
        'Popsel Application Code'
                        AS GJBPDEF_DESC,           -- Description of parameter
        30              AS GJBPDEF_LENGTH,         -- Maximum length of parameter value
        'C'             AS GJBPDEF_TYPE_IND,       -- (C)haracter, (D)ate, (I)nteger or (N)umber
        'R'             AS GJBPDEF_OPTIONAL_IND,   -- (O)ptional or (R)equired
        'S'             AS GJBPDEF_SINGLE_IND,     -- (S)ingle or (M)ultiple times
        SYSDATE         AS GJBPDEF_ACTIVITY_DATE,  -- Date this row was created/updated
        NULL            AS GJBPDEF_LOW_RANGE,      -- Low range boundry for this parameter
        NULL            AS GJBPDEF_HIGH_RANGE,     -- High range boundry for this parameter
        'Application code of the Popsel'  
                        AS GJBPDEF_HELP_TEXT,      -- Long description (78 char max)
        NULL            AS GJBPDEF_VALIDATION,     -- Parameter level validation label to be performed when job is submitted through the Job Submission system.
        NULL            AS GJBPDEF_LIST_VALUES     -- Name of form to call for List of Values (LOV)
    FROM DUAL;

    DBMS_OUTPUT.PUT_LINE('GJBPDEF - Parameter 03: Creator ID');
    INSERT INTO GENERAL.GJBPDEF (
        GJBPDEF_JOB,
        GJBPDEF_NUMBER,
        GJBPDEF_DESC,
        GJBPDEF_LENGTH,
        GJBPDEF_TYPE_IND,
        GJBPDEF_OPTIONAL_IND,
        GJBPDEF_SINGLE_IND,
        GJBPDEF_ACTIVITY_DATE,
        GJBPDEF_LOW_RANGE,
        GJBPDEF_HIGH_RANGE,
        GJBPDEF_HELP_TEXT,
        GJBPDEF_VALIDATION,
        GJBPDEF_LIST_VALUES)
    SELECT
        job_name        AS GJBPDEF_JOB,
        '03'            AS GJBPDEF_NUMBER,
        'Popsel Creator ID'
                        AS GJBPDEF_DESC,           -- Description of parameter
        30              AS GJBPDEF_LENGTH,         -- Maximum length of parameter value
        'C'             AS GJBPDEF_TYPE_IND,       -- (C)haracter, (D)ate, (I)nteger or (N)umber
        'R'             AS GJBPDEF_OPTIONAL_IND,   -- (O)ptional or (R)equired
        'S'             AS GJBPDEF_SINGLE_IND,     -- (S)ingle or (M)ultiple times
        SYSDATE         AS GJBPDEF_ACTIVITY_DATE,  -- Date this row was created/updated
        NULL            AS GJBPDEF_LOW_RANGE,      -- Low range boundry for this parameter
        NULL            AS GJBPDEF_HIGH_RANGE,     -- High range boundry for this parameter
        'User ID of the person who created the Popsel'
                        AS GJBPDEF_HELP_TEXT,      -- Long description (78 char max)
        NULL            AS GJBPDEF_VALIDATION,     -- Parameter level validation label to be performed when job is submitted through the Job Submission system.
        NULL            AS GJBPDEF_LIST_VALUES     -- Name of form to call for List of Values (LOV)
    FROM DUAL;

    DBMS_OUTPUT.PUT_LINE('GJBPDEF - Parameter 04: Attribute Code');
    INSERT INTO GENERAL.GJBPDEF (
        GJBPDEF_JOB,
        GJBPDEF_NUMBER,
        GJBPDEF_DESC,
        GJBPDEF_LENGTH,
        GJBPDEF_TYPE_IND,
        GJBPDEF_OPTIONAL_IND,
        GJBPDEF_SINGLE_IND,
        GJBPDEF_ACTIVITY_DATE,
        GJBPDEF_LOW_RANGE,
        GJBPDEF_HIGH_RANGE,
        GJBPDEF_HELP_TEXT,
        GJBPDEF_VALIDATION,
        GJBPDEF_LIST_VALUES)
    SELECT
        job_name        AS GJBPDEF_JOB,
        '04'            AS GJBPDEF_NUMBER,
        'Student Attribute Code'
                        AS GJBPDEF_DESC,           -- Description of parameter
        4               AS GJBPDEF_LENGTH,         -- Maximum length of parameter value
        'C'             AS GJBPDEF_TYPE_IND,       -- (C)haracter, (D)ate, (I)nteger or (N)umber
        'R'             AS GJBPDEF_OPTIONAL_IND,   -- (O)ptional or (R)equired
        'S'             AS GJBPDEF_SINGLE_IND,     -- (S)ingle or (M)ultiple times
        SYSDATE         AS GJBPDEF_ACTIVITY_DATE,  -- Date this row was created/updated
        NULL            AS GJBPDEF_LOW_RANGE,      -- Low range boundry for this parameter
        NULL            AS GJBPDEF_HIGH_RANGE,     -- High range boundry for this parameter
        'Student attribute code to add'  
                        AS GJBPDEF_HELP_TEXT,      -- Long description (78 char max)
        NULL            AS GJBPDEF_VALIDATION,     -- Parameter level validation label to be performed when job is submitted through the Job Submission system.
        'STVATTS'       AS GJBPDEF_LIST_VALUES     -- Name of form to call for List of Values (LOV)
    FROM DUAL;

    DBMS_OUTPUT.PUT_LINE('GJBPDEF - Parameter 05: Effective Term');
    INSERT INTO GENERAL.GJBPDEF (
        GJBPDEF_JOB,
        GJBPDEF_NUMBER,
        GJBPDEF_DESC,
        GJBPDEF_LENGTH,
        GJBPDEF_TYPE_IND,
        GJBPDEF_OPTIONAL_IND,
        GJBPDEF_SINGLE_IND,
        GJBPDEF_ACTIVITY_DATE,
        GJBPDEF_LOW_RANGE,
        GJBPDEF_HIGH_RANGE,
        GJBPDEF_HELP_TEXT,
        GJBPDEF_VALIDATION,
        GJBPDEF_LIST_VALUES)
    SELECT
        job_name        AS GJBPDEF_JOB,
        '05'            AS GJBPDEF_NUMBER,
        'Effective Term'AS GJBPDEF_DESC,           -- Description of parameter
        6               AS GJBPDEF_LENGTH,         -- Maximum length of parameter value
        'C'             AS GJBPDEF_TYPE_IND,       -- (C)haracter, (D)ate, (I)nteger or (N)umber
        'R'             AS GJBPDEF_OPTIONAL_IND,   -- (O)ptional or (R)equired
        'S'             AS GJBPDEF_SINGLE_IND,     -- (S)ingle or (M)ultiple times
        SYSDATE         AS GJBPDEF_ACTIVITY_DATE,  -- Date this row was created/updated
        NULL            AS GJBPDEF_LOW_RANGE,      -- Low range boundry for this parameter
        NULL            AS GJBPDEF_HIGH_RANGE,     -- High range boundry for this parameter
        'Effective term code of the attribute being added'  
                        AS GJBPDEF_HELP_TEXT,      -- Long description (78 char max)
        NULL            AS GJBPDEF_VALIDATION,     -- Parameter level validation label to be performed when job is submitted through the Job Submission system.
        'STVTERM '      AS GJBPDEF_LIST_VALUES     -- Name of form to call for List of Values (LOV)
    FROM DUAL;

    DBMS_OUTPUT.PUT_LINE('GJBPDEF - Parameter 06: Audit/Update Indicator');
    INSERT INTO GENERAL.GJBPDEF (
        GJBPDEF_JOB,
        GJBPDEF_NUMBER,
        GJBPDEF_DESC,
        GJBPDEF_LENGTH,
        GJBPDEF_TYPE_IND,
        GJBPDEF_OPTIONAL_IND,
        GJBPDEF_SINGLE_IND,
        GJBPDEF_ACTIVITY_DATE,
        GJBPDEF_LOW_RANGE,
        GJBPDEF_HIGH_RANGE,
        GJBPDEF_HELP_TEXT,
        GJBPDEF_VALIDATION,
        GJBPDEF_LIST_VALUES)
    SELECT
        job_name        AS GJBPDEF_JOB,
        '06'            AS GJBPDEF_NUMBER,
        'Audit/Update Indicator' 
                        as GJBPDEF_DESC,           -- Description of parameter
        1               as GJBPDEF_LENGTH,         -- Maximum length of parameter value
        'C'             as GJBPDEF_TYPE_IND,       -- (C)haracter, (D)ate, (I)nteger or (N)umber
        'O'             as GJBPDEF_OPTIONAL_IND,   -- (O)ptional or (R)equired
        'S'             as GJBPDEF_SINGLE_IND,     -- (S)ingle or (M)ultiple times
        SYSDATE         as GJBPDEF_ACTIVITY_DATE,  -- Date this row was created/updated
        NULL            as GJBPDEF_LOW_RANGE,      -- Low range boundry for this parameter
        NULL            as GJBPDEF_HIGH_RANGE,     -- High range boundry for this parameter
        'A=Audit (rollback), U=Update (commit); Default value is "A"'  
                        as GJBPDEF_HELP_TEXT,      -- Long description (78 char max)
        NULL            as GJBPDEF_VALIDATION,     -- Parameter level validation label to be performed when job is submitted through the Job Submission system.
        NULL            as GJBPDEF_LIST_VALUES     -- Name of form to call for List of Values (LOV)
    FROM DUAL;
    
    -----------------------------------------------------------------------------
    -- GJBPDFT - Job parameter defaults
    -- Need one row per parameter with user id set to NULL
    -----------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('GJBPDFT');

    DELETE FROM general.gjbpdft WHERE gjbpdft_job = job_name;

    DBMS_OUTPUT.PUT_LINE('GJBPDFT - Parameter 01: Popsel Selection Identifier');
    INSERT INTO GENERAL.GJBPDFT (
        GJBPDFT_JOB,
        GJBPDFT_NUMBER,
        GJBPDFT_ACTIVITY_DATE,
        GJBPDFT_USER_ID,
        GJBPDFT_VALUE)
    SELECT 
        job_name    AS GJBPDFT_JOB,            -- Job name
        '01'        AS GJBPDFT_NUMBER,         -- Parameter number
        SYSDATE     AS GJBPDFT_ACTIVITY_DATE,  -- Row creation/update date
        NULL        AS GJBPDFT_USER_ID,        -- User ID associated with this param.  Must be NULL initially.
        NULL        AS GJBPDFT_VALUE           -- Default value
    FROM DUAL;
    
    DBMS_OUTPUT.PUT_LINE('GJBPDFT - Parameter 02: Popsel Application Code');
    INSERT INTO GENERAL.GJBPDFT (
        GJBPDFT_JOB,
        GJBPDFT_NUMBER,
        GJBPDFT_ACTIVITY_DATE,
        GJBPDFT_USER_ID,
        GJBPDFT_VALUE)
    SELECT 
        job_name    AS GJBPDFT_JOB,            -- Job name
        '02'        AS GJBPDFT_NUMBER,         -- Parameter number
        SYSDATE     AS GJBPDFT_ACTIVITY_DATE,  -- Row creation/update date
        NULL        AS GJBPDFT_USER_ID,        -- User ID associated with this param.  Must be NULL initially.
        NULL        AS GJBPDFT_VALUE           -- Default value
    FROM DUAL;

    DBMS_OUTPUT.PUT_LINE('GJBPDFT - Parameter 03: Creator ID');
    INSERT INTO GENERAL.GJBPDFT (
        GJBPDFT_JOB,
        GJBPDFT_NUMBER,
        GJBPDFT_ACTIVITY_DATE,
        GJBPDFT_USER_ID,
        GJBPDFT_VALUE)
    SELECT 
        job_name    AS GJBPDFT_JOB,            -- Job name
        '03'        AS GJBPDFT_NUMBER,         -- Parameter number
        SYSDATE     AS GJBPDFT_ACTIVITY_DATE,  -- Row creation/update date
        NULL        AS GJBPDFT_USER_ID,        -- User ID associated with this param.  Must be NULL initially.
        NULL        AS GJBPDFT_VALUE           -- Default value
    FROM DUAL;

    DBMS_OUTPUT.PUT_LINE('GJBPDFT - Parameter 04: Attribute Code');
    INSERT INTO GENERAL.GJBPDFT (
        GJBPDFT_JOB,
        GJBPDFT_NUMBER,
        GJBPDFT_ACTIVITY_DATE,
        GJBPDFT_USER_ID,
        GJBPDFT_VALUE)
    SELECT 
        job_name    AS GJBPDFT_JOB,            -- Job name
        '04'        AS GJBPDFT_NUMBER,         -- Parameter number
        SYSDATE     AS GJBPDFT_ACTIVITY_DATE,  -- Row creation/update date
        NULL        AS GJBPDFT_USER_ID,        -- User ID associated with this param.  Must be NULL initially.
        NULL        AS GJBPDFT_VALUE           -- Default value
    FROM DUAL;

    DBMS_OUTPUT.PUT_LINE('GJBPDFT - Parameter 05: Effective Term');
    INSERT INTO GENERAL.GJBPDFT (
        GJBPDFT_JOB,
        GJBPDFT_NUMBER,
        GJBPDFT_ACTIVITY_DATE,
        GJBPDFT_USER_ID,
        GJBPDFT_VALUE)
    SELECT 
        job_name    AS GJBPDFT_JOB,            -- Job name
        '05'        AS GJBPDFT_NUMBER,         -- Parameter number
        SYSDATE     AS GJBPDFT_ACTIVITY_DATE,  -- Row creation/update date
        NULL        AS GJBPDFT_USER_ID,        -- User ID associated with this param.  Must be NULL initially.
        NULL        AS GJBPDFT_VALUE           -- Default value
    FROM DUAL;

    DBMS_OUTPUT.PUT_LINE('GJBPDFT - Parameter 06: Audit/Update Indicator');
    INSERT INTO GENERAL.GJBPDFT (
        GJBPDFT_JOB,
        GJBPDFT_NUMBER,
        GJBPDFT_ACTIVITY_DATE,
        GJBPDFT_USER_ID,
        GJBPDFT_VALUE)
    SELECT 
        job_name    AS GJBPDFT_JOB,            -- Job name
        '06'        AS GJBPDFT_NUMBER,         -- Parameter number
        SYSDATE     AS GJBPDFT_ACTIVITY_DATE,  -- Row creation/update date
        NULL        AS GJBPDFT_USER_ID,        -- User ID associated with this param.  Must be NULL initially.
        'A'         AS GJBPDFT_VALUE           -- Default value
    FROM DUAL;

    -----------------------------------------------------------------------------
    -- GRANTS
    -----------------------------------------------------------------------------
    EXECUTE IMMEDIATE 'grant execute on oitutil.MyTableType to public';
    EXECUTE IMMEDIATE 'grant execute on oitutil.str2tbl to public';
    
    -----------------------------------------------------------------------------
    -- THE END 
    -----------------------------------------------------------------------------
   
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUCCESS');
   
EXCEPTION
    WHEN OTHERS
    THEN
        DBMS_OUTPUT.PUT_LINE ('!!! SETUP ERROR !!!');
        DBMS_OUTPUT.PUT_LINE ('Error code: ' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE ('Error mesg: ' || SUBSTR(SQLERRM, 1, 200));
        ROLLBACK;
END;
/
