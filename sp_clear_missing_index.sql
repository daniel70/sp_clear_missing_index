if (object_id(N'tempdb.dbo.#missing_index', N'U') is not null) begin
	drop table #missing_index;
end;
if (object_id(N'tempdb.dbo.#missing_index_columns', N'U') is not null) begin
	drop table #missing_index_columns;
end;

select distinct database_id, object_id, statement
into #missing_index
from sys.dm_db_missing_index_details det

alter table #missing_index
add col sysname, dtype sysname

declare table_cursor cursor for
select mi.database_id, mi.object_id, mi.statement from #missing_index mi
for update of col, dtype;

open table_cursor;
declare @database_id int, @object_id int, @statement varchar(1000)
fetch next from table_cursor into @database_id, @object_id, @statement;

declare @db_name sysname,
	@stmt nvarchar(max)
	
while @@FETCH_STATUS = 0 begin
	print @statement

	
	set @db_name = QUOTENAME(db_name(@database_id));
	set @stmt = concat('select * into ##missing_index_columns from ', @db_name, '.sys.columns where object_id = @object_id');
	exec sys.sp_executesql @stmt=@stmt, @params=N'@object_id int', @object_id=@object_id
	-- instead of using a global temp table we will use OUT variables to get a column name and type
	
	update #missing_index set col = @db_name where current of table_cursor;

	fetch next from table_cursor into @database_id, @object_id, @statement;
end;
close table_cursor
deallocate table_cursor



select * from #missing_index
select * from ##missing_index_columns

