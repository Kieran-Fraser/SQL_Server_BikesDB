--My Ride DateBase Creation
--Kieran Fraser
--use kfraser22


--------------------------------------------------------------------------------------------------------
------------------------------ Checks and dropping Tables -----------------------------------------

--create database kfraser22_Lab01 

if exists				-- must drop sessions first cause of foregin key connections
(
select *
	from kfraser22.sys.tables
	--from sysdatabases
	where [name] = 'Sessions_RDB'
)
drop table Sessions_RDB
go


if exists
(
select *
	from kfraser22.sys.tables
	--from sysdatabases
	where [name] = 'Bikes_RDB'
)
drop table Bikes_RDB

if exists
(
select *
	from kfraser22.sys.tables
	--from sysdatabases
)
drop table Riders_RDB


if exists		-- drop check for classes last
(
select *
	from kfraser22.sys.tables
	--from sysdatabases
	where [name] = 'Classes_RDB'
)
drop table Classes_RDB


--------------------------------------------------------------------------------------------------------
------------------------------ Creation of Tables-----------------------------------------------------
use kfraser22
--drop table Classes_RDB
-- classes db creation
create table kfraser22.dbo.Classes_RDB
(
 ClassID nvarchar(10)  not null				-- not null classid is primary key
	constraint pk_ClassID primary key,
ClassDescription nvarchar(50)

)

-- riders db creation with contraints and foregin key connects
create table  kfraser22.dbo.Riders_RDB
(
	RiderID int  not null identity (10,1) primary key,	-- not null primary key 
														-- identity starting at 10 and increasing by 1
	[Name] nvarchar(max) not null						-- not null nvarchar name
	constraint chk_Name check (len ([Name] ) > 4),		-- check that name is greater that 4 characters
	ClassID nvarchar(10) 
		constraint kf_ClassID FOREIGN KEY 
		REFERENCES Classes_RDB(ClassID) on delete no action
		

)

-- bikes db creation 
create table kfraser22.dbo.Bikes_RDB
(
 BikeID nvarchar (50) not null		-- bike ID not null and primary key
	constraint pk_BikeID primary key,	
	constraint chk_BikeID check (BikeID like '[0-9][0-9][0-9][H,S,Y]-[A,P]'),-- contstraint to set bikeid as ###X-A

StableDate date			-- unrestricted date

)

-- sessions db creation
create table kfraser22.dbo.Sessions_RDB
(
 RiderID int Foreign key references Riders_RDB(RiderID) on delete no action, -- RiderID set as foreign key
 BikeID nvarchar(50),		
 SessionDate date 
	constraint pk_SessionDate primary key				-- primary key with check that it is after sept 1st 2017
	constraint chk_SessionDate check (SessionDate > '1 Sep 2017'),
Laps int default 0						-- start laps at zero 	
)

--ALter Tables
-- add bike id foreign key constraint
alter table kfraser22.dbo.Sessions_RDB
	add
		constraint fk_BikeID foreign key (BikeID)
		references Bikes_RDB(BikeID) on delete no action
go 

-- add composite index on RiderID and Sessions Date
	create nonclustered index RiderID on Sessions_RDB (SessionDate) 
go


-- Constraint addition to Classes
alter table kfraser22.dbo.Classes_RDB
	add
		constraint chk_descLen check ( len (ClassDescription) > 2)
go

--------------------------------------------------------------------------------------------------------
----------------- Populate Bikes Stored Prodcdure and Populate Classes with set Data -------------------

if exists (select * from sysobjects where name = 'PopulateBikes')	-- check/drop/recreate  populate bikes SP
	drop procedure PopulateBikes
go

create procedure PopulateBikes
as
declare @loop as int = 0			-- loop count will loop 120 times
declare @bikeC as int = 0			-- count of current bike models will reset at 20
declare @bikeS as nvarchar(3) 
declare @model as int =0				-- letter representing model type
declare @ModLett as nvarchar(3) = 'HYS'
declare @time as nvarchar 	= 'A'			-- letter representing AM or PM

