SET LINESIZE 4096
SET WRAP ON
SET VERIFY OFF
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT
SPOOL output/&1 REPLACE

/*
 * the following script dynamically generates a loader file given table name
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
    END;

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
    END;
    
    /*
    ** return primary key columns separated by comma
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
    ** generates the PL/SQL command to print a row in table
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
    END;

    /*
    ** generates header line
    ** #, coord    ,redirect_dest ,rgid ,whithinstore ,rotating_inc ,flowname
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
    END;

    /*
    ** generates column specs similar to the following
    ** tmname,            -- VARCHAR2 (6) NOT NULL
    ** deviceid,          -- NUMBER NOT NULL
    ** forkId,            -- NUMBER NOT NULL
    ** locked             -- NUMBER NOT NULL
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
    END;
BEGIN
    sqlCmd := '
      BEGIN
          dbms_output.put_line(''------------------------------------------------------------------------'');
          dbms_output.put_line(''-- (c) 2018 ENisco GmbH u. Co KG                                        '');
          dbms_output.put_line(''--                                                                      '');
          dbms_output.put_line(''--                                                                      '');
          dbms_output.put_line(''--                                                                      '');
          dbms_output.put_line(''-- SQL*Loader control file that describes how to load the data          '');
          dbms_output.put_line(''-- into table                                                           '');
          dbms_output.put_line(''------------------------------------------------------------------------'');
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
          FOR r IN (SELECT * FROM ' || tableName || ' ORDER BY ' || getPkColumns(tableName) ||  ')
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
