####################
Urban Airship API v3
####################

.. note::

   Urban Airship provides a number of REST API endpoints, collectively known as the Urban Airship API Version
   3. Version 3 is the current and only supported version of the Urban Airship API.

.. {{{ Push

.. _push-api:

****
Push
****

Send Push
=========

.. _POST-api-push:

.. http:post:: /api/push/

   Send a push notification to a specified device or list of devices. The body of the request must be one of:

   * A single :ref:`push-object`.
   * An array of one or more :ref:`Push Objects <push-object>`.

   **Example Request**:

   .. code-block:: http

      POST /api/push HTTP/1.1
      Authorization: Basic <master authorization string>
      Content-Type: application/json
      Accept: application/vnd.urbanairship+json; version=3;

      {
        "audience": {
            "ios_channel": "9c36e8c7-5a73-47c0-9716-99fd3d4197d5"
        },
        "notification": {
             "alert": "Hello!"
        },
        "device_types": "all"
      }


   **Example Response**:

   .. code-block:: http

      HTTP/1.1 202 Accepted
      Content-Type: application/json; charset=utf-8
      Data-Attribute: push_ids

      {
          "ok": true,
          "operation_id": "df6a6b50-9843-0304-d5a5-743f246a4946",
          "push_ids": [
              "9d78a53b-b16a-c58f-b78d-181d5e242078",
          ]
      }

   :json audience: An :ref:`audience selector <audience-selectors>` identifying the devices to push to.
   :json notification: A :ref:`push object <push-object>` defining the notification payload.
   :status 202 Accepted: The push notification has been accepted for processing
   :status 400 Bad Request: The request body was invalid, either due
                to malformed JSON or a data validation error.  See the
                response body for more detail.
   :status 401 Unauthorized: The authorization credentials are incorrect
   :status 406 Not Acceptable: The request could not be satisfied
                because the requested API version is not available.

.. todo::

   Add Full Capablity example for v3

.. _POST-api-push-validate:

Validate
========

.. http:post:: /api/push/validate

   Accept the same range of payloads as ``/api/push``, but parse and
   validate only, without sending any pushes.



   :status 200 OK: The payload was valid.
   :status 400 Bad Request: The request body was invalid, either due
                to malformed JSON or a data validation error.  See the
                response body for more detail.
   :status 401 Unauthorized: The authorization credentials are incorrect
   :status 406 Not Acceptable: The request could not be satisfied
                because the requested API version is not available.

Below are some specific validation cases which will cause pushes to be rejected with an ``HTTP 400`` error. The response body will provide explicit detail regarding the error. Below are two examples.

Missing Payload
----------------

A push which specifies delivery to a platform, but does not supply a
payload for that platform, is invalid.

Example - this push is invalid because it specifies Android as a delivery platform, but does not provide any payload for android:

.. code-block:: json
   :emphasize-lines: 3,5

   {
      "audience" : "all",
      "device_types" : [ "ios", "android" ],
      "notification" : {
         "ios" : {
            "alert" : "Boo"
         }
      }
   }


Device Identifier/Restriction Mis-Match
----------------------------------------

A push which includes a device identifier in the audience selection,
but does not include the corresponding platform (or ``"all"``) in the
``"device_types""`` specifier, is invalid.

Example - this push is invalid because it includes an iOS device token in the audience selection, but has not
specified ``"ios"`` as a delivery platform:

.. code-block:: json
   :emphasize-lines: 5,8

   {
      "audience": {
         "or": [
            { "device_pin": "1fd34210" },
            { "device_token": "645A5C6C06AFB2AE095B079135168A04A5F974FBF27163F3EC6FE1F2D5AFE008" }
         ]
      },
      "device_types": [ "blackberry" ],
      "notification": {
         "alert": "WAT"
      }
   }


.. _data-formats:


.. _push-object:

Push Object
============

A *push object* describes everything about a push, including the
:ref:`audience <audience-selectors>` and push payload. A push object
is composed of up to six attributes:

* ``"audience"`` - Required

* ``"notification"`` - Required if ``"message"`` is not present, optional if it is

* ``"device_types"`` Required. Can either be ``"all"`` or an array of one or more of the following
  values::

      "ios", "android", "amazon", "wns", "mpns", "blackberry"

* ``"options"`` - Optional, a place to specify non-payload-specific delivery options for the push. See :ref:`Push Options <push-options>`.

* ``"in_app"`` - Optional, an :ref:`In-App <api-in-app-object>` message

* ``"message"`` - Optional, a :ref:`Rich Push <rich-push>` message

.. code-block:: json
   :emphasize-lines: 2,9,15,18,23

   {
      "audience": {
         "OR": [
            { "tag": ["sports", "entertainment"] },
            { "device_token": "871922F4F7C6DF9D51AC7ABAE9AA5FCD7188D7BFA19A2FA99E1D2EC5F2D76506" },
            { "apid": "5673fb25-0e18-f665-6ed3-f32de4f9ddc6" }
         ]
      },
      "notification": {
         "alert": "Hi from Urban Airship!",
         "ios": {
            "extra": { "url": "http://www.urbanairship.com"}
         }
      },
      "options": {
         "expiry": "2015-04-01T12:00:00"
      },
      "message": {
         "title": "Message title",
         "body": "<Your message here>",
         "content_type": "text/html"
      },
      "device_types": [ "ios", "wns", "mpns" ]
   }

.. _audience-selectors:

Audience Selection
------------------

An *audience selector* forms the expression that determines the set of devices to which a notification
will be sent. A valid *audience selector* is a JSON expression which can identify an app installation by means of one of the following four selector types:

* Atomic selector
* Compound selector
* Location expression
* Special selector



Atomic Selectors
^^^^^^^^^^^^^^^^^

Atomic selectors are the simplest way to identify a single device, i.e., app installation, or a group of
devices. These selectors are either a unique identifier for the device such as a channel ID or metadata that
maps to the device (or multiple devices) such as a tag. Atomic selectors may be one of:

``tag``
  A :term:`tag` is an arbitrary bit of metadata used to group different devices together. A tag specifier
  may or may not have an associated ``group`` declaration, which specifies what :term:`tag group` the tag belongs
  to. If no tag group is specified, the default ``"device"`` group is used.

``segment``
  a :ref:`Segment <segments-api>` is a subset of your audience that is predefined by combining Tags and/or devices that meet your specified location-targeting criteria

``static_list``
  a :ref:`list <api-static-lists>` is a subset of your audience defined by a CSV file containing channel IDs, Named Users, or Aliases

``named_user``
  a :term:`named_user <Named User>` is an alternate, non-unique name, mapped to a user profile in a different database, i.e., CRM, that can be used to target devices associated with that profile

``alias``
  an :term:`alias` is an alternate, non-unique name, often mapped to a user profile in a different database,
  that can be used to target devices associated with that profile. Superseded by ``named_user``.

.. tip::

   See the steps outlined :ref:`here <tg-mdb-named-users-upgrade>` to initiate this move.

``ios_channel``
  the unique :term:`channel` identifier used to target an iOS device

``device_token``
  the unique identifier used to target an iOS device, superseded by
  ``ios_channel``

``device_pin``
  the unique identifier used to target a Blackberry device

``android_channel``
  the unique :term:`channel` identifier used to target an Android device

``apid``
  the unique identifier used to target an Android device, superseded by
  ``android_channel``

``amazon_channel``
  the unique :term:`channel` identifier used to target an Amazon device

``wns``
  the unique identifier used to target a Windows device

``mpns``
  the unique identifier used to target a Windows Phone device

**Examples**:

Push to a tag with no tag group specified:

.. code-block:: json

    {
        "audience" : {
            "tag" : "Giants Fans"
        }
    }

Push to a tag with a tag group specified:

.. code-block:: json

   {
      "audience": {
         "tag": "platinum-member",
         "group": "loyalty"
      }
   }

Push to a static list:

.. code-block:: json

   {
      "audience": {
         "static_list": "subscriptions"
      }
   }

Pushing to a single iOS device using a :term:`channel id`:

.. code-block:: json

   {
      "audience": {
         "ios_channel": "9c36e8c7-5a73-47c0-9716-99fd3d4197d5"
      }
   }

Specify more than one Channel of the same type by including the values in an array:

.. code-block:: json

   {
      "audience": {
         "amazon_channel": ["user-1", "user-2"]
      }
   }

Pushing to a single iOS device using a :term:`device token`:

.. code-block:: json

    {
        "audience" : {
            "device_token" : "C9E454F6105B0F442CABD48CB678E9A230C9A141F83CF4CC03665375EB78AD3A"
        }
    }

Pushing to a single Android device using a :term:`channel id`:

.. code-block:: json

   {
       "audience" : {
           "android_channel" : "b8f9b663-0a3b-cf45-587a-be880946e880"
       }
   }

Pushing to a single Amazon device using a :term:`channel id`:

.. code-block:: json

   {
       "audience" : {
           "amazon_channel" : "b8f9b663-0a3b-cf45-587a-be880946e880"
       }
   }

As is to a single Windows device:

.. code-block:: json

    {
        "audience" : {
            "wns" : "3644dada-d807-a2da-19d0-90d902ea7636"
        }
    }

Or Windows Phone:

.. code-block:: json

    {
        "audience" : {
            "mpns" : "7048a456-0ce9-1c33-77d0-5975d980ffa0"
        }
    }

Or Blackberry:

.. code-block:: json

    {
        "audience" : {
            "device_pin" : "f9307dd7"
        }
    }

And here's a Segment. You must know the ``segment-id`` for the target Segment:

.. code-block:: json

    {
        "audience" : {
            "segment" : "<segment-id>"
        }
    }

And a Named User:

.. code-block:: json

   {
      "audience" : {
         "named_user" : "user-id-54320"
      }
   }

And an alias:

.. code-block:: json

    {
        "audience" : {
            "alias" : "room_237"
        }
    }

.. _compound-selectors:

Compound Selectors
^^^^^^^^^^^^^^^^^^

Compound selectors combine boolean operators (AND, OR, or NOT) with one or more of the atomic
expressions mentioned above. The syntax can be either *implicit*, using an array of
values associated with an atomic selector, as seen in this example:

Implicit ``OR``
   .. code-block:: json

      {
         "audience" : {
            "tag" : ["apples", "oranges", "bananas"]
         }
      }

or *explicit*, employing a boolean operator followed by an array of atomic expression objects.


In the above expression, the push will be sent to any device matching any of the three tags, and is equivalent to the explicit form as follows:

Explicit ``OR``
   .. code-block:: json

      {
         "audience" : {
            "OR" : [
               { "tag" : "apples" },
               { "tag" : "oranges" },
               { "tag" : "bananas" }
            ]
         }
      }

Logical Expressions
^^^^^^^^^^^^^^^^^^^

An explicit logical expression is a JSON object consisting of a logical operator as the key,
and an array of one or more expressions (which can be atomic, implicit OR, or other explicit
logical expressions -- anything except "all").

**Examples**:

Select devices which have subscribed to pushes about sports or
entertainment, in English:

.. code-block:: json

   {
      "audience": {
         "AND": [
            {"OR": [
               {"tag": "sports"},
               {"tag": "entertainment"}
            ]},
            {"tag": "language_en"}
         ]
      }
   }

A simple group message could be composed to send to all members of the
group Group1 except for the sender, ``UserA``:

.. code-block:: json

   {
      "audience": {
         "AND": [
            { "tag": "Group1" },
            { "NOT":
               { "alias": "UserA" }
            }
         ]
      }
   }

Use Caution with ``NOT`` Operators
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

One or more ``NOT`` statements may cause latency when sending notifications, as ``NOT``
operations are inherently more expensive to perform than ``OR`` or ``AND`` operations.

Latency is greater with larger audiences. We recommend using ``AND`` statements in place
of ``NOT`` statments whenever possible as a best practice.

**Example**:

There are two types of people who have your app. Those who like Justin Bieber and those who
hate Justin Bieber.

Tag Strategy

* Users who like Justin Bieber tag "``belieber``" and "``nonhater``"
* Users who hate Justin Bieber tag "``hater``" and "``nonbelieber``"

Using tags this way assigns a *positive* **and** *non-negative* tag attribute to a user when possible,
making it easier and faster to identify audience with the absence of an attribute.

Location Expressions
^^^^^^^^^^^^^^^^^^^^

When sending to a location, include a location expression in the ``audience`` object,
identifying the intended polygon by means of:

#. **either an** ``id`` **or location alias** and
#. the window of time for the targeted message

The notification will match devices that have checked in with a location within the
given polygon during the given time window. The time window is required and must be specified by a
:ref:`time-period-specifier`.

**Example**: (*referencing a location by id*)


.. code-block:: json
   :emphasize-lines: 4

   {
      "audience": {
         "location": {
            "id": "4oFrxA7ncddPratuelEQIV",
            "date": {
               "days": {
                  "start": "2015-10-15",
                  "end": "2015-10-21"
               }
            }
         }
      }
   }

**Example**: (*referencing a location by alias*)

.. code-block:: json
   :emphasize-lines: 4

   {
      "audience": {
         "location": {
            "<alias-type>": "some_alias_value",
            "date": {
               "days": {
                  "start": "2015-10-15",
                  "end": "2015-10-21"
               }
            }
         }
      }
   }


**JSON Parameters**

:id: Optional, a polygon ID
:<alias-type>: Optional, a polygon alias, with the key indicating the type of alias. One of ``id`` or alias must be provided. See: :doc:`/reference/location_boundary_catalog` for more information.
:date: Required, a :ref:`time-period-specifier`

.. _time-period-specifier:

Time Period Specifier
"""""""""""""""""""""

The time period specifier is an object indicating a time period in which to
match device locations.

**Fields**

:<resolution>: Optional. An object with ``"start"`` and ``"end"``
       attributes containing ISO dates, specifying an absolute
       window. The key is one of the time resolution specifiers.
:recent: Optional. An object specifying a relative window. See table
         below.

One of either ``days`` or ``recent`` must be set.

**Resolutions**

Valid time resolutions are:

* ``"hours"``
* ``"days"``
* ``"weeks"``
* ``"months"``
* ``"years"``

**Absolute Window**

An absolute window is indicated by setting the ``"days"`` attribute on
the location selector. The value of that must be an object with two
required fields, ``"start"``, and ``"end"``, both of which must
contain ISO formatted date values as strings.

**Example**: (*absolute window*)

An absolute window is indicated by setting one of the time resolution
attributes on the location selector, which has two required
attributes - ``"start"``, and ``"end"``, both of which must be
ISO-formatted dates.

.. code-block:: json

   {
      "audience": {
         "location": {
            "id": "00xb78Jw3Zz1TyrjqRykN9",
            "date": {
               "days": {
                  "start": "2015-01-01",
                  "end": "2015-01-15"
               }
            }
         }
      }
   }

.. code-block:: json

    {
        "audience": {
            "location": {
                "id": "00xb78Jw3Zz1TyrjqRykN9",
                "date": {
                    "days": {
                        "start": "2015-01-01",
                        "end": "2015-01-02"
                    }
                }
            }
        }
    }

.. code-block:: json

   {
      "audience": {
         "location": {
            "id": "00xb78Jw3Zz1TyrjqRykN9",
            "date": {
               "months": {
                  "start": "2012-01",
                  "end": "2012-06"
               }
            }
         }
      }
   }

**Relative Window**

A relative window is indicated by setting the ``"recent"`` attribute
on the location selector. The value of that must be an object with a
single integer-valued attribute set. The name of the attribute
determines the unit of time and must be one of the resolution
specified, and the value, which must be a positive integer, determines
the period.

============= =========== =========================
Resolution    Valid Range Notes
============= =========== =========================
``"hours"``   1-48        Up to the last two days
``"days"``    1-60        Up to the past 60 days
``"weeks"``   1-10        Up to the past 10 weeks
``"months"``  1-48        Up to the past 4 years
``"years"``   1-20        Up to the past 10 years
============= =========== =========================

Using the number ``1`` in a relative window location expression may result in a smaller
audience than expected. When ``recent`` is passed a value of ``1``, the location API assumes
that you are referring to the *current* unit of time. For example, suppose you have the
following ``location`` payload:

.. code-block:: json

   {
      "location": {
         "id": "xyz123",
         "date": {
            "days": {
               "recent": 1
            }
         }
      }
   }

If you were to send a push with this ``location`` payload at 12:01 AM, your push would
only go to users that have been in location ``"xyz123"`` in the past minute. This is because
the API interprets ``"recent": 1`` to refer to the window 12:00 AM - 12:00 PM, or the
current day. If you would like to push to all devices that have been in the given location
in the past 24 hours, you would use ``hours`` as your unit:

.. code-block:: json

   {
      "location": {
         "id": "xyz123",
         "date": {
            "hours": {
               "recent": 24
            }
         }
      }
   }

Assuming the above push was sent at 1:01 PM, it would go to all devices that have been in
location ``"xyz123"`` between 12:01 and 1:01 PM.

**Example:** *(relative window)*

This example sends to devices that have been in the given location ID in the past
four weeks.

.. code-block:: json

   {
      "audience": {
         "location": {
            "id": "00xb78Jw3Zz1TyrjqRykN9",
            "date": {
               "weeks": {
                  "recent": 4
               }
            }
         }
      }
   }


Special Selectors
^^^^^^^^^^^^^^^^^

Certain audience selectors cannot be described as atomic and are represented by a string which
then maps to a special Urban Airship internal accounting of all devices that meet the
criteria for that string.

.. _broadcast-v3-api:

Broadcast
"""""""""

In previous versions of the Urban Airship API, the broadcast or "send to all" feature relied on a separate endpoint. Beginning with v3 of our API, send a broadcast message by using ``"all"`` as the audience selector.

**Example**:

.. code-block:: json

   {
      "audience": "all",
      "device_types": "all",
      "notification": {
         "alert": "This one goes out to all of the mobile people."
      }
   }

Triggered Audience
""""""""""""""""""

Another special selector value is for use with :ref:`pipelines-api`. The string ``"triggered"``
indicates that the audience is comprised of the device(s) that activated the trigger.

See: :ref:`Pipeline Objects <pipeline-object>` for more detail.


.. _notification-payload:

Notification Payload
--------------------

The notification payload is a JSON object assigned to the
``"notification"`` attribute on a :ref:`push-object`, which contains the
actual contents to be delivered to devices. At its simplest, the payload
consists of a single string-valued attribute, ``"alert"``, which sends
a push notification consisting of a single piece of text.

.. code-block:: json
   :emphasize-lines: 5

    {
        "audience": "all",
        "device_types": "all",
        "notification": {
            "alert": "Hello from Urban Airship."
        }
    }

The notification payload MAY include an optional ``"actions"`` object, which is
described in the :ref:`Actions <actions-api>` section. If present, the
``actions`` object cannot be ``null`` or empty (``{}``), or an HTTP 400 will
be returned.

.. _platform-overrides:

Platform Overrides
------------------

Each supported platform has an optional platform override section,
which can simply change the value of ``alert`` for that platform, or
provide more detailed platform-specific payload data.

If the ``alert`` key has been provided at the top level, it will be
merged with the platform-specific payload. For example, an Android
payload can add the ``extra`` map without overriding an ``alert``
value provided at the top level.

**Example**:

The following example sends a different alert string for every
supported platform:

.. code-block:: json

   {
      "audience": "all",
      "device_types": "all",
      "notification": {
         "ios": {
            "alert": "Hello, iDevices"
         },
         "android": {
            "alert": "These are not the...yeah, lame joke."
         },
         "amazon": {
            "alert": "Read any good books lately?"
         },
         "blackberry": {
            "alert": "Greetings, Blackberry Nation!"
         },
         "mpns": {
            "alert": "Hello, Nokia/HTC"
         },
         "wns": {
            "alert": "Developers, developers, developers."
         }
      }
   }

.. _notification-payload-ios:

iOS
^^^

The platform override section for iOS uses the attribute ``ios``. For more
detailed discussion of iOS-specific push behavior, see
:ref:`ios-push-integration`.

The iOS override section may have any of the following attributes:

* ``"alert"`` - Override the alert value provided at the top level, if
  any. May be a JSON string or an object which conforms to Apple's
  spec (see Table 3-2 in the `The Notification Payload
  <https://developer.apple.com/library/mac/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/ApplePushService.html#//apple_ref/doc/uid/TP40008194-CH100-SW1>`_) section of the APNs documentation.
* ``"badge"`` - May be an integer, or an auto badge value (see `Badge
  Values`, below).
* ``"sound"`` - a string.
* ``"content-available"`` or ``"content_available"`` - a boolean, one of ``true`` or ``false``
* ``"extra"`` -  a dictionary of string keys to arbitrary JSON values.
* ``"expiry"`` - The expiry time for APNS to cease trying to deliver a
  push. Can be an integer encoding number of seconds from now, or an
  absolute timestamp in ISO UTC format. An integer value of ``0``
  (zero) will be passed directly to Apple, and indicates that the push
  should be delivered immediately and not stored by APNS ("now or
  never" delivery). If a global ``expiry`` value has been provided in
  the push options object, this will override it.
* ``"priority"`` - Optional, an integer. Sets the APNS priority of the delivery. This feature of APNS is
  specific to iOS 7+. Valid values are ``10`` (immediate delivery) and ``5`` (conserve battery). The
  default value is ``10``. The ``priority`` key *must* be set to ``5`` if sending a push without
  an alert, otherwise the request will fail silently.
* ``"category"`` - Optional, a string. Sets the APNs category for the push. This maps directly to the
  ``"category"`` field in the ``"aps"`` section of the APNs payload.
* ``"interactive"`` - Optional, an object. The ``"interactive"`` value can be used to override the
  interactive notification payload. It conforms to the standard :ref:`interactive <interactive-api>`
  object specifications.
* ``"title"`` - Optional, a string. Sets the title of the notification. Used for specifying the
  Apple Watch :ref:`short look interface <tg-short-look>` and the iOS Notification Center title
  text.

.. note::

   Please use caution if you are considering sending a push that includes extras but no alert payload,
   or a content-available push that doesn't actually reveal additional content. APNS guidelines warn
   against sending pushes more frequently than necessary, and you could be blocked or throttled. Please
   see `section 5.8 <https://developer.apple.com/app-store/review/guidelines/#push-notifications>`__ for
   details on Apple's policy, and contact Support with any additional questions.


Extras and Actions
""""""""""""""""""

Keys provided in the ``extras`` object may conflict with ``actions``, if any
are specified, and can result in an HTTP 400 being returned. See :ref:`iOS,
Extras and Actions <ios-extras-and-actions>` for more details.

Badge Values
""""""""""""

The ``"badge"`` key on the iOS override may be an integer, the value
``"auto"``, or an increment value. Increments are expressed by
integers formatted as strings, and prefixed with either '+' (U+002B)
or '-' (U+002D). The numeric portion may be an integer value.

**Examples**:

* ``"+1"``
* ``"+12"``
* ``"-3"``
* ``12``
* ``"auto"``

The ``"badge"`` key is restricted to ``"auto"`` and integral values. Anything else will cause a validation
failure, resulting in an ``HTTP 400 Bad Request`` response.

Alert
"""""

The ``"alert"`` key on the iOS override may be either a plain string,
or a JSON object with one or more of the following fields.

:body: String, the alert text
:action-loc-key: String
:loc-key: String
:loc-args: Array of strings
:launch-image: String

.. _notification-payload-android:

Android
^^^^^^^

The platform override section for Android uses the attribute
``"android"``. The android override section may have any of the
following attributes:

* ``"alert"`` - Optional, override the alert value provided at the top level, if
  any.
* ``"collapse_key"`` - Optional, a string
* ``"time_to_live"`` - Optional, an integer or timestamp specifying
  the expiration time for the message. ``0`` indicates that GCM should
  not store the message (i.e. "now or never" delivery).
* ``"delay_while_idle"`` - Optional, a boolean
* ``"extra"`` - a JSON dictionary of string values. Values for each
  entry may only be strings. If an API user wishes to pass structured
  data in an extra key, it must be properly JSON-encoded as a string.
* ``"style"`` - Optional :ref:`advanced styles <android-amazon-styles>`
* ``"title"`` - Optional, a string representing the title of the notification. The default value is the
  name of the app at the SDK.
* ``"summary"`` - Optional, a string representing a summary of the notification.



For more detailed discussion of Android-specific push behavior, see
:ref:`Android Integration <android-push-integration>`.

See Google's `Downstream message syntax
<https://developers.google.com/cloud-messaging/http-server-ref#send-downstream>`_ documentation for
explanations of ``collapse_key``, ``time_to_live``, and
``delay_while_idle``.

**Example**:

.. code-block:: json

    {
        "android": {
            "alert": "Hello",
            "extra": {
                "url": "http://example.com",
                "story_id": "1234",
                "moar": "{\"key\": \"value\"}"
            },
            "collapse_key": "gobbledygook",
            "time_to_live" : 10,
            "delay_while_idle" : true
        }
    }

.. _android-l-features:

Android L Features
""""""""""""""""""

* ``"priority"`` - Optional integer in the range from -2 to 2, inclusive. Used to help determine notification
  sort order. 2 is the highest priority, -2 is the lowest, and 0 is the default priority.
* ``"category"`` - Optional string from the following list: ``"alarm"``, ``"call"``, ``"email"``,
  ``"err"``, ``"event"``, ``"msg"``, ``"promo"``, ``"recommendation"``, ``"service"``, ``"social"``,
  ``"status"``, ``"sys"``, and ``"transport"``. It is used to help determine notification sort order.
* ``"visibility"`` - Optional integer in the range from -1 to 1 inclusive. 1 is public (default), 0 is
  private, and -1 is secret. Secret does not show any notifications, while private shows a redacted
  version of the notification.
* ``"public_notification"`` - Optional object. A notification to show on the lock screen instead of the
  redacted one. This is only useful with ``"visibility"`` set to 0 (private). The object may contain any
  of the following fields: ``"title"``, ``"alert"``, and ``"summary"``.

**Example**:

.. code-block:: json

   {
      "android": {
         "priority": 1,
         "category": "promo",
         "visibility": -1,
         "public_notification": {
            "title": "the title",
            "alert": "hello, there",
            "summary": "the subtext"
         }
      }
   }

.. _android-wearables:

Wearables
"""""""""

* ``"local_only"`` - Optional boolean (default false). Set this to true if you do not want this notification to bridge to other devices (wearables).
* ``"wearable"`` - Optional object with the following optional fields:
   * ``"background_image"`` - String field containing the URL to a background image to display on the
     wearable device.
   * ``"extra_pages"`` - List of objects, each with "title" and "alert" string attributes for specifying
     extra pages of text to appear as pages after the notification alert on the wearable device.
   * ``"interactive"`` - An object which can be used to override the interactive notification payload for
     the wearable device. The object must conform to the :ref:`interactive <interactive-api>` object
     specification.

**Example**:

.. code-block:: json

   {
      "android": {
         "local_only": true,
         "wearable": {
            "background_image": "http://example.com/background.png",
            "extra_pages": [
               {
                  "title": "Page 1 title - optional title",
                  "alert": "Page 1 title - optional alert"
               },
               {
                  "title": "Page 2 title - optional title",
                  "alert": "Page 2 title - optional alert"
               }
            ],
            "interactive": {
               "type": "ua_yes_no_foreground",
               "button_actions": {
                  "yes": {
                     "add_tag": "butter",
                     "remove_tag": "cake",
                     "open": {
                        "type": "url",
                        "content": "http://www.urbanairship.com"
                     }
                  },
                  "no": {
                     "add_tag": "nope"
                  }
               }
            }
         }
      }
   }

.. _android-amazon-styles:

Style
"""""

A number of advanced styles are available on Android 4.3+ by adding the ``"style"`` attribute to the
platform-specific notation payload on Android and Amazon. The ``"style"`` object must contain
a string field ``"type"``, which will be set to either ``"big_text"``, ``"big_picture"``, or ``"inbox"``.
Whatever ``"type"`` is set to must also exist as an independent string field within the ``"style"`` object:

* ``"big_picture"`` - If ``"type"`` is set to ``"big_picture"``, then the ``"big_picture"`` string field
  must also be present. ``"big_picture"`` should be set to the URL for some image

* ``"big_text"`` - If ``"type"`` is set to ``"big_text"``, then the ``"big_text"`` string field must also
  be present. ``"big_text"`` should be set to the text that you want to display in big text style.

* ``"inbox"`` - If ``"type"`` is set to ``"inbox"``, then the ``"lines"`` field must also be present. The
  ``"lines"`` field should be an array of strings.

The ``"style"`` object may also contain ``"title"`` and ``"summary"`` override fields:

* ``"title"`` - Optional string field which will override the notification.
* ``"summary"`` - Optional string field which will override the summary of the notification.

**Examples**:

.. code-block:: json

   {
      "android": {
         "style": {
            "type": "big_text",
            "big_text": "This is big!",
            "title": "Big text title",
            "summary": "Big text summary"
         }
      }
   }

.. code-block:: json

   {
      "android": {
         "style": {
            "type": "big_picture",
            "big_picture": "http://pic.com/photo",
            "title": "Big picture title",
            "summary": "Big picture summary"
         }
      }
   }

.. code-block:: json

   {
      "android": {
         "style": {
            "type": "inbox",
            "lines": ["line 1", "line 2", "line 3", "line 4"],
            "title": "Inbox title",
            "summary": "Inbox summary"
         }
      }
   }


.. -notification-payload-amazon:

Amazon
^^^^^^

The platform override section for Amazon uses the attribute ``"amazon"``. the ``"amazon"`` object may
have zero or more of the following attributes:

* ``"alert"`` - Optional, override the alert value provided at the top level, if any.
* ``"consolidation_key"`` - Optional, a string value. Similar to GCM’s collapse_key.
* ``"expires_after"`` - Optional, an integer value indicating the number of seconds that ADM will retain the message if the device is offline. The valid range is 60 - 2678400 (1 minute to 31 days), inclusive. Can also be an absolute ISO UTC timestamp, in which case the same validation rules apply, with the time period calculated relative to the time of the API call.
* ``"extra"`` - JSON dictionary of string values. Values for each entry may only be strings. If you wish to pass structured data in an extra key, it must be properly JSON-encoded as a string.
* ``"title"`` - Optional, a string representing the title of the notification. The default value is the name of the app at the SDK.
* ``"summary"`` - Optional, a string representing a summary of the notification.
* ``"style"`` - Optional advanced styles available for certain Android and Amazon devices. See: :ref:`android-amazon-styles`.

.. _notification-payload-blackberry:

Blackberry
^^^^^^^^^^

The platform override section for Blackberry uses the attribute
``"blackberry"``. The Blackberry override section may have:

* ``"alert"`` - Shortcut for: ``"body": <alert value>, "content_type":
  "text/plain"``

Or:

* ``body``
* ``content_type`` or ``content-type``


.. _notification-payload-windows:

Windows 8
^^^^^^^^^

The platform override section for Windows 8 uses the attribute
``"wns"``. The ``"wns"`` object must have exactly one of the following
attributes:

* ``"alert"``
* ``"toast"``
* ``"tile"``
* ``"badge"``

With the exception of the removal of the ``"type"`` attribute, the WNS
platform override section is exactly as in API v2. See
:doc:`/reference/wns_payload_reference`


.. _notification-payload-windows-phone:

Windows Phone 8
^^^^^^^^^^^^^^^

The platform override section for Windows 8 uses the attribute
``"mpns"``. The ``"mpns"`` object must have exactly one of the
following attributes:

* ``"alert"``
* ``"toast"``
* ``"tile"``

With the exception of the removal of the ``"type"`` attribute, the MPNS
platform override section is exactly as in API v2. See
:doc:`/reference/mpns_payload_reference`

.. _push-options:

Push Options
------------

The ``options`` attribute is a JSON dictionary for specifying non-payload options related to the
delivery of the push, such as ``expiry``. Currently, ``expiry`` is the only publicly available push option
but we will continue to expose new options for this attribute in future releases.


.. _push-options-expiry:

Expiry
^^^^^^

Delivery expiration, also commonly referred to as **TTL**. If an expiry time is included with the push, and that time is subsequently reached before the push is delivered, the Platform provider, e.g., APNS or GCM will not attempt to redeliver the message.

The value is expressed as either absolute ISO UTC timestamp, or number of seconds from now. When the delivery platform supports it,
a value of zero (``0``) indicates that the message should be delivered immediately and never stored for later attempts.

If the value of ``expiry`` is zero and the underlying platform for a push does not support a "never store this message" option, the
minimum TTL for that platform will be used.

**Example**:

.. code-block:: json

   {
      "audience": "all",
      "device_types": [ "ios" ],
      "notification": {
         "ios": {
            "badge": "+1"
         }
      },
      "options": {"expiry" : "2015-04-01T12:00:00"}
   }


.. _api-in-app-object:

In-App Message
==============

The in-app message payload is an object assigned to the ``in_app`` attribute on a :ref:`push object
<push-object>`. Aside from the ``display`` and ``display_type`` attributes, which specify the appearance of the
in-app message, the ``in_app`` object looks very similar to a push object:

.. code-block:: json

   {
      "alert": "Happy holidays",
      "display_type": "banner",
      "display": {
         "duration": 60
      },
      "expiry": "2015-04-01T12:00:00",
      "actions": {
         "open": {
            "type": "url",
            "content": "http://www.urbanairship.com"
         }
      },
      "interactive": {
         "type": "ua_share",
         "button_actions": {
            "share": { "share": "Happy holidays!" }
         }
      },
      "extra": {
         "message_num": 12345
      }
   }

:JSON Parameters:

   * **alert** – (String) The text displayed on the in-app message.
   * **display_type** – (String) Specifies the display type. Currently, the only valid option is ``"banner"``.
   * **display** – (Object) A :ref:`api-in-app-display-object`.
   * **expiry** – (String) String specifying an :ref:`expiry value <push-options-expiry>`.
   * **actions** – (Object) An :ref:`Actions object <actions-api>` specifying actions which occur when
     the user taps on the banner notification.
   * **interactive** – (Object) An :ref:`Interactive object <interactive-api>` specifying interactive
     category and associated actions.
   * **extra** – (Object) Mapping of additional key-value pairs.

In-app message sends use the same endpoint as standard push sends.

**Example Request**:

.. code-block:: http

   POST /api/push HTTP/1.1
   Authorization: Basic <master authorization string>
   Content-Type: application/json
   Accept: application/vnd.urbanairship+json; version=3;

   {
      "audience": "all",
      "device_types": ["ios","android"],
      "notification": { "alert": "This part appears on the lockscreen" },
      "in_app": {
         "alert": "This part appears in-app!",
         "display_type": "banner",
         "expiry": "2015-04-01T12:00:00",
         "display": {
            "position": "top"
         },
         "actions": {
            "add_tag": "in-app"
         }
      }
   }

:JSON Parameters:

   * **audience** – (Required) An :ref:`audience selector <audience-selectors>`.
   * **device_types** – (Required) An array of ``device_type`` values
   * **notification** – (Optional) A :ref:`notification object <notification-payload>`. This specifies the
     text that will appear on the lockscreen.

   :in_app:

      * **alert** – (Required) String specifying the in-app message alert text.
      * **display_type** – (Required) Specifies the display type. Currently, the only valid option is
        ``"banner"``.
      * **expiry** – (Optional) String specifying an :ref:`expiry value <push-options-expiry>`.
      * **display** – (Optional) A :ref:`display object <api-in-app-display-object>` specifying the
        appearance of the in-app message.
      * **actions** – (Optional) An :ref:`Actions object <actions-api>` specifying actions which occur when
        the user taps on the banner notification.
      * **interactive** – (Optional) An :ref:`Interactive object <interactive-api>` specifying interactive
        category and associated actions.
      * **extra** – (Optional) Object.

.. note::

   If you would like to send a message that only includes an in-app component, simply exclude the
   ``notification`` attribute. When sending a message with both a ``notification`` and ``in_app``
   component, the ``notification`` text will only appear on the lockscreens of opted-in users, while
   the ``in_app`` text will be sent to the entire specified audience.

**Example Response**:

.. code-block:: http

   HTTP/1.1 202 Accepted
   Content-Type: application/json; charset=utf-8
   Data-Attribute: push_ids

   {
       "ok" : true,
       "operation_id" : "df6a6b50-9843-0304-d5a5-743f246a4946",
       "push_ids": [
           "9d78a53b-b16a-c58f-b78d-181d5e242078",
       ]
   }

.. _api-in-app-display-object:

Display Object
--------------

The allowed fields for this object depend on the value of of the ``display_type`` field. Currently, the only
valid type is ``"banner"``, so the following is an associated ``display`` object for the banner display
type:

.. code-block:: json

   {
      "primary_color": "#FF0000",
      "secondary_color": "#00FF00",
      "position": "top",
      "duration": 600
   }

:JSON Parameters:

   * **primary_color** – (String) Specifies the primary color of the in-app message.
   * **secondary_color** – (String) Specifies the secondary color of the in-app message.
   * **position** – (String) One of either ``"top"`` or ``"bottom"``, specifies the screen position of the
     message.
   * **duration** – (Int) Specifies how long the notification should stay on the screen in seconds before
     automatically disappearing, set to ``15`` by default. If you would prefer that the message not disappear,
     you may set ``duration`` to ``0``.

.. }}}

.. {{{ Schedules

.. _schedules-api:

*********
Schedules
*********

.. note::

  As of the release of the Urban Airship API v3, the operation of scheduling a push for a later time is no longer handled via an argument in the payload of the Push API at ``/api/push/scheduled/<schedule_id>``.

  Scheduled notifications are now managed via the schedule endpoint at
  ``/api/schedules``. See :doc:`api-v3-migration-guide` for
  more information.

.. warning::

   The API prohibits batch sizes of larger than 1000 for scheduled pushes, and batches of larger than 100 for push to local time scheduled pushes.

.. _POST-api-schedule:

Schedule a Notification
=======================

.. http:post:: /api/schedules/

   Scheduled notifications are created by POSTing to the schedule
   URI. The body of the request must be one of:

   * A single :ref:`schedule object <schedule-object>`.
   * An array of one or more :ref:`schedule objects <schedule-object>`.

   **Example Request**:

   .. code-block:: http

      POST /api/schedules/ HTTP/1.1
      Authorization: Basic <authorization string>
      Content-Type: application/json; charset=utf-8
      Accept: application/vnd.urbanairship+json; version=3;

      {
          "name": "Booyah Sports",
          "schedule": {
              "scheduled_time": "2013-04-01T18:45:00"
          },
          "push": {
              "audience": { "tag": "spoaaaarts" },
              "notification": { "alert": "Booyah!" },
              "device_types": "all"
          }
      }

   :json schedule: A :ref:`schedule object <schedule-object>` defining the schedule.
   :json scheduled_time: The time to send the notification, in :term:`UTC`.
   :json local_scheduled_time: Alternate to *scheduled_time*. The device local time to send the notification.
   :json name: An optional string.
   :json push: A :ref:`push object <push-object>` defining the notification payload.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 201 Created
      Content-Type: application/json; charset=utf-8;
      Data-Attribute: schedule_urls

      {
         "ok": true,
         "operation_id": "efb18e92-9a60-6689-45c2-82fedab36399",
         "schedule_urls": [
            "https://go.urbanairship/api/schedules/2d69320c-3c91-5241-fac4-248269eed109"
         ],
         "schedules": [
            {
               "url": "https://go.urbanairship/api/schedules/2d69320c-3c91-5241-fac4-248269eed109",
               "schedule": {
                  "scheduled_time": "2013-04-01T18:45:00"
               },
               "name": "Booyah Sports",
               "push": {
                  "audience": { "tag": "spoaaaarts" },
                  "notification": { "alert": "Booyah!" },
                  "device_types": "all"
               },
               "push_ids": [ "83046227-9b06-4114-9f23-0df349792bbd" ]
            }
         ]
      }

   :status 201 Created: The response body will contain an array of
      response objects with the created resource URIs.
   :status 400 Bad Request: The request body was invalid, most likely
                due to malformed JSON. See the response body for more
                detail.
   :status 401 Unauthorized: The authorization credentials are incorrect or missing.
   :status 403 Forbidden: The application does not have the proper
      entitlement to access scheduling.
   :status 404 Not Found: Returned if the scheduled push has been deleted or has already been delivered.

.. _GET-api-schedule:

List Schedules
==============

.. http:get:: /api/schedules/

   List all existing schedules. Returns an array of :ref:`schedule
   objects <schedule-object>` in the ``"schedules"`` attribute.

   **Example Request**:

   .. code-block:: http

      GET /api/schedules/ HTTP/1.1
      Authorization: Basic <authorization string>
      Accept: application/vnd.urbanairship+json; version=3;
      Content-Type: application/json; charset=utf-8

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8
      Count: 2
      Data-Attribute: schedules

      {
          "ok": true,
          "count": 2,
          "total_count": 4,
          "next_page": "https://go.urbanairship.com/api/schedules/?start=5c69320c-3e91-5241-fad3-248269eed104&limit=2&order=asc",
          "schedules": [
              {
                  "url": "http://go.urbanairship/api/schedules/2d69320c-3c91-5241-fac4-248269eed109",
                  "schedule": { },
                  "push": { }
              },
              {
                  "url": "http://go.urbanairship/api/schedules/2d69320c-3c91-5241-fac4-248269eed10A",
                  "schedule": { },
                  "push": { }
              }
          ]
      }

   :query start: string (optional) - ID of the starting element for paginating results
   :query limit: integer (optional) - maximum number of elements to return
   :status 200 OK: Returned on success, with the JSON representation
      of the scheduled pushes in the body of the response.
   :status 401 Unauthorized: The authorization credentials are incorrect or missing.
   :status 403 Forbidden: The application does not have the proper
      entitlement to access scheduling.

List a Specific Schedule
========================

.. _GET-api-schedule-id:

.. http:get:: /api/schedules/(id)

   Fetch the current definition of a single schedule resource. Returns
   a single :ref:`schedule object <schedule-object>`.

   **Example Request**:

   .. code-block:: http

      GET /api/schedules/5cde3564-ead8-9743-63af-821e12337812 HTTP/1.1
      Authorization: Basic <authorization string>
      Accept: application/vnd.urbanairship+json; version=3;
      Content-Type: application/json; charset=utf-8

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-type: application/json; charset=utf-8

      {
           "name": "Booyah Sports",
           "schedule": {
               "scheduled_time": "2013-04-01T18:45:30"
           },
           "push": {
               "audience": { "tag": [ "spoaaaarts", "Beyonce", "Nickelback" ] },
               "notification": { "alert": "Booyah!" },
               "device_types": "all"
           }
      }

   :uri id: The ID of the schedule to retrieve.
   :status 200 OK: Returned on success, with the JSON representation
      of the scheduled push in the body of the response.
   :status 401 Unauthorized: The authorization credentials are incorrect.
   :status 403 Forbidden: The application does not have the proper
      entitlement to access scheduling.
   :status 404 Not Found: Returned if the scheduled push has been
      deleted or has already been delivered.

Update Schedule
===============

.. _PUT-api-schedule-id:

.. http:put:: /api/schedules/(id)

   Update the state of a single schedule resource. The body must
   contain a single :ref:`schedule object <schedule-object>`. A PUT
   cannot be used to create a new schedule, it can only be used to
   update an existing one.

   **Example Request**:

   .. code-block:: http

      PUT /api/schedules/5cde3564-ead8-9743-63af-821e12337812 HTTP/1.1
      Authorization: Basic <authorization string>
      Content-type: application/json
      Accept: application/vnd.urbanairship+json; version=3;

      {
           "name": "Booyah Sports",
           "schedule": {
               "scheduled_time": "2013-04-01T18:45:30"
           },
           "push": {
               "audience": { "tag": [ "spoaaaarts", "Beyonce", "Nickelback" ] },
               "notification": { "alert": "Booyah!" },
               "device_types": "all"
           }
      }

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8; charset=utf-8
      Content-Length: 123

      {
           "ok": true,
           "operation_id": "7c56d013-5599-d66d-6086-6205115d85e2",
           "schedule_urls": [ "https://go.urbanairship.com/api/schedules/0af1dead-e769-4b78-879a-7c4bb52d7c9e" ],
           "schedules": [
               {
                   "url": "https://go.urbanairship.com/api/schedules/0af1dead-e769-4b78-879a-7c4bb52d7c9e",
                   "schedule": {
                       "scheduled_time": "2013-04-01T18:45:30"
                   },
                   "name": "Booyah Sports",
                   "push": {
                       "audience": { "tag": [ "spoaaaarts", "Beyonce", "Nickelback" ] },
                       "notification": { "alert": "Booyah!" },
                       "device_types": "all"
                   },
                   "push_ids": [ "48fb8e8a-ee51-4e2a-9a47-9fab9b13d846" ]
               }
           ]
      }

   :uri id: The ID of the schedule to update.
   :status 200 OK: Returned if the scheduled push has been succesfully
      updated.
   :status 401 Unauthorized: The authorization credentials are incorrect or missing.
   :status 403 Forbidden: The application does not have the proper
      entitlement to access scheduling.
   :status 404 Not Found: Returned if the scheduled push does not
      exist, has been deleted or has already been delivered.

Delete Schedule
================

.. _DELETE-api-schedule-id:

.. http:delete:: /api/schedules/(id)

   Delete a schedule resource, which will result in no more pushes
   being sent. If the resource is successfully deleted, the response
   does not include a body.

   **Example Request**:

   .. code-block:: http

      DELETE /api/schedules/b384ca54-0a1d-9cb3-2dfd-ae5964630e66 HTTP/1.1
      Authorization: Basic <authorization string>
      Accept: application/vnd.urbanairship+json; version=3;

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 204 No Content

   :uri id: The ID of the schedule to delete.
   :status 204 No Content: Returned if the scheduled push has been succesfully
      deleted.
   :status 401 Unauthorized: The authorization credentials are incorrect or missing.
   :status 403 Forbidden: The application does not have the proper
      entitlement to access scheduling.
   :status 404 Not Found: Returned if the scheduled push has been
      deleted or has already been delivered.

.. _schedule-object:

Schedule Object
===============

A schedule consists of a schedule, i.e., a future delivery time, an optional name, and a :ref:`push
object <push-object>`.

There are two forms of schedule, specifying a delivery time in :term:`UTC`.

Scheduled push to be delivered globally at the same moment

.. code-block:: json

   {"scheduled_time": "2013-04-01T18:45:30"}

Scheduled push to be delivered at the device local time

.. code-block:: json

    {"local_scheduled_time": "2013-04-01T18:45:30"}

A full schedule object, then, will have both a ``schedule`` and a ``push`` object.

.. code-block:: json

    {
        "url": "http://go.urbanairship/api/schedules/2d69320c-3c91-5241-fac4-248269eed109",
        "schedule": {"scheduled_time": "2013-04-01T18:45:30"},
        "name": "My schedule",
        "push": {
            "audience": {"tag": "49ers"},
            "device_types": "all",
            "notification": {"alert": "Touchdown!"},
            "options": {"expiry": 10800}
        }
    }

.. note::

   The ``url`` key is set by the server, and so is present in responses
   but not in creation requests sent from the client.


.. _push-to-local-time:

Local Time Delivery
===================

Push to Local time is an option, when scheduling a push, to have it delivered at the same time of
day across all time zones in your app's audience, around the world. If your application uses our
library and has analytic events turned on, you can schedule a push to each device's local time by
specifying ``local_scheduled_time`` in the :ref:`schedule object <schedule-object>` when creating
the schedule. The push will then arrive for that device or set of devices at local time, instead of
UTC (as is the case with other scheduled pushes). This feature is available only on iOS and Android,
and requires the integration of the library in your app.

.. note::

   In order to be able to use Local Time Delivery, you must have Analytic Events
   turned on and integrated into your application.
   See :ref:`iOS Analytic Reports <ios-reports>` and :ref:`Android Analytic Reports
   <android-analytics-reporting>` for more information.

**Example Request**:

.. code-block:: http

   POST /api/schedules HTTP/1.1
   Authorization: Basic <authorization string>
   Content-Type: application/json; charset=utf-8
   Accept: application/vnd.urbanairship+json; version=3;

   {
      "schedule": {
         "local_scheduled_time": "2015-04-01T12:00:00"
      },
      "push": {
         "audience": "all",
         "notification": { "alert" : "OH HAI FUTURE PEOPLEZ" },
         "device_types": "all"
      }
   }

.. }}}

.. {{{ Automation

.. _automation-api:

**********
Automation
**********

An :term:`Automated Message` is unlike a notification or a message in that the creation of an *Automated
Message* involves setting the conditions under which a notification or notifications will be delivered.

Due to the complexity of the logic and triggering events that will fulfill the delivery of the messages, we
have created a new endpoint for interacting with these kinds of messages at ``/api/pipelines/``. See below for
the examples.

.. note::

   "Pipelines" is the naming convention for generating :term:`Automated Messages <Automated Message>` through
   our API but that *Automated Message* is the proper product/feature name that you will see in the user
   dashboard.


.. _pipelines-api:

Create Pipeline (Automated Message)
===================================

.. _POST-api-pipelines:

.. http:post:: /api/pipelines/

   Pipelines are created by POSTing to the pipeline URI. The body of the request must be one of

   * A single :ref:`pipeline-object`.
   * An array of one or more :ref:`Pipeline Objects <pipeline-object>`.

   **Example Request**:

   .. code-block:: http

      POST /api/pipelines/ HTTP/1.1
      Authorization: Basic <master authorization string>
      Content-Type: application/json
      Accept: application/vnd.urbanairship+json; version=3;

      {
         "immediate_trigger": {
            "tag_added": "new_customer",
            "group": "crm"
         },
         "enabled": true,
         "outcome": {
            "push": {
               "audience": "triggered",
               "device_types": "all",
               "notification": { "alert": "Hello new customer!" }
            }
         }
      }

   In the event of success, the response will contain an array of pipeline URIs, in the ``"pipeline_urls"``
   attribute.  If more than one entity was included in the request, the URIs will be in the same order as the
   objects in the request.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 201 Created
      Content-Type: application/json; charset=utf-8
      Content-Length: 123
      Data-Attribute: pipeline_urls

      {
         "ok": true,
         "operation_id": "86ad9239-373d-d0a5-d5d8-04fed18f79bc",
         "pipeline_urls": [
            "https://go.urbanairship/api/pipelines/86ad9239-373d-d0a5-d5d8-04fed18f79bc"
         ]
      }

   :json name: A descriptive name for the pipeline.
   :json enabled: a boolean value indicating whether or not the pipeline is enabled.
   :json immediate_trigger: An :ref:`immediate trigger object <immediate-triggers>`
   :json outcome: An :ref:`outcome object <outcome-object>`

   :status 201 Created: The response body will contain an array of
      response objects with the created resource URIs.
   :status 400 Bad Request: The request body was invalid, most likely
                due to malformed JSON. See the response body for more
                detail.
   :status 401 Unauthorized: The authorization credentials are incorrect or missing.
   :status 403 Forbidden: The application does not have the proper
      entitlement to access pipelines.
   :status 409 Conflict: The application has exceeded the maximum
                         number of active or total pipelines. In order to increase pipeline maximum, contact support@urbanairship.com.


Validate Pipeline
-----------------

.. _POST-api-pipelines-validate:

.. http:post:: /api/pipelines/validate

   Accept the same range of payloads as POSTing to ``/api/pipelines``, but parse and
   validate only, without creating a pipeline.

   :status 200 OK: The payload was valid.
   :status 400 Bad Request: The request body was invalid, either due
                to malformed JSON or a data validation error.  See the
                response body for more detail.
   :status 401 Unauthorized: The authorization credentials are incorrect or missing.
   :status 406 Not Acceptable: The request could not be satisfied
                because the requested API version is not available.
   :status 409 Conflict: The application has exceeded the maximum
                         number of active or total pipelines. In order to increase pipeline maximum, contact support@urbanairship.com.


List Existing Pipelines
=======================

.. _GET-api-pipeline:

.. http:get:: /api/pipelines/?limit=(integer)&enabled=(enabled_flag)

   List all existing pipelines. Returns an array of :ref:`pipeline
   objects <pipeline-object>` in the ``"pipelines"`` attribute.

   **Example Request**:

   .. code-block:: http

      GET /api/pipelines/ HTTP/1.1
      Authorization: Basic <authorization string>
      Accept: application/vnd.urbanairship+json; version=3
      Content-Type: application/json; charset=utf-8

   :query limit: integer (optional) - Positive maximum number of elements to return.
   :query enabled: boolean (optional) - Limit the listing to only
                   pipelines which match the specified enabled
                   flag. If ``enabled`` is omitted, all pipelines will
                   be returned, regardless of status.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "ok": true,
         "pipelines": [
            {
               "creation_time": "2015-03-20T18:37:23",
               "enabled": true,
               "immediate_trigger": {
                  "tag_added": { "tag": "bought_shoes" }
               },
               "last_modified_time": "2015-03-20T19:35:12",
               "name": "Shoe buyers",
               "outcome": {
                  "push": {
                     "audience": "triggered",
                     "device_types": [ "android" ],
                     "notification": { "alert": "So you like shoes, huh?" }
                  }
               },
               "status": "live",
               "uid": "3987f98s-89s3-cx98-8z89-89adjkl29zds",
               "url": "https://go.urbanairship.com/api/pipelines/3987f98s-89s3-cx98-8z89-89adjkl29zds"
            },
            {
              "..."
            }
         ]
      }

   :json pipelines: An array of :ref:`pipeline objects <pipeline-object>`
   :status 200 OK: Returned on success, with the JSON representation
      of the pipelines in the body of the response.
   :status 401 Unauthorized: The authorization credentials are incorrect or missing.
   :status 403 Forbidden: The application does not have the proper
      entitlement to access pipelines.


List Deleted Pipelines
======================

.. _GET-api-pipeline-deleted:

.. http:get:: /api/pipelines/deleted/?start=(date)

   List all deleted pipelines. Returns an array of :ref:`deleted
   pipeline objects <deleted-pipeline-object>` in the ``"pipelines"``
   attribute.

   **Example Request**:

   .. code-block:: http

      GET /api/pipelines/ HTTP/1.1
      Authorization: Basic <authorization string>
      Accept: application/vnd.urbanairship+json; version=3
      Content-Type: application/json; charset=utf-8

   :query start: string (optional) - Timestamp of the starting element for paginating results

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 Ok
      Content-Type: application/json; charset=utf-8

      {
         "ok": true,
         "pipelines": [
            {
               "deletion_time": "2014-03-31T20:54:45",
               "pipeline_id": "0sdicj23-fasc-4b2f-zxcv-0baf934f0d69"
            },
            {
               "..."
            }
         ]
      }

   :json pipelines: An array of :ref:`deleted pipeline objects <deleted-pipeline-object>`


Individual Pipeline Lookup
==========================

.. _GET-api-pipeline-id:

.. http:get:: /api/pipelines/(id)

   Fetch the current definition of a single pipeline resource. Returns
   an array containing a single :ref:`pipeline object <pipeline-object>`
   in the ``"pipelines"`` attribute.

   **Example Request**:

   .. code-block:: http

      GET /api/pipelines/4d3ff1fd-9ce6-5ea4-5dc9-5ccbd38597f4 HTTP/1.1
      Authorization: Basic <authorization string>
      Accept: application/vnd.urbanairship+json; version=3
      Content-Type: application/json; charset=utf-8


   :uri id: The ID of the pipeline to update

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 Ok
      Content-Type: application/json; charset=utf-8

      {
         "ok": true,
         "pipeline": {
            "creation_time": "2015-02-14T19:19:19",
            "enabled": true,
            "immediate_trigger": { "tag_added": "new_customer" },
            "last_modified_time": "2015-03-01T12:12:54",
            "name": "New customer",
            "outcome": {
               "push": {
                  "audience": "triggered",
                  "device_types": "all",
                  "notification": { "alert": "Hello new customer!" }
               }
            },
            "status": "live",
            "uid": "86ad9239-373d-d0a5-d5d8-04fed18f79bc",
            "url": "https://go.urbanairship/api/pipelines/86ad9239-373d-d0a5-d5d8-04fed18f79bc"
         }
      }

   :json pipeline: A :ref:`pipeline-object`
   :status 200 OK: Returned on success, with the JSON representation
      of the pipeline in the body of the response.
   :status 401 Unauthorized: The authorization credentials are incorrect or missing.
   :status 403 Forbidden: The application does not have the proper
      entitlement to access pipelines.
   :status 404 Not Found: If the pipeline does not exist (perhaps
      because it has already been deleted).


Update Pipeline
===============

.. _PUT-api-pipeline-id:

.. http:put:: /api/pipelines/(id)

   Update the state of a single pipeline resource. Partial updates are not permitted.

   **Example Request**:

   .. code-block:: http

      PUT /api/pipelines/0f927674-918c-31ef-51ca-e96fdd234da4 HTTP/1.1
      Authorization: Basic <authorization string>
      Accept: application/vnd.urbanairship+json; version=3;

      {
         "immediate_trigger": { "tag_added": "new_customer" },
         "enabled": true,
         "outcome": {
            "push": {
               "audience": "triggered",
               "device_types": [ "ios" ],
               "notification": { "alert": "Hello new customer!" }
            }
         }
      }

   :uri id: The ID of the pipeline to update.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 Ok
      Content-Type: application/json; charset=utf-8

      {
         "ok": true
      }

   :status 200 OK: Returned if the pipeline has been succesfully
      updated.
   :status 401 Unauthorized: The authorization credentials are incorrect or missing.
   :status 403 Forbidden: The application does not have the proper
      entitlement to access pipelines.
   :status 409 Conflict: The application has exceeded the maximum
                         number of active or total pipelines. In order to increase pipeline maximum, contact support@urbanairship.com.


Delete Pipeline
===============

.. _DELETE-api-pipeline-id:

.. http:delete:: /api/pipelines/(id)

   Delete a pipeline resource, which will result in no more pushes
   being sent. If the resource is successfully deleted, the response
   does not include a body.

   **Example Request**:

   .. code-block:: http

      DELETE /api/pipelines/0f927674-918c-31ef-51ca-e96fdd234da4 HTTP/1.1
      Authorization: Basic <authorization string>
      Accept: application/vnd.urbanairship+json; version=3;

   :uri id: The ID of the pipeline to delete

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 204 No Content

   :status 204 No Content: Returned if the pipeline has been succesfully
      deleted.
   :status 401 Unauthorized: The authorization credentials are incorrect or missing.
   :status 403 Forbidden: The application does not have the proper
      entitlement to access pipelines.
   :status 404 Not Found: Returned if the pipeline does not exist.


.. _pipeline-object:

Pipeline Object
===============

A pipeline object encapsulates the complete set of objects that define
an Automation pipeline: Triggers, Outcomes, and metadata.

A pipeline object has the following attributes:

+------------------------+-------------+-------------+------------------------------------------------------------------------+
| Key                    | Type        | Qualifier   | Notes                                                                  |
+========================+=============+=============+========================================================================+
| **Requests**                                                                                                                |
+------------------------+-------------+-------------+------------------------------------------------------------------------+
| ``name``               | string      | Optional    | A descriptive name for the pipeline.                                   |
+------------------------+-------------+-------------+------------------------------------------------------------------------+
| ``enabled``            | boolean     | Required    | Determines whether or not the pipeline is active.                      |
+------------------------+-------------+-------------+------------------------------------------------------------------------+
| ``outcome``            | object*     | Required    | A single :ref:`outcome object <outcome-object>` or an array of         |
|                        |             |             | :ref:`outcome objects <outcome-object>`.                               |
+------------------------+-------------+-------------+------------------------------------------------------------------------+
| ``immediate_trigger``  | object*     | Optional    | A single :ref:`event identifier <event-identifier>`                    |
|                        |             |             | or an array of :ref:`event identifiers <event-identifier>`.            |
+------------------------+-------------+-------------+------------------------------------------------------------------------+
| ``historical_trigger`` | object*     | Optional    | A single :ref:`historical trigger object <historical-trigger-object>`  |
|                        |             |             | or an array of :ref:`historical trigger objects                        |
|                        |             |             | <historical-trigger-object>`.                                          |
+------------------------+-------------+-------------+------------------------------------------------------------------------+
| ``constraint``         | object*     | Optional    | A single :ref:`constraint object <constraint-object>` or array of      |
|                        |             |             | :ref:`constraint objects <constraint-object>`.                         |
+------------------------+-------------+-------------+------------------------------------------------------------------------+
| ``condition``          | object*     | Optional    | A single :ref:`condition set <condition-set>` or array of              |
|                        |             |             | :ref:`condition sets <condition-set>`.                                 |
+------------------------+-------------+-------------+------------------------------------------------------------------------+

+------------------------+-------------+-------------+------------------------------------------------------------------------+
| Key                    | Type        | Qualifier   | Notes                                                                  |
+========================+=============+=============+========================================================================+
| **Responses**                                                                                                               |
+------------------------+-------------+-------------+------------------------------------------------------------------------+
| ``url``                | string      | Read only   | The canonical identify of the pipeline. This is a read-only field      |
|                        |             |             | present on responses from the API, but will be ignored if it is        |
|                        |             |             | present on requests.                                                   |
+------------------------+-------------+-------------+------------------------------------------------------------------------+
| ``status``             | string      | Read only   | One of ``live``, or ``disabled``. An                                   |
|                        |             |             | enumerated string value indicating whether the pipeline is currently   |
|                        |             |             | capable of triggering pushes, based on evaluation of values for        |
|                        |             |             | ``enabled``.                                                           |
+------------------------+-------------+-------------+------------------------------------------------------------------------+
| ``creation_time``      | timestamp   | Read only   | An ISO 8601 timestamp in UTC indicating the time that the pipeline was |
|                        |             |             | initially created. This is a read-only field which is present on GET   |
|                        |             |             | responses. If it is included in a POST or PUT request it will be       |
|                        |             |             | ignored.                                                               |
+------------------------+-------------+-------------+------------------------------------------------------------------------+
| ``last_modified_time`` | timestamp   | Read only   | An ISO 8601 timestamp in UTC indicating the time that the pipeline was |
|                        |             |             | last modified. This is a read-only field which is present on GET       |
|                        |             |             | responses. If it is included in a POST or PUT request it will be       |
+------------------------+-------------+-------------+------------------------------------------------------------------------+



.. _outcome-object:

Outcome Object
--------------

An outcome object has the following attributes:

* ``"delay"`` - Optional, integer >= 60. The number of seconds to delay
  before processing the outcome. Only valid if the ``"push"``
  attribute is present.
* ``"push"`` - A single :ref:`push object <push-object>`. The ``"audience"`` field must be set to ``"triggered"``.

.. _immediate-triggers:

Immediate Triggers
------------------

An immediate trigger object defines a condition that activates a
trigger immediately when an event matching it occurs. If a pipeline
has multiple immediate triggers, they're combined via an implicit OR
operation. Any one of the triggers firing will activate the pipeline.

Immediate triggers are all :ref:`event identifiers <event-identifier>`.

.. _historical-trigger-object:

Historical Trigger Object
-------------------------

A historical trigger object defines a condition that matches against event data trended over time. The trigger consists of the following
components:

event identifier
   .. code-block:: text

      "event" : "open"

   matches on app open, registered upon app open via the Urban Airship iOS and Android client libraries.

matching operator
   .. code-block:: text

      "equals" : 0,

   Only a value of ``0`` is currently supported in this field, to initiate an inactivity trigger. Future
   releases will support more flexible notions of triggering based on historical events.

time period
   .. code-block:: text

      "days" : 30

   set value up to 90 days


.. Docs Note: (3-13-14 PFD) this note below (from the API spec) can be left out for now because there is no combining of historical and
.. immediate triggers yet.

.. Evaluation
..    When a historical trigger is combined with an immediate trigger in
..    a single pipeline, the historical portion is only evaluated in the
..    context of individual devices, when the immediate trigger is
..    matched. When a historical trigger is the only trigger in an active
..    pipeline, it will be periodically evaluated against the event history
..    for every active device belonging to the application.


**Example**:  (*this trigger will match if a device has not opened the app in 30 days*)

.. code-block:: json

   {
      "event" : "open",
      "equals" : 0,
      "days" : 30
   }

.. _event-identifier:

Event Identifiers
^^^^^^^^^^^^^^^^^

Event identifiers describe events that Automation can detect and act
on. They may be described by a simple string (e.g. ``"open"``), or by
an object for parameterized events (e.g. ``{ "tag_added" : "<t>" }``).

.. _simple-event-identifiers:

A simple event identifier is a string that names an event which does
not require any parameters to match.

At this time, there are two simple event identifiers:

* ``"open"`` - Matches on app opens.

* ``"first_open"`` - Matches on first open of an app.

Because an app ``open`` event is communicated to Urban Airship via our iOS and Android mobile client libraries, it is required that
your app is utilizing the library and registering app ``open`` events.

.. note::

   ``open`` is a valid Event Identifier only for :ref:`Historical Triggers <historical-trigger-object>`, and cannot be used
   to activate a pipeline via *Immediate Trigger*. Conversely, ``first_open`` is a valid Event Identifier only for Immediate
   Triggers.

.. _compound-event-identifiers:

A compound event identifier is a JSON dictionary with a single key
indicating the event type, and a value specifying the specific
parameter to match on.

Valid compound event identifiers are:

* ``"tag_added"`` - Matches when the specified tag is added. The value of the identifier is a simple string identifying a device tag. See :ref:`tags <tags>`.
* ``"tag_removed"`` - Matches when the specified tag is removed. The value of the identifier is a simple string identifying a device
  tag. See :ref:`tags <tags>`.

.. _constraint-object:

Constraint Object
-----------------

A constraint object describes a constraint placed on when triggered
pushes can be sent, such as a rate limit, or a window in which pushes
can be delivered or suppressed. A constraint object is expressed as a
JSON dictionary with a single key indicating the type of the
constraint, and a dictionary with its values.

Valid constraint types are:

* ``rate`` - A :ref:`rate limit constraint <rate-limit-constraint>`.

.. _rate-limit-constraint:

A rate limit constraint describes a limit on the number of pushes that
can be sent to an individual device per a specified time period.

A rate limit object is comprised of two fields:

* ``pushes`` - An integer, specifying the maximum number of pushes that can be sent to a device per time period.
* ``days`` - An integer, specifying the time period in number of days.

**Example**: (*This pipeline is limited to a maximum of 10 pushes per day, per
device*.)

.. code-block:: json

   {
      "name": "Rate-limited pipeline",
      "enabled": true,
      "immediate_trigger": { "tag_added": "pipelines_are_people_too" },
      "outcome": { "push": { } },
      "constraint": [
         {
            "rate": {
               "pushes": 10,
               "days": 1
            }
         }
      ]
   }

.. _tag-conditions-api:

Tag Conditions
--------------

*Tag Conditions* use the top level attribute of the pipeline object, ``"conditions"``.
When present, the ``"conditions"`` attribute will evaluate for the presence or non-presence
of the only valid condition type, tag(s).

Upon evaluation, combined with boolean operators in a :ref:`condition-set`,
when true, *Tag Conditions* will execute the given outcomes of the pipeline.

.. _condition-object:

Condition Object
----------------

A condition object defines an individual condition which will be
evaluated when considering whether to execute the outcomes of a
pipeline. Condition objects are JSON dictionaries with a key
indicating the type of condition, and a value containing any necessary
parameters to that condition.

There is one valid condition type: ``"tag"``, and *Tag Conditions* have two
possible attributes:

============= ====================================================================================
``tag_name``  Required - the name of the tag to be matched.
``negated``   Optional - a boolean indicating this condition should match on the absence of a tag.
============= ====================================================================================

**Example**:

The following example shows a *Condition Object* from a pipeline which will execute if the target device has
the ``VIP`` tag, *or* does NOT have the ``dont_push`` tag.

.. code-block:: json

   {
      "condition": [
         {
            "or": [
               {
                  "tag": {
                     "tag_name": "VIP"
                  }
               },
               {
                  "tag": {
                     "tag_name": "dont_push",
                     "negated": true
                  }
               }
            ]
         }
      ]
   }




.. _condition-set:

Condition Set
-------------

A condition set is a collection of one or more conditions and an
operator for combining them, in the case that there are multiple
conditions. A condition set may contain a **maximum of 20 conditions**.

Taken together, the operator and set of conditions form a boolean
expression which must evaluate to true for a pipeline to be activated
and its outcomes executed.

Valid operators for a condition set are ``"and"`` and ``"or"``.

.. warning::

   Nesting of operators is not supported within a condition set, i.e., you may not combine ``"and"`` logic with ``"or"`` logic.

**Example**:

.. code-block:: json

   {
      "name": "Very Specific Pipeline With Conditions",
      "enabled": true,
      "immediate_trigger": { "tag_added": "new_customer" },
      "outcome": {
         "push": {
            "audience": "triggered",
            "device_types": "all",
            "notification": { "alert": "A fine conditional VIP hello to you!" }
         }
      },
      "condition": [
         {
            "or": [
               {
                  "tag": {
                     "tag_name": "VIP"
                  }
               },
               {
                  "tag": {
                     "tag_name": "dont_push",
                     "negated": true
                  }
               }
            ]
         }
      ]
   }

.. _deleted-pipeline-object:

Deleted Pipeline Object
=======================

A deleted pipeline object contains the id and the deletion time for each pipeline that is returned when you list deleted
pipelines with :ref:`GET /api/pipelines/deleted <GET-api-pipeline-deleted>`.

The object contains:

* ``pipeline_id`` - The id of the pipeline.
* ``deletion_time`` - An ISO 8601 UTC timestamp indicating the date and
  time that the pipeline was deleted.

.. Docs note: not saying much here at the moment (3/13/14 PFD) about what you can or can't do with a UUID from a deleted pipeline due to
.. lack of integration with Reports stuff

.. }}}

.. {{{ Tags

.. _tags-api:



****
Tags
****

*Prior to the Urban Airship product release in Spring 2015, tag manipulation (addition, removal, setting of tags) was
handled either on the client- or server-side, but not both. Tags set by the device would be overwritten by tags set
from your server and vice versa.*

With the release of Named Users and Tag Groups, (see: :doc:`/topic-guides/mobile-data-bridge`), and in conjunction
with Urban Airship's multi-platform device identifier, :term:`Channel IDs <channel>`, tag manipulation is now fundamentally simpler *and* supports significantly more complex use-cases and integrations.

This reference covers API tag operations for Channels and Named Users, the two recommended approaches today. Reference
is also provided below for the ``/api/tags/`` endpoint, which must now be considered legacy.

.. _api-tags-channels:

Tags: Channels
==============

.. http:post:: /api/channels/tags/

   Allows the addition, removal, and setting of tags on a channel specified by the required ``audience`` field. A
   single request body may contain an ``add`` or ``remove`` field, or both, or a single ``set`` field. If both ``add``
   and ``remove`` are fields are present and the intersection of the tags in these fields is not empty,
   then a 400 will be returned.

   Tag operations done by application secret can only be made to a single channel.

   Tag set operations only update tag groups that are present in the request. Tags for a given Tag Group can be cleared
   by sending a ``set`` field with an empty list.

   Secure Tag Groups require the master secret to modfiy tags, otherwise a 403 Forbidden response is returned.

   If a tag update request contains tags in multiple Tag Groups, the request will be accepted if at least one
   of the Tag Groups is active. If inactive or missing Tag Groups are specified, a warning will be included
   in the response.

   .. note::

      ``tag_groups`` must be provisioned in the Urban Airship web application. See :ref:`Settings: Tag Groups <ug-settings-tag-groups>` for details on setting up Tag Groups.

   **Example request**:

   .. code-block:: http

      POST /api/channels/tags/ HTTP/1.1
      Authorization: Basic <master authorization string>
      Accept: application/vnd.urbanairship+json; version=3;
      Content-Type: application/json

      {
         "audience": {
            "ios_channel": "b8f9b663-0a3b-cf45-587a-be880946e881",
            "android_channel": "13863b3c-f860-4bbf-a9f1-4d785379b8a2",
         },
         "add": {
            "my_fav_tag_group1": ["tag1", "tag2", "tag3"],
            "my_fav_tag_group2": ["tag1", "tag2", "tag3"],
            "my_fav_tag_group3": ["tag1", "tag2", "tag3"]
         }
      }

   :JSON Paramaeters:

      * | **audience** - The required ``audience`` specifier should contain one or more channels to apply the tag operations to.
      * | **add**: - A map of tags to add to this or these channels.

Audience selectors are all of the following forms:

.. code-block:: json

   { "<type>" : "<id>" } or { "<type>" : ["<id1>", "<id2>",...] }

where ``<type>`` is one of:

* ``amazon_channel``
* ``android_channel``
* ``ios_channel``

Valid commands:

add
   Add the list of tags to the channel(s), but do not remove any. If the tags are already present, do not remove them.

remove
   Remove the list of tags from the channel(s), but do not remove any others. If the tags are not currently present, do nothing else.

set
   Set the current list of tags to this list exactly; any previously set tags that are not in this current list should be removed.

   **Example response**:

   .. code-block:: http

      HTTP/1.1 200 Ok
      Content-Type: application/json

      {
         "ok": true,
         "warnings": ["The following tag groups do not exist: my_fav_tag_group2", "The following tag groups are deactivated: my_fav_tag_group3"]
      }

.. _api-named-users-tags:

Tags: Named Users
=================

.. http:post:: /api/named_users/tags/

   This endpoint allows the addition, removal, and setting of tags on a named user. A single request body may
   contain an ``add`` or ``remove`` field, or both, or a single ``set`` field. If a tag is present in both
   the ``add`` and ``remove`` fields, however, a HTTP 400 response will be returned.

   Tag set operations only update :ref:`tag groups <tg-mdb-tag-groups>` that are present in the request. Tags
   for a given tag group can be cleared by sending a ``set`` field with an empty list.


   **Example Request**:

   .. code-block:: http

      POST /api/named_users/tags/ HTTP/1.1
      Authorization: Basic <master authorization string>
      Accept: application/vnd.urbanairship+json; version=3;
      Content-Type: application/json

      {
         "audience": {
            "named_user_id": ["user-1", "user-2", "user-3"]
         },
         "add": {
            "crm": ["tag1", "tag2", "tag3"],
            "loyalty": ["tag1", "tag4", "tag5"]
         },
         "remove": {
            "loyalty": ["tag6", "tag7"]
         }
      }

   .. note::

      One or more of the ``add``, ``audience``, or ``set`` keys must be present in a request to the
      ``/api/named_users/tags/`` endpoint.

   :JSON Parameters:

      * | **audience** - An :ref:`audience selector <audience-selectors>`.
      * | **add** - (Optional) Specifies the tags you'd like to add to the given tag groups.
      * | **remove** - (Optional) Specifies the tags you'd like to remove from the given tag groups.
      * | **set** - (Optional) Specifies the tags you would like to set on the given tag groups.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 Ok
      Content-Type: application/json

      {
         "ok": true
      }

Tags: Legacy
============

This reference is provided for customers using the ``/api/tags/`` endpoint. If you are using this endpoint, we highly recommend
transitioning to using tags on either Channels or Named Users (or both) in your implementation.

Tag Listing
-----------

.. http:get:: /api/tags/

   List tags that exist for this application.

   .. note::

      Tag Listing will return up to the first 100 tags per application.

   **Example Request**:

   .. code-block:: http

      GET /api/tags/ HTTP/1.1
      Authorization: Basic <application authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "tags": [
            "tag1",
            "some_tag",
            "portland_or"
         ]
      }

Tag Creation
------------

.. http:put:: /api/tags/(tag)

   Explicitly create a tag with no devices associated with it.

   .. note::

      This call is optional; tags are created implicitly when devices are added
      to them. You might use this to pre-create the list for your Push Composer
      users, however.

   **Example Request**:

   .. code-block:: http

      PUT /api/tags/new_tag HTTP/1.1
      Authorization: Basic <application authorization string>

   :status 200: The tag already exists.
   :status 201: The tag was created.
   :status 400: The tag is invalid.

.. _api-tags-add-remove:

Adding and Removing Devices from a Tag
--------------------------------------

.. warning::

   **Use Caution When Setting Tags Server-Side**

   **iOS**

   In the iOS SDK, registration is handled for you automatically, which gives
   us any tags that are set on the device. Calling this API from a server might interfere with metadata if
   set differently. Specifically, if you set a tag from the API but are
   using the SDK, the SDK will clear the tag upon registration.

   It is possible to disable tags being set by the SDK by setting ``deviceTagsEnabled`` to ``NO`` on iOS.

   **Android**

   Similarly, on Android/Amazon, metadata set from the server will be overwritten or cleared by
   registrations from the SDK unless you turn off device-side tag setting:

    **Prior to Android 5.0 SDK**:
       .. code-block:: obj-c

          PushManager.shared().setDeviceTagsEnabled(false);

    **Android SDK 5.0 or later**:
       .. code-block:: obj-c

          UAirship.shared().getPushManager()
                  .setDeviceTagsEnabled(false);

.. warning::

   The only justification for using this endpoint is setting server tags on device identifiers other than
   channels. If you wish to use this endpoint with channels only, we *strongly* recommend that you use the
   new :ref:`channels tag endpoint <api-channels-tags>` instead. The ``/api/channels/tags`` endpoint allows
   the specification of :ref:`tag groups <tg-mdb-tag-groups>`, circumventing the issue detailed in the
   previous warning.

.. http:post:: /api/tags/(tag)

   Add or remove one or more :term:`iOS, Android or Amazon channels<channel>` (or
   :term:`device tokens<device token>`,
   :term:`APIDs<APID>`, or :term:`PINs<PIN>`) to a particular tag.

   **Example Request**:

   .. code-block:: http

      POST /api/tags/some_tag HTTP/1.1
      Authorization: Basic <master authorization string>
      Content-Type: application/json; charset=utf-8

      {
         "ios_channels": {
            "add": [
               "9c36e8c7-5a73-47c0-9716-99fd3d4197d5",
               "9c36e8c7-5a73-47c0-9716-99fd3d4197d6"
            ]
         },
         "android_channels": {
            "remove": [
               "channel_1_to_remove"
            ]
         }
      }

   :status 200: The devices are being added or removed from this tag.
   :status 401: The authorization credentials are incorrect

   **Full capability**:

   Any number of Channels, device tokens, APIDs, or PINs can be added or
   removed.

   .. code-block:: http

      POST /api/tags/some_tag HTTP/1.1
      Authorization: Basic <master authorization string>
      Content-Type: application/json; charset=utf-8

      {
         "ios_channels": {
            "add": [
               "9c36e8c7-5a73-47c0-9716-99fd3d4197d5",
               "9c36e8c7-5a73-47c0-9716-99fd3d4197d6"
            ]
         },
         "device_tokens": {
            "add": [
               "device_token_1_to_add",
               "device_token_2_to_add"
            ],
            "remove": [
               "device_token_to_remove"
            ]
         },
         "device_pins": {
            "add": [
               "device_pin_1_to_add",
               "device_pin_2_to_add"
            ],
            "remove": [
               "device_pin_to_remove"
            ]
         },
         "apids": {
            "add": [
               "apid_1_to_add",
               "apid_2_to_add"
            ],
            "remove": [
               "apid_to_remove"
            ]
         }
      }

   :status 200: The devices are being added or removed from this tag.
   :status 401: The authorization credentials are incorrect

Deleting a Tag
--------------

A tag can be removed from our system by issuing a delete. This will remove the
master record of the tag. Additionally it will remove the tag from all devices
with the exception of devices that are inactive due to uninstall. Devices that
were uninstalled will retain their tags.


.. note::

   The removal process can take a long time if many devices use this tag.

.. http:delete:: /api/tags/(tag)

   Delete a tag and remove it from devices.

   **Example Request**:

   .. code-block:: http

      DELETE /api/tags/some_tag HTTP/1.1
      Authorization: Basic <master authorization string>


   **Example Response**:

   .. code-block:: http

      HTTP/1.1 204 No Content

   :status 204: The tag has been removed.
   :status 401: The authorization credentials are incorrect
   :status 404: The tag was not found or has already been removed.


Batch modification of tags
--------------------------

.. http:post:: /api/tags/batch/

   Modify the tags for a number of device tokens, channels, or apids.

   You must include an object containing either an ``ios_channel``, ``android_channel``,
   ``amazon_channel``, ``device_pins``, ``device_token`` or ``apid`` section and also containing a tags section to
   apply the tags.

   Each row of data will be validated to confirm that the device token, channel
   or APID is valid, and that a list of tags is present. For any row that does not
   match these validation requirements, an error response will be returned. The
   error response is an object, the errors member of which is an array of
   two-member arrays. The two-member arrays will contain the row that did not
   pass validation and the error response produced by our system. Note: the
   error messages are not normalized or machine-readable; they are currently
   just short strings meant to give the API caller enough information to debug
   the issue with the failed row. Note: we do not validate the existence of the
   APID, if one or more of the APIDs do not exist in our system the application
   of tags to those APIDs will silently fail.

   **Example Request**:

   .. code-block:: http

      POST /api/tags/batch/ HTTP/1.1
      Authorization: Basic <master authorization string>

      [
         {
            "ios_channel": "9c36e8c7-5a73-47c0-9716-99fd3d4197d5",
            "tags": [
               "tag_to_apply_1",
               "tag_to_apply_2"
            ]
         },
         {
            "device_token": "device_token_to_tag_1",
            "tags": [
               "tag_to_apply_1",
               "tag_to_apply_2",
               "tag_to_apply_3"
            ]
          },
         {
            "device_token": "device_token_to_tag_2",
            "tags": [
               "tag_to_apply_1",
               "tag_to_apply_4",
               "tag_to_apply_5"
            ]
         },
         {
            "apid": "apid_to_tag_2",
            "tags": [
               "tag_to_apply_1",
               "tag_to_apply_4",
               "tag_to_apply_5"
            ]
         }
      ]

   .. todo:: example response?

   :status 200: The tags are being applied.
   :status 400: The batch tag request was invalid.
   :status 401: The authorization credentials are incorrect

.. }}}

.. {{{ Actions

.. _actions-api:

*******
Actions
*******

Actions are specified by the ``"actions"`` attribute on a notification object. See :ref:`push-object` for more
detail about the notification object.

.. code-block:: json

   {
      "audience": "all",
      "notification": {
         "alert": "You got your emails!",
         "actions": {
            "add_tag": "MY_TAG"
         }
      },
      "device_types" : "all"
   }

.. note::

   For information on how ``actions`` are handled within the client code within your app, see: :ref:`iOS
   Actions <ios-actions>` and :ref:`Android Actions <android-actions>`.

The ``"actions"`` attribute MUST be an object as described in this
section. The ``actions`` object can have the following five attributes:

* ``"add_tag"`` -- see :ref:`add_tag <add_tag>`
* ``"remove_tag"`` -- see :ref:`remove_tag <remove_tag>`
* ``"open"`` -- see :ref:`open <open>`
* ``"share"``     -- :ref:`share <api-actions-share>`
* ``"app_defined"`` -- :ref:`application-defined actions <action-mapping>`

Any combination of these attributes may be present. If any other attribute is
present, an HTTP 400 response will be returned. Also, if no attributes are
present, a 400 will be returned.

**Example**:

This ``actions`` object contains each of the possible action attributes.

.. code-block:: json

   {
      "actions": {
         "add_tag": "airship",
         "remove_tag": "boat",
         "share": "Check out Urban Airship!",
         "open": {
            "type": "url",
            "content": "http://www.urbanairship.com"
         },
         "app_defined": { "some_app_defined_action" : "some_value" }
      }
   }


.. _add_tag:

Add Tag
=======

The ``"add_tag"`` attribute can be a single string or an array of strings. A
``null`` value, empty array, or any ``null`` values in the array will result in
an HTTP 400 response. Duplicate tags in an array will not cause an error, but
will have the same effect as if just a single instance of that tag was included.

.. note::

   A single-element array will be passed to the client device (we do not turn
   it into a plain string).

**Example**:

Here we add a single tag:

.. code-block:: json

   {
      "actions": {
         "add_tag": "a_tag"
      }
   }

Here we add several tags:

.. code-block:: json

   {
      "actions": {
         "add_tag": ["a_tag", "b_tag"]
      }
   }

.. _remove_tag:

Remove Tag
==========

The ``"remove_tag"`` attribute can be a single string or an array of strings. A
``null`` value, empty array, or any ``null`` values in the array will result in
an HTTP 400 response. Duplicate tags in an array will not cause an error, but
will have the same effect as if just a single instance of that tag was included.

.. note::

   A single-element array will be passed on to the client device (we do not turn
   it into a plain string).

**Example**:

Here we remove a tag:

.. code-block:: json

   {
      "actions": {
         "remove_tag": "a_tag"
      }
   }

Here we remove several tags:

.. code-block:: json

   {
      "actions": {
         "remove_tag": ["a_tag", "b_tag"]
      }
   }

.. _open:

Open
====

The ``"open"`` attribute MUST be an object with two attributes: ``type`` and
``content``.

* ``"type"`` -- A string. MUST be one of: ``url``, ``deep_link`` or
  ``landing_page``:

  * ``"url"`` -- ``"content"`` is a string, which MUST be a URL. ``null`` is not accepted. The URL MUST start with either "``http``" or "``https``".

  * ``"deep_link"`` -- ``"content"`` MUST be non-blank string. ``null`` is not accepted.

  * ``"landing_page"`` -- ``content`` must be a content object (see example).


If the ``open`` object fails any of these conditions, an HTTP 400
will be returned.

**Examples**:

Examples for each type of ``"open"``:

.. code-block:: json

   {
      "actions": {
         "open": {
            "type": "url",
            "content": "http://www.urbanairship.com"
         }
      }
   }

In the following example, note that the value for the ``"content"`` attribute, ``"prefs"``, is a string
representing a common deep-linking use case: sending the user to the app's preferences page. This is not
an out-of-the-box deep link; rather, it must be defined in your project.

See the :doc:`/topic-guides/ios-deep-linking` and :doc:`Android/Amazon Deep Link Actions </topic-guides/android-deep-linking>`
topic guides for information about defining these resources in your app.

.. code-block:: json

   {
      "actions": {
         "open": {
            "type": "deep_link",
            "content": "prefs"
         }
      }
   }

.. code-block:: json

   {
      "actions": {
         "open": {
            "type": "landing_page",
            "content": {
               "body": "<html>content</html>",
               "content_type": "text/html",
               "content_encoding": "utf-8"
            }
         }
      }
   }


.. _api-actions-share:

Share
=====

The ``"share"`` attribute must be a string if present. Anything else will return an HTTP 400 response.

In the following example, the text "Check out Urban Airship!" will populate the share feature for the user.

**Example**:

.. code-block:: json

   {
      "actions": {
         "share": "Check out Urban Airship!"
      }
   }


.. _action-mapping:

Action Mappings
================

Most of the top-level actions described above also map to a short name and
a long name on the mobile device. You can use these alternatives in your
API requests if you include them under the ``app_defined`` object. If either
the short name or the long name appears in the ``app_defined`` object, but
the corresponding top-level key also appears, then an HTTP 400 error will be
returned. However, no error occurs if the corresponding top-level key does
not appear.

========================================== ========== =========================
Action                                     Short Name Long Name
========================================== ========== =========================
``add_tag``                                ^+t        add_tags_action
``remove_tag``                             ^-t        remove_tags_action
``open: { "type": "url", ... }``           ^u         open_external_url_action
``open: { "type": "deep_link", ... }``     ^d         deep_link_action
``open: { "type": "landing_page", ... }``  ^p         landing_page_action
========================================== ========== =========================

.. todo::

   add mapping for ``open: { "type": "message" }`` as well as a section
   describing its use above

**Examples:**

This is the short name equivalent of the top-level action ``add_tag``:

.. code-block:: json

   {
      "actions": {
         "app_defined": {
            "^+t": "foo"
         }
      }
   }

And here is the long name equivalent of the top-level ``"open"`` action for a
``"url"``:

.. code-block:: json

   {
      "actions": {
         "app_defined": {
            "open_external_url_action": "http://www.urbanairship.com"
         }
      }
   }

This next example will result in an HTTP 400 because the ``app_defined``
action ``^+t`` corresponds to the top-level action ``add_tag``:

.. code-block:: json

   {
       "actions": {
           "add_tag": "foo",
           "app_defined": {
               "^+t": "bar"
           }
       }
   }

This action will result in an HTTP 400 because the ``app_defined`` action
``^p`` corresponds to the top-level ``open`` action for a landing page:

.. code-block:: json

   {
       "actions": {
           "open": {
               "type": "landing_page",
               "content": {
                   "body": "foo",
                   "content_type": "text/html"
               }
           },
           "app_defined": {
               "^p": "bar"
           }
       }
   }

This action results in an error because the ``app_defined`` action
``add_tags_action`` maps to the top-level ``add_tag`` action:

.. code-block:: json

   {
       "actions": {
           "add_tag": "foo",
           "app_defined": {
               "add_tags_action": "bar"
           }
       }
   }

This action will result in an HTTP 400 because the same key (``"open"``) appears
in both the ``app_defined`` and top-level ``action`` objects:

.. code-block:: json

   {
      "actions": {
         "open": {
            "type": "landing_page",
            "content": {
               "body": "foo",
               "content_type": "text/html"
            }
         },
         "app_defined": {
            "open": {
               "type": "deep_link",
               "content": "bar"
            }
         }
      }
   }

.. note::

   The preceding shows that even if a top-level ``open`` action seems to
   represent a different meaning than an ``app_defined`` ``open`` action, we
   still give an HTTP 400 due to duplicate key appearing on both objects.

This action will NOT result in an error. The top-level action opens a landing
page (``"open" : { "type" : "landing_page" }``), but the ``app_defined`` action
``^d`` corresponds to a deep-link open, not a landing page open:

.. code-block:: json

   {
      "actions": {
         "open": {
            "type": "landing_page",
            "content": {
               "body": "foo",
               "content_type": "text/html"
            }
         },
         "app_defined": {
            "^d": "bar"
         }
      }
   }

.. note::

   Even though you don't receive an error, since both of these are ``"open"`` actions, which one will actually
   be opened is unknown. One of them will most likely be dropped on the mobile device (unless the app developer
   has overridden action handling in some way to deal with this).

This action will NOT result in an error, but is also problematic. The
``app_defined`` keys ``^d`` and ``deep_link_action`` map to the same action on
the device, but we do not translate any keys in the ``app_defined`` object, so
no error occurs:

.. code-block:: json

   {
      "actions": {
         "app_defined": {
            "^d": "bar",
            "deep_link_action": "baz"
         }
      }
   }

.. note::

   Only one of these will actually be included in the delivery to the mobile device and result in an action.

.. _ios-extras-and-actions:

iOS, Extras and Actions
=======================

On iOS, the ``extra`` object can conflict with top-level action names. If an
``extra`` key is the same as one of the long or short names specified in the
:ref:`Action Mappings <action-mapping>` section, and the corresponding
top-level action is present, then an HTTP 400 will be returned.

Additionally, if an ``extras`` key is the same as a key on the ``app_defined``
object, an HTTP 400 will be returned.

**Example**:

This action will result in an HTTP 400 because the same key (``"open"``) appears in
the ``app_defined`` and ``extra`` objects:

.. code-block:: json

   {
      "notification": {
         "alert": "Boo",
         "ios": {
            "extra": {
               "open": "hello"
            }
         },
         "actions": {
            "app_defined": {
               "open": "goodbye"
            }
         }
      }
   }

This action will give an HTTP 400 because the ``extra`` object carries a key that
conflicts with the long name (``"add_tags_action"``) for the ``add_tags``
action.

.. code-block:: json

   {
      "notification": {
         "alert": "Boo",
         "ios": {
            "extra": {
               "add_tags_action": "hello"
            }
         },
         "actions": {
            "add_tags": "hello"
         }
      }
   }


The following example would also give an HTTP 400 because the ``"^+t"`` key on
the ``extra`` object conflicts with short name for the ``add_tags`` action:

.. code-block:: json

   {
      "notification": {
         "alert": "Boo",
         "ios": {
            "extra": {
               "^+t": "hello"
            }
         },
         "actions": {
            "add_tags": "hello"
         }
      }
   }

This action will NOT give an error, even though the ``extra`` object has a key
(``"add_tags_action"``) matching the long name for ``add_tags``, because
``"add_tags"`` is not included as a top-level action:

.. code-block:: json

   {
      "notification": {
         "alert": "Boo",
         "ios": {
            "extra": {
               "add_tags_action": "hello"
            }
         },
         "actions": {
            "remove_tags": "hello"
         }
      }
   }

This action will NOT give an error, even though the ``extra`` object has a
``^+t`` key, because the "add_tags_action" key is included in the ``app_defined``
section, and therefore won't be translated to a short name:

.. code-block:: json

   {
      "notification": {
         "alert": "Boo",
         "ios": {
            "extra": {
               "^+t": "hello"
            }
         },
         "actions": {
            "app_defined": {
               "add_tags_action": "hello"
            }
         }
      }
   }

.. note::

   In the above case, the client device will most likely drop one of the
   actions, and the results will be indeterminate.

Actions payload for GCM and iOS
-------------------------------

*Actions* specify a payload that will be sent to the mobile
device. Predefined actions use the mapping as specified in the
:ref:`action mappings <action-mapping>` section. This section details the
specific payload sent to iOS and Android devices.

On iOS, action names map to keys at the top level of the payload, and arguments
are any valid JSON fragment (as long as the targeted action supports those
arguments).

On Android we can only send extras in the form of string-to-string key/value
pairs. Therefore, we will send the "com.urbanairship.actions" key, whose value will be serialized
JSON object mapping action names to argument values.

**Example**:

Here is a push payload that adds a tag and alerts the user:

.. code-block:: json

   {
      "audience": "all",
      "notification": {
         "alert": "You got your emails!",
         "actions": {
            "add_tag": "MY_TAG"
         }
      },
      "device_types": ["ios", "android"]
   }

The APNS payload sent to an iOS device will look like:

.. code-block:: json

   {
      "aps": {
         "alert": "You got your emails."
      },
      "^+t": "MY_TAG"
   }


And the GCM payload sent to an Android device will look like (notice that
the value of the ``actions`` key is a serialized JSON object):

**Example**:

.. code-block:: json

   {
      "registration_ids": [ "..."],
      "data": {
         "alert": "You got your emails!",
         "com.urbanairship.actions": "{\"^+t\" : \"MY_TAG\"}"
      }
   }

.. }}}

.. {{{ Interactive notifications

.. _interactive-api:

*************************
Interactive Notifications
*************************

*Interactive Notifications* are specified by the ``"interactive"`` attribute in a notification object. The
``"interactive"`` attribute must be an object as described in this section. The ``interactive`` object
may contain the following two attributes:

- ``"type"`` -- see :ref:`api-interactive-type`

- ``"button_actions"`` -- see :ref:`api-interactive-button-actions`

The ``type`` attribute is mandatory and the ``button_actions`` attribute is optional. If any other attribute
is present, an HTTP 400 response will be returned.  Attempting to specify an interactive payload on an
unsupported device will result in an HTTP 400 response.

**Example**:

This ``interactive`` object contains a pre-defined ``"type"`` with actions defined for each button.

.. code-block:: json
   :emphasize-lines: 3,4

   {
      "interactive": {
         "type": "ua_yes_no_foreground",
         "button_actions": {
            "yes": {
               "add_tag": "more_cake_please",
               "remove_tag": "lollipop",
               "open": {
                  "type": "url",
                  "content": "http://www.urbanairship.com"
               }
            },
            "no": {
               "add_tag": "nope"
            }
         }
      }
   }

**Example**:

This ``interactive`` object contains the pre-defined ``"ua_share"`` type with the share button action and text
defined.

.. code-block:: json
   :emphasize-lines: 3

   {
      "interactive": {
         "type": "ua_share",
         "button_actions": {
            "share": { "share": "Look at me! I'm on a boat." }
         }
      }
   }

.. _api-interactive-type:

Type
====

The ``type`` field of the ``interactive`` object must be a string and specify either the name of one of the
:doc:`predefined interactive notifications </reference/built-in_interactive_notifications>` or a custom defined
interactive notification. Note that all predefined interactive notification types begin with the prefix
``"ua_"``, and custom defined interactive notification types must not begin with ``"ua_"``.

.. _api-interactive-button-actions:

Button Actions
==============

The ``button_actions`` field of the ``interactive`` object must be an object if present. The keys are
the button IDs for the specified interactive notification type. If the notification type begins with
``"ua_"``, the keys must match exactly the button IDs for that type or a strict subset. The names of the button
IDs cannot be validated for custom notifications. The values must be valid Actions objects as described
in the :ref:`Actions API documentation <actions-api>`.

.. }}}

.. {{{ Channels

.. _api-channels:

********
Channels
********

.. _api-channel-object:

Channel Object
==============

.. code-block:: json

   {
      "channel_id": "01234567-890a-bcde-f012-3456789abc0",
      "device_type": "ios",
      "installed": true,
      "background": true,
      "opt_in": false,
      "push_address": "FE66489F304DC75B8D6E8200DFF8A456E8DAEACEC428B427E9518741C92C6660",
      "created": "2013-08-08T20:41:06",
      "last_registration": "2014-05-01T18:00:27",

      "alias": "your_user_id",
      "tags": [
         "tag1",
         "tag2"
      ],

      "tag_groups": {
         "tag_group_1": ["tag1", "tag2"],
         "tag_group_2": ["tag1", "tag2"]
      },

      "ios": {
         "badge": 0,
         "quiettime": {
            "start": null,
            "end": null
         },
         "tz": "America/Los_Angeles"
      }
   }

:JSON Paramaeters:

   * | **channel_id** – (String) The unique :term:`channel` identifier assigned to this device.
   * | **device_type** – (String) Specifies the platform. In this case, one of ``"ios"``, ``"android"``, or
       ``"amazon"``.
   * | **installed** – (Boolean) Specifies whether the channel is installed or not.
   * | **background** – (Boolean) Specifies whether the device associated with this channel has background
       app refresh enabled. If this is true, then the device can receive background push. This field only
       appears for iOS devices on the 5.0+ SDK.
   * | **opt_in** – (Boolean) Specifies whether this channel is opted-in to push. For devices on SDK 4.0 or
       under, we assume this is ``true`` except in the following two scenerios: the app has been
       uninstalled, or the user explicitly disabled push from within the app.
   * | **push_address** – (String) The underlying device identifier (e.g. a device token, APID, or BlackBerry
       PIN) that maps to this channel.
   * | **created** – (String) The creation date of this channel identifier.
   * | **last_registration** – (String) Displays the last registration date of this channel, if it is known.
   * | **alias** – (String) Displays the alias associated with this channel, if one exists.
   * | **tags** – (Array) An array of tags associated with this channel.
   * | **ios** – (Object) An object containing iOS-specific parameters. Contains the current badge value,
       :ref:`quiet time <int-quiet-time>` preferences, and the timezone associated with the device.


.. _api-channel-lookup:

Channel Lookup
==============

.. http:get:: /api/channels/(channel)

   Get information on an individual :term:`channel`

   .. note::

      For more information on Channels, see :doc:`/topic-guides/channels`.

   **Example Request**:

   .. code-block:: http

      GET /api/channels/9c36e8c7-5a73-47c0-9716-99fd3d4197d5 HTTP/1.1
      Authorization: Basic <application authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "ok": true,
         "channel": {
            "channel_id": "01234567-890a-bcde-f012-3456789abc0",
            "device_type": "ios",
            "installed": true,
            "opt_in": false,
            "push_address": "FE66489F304DC75B8D6E8200DFF8A456E8DAEACEC428B427E9518741C92C6660",
            "created": "2013-08-08T20:41:06",
            "last_registration": "2014-05-01T18:00:27",

            "alias": "your_user_id",
            "tags": [
               "tag1",
               "tag2"
            ],

            "tag_groups": {
               "tag_group_1": ["tag1", "tag2"],
               "tag_group_2": ["tag1", "tag2"]
            },

            "ios": {
               "badge": 0,
               "quiettime": {
                  "start": null,
                  "end": null
               },
               "tz": "America/Los_Angeles"
            }
         }
      }

   :json channel: A :ref:`api-channel-object`.

.. note::

   Tags added to a channel via the :ref:`Named Users tag endpoint <api-named-users-tags>` will not appear
   with a request to this endpoint. To view those tags, you must :ref:`lookup the Named User
   <api-named-users-lookup>` associated with the channel.


.. _channel-list-api:

Channel Listing
===============

.. http:get:: /api/channels/

   Fetch :term:`channels <channel>` registered to this application, along with associate data and metadata

   **Example Request**:

   .. code-block:: http

      GET /api/channels/ HTTP/1.1
      Authorization: Basic <master authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "next_page": "https://go.urbanairship.com/api/channels?start=07AAFE44CD82C2F4E3FBAB8962A95B95F90A54857FB8532A155DE3510B481C13&limit=2",
         "channels": [
            {
               "channel_id": "9c36e8c7-5a73-47c0-9716-99fd3d4197d5",
               "device_type": "ios",
               "push_address": "FE66489F304DC75B8D6E8200DFF8A456E8DAEACEC428B427E9518741C92C6660",
               "opt_in": true,
               "installed": true,

               "created": "2014-03-06T18:52:59",
               "last_registration": "2014-10-07T21:28:35",

               "alias": "your_user_id",
               "tags": [
                  "tag1",
                  "tag2"
               ],

               "tag_groups": {
                  "tag_group_1": ["tag1", "tag2"],
                  "tag_group_2": ["tag1", "tag2"]
               },

               "ios": {
                  "badge": 2,
                  "quiettime": {
                     "start": "22:00",
                     "end": "8:00"
                  },
                  "tz": "America/Los_Angeles"
               }
            },
            {
               "channel_id": "bd36e8c7-5a73-47c0-9716-99fd3d4197d5",
               "device_type": "ios",
               "push_address": null,
               "opt_in": false,
               "installed": true,

               "created": "2014-03-06T18:52:59",
               "last_registration": "2014-10-07T21:28:35",

               "alias": "your_user_id",
               "tags": [
                  "tag1",
                  "tag2"
               ],

               "tag_groups": {
                  "tag_group_1": ["tag1", "tag2"],
                  "tag_group_2": ["tag1", "tag2"]
               },

               "ios": {
                  "badge": 0,
                  "quiettime": {
                     "start": null,
                     "end": null,
                  },
                  "tz": null
               }
            }
         ]
      }

   :json next_page: (String) There might be more than one page of results for this
      listing. Follow this URL if it is present to the next batch of results.
   :json channels: (Array of objects) An array of :ref:`channel objects <api-channel-object>`.

.. note::

   Tags added to a channel via the :ref:`Named Users tag endpoint <api-named-users-tags>` will not appear
   with a request to this endpoint. To view those tags, you must do a :ref:`Named User listing
   <api-named-users-lookup>`.


.. _api-channels-tags:

Add/Remove Tags From Channel
============================

.. http:post:: /api/channels/tags/

   This endpoint allows the addition, removal, and setting of tags on a channel specified by the ``audience`` field. A
   single request may include an ``add`` or ``remove`` field, or both, or a single ``set`` field. If both ``add`` and
   ``remove`` fields are present, and the intersection of tags in these fields is not empty, then a 400 will be returned.

   **Example Request**:

   .. code-block:: http

      POST /api/channels/tags/ HTTP/1.1
      Authorization: Basic <master authorization string>
      Accept: application/vnd.urbanairship+json; version=3;
      Content-Type: application/json; charset=utf-8

      {
         "audience": {
            "ios_channel": "b8f9b663-0a3b-cf45-587a-be880946e881",
            "android_channel": "13863b3c-f860-4bbf-a9f1-4d785379b8a2"
         },
         "add": {
            "crm": ["active", "partner"]
         }
      }

   .. warning::

      Previously, adding tags to a device using both the client and the server, via the old ``/api/tags/`` endpoint, would result
      in possible overwriting errors (see :ref:`this warning <api-tags-add-remove>`). The new `/api/channels/tags/` endpoint mostly
      circumvents this issue by allowing you to specify tag groups, **so long as you are manipulating tag groups other than**
      ``device``. The ``/api/channels/tags/`` endpoint encounters  the same server-client tagging issues when used with the
      ``device`` tag group.

.. }}}

.. {{{ Feeds

.. _feeds-api:

*****
Feeds
*****

The Feed API is used to add and remove RSS or Atom feeds used to trigger push notifications. For most
users the API is unnecessary, and you should use the dashboard instead. For more information about feeds, see
:ref:`integrating feeds <feeds-integration>`.


Creating a new feed
===================

.. http:post:: /api/feeds/

   We only require two things be present in the data: the feed URL you wish
   to follow and your feed template.

   We recommend checking the template with our feeds interface to see
   exactly how it performs.

   **Example Request**:

   .. code-block:: http

      POST /api/feeds/ HTTP/1.1
      Authorization: Basic <master authorization string>
      Content-Type: application/json; charset=utf-8

      {
         "feed_url": "http://example.com/atom.xml",
         "template": {
            "audience": "all",
            "device_types": [ "ios", "android" ],
            "notification": {
               "alert": "Check this out! - {{ title }}",
               "ios": {
                  "alert": "New item! - {{ title }}"
               }
            }
         }
      }

   :json feed_url: The full URL to the RSS or Atom feed.
   :json template: A template for the API v3 push object.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 201 Created
      Content-Type: application/json; charset=utf-8
      Location: https://go.urbanairship.com/api/feeds/<feed_id>/

      {
         "url": "https://go.urbanairship.com/api/feeds/<feed_id>/",
         "id": "<feed_id>",
         "last_checked": null,
         "feed_url": "http://example.com/atom.xml",
         "template": {
            "audience": "all",
            "device_types": [ "ios", "android" ],
            "notification": {
               "alert": "Check this out! - {{ title }}",
               "ios": {
                  "alert": "New item! - {{ title }}"
               }
            }
         }
      }

   :json url: The location of the feed entry. Can be used for altering or
      removing the feed later.
   :json last_checked: The last time we saw a new entry for this feed, in
      :term:`UTC`.
   :status 201: The feed is now being monitored.
   :status 400: The request is invalid; see the response body for details.
   :status 401: The authorization credentials are incorrect.


Feed details
============

.. http:get:: /api/feeds/(feed_id)/

   Returns information about that particular feed.

   **Example Request**:

   .. code-block:: http

      GET /api/feeds/<feed_id> HTTP/1.1
      Authorization: Basic <master authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "url": "https://go.urbanairship.com/api/feeds/<feed_id>/",
         "template": {
            "audience": "all",
            "device_types": "all",
            "notification": {
               "alert": "New Item! - {{ title }}"
            }
         },
         "id": "<feed_id>",
         "last_checked": "2010-03-08 21:52:21",
         "feed_url": "<your_feed_url>"
      }

   :json url: The location of the feed entry. Can be used for altering or
      removing the feed later.
   :json last_checked: The last time we saw a new entry for this feed, in
      :term:`UTC`.

Updating a feed
===============

.. http:put:: /api/feeds/(feed_id)/

   Updates a feed with a new template

   **Example Request**:

   .. code-block:: http

      PUT /api/feeds/<feed_id> HTTP/1.1
      Authorization: Basic <master authorization string>
      Content-Type: application/json; charset=utf-8

      {
         "template": {
            "audience": { "tag": "new_customer" }
            "device_types": [ "android" ]
            "notification": {
               "alert": "New item! - {{ title }}"
            }
         }
      }

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "url": "https://go.urbanairship.com/api/feeds/<feed_id>/",
         "template": {
            "audience": { "tag": "new_customer" }
            "device_types": [ "android" ]
            "notification": {
               "alert": "New item! - {{ title }}"
            }
         },
         "id": "<feed_id>",
         "last_checked": "2010-03-08 21:52:21",
         "feed_url": "<new_feed_url>"
      }

   :json url: The location of the feed entry. Can be used for altering or
      removing the feed later.
   :json last_checked: The last time we saw a new entry for this feed, in
      :term:`UTC`.
   :status 200: The feed update was successful.
   :status 400: The request is invalid; see the response body for details.
   :status 401: The authorization credentials are incorrect.


Deleting a feed
===============

.. http:delete:: /api/feeds/(feed_id)/

   Removes a feed from the monitoring service, and stops new pushes from being
   sent.

   **Example Request**:

   .. code-block:: http

      DELETE /api/feeds/<feed_id> HTTP/1.1
      Authorization: Basic <master authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 204 No Content

   :status 204: The feed was deleted, and no content was returned.

.. }}}

.. {{{ Rich App Pages

.. _rich-push-api:

**************
Rich App Pages
**************

.. note::

   As of the release of the Urban Airship Push API v3, the operation of sending a rich message to an inbox within
   the application is no longer handled via the Rich Push endpoints at ``/api/airmail/``.

   Rich content which is optionally associated with a push notification is now included in the ``message`` component of
   the Push API at ``/api/push/``


.. _api-sending-a-rich-message:

Sending a Rich Message
======================

.. http:post:: /api/push/


.. code-block:: json

    {
       "audience": { "tag": [ "tag1", "tag2" ] },
       "notification": { "alert": "New message!" },
       "message": {
          "title": "Message title",
          "body": "<Your message here>",
          "content_type": "text/html"
       }
    }

.. note::

   Rich messages automatically result in a badge update, even if the ``notification`` attribute is not
   included in the payload. This is default behavior. Customers who would like to turn off this behavior
   should contact Support or their technical account manager.

.. warning::

   Because rich push broadcasts cannot be segmented by platform, the ``"device_types"`` parameter that may
   be present during a standard push broadcast has no effect here. For example, if the above request included
   a ``"device_types" : [ "ios" ]`` line, the message would still be sent to *all* devices with the required
   tags, including Android and Amazon devices.

.. _rich-push:

Rich Message Object
======================

The object may have the following attributes:

* ``title`` — Required, string
* ``body`` — Required, string
* ``content_type`` or ``content-type`` — Optional, a string denoting the MIME type of the
  data in ``body``. Defaults to ``"text/html"``.
* ``content_encoding`` or ``content-encoding`` — Optional, a string denoting encoding type
  of the data in ``body``. For example, ``utf-8`` or
  ``base64``. Defaults to ``utf-8`` if not supplied. ``base64``
  encoding can be used in cases which would be complex to escape
  properly, just as HTMl containing embedded JavaScript code, which
  itself may contain embedded JSON data.
* ``expiry`` - The expiry time for a rich app page to delete a message from the user’s inbox. Can be an integer encoding number
  of seconds from now, or an absolute timestamp in ISO UTC format. An integer value of 0 is equivalent to no expiry set.
* ``extra`` — a JSON dictionary of string values. Values for each
  entry may only be strings. If an API user wishes to pass structured
  data in an extra key, it must be properly JSON-encoded as a string.
* ``icons`` — an optional JSON dictionary of string key and value pairs. At this time,
  only one key, "list_icon", is supported. Values must be URI/URLs to the icon
  resources. For resources hosted by UA, use the following URI format "ua:<resource-id>".
  For example: ``"icons" : { "list_icon" : "ua:9bf2f510-050e-11e3-9446-14dae95134d2" }``
* ``options`` — an optional JSON dictionary of key and value pairs specifying non-payload options (**coming soon**).

.. note::

   Use of ``expiry`` carries the following SDK requirements:

   - iOS 3.0.4 or greater
   - Android 3.2.3 or greater
   - Amazon 4.0.0 or greater

**Example**:

.. code-block:: json

   {
      "audience": "all",
      "notification": {
         "ios": {
            "badge": "+1"
         }
      },
      "message": {
         "title": "This week's offer",
         "body": "<html><body><h1>blah blah</h1> etc...</html>",
         "content_type": "text/html",
         "expiry": "2015-04-01T12:00:00",
         "extra": {
            "offer_id": "608f1f6c-8860-c617-a803-b187b491568e"
         },
         "icons": {
            "list_icon": "http://cdn.example.com/message.png"
         },
         "options": {
            "some_delivery_option": true
         }
      }
   }


.. _rich-push-message-id:

Rich Message ID
===============

Rich message IDs generated by the API are in the form of web-safe
base64-encoded UUIDs, which are 22 characters in length. For example,
``"hpkAHEIAAAl6wn2h6yUR4g"``.

When a rich message is accompanied by a push notification, the ID of the rich
message will be added to the notification payload that is sent to the device
for any platform that supports ``extra`` (currently iOS, Android) as
the value of the key ``"_uamid"``. This will be a root level key in the iOS
payload, and a member of the ``"extra"`` map for Android and ADM.

For iOS, this reduces the number of bytes available for the APNS alert payload
from 2000 to 1966 (by adding ``,"_uamid":"hpkAHEIAAAl6wn2h6yUR4g"`` to the APNS
payload).

.. }}}

.. {{{ Reports

.. _reports-api:

*******
Reports
*******

.. warning::

   The :ref:`Statistics API <statistics-api>` at ``/api/push/stats/`` is available to all customers.

   The Urban Airship Reports APIs, however, are only available for use by customers on certain paid account plans.
   Please contact Support or your account manager if you are unable to use them for an app key that
   you believe is on an appropriate plan.


.. Commenting out Active user count section 9/29/14 per Neel B. see /extdocs/pull/583

   Active User Count
   -----------------

   .. http:get:: /api/reports/activeusers/?date=(date)

      Returns the number of billable users for the month, broken out by iOS
      and Android. Results are scoped to specified month for months in the
      past, month-to-date for the current month. ``date`` can be any date within
      the month in question (for example, ``date=2012-04-15`` would return results
      for the entire month of April, 2012).

      **Example request**

      .. code-block:: http

         GET /api/reports/activeusers/?date=2013-01-01 HTTP/1.1
         Authorization: Basic <master authorization string>

      :query date: Date specifying which month to query for.

      **Example response**

      .. code-block:: http

         HTTP/1.1 200 OK
         Content-Type: application/json; charset=utf-8

         {
            "android": 505948,
            "ios": 741360
         }


.. _api-push-response:

Individual Push Response Statistics
===================================

.. http:get:: /api/reports/responses/(push_id)

   Returns detailed reports information about a specific push notification. Use the
   ``push_id``, which is the identifier returned by the API that represents a
   specific push message delivery.

   **Example Request**:

   .. code-block:: http

      GET /api/reports/responses/8913541 HTTP/1.1
      Authorization: Basic <master authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 Ok
      Content-Type: application/json; charset=utf-8

      {
         "push_uuid": "f133a7c8-d750-11e1-a6cf-e06995b6c872",
         "direct_responses": "45",
         "sends": 123,
         "push_type": "UNICAST_PUSH",
         "push_time": "2012-07-31 12:34:56"
      }

   :json push_type: Describes the push *operation*, which is often comparable to the audience
      selection, e.g., ``BROADCAST_PUSH``

.. _device-counts-api:

Devices Report API
===================

.. http:get:: /api/reports/devices/?date=(Date)

   Returns an app’s opted-in and installed device counts broken out by device type. This endpoint returns
   the same data that populates the :ref:`devices-report`.

   **Example Request**:

   .. code-block:: http

      GET /api/reports/devices/?date=2014-05-05%2010:00 HTTP/1.1
      Authorization: Basic <master authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 Ok
      Content-type: application/json; charset=utf-8

      {
         "total_unique_devices": 150,
         "date_computed": "2014-10-01T08:31:54.000Z",
         "date_closed": "2014-10-01T00:00:00.000Z",
         "counts": {
            "android": {
                "unique_devices": 50,
                "opted_in": 0,
                "opted_out": 0,
                "uninstalled": 10
            },
            "ios": {
                "unique_devices": 50,
                "opted_in": 0,
                "opted_out": 0,
                "uninstalled": 10
            },
         }
      }

   :json total_unique_devices: Sum of the unique devices for every device type
   :json date_computed: The date and time the device event data was tallied and stored
   :json date_closed: All device events counted occured before this date and time
   :json unique_devices: Devices considered by Urban Airship Reports to have the app installed
   :json opted_in: Opted in to receiving push notifications
   :json opted_out: Opted out of receiving push notifications
   :json uninstalled: Devices for which Reports has seen an uninstall event

Push Report
===========

.. http:get:: /api/reports/sends/?start=(date)&end=(date)&precision=(precision)

   Get the number of pushes you have sent within a specified time period.

   **Example HTTP request**:

   .. code-block:: http

      GET /api/reports/sends/?start=2012-05-05%2010:00&end=2012-05-15%2020:00&precision=HOURLY HTTP/1.1
      Authorization: Basic <master authorization string>

   :query start: Timestamp for start of report
   :query end: Timestamp for end of report
   :query precision: Granularity of results to return. Possible values: ``HOURLY``, ``DAILY``, ``MONTHLY``

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "sends": [
            {
               "android": 50
               "date": "2012-12-01 00:00:00",
               "ios": 500
            }
         ]
         "next_page": "https://go.urbanairship.com/api/reports/..."
      }

   :json next_page: There might be more than one page of results for this
      report. Follow this URL if it is present to the next batch of results.

Response Report
===============

.. http:get:: /api/reports/responses/?start=(date)&end=(date)&precision=(precision)

   Get the number of direct and influenced opens of your app.

   **Example Request**:

   .. code-block:: http

      GET /api/reports/responses/?start=2012-05-05%2010:00&end=2012-05-15%2020:00&precision=HOURLY HTTP/1.1
      Authorization: Basic <master authorization string>

   :query start: Timestamp for start of report
   :query end: Timestamp for end of report
   :query precision: Granularity of results to return. Possible values:
      ``HOURLY``, ``DAILY``, ``MONTHLY``

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "next_page": "https://go.urbanairship.com/api/reports/..."
         "responses": [
            {
               "android": {
                  "direct": 0,
                  "influenced": 0
               },
               "date": "2012-12-11 10:00:00",
               "ios": {
                  "direct": 0,
                  "influenced": 0
               }
            }
         ]
      }

   :json next_page: There might be more than one page of results for this
      report. Follow this URL if it is present to the next batch of results.

Response Listing
================

.. _GET-api-response-list:

.. http:get:: /api/reports/responses/list?start=(date)&end=(date)&limit=(results_per_page)

   Get a listing of all pushes, plus basic response information, in a given timeframe. Start and end date
   times are required parameters.

   **Example Request**:

   .. code-block:: http

      GET /api/reports/responses/list?start=2013-07-01T00:00:00.000Z&end=2013-08-01T00:00:00.000Z&limit=25 HTTP/1.1
      Authorization: Basic <master authorization string>


   :query start: Timestamp for start of report
   :query end: Timestamp for end of report
   :query limit: Number of results to return at one time (for pagination)
   :query push_id_start: Begin with this id

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8
      Data-Attribute: push_ids

      {
         "next_page": "/api/reports/..../?start=2013-07-01T00:00:00.000Z&end=2013-08-01T00:00:00.000Z&push_id_start=04911800-f48d-11e2-acc5-90e2ba027020&limit=25",
         "pushes": [
            {
            "push_uuid": "f133a7c8-d750-11e1-a6cf-e06995b6c872",
            "push_time": "2012-07-31 12:34:56",
            "push_type": "UNICAST_PUSH",
            "direct_responses": "10",
            "sends": "123",
            "group_id": "04911800-f48d-11e2-acc5-90e2bf027020"
            }
         ]
      }

   :json next_page: There might be more than one page of results for this
      report. Follow this URL if it is present to the next batch of results.
   :json push_type: Describes the push *operation*, which is often comparable to the audience
      selection, e.g., ``BROADCAST_PUSH``
   :json group_id: An identifier set by the server to logically group a set of related pushes, e.g., in a push to local time.


   :status 202 Accepted: The push notification has been accepted for processing
   :status 400 Bad Request: The request body was invalid, either due
                to malformed JSON or a data validation error.  See the
                response body for more detail.
   :status 401 Unauthorized: The authorization credentials are incorrect
   :status 406 Not Acceptable: The request could not be satisfied
                because the requested API version is not available.


App Opens Report
================

.. http:get:: /api/reports/opens/?start=(date)&end=(date)&precision=(precision)

   Get the number of users who have opened your app within the specified time period.

   **Example Request**:

   .. code-block:: http

      GET /api/reports/opens/?start=2012-05-05%2010:00&end=2012-05-15%2020:00&precision=HOURLY HTTP/1.1
      Authorization: Basic <master authorization string>

   :query start: Timestamp for start of report
   :query end: Timestamp for end of report
   :query precision: Granularity of results to return. Possible values:
      ``HOURLY``, ``DAILY``, ``MONTHLY``

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "opens": [
            {
               "android": 50,
               "date": "2012-12-01 00:00:00",
               "ios": 500
            }
         ],
         "next_page": "https://go.urbanairship.com/api/reports/..."
      }

   :json next_page: There might be more than one page of results for this
      report. Follow this URL if it is present to the next batch of results.

Time in App Report
==================

.. http:get:: /api/reports/timeinapp/?start=(date)&end=(date)&precision=(precision)

   Get the average amount of time users have spent in your app within the specified time period.

   **Example Request**:

   .. code-block:: http

      GET /api/reports/timeinapp/?start=2012-05-05%2010:00&end=2012-05-15%2020:00&precision=HOURLY HTTP/1.1
      Authorization: Basic <master authorization string>

   :query start: Timestamp for start of report
   :query end: Timestamp for end of report
   :query precision: Granularity of results to return. Possible values:
      ``HOURLY``, ``DAILY``, ``MONTHLY``

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "timeinapp": [
            {
               "android": 50,
               "date": "2012-12-01 00:00:00",
               "ios": 500
            }
         ],
         "next_page": "https://go.urbanairship.com/api/reports/..."
      }

   :json next_page: There might be more than one page of results for this
      report. Follow this URL if it is present to the next batch of results.

Opt-in Report
=============

.. http:get:: /api/reports/optins/?start=(date)&end=(date)&precision=(precision)

   Get the number of opted-in Push users who access the app within the specified time period.

   **Example Request**:

   .. code-block:: http

      GET /api/reports/optins/?start=2012-05-05%2010:00&end=2012-05-15%2020:00&precision=HOURLY HTTP/1.1
      Authorization: Basic <master authorization string>

   :query start: Timestamp for start of report
   :query end: Timestamp for end of report
   :query precision: Granularity of results to return. Possible values:
      ``HOURLY``, ``DAILY``, ``MONTHLY``

   **Example Response**

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json

      {
         "optins": [
            {
               "android": 50
               "date": "2012-12-01 00:00:00",
               "ios": 500
            }
         ],
         "next_page": "https://go.urbanairship.com/api/reports/..."
      }

   :json next_page: There might be more than one page of results for this
      report. Follow this URL if it is present to the next batch of results.


Opt-out Report
==============

.. http:get:: /api/reports/optouts/?start=(date)&end=(date)&precision=(precision)

   Get the number of opted-out Push users who access the app within the specified time period.

   **Example Request**:

   .. code-block:: http

      GET /api/reports/optouts/?start=2012-05-05%2010:00&end=2012-05-15%2020:00&precision=HOURLY HTTP/1.1
      Authorization: Basic <master authorization string>

   :query start: Timestamp for start of report
   :query end: Timestamp for end of report
   :query precision: Granularity of results to return. Possible values:
      ``HOURLY``, ``DAILY``, ``MONTHLY``

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "optouts": [
            {
               "android": 50
               "date": "2012-12-01 00:00:00",
               "ios": 500
            }
         ],
         "next_page": "https://go.urbanairship.com/api/reports/..."
      }

   :json next_page: There might be more than one page of results for this
      report. Follow this URL if it is present to the next batch of results.


.. _api-custom-events-detail-listing:

Custom Events Detail Listing
============================

.. http:get:: /api/reports/events?start=(date)&end=(date)&precision=(precision)&page=(int)&page_size=(int)

   Get a summary of custom event counts and values, by custom event, within the specified
   time period.

   **Example Request**:

   .. code-block:: http

      GET /api/reports/events?start=2012-05-05%2010:00&end=2012-05-15%2020:00&precision=HOURLY&page=3&page_size=20 HTTP/1.1
      Authorization: Basic <master authorization string>

   :query start: Timestamp for start of report
   :query end: Timestamp for end of report
   :query precision: Granularity of results to return. Possible values:
   :query page: (Optional) Identifies the desired page number. Defaults to ``1``. If
      ``page`` is given a negative or out of bounds value, the default value will be used.
   :query page_size: (Optional) Specifies how many results to return per page. Has a default
      value of ``25`` and a maximum value of ``100``.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8
      Link: https://go.urbanairship.com/api/reports/events...; rel="next"
      Link: https://go.urbanairship.com/api/reports/events...; rel="prev"

      {
         "events": [
            {
               "name": "custom_event_name",
               "location": "custom",
               "conversion": "direct",
               "count": 4,
               "value": 16.4
            },
            "..."
         ],
         "total_count": 12,
         "total_value": 321.2,
         "next_page": "https://go.urbanairship.com/api/reports/events...",
         "prev_page": "https://go.urbanairship.com/api/reports/events..."
      }

   :JSON Parameters:

      :events:

         - **name** – The name of the custom event.
         - **location** – The source from which the event originates, e.g. Message Center,
           Landing Page, custom, etc.
         - **conversion** – Can be one of ``direct`` or ``indirect``
         - **count** – Number of instances of this event.
         - **value** – The value generated by the event.

      - **total_count** – Sum of all the ``count`` fields in the above array.
      - **total_value** – Sum of all the ``value`` fields in the above array.


.. _api-custom-events-time-series-listing:

Custom Events Time Series Listing
=================================

.. http:get:: /api/reports/events/?start=(date)&end=(date)&precision=(precision)

   Get a summary of custom event counts and values over time. Aggregated across custom events.

   **Example Request**:

   .. code-block:: http

      GET /api/reports/events/?start=2012-05-05%2010:00&end=2012-05-15%2020:00&precision=HOURLY HTTP/1.1
      Authorization: Basic <master authorization string>

   :query start: Timestamp for start of report
   :query end: Timestamp for end of report
   :query precision: Granularity of results to return. Possible values:
      ``HOURLY``, ``DAILY``, ``MONTHLY``

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "events": [
            {
               "count": 25,
               "value": 330,
               "time": "2012-12-01 00:00:00",
               "conversion": "direct"
            },
            {
               "count": 50,
               "value": 660,
               "time": "2012-12-01 00:00:00",
               "conversion": "indirect"
            }
         ]
      }

   :JSON Parameters:

      :events:

         - **count** – The number of custom events at this timestamp.
         - **value** – The value generated by the custom events.
         - **time** – Current timestamp.
         - **conversion** – Can be one of ``"direct"`` or ``"indirect"``.


.. _statistics-api:

Statistics
==========

.. todo::

   Remove warning when PPDX-204 is resolved (pfd 10/6/2014)

.. warning::

   Requests to ``/api/push/stats/`` must be made **without** an ``Accept`` HTTP header that specifies an API
   version.

The statistics API is available for all applications.

.. http:get:: /api/push/stats/?start=(start_time)&end=(end_time)

   Return hourly counts for pushes sent for this application. Times are in UTC, and data is provided for each
   push platform. (Currently: iOS, Helium, BlackBerry, C2DM, GCM, Windows 8, and Windows
   Phone 8, in that order.)

   In addition to JSON, the data is also available in CSV for easy importing
   into spreadsheets.

   **Example Request**:

   .. code-block:: http

      GET /api/push/stats/?start=2009-06-22&end=2009-06-22+06:00&format=csv" HTTP/1.1
      Authorization: Basic <master authorization string>

   **Example Response**

   .. code-block:: http

      HTTP/1.1 Ok
      Content-Type: text/csv; charset=utf-8

      2009-06-22 00:00:00,0,0,0,0,0,0,0
      2009-06-22 01:00:00,0,0,4,0,0,0,0
      2009-06-22 02:00:00,0,0,2,0,0,0,0
      2009-06-22 03:00:00,0,0,1,0,0,0,0
      2009-06-22 04:00:00,8,0,0,0,0,0,0
      2009-06-22 05:00:00,1,0,0,0,0,0,0


.. _push-mappings:

Mappings
========

.. http:get:: /api/reports/mappings/send_ids/(send_id)

   The `send_ids` endpoint allows you to look up the particular push ID
   associated with a given push received on a device.

   **Example Request**:

   .. code-block:: http

      GET /api/reports/mappings/send_ids/5ciT0WadEeOjtAAbIc5Dvb HTTP/1.1
      Authorization: Basic <master authorization string>

   :param send_id: The send ID to use for lookup.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
        "send_id": "5ciT0WadEeOjtAAbIc5Dvb",
        "push_id": "17e6719c-af7f-41fe-bb50-06b33bc63a3e"
      }

   :status 200: A push ID to send ID mapping.
   :status 400 Bad request: `send_id` malformed and could not be decoded.
   :status 404 Not found: No push ID associated with the send ID.

.. http:get:: /api/reports/mappings/message_ids/(message_id)

   The `message_ids` endpoint takes a message ID from a rich message and
   returns the equivalent push ID. The endpoint does not guarantee that a rich
   message corresponding to the `message_id` actually exists. For details on
   the rich message ID, see :ref:`rich-push-message-id`.

   **Example Request**:

   .. code-block:: http

      GET /api/reports/mappings/message_ids/5KzYeYGKwEeOHhgCQ9dZz4g HTTP/1.1
      Authorization: Basic <master authorization string>

   :param message_id: The rich message ID to use for lookup.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
        "message_id": "KzYeYGKwEeOHhgCQ9dZz4g",
        "push_id": "2b361e60-62b0-11e3-8786-0090f5d673e2"
      }

   :statuscode 200: A push ID to message ID mapping.
   :status 400 Bad request: `message_id` malformed and could not be decoded.

.. _per-push-api-detail:

Per Push Reporting
==================

There are two endpoints for retrieving data specific to the performance of an individual push. One that
provides all the performance details at:

.. code-block:: text

  /api/reports/perpush/detail/(push_id)

and one that provides data for a time series at:

.. code-block:: text

  /api/reports/perpush/series/(push_id)

The Detail endpoint, if used with the ``GET`` method, requires no additional arguments. The endpoint can
also be used with the ``POST`` method to get information on a collection of push IDs. In the latter case,
you would omit the ``(push_id)`` and include a JSON array of push IDs. In either situation, you will receive
an object (or array of objects) containing the following information:

**Message Detail**

``app_key``
   unique identifier for your application, used to authenticate the application for API calls

``push_id``
   UUID that is returned in the response for the push

``created``
   time that the push was created

``push_body``
   push payload as a Base64 encoded string


**Engagement Activity**

``rich_deletions``
   if applicable, number of rich messages marked as deleted

``rich_responses``
   if applicable, unique number of rich messages marked as opened

``rich_sends``
   if applicable, number of rich notifications sent

``sends``
   total number of push notification sent

``direct_responses``
   app opens that are directly attributable to the push notification, i.e., user taps message or slides to view

``influenced_responses``
   combination of app opens that are both directly and indirectly attributable to the push notification.
   **Note**: Urban Airship will no longer count influenced responses once 12 hours have passed since the
   notification was sent.


**Platform-Specific Values**

Beneath the totals, platform-specific values are given for sends, direct responses and influenced responses.
Only iOS and Android are supported at this time. As a result, it's possible that the total values, which
include all platforms, will not match up with the sum of the platform-specific values if you are sending to
additional platforms.

.. warning::

   We do not support high levels of traffic to these endpoints. If your use
   case requires calling them for a very large number of push IDs, use an
   alternative listing endpoint that includes the relevant information instead.
   For example, to get push response information for a large number of push
   IDs, you should use the :ref:`Response Listing API <GET-api-response-list>`.


Per Push: Detail
----------------


Single Request
^^^^^^^^^^^^^^

.. http:get:: /api/reports/perpush/detail/(push_id)

   Get all the analytics detail for a specific push ID

   **Example Request**:

   .. code-block:: http

      GET /api/reports/perpush/detail/57ef3728-79dc-46b1-a6b9-20081e561f97 HTTP/1.1
      Authorization: Basic <authorization string>
      Accept: application/vnd.urbanairship+json; version=3;

   **Example response**

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset utf-8

      {
          "app_key": "some_app_key",
          "push_id": "57ef3728-79dc-46b1-a6b9-20081e561f97",
          "created": "2013-07-25 23:03:12",
          "push_body": "<Base64-encoded string>",
          "rich_deletions": 0,
          "rich_responses": 0,
          "rich_sends": 0,
          "sends": 58,
          "direct_responses": 0,
          "influenced_responses": 1,
          "platforms": {
              "android": {
                  "direct_responses": 0,
                  "influenced_responses": 0,
                  "sends": 22
              },
              "ios": {
                  "direct_responses": 0,
                  "influenced_responses": 1,
                  "sends": 36
              }
          }
      }

   :status 400 Bad request: The request is malformed, precision is not one of HOURLY, DAILY, or MONTHLY, start or end date doesn't parse (is not ISO 8601 or epoch millisecsonds).
   :status 401 Unauthorized: The authorization credentials are incorrect or missing.
   :status 403 Forbidden: Your account does not have access to this feature.
   :status 404 Not found: The push does not exist.


.. _api-per-push-batch:

Batch Request
^^^^^^^^^^^^^

.. http:post:: /api/reports/perpush/detail/

   Pass an array of individual Push IDs to the ``/reports/perpush/detail/`` endpoint for batch processing.
   Receive Push Reports for a number of device tokens, channels, or APIDs.

   Maximum 100 Push IDs per request.

   **Example Request**:

   .. code-block:: http

      POST /api/reports/perpush/detail/ HTTP/1.1
      Authorization: Basic <authorization string>
      Content-Type: application/json; charset=utf-8
      Accept: application/vnd.urbanairship+json; version=3;

      {
         "push_ids": [
            "8ecd82a9-982z-14da-39sg-uia90sa9",
            "8cj28vhw-734x-dj12-bbk0-08zii341"
         ]
      }

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      [
         {
            "app_key": "DLRssdsoQ231FEqu92z_43",
            "push_id": "8ecd82a9-982z-14da-39sg-uia90sa9",
            "created": 0,
            "push_body": "<Base64-encoded string>",
            "sends": 57356,
            "direct_responses": 2654,
            "influenced_responses": 8915,
            "rich_sends": 0,
            "rich_responses": 0,
            "rich_deletions": 0,
            "platforms": {
               "ios": {
                  "sends": 31522,
                  "direct_responses": 1632,
                  "influenced_responses": 5347
               },
               "android": {
                  "sends": 25834,
                  "direct_responses": 1022,
                  "influenced_responses": 3568
               }
            }
         },
         {
            "app_key": "DLRssdsoQ231FEqu92z_43",
            "push_id": "8cj28vhw-734x-dj12-bbk0-08zii341",
            "created": 0,
            "push_body": "<Base64-encoded string>",
            "sends": 68348,
            "direct_responses": 3492,
            "influenced_responses": 11376,
            "rich_sends": 0,
            "rich_responses": 0,
            "rich_deletions": 0,
            "platforms": {
               "ios": {
                  "sends": 39476,
                  "direct_responses": 1987,
                  "influenced_responses": 6754
               },
               "android": {
                  "sends": 28872,
                  "direct_responses": 1505,
                  "influenced_responses": 4622
               }
            }
         },
      ]

   :json push_ids: An array of individual ``push_id`` values


.. _per-push-api-series:

Per Push: Series
----------------

.. http:get:: /api/reports/perpush/series/(push_id)

   Get the default time series data: Hourly precision for 12 hours. The series begins with the hour in which
   the push was sent.

   **Example Request**:

   .. code-block:: http

      GET /api/reports/perpush/series/57ef3728-79dc-46b1-a6b9-20081e561f97 HTTP/1.1
      Authorization: Basic <authorization string>
      Accept: application/vnd.urbanairship+json; version=3;

   **Example response** (truncated to show only the first three items in array)

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
          "app_key": "some_app_key",
          "push_id": "57ef3728-79dc-46b1-a6b9-20081e561f97",
          "start": "2013-07-25 23:00:00",
          "end": "2013-07-26 11:00:00",
          "precision": "HOURLY",
          "counts": [
              {
                  "push_platforms": {
                      "all": {
                          "direct_responses": 0,
                          "influenced_responses": 1,
                          "sends": 58
                      },
                      "android": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 22
                      },
                      "ios": {
                          "direct_responses": 0,
                          "influenced_responses": 1,
                          "sends": 36
                      }
                  },
                  "rich_push_platforms": {
                      "all": {
                          "responses": 0,
                          "sends": 0
                      }
                  },
                  "time": "2013-07-25 23:00:00"
              },
              {
                  "push_platforms": {
                      "all": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 0
                      },
                      "android": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 0
                      },
                      "ios": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 0
                      }
                  },
                  "rich_push_platforms": {
                      "all": {
                          "responses": 0,
                          "sends": 0
                      }
                  },
                  "time": "2013-07-26 00:00:00"
              },
              {
                  "push_platforms": {
                      "all": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 0
                      },
                      "android": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 0
                      },
                      "ios": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 0
                      }
                  },
                  "rich_push_platforms": {
                      "all": {
                          "responses": 0,
                          "sends": 0
                      }
                  },
                  "time": "2013-07-26 01:00:00"
              },

   :status 400 Bad request: The request is malformed, precision is not one of HOURLY, DAILY, or MONTHLY, start or end date doesn't parse (is not ISO 8601 or epoch millisecsonds).
   :status 401 Unauthorized: The authorization credentials are incorrect or missing.
   :status 403 Forbidden: Your account does not have access to this feature.
   :status 404 Not found: The push does not exist.

.. _per-push-api-series-precision:

Per Push: Series with Precision
--------------------------------

.. http:get:: /api/reports/perpush/series/(push_id)?precision=(precision)

   Get the series data, specifying the precision as ``HOURLY``, ``DAILY``, or ``MONTHLY``. By specifying the precision without providing a time range, the default number of periods at each precision returned are as follows:
   Hourly: **12**
   Daily: **7**
   Monthly: **3**

   **Example Request**:

   .. code-block:: http

      GET /api/reports/perpush/series/57ef3728-79dc-46b1-a6b9-20081e561f97?precision=HOURLY HTTP/1.1
      Authorization: Basic <authorization string>
      Accept: application/vnd.urbanairship+json; version=3;

   **Example response** (truncated to show only the first three items in array)

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
          "app_key": "some_app_key",
          "push_id": "57ef3728-79dc-46b1-a6b9-20081e561f97",
          "start": "2013-07-25 23:00:00",
          "end": "2013-07-26 11:00:00",
          "precision": "HOURLY",
          "counts": [
              {
                  "push_platforms": {
                      "all": {
                          "direct_responses": 0,
                          "influenced_responses": 1,
                          "sends": 58
                      },
                      "android": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 22
                      },
                      "ios": {
                          "direct_responses": 0,
                          "influenced_responses": 1,
                          "sends": 36
                      }
                  },
                  "rich_push_platforms": {
                      "all": {
                          "responses": 0,
                          "sends": 0
                      }
                  },
                  "time": "2013-07-25 23:00:00"
              },
              {
                  "push_platforms": {
                      "all": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 0
                      },
                      "android": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 0
                      },
                      "ios": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 0
                      }
                  },
                  "rich_push_platforms": {
                      "all": {
                          "responses": 0,
                          "sends": 0
                      }
                  },
                  "time": "2013-07-26 00:00:00"
              },
              {
                  "push_platforms": {
                      "all": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 0
                      },
                      "android": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 0
                      },
                      "ios": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 0
                      }
                  },
                  "rich_push_platforms": {
                      "all": {
                          "responses": 0,
                          "sends": 0
                      }
                  },
                  "time": "2013-07-26 01:00:00"
              },

   :status 400 Bad request: The request is malformed, precision is not one of HOURLY, DAILY, or MONTHLY, start or end date doesn't parse (is not ISO 8601 or epoch millisecsonds).
   :status 401 Unauthorized: The authorization credentials are incorrect or missing.
   :status 403 Forbidden: Your account does not have access to this feature.
   :status 404 Not found: The push does not exist.

.. _per-push-api-series-precision-range:

Per Push: Series with Precision & Range
---------------------------------------

.. note::

   Results may be paginated if requesting hourly precision over a long period of time.

.. http:get:: /api/reports/perpush/series/(push_id)?precision=(precision)&start=(start_time)&end=(end_time)

   Get the series data and specify what type of precision and a time range

   **Example Request**:

   .. code-block:: http

      GET /api/reports/perpush/series/57ef3728-79dc-46b1-a6b9-20081e561f97?precision=DAILY&start=2013-07-25&end=2013-07-30 HTTP/1.1
      Authorization: Basic <authorization string>
      Accept: application/vnd.urbanairship+json; version=3;

   **Example response** (truncated to show only the first two items in array)

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
          "app_key": "some_app_key",
          "push_id": "57ef3728-79dc-46b1-a6b9-20081e561f97",
          "start": "2013-07-25 00:00:00",
          "end": "2013-07-30 00:00:00",
          "precision": "DAILY",
          "counts": [
              {
                  "push_platforms": {
                      "all": {
                          "direct_responses": 0,
                          "influenced_responses": 1,
                          "sends": 58
                      },
                      "android": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 22
                      },
                      "ios": {
                          "direct_responses": 0,
                          "influenced_responses": 1,
                          "sends": 36
                      }
                  },
                  "rich_push_platforms": {
                      "all": {
                          "responses": 0,
                          "sends": 0
                      }
                  },
                  "time": "2013-07-25 00:00:00"
              },
              {
                  "push_platforms": {
                      "all": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 0
                      },
                      "android": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 0
                      },
                      "ios": {
                          "direct_responses": 0,
                          "influenced_responses": 0,
                          "sends": 0
                      }
                  },
                  "rich_push_platforms": {
                      "all": {
                          "responses": 0,
                          "sends": 0
                      }
                  },
                  "time": "2013-07-26 00:00:00"
              },

   :status 400 Bad request: The request is malformed, precision is not one of HOURLY, DAILY, or MONTHLY, start or end date doesn't parse (is not ISO 8601 or epoch millisecsonds).
   :status 401 Unauthorized: The authorization credentials are incorrect or missing.
   :status 403 Forbidden: Your account does not have access to this feature.
   :status 404 Not found: The push does not exist.

.. }}}

.. {{{ Device Information

.. _device-information-api:

******************
Device Information
******************

.. note::

   If you are looking Channel information, please see the :ref:`api-channels` section.

The Device Information API can be queried for information on either a specific device identifier
or the full list of devices registered to your app.

Either type of request (:ref:`api-individual-device-lookup`, :ref:`api-device-listing`) will return a device
identifier object (or array of objects) containing data and metadata related to each identifier.


.. _api-device-identifier-objects:

Device Identifier Objects
=========================

Each device identifier has an associated JSON object, which contains data and metadata about the device.

.. _api-device-token-object:

Device Token Object
-------------------

.. code-block:: json

   {
      "device_token": "FE66489F304DC75B8D6E8200DFF8A456E8DAEACEC428B427E9518741C92C6660",
      "active": true,
      "alias": "your_user_id",
      "tags": [
         "tag1",
         "tag2"
      ],
      "created": "2013-08-08 20:41:06",
      "last_registration": "2014-05-01 18:00:27",
      "badge": 2,
      "quiettime": {
         "start": "22:00",
         "end": "8:00"
      },
      "tz": "America/Los_Angeles"
   }

:JSON Parameters:

   * | **device_token** – (String) The APNs identifier associated to this device
   * | **active** – (Boolean) Status of the device token. We do not push to inactive device tokens.
   * | **alias** – (String) Displays the alias associated with this device token, if one exists.
   * | **tags** – (Array of strings) A list of tags associated with this device token.
   * | **created** – (String) The creation date of this device token.
   * | **last_registration** – (String) Displays the last registration date of this device token, if it is known.
   * | **badge** – (Integer) Your app's current badge value on this device
   * | **quiettime** – (Object) :ref:`Quiet time specifications <int-quiet-time>`
   * | **tz** – (String) The timezone associated with this device.

.. _api-apid-object:

APID Object
-----------

.. code-block:: json

   {
      "apid": "11111111-1111-1111-1111-111111111111",
      "active": true,
      "alias": "",
      "tags": [
         "tag1",
         "tag2"
      ],
      "created": "2013-03-11 17:49:36",
      "last_registration": "2014-05-01 18:00:27",
      "gcm_registration_id": "your_gcm_reg_id"
   }

:JSON Parameters:

   * | **apid** – (String) The GCM identifier associated with this device.
   * | **active** – (Boolean) Status of the APID. We do not push to inactive APIDs.
   * | **alias** – (String) Displays the alias associated with this APID, if one exists.
   * | **tags** – (Array of strings) A list of tags associated with this APID.
   * | **created** – (String) The creation date of this APID.
   * | **last_registration** – (String) Displays the last registration date of this APID, if it is known.
   * | **gcm_registration_id** – (String) The GCM registration ID associated with your application.


.. _api-bb-pin-object:

BlackBerry PIN Object
---------------------

.. code-block:: json

   {
      "device_pin": "12345678",
      "active": true,
      "alias": "your_user_id",
      "tags": [
         "tag1",
         "tag2"
      ],
      "created": "2013-03-11 17:49:36",
      "last_registration": "2014-05-01 18:00:27"
   }

:JSON Parameters:

   * | **device_pin** – (String) The identifier associated to this BlackBerry device
   * | **active** – (Boolean) Status of the BlackBerry PIN. We do not push to inactive PINs.
   * | **alias** – (String) Displays the alias associated with this APID, if one exists.
   * | **tags** – (Array of strings) A list of tags associated with this PIN.
   * | **created** – (String) The creation date of this BlackBerry PIN.
   * | **last_registration** – (String) Displays the last registration date of this PIN, if it is known.


.. _api-individual-device-lookup:

Individual Device Lookup
========================

Get information about an individual device using its device token, APID, or PIN.


Device Token Lookup
-------------------

.. http:get:: /api/device_tokens/(device_token)

   Get information on a particular iOS :term:`device token`.

   .. note::

      For iOS devices, we recommend transitioning to *Channels* as your primary identifier. Channels
      are available today for iOS apps using at minimum the 4.0 version of the Urban Airship SDK. See
      :doc:`/topic-guides/channels` for more information.

   **Example Request**:

   .. code-block:: http

      GET /api/device_tokens/FE66489F304DC75B8D6E8200DFF8A456E8DAEACEC428B427E9518741C92C6660 HTTP/1.1
      Authorization: Basic <application authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "device_token": "FE66489F304DC75B8D6E8200DFF8A456E8DAEACEC428B427E9518741C92C6660",
         "active": true,
         "alias": "your_user_id",
         "tags": [
            "tag1",
            "tag2"
         ],
         "created": "2013-08-08 20:41:06",
         "last_registration": "2014-05-01 18:00:27",
         "badge": 2,
         "quiettime": {
            "start": "22:00",
            "end": "8:00"
         },
         "tz": "America/Los_Angeles"
      }

   :Return Value: A :ref:`api-device-token-object`.

APID Lookup
--------------

.. http:get:: /api/apids/(APID)

   Get information on a particular Android :term:`APID`.

   **Example Request**:

   .. code-block:: http

      GET /api/apids/11111111-1111-1111-1111-111111111111 HTTP/1.1
      Authorization: Basic <application authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "apid": "11111111-1111-1111-1111-111111111111",
         "active": true,
         "alias": "",
         "tags": [
            "tag1",
            "tag2"
         ],
         "created": "2013-03-11 17:49:36",
         "last_registration": "2014-05-01 18:00:27",
         "gcm_registration_id": "your_gcm_reg_id"
      }

   :Return Value: An :ref:`api-apid-object`.

PIN Lookup
----------

.. http:get:: /api/device_pins/(PIN)

   Get information on a particular BlackBerry :term:`PIN`.

   **Example Request**:

   .. code-block:: http

      GET /api/device_pins/12345678 HTTP/1.1
      Authorization: Basic <application authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "device_pin": "12345678",
         "active": true,
         "alias": "your_user_id",
         "tags": [
            "tag1",
            "tag2"
         ],
         "created": "2013-03-11 17:49:36",
         "last_registration": "2014-05-01 18:00:27"
      }

   :Return Value: A :ref:`api-bb-pin-object`.


.. _api-device-listing:

Device listing
==============

Fetch device identifiers and associated data and metadata.


Device Token Listing
--------------------

.. _device-token-list-api:

.. http:get:: /api/device_tokens/

   Fetch iOS device tokens registered to this application, along with associated data and metadata

   .. note::

      You may now encounter :term:`Channels <channel>` (e.g.,  "9c36e8c7-5a73-47c0-9716-99fd3d4197d5") in the
      next page URLs for this endpoint. This is expected behavior resulting from our back-end migration
      of device tokens to Channels as primary push identifiers. Calls to this endpoint should still work as
      expected as long as your code is dynamically getting to the next page based on the given URL.

   **Example Request**:

   .. code-block:: http

      GET /api/device_tokens/ HTTP/1.1
      Authorization: Basic <master authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "next_page": "https://go.urbanairship.com/api/device_tokens/?start=07AAFE44CD82C2F4E3FBAB8962A95B95F90A54857FB8532A155DE3510B481C13&limit=2",
         "device_tokens_count": 87,
         "device_tokens": [
            {
               "device_token": "0101F9929660BAD9FFF31A0B5FA32620FA988507DFFA52BD6C1C1F4783EDA2DB",
               "active": false,
               "alias": null,
               "tags": []
            },
            {
               "device_token": "07AAFE44CD82C2F4E3FBAB8962A95B95F90A54857FB8532A155DE3510B481C13",
               "active": true,
               "alias": null,
               "tags": ["tag1", "tag2"]
            }
         ],
         "active_device_tokens_count": 37
      }

   :json next_page: (String) There might be more than one page of results for this
      listing. Follow this URL if it is present to the next batch of results.
   :json device_tokens_count: (Integer) The full count of device tokens registered to this app, both active
      and inactive.
   :json device_tokens: (Array of objects) An array of :ref:`device token objects <api-device-token-object>`.
   :json active_device_tokens_count: (Integer) The number of active device tokens associated with this app.

Device Tokens Count
-------------------

.. _device-count-api:

.. http:get:: /api/device_tokens/count/

   Fetch count of iOS device tokens registered to this application.

   **Example Request**:

   .. code-block:: http

      GET /api/device_tokens/count/ HTTP/1.1
      Authorization: Basic <master authorization string>

   **Example Response**:

   .. code-block:: json

      {
        "active_device_tokens_count" : 100,
        "device_tokens_count" : 140
      }


APID Listing
------------

.. http:get:: /api/apids/

   Fetch Android APIDs registered to this application, along with associated metadata

   **Example Request**:

   .. code-block:: http

      GET /api/apids/ HTTP/1.1
      Authorization: Basic <master authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "next_page": "https://go.urbanairship.com/api/apids/?start=11111111-1111-1111-1111-111111111111&limit=2000",
         "apids": [
           {
               "c2dm_registration_id": null,
               "created": "2012-04-25 23:01:53",
               "tags": [],
               "apid": "00000000-0000-0000-0000-000000000000",
               "alias": null,
               "active": false
           },
           {
               "c2dm_registration_id": null,
               "created": "2013-01-25 00:55:06",
               "tags": [
                   "tag1"
               ],
               "apid": "11111111-1111-1111-1111-111111111111",
               "alias": "alias1",
               "active": true
           }
         ]
      }


   :json next_page: (String) There might be more than one page of results for this
      listing. Follow this URL if it is present to the next batch of results.
   :json apids: (Array of objects) An array of :ref:`APID objects <api-apid-object>`.


BlackBerry PIN Listing
----------------------

.. http:get:: /api/device_pins/

   Fetch BlackBerry PINs registered to this application, along with associated metadata

   **Example Request**:

   .. code-block:: http

      GET /api/device_pins/ HTTP/1.1
      Authorization: Basic <master authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "next_page": "https://go.urbanairship.com/api/device_pins/?start=31676e1e&limit=2",
         "device_pins": [
            {
               "device_pin": "21504591",
               "active": true,
               "alias": "adam",
               "tags": [
                  "tag1"
               ]
            },
            {
               "device_pin": "27a526e5",
               "active": true,
               "alias": null,
               "tags": [
                   "tag1",
                   "tag2"
               ]
            }
         ]
      }

   :json next_page: (String) There might be more than one page of results for this
      listing. Follow this URL if it is present to the next batch of results.
   :json device_pins: (Array of objects) An array of :ref:`BlackBerry PIN objects <api-bb-pin-object>`.


.. _feedback-api:

Feedback
========

.. http:get:: /api/device_tokens/feedback/?since=(timestamp)

   Apple informs us when a push notification is sent to a device that can't
   receive it because the application has been uninstalled. We mark the
   device token as inactive and immediately stop sending notifications to
   that device.

   The device token feedback listing API returns all device tokens marked inactive since the
   given timestamp. A device token can be marked as inactive in the Urban
   Airship system for one of three reasons:

   #. Apple's feedback service reports the device token, as above.
   #. The device token was rejected by APNS. See :ref:`Rejected device token
      <troubleshooting-ios-rejected>` in the troubleshooting guide for more
      information.

   .. note::

      Apple sends a timestamp for each device token
      returned via the feedback service. Since a device can be off the network
      for a while, this can be a point in the recent past. In order to make
      this API work smoothly for you, we record the timestamp we marked as
      inactive. This means you only need to query for data since the last time
      you queried. Once a day is a good timeframe, or once a week for very
      small or infrequently used applications. A few times a day is good for
      applications with heavy use.

   **Example Request**:

   .. code-block:: http

      GET /api/device_tokens/feedback/?since=2009-06-15 HTTP/1.1
      Authorization: Basic <master authorization string>

   :query since: Find device tokens deactivated since this date or timestamp.
      This value must be less than one month from the current date.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      [
         {
            "device_token": "1234123412341234123412341234123412341234123412341234123412341234",
            "marked_inactive_on": "2009-06-22 10:05:00",
            "alias": "bob"
         },
         {
            "device_token": "ABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCD",
            "marked_inactive_on": "2009-06-22 10:07:00",
            "alias": null
         }
      ]

   :json marked_inactive_on: Timestamp this token was marked inactive in our
      system.


.. http:get:: /api/apids/feedback/?since=(timestamp)

   Google informs us when a push notification is sent to a device that can't
   receive it because the application has been uninstalled. We mark the
   APID as inactive and immediately stop sending notifications to
   that device.


   .. note::

      You only need to query for data since the last time you queried. Once a
      day is a good timeframe, or once a week for very small or infrequently
      used applications. A few times a day is good for applications with heavy
      use.

   **Example Request**:

   .. code-block:: http

      GET /api/apids/feedback/?since=2009-06-15T10:10:00 HTTP/1.1
      Authorization: Basic <master authorization string>

   :query since: Find APIDs deactivated since this date or timestamp. This value
      must be less than one month from the current date.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      [
         {
            "apid": "00000000-0000-0000-0000-000000000000",
            "gcm_registration_id": null,
            "marked_inactive_on": "2009-06-22 10:05:00",
            "alias": "bob"
         },
         {
            "apid": "00000000-0000-0000-0000-000000000001",
            "gcm_registration_id": null,
            "marked_inactive_on": "2009-06-22 10:07:00",
            "alias": null
         }
      ]

   :json marked_inactive_on: Timestamp this APID was marked inactive in our
      system.

.. }}}

.. {{{ Device Registration

.. _device-registration-api:

************************
Device Registration APIs
************************

One of the primary duties of the Urban Airship mobile SDKs is to register device identifiers
with Urban Airship. Because this process is handled automatically by the SDK, there is no reason
to manually register device IDs with Urban Airship via our APIs, except in the following case:

#. You are sending notifications to the Blackberry platform, *for which UA does not support a mobile SDK*.

   We do not provide an SDK for Blackberry apps. See: :ref:`bb-registration` for details on registering
   Blackberry PINs with Urban Airship.

.. hiding this (pfd 1/29/15)

   .. note::

      Why use the registration call? We query Apple’s feedback service for
      you, marking any device tokens they tell us are inactive so you don’t
      accidentally send anything to them in the future. The registration call
      tells us that the device token is valid as of this time, so if a user
      re-installs your application they can receive them successfully again.

.. removing this from public view for now because no one should use it (pfd 1/29/15)

   .. _dt-registration:

   Device Token Registration
   =========================

   .. http:put:: /api/device_tokens/(device token)

      Register the device token with this application. This will mark the device
      token as active in our system. Optionally set metadata.

      .. warning::

         If you are using the iOS mobile client library, registration is handled
         for you. Calling this API from a server might interfere with metadata if
         set differently. Specifically, if you set an alias from the API but are
         using the library, the library will clear the alias upon registration.
         The same will occur with tags unless you set deviceTagsEnabled to NO in
         your client code.

      Simple registration can be done without a body.

      **Example Request**:

      .. code-block:: http

         PUT /api/device_tokens/FE66489F304DC75B8D6E8200DFF8A456E8DAEACEC428B427E9518741C92C6660 HTTP/1.1
         Authorization: Basic <application authorization string>

      :status 200: The device token registration has been accepted.

      **Full capability**:

      Optionally, an :term:`alias`, :term:`Quiet Time`, :term:`badge`, or
      :term:`tags <tag>` can be set in this request.

      .. code-block:: http

         PUT /api/device_tokens/FE66489F304DC75B8D6E8200DFF8A456E8DAEACEC428B427E9518741C92C6660 HTTP/1.1
         Authorization: Basic <application authorization string>
         Content-Type: application/json

         {
            "alias": "your_user_id",
            "tags": [
               "tag1",
               "tag2"
            ],
            "badge": 2,
            "quiettime": {
               "start": "22:00",
               "end": "8:00"
            },
            "tz": "America/Los_Angeles"
         }

      :json alias: An alias for this device token. If no alias is supplied, any
         existing alias will be removed from the device token record.
      :json tags: Zero or more tags for this device token. If the ``tags`` key is
         missing from the JSON body, tags will not be modified. To empty the tag
         set, send an empty array: ``[]``.
      :json badge: Value for the :term:`autobadge` system. If this is not present,
         the badge will be stored as ``0``.
      :json quiettime: A time range where alerts and sounds will not be sent, to
         avoid waking your user up. If not present, quiet time will be removed.
      :json tz: The time zone of the device, used to make quiet time work across
         daylight savings time and through traveling. This is required if
         ``quiettime`` is set.

      The ``quiettime`` object contains:

      ``start``
         When the quiet time begins as a string containing a time in 24 hour format. e.g., ``20:30``.
      ``end``
         When the quiet time ends as a string containing a time in 24 hour format. e.g., ``6:45``.

.. hiding dt-deactivation.

   .. http:delete:: /api/device_tokens/(device token)

      Deactivate the device token. Pushes will not be sent to inactive device tokens. A future
      registration will reactivate the device token.

      .. warning::

         If you are using the iOS mobile client library, deactivation is handled
         for you. Calling this API from a server will only deactivate the device
         token until the next time the library registers it.

      **Example Request**:

      .. code-block:: http

         DELETE /api/device_tokens/FE66489F304DC75B8D6E8200DFF8A456E8DAEACEC428B427E9518741C92C6660 HTTP/1.1
         Authorization: Basic <application authorization string>

      :status 204: The device token has been deactivated.

.. hiding API registration for now. No one should be doing this. (pfd 1/29/15)

   APID Registration
   =================

   .. http:put:: /api/apids/(apid)

      Register the APID and options with Urban Airship

         * **Prior to Android 5.0 SDK**: ``PushManager.shared().setDeviceTagsEnabled(false);``

         or

         * **Android SDK 5.0 or later**: ``UAirship.shared().getPushManager().setDeviceTagsEnabled(false);``

         Moreover, if you set an alias with the API but the client does not have an alias, the
         library will clear the alias upon device registration. If you do not include
         the client-side alias when you set tags via this API request, it will clear the alias
         in that case as well. Because of this, we do not recommend that you use the APID
         registration endpoint to set tags unless you are not using aliases at all in
         your implementation.

      **Example request**

      .. code-block:: http

         PUT /api/apids/11111111-1111-1111-1111-111111111111 HTTP/1.1
         Authorization: Basic <application authorization string>
         Content-Type: application/json

         {
            "alias": "example_alias",
            "tags": ["tag1", "tag2"]
         }

      :status 200: The APID registration has been accepted.

.. Note: APID DELETE example is not here by design. That action is handled by the library.

.. _bb-registration:

BlackBerry PIN Registration
===========================

.. http:put:: /api/device_pins/(pin)

   Register this :term:`PIN` with this application. This will mark the PIN as
   active in our system. Optionally set metadata.

   Simple registration can be done without a body.

   **Example Request**:

   .. code-block:: http

      PUT /api/device_pins/12345678 HTTP/1.1
      Authorization: Basic <application authorization string>

   :status 200: The device pin registration has been accepted.
   :status 201: The device pin registration has been accepted, and this device token has not been recorded for this app before.

   **Full capability**:

   Optionally, an :term:`alias` or :term:`tags <tag>` can be set in this
   request.

   .. code-block:: http

      PUT /api/device_pins/12345678 HTTP/1.1
      Authorization: Basic <application authorization string>
      Content-Type: application/json

   .. code-block:: json

      {
         "alias": "your_user_id",
         "tags": [
            "tag1",
            "tag2"
         ]
      }

   :json alias: An alias for this device token. If no alias is supplied, any
      existing alias will be removed from the device record.
   :json tags: Zero or more tags for this device token. If the ``tags`` key is
      missing from the JSON body, tags will not be modified. To empty the tag
      set, send an empty array: ``[]``.


Blackberry Pin Deactivation
===========================

.. http:delete:: /api/device_pins/(pin)

   Deactivate the PIN. Pushes will not be sent to inactive PINs. A future
   registration will reactivate the PIN.

   **Example Request**:

   .. code-block:: http

      DELETE /api/device_pins/12345678 HTTP/1.1
      Authorization: Basic <application authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 204 No Content

   :status 204: The device token has been deactivated.

.. _channel-uninstall:

Uninstall Channels
==================

.. http:post:: /api/channels/uninstall/

   Mark the given Channels as uninstalled; uninstalled channels do not receive
   push or rich app pages.

   .. note::

      Uninstallation is handled automatically by our SDK and push systems.
      If an end user opens their app after this API marks the device as
      "uninstalled", it will automatically be set as "active" and "installed"
      again. This API is only useful for very specific scenarios. Before
      using this API endpoint, it is recommended that you first contact
      Urban Airship Support or your Account Manager to discuss
      your plans and intended use of this API endpoint.

   **Example Request**:

   .. code-block:: http

      POST /api/channels/uninstall/ HTTP/1.1
      Authorization: Basic <master authorization string>
      Content-Type: application/json
      Accept: application/vnd.urbanairship+json; version=3;

      [
         {
            "channel_id": "00000000-0000-0000-0000-000000000000",
            "device_type": "ios"
         },
         {
            "channel_id": "00000000-0000-0000-0000-000000000001",
            "device_type": "ios"
         }
      ]

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 202 Accepted
      Content-Type: application/json; charset=utf-8

      {
         "ok": true
      }

.. }}}

.. {{{ Segments

.. _segments-api:

********
Segments
********

Segments are portions of your audience that have arbitrary metadata (e.g. tags, location data, etc) attached.
You can create, delete, update, or request information on a segment via the ``/api/segments/`` endpoint.
Pushing to a segment is done through the ``/api/push/`` endpoint (see the :ref:`Audience Selection
<audience-selectors>` section for more information).

Segment Listing
===============

.. http:get:: /api/segments/

   List all of the segments for the application.

   **Example Request**:

   .. code-block:: http

      GET /api/segments/ HTTP/1.1
      Authorization: Basic <master authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Link: <https://go.urbanairship.com/api/segments?limit=1&sort=id&order=asc&start=3832cf72-cb44-4132-a11f-eafb41b82f64>;rel=next
      Content-Type: application/json; charset=utf-8

      {
         "next_page": "https://go.urbanairship.com/api/segments?limit=1&sort=id&order=asc&start=3832cf72-cb44-4132-a11f-eafb41b82f64",
         "segments": [
            {
               "creation_date": 1346248822221,
               "display_name": "A segment",
               "id": "00c0d899-a595-4c66-9071-bc59374bbe6b",
               "modification_date": 1346248822221
            }
         ]
      }

   :responseheader link: A link to the next page of results. If present, follow
      this URL to the next page of segments. Also available in the
      ``next_page`` value in the response body.
   :json next_page: A link to the next page of results. If present, follow
      this URL to the next page of segments. Also available in the ``Link``
      header.


Individual Segment Lookup
=========================

.. http:get:: /api/segments/(segment_id)

   Fetch information about a particular segment.

   **Example Request**:

   .. code-block:: http

      GET /api/segments/00c0d899-a595-4c66-9071-bc59374bbe6b HTTP/1.1
      Authorization: Basic <master authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "criteria": {
            "and": [
               {
                  "tag": "ipad"
               },
               {
                  "not": {
                     "tag": "foo"
                  }
               }
            ]
         },
         "display_name": "A segment"
      }


Create Segment
==============

.. http:post:: /api/segments/

   Create a new segment.

   **Example Request**:

   .. code-block:: http

      POST /api/segments/ HTTP/1.1
      Authorization: Basic <master authorization string>
      Content-Type: application/json; charset=utf-8

      {
         "display_name": "News but not sports",
         "criteria": {
            "and": [
               {"tag": "news"},
               {"not":
                  {"tag": "sports"}
               }
            ]
         }
      }

   :json display_name: Human readable name for this segment. This will be
      used in the push composer.
   :json criteria: Audience selection criteria. See the
      :ref:`Segments documentation <segments-criteria>` for detailed
      description.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 201 Created

   :status 201: The segment was created.

.. tip::

   If you are interested in creating segments using both mobile and non-mobile data, read our
   :doc:`/topic-guides/mobile-data-bridge` and view the example :ref:`here <tg-mdb-quickstart-segment>`.

Update Segment
==============

.. http:put:: /api/segments/(segment_id)

   Change the definition of the segment.

   **Example Request**:

   .. code-block:: http

      PUT /api/segments/00c0d899-a595-4c66-9071-bc59374bbe6b HTTP/1.1
      Authorization: Basic <master authorization string>
      Content-Type: application/json; charset=utf-8

      {
         "display_name": "Entertainment but not sports",
         "criteria": {
            "and": [
               {"tag": "news"},
               {"not":
                  {"tag": "entertainment"}
               }
            ]
         }
      }

   :json display_name: Human readable name for this segment. This will be
      used in the push composer.
   :json criteria: Audience selection criteria. See the
      :ref:`Segments documentation <segments-criteria>` for detailed
      description.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 Ok

   :status 200: The segment was updated.


Delete Segment
==============

.. http:delete:: /api/segments/(segment_id)

   Remove the segment.

   **Example Request**:

   .. code-block:: http

      DELETE /api/segments/00c0d899-a595-4c66-9071-bc59374bbe6b HTTP/1.1
      Authorization: Basic <master authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 204 No Content

   :status 204: The segment has been deleted.

Segments Push
=============

The Push APIs have been significantly updated in :doc:`API
v3 </api/index>`, and they now have the ability to push to
segments. See :ref:`Push API v3 <push-api>` and
:doc:`/api/api-v3-migration-guide` for more information.

.. }}}

.. {{{ Location

.. _location-api:

********
Location
********

Location Boundary Information
=============================


.. _api-location-name-lookup:

Name Lookup
-----------

.. http:get:: /api/location/?q=(query)&type=(boundary_type)

   Search for a location boundary by name. The search
   primarily uses the location names, but you can also filter the results
   by :ref:`boundary type <location-boundary-type>`. For a full reference, please
   see our :doc:`/reference/location_boundary_catalog`. Because there are
   over 2.5M location boundaries available in
   Segments, we recommend you provide a type parameter along with your
   search to increase the chance you find the polygon you're looking for.
   If you are not getting satisfactory results with searching for a
   location by name, you may want to consider using "Search for location by
   latitude and longitude" or "Search for location by bounding box" below.

   .. note::

      Due to contractual obligations we do not return proprietary datasets such
      as Maponics Neighborhood Boundaries or Nielsen DMA© in this endpoint.
      You can, however, search for those locations using the web interface.

   **Example Request**:

   .. code-block:: http

      GET /api/location/?q=San%20Francisco&type=city HTTP/1.1
      Authorization: Basic <master authorization string>

   :query q: Text search query.
   :query type: Optional location type, e.g. ``city``, ``province``,
      or ``country``.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "features": [
            {
               "bounds": [
                  37.63983,
                  -123.173825,
                  37.929824,
                  -122.28178
               ],
               "centroid": [
                  37.759715,
                  -122.693976
               ],
               "id": "4oFkxX7RcUdirjtaenEQIV",
               "properties": {
                  "boundary_type": "city",
                  "boundary_type_string": "City/Place",
                  "context": {
                     "us_state": "CA",
                     "us_state_name": "California"
                  },
                  "name": "San Francisco",
                  "source": "tiger.census.gov"
               },
               "type": "Feature"
            }
         ]
      }

   :json features: :term:`GeoJSON features <GeoJSON>` that match the query.


.. _api-location-lat-long-lookup:

Lat/Long Lookup
---------------

.. http:get:: /api/location/(latitude),(longitude)?type=(boundary_type)

   Search for a location by latitude and longitude. For example, if you have (latitude: 37.7749295,
   longitude: -122.4194155), you could systematically convert those coordinates to the surrounding city
   (San Francisco) or the surrounding ZIP code (94103).

   **Example Request**:

   .. code-block:: http

      GET /api/location/37.7749295,-122.4194155?type=city HTTP/1.1
      Authorization: Basic <master authorization string>

   :query type: Optional location type, e.g. ``city``, ``province``,
      or ``country``.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "features": [
            {
               "bounds": [
                  37.63983,
                  -123.173825,
                  37.929824,
                  -122.28178
               ],
               "centroid": [
                  37.759715,
                  -122.693976
               ],
               "id": "4oFkxX7RcUdirjtaenEQIV",
               "properties": {
                  "boundary_type": "city",
                  "boundary_type_string": "City/Place",
                  "context": {
                     "us_state": "CA",
                     "us_state_name": "California"
                  },
                  "name": "San Francisco",
                  "source": "tiger.census.gov"
               },
               "type": "Feature"
            }
         ]
      }

   :json features: :term:`GeoJSON features <GeoJSON>` that match the query.

.. _api-location-bounding-box-lookup:

Bounding Box Lookup
-------------------

.. http:get:: /api/location/(latitude_1),(longitude_1),(latitude_2),(longitude_2)&type=(boundary_type)

   Search for locations using a bounding box. A bounding box is a rectangle
   that covers part of the earth. For example, you could say "give me all the
   ZIP codes in this area". This may be useful if you want to create Segments
   that cover multiple locations nearby a certain area.

   **Example Request**:

   .. code-block:: http

      GET /api/location/37.805172690644405,-122.44863510131836,37.77654930110633,-122.39404678344727?type=postalcode HTTP/1.1
      Authorization: Basic <master authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "features": [
            {
               "bounds": [
                  37.758749999999999,
                  -122.477411,
                  37.778851000000003,
                  -122.428426
               ],
               "centroid": [
                  37.769751999999997,
                  -122.448239
               ],
               "id": "191QgPcnG1Um9MW06h1fa6",
               "properties": {
                  "aliases": {
                     "us_zip": "94117"
                  },
                  "boundary_type": "postalcode",
                  "boundary_type_string": "Postal/ZIP Code",
                  "name": "94117",
                  "source": "tiger.census.gov"
               },
               "type": "Feature"
            },
         ]
      }

.. _api-location-alias-lookup:

Alias Lookup
------------

.. http:get:: /api/location/from-alias?(query)

   Look up location boundary information based on real-world references.

   **Example Request**:

   .. code-block:: http

      GET /api/location/from-alias?us_state=CA HTTP/1.1
      Authorization: Basic <master authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "bounds": [
            32.528832,
            -124.482003,
            42.009517,
            -114.131211
         ],
         "centroid": [
            37.215297,
            -119.663837
         ],
         "id": "5LajTWicgiQKuX1RBBLDRI",
         "properties": {
            "abbr": "CA",
            "aliases": {
               "fips_10-4": "US06",
               "hasc": "US.CA",
               "state": "US06",
               "us_state": "CA"
            },
            "boundary_type": "province",
            "boundary_type_string": "State/Province",
            "name": "California",
            "source": "tiger.census.gov"
         },
         "type": "Feature"
      }

   Multiple queries may be passed in one API call:

   .. code-block:: http

      GET /api/location/from-alias?us_state=CA&us_state=OR&us_state=WA HTTP/1.1
      Authorization: Basic <master authorization string>

Polygon Lookup
--------------

   .. note::

      Due to contractual obligations we do not return proprietary datasets such
      as Maponics Neighborhood Boundaries or Nielsen DMA© in this endpoint.
      You can, however, search for those locations using the web interface.

.. http:get:: /api/location/(polygon ID)?zoom=(zoom level)

   Use this call to query polygons for which you already know the ID, for information such as
   context, boundary type, centroid, bounds, and its geometry.

   The zoom level determines the level of detail of the coordinates (higher numbers are zoomed out farther,
   so they include fewer coordinates/the shape is simplified).

   Valid range for zoom level is 1 (least detailed) through 20 (most detailed).

   The polygon ID is what is returned from other location API lookup calls, and is the unique identifier for
   that polygon.

   **Example Request**:

   .. code-block:: http

      GET /api/location/1H4pYjuEW0xuBurl3aaFZS?zoom=1 HTTP/1.1
      Authorization: Basic <master authorization string>

   **Example response** (*Coordinates listing truncated*):

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      {
         "type": "Feature",
         "id": "1H4pYjuEW0xuBurl3aaFZS",
         "properties": {
            "source": "tiger.census.gov",
            "boundary_type_string": "City/Place",
            "name": "Portland",
            "context": {
               "us_state_name": "Oregon",
               "us_state": "OR"
            },
            "boundary_type": "city"
         },
         "bounds": [
            45.432393,
            -122.83675,
            45.653272,
            -122.472021
         ],
         "centroid": [
            45.537179,
            -122.650037
         ],
         "geometry": {
            "coordinates": [
               [
                  [
                     [
                        -122.586136,
                         45.462439
                     ],
                     [
                        "..."
                     ]
                  ]
               ]
            ],
             "type": "MultiPolygon"
         }
      }

Location Date Ranges
====================

The historical part of location is subject to some generous restraints.
For example, you can't use per-hour granularity for locations from 8
weeks ago, but you can do per-day granularity for locations from 8
weeks ago.  This endpoint retrieves the possible date range bucket
types that can be used for date ranges with location predicates and the
cutoff date for history available for each range.  This defines what
time ranges are legal in location predicates.  For example, 8 weeks =
1344 hours.  You cannot say "was in ZIP code 94123 in the
past 1344 hours", but you can say "was in ZIP code 94123 in the past
56 days".

You can query based on the following time ranges:

-  By hour for the past 48 hours
-  By day for the past 60 days
-  By week for the past 10 weeks
-  By month for the past 48 months
-  By year for the past 10 years

.. http:get:: /api/segments/dates/

   Retrieve cutoff dates for each time granularity.

   **Example request**

   .. code-block:: http

      GET /api/segments/dates/ HTTP/1.1
      Authorization: Basic <master authorization string>

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json; charset=utf-8

      [
         {
            "unit": "hours",
            "cutoff": "2012-07-09 15"
         },
         {
            "unit": "days",
            "cutoff": "2012-05-12"
         },
         {
            "unit": "weeks",
            "cutoff": "2012-W18"
         },
         {
            "unit": "months",
            "cutoff": "2008-07"
         },
         {
            "unit": "years",
            "cutoff": "2002"
         }
      ]

.. }}}

.. {{{ Named Users

.. _api-named-users:

***********
Named Users
***********

A *Named User* is a new, proprietary identifier that maps customer-chosen IDs, e.g., CRM data, to
*Channels*.

It is useful to think of a Named User as an individual consumer who might have more than one mobile device
registered with your app. For example, Named User "john_doe_123" might have a personal Android phone
and an iPad, on both of which he has opted in for push notifications. If you want to reach John on both
devices, associate the Channel (device) identifiers for each device to the Named User "john_doe_123," and
push to the Named User. Notifications will then fan out to each associated device.

You can use Named Users to:

* Send messages
* Manage tags
* Query status

without needing to store the mapping of users to channels in a separate database. Urban Airship maintains the
mapping as soon as the Named User record is created.

A Named User may be associated with multiple Channels, but a channel may only be associated to one
Named User.

**Example**:

.. code-block:: text

   If a channel has an assigned named user and you make an additional
   call to associate that same channel with a new named user, the
   original named user association will be removed and the new named user
   and associated data will take its place.  Additionally, all tags
   associated to the original named user cannot be used to address this
   channel unless they are also associated with the new named user.


.. _api-named-user-object:

The Named User Object
=====================

The Named User Object lists tags that are associated with the Named User and the
array of associated :ref:`Channel Objects <api-channel-object>`.

.. code-block:: json

   {
      "named_user_id": "user-id-1234",
      "tags": {
         "crm": ["tag1", "tag2"]
      },
      "channels": [
         {
            "channel_id": "ABCD",
            "device_type": "ios",
            "installed": true,
            "opt_in": true,
            "push_address": "FFFF",

            "created": "2013-08-08T20:41:06",
            "last_registration": "2014-05-01T18:00:27",

            "alias": "xxxx",
            "ios": {
               "badge": 0,
               "quiettime": {
                  "start": "22:00",
                  "end": "06:00"
               },
               "tz": "America/Los_Angeles"
            }
         }
      ]
   }

:JSON Parameters:

   * | **named_user_id** – (String) An identifier chosen by the customer to represent a user. The
       ``named_user_id`` cannot contain leading or trailing whitespace and must be between 1 and 128
       characters.
   * | **tags** – (Object) Contains a series of ``<tag_group>: [tag_1,...,tag_n]`` key value pairs.
   * | **channels** – (Array of Objects) An array of :ref:`channel objects <api-channel-object>`.


.. _api-named-user-association:

Association
===========

.. http:post:: /api/named_users/associate

   Associate a channel to a named user ID. Called after a succesful login inside a mobile application.

   .. warning::

      **You may only associate up to 20 Channels to a Named User**. This limit is in place to prevent Urban Airship
      customers from using Named Users to function like Tags. It is highly unlikely that any one individual
      would have more than 20 devices registered with your app for notifications, so you should never
      encounter this limit. Please contact Support with questions.

   **Example Request**:

   .. code-block:: http

      POST /api/named_users/associate HTTP/1.1
      Authorization: Basic <application or master authorization string>
      Accept: application/vnd.urbanairship+json; version=3;
      Content-type: application/json

      {
         "channel_id": "df6a6b50-9843-0304-d5a5-743f246a4946",
         "device_type": "ios",
         "named_user_id": "user-id-1234"
      }

   :json channel_id: (Required) The ``channel_id`` you would like to associate to a named user.
   :json device_type: (Required) The device type of the channel (iOS, Android, or Amazon).
   :json named_user_id: (Required) The id a user would like to give to the ``named_user``.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 Ok
      Content-Type: application/json

      {
         "ok": true
      }


Disassociation
==============

.. http:post:: /api/named_users/disassociate

   Disassociate a channel from a named user ID, if an association exists. Called after an explicit logout inside
   a mobile application.

   **Example Request**:

   .. code-block:: http

      POST /api/named_users/disassociate HTTP/1.1
      Authorization: Basic <application or master authorization string>
      Accept: application/vnd.urbanairship+json; version=3;
      Content-type: application/json

      {
         "channel_id": "df6a6b50-9843-0304-d5a5-743f246a4946",
         "device_type": "ios",
         "named_user_id": "user-id-1234"
      }

   :json channel_id: (Required) The ``channel_id`` you would like to disassociate from a named user.
   :json device_type: (Required) The device type of the channel.
   :json named_user_id: (Optional) The existing named user ID association. Because channels can only have
      one named user association, this parameter is optional.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 Ok
      Content-Type: application/json

      {
         "ok": true
      }


.. _api-named-users-lookup:

Lookup
======

.. http:get:: /api/named_users/?id=(named_user_id)

   Look up a single named user.

   **Example Request**:

   .. code-block:: http

      GET /api/named_users/?id=(named_user_id) HTTP/1.1
      Authorization: Basic <master authorization string>
      Accept: application/vnd.urbanairship+json; version=3;

   :query id: (Required)  The named user id.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 Ok
      Content-type: application/json
      Data-Attribute: named_users
      Link: <https://go.urbanairship.com/api/named_users?start=user-1234>; rel=next

      {
         "ok": true,
         "named_user": {
            "named_user_id": "user-id-1234",
            "tags": {
               "crm": ["tag1", "tag2"]
            },
            "channels": [
               {
                  "channel_id": "ABCD",
                  "device_type": "ios",
                  "installed": true,
                  "opt_in": true,
                  "push_address": "FFFF",

                  "created": "2013-08-08T20:41:06",
                  "last_registration": "2014-05-01T18:00:27",

                  "alias": "xxxx",
                  "ios": {
                     "badge": 0,
                     "quiettime": {
                        "start": "22:00",
                        "end": "06:00"
                     },
                     "tz": "America/Los_Angeles"
                  }
               }
            ]
         }
      }

   :Return Value: A :ref:`named user object <api-named-user-object>`


.. _api-named-users-listing:

Listing
=======

.. http:get:: /api/named_users

   Get a paginated list of all named users.

   **Example Request**:

   .. code-block:: http

      GET /api/named_users/ HTTP/1.1
      Authorization: Basic <master authorization string>
      Accept: application/vnd.urbanairship+json; version=3;

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 Ok
      Content-type: application/json
      Data-Attribute: named_users
      Link: <https://go.urbanairship.com/api/named_users?start=user-1234>; rel=next

      {
         "next_page": "https://go.urbanairship.com/api/named_users?start=user-1234",
         "named_users": [
            {
               "named_user_id": "user-id-1234",
               "tags": {
                  "crm": ["tag1", "tag2"]
               },
               "channels": [
                  {
                     "channel_id": "ABCD",
                     "device_type": "ios",
                     "installed": true,
                     "opt_in": true,
                     "push_address": "FFFF",

                     "created": "2013-08-08T20:41:06",
                     "last_registration": "2014-05-01T18:00:27",

                     "alias": "xxxx",
                     "tags": ["asdf"],

                     "ios": {
                        "badge": 0,
                        "quiettime": {
                           "start": "22:00",
                           "end": "06:00"
                        },
                        "tz": "America/Los_Angeles"
                     }
                  }
               ]
            }
         ]
      }

   :Return Value:

      * | **next_page** - A continuation of the current results.
      * | **named_users** - An array of :ref:`named user objects <api-named-user-object>`.



.. Counts
   ======

   .. http:get:: /api/named_users/count

      Retrieve the number of named users registered to an app. Testing of large audiences show an error of
      ~1%, so the counts above 1000 will be rounded to reflect the 1% innacuracy.

      **Example Request**:

      .. code-block:: http

         GET /api/named_users/count HTTP/1.1
         Authorization: Basic <master authorization string>
         Accept: application/vnd.urbanairship+json; version=3;

      **Example Response**:

      .. code-block:: http

         HTTP/1.1 200 Ok
         Content-type: application/json

         {
            "ok": true,
            "count": 109
         }

      :Return Value:

         * | **count** - The number of named users registered to an app.

Tags
====

\

See: :ref:`api-named-users-tags`

.. }}}

.. {{{ Static List API

.. _api-static-lists:

************
Static Lists
************

With the *Static List* API endpoint, you can easily target and manage lists of devices that are defined in your systems outside of Urban Airship. Any list or grouping of devices for which the canonical source of data about the members
is *elsewhere* is a good candidate for Static Lists, e.g., members of a
customer loyalty program.

Getting started with Static Lists is easy. Simply:

#. Create your list in the Urban Airship system
#. Populate, update, view, delete lists
#. Push to lists using :ref:`audience-selectors`

Read below for the Static List API reference and see our :doc:`Static List
API Topic Guide </topic-guides/static-lists-api>` for further use-cases and examples.


.. _api-list-object:

The List Object
===============

The list object contains eight attributes:

.. code-block:: json

   {
      "ok": true,
      "name": "platinum_members",
      "description": "loyalty program platinum members",
      "extra": { "key": "value" },
      "created": "2013-08-08T20:41:06",
      "last_updated": "2014-05-01T18:00:27",
      "channel_count": 1000,
      "status": "ready"
   }


:JSON Parameters:

   * | **ok** – (Bool)
   * |  **name** – (String) The user-provided name of the list. Maximum length of 64 characters
   * | **description** – (String) An optional user-provided description of the list. Maximum length of
       1000 characters
   * | **extra** – (Object) An optional user-provided JSON map of string values associated with a list.
       A key has a maximum length of 64 characters, while a value can be up to 1024 characters. You may
       add up to 100 key-value pairs.
   * | **created** – (String) The time the list was initially created, in UTC Timestamp form
   * | **last_updated** – (String) The time the identifiers of the list were last updated successfully, in
       UTC timestamp form
   * | **channel_count** – (Int) A count of resolved channel identifiers for the last uploaded and successfully
       processed identifier list.
   * | **status** – (String) One of ``"ready"``, ``"processing"``, or ``"failure"``:

      *  ``"ready"`` - The list was processed successfully and ready for sending
      *  ``"processing"`` - The list is being processed
      *  ``"failure"`` - There was an error processing the last uploaded list


.. _api-lifecycle-list-names:

Lifecycle List Names
--------------------

.. TODO: add uninstalls info

Aside from uploading custom lists, you can send to one of Urban Airship's built-in Lifecycle Lists.

.. note::

   Before using Lifecycle Lists, you must activate them through the Dashboard. See the :ref:`User Guide
   documentation <ug-lifecycle-lists>` for more information.

The table below details the various Lifecycle Lists and the names used to refer to them within the API:

================= ============= =======================================
List Type         Time Interval List API Name
================= ============= =======================================
First App Open    Last 7 days   ``ua_first_app_open_last_7_days``
First App Open    Last 30 days  ``ua_first_app_open_last_30_days``
Opened App        Yesterday     ``ua_app_open_last_1_day``
Opened App        Last 7 days   ``ua_app_open_last_7_days``
Opened App        Last 30 days  ``ua_app_open_last_30_days``
Sent Notification Yesterday     ``ua_message_sent_last_1_day``
Sent Notification Last 7 days   ``ua_message_sent_last_7_days``
Sent Notification Last 30 days  ``ua_message_sent_last_30_days``
Direct Open       Yesterday     ``ua_direct_open_last_1_day``
Direct Open       Last 7 days   ``ua_direct_open_last_7_days``
Direct Open       Last 30 days  ``ua_direct_open_last_30_days``
Dormant           Yesterday     ``ua_has_not_opened_last_1_day``
Dormant           Last 7 days   ``ua_has_not_opened_last_7_days``
Dormant           Last 30 days  ``ua_has_not_opened_last_30_days``
Uninstalls        Yesterday     ``ua_uninstalls_last_1_day``
Uninstalls        Last 7 days   ``ua_uninstalls_last_7_days``
Rich Page Sent    Last 7 days   ``ua_message_center_sent_last_7_days``
Rich Page Sent    Last 30 days  ``ua_message_center_sent_last_30_days``
Rich Page View    Last 7 days   ``ua_message_center_view_last_7_days``
Rich Page View    Last 30 days  ``ua_message_center_view_last_30_days``
================= ============= =======================================


.. _api-create-list:

Create List
===========

.. http:post:: /api/lists/

   Create a static list. The body of the request will contain several of the :ref:`list object
   <api-list-object>` parameters, but the actual list content will be provided by a second call
   to the :ref:`upload endpoint <api-list-upload>`.

   **Example Request**:

   .. code-block:: http

      POST /api/lists/ HTTP/1.1
      Authorization: Basic <application authorization string>
      Accept: application/vnd.urbanairship+json; version=3;
      Content-Type: application/json

      {
         "name" : "platinum_members",
         "description" : "loyalty program platinum members",
         "extra" : {
            "key" : "value"
         }
      }

   :json name: (Required) User-provided name of the list, consists of up to 64 URL-safe characters.
   :json description: (Optional) User-provided description of the list.
   :json extra: (Optional) A dictionary of string keys to arbitrary JSON values.

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json
      Location: https://go.urbanairship.com/api/lists/platinum_members

      {
         "ok" : true
      }


.. _api-list-upload:

Upload List
===========

.. http:put:: /api/lists/(name)/csv

   List target identifiers are specified or replaced with an upload to this endpoint. Uploads must be
   newline delimited identifiers (text/CSV) as described in `RFC 4180 <https://tools.ietf.org/html/rfc4180>`_,
   with commas as the delimiter. The CSV format is two columns, ``identifier_type,identifier``:

   - **identifier_type**: must be one of ``alias``, ``named_user``, ``ios_channel``, ``android_channel``, or
     ``amazon_channel``
   - **identifier**: the associated identifier you wish to send to

   The maximum number of ``identifier_type,identifier`` pairs that may be uploaded to a list is 10 million.

   .. note::

      "Content-Encoding: gzip" is supported (and recommended) on this endpoint to reduce network traffic.

   **Example request**:

   .. code-block:: http

      PUT /api/lists/platinum_members/csv HTTP/1.1
      Authorization: Basic <application authorization string>
      Accept: application/vnd.urbanairship+json; version=3;
      Content-Type: text/csv

      alias,stevenh
      alias,marianb
      ios_channel,5i4c91s5-9tg2-k5zc-m592150z5634
      named_user,SDo09sczvJkoiu
      named_user,"gates,bill"


   **Example response**:

   .. code-block:: http

      HTTP/1.1 202 Accepted
      Content-Type: application/json

      {
         "ok" : true,
      }

   :Status Codes:

      * | **202 Accepted** – The list was uploaded successfully, and is now being processed.
      * | **400 Bad Request** – This could mean one of several things, depending on the error code:

          * **error_code 40002**: CSV contains too many identifiers.
          * **error_code 40003**: CSV contains an entry with a column count other than 2.
          * **error_code 40004**: CSV contains an invalid ``identifier_type``.
          * **error_code 40005**: CSV contains a channel identifier that is not a valid UUID

      * | **404 Not Found** – No list with the given name exists.

.. warning::

   If an attempt to upload a list times out due to a poor connection, you must re-upload the list from
   scratch. Because we want to ensure that the entirety of a given list is successfully uploaded, we do not support
   partial list uploads.


Update List
===========

.. note::

   If you are trying to update the list contents, please see the :ref:`list upload <api-list-upload>`
   endpoint. The ``update`` endpoint is used to update a list's metadata rather than the actual
   list of device identifiers.

.. http:put:: /api/lists/(name)

   Update the metadata of a static list. The body of the request will contain a :ref:`list
   object <api-list-object>`, though the ``name`` attribute could be omitted. If present, it must match the
   ``name`` provided in the URL.

   The following example updates the ``platinum_members`` list's metadata:

   **Example Request (Update list metadata)**:

   .. code-block:: http

      PUT /api/lists/platinum_members HTTP/1.1
      Authorization: Basic <application authorization string>
      Accept: application/vnd.urbanairship+json; version=3;
      Content-Type: application/json

      {
         "name" : "platinum_members",
         "description" : "loyalty program platinum members",
         "extra" : {
            "key" : "value"
         }
      }

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json

      {
         "ok" : true
      }

   :Status Codes:

      * | **200 Created** – The list metadata was updated successfully.
      * | **400 Bad Request** – Malformed JSON payload.
      * | **400 Bad Request (error_code 40001)** – Attempted list rename. List renaming is not allowed.
      * | **404 Not Found** – No list with the given name exists.


.. todo:: Comment out for now, not sure if this is a thing

..      You can also directly edit the list of identifiers contained in a list by including the ``list`` attribute:

      **Example Request (Update list content)**:

      .. code-block:: http

         PUT /api/lists/foobar HTTP/1.1
         Authorization: Basic <application authorization string>
         Accept: application/vnd.urbanairship+json; version=3;
         Content-Type: application/json

         {
            "name" : "foobar",
            "list" : [
               "uuid1",
               "uuid2"
            ],
            "data_type" : "channel"
         }

      :json list: (Optional) An array of device ID's, replaces the current list of identifiers associated with
                  the list.

      **Example response**:

      .. code-block:: http

         HTTP/1.1 200 OK
         Content-Type: application/json

         {
            "ok" : "true"
         }


Lookup List
===========


Single List
-----------

.. http:get:: /api/lists/(name)

   Retrieve information about one static list, specified in the URL.

   **Example Request**:

   .. code-block:: http

      GET /api/lists/platinum_members/ HTTP/1.1
      Authorization: Basic <master authorization string>
      Accept: application/vnd.urbanairship+json; version=3;


   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json
      Data-Attribute: static_list
      Link: <https://go.urbanairship.com/api/platinum_members/list/?start=uuid101&limit=100>; rel=next

      {
         "ok" : true,
         "name" : "platinum_members",
         "description" : "loyalty program platinum members",
         "extra" : { "key" : "value" },
         "created" : "2013-08-08T20:41:06",
         "last_updated" : "2014-05-01T18:00:27",
         "channel_count" : 1000,
         "status" : "ready"
      }

   :Return Value:

      - A :ref:`list object <api-list-object>`

.. warning::

   When looking up lists, the returned information may actually be a combination of values from both the last uploaded list
   and the last successfully processed list. If you create a list successfully, and then you update it and the processing
   step fails, then the list ``status`` will read ``"failed"``, but the ``channel_count`` and ``last_modified`` fields will
   contain information on the last successfully processed list.


All Lists
---------

.. http:get:: /api/lists?start=(start of listing)&limit=(max number of elements)

   Retrieve information about all static lists. This call returns a paginated list of metadata that will
   not contain the actual lists of users.

   **Example Request**:

   .. code-block:: http

      GET /api/lists HTTP/1.1
      Authorization: Basic <master authorization string>
      Accept: application/vnd.urbanairship+json; version=3;
      Content-type: application/json

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 200 OK
      Content-Type: application/json
      Data-Attribute: lists

      {
         "ok" : true,
         "lists" : [
            {
               "name" : "platinum_members",
               "description" : "loyalty program platinum members",
               "extra" : { "key" : "value" },
               "created" : "2013-08-08T20:41:06",
               "last_modified" : "2014-05-01T18:00:27",
               "channel_count": 3145
               "status": "ready"
            },
            {
               "name": "gold_members",
               "description": "loyalty program gold member",
               "extra": { "key": "value" },
               "created": "2013-08-08T20:41:06",
               "last_updated": "2014-05-01T18:00:27",
               "channel_count": 678,
               "status": "ready"
            }
         ]
      }

   :Return Value:

      - An array of :ref:`list objects <api-list-object>`


Delete a List
=============

.. warning::

   If you are attempting to update a current list by deleting it and then recreating it with
   new data, stop and go to the :ref:`upload endpoint <api-list-upload>`. There is no need to
   delete a list before uploading a new CSV file. Moreover, once you delete a list, you will
   be unable to create a list with the same name as the deleted list.

.. http:post:: /api/lists/(name)

   Delete a list.

   **Example Request**:

   .. code-block:: http

      DELETE /api/lists/platinum_members/ HTTP/1.1
      Authorization: Basic <master authorization string>
      Accept: application/vnd.urbanairship+json; version=3;

   **Example Response**:

   .. code-block:: http

      HTTP/1.1 204 No Content


.. }}}
