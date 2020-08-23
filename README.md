# sp_clear_missing_index
Clear SQL Servers missing index DMV's online.

SQL Server can clear some statistics:
- DBCC SQLPERF("sys.dm_os_latch_stats",CLEAR);
- DBCC SQLPERF("sys.dm_os_wait_stats",CLEAR);

however, DBCC SQLPERF("sys.dm_db_missing_index_details",CLEAR) does not exist.  
If you would like to see this functionality in SQL Server go to their [feedback forum](https://feedback.azure.com/forums/908035-sql-server/) and vote for [this](https://feedback.azure.com/forums/908035-sql-server/suggestions/32889847-clearing-dm-db-missing-index) request.

The suggestion is from 2008 so, at the time I'm writing this, already more than 12 years ago.  
I hope that Microsoft wil get around to implementing this with their new release but until that time I have created a work around that does not require you to restart the service or detach/attach the database.

Here is what the procedure does:
1. find all tables that have missing indexes
2. per table find one column with numbers (int or tinyint or smallint etc.) or characters (varchar, nvarchar, text etc.)
3. create an index called "missing_index" on this table for this column with a WHERE clause, e.g. WHERE [Id] = 42
4. drop the index

By creating the index SQL Server will remove the entry for this table from the missing index tables.

If you find any issues with this procedure please create an Issue here on GitHub. You can also leave your suggestions here.

Some performance metrics:
SQL 2014 with 166 entries took 96 seconds