while @loop < 20
begin
	if (@bikeC < 10)			-- check if bike is single digit or double digits
		set @bikeS = '00'+ convert(nvarchar,@bikeC)
	else
		set @bikeS = '0' + CONVERT(nvarchar,@bikeC)
	

	insert into kfraser22.dbo.Bikes_RDB (BikeID,StableDate)	-- 
	values ((@bikeS+SUBSTRING(@ModLett,1,1)+'-'+'A'), GETDATE())	-- insert honda am bikes

	insert into kfraser22.dbo.Bikes_RDB (BikeID,StableDate)	-- 
	values ((@bikeS+SUBSTRING(@ModLett,1,1)+'-'+'P'), GETDATE())	-- insert honda pm bikes

	insert into kfraser22.dbo.Bikes_RDB (BikeID,StableDate)	-- 
	values ((@bikeS+SUBSTRING(@ModLett,2,1)+'-'+'A'), GETDATE())	-- insert Yamaha am bikes

	insert into kfraser22.dbo.Bikes_RDB (BikeID,StableDate)	-- 
	values ((@bikeS+SUBSTRING(@ModLett,2,1)+'-'+'P'), GETDATE())	-- insert Yamaha pm bikes

	insert into kfraser22.dbo.Bikes_RDB (BikeID,StableDate)	-- 
	values ((@bikeS+SUBSTRING(@ModLett,3,1)+'-'+'A'), GETDATE())	-- insert Suzuki am  bikes

	insert into kfraser22.dbo.Bikes_RDB (BikeID,StableDate)	-- 
	values ((@bikeS+SUBSTRING(@ModLett,3,1)+'-'+'P'), GETDATE())	-- insert Suzuki pm  bikes


	set @loop = @loop +1
	set @bikeC = @bikeC+1
end

select				-- display result set of Bikes table
	BikeID,
	StableDate,
	@@ERROR as 'Procedure Success'
 from kfraser22.dbo.Bikes_RDB 


go

exec PopulateBikes


insert into kfraser22.dbo.Classes_RDB (ClassID,ClassDescription)	-- insertion of values into Classes table
values ('moto_3', 'Default Chassis, 250cc'),
('moto_2', 'Default 600cc, Custom Chassis'),
('motogp', '1000cc Factory Spec')

select * from kfraser22.dbo.Classes_RDB		-- display classes table


--------------------------------------------------------------------------------------------------------
------------------------------ Remove Bike SP and Test given in lab ------------------------------------

if exists (select * from sysobjects where name = 'RemoveBike')		-- check/drop/recreate remove bike
	drop procedure RemoveBike
go

create procedure RemoveBike
--@forceDel as int,
@BikeID as nchar(6) = null,
@errorMessage as nvarchar(max) output
as
	if @BikeID is null
	begin 
		set @errorMessage = 'RemoveBike: BikeID can''t be NULL'
		return -1
	end
	if not exists (select * from Bikes_RDB where BikeID = @BikeID)
	begin
		set @errorMessage = 'RemoveBike: ' + @BikeID + ' doesn''t exist'
		return -1
	end
	if exists ( select * from Sessions_RDB where BikeID = @BikeID)
	begin
		set @errorMessage = 'RemoveBike: ' +  @BikeID +' Currently in Session'
		return -1
	end

	
	delete from Bikes_RDB where BikeID = @BikeID  -- delete from bikes after checks

	set @errorMessage = 'OK'
	return 0
go

--Remove Bike Test
-- null Test
declare @pBikeID as char(6)
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pBikeID = null
set @errMsg= ''
exec @retVal = RemoveBike @BikeId = @pBikeID , @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Bike Exists test
declare @pBikeID as char(6)
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pBikeID = '000H-A' -- BikeID expected to exist
set @errMsg = ''
exec @retVal = RemoveBike @BikeID = @pBikeID, @ErrorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

--Session Exists test
declare @pBikeID as char(6)
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pBikeID = '000H-A' -- set to a BikeID with Session records
set @errMsg = ''
exec @retVal = RemoveBike @BikeID = @pBikeID, @ErrorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go


--------------------------------------------------------------------------------------------------------
------------------------------ Add Rider Stored Prodcedure and Tests------------------------------------

if exists (select * from sysobjects where name = 'AddRider')	-- existence check and drop for AddRider
	drop procedure AddRider
go

create procedure AddRider
@RiderName as nvarchar(max),	-- rider name input parameter
@ClassID as nvarchar(6),			-- classid input parameter
@errorMessage as nvarchar(max) output	-- errmes output
as

	if @RiderName is null			-- break if ridenamer is null
	begin
		set @errorMessage = 'AddRider: RiderName can''t be NULL'
		return -1
	end

	if not exists ( select * from Classes_RDB where ClassID = @ClassID)  -- check for class from classes
	begin
		set @errorMessage = 'AddRider: Class ' + @ClassID + ' doesn''t exist '
		return -1
	end

	insert into kfraser22.dbo.Riders_RDB (Name,ClassID)
	values (@RiderName, @ClassID) 
go



