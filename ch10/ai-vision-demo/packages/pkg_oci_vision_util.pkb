create or replace package body pkg_oci_vision_util
as
  function f_analyze_document(
    p_bucket_name in varchar2
    , p_filename in varchar2
  ) return blob
  as
    c_path constant varchar2(100) := '/20220125/actions/analyzeDocument';

    l_response blob;
  begin
    apex_web_service.g_request_headers(1).name := 'Content-Type';
    apex_web_service.g_request_headers(1).value := 'application/json';

    l_response := apex_web_service.make_rest_request_b(
      p_url => pkg_oci_vision_util.gc_vision_endpoint || c_path
      , p_http_method => 'POST'
      , p_body =>
          json_object(
            'document' value json_object(
              'source' value 'OBJECT_STORAGE'
              , 'namespaceName' value pkg_oci_vision_util.gc_namespace
              , 'bucketName' value p_bucket_name
              , 'objectName' value p_filename
            )
            , 'features' value json_array(json_object('featureType' value
                'KEY_VALUE_DETECTION') format json)
          )
      , p_credential_static_id => pkg_oci_vision_util.gc_credential_static_id
    );

    if apex_web_service.g_status_code != 200 then
      raise_application_error(-20003, 'Analyze Document failed: '
        || apex_web_service.g_status_code);
      apex_debug.error('HTTP Status Code: ' || apex_web_service.g_status_code);
      apex_debug.error(to_clob(l_response));
    end if;

    return l_response;
  end f_analyze_document;
end pkg_oci_vision_util;
/