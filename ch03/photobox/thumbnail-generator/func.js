const fdk = require('@fnproject/fdk');

const imageThumbnail = require('image-thumbnail');
const fileType = require('file-type');

const common = require('oci-common');
const objectStorage = require('oci-objectstorage');

const fs = require('fs');
const path = require('path');

// Constants
const OBJECT_CREATE_EVENT = 'com.oraclecloud.objectstorage.createobject';
const OBJECT_UPDATE_EVENT = 'com.oraclecloud.objectstorage.updateobject';
const OBJECT_DELETE_EVENT = 'com.oraclecloud.objectstorage.deleteobject';
const TEMP_DIRNAME = '/tmp';
const DEFAULT_THUMBNAIL_SIZE_PIXEL = 80;
const DEFAULT_THUMBNAIL_BUCKET_NAME = 'thumbnails';

async function generateThumbnail(sourceFilepath, targetFilepath, options) {
  console.log(sourceFilepath);
  try {
    const thumbnail = await imageThumbnail(sourceFilepath, options);
    await fs.promises.writeFile(targetFilepath, thumbnail);
    console.log('Thumbnail created sucessfully.');
  } catch(errorMessage) {
    console.error(errorMessage);
  }
}

async function functionHandler(input, ctx) {
  // Set the authentication provider using resource principals.
  const authenticationProvider = await common.ResourcePrincipalAuthenticationDetailsProvider.builder();

  // Get the thumbnails bucket name from the environment.
  const THUMBNAIL_BUCKET_NAME = process.env.THUMBNAIL_BUCKET_NAME || DEFAULT_THUMBNAIL_BUCKET_NAME;
  const THUMBNAIL_SIZE_PIXEL = parseInt(process.env.THUMBNAIL_SIZE_PIXEL) || DEFAULT_THUMBNAIL_SIZE_PIXEL;

  // Read event information.
  const eventType = input.eventType;
  const bucketName = input.data.additionalDetails.bucketName;
  const objectName = input.data.resourceName
  console.log('eventType', eventType);


  // Create an Object Storage client.
  const client = new objectStorage.ObjectStorageClient({
    authenticationDetailsProvider: authenticationProvider
  });

  // Get the namespace
  const request = {};
  const namespaceName = (await client.getNamespace(request)).value;
  console.log('Namespace is', namespaceName);

  if (eventType === OBJECT_CREATE_EVENT || eventType === OBJECT_UPDATE_EVENT) {
    console.log('Start thumbnail generation process.');

    // Prepare the request to get the object.
    const getObjectRequest = {
      namespaceName: namespaceName,
      bucketName: bucketName,
      objectName: objectName
    }

    // Get the object.
    const getObjectResponse = await client.getObject(getObjectRequest);

    // Set the temporary file name for both the photo and thumbnail.
    const tempFilepath = path.join(TEMP_DIRNAME, objectName);

    // Save the file to disk.
    let fileStream = fs.createWriteStream(tempFilepath);
    await new Promise((resolve, reject) => {
      getObjectResponse.value.pipe(fileStream);
      fileStream.on('finish', resolve);
      fileStream.on('error', reject);
    });

    // Generate the thumbnail, override the original.
    await generateThumbnail(
      tempFilepath,
      tempFilepath,
      { width: THUMBNAIL_SIZE_PIXEL, height: THUMBNAIL_SIZE_PIXEL }
    );

    // Upload the file to object storage.
    const stats = await fs.promises.stat(tempFilepath);
    const nodFsBlob = new objectStorage.NodeFSBlob(tempFilepath, stats.size);
    const objectData = await nodFsBlob.getData();
    const contentType = await fileType.fromFile(tempFilepath);

    const putObjectRequest = {
      namespaceName: namespaceName,
      bucketName: THUMBNAIL_BUCKET_NAME,
      objectName: objectName,
      putObjectBody: objectData,
      contentType: contentType.mime,
      contentLength: stats.size
    }
    const putObjectResponse = await client.putObject(putObjectRequest);
    console.log('Uploaded thumbnail.');

    // Clean up
    await fs.promises.unlink(tempFilepath);
  } else {
    // Delete from the thumbnails bucket.
    console.log("Delete thumbnail object");
    const deleteObjectRequest = {
      namespaceName: namespaceName,
      bucketName: THUMBNAIL_BUCKET_NAME,
      objectName: objectName
    };
    const deleteObjectResponse = await client.deleteObject(deleteObjectRequest);
    console.log("Thumbnail object executed successfully" + deleteObjectResponse);
  }

  console.log('Done.');
  return '{"status": "success"}';
}

fdk.handle(functionHandler);