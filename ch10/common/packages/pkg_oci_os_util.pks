create or replace package pkg_oci_os_util
as
  gc_objectstorage_endpoint constant varchar2(500) := 'https://objectstorage.us-phoenix-1.oraclecloud.com';
  gc_namespace constant varchar2(30) := 'axcew3ppxexo';
  gc_credential_static_id constant varchar2(50) := 'OCI_CREDENTIALS';

  procedure p_upload_object(
    p_bucket_name in varchar2
    , p_file_blob in blob
    , p_filename in varchar2
    , p_mime_type in varchar2
  );

  procedure p_delete_object(
    p_bucket_name in varchar2
    , p_filename in varchar2
  );
end pkg_oci_os_util;
/