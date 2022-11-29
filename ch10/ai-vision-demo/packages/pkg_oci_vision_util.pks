create or replace package pkg_oci_vision_util
as
  gc_vision_endpoint constant varchar2(500) := 'https://vision.aiservice.us-phoenix-1.oci.oraclecloud.com';
  gc_namespace constant varchar2(30) := 'axcew3ppxexo';
  gc_credential_static_id constant varchar2(50) := 'OCI_CREDENTIALS';

  function f_analyze_document(
    p_bucket_name in varchar2
    , p_filename in varchar2
  ) return blob;
end pkg_oci_vision_util;
/