resource "newrelic_synthetics_script_monitor" "this" {
  status           = "ENABLED"
  name             = "script_api_monitor"
  type             = "SCRIPT_API"
  locations_public = ["AWS_AP_NORTHEAST_1"]
  period           = "EVERY_12_HOURS"

  script = <<-EOT
  //Import the 'assert' module to validate results.
  var assert = require('assert');

  var options = {
      //Define endpoint URL.
      url: "https://www.google.com",
  };

  //Define expected results using callback function.
  function callback(error, response, body) {
      //Log status code to Synthetics console.
      console.log(response.statusCode + " status code")
      //Verify endpoint returns 200 (OK) response code.
      assert.ok(response.statusCode == 200, 'Expected 200 OK response');
      //Log end of script.
      console.log("End reached");
  }

  $http.get(options, callback);
  
  EOT

  script_language      = "JAVASCRIPT"
  runtime_type         = "NODE_API"
  runtime_type_version = "16.10"
}