--Add Rider Tests
-- Add rider success test
declare @pRiderName as nvarchar(max)
declare @pClassID as nvarchar(6)
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderName = 'Bill Bo Baggins'
set @pClassID = 'moto_2'
set @errMsg= 'OK'
exec @retVal = AddRider @RiderName = @pRiderName ,@ClassID = @pClassID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- add another rider
declare @pRiderName as nvarchar(max)
declare @pClassID as nvarchar(6)
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderName = 'Frodo Baggins'
set @pClassID = 'moto_2'
set @errMsg= 'OK'
exec @retVal = AddRider @RiderName = @pRiderName ,@ClassID = @pClassID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go
-- add a wizard rider
declare @pRiderName as nvarchar(max)
declare @pClassID as nvarchar(6)
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderName = 'Gandalf the Gray'
set @pClassID = 'moto_3'
set @errMsg= 'OK'
exec @retVal = AddRider @RiderName = @pRiderName ,@ClassID = @pClassID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go



-- Name null Test
declare @pRiderName as nvarchar(max)
declare @pClassID as nvarchar(6)
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderName = null
set @errMsg= ''
exec @retVal = AddRider @RiderName = @pRiderName ,@ClassID = @pClassID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Class does not exists test
declare @pRiderName as nvarchar(max)
declare @pClassID as nvarchar(6)
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderName = 'Bill Bo Baggins'
set @pClassID = 'LOTRfs'
set @errMsg= ''
exec @retVal = AddRider @RiderName = @pRiderName ,@ClassID = @pClassID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go




select * from kfraser22.dbo.Classes_RDB -- testing
select * from kfraser22.dbo.Riders_RDB


--------------------------------------------------------------------------------------------------------
------------------------------ Remove Rider Stored Prodcedure and Tests --------------------------------

if exists (select * from sysobjects where name = 'RemoveRider')		--check/drop/ recreate procedure
	drop procedure RemoveRider
go

create procedure RemoveRider
@forceDel as bit = 0,	-- optional force bool
@RiderID as int,		--
@errorMessage as nvarchar(max) output
as
	if @RiderID is null		-- input parameter must have a rider value / null checl
	begin
		set @errorMessage = 'RemoveRider: RiderID can''t be NULL'
		return -1
	end
	if not exists ( select * from Riders_RDB where RiderID = @RiderID)	-- check if rider exists in rider table
	begin
		set @errorMessage = 'RemoveRider: Rider ' + convert(nvarchar,@RiderID) + ' doesn''t exist '
		return -1
	end

	if (@forceDel =0 and exists (select * from Sessions_RDB where RiderID = @RiderID)) -- if were not forceing dont remove rider when it is sessions
	begin
		set @errorMessage = 'RemoveRider: ' + convert(nvarchar,@RiderID) + ' Currently in Sessions'
		return -1
	end

	if @forceDel = 0 -- not forcing just delete from riders
	delete from Riders_RDB where RiderID = @RiderID

	if @forceDel =1	-- if forceing delete rider from both sessions and riders
	begin
	delete from Sessions_RDB where RiderID = @RiderID	-- delete rider in sessions first cause of foreign key constraint
	delete from Riders_RDB where RiderID = @RiderID		-- delete rider in riders db
	end
go

--RemoveRider Test with force
declare @pRiderID as int
declare @force as bit =1	
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID =10
set @errMsg= 'OK'
exec @retVal = RemoveRider @forceDel = @force,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- RemoveRider null Test
declare @pRiderID as int
declare @force as bit =0
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID = null
set @errMsg= ''
exec @retVal = RemoveRider @forceDel = @force,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- RemoveRider riderID doesnt exist
declare @pRiderID as int
declare @force as bit =0
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID = 15
set @errMsg= ''
exec @retVal = RemoveRider @forceDel = @force,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Remove Rider no force with Session data  
-- need to add sessions data first
declare @pRiderID as int
declare @force as bit =0
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID = 15
set @errMsg= ''
exec @retVal = RemoveRider @forceDel = @force,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Remove Rider with force and Session data  
-- need to add sessions data first
declare @pRiderID as int
declare @force as bit =1
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID = 15
set @errMsg= ''
exec @retVal = RemoveRider @forceDel = @force,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

--------------------------------------------------------------------------------------------------------
------------------------------Add Session Stored Procedure and Tests -----------------------------------

if exists (select * from sysobjects where name = 'AddSession')		-- -- existence check and drop/recreate of SP add session
	drop procedure AddSession
go

