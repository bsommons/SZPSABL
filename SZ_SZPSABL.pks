CREATE OR REPLACE PACKAGE baninst1.sz_szpsabl
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
    NAME:       SZ_SZPSABL.pks (Student Attribute Batch Load)

    PURPOSE:    Batch load student attributes into Banner using a file or PopSel.

    Ver         Date        Author          Description
    ---------   ----------  --------------  ------------------------------------
    1.0         10/18/2021  Kevin Klob      Initial Creation
    See the package body comment prologue for more modication history entries.
    ******************************************************************************/
  
    -- Driving procedure
    PROCEDURE p_process (one_up_no_in IN NUMBER);

END sz_szpsabl;
/
