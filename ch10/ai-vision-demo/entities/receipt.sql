/**
 * TODO_Comments
 *
 * Notes:
 *  -
 *
 * Related Tickets:
 *  -
 *
 * @author TODO
 * @created TODO
 */
--
-- drop table receipt cascade constraints purge;

create table receipt (
	receipt_id number generated always as identity
	, scanned_image blob not null
	, filename varchar2(1000) not null
	, mime_type varchar2(100) not null
	, receipt_data clob
	, created_by varchar2(30)
	, created_on timestamp with local time zone
	, updated_by varchar2(30)
	, updated_on timestamp with local time zone
	, constraint receipt_pk primary key (receipt_id)
	,constraint receipt_chk01 check (receipt_data is json)
)
/


create or replace trigger receipt_biu
before insert or update on receipt
for each row
declare
begin
	if inserting then
		:new.created_by := coalesce(sys_context('APEX$SESSION','APP_USER'), user);
		:new.created_on := localtimestamp;
	else
		:new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'), user);
		:new.updated_on := localtimestamp;
	end if;
end;
/