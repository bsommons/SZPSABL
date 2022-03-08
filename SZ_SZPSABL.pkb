CREATE OR REPLACE PACKAGE BODY baninst1.sz_szpsabl
AS
    /* Copyright Ellucian */
    /* This software is supplied as-is, with all defects, and without warranty
       of any kind.

    Ellucian further disclaims all implied warranties including
    any implied warranties of merchantability or of fitness for a particular
    purpose or that the software is hack proof, bug-free or will operate without
    interruption.  The entire risk arising out of the use of the software and
    documentation remains with you.  In no event shall Ellucian
    or anyone involved in the creation or documentation of the software be
    liable for any damages whatsoever, whether arising in tort or contract, and
    including, without limitation, special, consequential or incidental damages,
    or damages for loss of business profits, interruption of business activity,
    loss of business information, or other damages or monetary loss arising out
    of the sale,  license, possession, use or inability to use the software or
    documentation. You agree not to obtain or use the software in any state or
    country that does not allow the full exclusion or limitation of liability as
    set forth above, and if you do so, you agree by your use of the software to
    waive any claims which otherwise would be excluded or limited.
    Unless otherwise specifically agreed to by Ellucian, Ellucian
    shall have no duty or obligation to update, enhance,
    improve, modify or otherwise maintain or support the software or
    documentation (collectively referred to as "enhancements").  Ellucian Higher
    Education may, but is not obligated to, distribute enhancements to the
    software and documentation to you.  If you modify the software you shall be
    solely responsible for such modifications and the effect such modifications
    has on the performance of the software.  Ellucian reserves
    all rights in the software, and to any enhancements or modifications to the
    software, including any made by you. */

    /******************************************************************************
    NAME:       SZ_SZPSABL.pkb (Student Attribute Batch Load)

    PURPOSE:    Batch load student attributes into Banner using a file or PopSel.

    Ver         Date        Author          Description
    ---------   ----------  --------------  ------------------------------------
    1.0         10/18/2021  Kevin Klob      Initial Creation
    ******************************************************************************/

    -----------------------------------------------------------------------------
    -- This is the driving procedure for reading the file and updating Banner
    -----------------------------------------------------------------------------
    PROCEDURE p_process (one_up_no_in IN NUMBER)
    IS
        job_name                CONSTANT VARCHAR2(8) := 'SZPSABL';
        version_str             CONSTANT VARCHAR2(10) := '1.0';
        rpt_file_lis            z_jobsub_utility.rpt_file_type;
        dict                    oitutil.assoc_array := oitutil.assoc_array();

        infile_dir              VARCHAR2(100) := 'DATAHOME_STUDENT';
        infile_name             VARCHAR2(100);
        infile_name_full        VARCHAR2(200);
        
        p01_popsel_select       VARCHAR2(100);
        p02_popsel_applic       VARCHAR2(100);
        p03_popsel_creator      VARCHAR2(100);
        p04_attribute_code      VARCHAR2(100);
        p05_effective_term      VARCHAR2(100);
        p06_auditupdate         VARCHAR2(100);
        p06_auditupdate_desc    VARCHAR2(100);

        rec_count_total         PLS_INTEGER := 0;
        rec_count_updated       PLS_INTEGER := 0;
        rec_count_errors        PLS_INTEGER := 0;

        error_msg               VARCHAR2(1000);
        loop_error              EXCEPTION;
        loop_warning            EXCEPTION;
        app_error               EXCEPTION;

        ----------------------------------------------------------------------------
        -- Population Selection Types
        ----------------------------------------------------------------------------
        -- Using a virtual table to store ID's instead of a CURSOR.
        -- Reason: The original design included the ability to read ID's from either a Popsel or a file.
        -- Since you can't use a cursor to read from a file, a common collection set was needed.
        TYPE population_rec_t IS RECORD (
            pidm        NUMBER,
            bronc_id    VARCHAR2(9)
        );
        TYPE population_table_t IS TABLE OF population_rec_t;
        population_table population_table_t;

        TYPE popsel_t IS RECORD (
            application  general.glbslct.glbslct_application%TYPE,
            selection    general.glbslct.glbslct_selection%TYPE,
            creator_id   general.glbslct.glbslct_creator_id%TYPE,
            user_id      general.glbslct.glbslct_user_id%TYPE
        );
        popsel popsel_t;

        ----------------------------------------------------------------------------
        -- Write a blank line to the LOG file
        ----------------------------------------------------------------------------
        PROCEDURE write_log_nl IS
        BEGIN
            dbms_output.put(CHR(10)); -- New line char in Linux
        END write_log_nl;
        
        ----------------------------------------------------------------------------
        -- Write a blank line to the LIS file
        ----------------------------------------------------------------------------
        PROCEDURE write_lis_nl IS
        BEGIN
            z_jobsub_utility.write_report_line (rpt_file_lis, '');
        END write_lis_nl;
        
        ----------------------------------------------------------------------------
        -- Write a line of text to the LOG file
        ----------------------------------------------------------------------------
        PROCEDURE write_log_line (line VARCHAR2) IS
            tab oitutil.MyTableType := oitutil.str2tbl(line, CHR(10));
        BEGIN
            -- Break on line feed char
            FOR i IN 1 .. tab.COUNT LOOP
                dbms_output.put_line(tab(i));
            END LOOP;
        END write_log_line;
        
        ----------------------------------------------------------------------------
        -- Write a line of text to the LIS file
        ----------------------------------------------------------------------------
        PROCEDURE write_lis_line (line VARCHAR2) IS
            tab oitutil.MyTableType := oitutil.str2tbl(line, CHR(10));
        BEGIN
            -- Break on line feed char
            FOR i IN 1 .. tab.COUNT LOOP
                z_jobsub_utility.write_report_line (rpt_file_lis, tab(i));
            END LOOP;
        END write_lis_line;
        
        ----------------------------------------------------------------------------
        -- Write a generic error message to the LOG file
        ----------------------------------------------------------------------------
        PROCEDURE write_log_error (line VARCHAR2) IS
        BEGIN
            write_log_line('***** ERROR: ' || line);
        END write_log_error;

        ----------------------------------------------------------------------------
        -- Write a generic error message to the LIS file
        ----------------------------------------------------------------------------
        PROCEDURE write_lis_error (line VARCHAR2) IS
        BEGIN
            write_lis_line('***** ERROR: ' || line);
        END write_lis_error;

        --------------------------------------------------------------------------
        -- Create the metrics file (.lis)
        --------------------------------------------------------------------------
        PROCEDURE create_lisfile (filename VARCHAR2) IS
        BEGIN
            --rpt_file_lis.one_up_no := job_nbr; -- Not needed
            rpt_file_lis.file_name := filename;
            rpt_file_lis.file_number := 0;
            rpt_file_lis.max_lines := 0;
            rpt_file_lis.seq_no := 0;
            rpt_file_lis.page_no := 0;
            rpt_file_lis.total_lines := 0;
            rpt_file_lis.line_width := NULL;
            rpt_file_lis.run_date := SYSDATE;
            rpt_file_lis.title_1 := job_name || ' - Student Attribute Batch Load - ' || version_str;
            rpt_file_lis.title_2 := NULL;
            rpt_file_lis.institution_name := NULL;
            rpt_file_lis.column_head := NULL;
            rpt_file_lis.column_head_2 := NULL;
            
            z_jobsub_utility.create_file_header(rpt_file_lis);
            z_jobsub_utility.write_page_header (rpt_file_lis);
        END create_lisfile;
        
        --------------------------------------------------------------------------
        -- Write the report header line to the log file
        --------------------------------------------------------------------------
        PROCEDURE write_lis_report_hdr IS
        BEGIN
            write_lis_nl;
            write_lis_line(UTL_LMS.format_message(
                '%s  %s  %s',
                RPAD('BRONC_ID',    9),     -- Student ID
                RPAD('PIDM',        8),     -- Student PIDM
                RPAD('LOAD_STATUS', 11)));   -- Banner Update Status
        END write_lis_report_hdr;

        --------------------------------------------------------------------------
        -- Write the report detail line to the lis file
        --------------------------------------------------------------------------
        PROCEDURE write_lis_report_dtl (
            pop_rec     population_rec_t, 
            status_msg  VARCHAR2) IS
        BEGIN
            write_lis_line(UTL_LMS.format_message(
                '%s  %s  %s',
                RPAD(NVL(pop_rec.bronc_id,' '), 9),
                RPAD(NVL(TO_CHAR(pop_rec.pidm),' '), 8),
                status_msg));
        END write_lis_report_dtl;

        --------------------------------------------------------------------------
        -- Write the attribute sets of the given PIDM to the log file
        --------------------------------------------------------------------------
        PROCEDURE write_log_attr (
            i_pidm      NUMBER, 
            i_eff_term  VARCHAR2) 
        IS
            eff_term    sgrsatt.sgrsatt_term_code_eff%TYPE;
            end_term    sgrsatt.sgrsatt_end_term_ethos%TYPE;
            attr_list   VARCHAR2(500);
            rec_count   NUMBER := 0;
            
            -- Used for displaying attribute sets for the previous term and all future terms
            CURSOR cur IS
                SELECT  *
                FROM    (   -- Summary of all attribute sets for this PIDM
                            SELECT  sgrsatt_pidm,
                                    sgrsatt_term_code_eff,
                                    sgrsatt_end_term_ethos,
                                    LISTAGG(sgrsatt_atts_code,',') WITHIN GROUP (ORDER BY sgrsatt_atts_code) AS attr_list,
                                    DENSE_RANK() OVER (ORDER BY sgrsatt_term_code_eff) AS set_nbr
                            FROM    sgrsatt
                            WHERE   sgrsatt_pidm = i_pidm
                            GROUP BY sgrsatt_pidm, sgrsatt_term_code_eff, sgrsatt_end_term_ethos
                        ) a
                WHERE   sgrsatt_term_code_eff IN (
                            -- Include prior term, current term, and all future terms
                            SELECT  sgrsatt_term_code_eff
                            FROM    sgrsatt
                            WHERE   sgrsatt_pidm = a.sgrsatt_pidm
                            AND     sgrsatt_end_term_ethos >= i_eff_term) -- Prior term record will have an end term set to current term
                ORDER BY sgrsatt_pidm, sgrsatt_term_code_eff;
        BEGIN
            FOR rec IN cur LOOP
                rec_count := rec_count + 1;
                write_log_line(UTL_LMS.format_message(
                    '(%s) %s-%s: %s',
                    LPAD(rec.set_nbr, 2, '0'),
                    rec.sgrsatt_term_code_eff,
                    rec.sgrsatt_end_term_ethos,
                    rec.attr_list));
            END LOOP;

            IF rec_count = 0 THEN
                write_log_line('(xx) NONE');
            END IF;
        END write_log_attr;

        --------------------------------------------------------------------------
        -- Return TRUE if the given student attribute is valid
        --------------------------------------------------------------------------
        FUNCTION valid_attribute_code (i_attr VARCHAR2) RETURN BOOLEAN IS
            row_count NUMBER;
        BEGIN
            SELECT  COUNT(*)
            INTO    row_count
            FROM    stvatts
            WHERE   stvatts_code = i_attr;
            RETURN row_count > 0;
        END valid_attribute_code;

        --------------------------------------------------------------------------
        -- Return TRUE if the given term is valid
        --------------------------------------------------------------------------
        FUNCTION valid_term (i_term VARCHAR2) RETURN BOOLEAN IS
            row_count NUMBER;
        BEGIN
            SELECT  COUNT(*)
            INTO    row_count
            FROM    stvterm
            WHERE   stvterm_code = i_term;
            RETURN row_count > 0;
        END valid_term;

        --------------------------------------------------------------------------
        -- Return TRUE if the given popsel exists
        --------------------------------------------------------------------------
        FUNCTION valid_popsel (i_popsel popsel_t) RETURN BOOLEAN IS
            row_count NUMBER;
        BEGIN
            SELECT  COUNT(*)
            INTO    row_count
            FROM    glbslct
            WHERE   glbslct_application = i_popsel.application
            AND     glbslct_selection   = i_popsel.selection
            AND     glbslct_creator_id  = i_popsel.creator_id;
            RETURN row_count > 0;
        END valid_popsel;

        --------------------------------------------------------------------------
        -- Return list of people for the given popsel
        --------------------------------------------------------------------------
        FUNCTION get_popsel (i_popsel popsel_t) RETURN population_table_t IS
            pop_rec     population_rec_t;
            pop_table   population_table_t := population_table_t();
            CURSOR c_popsel
            IS
                SELECT  TO_NUMBER(glbextr_key) AS pidm,
                        spriden_id AS bronc_id
                FROM    glbextr
                JOIN    spriden ON spriden_pidm = glbextr_key AND spriden_change_ind IS NULL
                WHERE   glbextr_application = i_popsel.application
                AND     glbextr_selection   = i_popsel.selection
                AND     glbextr_creator_id  = i_popsel.creator_id
                AND     glbextr_user_id     = i_popsel.user_id
                ORDER   BY spriden_id;
        BEGIN
            FOR cur_rec IN c_popsel LOOP -- Fill list
                pop_table.EXTEND;
                pop_rec.pidm := cur_rec.pidm;
                pop_rec.bronc_id := cur_rec.bronc_id;
                pop_table(pop_table.COUNT) := pop_rec;
            END LOOP;
            RETURN pop_table;
        END get_popsel;
        
        --------------------------------------------------------------------------
        -- Copy SGRSATT attributes from previous term if they overlap this term
        --------------------------------------------------------------------------
        -- It is important to copy attributes before adding new ones because adding a new
        -- attribute changes the end term of the previous term.  We need to check the
        -- original end term of previous attributes to decide if they should be copied.
        --------------------------------------------------------------------------
        PROCEDURE sgrsatt_copy_attr (
            i_pidm      NUMBER, 
            i_eff_term  VARCHAR2) 
        IS
            v_prev_eff_term  sgrsatt.sgrsatt_term_code_eff%TYPE;

            -- Previous active effective term
            CURSOR c_prev IS
                SELECT  MAX(sgrsatt_term_code_eff)
                FROM    sgrsatt
                WHERE   sgrsatt_pidm = i_pidm
                AND     sgrsatt_term_code_eff  < i_eff_term
                AND     sgrsatt_end_term_ethos > i_eff_term;
        BEGIN
            OPEN  c_prev;
            FETCH c_prev INTO v_prev_eff_term;
            CLOSE c_prev;

            MERGE INTO sgrsatt s
            USING (
                    -- Attributes for previous effective terms that need copying
                    SELECT  * 
                    FROM    sgrsatt a
                    WHERE   sgrsatt_pidm = i_pidm
                    AND     sgrsatt_term_code_eff = v_prev_eff_term
                ) u
            ON  (
                    -- Does the attribute for the previous term exist in the given term?
                    s.sgrsatt_pidm = u.sgrsatt_pidm AND
                    s.sgrsatt_atts_code = u.sgrsatt_atts_code AND
                    s.sgrsatt_term_code_eff = i_eff_term
                )
            WHEN NOT MATCHED THEN
                -- The attribute doesn't exist yet for the given term.  Add it.  Let the database triggers figure out the end term.
                INSERT (
                    sgrsatt_pidm,           sgrsatt_term_code_eff,  sgrsatt_atts_code, 
                    sgrsatt_activity_date,  sgrsatt_user_id,        sgrsatt_data_origin) 
                VALUES (
                    u.sgrsatt_pidm,         i_eff_term,             u.sgrsatt_atts_code,
                    SYSDATE,                USER,                   job_name);
        EXCEPTION
            WHEN OTHERS THEN
                error_msg := 'Failed to insert previous term attributes into SGRSATT: ' || SQLERRM;
                RAISE loop_error;
        END sgrsatt_copy_attr;

        --------------------------------------------------------------------------
        -- Insert attribute code into the SGRSATT table if doesn't already exist
        --------------------------------------------------------------------------
        PROCEDURE sgrsatt_add_attr (
            i_pidm      NUMBER, 
            i_eff_term  VARCHAR2,
            i_atts_code VARCHAR2) 
        IS
            -- Effective terms for which this attribute needs to be applied
            CURSOR c_eff_terms IS
                -- Target effective term
                SELECT  i_eff_term AS eff_term
                FROM    DUAL
                UNION
                -- Future effective terms
                SELECT  sgrsatt_term_code_eff AS eff_term
                FROM    sgrsatt 
                WHERE   sgrsatt_pidm = i_pidm
                AND     sgrsatt_term_code_eff > i_eff_term;
        BEGIN
            FOR rec IN c_eff_terms LOOP 
                BEGIN
                    MERGE INTO sgrsatt
                    USING (SELECT 1 FROM DUAL)
                    ON  (
                            -- Does the attribute exist for this term?
                            sgrsatt_pidm = i_pidm AND
                            sgrsatt_term_code_eff = rec.eff_term AND
                            sgrsatt_atts_code = i_atts_code
                        )
                    WHEN NOT MATCHED THEN
                        -- The attribute doesn't exist yet for this term.  Add it.  Let the database triggers figure out the end term.
                        INSERT (
                            sgrsatt_pidm,           sgrsatt_term_code_eff,  sgrsatt_atts_code, 
                            sgrsatt_activity_date,  sgrsatt_user_id,        sgrsatt_data_origin) 
                        VALUES (
                            i_pidm,                 rec.eff_term,           i_atts_code,
                            SYSDATE,                USER,                   job_name);
                EXCEPTION
                    WHEN OTHERS THEN
                        error_msg := 'Failed to insert attribute code into SGRSATT for ' || rec.eff_term || ': ' || SQLERRM;
                        RAISE loop_error;
                END;
            END LOOP;
        END sgrsatt_add_attr;

    ----------------------------------------------------------------------------------------------------------------------------

    BEGIN
        -- Retrieve parameters for BannerJob Submission
        p01_popsel_select   := z_jobsub_utility.get_jobsub_parm (job_name, one_up_no_in, '01');
        p02_popsel_applic   := z_jobsub_utility.get_jobsub_parm (job_name, one_up_no_in, '02');
        p03_popsel_creator  := z_jobsub_utility.get_jobsub_parm (job_name, one_up_no_in, '03');
        p04_attribute_code  := z_jobsub_utility.get_jobsub_parm (job_name, one_up_no_in, '04');
        p05_effective_term  := z_jobsub_utility.get_jobsub_parm (job_name, one_up_no_in, '05');
        p06_auditupdate     := UPPER(NVL(z_jobsub_utility.get_jobsub_parm (job_name, one_up_no_in, '06'), 'U')); -- Audit or Update
        p06_auditupdate_desc := CASE WHEN p06_auditupdate = 'U' THEN 'UPDATE' ELSE 'AUDIT' END;

        create_lisfile(LOWER(job_name) || '_' || one_up_no_in || '.lis');

        -- Show the parameter values in the log and lis files
        dict.clear;
        dict.add_pair('P01 Popsel Selection',   p01_popsel_select);
        dict.add_pair('P02 Popsel Application', p02_popsel_applic);
        dict.add_pair('P03 Popsel Creator ID',  p03_popsel_creator);
        dict.add_pair('P04 Attribute Code',     p04_attribute_code);
        dict.add_pair('P05 Effective Term',     p05_effective_term);
        dict.add_pair('P06 Audit/Update',       p06_auditupdate || ' (' || p06_auditupdate_desc || ')');
        write_log_line(dict.tabulate);
        write_log_nl;
        write_lis_line(dict.tabulate);
        write_lis_nl;

        -- Check for valid attribute code
        IF NOT valid_attribute_code(p04_attribute_code) THEN
            error_msg := 'Attribute code is not valid';
            RAISE app_error;
        END IF;

        -- Check for valid effective term
        IF NOT valid_term(p05_effective_term) THEN
            error_msg := 'Effective term is not valid';
            RAISE app_error;
        END IF;

        -- Initialize popsel
        popsel.application := p02_popsel_applic;
        popsel.selection   := p01_popsel_select;
        popsel.creator_id  := p03_popsel_creator;
        popsel.user_id     := USER;

        IF NOT valid_popsel(popsel) THEN
            error_msg := 'Popsel is not valid';
            RAISE app_error;
        END IF;

        dbms_output.put_line('Popsel is valid; getting PIDM list from popsel');
        population_table := get_popsel(popsel);
        IF population_table.COUNT = 0 THEN
            error_msg := 'Popsel is valid but no extract found for user ' || popsel.user_id;
            RAISE app_error;
        END IF;

        write_lis_report_hdr;

        FOR i IN 1..population_table.COUNT LOOP
            BEGIN
                rec_count_total := rec_count_total + 1;
                write_log_line('--------------------------------------------------------------------------------');
                write_log_line(UTL_LMS.format_message(
                    '[%s] ID=%s, PIDM=%s, TERM=%s, ATTR=%s',
                    TO_CHAR(rec_count_total),
                    population_table(i).bronc_id,
                    TO_CHAR(population_table(i).pidm),
                    p05_effective_term,
                    p04_attribute_code));
                
                IF population_table(i).pidm IS NULL THEN
                    error_msg := 'Invalid Student ID: No PIDM found';
                    RAISE loop_error;
                END IF;

                write_log_line('Attribute sets before update:');
                write_log_attr(population_table(i).pidm, p05_effective_term);

                sgrsatt_copy_attr(population_table(i).pidm, p05_effective_term);  -- See function comments to see why we copy first
                sgrsatt_add_attr(population_table(i).pidm, p05_effective_term, p04_attribute_code);

                write_log_line('Attribute sets after update:');
                write_log_attr(population_table(i).pidm, p05_effective_term);
                
                rec_count_updated := rec_count_updated + 1;
                write_log_line('Status: SUCCESS');
                write_lis_report_dtl(population_table(i), 'SUCCESS');
            EXCEPTION
                WHEN loop_error THEN
                    rec_count_errors := rec_count_errors + 1;
                    write_log_line('Status: ERROR: ' || error_msg);
                    write_lis_report_dtl(population_table(i), 'ERROR: ' || error_msg);
            END;
        END LOOP;

        write_log_nl;
        write_lis_nl;

        dict.clear;
        dict.add_pair('Total records',      rec_count_total);
        dict.add_pair('Records imported',   rec_count_updated);
        dict.add_pair('Records failed',     rec_count_errors);
        
        write_log_line(dict.tabulate);
        write_lis_line(dict.tabulate);

        IF p06_auditupdate = 'U' THEN
            COMMIT;
        ELSE
            ROLLBACK;
        END IF;

        write_log_nl;
        write_lis_nl;
        
        z_jobsub_utility.close_file_header (rpt_file_lis);
        z_jobsub_utility.clean_up_parms (job_name, one_up_no_in);      
        
    EXCEPTION
        WHEN app_error THEN
            -- Internal application error occurred and has already been handled.  Do not re-raise.
            write_log_error(error_msg);
            write_lis_error(error_msg);
            ROLLBACK;  -- Release any locks held by this process
            z_jobsub_utility.close_file_header (rpt_file_lis); -- Make sure the lis file is closed
        WHEN OTHERS THEN
            ROLLBACK;
            write_log_error(SQLERRM);
            write_log_error(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE());
            write_lis_error(SQLERRM);
            write_lis_error(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE());
            z_jobsub_utility.close_file_header (rpt_file_lis);
   END p_process;
END sz_szpsabl;
/
