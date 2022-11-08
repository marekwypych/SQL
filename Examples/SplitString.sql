	
	select '1,2,34' Liczby
		union all 
		select '7,5' Liczby

	SELECT value  
		FROM (select '1,2,34' Liczby
					union all 
					select '7,5' Liczby) t  
		CROSS APPLY STRING_SPLIT(Liczby, ',')
		order by CONVERT(int, value)