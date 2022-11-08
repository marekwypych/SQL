declare @Tekst varchar(500)
declare @TekstWyjscie varchar(500) = ''
declare @Licznik int = 1
declare @Znak char(1)
declare @LiczbaZnakow int

set @Tekst = 'aadddaaadetffgthcbmnli'

while @Licznik <= len(@Tekst)
begin
	set @Znak = substring(@tekst, @Licznik, 1)
	set @LiczbaZnakow =  len(@Tekst) - len(replace(@Tekst, @Znak, ''))
	if(len(@TekstWyjscie) - len(replace(@TekstWyjscie, convert(varchar, @LiczbaZnakow) + @Znak, '')) = 0)
		begin
			select @TekstWyjscie = @TekstWyjscie + convert(varchar, @LiczbaZnakow) + @Znak
		end
	set @Licznik = @Licznik + 1
end

select @TekstWyjscie Output

