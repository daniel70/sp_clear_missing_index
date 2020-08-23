use StackOverflow2010
GO
-- create some missing indexes
select id from Posts where ViewCount > 100 order by ViewCount desc


-- create some indexes
create index please_drop_me on StackOverflow2010.dbo.Posts(Id) where Id = 42;

-- drop some indexes
drop index please_drop_me on StackOverflow2010.dbo.Posts;

EXEC dbo.sp_clear_missing_index