for file in (
  select * from apex_application_temp_files
  where name = :P3_FILE
) loop
  insert into photo(
    title
    , description
    , filename
    , mime_type
  ) values (
    :P3_TITLE
    , :P3_DESCRIPTION
    , file.filename
    , file.mime_type
  ) returning photo_id into l_photo.photo_id;

  l_photo.object_name := pkg_oci_os_util.f_generate_object_name(
      p_photo_id => l_photo.photo_id
      , p_filename => file.filename);

  update photo
  set object_name = l_photo.object_name
  where photo_id = l_photo.photo_id;

  pkg_oci_os_util.p_upload_object(
    p_base_url => :G_BASE_URL
    , p_bucket_name => :G_PHOTOS_BUCKET_NAME
    , p_object_name => l_photo.object_name
    , p_blob_content => file.blob_content
    , p_mime_type => file.mime_type
    , p_oci_web_credential_id => :G_OCI_WEB_CREDENTIAL_ID
  );
end loop;