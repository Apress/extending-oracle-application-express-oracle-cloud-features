select * into l_photo
from photo where photo_id = :P3_PHOTO_ID;

update photo
set
  title = :P3_TITLE
  , description = :P3_DESCRIPTION
where photo_id = l_photo.photo_id;

for file in (
  select * from apex_application_temp_files
  where name = :P3_FILE
) loop
  l_photo.object_name := pkg_oci_os_util.f_generate_object_name(
    p_photo_id => l_photo.photo_id
    , p_filename => file.filename);

  update photo
  set filename = file.filename
    , mime_type = file.mime_type
    , object_name = l_photo.object_name
  where photo_id = l_photo.photo_id;

  -- If the filename does not match what is on record, then delete it first.
  if l_photo.filename <> file.filename then
    pkg_oci_os_util.p_delete_object(
      p_base_url => :G_BASE_URL
      , p_bucket_name => :G_PHOTOS_BUCKET_NAME
      , p_object_name => pkg_oci_os_util.f_generate_object_name(
          p_photo_id => l_photo.photo_id
          , p_filename => l_photo.filename)
      , p_oci_web_credential_id => :G_OCI_WEB_CREDENTIAL_ID
    );
  end if;

  pkg_oci_os_util.p_upload_object(
    p_base_url => :G_BASE_URL
    , p_bucket_name => :G_PHOTOS_BUCKET_NAME
    , p_object_name => l_photo.object_name
    , p_blob_content => file.blob_content
    , p_mime_type => file.mime_type
    , p_oci_web_credential_id => :G_OCI_WEB_CREDENTIAL_ID
  );
end loop;