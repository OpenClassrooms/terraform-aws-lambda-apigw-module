'use strict';

const AWS = require('aws-sdk');

AWS.config.update({
  region: 'eu-west-3'
})


exports.lambdaHandler = async function (event, context, callback) {

  // console.log('Received event:', JSON.stringify(event, null, 2));

  let api_stage = process.env.ENV

  var token_authorization = event.headers['Authorization']
  var token = token_authorization.replace("Bearer ", "")

  var event_path = event.path.replace("/", "")
  const ssm_path_key = '/vault/aws/apigateway_authorizer/' + api_stage + "/" + event_path

  const ssm_token_result = await getParameterFromStore(ssm_path_key)
  const token_result = ssm_token_result["Value"]


  switch (token) {
    case token_result:
      callback(null, generatePolicy('user', 'Allow', event.methodArn));
      break;
    case 'deny':
      callback(null, generatePolicy('user', 'Deny', event.methodArn));
      break;
    case 'unauthorized':
      callback("Unauthorized");   // Return a 401 Unauthorized response
      break;
    default:
      callback("Unauthorized");   // Return a 401 Unauthorized response
    // callback("Error: Invalid token"); // Return a 500 Invalid token response
  }
};

const parameterStore = new AWS.SSM()

const getParameterFromStore = (param) => {
  return new Promise((res, rej) => {
    parameterStore.getParameter({
      Name: param,
      WithDecryption: true
    }, (err, data) => {
      if (err) {
        return rej(err)
      }
      return res(data["Parameter"])
    })
  })
};

// Help function to generate an IAM policy
var generatePolicy = function (principalId, effect, resource) {
  var authResponse = {};

  authResponse.principalId = principalId;
  if (effect && resource) {
    var policyDocument = {};
    policyDocument.Version = '2012-10-17';
    policyDocument.Statement = [];
    var statementOne = {};
    statementOne.Action = 'execute-api:Invoke';
    statementOne.Effect = effect;
    statementOne.Resource = resource;
    policyDocument.Statement[0] = statementOne;
    authResponse.policyDocument = policyDocument;
  }

  // Optional output with custom properties of the String, Number or Boolean type.
  // authResponse.context = {
  //    "stringKey": "stringval",
  //    "numberKey": 123,
  //    "booleanKey": true
  //};
  return authResponse;
}
