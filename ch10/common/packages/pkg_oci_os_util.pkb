create or replace package body pkg_oci_os_util
as
  procedure p_upload_object(
    p_bucket_name in varchar2
    , p_file_blob in blob
    , p_filename in varchar2
    , p_mime_type in varchar2
  )
  as
    l_request_url varchar2(32767);
    l_content_length number;

    l_response clob;
  begin
    l_request_url := pkg_oci_os_util.gc_objectstorage_endpoint
      || '/n/' || pkg_oci_os_util.gc_namespace
      || '/b/' || p_bucket_name
      || '/o/' || apex_util.url_encode(p_filename);

    apex_web_service.g_request_headers(1).name := 'Content-Type';
    apex_web_service.g_request_headers(1).value := p_mime_type;

    l_response := apex_web_service.make_rest_request(
      p_url => l_request_url
      , p_http_method => 'PUT'
      , p_body_blob => p_file_blob
      , p_credential_static_id => pkg_oci_os_util.gc_credential_static_id
    );

    if apex_web_service.g_status_code != 200 then
      raise_application_error(-20001, 'Upload object failed: '
        || apex_web_service.g_status_code);
      apex_debug.error('HTTP Status Code: ' || apex_web_service.g_status_code);
      apex_debug.error(l_response);
    end if;
  end p_upload_object;

  procedure p_delete_object(
    p_bucket_name in varchar2
    , p_filename in varchar2
  )
  as
    l_request_url varchar2(32767);
    l_response clob;
  begin
    l_request_url := pkg_oci_os_util.gc_objectstorage_endpoint
      || '/n/' || pkg_oci_os_util.gc_namespace
      || '/b/' || p_bucket_name
      || '/o/' || apex_util.url_encode(p_filename);

    l_response := apex_web_service.make_rest_request(
      p_url => l_request_url
      , p_http_method => 'DELETE'
      , p_credential_static_id => pkg_oci_os_util.gc_credential_static_id
    );

    if apex_web_service.g_status_code != 204 then
      raise_application_error(-20002, 'Delete object failed: '
        || apex_web_service.g_status_code);
      apex_debug.error('HTTP Status Code: ' || apex_web_service.g_status_code);
      apex_debug.error(l_response);
    end if;
  end p_delete_object;
end pkg_oci_os_util;
/