create or replace package pkg_oci_os_util
as
  /**
  * TODO_Comments
  *
  * Notes:
  *  -
  *
  * Related Tickets:
  *  -
  *
  * @author TODO
  * @created TODO
  * @param TODO
  * @return TODO
  */
  --
  function f_generate_object_name(
    p_photo_id photo.photo_id%type
    , p_filename photo.filename%type
  ) return varchar2;

  procedure p_upload_object(
    p_base_url in varchar2
    , p_bucket_name in varchar2
    , p_object_name in varchar2
    , p_blob_content in blob
    , p_mime_type in varchar2
    , p_oci_web_credential_id in varchar2
  );

  procedure p_delete_object(
    p_base_url in varchar2
    , p_bucket_name in varchar2
    , p_object_name in varchar2
    , p_oci_web_credential_id in varchar2
  );

  procedure p_get_object(
    p_base_url in varchar2
    , p_bucket_name in varchar2
    , p_object_name in varchar2
    , p_oci_web_credential_id in varchar2
    , p_blob_content out blob
    , p_content_type out varchar2
    , p_content_length out number
  );
end pkg_oci_os_util;
/