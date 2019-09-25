--------------------------------------------------------------------------------
-- Generate INSERT script
-- Copyright (C) 2018  - Linh Mai
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--------------------------------------------------------------------------------
SET LINESIZE 512
SET WRAP ON
SET VERIFY OFF
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT
SPOOL INSERTscript REPLACE

DECLARE

    /*
    ** createInsertScript creates a PL/SQL code and executes it dynamically
    ** to generate INSERT statements for a given table.
    ** Note that table column data type is limited to specific data types
    ** handled in function getColumnValue(), this function needs to be extended
    ** if necessary.
    **
    ** @param tableNameIn : input table name
    ** @param whereClause : (optional) WHERE clause
    ** @param orderClause : (optional) ORDER BY clause, use primary key by default
    */
    PROCEDURE createInsertScript(tableNameIn VARCHAR2, whereClause VARCHAR2 DEFAULT NULL, orderClause VARCHAR2 DEFAULT NULL)
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
        ** FK-referenced tables
        */
        CURSOR refTables(tableName VARCHAR2)
        IS
            SELECT cons2.table_name AS REFERENCED_TABLE, cons1.constraint_name AS FK_CONSTRAINT, cons2.constraint_name AS REFERENCED_CONSTRAINT
              FROM user_constraints cons1, user_constraints cons2
             WHERE cons1.table_name = tableName
               AND cons1.constraint_type = 'R'                     -- FK only
               AND cons2.constraint_name = cons1.r_constraint_name -- referenced constraint
               AND cons1.table_name <> cons2.table_name            -- not self-referenced
             ORDER BY cons2.table_name;

        /*
        ** returns fields separated by commas
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
        ** returns referenced tables separated by commas
        */
        FUNCTION getRefTables(tableName VARCHAR2)
            RETURN VARCHAR2
        IS
            ret VARCHAR2(1024);
            fst BOOLEAN := TRUE;
        BEGIN
            FOR r IN refTables(tableName)
            LOOP
                IF (fst)
                THEN
                    fst := FALSE;
                    ret := ret || r.referenced_table;
                ELSE
                    ret := ret || ', ' || r.referenced_table;
                END IF;
            END LOOP;

            RETURN NVL(ret, 'NONE');
        END getRefTables;

        /*
        ** get name of first column in table
        */
        FUNCTION getFirstColumn(tableName VARCHAR2)
            RETURN VARCHAR2
        AS
            colName all_tab_columns.column_name%TYPE;
        BEGIN
            SELECT column_name
              INTO colName
              FROM all_tab_columns
             WHERE table_name=tableName
               AND column_id=1;

            RETURN lower(colName);
        END getFirstColumn;

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
        ** generates ORDER BY clause in the SELECT statement.
        ** If table has primary key then order records by primary key,
        ** otherwise order by the first column in table.
        */
        FUNCTION getOrderByClause(tableName VARCHAR2)
            RETURN VARCHAR2
        AS
        BEGIN
            RETURN NVL(getPkColumns(tableName), getFirstColumn(tableName));
        END getOrderByClause;

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

        selectCmd := 'SELECT ' || getFieldList(tableName) || ' FROM ' || tableName ;

        IF (whereClause IS NOT NULL)
        THEN
            selectCmd := selectCmd || ' WHERE ' || whereClause;
        END IF;

        selectCmd := selectCmd || ' ORDER BY ';

        IF (orderClause IS NULL)
        THEN
            selectCmd := selectCmd || getOrderByClause(tableName);
        ELSE
            selectCmd := selectCmd || orderClause;
        END IF;

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
              dbms_output.put_line(''    -- execute after inserts on ' || getRefTables(tableName) || ' --'');

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

    createInsertScript(tableNameIn => 'dept');
    createInsertScript(tableNameIn => 'emp', whereClause => 'deptno=10', orderClause => 'ename');
    createInsertScript(tableNameIn => 'bonus');
    createInsertScript(tableNameIn => 'salgrade');

    DBMS_OUTPUT.PUT_LINE('END;');
    DBMS_OUTPUT.PUT_LINE('/');

END;
/

EXIT