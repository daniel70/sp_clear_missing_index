-- TODO: check sql server version
-- TODO: check sysadmin
-- TODO: write explanation
-- TODO: write disclaimer
-- TODO: make animated gif example

IF OBJECT_ID(N'tempdb.dbo.#missing_index', N'U') IS NOT NULL
	DROP TABLE #missing_index;

IF OBJECT_ID(N'tempdb.dbo.#missing_index_data_types', N'U') IS NOT NULL
	DROP TABLE #missing_index_data_types;

select distinct database_id, object_id, statement
into #missing_index
from sys.dm_db_missing_index_details det

-- alter table #missing_index
-- add column_name sysname, type_name VARCHAR(9)

CREATE TABLE #missing_index_data_types (
	id SMALLINT IDENTITY NOT NULL PRIMARY KEY (id),
	type_id TINYINT,
	type_name VARCHAR(9)
);

-- data type info is in sys.types, at this moment we only look for numbers and text
-- if a table does not have a number of text column then it will be skipped
INSERT INTO #missing_index_data_types (type_id, type_name) VALUES
	(56, 'NUMBER') -- int
	,(127, 'NUMBER') -- bigint
	,(52, 'NUMBER') -- smallint
	,(48, 'NUMBER') -- tinyint
	,(59, 'NUMBER') -- real
	,(62, 'NUMBER') -- float
	,(106, 'NUMBER') -- decimal
	,(108, 'NUMBER') -- numeric
	,(167, 'CHARACTER') -- varchar
	,(175, 'CHARACTER') -- char
	,(231, 'CHARACTER') -- nvarchar
	,(239, 'CHARACTER') -- nchar
	,(35, 'CHARACTER') -- text
	,(99, 'CHARACTER') -- ntext

DECLARE @database_id int,
	@object_id int,
	@statement nvarchar(1000), -- TODO: find date type
	@db_name SYSNAME,
	@stmt NVARCHAR(1000),
	@column_name SYSNAME,
	@type_name VARCHAR(9),
	@create_stmt VARCHAR(1000),
	@drop_stmt VARCHAR(1000);

declare table_cursor cursor for
select mi.database_id, mi.object_id, mi.statement from #missing_index mi
-- for update of column_name, type_name;

open table_cursor;
fetch next from table_cursor into @database_id, @object_id, @statement;

	
while @@FETCH_STATUS = 0 begin
	set @db_name = QUOTENAME(db_name(@database_id));
	set @stmt = concat(
		'select top 1 @column_name = c.name, @type_name = dt.type_name from', @db_name, '.sys.columns c
			join #missing_index_data_types dt on c.system_type_id = dt.type_id
		 where object_id = @object_id
		 order by dt.id asc
		');
	exec sys.sp_executesql @stmt=@stmt, 
		@params=N'@object_id int, @column_name sysname OUTPUT, @type_name VARCHAR(9) OUTPUT',
		@object_id=@object_id,
		@column_name = @column_name OUTPUT,
		@type_name = @type_name OUTPUT
	
	-- update #missing_index set column_name = @column_name, type_name = @type_name where current of table_cursor;

	if @type_name = 'NUMBER' begin
		set @create_stmt = CONCAT('CREATE INDEX missing_index ON ', @statement, '(', @column_name, ') WHERE ', @column_name, ' = 42');
		print @create_stmt;
--		exec sp_executesql @create_stmt;
--		set @drop_stmt = CONCAT('DROP INDEX missing_index ON ', @statement);
--		exec sp_executesql @drop_stmt;
	end
	else begin
		set @create_stmt = CONCAT('CREATE INDEX missing_index ON ', @statement, '(', @column_name, ') WHERE ', @column_name, ' = ''42''');
		exec sp_executesql @create_stmt;
		set @drop_stmt = CONCAT('DROP INDEX missing_index ON ', @statement);
		exec sp_executesql @drop_stmt;
	end
	fetch next from table_cursor into @database_id, @object_id, @statement;

end;
close table_cursor
deallocate table_cursor



--select * from #missing_index;

