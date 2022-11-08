declare @tb table (id int identity, znak char(1), liczba int)
declare @tekst varchar(500)
declare @output varchar(500) = ''
declare @i int = 1
declare @znak char(1)

set @tekst = 'dsfdsfdsfsdfdsfzza'

while @i <= LEN(@tekst)
begin
	set @znak = SUBSTRING(@tekst, @i, 1)
	if not exists(select 1 from @tb where znak = @znak)
		insert into @tb (znak, liczba) values (@znak, 1)
	else
		update @tb set liczba = liczba + 1 where znak = @znak
	set @i = @i + 1
end

declare znaki cursor for select znak, liczba from @tb order by id
open znaki
fetch next from znaki into @znak, @i
while @@FETCH_STATUS = 0
	begin
		set @output = @output + CONVERT(varchar, @i) + @znak
		fetch next from znaki into @znak, @i
	end
close znaki
deallocate znaki

select @output