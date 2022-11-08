declare @room int, @row int, @seat int

set @room = 1

while @room < 4
	begin
		set @row = 1
		while @row < 13 
			begin
				set @seat = 1
				While @seat < 25
					begin
						insert into Seats (RoomId, RowNo, SeatNo) Values (@room, @row, @seat)
						set @seat = @seat + 1
					end
				set @row = @row + 1
			end
		set @room = @room + 1
	end