create procedure AddSession
@RiderID as int,	
@BikeID as nvarchar(50),
@SessionDate as date,
@errorMessage as nvarchar(max) output
as
	if @RiderID is null			-- break if ridenamer is null
	begin
		set @errorMessage = 'AddSession: RiderID can''t be NULL'
		return -1
	end

	if @BikeID is null	-- null check for bikeId
	begin 
		set @errorMessage = 'AddSession: BikeID can''t be NULL'
		return -1
	end

	if @SessionDate is null		-- null check for session date
	begin 
		set @errorMessage = 'AddSession: Session Date can''t be NULL'
		return -1
	end

	if (DATEDIFF(dd,'1 Sep 2017',@SessionDate) < 0)		-- date check for session date. check that it is after sept 1 2017
	begin
		set @errorMessage = 'AddSession: Session Date must be a future date'
		return -1
	end

	if not exists ( select *from Riders_RDB where RiderID = @RiderID)	-- riderid in riders exist check
	begin
		set @errorMessage = 'AddSession: '+convert(nvarchar,@RiderID)+' does not exist'
		return -1
	end 

	if not exists ( select *from Bikes_RDB where BikeID = @BikeID) -- bikeid in bikes existence check
	begin
		set @errorMessage = 'AddSession: '+Convert(nvarchar,@BikeID)+' does not exist'
		return -1
	end 

	if exists ( select * from Sessions_RDB where BikeID = @BikeID) 
	begin
		set @errorMessage = 'AddSession: '+Convert(nvarchar,@BikeID)+' already assigned'
		return -1
	end

	insert into kfraser22.dbo.Sessions_RDB (RiderID,BikeID, SessionDate)
	values (@RiderID,@BikeID,@SessionDate)
	

go

-- Add Session Test  success test
declare @pRiderID as int
declare @pBIkeID as nvarchar(6)
declare @pSessionDate as date
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID = 10
set @pBIkeID = '003H-A'
set @pSessionDate = '1 Dec 2017'
set @errMsg= 'OK'
exec @retVal = AddSession @RiderID = @pRiderID ,@BikeID = @pBIkeID,@SessionDate = @pSessionDate, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go



-- Rider ID null Test
declare @pRiderID as int
declare @pBIkeID as nvarchar(6)
declare @pSessionDate as date
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID = null
set @pBIkeID = '000H-A'
set @pSessionDate = GETDATE()
set @errMsg= 'OK'
exec @retVal = AddSession @RiderID = @pRiderID ,@BikeID = @pBIkeID,@SessionDate = @pSessionDate, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Bike ID null test
declare @pRiderID as int
declare @pBIkeID as nvarchar(6)
declare @pSessionDate as date
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID = 10
set @pBIkeID = null
set @pSessionDate = GETDATE()
set @errMsg= 'OK'
exec @retVal = AddSession @RiderID = @pRiderID ,@BikeID = @pBIkeID,@SessionDate = @pSessionDate, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Rider ID does not exist test
declare @pRiderID as int
declare @pBIkeID as nvarchar(6)
declare @pSessionDate as date
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID = 113
set @pBIkeID = '000H-A'
set @pSessionDate = convert (date,GetDate(),107)
set @errMsg= 'OK'
exec @retVal = AddSession @RiderID = @pRiderID ,@BikeID = @pBIkeID,@SessionDate = @pSessionDate, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go


-- Bike ID does not exist test
declare @pRiderID as int
declare @pBIkeID as nvarchar(6)
declare @pSessionDate as date
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID = 10
set @pBIkeID = 'bikey'
set @pSessionDate = convert (date,GetDate(),107)
set @errMsg= 'OK'
exec @retVal = AddSession @RiderID = @pRiderID ,@BikeID = @pBIkeID,@SessionDate = @pSessionDate, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- SessionDate is null test
declare @pRiderID as int
declare @pBIkeID as nvarchar(6)
declare @pSessionDate as date
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID = 10
set @pBIkeID = '000H-A'
set @pSessionDate = null
set @errMsg= 'OK'
exec @retVal = AddSession @RiderID = @pRiderID ,@BikeID = @pBIkeID,@SessionDate = @pSessionDate, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- date is invlaid check
declare @pRiderID as int
declare @pBIkeID as nvarchar(6)
declare @pSessionDate as date
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID = 10
set @pBIkeID = '000H-A'
set @pSessionDate ='August 1 2017'
set @errMsg= 'OK'
exec @retVal = AddSession @RiderID = @pRiderID ,@BikeID = @pBIkeID,@SessionDate = @pSessionDate, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Bike already assigned test
declare @pRiderID as int
declare @pBIkeID as nvarchar(6)
declare @pSessionDate as date
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID = 10
set @pBIkeID = '000H-A'
set @pSessionDate = '2 Dec 2017'
set @errMsg= 'OK'
exec @retVal = AddSession @RiderID = @pRiderID ,@BikeID = @pBIkeID,@SessionDate = @pSessionDate, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

