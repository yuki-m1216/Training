const assert = require("assert");

const URL = $secure.URL;
const apiKey = $secure.API_KEY;

const headers = {
  "Content-Type": "application/json",
  "X-Api-Key": apiKey,
};

const options = {
  headers: headers,
};

const callback = function (error, response, body) {
  if (error) {
    console.error(`Request failed with error: ${error}`);
    return;
  }
  assert.equal(response.statusCode, 200, "Expected 200 OK response");
  console.log(`Response Status Code: ${response.statusCode}`);
  const data = JSON.stringify(body);
  console.log(`Response body: ${data}`);
};

$http.get(URL, options, callback);
