select * into l_photo
from photo where photo_id = :P3_PHOTO_ID;

delete from photo where photo_id = l_photo.photo_id;

pkg_oci_os_util.p_delete_object(
  p_base_url => :G_BASE_URL
  , p_bucket_name => :G_PHOTOS_BUCKET_NAME
  , p_object_name => l_photo.object_name
  , p_oci_web_credential_id => :G_OCI_WEB_CREDENTIAL_ID
);