select * from Sessions_RDB



--------------------------------------------------------------------------------------------------------
------------------------------ Update Session Stored Prodcedure And Tests ------------------------------


if exists (select * from sysobjects where name = 'UpdateSession') -- existence check and drop/recreate of SP update session
	drop procedure UpdateSession
go


-- increase number of laps by set num
create procedure UpdateSession
@RiderID as int,		
@BikeID as nvarchar(50),
@SessionDate as date,
@lapsToAdd as int,
@errorMessage as nvarchar(max) output

as
declare @testLaps as int

	if @RiderID is null												-- rider id null check
	begin
		set @errorMessage = 'Update Session: Rider ID can''t be NULL' 
		return -1
	end
	if @BikeID is null					-- bike id bull check and return
	begin 
		set @errorMessage = 'UpdateSession: BikeID can''t be NULL'
		return -1
	end

	if @SessionDate is null					-- session id null check and return
	begin 
		set @errorMessage = 'UpdateSession: Session Date can''t be NULL'
		return -1
	end

	if not exists (select * from Sessions_RDB where RiderID = @RiderID)		-- exists checks for rider and return if not
	begin
		set @errorMessage = 'UpdateSesson: '+ convert(nvarchar,@RiderID) + ' doesn''t exist'
		return -1
	end

	if not exists ( select *from Bikes_RDB where BikeID = @BikeID)		-- exist check for bikeid and return if not
	begin
		set @errorMessage = 'UpdateSession: '+convert(nvarchar,@BikeID)+' does not exist'
		return -1
	end 
	if not exists (select * from Sessions_RDB where SessionDate = @SessionDate)		-- exist check for sessions in session db and return if not
	begin
	set 
		@errorMessage = 'UpdateSession: '+convert(nvarchar,@SessionDate,107)+' SessionDate does not exist'
		return -1
	end

	select				-- select to find current laps with the current keys that passed other tests
		@testLaps = Laps
		from Sessions_RDB
		where RiderID = @RiderID
		and BikeID = @BikeID and SessionDate = @SessionDate
	
	if (@testLaps > @lapsToAdd)		-- check if existing laps is smaller then laps to add
	begin
		set @errorMessage = 'UpdateSession: Laps added must be greater then Current Laps'
		return -1
	end

	
	update kfraser22.dbo.Sessions_RDB	-- update laps in sessions after checks
	set Laps = Laps + @lapsToAdd
	where SessionDate = @SessionDate
go

--Update Session Tests
-- Update Session Success test
declare @pRiderID as int
declare @pBIkeID as nvarchar(6)
declare @pSessionDate as date
declare @pLapstoAdd as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID = 10
set @pBIkeID = '003H-A'
set @pSessionDate = '1 Dec 2017'
set @pLapstoAdd = 10
set @errMsg= 'OK'
exec @retVal = UpdateSession @RiderID = @pRiderID ,@BikeID = @pBIkeID,@SessionDate = @pSessionDate,@lapsToAdd =@pLapstoAdd, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

--select * from Sessions_RDB

-- Key Params dont match, Rider does not match
declare @pRiderID as int
declare @pBIkeID as nvarchar(6)
declare @pSessionDate as date
declare @pLapstoAdd as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID = 15
set @pBIkeID = '000H-A'
set @pSessionDate = GETDATE()
set @pLapstoAdd = 5
set @errMsg= 'OK'
exec @retVal = UpdateSession @RiderID = @pRiderID ,@BikeID = @pBIkeID,@SessionDate = @pSessionDate,@lapsToAdd =@pLapstoAdd, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Key Params dont match, Bike does not match
declare @pRiderID as int
declare @pBIkeID as nvarchar(6)
declare @pSessionDate as date
declare @pLapstoAdd as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID = 10
set @pBIkeID = 'Bikey'
set @pSessionDate = GETDATE()
set @pLapstoAdd = 5
set @errMsg= 'OK'
exec @retVal = UpdateSession @RiderID = @pRiderID ,@BikeID = @pBIkeID,@SessionDate = @pSessionDate,@lapsToAdd =@pLapstoAdd, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Key Params dont match, Sessiondate does not match
declare @pRiderID as int
declare @pBIkeID as nvarchar(6)
declare @pSessionDate as date
declare @pLapstoAdd as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID = 10
set @pBIkeID = '000H-A'
set @pSessionDate = '27 Dec 2017'
set @pLapstoAdd = 5
set @errMsg= 'OK'
exec @retVal = UpdateSession @RiderID = @pRiderID ,@BikeID = @pBIkeID,@SessionDate = @pSessionDate,@lapsToAdd =@pLapstoAdd, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Laps adding is less than laps existing
declare @pRiderID as int
declare @pBIkeID as nvarchar(6)
declare @pSessionDate as date
declare @pLapstoAdd as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pRiderID = 10
set @pBIkeID = '000H-A'
set @pSessionDate = '2 Dec 2017'
set @pLapstoAdd = 1
set @errMsg= 'OK'
exec @retVal = UpdateSession @RiderID = @pRiderID ,@BikeID = @pBIkeID,@SessionDate = @pSessionDate,@lapsToAdd =@pLapstoAdd, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go




