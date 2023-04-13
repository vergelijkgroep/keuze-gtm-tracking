___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Keuze.nl tracking",
  "brand": {
    "id": "brand_dummy",
    "displayName": ""
  },
  "description": "Keuze.nl tracking solution. This tag captures the visitor: it determines the \u0027kzemc\u0027 parameter in the URL and sets a cookie \u0027_kzemc\u0027. Use in conjunction with the conversion tracking tag.",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "RADIO",
    "name": "mode",
    "displayName": "Mode",
    "radioItems": [
      {
        "value": "capture",
        "displayValue": "Capture lead"
      },
      {
        "value": "conversion",
        "displayValue": "Record conversion"
      }
    ],
    "simpleValueType": true,
    "defaultValue": "capture",
    "help": "Select the operating mode for this tag. Capture lead only sets a cookie, track conversion actually tracks the conversion and sends a pingback to Keuze.nl if a cookie was found."
  },
  {
    "type": "TEXT",
    "name": "channel",
    "displayName": "Channel (provided by Keuze.nl)",
    "simpleValueType": true
  },
  {
    "type": "TEXT",
    "name": "eventName",
    "displayName": "Event name",
    "simpleValueType": true,
    "valueHint": "Use event_name"
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "orderData",
    "displayName": "Order data",
    "simpleTableColumns": [
      {
        "defaultValue": "",
        "displayName": "Key",
        "name": "key",
        "type": "TEXT"
      },
      {
        "defaultValue": "",
        "displayName": "Value",
        "name": "value",
        "type": "TEXT"
      }
    ],
    "enablingConditions": [
      {
        "paramName": "mode",
        "paramValue": "conversion",
        "type": "EQUALS"
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

const encodeUriComponent = require('encodeUriComponent');
const generateRandom = require('generateRandom');
const getCookieValues = require('getCookieValues');
const getEventData = require('getEventData');
const logToConsole = require('logToConsole');
const makeString = require('makeString');
const sendHttpGet = require('sendHttpGet');
const setCookie = require('setCookie');
const parseUrl = require('parseUrl');

const USER_ID_COOKIE = '_kzemc';
const MAX_USER_ID = 1000000000;

// The event name is taken from either the tag's configuration or from the
// event. Configuration data comes into the sandboxed code as a predefined
// variable called 'data'.
const eventName = data.eventName || getEventData('event_name');

// page_location is automatically collected by the Google Analytics 4 tag.
// Therefore, it's safe to take it directly from event data rather than require
// the user to specify it. Use the getEventData API to retrieve a single data
// point from the event. There's also a getAllEventData API that returns the
// entire event.
const pageLocation = getEventData('page_location');

if (data.mode == 'capture') {
  // Capture lead, set cookie
  const urlObject = parseUrl(pageLocation);

  logToConsole(urlObject);

  if (typeof urlObject == 'undefined') {
    logToConsole('No valid URL');
    data.gtmOnSuccess();
    return;
  }

  const userId = urlObject.searchParams.kzemc;

  if (typeof userId == 'undefined') {
    logToConsole('No kzemc');
    data.gtmOnSuccess();
    return;
  }

  logToConsole('Keuze.nl: using ', userId);

  // Store cookie:
  setCookie(USER_ID_COOKIE, makeString(userId), {
    'max-age': 3600 * 24 * 365 * 2,
    domain: 'auto',
    path: '/',
    httpOnly: true,
    secure: true,
  });

  logToConsole('Cookie set');
  
  const url = 'https://gtm-ws.keuze.dev/?' +
     'mode=tracking' +
     '&channel=' + encodeUriComponent(data.channel) +
     '&event=' + encodeUriComponent(eventName) +
      (pageLocation ? '&url=' + encodeUriComponent(pageLocation) : '') +
     '&uid=' + userId;
  
  logToConsole(url);

  sendHttpGet(url).then((result) => {
    if (result.statusCode >= 200 && result.statusCode < 300) {
      data.gtmOnSuccess();
    } else {
      data.gtmOnFailure();
    }
  });
} else if (data.mode == 'conversion') {
  // Record a conversion
  
  // Check if we have an user ID
  const userId = getCookieValues(USER_ID_COOKIE)[0];
  
  if (typeof userId == 'undefined' || userId == null) {
    logToConsole('No Keuze.nl user ID found');
    data.gtmOnSuccess();
    return;
  }
  
  logToConsole('Using Keuze.nl user ID', userId);
  
  const url = 'https://gtm-ws.keuze.dev/?' +
   'mode=conversion' +
   '&channel=' + encodeUriComponent(data.channel) +
   '&event=' + encodeUriComponent(eventName) +
    (pageLocation ? '&url=' + encodeUriComponent(pageLocation) : '') +
   '&uid=' + userId;
  
    logToConsole(url);

  sendHttpGet(url).then((result) => {
    if (result.statusCode >= 200 && result.statusCode < 300) {
      data.gtmOnSuccess();
    } else {
      data.gtmOnFailure();
    }
  });
}


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "get_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "cookieAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "cookieNames",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "_kzemc"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "set_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedCookies",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "name"
                  },
                  {
                    "type": 1,
                    "string": "domain"
                  },
                  {
                    "type": 1,
                    "string": "path"
                  },
                  {
                    "type": 1,
                    "string": "secure"
                  },
                  {
                    "type": 1,
                    "string": "session"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "_kzemc"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "secure"
                  },
                  {
                    "type": 1,
                    "string": "any"
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_event_data",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keyPatterns",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "event_name"
              },
              {
                "type": 1,
                "string": "page_location"
              }
            ]
          }
        },
        {
          "key": "eventDataAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 4/13/2023, 10:30:46 AM


