-- drop table photo cascade constraints purge;

create table photo (
  photo_id number generated always as identity
  , title varchar2(500) not null
  , description varchar2(2000)
  , object_name varchar2(1024)
  , filename varchar2(500)
  , mime_type varchar2(100)
  , created_by varchar2(30)
  , created_on timestamp with local time zone
  , updated_by varchar2(30)
  , updated_on timestamp with local time zone
  , constraint photo_pk primary key (photo_id)
)
/

create or replace trigger photo_biu
before insert or update on photo
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