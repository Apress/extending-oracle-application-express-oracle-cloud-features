create or replace package pkg_receipt
as
  gc_bucket_name constant varchar2(30) := 'ai-vision-demo';

  procedure p_create(
    p_scanned_image in blob
    , p_filename in varchar2
    , p_mime_type in varchar2
    , p_receipt_id out number
  );
end pkg_receipt;
/