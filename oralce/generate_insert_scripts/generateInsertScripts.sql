DECLARE

    PROCEDURE createInsertScript(tableNameIn VARCHAR2)
    IS
        tableName VARCHAR2(32) := UPPER(tableNameIn);

        fieldList VARCHAR2(1024);

        selectCmd VARCHAR2(2048);

        sqlCmd    VARCHAR2(20000);

        /*
        ** table column metadata
        */
        CURSOR tableColumns(tableName VARCHAR2)
        IS
            SELECT * --column_name, data_type, data_length, column_id, nullable, data_default
              FROM all_tab_columns
             WHERE table_name=tableName
             ORDER BY column_id;

        /*
        ** primary key columns
        */
        CURSOR pkColumns(tableName VARCHAR2)
        IS
            SELECT cols.column_name
              FROM all_constraints cons, all_cons_columns cols
             WHERE cols.table_name = tableName
               AND cons.constraint_type = 'P'
               AND cons.constraint_name = cols.constraint_name
               AND cons.owner = cols.owner
             ORDER BY cols.table_name, cols.position;

        /*
        ** returns fields separated by comma
        */
        FUNCTION getFieldList(tableName VARCHAR2)
            RETURN VARCHAR2
        IS
            ret VARCHAR2(1024);
            fst BOOLEAN := TRUE;
        BEGIN
            FOR r IN tableColumns(tableName)
            LOOP
                IF (fst)
                THEN
                    fst := FALSE;
                    ret := ret || r.column_name;
                ELSE
                    ret := ret || ', ' || r.column_name;
                END IF;
            END LOOP;

            RETURN ret;
        END;


        /*
        ** returns primary key columns separated by comma
        */
        FUNCTION getPkColumns(tableName VARCHAR2)
            RETURN VARCHAR2
        IS
            ret VARCHAR2(128);
            fst BOOLEAN := TRUE;
        BEGIN
            FOR r IN pkColumns(tableName)
            LOOP
                IF (fst)
                THEN
                    fst := FALSE;
                    ret := ret || r.column_name;
                ELSE
                    ret := ret || ', ' || r.column_name;
                END IF;
            END LOOP;

            RETURN ret;
        END;

        /*
        ** returns column value as text depending on column data type
        */
        FUNCTION getColumnValue(r all_tab_columns%ROWTYPE)
            RETURN VARCHAR2
        IS
            ret VARCHAR2(128);
        BEGIN
            IF r.data_type IN ('CHAR', 'NCHAR', 'VARCHAR2', 'NVARCHAR2')
            THEN
                ret := ret || ''''''''' || escapeSingleQuotes(r.';
                ret := ret || r.column_name;
                ret := ret || ') || ''''''''';
            ELSIF r.data_type IN ('LONG', 'FLOAT', 'NUMBER')
            THEN
                ret := ret || 'r.' || r.column_name;
            ELSIF instr(r.data_type, 'TIMESTAMP') = 1
            THEN
                ret := ret || '''TO_TIMESTAMP('''''' || ';
                ret := ret || 'r.' || r.column_name;
                ret := ret || ' || '''''')''';
            ELSIF r.data_type IN ('DATE')
            THEN
                ret := ret || '''TO_DATE('''''' || ';
                ret := ret || 'r.' || r.column_name;
                ret := ret || ' || '''''')''';
            ELSE
                RAISE_APPLICATION_ERROR(-20001, 'Unhandled data type ' || r.data_type || '. Table ' || r.table_name || ' Column ' || r.column_name);
            END IF;

            RETURN ret;
        END;

        /*
        ** returns SQL code to NULL-check and write corresponding column values
        */
        FUNCTION getValueList(tableName VARCHAR2)
            RETURN VARCHAR2
        IS
            ret VARCHAR2(20000);
            fst BOOLEAN := TRUE;
        BEGIN
            FOR r IN tableColumns(tableName)
            LOOP
                IF fst THEN
                    fst := FALSE;
                ELSE
                    ret := ret || '     insertCmd := insertCmd || '', '';';
                END IF;

                ret := ret || '
                    IF r.' || r.column_name || ' IS NULL THEN
                        insertCmd := insertCmd || '' NULL '';
                    ELSE
                        insertCmd := insertCmd || ' || getColumnValue(r) || ' ;
                    END IF;
                ';
            END LOOP;

            RETURN ret;
        END;

    BEGIN -- createInsertScript

        fieldList := getFieldList(tableName);
        selectCmd := 'SELECT ' || fieldList || ' FROM ' || tableName || ' ORDER BY ' || getPkColumns(tableName);

        sqlCmd := '
            DECLARE
                insertCmd VARCHAR2(2048);

                /*
                ** escapes single quotes in PL/SQL
                */
                FUNCTION escapeSingleQuotes(s VARCHAR2)
                    RETURN VARCHAR2
                IS
                BEGIN
                    RETURN replace(s, '''''''', '''''''''''');
                END;

            BEGIN
              dbms_output.put_line(''    -- table ' || tableName || ' --'');
              FOR r IN (' || selectCmd || ')
              LOOP
                  insertCmd := ''    INSERT INTO ' || tableName || ' (' || getFieldList(tableName) || ') VALUES ('';'
                  || getValueList(tableName) || '
                  insertCmd := insertCmd || '');'' ;
                  dbms_output.put_line(insertCmd);
              END LOOP;
              dbms_output.put_line(''    COMMIT;'');
            END;';

        --DBMS_OUTPUT.PUT_LINE(sqlCmd);
        EXECUTE IMMEDIATE sqlCmd;

    END; -- createInsertScript

