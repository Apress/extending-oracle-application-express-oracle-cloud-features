create or replace package body pkg_receipt
as
  procedure p_create(
    p_scanned_image in blob
    , p_filename in varchar2
    , p_mime_type in varchar2
    , p_receipt_id out number
  )
  as
    l_receipt_data blob;
  begin
    pkg_oci_os_util.p_upload_object(
      p_bucket_name => pkg_receipt.gc_bucket_name
      , p_file_blob => p_scanned_image
      , p_filename => p_filename
      , p_mime_type => p_mime_type
    );

    l_receipt_data := pkg_oci_vision_util.f_analyze_document(
      p_bucket_name => pkg_receipt.gc_bucket_name
      , p_filename => p_filename
    );

    pkg_oci_os_util.p_delete_object(
      p_bucket_name => pkg_receipt.gc_bucket_name
      , p_filename => p_filename
    );

    insert into receipt(
      scanned_image
      , filename
      , mime_type
      , receipt_data
    ) values (
      p_scanned_image
      , p_filename
      , p_mime_type
      , to_clob(l_receipt_data)
    ) returning receipt_id into p_receipt_id;
  end p_create;
end pkg_receipt;
/