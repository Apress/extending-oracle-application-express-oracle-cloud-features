declare
  l_photo photo%rowtype;
  l_blob_content blob;
  l_content_type varchar2(32767);
  l_content_length number;
  l_if_none_matched varchar2(32767);
begin
  -- Retrive the HTTP header variable If-None-Match if available.
  l_if_none_matched := regexp_replace(
    owa_util.get_cgi_env('HTTP_IF_NONE_MATCH'), '"', '');
  apex_debug.info('If-None-Matched=' || l_if_none_matched);

  if :APP_PHOTO_ID is not null then
    for photo in (
      select
        photo_id
        , filename
        , object_name
        , lower(standard_hash(
            to_char(photo_id)
            || to_char(coalesce(updated_on, created_on), 'YYYYDDMMHH24MISS')
          )) as etag
      from photo
      where photo_id = :APP_PHOTO_ID
    ) loop
      if l_if_none_matched is not null and l_if_none_matched = photo.etag then
        -- If the hash value found in the If-None-Match matches the geneated
        -- ETag value, return a HTTP 304 (Not Modified) status so that the
        -- browser will load the image from its cache instead.
        --
        -- Note: The ETag and Cache-Control HTTP headers must be set or
        --       subsequent calls will require an OCI download even though the
        --       object has not been modified.
        sys.htp.init;
        owa_util.status_line(nstatus => 304, bclose_header => false);
        sys.htp.p('ETag: "' || photo.etag || '"');
        sys.htp.p('Cache-Control: max-age=0');
      else
        -- If the value of If-None-Match is either missing or different, then
        -- proceed to retrieve the object from the bucket.
        pkg_oci_os_util.p_get_object(
          p_base_url => :G_BASE_URL
          , p_bucket_name => :APP_BUCKET_NAME
          , p_object_name => photo.object_name
          , p_oci_web_credential_id => :G_OCI_WEB_CREDENTIAL_ID
          , p_blob_content => l_blob_content
          , p_content_type => l_content_type
          , p_content_length => l_content_length
        );

        sys.htp.init;

        if l_content_type is not null then
          sys.owa_util.mime_header(trim(l_content_type), false);
        end if;
        sys.htp.p('Content-length: ' || to_char(l_content_length));
        sys.htp.p(
          'Content-Disposition: '
          || coalesce(:APP_CONTENT_DISPOSITION, 'attachment')
          || '; filename="'
          || photo.filename || '"' );

        -- Set the HTTP header ETag and Cache-Control to allow the browser to
        -- load the image from its cache instead.
        sys.htp.p('ETag: "' || photo.etag || '"');
        sys.htp.p('Cache-Control: max-age=0');
        sys.owa_util.http_header_close;
        sys.wpg_docload.download_file(l_blob_content);
      end if;

      begin
        apex_application.stop_apex_engine;
      exception
        when others then
          null; -- Do nothing
      end;
    end loop;
  end if;
exception
  when others then
    owa_util.status_line(
      nstatus => 500
      , creason => sqlerrm
    );
end;