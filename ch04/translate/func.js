const fdk = require("@fnproject/fdk");
const translate = require("translate");

translate.engine = "libre";

// Set the LibreTranslate endpoint URL using the Oracle Functions configuration
// parameter.
translate.url = process.env.LIBRE_SERVER_URL || "https://libretranslate.com/translate";

async function functionHandler(input, ctx) {
  let toLanguage = "en";
  let text;
  let translatedText;

  // Retrieve the target language to translate to using the HTTP variable set
  // through the API Gateway deployment.
  if (ctx._headers["Fn-Http-H-X-To-Lang"]) {
    toLanguage = ctx._headers["Fn-Http-H-X-To-Lang"].toString();
  }

  console.log("\nTranslate to language: " + toLanguage);

  // Retrieve the value of "text" from the request body referenced by the
  // variable "input".
  text = input.text;

  console.log("\nText received: " + text);

  // Make a REST request to the LibreTranslate endpoint to get the translated
  // text.
  translatedText = await translate(text, { to: toLanguage });

  console.log('\Translated text: ' + translatedText);

  return { 'translatedText': translatedText };
}

fdk.handle(functionHandler);