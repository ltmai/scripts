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
oder of INSERT statements. For instance:

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
files are generated in `output` folder.
