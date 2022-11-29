create or replace package body pkg_oci_os_util
as
  function f_generate_object_name(
    p_photo_id photo.photo_id%type
    , p_filename photo.filename%type
  ) return varchar2 as
    l_return varchar2(32767);
  begin
    with file_parts as (
      select
        substr(
          p_filename
          , 1
          , (instr(p_filename, '.', -1, 1) -1)
        ) as file_name
        , substr(
            p_filename
            , (instr(p_filename, '.', -1, 1) + 1)
            , length(p_filename)
        ) as file_extension
      from dual
    )
    select
      lower(
        standard_hash(
          'P' || lpad(p_photo_id, 38, 0)
          || '|'
          || file_parts.file_name
        ))
      || '.'
      || file_parts.file_extension
    into l_return
    from file_parts;

    return l_return;
  end f_generate_object_name;

  procedure p_upload_object(
    p_base_url in varchar2
    , p_bucket_name in varchar2
    , p_object_name in varchar2
    , p_blob_content in blob
    , p_mime_type varchar2
    , p_oci_web_credential_id in varchar2
  ) as
    l_request_url varchar2(32767);

    l_response clob;
  begin
    l_request_url := p_base_url || '/b/' || p_bucket_name
        || '/o/' || apex_util.url_encode(p_object_name);

    apex_debug.info('l_request_url = ' || l_request_url);

    apex_web_service.g_request_headers(1).name := 'Content-Type';
    apex_web_service.g_request_headers(1).value := p_mime_type;

    l_response := apex_web_service.make_rest_request(
      p_url => l_request_url
      , p_http_method => 'PUT'
      , p_body_blob => p_blob_content
      , p_credential_static_id => p_oci_web_credential_id
    );

    if apex_web_service.g_status_code != 200 then
      raise_application_error(
        -20001
        , l_response || chr(10) || 'status_code='
            || to_char(apex_web_service.g_status_code)
      );
    end if;
  end p_upload_object;

  procedure p_delete_object(
    p_base_url in varchar2
    , p_bucket_name in varchar2
    , p_object_name in varchar2
    , p_oci_web_credential_id in varchar2
  ) as
    l_request_url varchar2(32767);

    l_response clob;
  begin
    l_request_url := p_base_url || '/b/' || p_bucket_name
      || '/o/' || apex_util.url_encode(p_object_name);

    apex_debug.info('l_request_url = ' || l_request_url);

    l_response := apex_web_service.make_rest_request(
      p_url => l_request_url
      , p_http_method => 'DELETE'
      , p_credential_static_id => p_oci_web_credential_id
    );

    if apex_web_service.g_status_code != 204 then
      raise_application_error(
        -20003
        , l_response || chr(10) || 'status_code='
            || to_char(apex_web_service.g_status_code)
      );
    end if;
  end p_delete_object;

  procedure p_get_object(
    p_base_url in varchar2
    , p_bucket_name in varchar2
    , p_object_name in varchar2
    , p_oci_web_credential_id in varchar2
    , p_blob_content out blob
    , p_content_type out varchar2
    , p_content_length out number
  )
  as
    l_request_url varchar2(32767);

    l_response blob;
  begin
    l_request_url := p_base_url || '/b/' || p_bucket_name
        || '/o/' || apex_util.url_encode(p_object_name);

    apex_debug.info('l_request_url = ' || l_request_url);

    l_response := apex_web_service.make_rest_request_b(
      p_url => l_request_url
      , p_http_method => 'GET'
      , p_credential_static_id => p_oci_web_credential_id
    );

    if apex_web_service.g_status_code != 200 then
      raise_application_error(
        -20004
        , 'status_code=' || to_char(apex_web_service.g_status_code)
      );
    else
      for i in 1..apex_web_service.g_headers.count
      loop
        apex_debug.info(apex_web_service.g_headers(i).name || '='
          || apex_web_service.g_headers(i).value );

        if lower(apex_web_service.g_headers(i).name) = 'content-length' then
          p_content_length := to_number(apex_web_service.g_headers(i).value);
        end if;

        if lower(apex_web_service.g_headers(i).name) = 'content-type' then
          p_content_type := apex_web_service.g_headers(i).value;
        end if;
      end loop;

      p_blob_content := l_response;
    end if;
  end p_get_object;
end pkg_oci_os_util;
/