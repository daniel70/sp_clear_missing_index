# sp_clear_missing_index
Clear SQL Servers missing index DMV's

SQL Server can clear some statistics:
- DBCC SQLPERF("sys.dm_os_latch_stats",CLEAR);
- DBCC SQLPERF("sys.dm_os_wait_stats",CLEAR);

however, DBCC SQLPERF("sys.dm_db_missing_index_details",CLEAR) does not exist.

