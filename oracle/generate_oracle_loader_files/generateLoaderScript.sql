--------------------------------------------------------------------------------
-- Generate Oracle LOADER script
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

SET LINESIZE 4096
SET WRAP ON
SET VERIFY OFF
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT
SPOOL output/&1 REPLACE

/*
 * The following script dynamically generates a loader file given table name.
   Sample output: 
    LOAD DATA
    INFILE *
    DISCARDFILE bonus.dsc
    REPLACE
    INTO TABLE bonus
    WHEN (ename != "#")
    FIELDS TERMINATED BY ","
    OPTIONALLY ENCLOSED BY '~'
    (
    ename,      -- VARCHAR2(10)
    job,        -- VARCHAR2(9)
    sal,        -- NUMBER(22)
    comm        -- NUMBER(22)
    )
    BEGINDATA
    #,----------------------------------------------------------------------
    #,
    #,----------------------------------------------------------------------
    #, ename    ,job        ,sal    ,comm
    ~SCOTT~     ,~ANALYST~  ,~3000~ ,~~
 */
DECLARE
    /*
    ** table column metadata
    */
    CURSOR tableColumns(tableName VARCHAR2)
    IS
        SELECT column_name, data_type, data_length, column_id, nullable, data_default
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

    tableName VARCHAR2(512) := UPPER('&1');

    sqlCmd    VARCHAR2(8192);

    /*
    ** escapes single quotes in PL/SQL
    ** '0' -> ''0''
    */
    FUNCTION escapeSingleQuote(s VARCHAR2)
        RETURN VARCHAR2
    IS
    BEGIN
        RETURN replace(s, '''', '''''');
    END escapeSingleQuote;

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
    ** return PRIMARY KEY columns separated by comma
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
    ** generate ORDER BY clause
    */
    FUNCTION getOrderByClause(tableName VARCHAR)    
        RETURN VARCHAR2
    AS
    BEGIN
        RETURN NVL(getPkColumns(tableName), getFirstColumn(tableName));
    END getOrderByClause;

    /*
    ** generates the PL/SQL command to print a row in table
    ** Example:
    ** ~SCOTT~     ,~ANALYST~  ,~3000~ ,~~
    */
    FUNCTION generateRowCommand(tableName VARCHAR2)
        RETURN VARCHAR2
    AS
        line  VARCHAR2(4096);
    BEGIN
        FOR r IN tableColumns(tableName)
        LOOP
            line := line || ''',~'' || r.' || r.column_name || ' || ''~'' || chr(9) || ';
        END LOOP;

        line := substr(line, 3);
        line := substr(line, 1, length(line)-14);

        RETURN 'dbms_output.put_line(''' || line || ');';
    END generateRowCommand;

    /*
    ** generates header line
    ** Example:    
    ** #, ename    ,job    ,sal    ,comm
    */
    FUNCTION generateHeaderLine(tableName VARCHAR2)
        RETURN VARCHAR2
    AS
        headerLine  VARCHAR2(4096);
        separator   VARCHAR2(23);

    BEGIN

        headerLine := '#, ';

        FOR r IN tableColumns(tableName)
        LOOP
            IF (r.column_id = 1)
            THEN
                separator := '';
            ELSE
                separator := ',';
            END IF;

            headerLine := headerLine || separator || lower(r.column_name) || '    ';
        END LOOP;

        RETURN 'dbms_output.put_line(''' || headerLine || ''');';
    END generateHeaderLine;

    /*
    ** generates column specs.
    ** Example:
    ** ename,      -- VARCHAR2(10)
    ** job,        -- VARCHAR2(9)
    ** sal,        -- NUMBER(22)
    ** comm        -- NUMBER(22)
    */
    FUNCTION generateColumnSpecs(tableName VARCHAR2)
        RETURN VARCHAR2
    AS
        columnSpec  VARCHAR2(4096);
        nullConstraint VARCHAR2(64);
        lineSeparator VARCHAR2(64);
        defaultValue VARCHAR2(64);
        maxColumnId NUMBER;

    BEGIN
        SELECT max(column_id)
          INTO maxColumnId
          FROM all_tab_columns
         WHERE table_name = tableName;

        FOR r IN tableColumns(tableName)
        LOOP
            IF (r.nullable = 'Y')
            THEN
                nullConstraint := '';
            ELSE
                nullConstraint := ' NOT NULL';
            END IF;

            IF (r.column_id = maxColumnId)
            THEN
                lineSeparator := '';
            ELSE
                lineSeparator := ',';
            END IF;

            IF (r.data_default IS NULL)
            THEN
                defaultValue := '';
            ELSE
                defaultValue := ' DEFAULT ' || r.data_default;
            END IF;

            columnSpec := columnSpec
                          || '          dbms_output.put_line('''
                          || lower(r.column_name)
                          || lineSeparator
                          || '        -- '
                          || r.data_type
                          || '('
                          || r.data_length
                          || ')'
                          || escapeSingleQuote(defaultValue)
                          || nullConstraint
                          || ''');'
                          || chr(13);
        END LOOP;

        RETURN columnSpec;
    END generateColumnSpecs;
    
BEGIN
    sqlCmd := '
      BEGIN
          dbms_output.put_line(''--------------------------------------------------------------------------'');
          dbms_output.put_line(''-- SQL*Loader control file that describes how to load the data into table.'');
          dbms_output.put_line(''--------------------------------------------------------------------------'');
          dbms_output.put_line('''');
          dbms_output.put_line(''LOAD DATA'');
          dbms_output.put_line(''INFILE *'');
          dbms_output.put_line(''DISCARDFILE ' || lower(tableName) || '.dsc'');
          dbms_output.put_line(''REPLACE'');
          dbms_output.put_line(''INTO TABLE ' || lower(tableName) ||  ''');
          dbms_output.put_line(''WHEN (' || getFirstColumn(tableName) || ' != "#")'');
          dbms_output.put_line(''FIELDS TERMINATED BY ","'');
          dbms_output.put_line(''OPTIONALLY ENCLOSED BY ''''~'''''');
          dbms_output.put_line('''');
          dbms_output.put_line(''('');

'         || generateColumnSpecs(tableName) || '
          dbms_output.put_line('')'');
          dbms_output.put_line('''');
          dbms_output.put_line(''BEGINDATA'');
          dbms_output.put_line(''#,----------------------------------------------------------------------'');
          dbms_output.put_line(''#,'');
          dbms_output.put_line(''#,----------------------------------------------------------------------'');
          '
          || generateHeaderLine(tableName) ||
          '
          FOR r IN (SELECT * FROM ' || tableName || ' ORDER BY ' || getOrderByClause(tableName) ||  ')
          LOOP
               ' || generateRowCommand(tableName) || '
          END LOOP;
      END;
      ';

    --dbms_output.put_line(sqlCmd);
    EXECUTE IMMEDIATE sqlCmd;
END;
/
EXIT
