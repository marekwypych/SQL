set dateformat ymd
declare @DataBazowa date, @DataKursu date, @DodatkoweDni int
declare @Kurs float
declare @i int = 0
declare @akt bit

update kursy_franka set KursSplaty = 0 
while @i < 208
begin
	select @Kurs = 0
	select @DodatkoweDni = 0
	select @akt = 0 
	while @akt = 0
		begin
			select @DataBazowa = dateadd(mm, @i, '2005-07-12')
			select @DataKursu = dateadd(dd, @DodatkoweDni, @DataBazowa)
			--select @Kurs = Kurs from [testy].[dbo].[KURSY_FRANKA] where data = @DataKursu
			update [testy].[dbo].[KURSY_FRANKA] set KursSplaty = 1 where data = @DataKursu
			select @akt = @@ROWCOUNT
			set @DodatkoweDni = @DodatkoweDni + 1
		end
	set @i = @i + 1
end
