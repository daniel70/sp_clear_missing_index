SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

IF OBJECT_ID('dbo.sp_clear_missing_index') IS NULL
  EXEC ('CREATE PROCEDURE dbo.sp_clear_missing_index AS RETURN 0;')
GO

ALTER PROCEDURE dbo.sp_clear_missing_index 
WITH RECOMPILE
AS
SET NOCOUNT ON;
BEGIN;

	/*
	MIT License

	Copyright (c) 2020 Daniel van der Meulen

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
	*/

	IF OBJECT_ID(N'tempdb.dbo.#missing_index', N'U') IS NOT NULL
		DROP TABLE #missing_index;

	IF OBJECT_ID(N'tempdb.dbo.#missing_index_data_types', N'U') IS NOT NULL
		DROP TABLE #missing_index_data_types;

	SELECT DISTINCT database_id, object_id, statement
	INTO #missing_index
	FROM sys.dm_db_missing_index_details det

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

	DECLARE @database_id INT,
		@object_id INT,
		@statement NVARCHAR(4000),
		@db_name SYSNAME,
		@stmt NVARCHAR(4000),
		@column_name SYSNAME,
		@type_name VARCHAR(9),
		@create_stmt NVARCHAR(4000),
		@drop_stmt NVARCHAR(4000);

	DECLARE table_cursor CURSOR FOR
	SELECT mi.database_id, mi.object_id, mi.statement from #missing_index mi

	OPEN table_cursor;
	FETCH NEXT FROM table_cursor INTO @database_id, @object_id, @statement;

	WHILE @@FETCH_STATUS = 0 BEGIN
		SET @db_name = QUOTENAME(DB_NAME(@database_id));
		SET @stmt = CONCAT(
			'SELECT TOP 1 @column_name = QUOTENAME(c.name), @type_name = dt.type_name from', @db_name, '.sys.columns c
				JOIN #missing_index_data_types dt ON c.system_type_id = dt.type_id
			 WHERE object_id = @object_id
			 ORDER by dt.id asc
			');
		EXEC sys.sp_executesql @stmt=@stmt, 
			@params=N'@object_id int, @column_name sysname OUTPUT, @type_name VARCHAR(9) OUTPUT',
			@object_id=@object_id,
			@column_name = @column_name OUTPUT,
			@type_name = @type_name OUTPUT;
	
		SET @create_stmt = CONCAT(N'CREATE INDEX missing_index ON ', @statement, N'(', @column_name, N') WHERE ', @column_name);
		IF @type_name = 'NUMBER'
			SET @create_stmt += N' = 42';
		ELSE IF @type_name = 'CHARACTER'
			SET @create_stmt += N' = ''Q''';
		ELSE BEGIN
			PRINT @statement + ' has no columns of type NUMBER or CHARACTER, skipping...';
			FETCH NEXT FROM table_cursor INTO @database_id, @object_id, @statement;
			CONTINUE;
		END;

		EXEC sp_executesql @create_stmt;
		
		SET @drop_stmt = CONCAT(N'DROP INDEX missing_index ON ', @statement);
		EXEC sp_executesql @drop_stmt;

		FETCH NEXT FROM table_cursor INTO @database_id, @object_id, @statement;

	END;
	CLOSE table_cursor;
	DEALLOCATE table_cursor;
END;

