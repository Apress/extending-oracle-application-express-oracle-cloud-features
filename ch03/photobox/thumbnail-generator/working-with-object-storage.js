const common = require('oci-common');
const objectStorage = require('oci-objectstorage');

const fs = require('fs');
const path = require('path');

const PROFILE_NAME = 'PROAPEXBOOK_FNDEV_PHX';
const TEMP_DIRNAME = '/tmp';
const PHOTOS_BUCKET_NAME = 'photos';
const THUMBNAILS_BUCKET_NAME = 'thumbnails';
const OBJECT_NAME = 'my-photo.jpg';


(async() => {
  // Set the authentication provider.
  const provider = new common.ConfigFileAuthenticationDetailsProvider(
    '~/.oci/config', PROFILE_NAME
  );

  // Create an Object Storage client.
  const client = new objectStorage.ObjectStorageClient({
    authenticationDetailsProvider: provider
  });

  // Create an empty request
  const request = {};
  const namespaceName = (await client.getNamespace(request)).value;
  console.log('Namespace is', namespaceName);

  let bucketName = PHOTOS_BUCKET_NAME;
  let objectName = OBJECT_NAME;

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

  // Set the bucket name.
  bucketName = THUMBNAILS_BUCKET_NAME;

  // Retrieve some file statistics.
  const stats = await fs.promises.stat(tempFilepath);

  // Prepare the file for upload.
  const nodFsBlob = new objectStorage.NodeFSBlob(tempFilepath, stats.size);
  const objectData = await nodFsBlob.getData();

  const putObjectRequest = {
    namespaceName: namespaceName,
    bucketName: bucketName,
    objectName: objectName,
    putObjectBody: objectData,
    contentLength: stats.size
  }
  const putObjectResponse = await client.putObject(putObjectRequest);
  console.log('Uploaded thumbnail.');

  // Clean up
  await fs.promises.unlink(tempFilepath);

  console.log('Exit');
})();