--------------------------------------------------------------------------------------------------------
------------------------------ Remove Class Stored Prodcedures and tests -------------------------------

--- Remove Class sp
if exists (select * from sysobjects where name = 'RemoveClass')			-- SP existence check and drop / recreate 
	drop procedure RemoveClass
go

create procedure RemoveClass
@forceDel as bit,
@ClassID as nvarchar(6),
@RiderID as int,
@errorMessage as nvarchar(max) output
as
	if @ClassID is null								-- class id null check
	begin
		set @errorMessage = 'RemoveClass: ClassID can''t be NULL'	
		return -1
	end
	if not exists ( select * from Classes_RDB where ClassID like @ClassID) -- existence check for classes in class db return if not
	begin
		set @errorMessage = 'RemoveClass: Class ' + @ClassID + ' doesn''t exist '
		return -1
	end
	if (@forceDel = 0 and exists ( select * from Riders_RDB where ClassID = @ClassID))--check force and check for class in riders error if it is in riders
	begin
		set @errorMessage = 'RemoveClass: ' + @ClassID + ' Currently in Riders'
		return -1
	end
	if @forceDel =0
	delete from Classes_RDB where ClassID = @ClassID -- delete class after checks


	if @forceDel =1
	begin
		select @RiderID = RiderID	-- get riderId to delete for manual delete cascading
		from Riders_RDB
		where ClassID = @ClassID
	delete from Classes_RDB where ClassID = @ClassID -- delete class with forced
	

	delete from Riders_RDB where ClassID = @ClassID -- force delete from riders as well
	delete from Sessions_RDB where RiderID = @RiderID -- force delete rider in sessions as well

	end

	set @errorMessage = 'OK'	-- set errr message and return 0
	return 0

go



--Remove Class Tests
-- Success Test
declare @pClassID as char(6)
declare @pRiderID as int
declare @force as bit =0
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pClassID = 'motogp'
set @errMsg= ''
exec @retVal = RemoveClass @forceDel = @force, @ClassID = @pClassID ,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go


-- null Test
declare @pClassID as char(6)
declare @pRiderID as int
declare @force as bit =0
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pClassID = null
set @errMsg= ''
exec @retVal = RemoveClass @forceDel = @force, @ClassID = @pClassID ,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Class Exists Test no force into riders
declare @pClassID as nvarchar(6)
declare @pRiderID as int
declare @force as bit =0
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pClassID = 'motogp'
set @errMsg= ''
exec @retVal = RemoveClass @forceDel = @force, @ClassID = @pClassID ,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Class Exists Test with force into riders
declare @pClassID as nvarchar(6)
declare @pRiderID as int
declare @force as bit =1
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pClassID = 'moto_1'
set @errMsg= ''
exec @retVal = RemoveClass @forceDel = @force, @ClassID = @pClassID ,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go


--------------------------------------------------------------------------------------------------------
------------------------------ Class Info Stored Prodcedure and Tests ----------------------------------




if exists (select * from sysobjects where name = 'ClassInfo')
	drop procedure ClassInfo
go

create procedure ClassInfo
@ClassID as nvarchar(6),		-- classID input to be used in SP
@RiderID as int,
@errorMessage as nvarchar(max) output