BEGIN
    DBMS_OUTPUT.PUT_LINE('BEGIN');

    --------- testing with one table----------
    IF FALSE THEN
        createInsertScript('SYS_CONSTANT');
        RETURN;
    END IF;
    --------- testing with one table----------

    --createInsertScript('SYS_APPSESSION');
    createInsertScript('SYS_CONSTANT');
    createInsertScript('SYS_DBEREG');
    --createInsertScript('SYS_EVENT');
    createInsertScript('SYS_LANGUAGE');
    createInsertScript('SYS_LOCALE');
    createInsertScript('SYS_MODULE');
    createInsertScript('SYS_PARAMETER');
    --createInsertScript('SYS_PICTURE'); -- SYS_PICTURE.PICTURE is of type BLOB
    createInsertScript('SYS_STATE');
    createInsertScript('SYS_TEXTBLOCK');
    createInsertScript('SYS_TB_TEXT');
    --createInsertScript('SYS_TRANSACTION');
    createInsertScript('SYS_WTM');
    createInsertScript('SYS_WTM_SHIFT');
    createInsertScript('SYS_WTM_WEEK');
    createInsertScript('SYS_WEEK_CAL_TEMPL');
    createInsertScript('SYS_WEEK_CAL_SHIFT');

    createInsertScript('KNL_ACTION');
    --createInsertScript('KNL_ACTIVITY'); -- created by PL/SQL
    --createInsertScript('KNL_ACTIVITY_DETAIL');
    createInsertScript('KNL_CONTROL');
    --createInsertScript('KNL_EVENTLOG');
    createInsertScript('KNL_FLOW');
    createInsertScript('KNL_FLOW_DETAIL');
    createInsertScript('KNL_JOB');
    --createInsertScript('KNL_MANUALTELEGRAM');
    createInsertScript('KNL_MSQ');
    createInsertScript('KNL_PARAM');
    createInsertScript('KNL_PARAMPROC');
    createInsertScript('KNL_SYNC');
    createInsertScript('KNL_SYNC_DETAIL');
    --createInsertScript('KNL_TRACE');
    --createInsertScript('KNL_TRACEOFSCHEDULED');

    --createInsertScript('EGW_ACTIVITY');
    createInsertScript('EGW_CHANNEL');
    createInsertScript('EGW_CHANNELSTATE');
    createInsertScript('EGW_ERRORCODE');
    createInsertScript('EGW_MSGDIRECT');
    createInsertScript('EGW_MSGSTATE');
    --createInsertScript('EGW_PLCMSG');
    createInsertScript('EGW_TMERROR');
    --createInsertScript('EGW_XMLMSG');

    --createInsertScript('MFC_DATAMODULE'); -- MFC_DATAMODULE.DATAMODULE is of type BLOB
    createInsertScript('MFC_DESTINATION2REDIRECT');
    createInsertScript('MFC_HEIGHTCLS');
    createInsertScript('MFC_KEYPRESSED');
    --createInsertScript('MFC_LANE');
    --createInsertScript('MFC_LANE_DEST');
    --createInsertScript('MFC_LANESTATE');
    --createInsertScript('MFC_OPERATIONTIME');
    createInsertScript('MFC_PATH');
    --createInsertScript('MFC_PCHECK');
    --createInsertScript('MFC_PCHECK_DETAIL');
    createInsertScript('MFC_PCHECK2REDIRECT');
    --createInsertScript('MFC_PDATA');
    --createInsertScript('MFC_PDATA_DETAIL');
    createInsertScript('MFC_PFC');
    createInsertScript('MFC_POINT');
    createInsertScript('MFC_POINT2FLOW');
    createInsertScript('MFC_POINT2FTPK');
    createInsertScript('MFC_POINT2TO');
    createInsertScript('MFC_RECONCILIATIONCONFIG');
    createInsertScript('MFC_ROUTE');
    createInsertScript('MFC_RSCGRP');
    createInsertScript('MFC_SYNC_TO');
    --createInsertScript('MFC_TEST_ROUTING');
    --createInsertScript('MFC_TEST_VSW');
    --createInsertScript('MFC_THROUGHPUT');
    createInsertScript('MFC_TM');
    createInsertScript('MFC_TMDEVICE');
    --createInsertScript('MFC_TO');
    --createInsertScript('MFC_TOBINCOORD');
    createInsertScript('MFC_TOPARAM');
    createInsertScript('MFC_TUTYPE');
    createInsertScript('MFC_TUTYPECLASS');
    createInsertScript('MFC_TUTYPE2TM');

    createInsertScript('MMD_ARTCLS');
    createInsertScript('MMD_ARTCLSPROP');
    createInsertScript('MMD_ARTCLSSTATE');
    createInsertScript('MMD_ARTICLE');
    createInsertScript('MMD_ARTPROP');
    createInsertScript('MMD_ARTSTATE');
    createInsertScript('MMD_ARTUNIT');
    createInsertScript('MMD_ARTVAR');
    createInsertScript('MMD_CLIENT');
    createInsertScript('MMD_CLIENTACCESS');
    createInsertScript('MMD_CVAL');
    createInsertScript('MMD_CVALLVL');
    createInsertScript('MMD_CVALSEQ');
    createInsertScript('MMD_CVALSEQELEMENT');
    createInsertScript('MMD_HUCLS');
    createInsertScript('MMD_HUCLSARTLIMIT');
    createInsertScript('MMD_HUCLSNEST');
    createInsertScript('MMD_HUCLSPROP');
    createInsertScript('MMD_PICKINGLVL');
    createInsertScript('MMD_PROP');
    createInsertScript('MMD_PROPHULVL');
    createInsertScript('MMD_PROPVALUE');
    createInsertScript('MMD_REFENTITY');
    createInsertScript('MMD_UNIT');
    createInsertScript('MMD_VARIANT');
    createInsertScript('MMD_VARIANTPROP');

    createInsertScript('INV_ALLOCTYPE');
    --createInsertScript('INV_HU');
    --createInsertScript('INV_HUJNL');
    createInsertScript('INV_HULOCK');
    createInsertScript('INV_HUPROP');
    createInsertScript('INV_HUPROPJNL');
    --createInsertScript('INV_LOCALLOC');
    createInsertScript('INV_STRATEGYMAP');
    --createInsertScript('INV_SUMMARY');

    createInsertScript('CRM_TMDEVICE');
    createInsertScript('CRM_FORK');
    createInsertScript('CRM_POINT');
    createInsertScript('CRM_POINT2FTPK');
    createInsertScript('CRM_TMERROR2PROC');
    --createInsertScript('CRM_TO');
    --createInsertScript('DEV_TRC_BUFFER'); -- no primary key found

    createInsertScript('OMS_CANCEL');
    createInsertScript('OMS_EXECCODE');
    createInsertScript('OMS_ORDER');
    createInsertScript('OMS_ORDHU');
    createInsertScript('OMS_ORDSCHED');
    createInsertScript('OMS_ORDSTATE');
    createInsertScript('OMS_ORDTYPE');
    createInsertScript('OMS_PROGRAM');
    createInsertScript('OMS_REQEXECCODE');
    createInsertScript('OMS_RESET');
    createInsertScript('OMS_STATEMACHINE');
    createInsertScript('OMS_STATETRANS');
    createInsertScript('OMS_SUBTYPE');
    createInsertScript('OMS_TEMPORDER');

    createInsertScript('MOM_MFCSTRATEGYMAP');
    createInsertScript('MOM_RELOCDEST');
    createInsertScript('MOM_TOTYPEMAP');
    createInsertScript('MOM_TUTYPEMAP');
    createInsertScript('MRM_POINT');
    createInsertScript('MRM_SIMULATION');
    createInsertScript('MRM_TORECONCILIATION');

    createInsertScript('PCS_TELE_CONFIGURATION');
    createInsertScript('PLC_CFG_PARAM');

    createInsertScript('PRJ_PDATA');
    createInsertScript('PRJ_PPS');
    --createInsertScript('PRJ_PPS_IBN');
    createInsertScript('PRJ_SHUTTLE');
    --createInsertScript('PRJ_SHUTTLE_TO');
    --createInsertScript('PRJ_SIMU_CFG');
    --createInsertScript('PRJ_SKID');
    createInsertScript('PRJ_TERMINAL');
    createInsertScript('SLM_CLONEIDMAP');
    createInsertScript('SLM_EXECUTOR');
    createInsertScript('SLM_EXECUTOR_CHAIN');
    --createInsertScript('SLM_LOCATION'); -- generated by PL/SQL
    createInsertScript('SLM_LOCATIONLOCK');
    createInsertScript('SLM_LOCBLOCKING');
    createInsertScript('SLM_LOCNEIGHBOUR');
    createInsertScript('SLM_LOCPROPVAL');
    createInsertScript('SLM_LOCRSC');
    createInsertScript('SLM_LOCTYPE');
    createInsertScript('SLM_LOCTYPEPROP');
    createInsertScript('SLM_PATCHSET');
    createInsertScript('SLM_PATCHSETHDR');
    createInsertScript('SLM_PROPSET');
    createInsertScript('SLM_PROPSET_PROP');
    createInsertScript('SLM_SELNODE');
    --createInsertScript('SLM_TEMP_LOCRANGELIST'); -- temporary table
    --createInsertScript('SLM_TEMP_PROPVALTABLE'); -- temporary table
    --createInsertScript('SLM_TEMP_PROPVALUES');   -- temporary table
    createInsertScript('SLM_VALIDATOR');
    createInsertScript('SLM_VALIDATOR_CHAIN');
    createInsertScript('SLM_VALUESET');
    createInsertScript('SLM_VALUESET_VALUE');

    DBMS_OUTPUT.PUT_LINE('END;');
    DBMS_OUTPUT.PUT_LINE('/');

END;

/


-- generate procedure call for all tables
SELECT '    createInsertScript(''' || table_name || ''');'
  FROM user_tables
 ORDER BY table_name
;
/

