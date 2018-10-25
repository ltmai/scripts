SET LINESIZE 512
SET WRAP ON
SET VERIFY OFF
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT
SPOOL INSERTscript.sql REPLACE

DECLARE

    PROCEDURE createInsertScript(tableNameIn VARCHAR2)
    IS
        tableName VARCHAR2(32) := UPPER(tableNameIn);

        selectCmd VARCHAR2(2048);

        sqlCmd    VARCHAR2(20000);

        /*
        ** table column metadata
        */
        CURSOR tableColumns(tableName VARCHAR2)
        IS
            SELECT * --column_name, data_type, data_length, column_id, nullable, data_default
              FROM user_tab_columns
             WHERE table_name=tableName
             ORDER BY column_id;

        /*
        ** primary key columns
        */
        CURSOR pkColumns(tableName VARCHAR2)
        IS
            SELECT cols.column_name
              FROM user_constraints cons, user_cons_columns cols
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
        END getFieldList;


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
        END getPkColumns;

        /*
        ** returns column value as text depending on column data type
        */
        FUNCTION getColumnValue(r user_tab_columns%ROWTYPE)
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
        END getColumnValue;

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
        END getValueList;

    BEGIN -- createInsertScript

        selectCmd := 'SELECT ' || getFieldList(tableName) || ' FROM ' || tableName || ' ORDER BY ' || getPkColumns(tableName) ;

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

    END createInsertScript; 

BEGIN

    DBMS_OUTPUT.PUT_LINE('BEGIN');

    createInsertScript('departments');
    createInsertScript('employees');

    DBMS_OUTPUT.PUT_LINE('END;');
    DBMS_OUTPUT.PUT_LINE('/');

END;
/

EXIT