as
declare @cDes as nvarchar
	if @ClassID is null			-- classID null check and return if true
	begin
		set @errorMessage = 'ClassInfo: ClassID can''t be NULL'
		return -1
	end
	if not exists ( select * from Classes_RDB where ClassID like @ClassID) -- class ID existence check and return if not existing
	begin
		set @errorMessage = 'ClassInfo: Class ' + @ClassID + ' doesn''t exist '
		return -1
	end


	if @RiderID is null		-- should show all riders in database
		begin
		select
			c.ClassID, 
			ClassDescription,
			RiderID,
			Name


			from Classes_RDB as c left outer join		-- join on classes, riders, 
				Riders_RDB as R 
				on r.ClassID = @ClassID
					where c.ClassID = @ClassID
		end
	
	else
		begin
			if (select Count(*) from Riders_RDB ) =0	-- check that riders table  is not empty
			begin
				set @errorMessage = 'ClassInfo: Riders Table is empty '
				return -1
			end

			if not exists ( select * from Riders_RDB where RiderID = @RiderID)		-- check that rider exists
			begin
				set @errorMessage = 'ClassInfo: Rider ' + convert(nvarchar,@RiderID) + ' doesn''t exist '
				return -1
			end

			
			select				-- no errors select display from riders and class
			c.ClassID, 
			ClassDescription,
			RiderID,
			r.Name
			from Classes_RDB as C left outer join  -- join on classes, riders, 
			Riders_RDB as R on c.ClassID = r.ClassID
			where c.ClassID = @ClassID and r.RiderID = @RiderID

		end

go

-- Class info tests
-- Class info Test no rider
declare @pClassID as nvarchar(6)
declare @pRiderID as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pClassID = 'motogp'
set @pRiderID = null
set @errMsg= ''
exec @retVal = ClassInfo  @ClassID = @pClassID ,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go


-- Null Class info Test
declare @pClassID as nvarchar(6)
declare @pRiderID as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pClassID = null
set @pRiderID = null
set @errMsg= ''
exec @retVal = ClassInfo  @ClassID = @pClassID ,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Rider ID Null Test ??
declare @pClassID as nvarchar(6)
declare @pRiderID as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pClassID = 'motogp'
set @pRiderID = null
set @errMsg= ''
exec @retVal = ClassInfo  @ClassID = @pClassID ,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Rider ID not null Test
declare @pClassID as nvarchar(6)
declare @pRiderID as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pClassID = 'moto_2'
set @pRiderID = 10
set @errMsg= ''
exec @retVal = ClassInfo  @ClassID = @pClassID ,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- No Riders test ?????
declare @pClassID as nvarchar(6)
declare @pRiderID as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pClassID = 'moto_2'
set @pRiderID = 9
set @errMsg= ''
exec @retVal = ClassInfo  @ClassID = @pClassID ,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Class ID doesnt exist test
declare @pClassID as nvarchar(6)
declare @pRiderID as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pClassID = 'classy'
set @pRiderID = null
set @errMsg= ''
exec @retVal = ClassInfo  @ClassID = @pClassID ,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Rider ID doesnt exist test
declare @pClassID as nvarchar(6)
declare @pRiderID as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pClassID = 'motogp'
set @pRiderID = 37
set @errMsg= ''
exec @retVal = ClassInfo  @ClassID = @pClassID ,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go


--------------------------------------------------------------------------------------------------------
------------------------------ Class Summary Stored Prodcedure and Tests -----------------------------------------

if exists (select * from sysobjects where name = 'ClassSummary')
	drop procedure ClassSummary
go

