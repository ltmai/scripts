# Various scripts

## Oracle

We will use schema tiger for testing. Login as user SYS AS SYSDBA and unlock it as follows:

```sql
SQL> ALTER USER scott IDENTIFIED BY tiger ACCOUNT UNLOCK;
```

1. Generate INSERT script
   
The script `oracle\generate_insert_scripts\generateInsertScript.sql` contains the code and its 
example use. In general the syntax is `createInsertScript(tableName, customWhereClause, customOrderByClause)`
where `customWhereClause` and `customOrderByClause` are optional. By default INSERT statements are
generated for all rows; data is sorted by primary key or first column if no primary key is defined. 
You may use custom WHERE clause to filter target data and custom ORDER BY clause to change the 
oder of INSERT statements. For example:

```sql
BEGIN
    createInsertScript(tableNameIn => 'emp', whereClause => 'deptno=10', orderClause => 'ename');
END;
/
```

The batch file `generateInsertScript.cmd` is only a wrapper to run the SQL script and trim trailing 
white spaces in output file. 

2. Generate LOADER files

The script `oracle\generate_oracle_loader_files\generateLoaderScript.sql` contains the SQL code.
The batch file `generateLoaderScripts.cmd` is a wrapper to run this script and also provides some
examples. For convenience, you may want to edit the batch file to change the table names. The output
files are generated in `output` folder. The following should be adapted to suit your need:

```batch
:: Change Oracle connection string here
:: Syntax: username/password@SID
SET dbconn=scott/tiger@ORACLE

:: Change table names or add new tables here
sqlplus %dbconn% @generateLoaderScript dept
sqlplus %dbconn% @generateLoaderScript emp
sqlplus %dbconn% @generateLoaderScript bonus
sqlplus %dbconn% @generateLoaderScript salgrade
```

## Windows Batch

1. env.cmd - Initialize console settings 

This script is an example of initializing the Windows console settings at startup. It is place to
set environment variables, change the dafault command prompt, define doskey macros, and so on.

2. head.cmd - Show the first lines in file

3. line.cmd - Show specific line in file

4. which.cmd - Locate the executable

## Powershell

1. Powergrep.ps1

2. ReplaceTextInFile.ps1

3. TrimTrailingSpacesInFile.ps1

4. FilterFileContentNotLike.ps1

5. ExtractRemoteHost.ps1

6. WildflyHttpConnections.ps1