create procedure ClassSummary
@ClassID as nvarchar(6),
@RiderID as int,
@errorMessage as nvarchar(max) output
as
	if (select Count(*) from Riders_RDB ) =0	-- check that riders table  is not empty	return if is
			begin
				set @errorMessage = 'ClassSummary: Riders Table is empty '
				return -1
			end
	if (select Count(*) from Sessions_RDB ) =0	-- check that sessions table  is not empty	return  if is
			begin
				set @errorMessage = 'ClassSummarry: Sessions Table is empty '
				return -1
			end

	if (not exists ( select * from Classes_RDB where ClassID like @ClassID))and @ClassID is not null --  existence and noy null check for ClassID
		begin
			set @errorMessage = 'ClassSummary: Class ' + convert(nvarchar,@ClassID) + ' doesn''t exist '
			return -1
		end
	if (not exists ( select * from Riders_RDB where RiderID like @RiderID)) and @RiderID is not null	-- existence and not null check for ClassID
		begin
			set @errorMessage = 'ClassSummary: Rider ' + convert(nvarchar,@RiderID) + ' doesn''t exist '
			return -1
		end

	
	if (@RiderID is null and @ClassID is null)		-- will show all classes with nulls in the rest of table
		begin									    -- no rider to get other info for
		select
			c.ClassID, 
			ClassDescription,
			r.RiderID,
			Name,
			avg(coalesce(s.Laps,0)) as 'Laps Avg',  -- zero the nulls
			min(coalesce(s.Laps,0)) as 'Laps Min',
			max(coalesce(s.Laps,0)) as 'Laps Max'
			from Classes_RDB as c left outer join
				Riders_RDB as R 
				on r.ClassID = c.ClassID
					left outer join Sessions_RDB as s
					on r.RiderID = s.RiderID
			group by c.ClassID, ClassDescription, r.RiderID, Name
		return 0
		end

		if (@ClassID is null)		-- give a specific riders roll up
		begin
		select
			c.ClassID, 
			ClassDescription,
			r.RiderID,
			Name,
			avg(coalesce(s.Laps,0)) as 'Laps Avg', -- zero the nulls
			min(coalesce(s.Laps,0)) as 'Laps Min',
			max(coalesce(s.Laps,0)) as 'Laps Max'
			from Classes_RDB as c left outer join
				Riders_RDB as R 
				on r.ClassID = c.ClassID			-- join on class, sessions, riders
					left outer join Sessions_RDB as s
					on r.RiderID = s.RiderID
						
			group by c.ClassID, ClassDescription, r.RiderID, Name
			having r.RiderID = @RiderID
		return 0
		end

		if (@RiderID is null)	-- give rollup for all riders in that class
		begin
		select
			c.ClassID, 
			ClassDescription,
			r.RiderID,
			Name,
			avg(coalesce(s.Laps,0)) as 'Laps Avg', -- zero the nulls
			min(coalesce(s.Laps,0)) as 'Laps Min',
			max(coalesce(s.Laps,0)) as 'Laps Max'
			from Classes_RDB as c left outer join
				Riders_RDB as R 
				on r.ClassID = c.ClassID			-- join on class, sessions, riders
					left outer join Sessions_RDB as s
					on r.RiderID = s.RiderID
						
			group by c.ClassID, ClassDescription, r.RiderID, Name
			having c.ClassID = @ClassID
		return 0
		end

		if (@RiderID is not null and @ClassID is not null) -- rollup for class and rider
		begin
		select
			c.ClassID, 
			ClassDescription,
			r.RiderID,
			Name,
			avg(coalesce(s.Laps,0)) as 'Laps Avg', -- zero the nulls
			min(coalesce(s.Laps,0)) as 'Laps Min',
			max(coalesce(s.Laps,0)) as 'Laps Max'
			from Classes_RDB as c left outer join
				Riders_RDB as R 
				on r.ClassID = c.ClassID					-- join on class, sessions, riders
					left outer join Sessions_RDB as s
					on r.RiderID = s.RiderID
						
			group by c.ClassID, ClassDescription, r.RiderID, Name
			having c.ClassID = @ClassID and r.RiderID =@RiderID
		return 0
		end
go

-- Class Summary Tests 
-- Class Summary will null riders and class
-- will display all classes and riders with info
declare @pClassID as nvarchar(6)
declare @pRiderID as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pClassID = null
set @pRiderID = null
set @errMsg= 'OK'
exec @retVal = ClassSummary @ClassID = @pClassID ,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Class Summary with null class
-- will display specificed riders summary of class/laps
declare @pClassID as nvarchar(6)
declare @pRiderID as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pClassID = null
set @pRiderID = 10
set @errMsg= 'OK'
exec @retVal = ClassSummary @ClassID = @pClassID ,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Class Summary with null rider
-- will display all riders in that class with laps info
declare @pClassID as nvarchar(6)
declare @pRiderID as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pClassID = 'moto_2'
set @pRiderID = null
set @errMsg= 'OK'
exec @retVal = ClassSummary @ClassID = @pClassID ,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go


-- Class Summary with class that doesnt exist
-- will error
declare @pClassID as nvarchar(6)
declare @pRiderID as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pClassID = 'classy'
set @pRiderID = null
set @errMsg= 'OK'
exec @retVal = ClassSummary @ClassID = @pClassID ,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Class Summary with rider that doesnt exist
-- will error
declare @pClassID as nvarchar(6)
declare @pRiderID as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pClassID = 'motogp'
set @pRiderID = 26
set @errMsg= 'OK'
exec @retVal = ClassSummary @ClassID = @pClassID ,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go

-- Class Summary with valid rider and class  -- how should this error
declare @pClassID as nvarchar(6)
declare @pRiderID as int
declare @errMsg as nvarchar(max)
declare @retVal as int = 0
set @pClassID = 'motogp'
set @pRiderID = 10
set @errMsg= 'OK'
exec @retVal = ClassSummary @ClassID = @pClassID ,@RiderID =@pRiderID, @errorMessage = @errMsg output
if @retVal >= 0 print 'Error Code Invalid'
select @errMsg as 'ErrorMessage', @retVal as 'Return Code'
go



select * from kfraser22.dbo.Classes_RDB