####################
Example API Requests
####################

With the :doc:`Urban Airship API </api/ua>`, you can design and automate a complex messaging strategy, retrieve
detailed analytics, and more. In order to help you begin testing in your own environment we have pulled
together a collection of common use-cases, providing example requests in multiple languages.

This guide is neither an introduction to the Urban Airship API nor a full reference. Rather, this
document serves as a middle ground— you should have a high-level understanding of our APIs before
proceeding, but you are not expected to be an expert. To that end, we suggest that you read (or skim)
our :doc:`Integration Guide </integration>` and :doc:`API Overview </api/overview>` before attempting
the implementations listed here.

*************
Preliminaries
*************

In the :doc:`Urban Airship API Reference </api/ua>`, example API requests/responses are provided in HTTP format with JSON data objects
representing the features and attributes of the Urban Airship service. From time to time in our documentation or on our `Support Site
<https://support.urbanairship.com>`_, we may also provide convenient HTTP examples for use with the command-line tool `cURL <http://en.wikipedia.org/wiki/CURL>`_.

Understanding that cURL examples are primarily useful for testing, we endeavor to provide additional examples that you
may be able to use in your production environment. To that end, we are including example requests here written in Python and Java,
two of the three languages for which we currently provide supported :ref:`Server Libraries <server-libraries>`.

This document will evolve over time as we continue to add additional features and server library support over time. If you
have any questions about this page or would like to suggest a new example, please send a note to our `Support Team <mailto:support@urbanairship.com>`_.


Java
====

Because Java code can be quite verbose, we have only included one full example: :ref:`sending a push
broadcast <example-broadcast-all-devices>`. Other Java examples have been reduced to the essential
components.

In particular, the ``apiClient`` is used repeatedly throughout the following examples. Unless explicitly
stated otherwise, ``apiClient`` is defined as:

.. sourcecode:: java

   APIClient apiClient = APIClient
      .newBuilder()
      .setKey("<appKey>")
      .setSecret("<appSecret>")
      .build();


.. _tg-examples-push:

****
Push
****

The :ref:`Push API <push-api>` is used to send notifications to opted in devices. The process for sending
out a notification via the API can be abstracted to the following four steps:

1. Select the audience.
2. Define the notification payload.
3. Specify device types.
4. Deliver the notification.

This section gives complete examples for several common use cases.


.. _example-broadcast-all-devices:

Broadcast to All Devices
========================

Send a push message to all devices.

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 7

      curl https://go.urbanairship.com/api/push \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "audience": "all",
                "notification": { "alert" : "A broadcast message" },
                "device_types": "all"
             }'

   .. code-block:: python
      :emphasize-lines: 5

      import urbanairship as ua

      airship = ua.Airship('app_key', 'master_secret')
      push = airship.create_push()
      push.audience = ua.all_
      push.notification = ua.notification(alert="Hello, world!")
      push.device_types = ua.all_
      push.send()

   .. code-block:: java
      :emphasize-lines: 33

      import com.urbanairship.api.client.*;
      import com.urbanairship.api.client.model.APIClientResponse;
      import com.urbanairship.api.client.model.APIPushResponse;
      import com.urbanairship.api.push.model.DeviceTypeData;
      import com.urbanairship.api.push.model.PushPayload;
      import com.urbanairship.api.push.model.audience.Selectors;
      import com.urbanairship.api.push.model.notification.Notifications;

      import org.apache.log4j.BasicConfigurator;

      import org.slf4j.Logger;
      import org.slf4j.LoggerFactory;

      import java.io.IOException;

      public class PushExample {

         private static final Logger logger = LoggerFactory.getLogger("com.urbanairship.api");

         public void sendPush() {

            String appKey = "<applicationKey>";
            String appSecret = "<applicationMasterSecret>";

            // Build and configure an APIClient
            APIClient apiClient = APIClient.newBuilder()
                  .setAppKey(appKey)
                  .setAppSecret(appSecret)
                  .build();

            // Set up a payload for the message you want to send
            PushPayload payload = PushPayload.newBuilder()
                  .setAudience(Selectors.all())
                  .setNotification(Notifications.alert("Hello, world!"))
                  .setDeviceTypes(DeviceTypeData.all())
                  .build();

            // Try/Catch for any issues, any non 200 response, or non library related
            // exceptions
            try {
               APIClientResponse<APIPushResponse> response = apiClient.push(payload);
               logger.debug(String.format("Response %s", response.toString()));
            }
            catch (APIRequestException ex) {
               logger.error(String.format("APIRequestException " + ex));
               logger.error("Something wrong with the request " + ex.toString());
            }
            catch (IOException e) {
               logger.error("IOException in API request " + e.getMessage());
            };

         }

         public static void main(String args[]) {
            BasicConfigurator.configure();
            logger.debug("Starting test push");
            PushExample example = new PushExample();
            example.sendPush();
         }

      }

   .. code-block:: ruby
      :emphasize-lines: 7

      require 'urbanairship'

      UA = Urbanairship
      cl = UA::Client.new(key:'app_key', secret:'master_secret')

      push = cl.create_push
      push.audience = UA.all
      push.notification = UA.notification(alert: 'Hello, world!')
      push.device_types = UA.all
      push.send_push


Push to Platform
================

You can send a push message to a specific platform. The example below sends a message to iOS and Android devices.

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 9

      curl https://go.urbanairship.com/api/push \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "audience": "all",
                "notification": { "alert" : "Hey Android and iOS!!" },
                "device_types": ["android","ios"]
             }'

   .. code-block:: python
      :emphasize-lines: 7-8

      import urbanairship as ua

      airship = ua.Airship('app_key', 'master_secret')
      push = airship.create_push()
      push.audience = ua.all_
      push.notification = ua.notification(alert="Hey Android and iOS!!")
      push.device_types = or_( ua.device_types('ios')
                             , ua.device_types('android'))
      push.send()

   .. code-block:: java
      :emphasize-lines: 5

      // Set up a payload for the message you want to send
      PushPayload payload = PushPayload.newBuilder()
            .setAudience(Selectors.all())
            .setNotification(Notifications.alert("Hey Android and iOS!!"))
            .setDeviceType(DeviceTypeData.of(DeviceType.IOS, DeviceType.ANDROID))
            .build();


   .. code-block:: ruby
      :emphasize-lines: 9

      require 'urbanairship'

      UA = Urbanairship
      cl = UA::Client.new(key:'app_key', secret:'master_secret')

      push = cl.create_push
      push.audience = UA.all
      push.notification = UA.notification(alert: 'Hey Android and iOS!!')
      push.device_types = UA.device_types(['ios','android'])
      push.send_push


.. _curl-push-to-device-id:

Push to Device Identifiers
==========================

If you would like to target specific users, you can push to device identifiers. The example below sends
a message to several ios channels:

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 7-13

      curl https://go.urbanairship.com/api/push \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "audience": {
                   "OR": [
                      {"ios_channel": "<iosChannel1>"},
                      {"ios_channel": "<iosChannel2>"},
                      {"ios_channel": "<iosChannel3>"}
                   ]
                },
                "notification": { "alert" : "This goes to three iOS devices" },
                "device_types": ["ios"]
             }'

   .. code-block:: python
      :emphasize-lines: 6-8

      import urbanairship as ua

      airship = ua.Airship('app_key', 'master_secret')
      push = airship.create_push()

      push.audience = or_( ua.ios_channel('iosChannel1')
                         , ua.ios_channel('iosChannel2')
                         , ua.ios_channel('iosChannel3'))

      push.notification = ua.notification("This goes to three iOS devices")
      push.device_types = ua.device_types('ios')
      push.send()

   .. code-block:: java
      :emphasize-lines: 2

      PushPayload payload = PushPayload.newBuilder()
            .setAudience(Selectors.iosChannels("<iosChannel1>", "<iosChannel2>", "<iosChannel3>"))
            .setNotification(Notifications.alert("Hi iOS users."))
            .setDeviceType(DeviceTypeData.of(DeviceType.IOS))
            .build();

   .. code-block:: ruby
      :emphasize-lines: 7-10

      require 'urbanairship'

      UA = Urbanairship
      cl = UA::Client.new(key:'app_key', secret:'master_secret')

      push = cl.create_push
      push.audience = UA.or( UA.ios_channel('iosChannel1')
                           , UA.ios_channel('iosChannel2')
                           , UA.ios_channel('iosChannel3')
                           )
      push.notification = UA.notification(alert: 'Hi iOS users')
      push.device_types = UA.device_types(['ios'])
      push.send_push


The above example uses a :ref:`segment <segments-criteria>` that goes out to any device with one of the
three device tokens. You can also push to specific Android devices by replacing ``ios_channel`` with
``android_channel``, and switching the ``device_type`` to ``android``:

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 7-12

      curl https://go.urbanairship.com/api/push \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "audience": {
                   "OR": [
                      {"android_channel": "<androidChannel1>"},
                      {"android_channel": "<androidChannel2>"},
                   ]
                },
                "notification": {
                   "alert": "Hi Android Users!"
                },
                "device_types": ["android"]
             }'

   .. code-block:: python
      :emphasize-lines: 6-8

      import urbanairship as ua

      airship = ua.Airship('app_key', 'master_secret')
      push = airship.create_push()

      push.audience = or_( ua.android_channel('androidChannel1')
                         , ua.android_channel('androidChannel2')
                         )

      push.notification = ua.notification("Hi Android users!")
      push.device_types = ua.device_types('android')
      push.send()

   .. code-block:: java
      :emphasize-lines: 3

      // Set up a payload for the message you want to send
      PushPayload payload = PushPayload.newBuilder()
            .setAudience(Selectors.androidChannels("<androidChannel1>", "<androidChannel2>"))
            .setNotification(Notifications.alert("Hi Android users!"))
            .setDeviceType(DeviceTypeData.of(DeviceType.ANDROID))
            .build();

   .. code-block:: ruby
      :emphasize-lines: 7-10

      require 'urbanairship'

      UA = Urbanairship
      cl = UA::Client.new(key:'app_key', secret:'master_secret')

      push = cl.create_push
      push.audience = UA.or( UA.android_channel('androidChannel1')
                           , UA.android_channel('androidChannel2')
                           , UA.android_channel('androidChannel3')
                           )
      push.notification = UA.notification(alert: 'Hi Android users!')
      push.device_types = UA.device_types(['android'])
      push.send_push


.. _curl-push-to-tag:

Push to Tag
===========

You can send pushes to devices with certain tags. In the example below, we send a message to devices that have
the tags ``breakingnews`` and ``sports``, or the tags ``breakingnews`` and ``worldnews``:

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 7-15

      curl https://go.urbanairship.com/api/push \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "audience": {
                   "AND": [
                      "tag": "breakingnews",
                      "OR": [
                         {"tag": "sports"},
                         {"tag": "worldnews"}
                      ]
                   ]
                },
                "notification": {
                   "alert": "BREAKING: Important news is happening"
                },
                "device_types": "all"
             }'

   .. code-block:: python
      :emphasize-lines: 5-11

      import urbanairship as ua

      airship = ua.Airship('app_key', 'master_secret')
      push = airship.create_push()
      push.audience = ua.and_(
         ua.tag("breakingnews"),
         ua.or_(
            ua.tag("sports"),
            ua.tag("worldnews")
         )
      )
      push.notification = ua.notification(alert="BREAKING: Important news is happening")
      push.device_types = ua.all_
      push.send()

   .. code-block:: java
      :emphasize-lines: 1-4, 8

      // Select the tags breakingnews and either of the tags sports or worldnews
      Selector orSelector = Selectors.tags("sports", "worldnews");
      Selector bnewsSelector = Selectors.tag("breakingnews");
      Selector compound = Selectors.and(orSelector, bnewsSelector);

      // Set up a payload for the message you want to send
      PushPayload payload = PushPayload.newBuilder()
            .setAudience(compound)
            .setNotification(Notifications.alert("BREAKING: Important news is happening")
            .setDeviceTypes(DeviceTypeData.all())
            .build();

   .. code-block:: ruby
      :emphasize-lines: 7-13

      require 'urbanairship'

      UA = Urbanairship
      cl = UA::Client.new(key:'app_key', secret:'master_secret')

      push = cl.create_push
      push.audience = UA.and(
         UA.tag('breakingnews'),
         UA.or(
            UA.tag('worldnews'),
            UA.ios_channel('sports')
         )
      )
      push.notification = UA.notification(alert: 'BREAKING: Important news is happening')
      push.device_types = UA.all
      push.send_push

Pushing to a tag contained in a specific :doc:`Tag Group <tag-groups-walkthrough>` is similarly
easy:

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 7-12

      curl https://go.urbanairship.com/api/push \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "audience": {
                   "AND": [
                      { "tag": "sports", "group": "device" },
                      { "tag": "gold", "group": "loyalty" }
                   ]
                },
                "notification": {
                   "alert": "BREAKING: Important news is happening"
                },
                "device_types": "all"
             }'

   .. code-block:: python

      # Tag Groups are not currently supported by the Python library.

   .. code-block:: java

      // Tag Groups are not currently supported by the Java library.

   .. code-block:: ruby

      # Tag Groups are not currently supported by the Ruby library.

The process of pushing to a :ref:`Device Property Tag <ug-ootb-tags>` is similar:

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 7

      curl https://go.urbanairship.com/api/push \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "audience": { "tag": "Africa/Addis_Ababa", "group": "timezone" }
                "notification": {
                   "alert": "BREAKING: Important news is happening"
                },
                "device_types": "all"
             }'

   .. code-block:: python

      # Device Property Tags require the use of Tag Groups, which are currently unsupported
      # by the Python library

   .. code-block:: java

      // Device Property Tags require the use of Tag Groups, which are currently unsupported
      // by the Java library

   .. code-block:: ruby

      # Device Property Tags require the use of Tag Groups, which are currently unsupported
      # by the Ruby library

The only difference between pushing to a Device Property Tag and any other tag is that Device
Property Tags are automatically generated by Urban Airship. For a list of available Device
Property Tags, please see our :doc:`reference document </reference/device-property-tags>`.


Push to Segment
===============

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 7

      curl https://go.urbanairship.com/api/push \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "audience": { "segment": "<SegmentID>" },
                "notification": { "alert": "What up segment" },
                "device_types": "all"
             }' \

   .. code-block:: python
      :emphasize-lines: 5

      import urbanairship as ua

      airship = ua.Airship('app_key', 'master_secret')
      push = airship.create_push()
      push.audience = ua.segment('segmentID')
      push.notification = ua.notification(alert="What's up segment?")
      push.device_types = ua.all_
      push.send()

   .. code-block:: java
      :emphasize-lines: 3

      // Set up a payload for the message you want to send
      PushPayload payload = PushPayload.newBuilder()
            .setAudience(Selectors.segment("<SegmentID>"))
            .setNotification(Notifications.alert("What's up segment?"))
            .setDeviceTypes(DeviceTypeData.all())
            .build();

   .. code-block:: ruby
      :emphasize-lines: 7

      require 'urbanairship'

      UA = Urbanairship
      cl = UA::Client.new(key:'app_key', secret:'master_secret')

      push = cl.create_push
      push.audience = UA.segment('segmentID')
      push.notification = UA.notification(alert: "What's up segment?")
      push.device_types = UA.all
      push.send_push

.. note::

   For details on creating, deleting, or getting information on segments, please see our
   :ref:`Segments` section.


**************
Scheduled Push
**************

If you are scheduling a push to go out at a future time, i.e., *not immediately*, use the ``/api/schedules/`` endpoint and include at least one :ref:`schedule-object`.

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 8-13

      curl https://go.urbanairship.com/api/schedules \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "name": "Baseball fans",
                "schedule": { "scheduled_time" : "2015-02-16T10:30:00" },
                "push": {
                   "audience": { "tag": "usa" },
                   "notification": { "alert": "Guess what day it is!" },
                   "device_types": "all"
                }
             }'

   .. code-block:: python
      :emphasize-lines: 5-7

      import urbanairship as ua
      import datetime

      sched = airship.create_scheduled_push()
      sched.schedule = ua.schedule_time(
         datetime.datetime(2015, 2, 16, 10, 30)
      )

      sched.push = airship.create_push()
      sched.push.audience = ua_tag("usa")
      sched.push.notification = ua.notification(alert="Guess what day it is!")
      sched.push.device_types = ua.all_
      sched.send()

   .. code-block:: java
      :emphasize-lines: 8-11, 16

      // Set up a payload for the message you want to send
      PushPayload payload = PushPayload.newBuilder()
            .setAudience(Selectors.all())
            .setNotification(Notifications.alert("Hello, World."))
            .setDeviceTypes(DeviceTypeData.of(DeviceType.IOS))
            .build();

      DateTime dt = DateTime.now().plusSeconds(60);
      Schedule schedule = Schedule.newBuilder()
            .setScheduledTimestamp(dt)
            .build();

      SchedulePayload schedulePayload = SchedulePayload.newBuilder()
            .setName("Urban Airship Scheduled Push")
            .setPushPayload(payload)
            .setSchedule(schedule)
            .build();

   .. code-block:: ruby
      :emphasize-lines: 10-12

      require 'urbanairship'

      UA = Urbanairship
      cl = UA::Client.new(key:'app_key', secret:'master_secret')

      push = cl.create_push
      push.audience = UA.tag('usa')
      push.notification = UA.notification(alert: 'Guess what day it is!')
      push.device_types = UA.all
      sched = cl.create_schedule_push
      sched.schedule = UA.scheduled_time(Time.new(2015, 2, 16, 10, 30))
      sched.push = push
      sched.send_push

For more information on scheduling pushes, please see :ref:`POST-api-schedule`.


**********
Automation
**********

Automated messages are handled via the :ref:`pipelines API <pipelines-api>`. Broadly, a request to the pipelines
api must contain ``outcome`` and ``enabled`` attributes, and some sort of trigger. The trigger specifies
what sets off the automated messsage, and the ``outcome`` attribute specifies what happens once the
message has been triggered. ``enabled`` is a boolean that specifies whether the automated message
is active or not.


.. _automated-message-with-a-tag-trigger:

Tag Trigger
===========

The following request creates an automated message that sends when the tag ``bought-shoes`` is added to a
device:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/pipelines \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "name": "shoe buyer",
                "enabled": true,
                "immediate_trigger": { "tag_added": "bought-shoes" },
                "outcome": {
                   "push": {
                      "audience": "triggered",
                      "notification": { "alert": "heard u like shoes bruh" },
                      "device_types": "all"
                   }
                }
             }'

   .. code-block:: python

      # The Automation API is not currently supported by the Python library.

   .. code-block:: java

      // The Automation API is not currently supported by the Java library.

   .. code-block:: ruby

      # The Automation API is not currently supported by the Ruby library.

Tag Trigger and Delay
=====================

The following request is identical to the previous one, except we now add the ``delay`` attribute:

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 11

      curl https://go.urbanairship.com/api/pipelihes \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "name": "shoe buyer",
                "enabled": true,
                "immediate_trigger": { "tag_added" : "bought-shoes" },
                "outcome": {
                   "delay": 3600,
                   "push": {
                      "audience": "triggered",
                      "notification": { "alert": "heard u like shoes br" },
                      "device_types": "all"
                   }
                }
             }'

   .. code-block:: python

      # The Automation API is not currently supported by the Python library.

   .. code-block:: java

      // The Automation API is not currently supported by the Java library.

   .. code-block:: ruby

      # The Automation API is not currently supported by the Ruby library.

Once a device is tagged with ``bought-shoes``, this automated message will send after a 60 minute delay.


First Open Trigger
==================

This request creates an automated message with a :ref:`First Open Trigger <event-identifier>`:

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 8

      curl https://go.urbanairship.com/api/pipelines \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "enabled": true,
                "immediate_trigger": "first_open",
                "outcome": {
                   "delay": 3600,
                   "push": {
                      "audience": "triggered",
                      "notification": { "alert" : "thanks for downloading our app!" },
                      "device_types": "all"
                   }
                }
             }'

   .. code-block:: python

      # The Automation API is not currently supported by the Python library.

   .. code-block:: java

      // The Automation API is not currently supported by the Java library.

   .. code-block:: ruby

      # The Automation API is not currently supported by the Ruby library.


List Enabled Pipelines
======================

This request will display all automated messages that are currently active:

.. example-code::

   .. code-block:: bash

      curl "https://go.urbanairship.com/api/pipelines?enabled=true" \
         -u "<AppKey>:<MasterSecret>"

   .. code-block:: python

      # The Automation API is not currently supported by the Python library.

   .. code-block:: java

      // The Automation API is not currently supported by the Java library.

   .. code-block:: ruby

      # The Automation API is not currently supported by the Ruby library.

If you would like to see inactive automated messages, change ``enabled=true`` to ``enabled=false``


****
Tags
****

Channel Tag Operations
======================

The examples below use the ``/api/channels/tags`` endpoint to add, remove, and set tags on devices.
Each example incorporates new :ref:`Tag Group <tg-mdb-tag-groups>` functionality as well.

**Example (add tags)**:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/channels/tags \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
               "audience": {
                  "ios_channel": "ios_channel_id",
                  "android_channel": "android-channel-id"
               },
               "add": {
                  "crm": ["partner_offers", "new_customer"]
               }
            }'

   .. code-block:: python

      # The /api/channels/tags/ endpoint is not currently supported by the Python library.

   .. code-block:: java

      // The /api/channels/tags/ endpoint is not currently supported by the Java library.

   .. code-block:: ruby

      # The channels API is not currently supported by the Ruby library.

|

**Example (remove tags)**:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/channels/tags \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
               "audience": {
                  "ios_channel": "ios_channel_id"
               },
               "remove": {
                  "loyalty": ["gold_member"]
               }
            }'

   .. code-block:: python

      # The /api/channels/tags/ endpoint is not currently supported by the Python library.

   .. code-block:: java

      // The /api/channels/tags/ endpoint is not currently supported by the Java library.

   .. code-block:: ruby

      # The channels API is not currently supported by the Ruby library.

|

**Example (set tags)**:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/channels/tags \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
               "audience": {
                  "ios_channel": "ios_channel_id"
               },
               "set": {
                  "best_tag_group": ["a_tag"]
               }
            }'

   .. code-block:: python

      # The /api/channels/tags/ endpoint is not currently supported by the Python library.

   .. code-block:: java

      // The /api/channels/tags/ endpoint is not currently supported by the Java library.

   .. code-block:: ruby

      # The channels API is not currently supported by the Ruby library.

For more information on Tag Groups and Mobile Data Bridge, please see the
:doc:`/topic-guides/mobile-data-bridge` and :doc:`/topic-guides/tag-groups-walkthrough`.


Legacy Tag Operations
=====================

The examples here use the legacy ``/api/tags/`` endpoint. If you are using this endpoint,
we strongly recommend transitioning to an implementation that uses either the Channels or
Named Users tag endpoints.

List Tags
---------

The following request lists all tags associated with a certain app key:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/tags/ \
         -X GET \
         -u "<AppKey>:<MasterSecret>"

   .. code-block:: python

      import urbanairship as ua
      airship = ua.Airship('app_key', 'master_secret')
      list_tags = ua.Taglist(airship)
      list_tags.list_tags()

   .. code-block:: java

      APIClientResponse<APIListTagsResponse> response = apiClient.listTags();

      // List of Tags
      List<String> tags = response.getApiResponse().getTags();

   .. code-block:: ruby

      # The tags API is not currently supported by the Ruby library.

Create Tag
----------

The following request creates the ``pizza_yolo`` tag:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/tags/pizza_yolo \
         -X PUT \
         -u "<AppKey>:<MasterSecret>"

   .. code-block:: python

      # The tag creation endpoint is not supported by the Python library.

   .. code-block:: java

      String newTag = "pizza_yolo";
      HttpResponse response = apiClient.createTag(newTag);

      int status = response.getStatusLine().getStatusCode();

   .. code-block:: ruby

      # The tags API is not currently supported by the Ruby library.

Add or Remove Devices from a Tag
--------------------------------

.. warning::

   If you are currently using the SDK to set tags, using this endpoint to add additional tags will
   result in the SDK immediately clearing the tags upon registration. See the warnings :ref:`here
   <api-tags-add-remove>` for more information.

The following request removes the tag ``pizza_yolo`` from three Android devices, and adds it to
two iOS devices:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/tags/pizza_yolo \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "ios_channels": {
                   "add": [
                      "<iosChannel1>",
                      "<iosChannel2>"
                   ]
                },
                "android_channels": {
                   "remove": [
                      "<androidChannel1>",
                      "<androidChannel2>",
                      "<androidChannel3>"
                   ]
                }
             }'

   .. code-block:: python

      import urbanairship as ua

      airship = ua.Airship('app_key', 'master_secret')
      devices.add(
         ios_channels = ['ios_channel_1', 'ios_channel_2']
      )
      devices.remove(
         android_channels = ['android_channel_1', 'android_channel_2', 'android_channel_3']
      )

   .. code-block:: java

	  String tag = "pizza_yolo";

	  AddRemoveDeviceFromTagPayload payload = AddRemoveDeviceFromTagPayload.newBuilder()
	      .setIOSChannels(AddRemoveSet.newBuilder()
	          .add("iosChannel1")
	          .add("iosChannel2")
	          .build())
	      .setApids(AddRemoveSet.newBuilder()
	          .remove("androidApid1")
	          .remove("androidApid2")
		  .remove("androidApid3")
	          .build())
	      .build();

	  HttpResponse response = apiClient.addRemoveDevicesFromTag(tag, payload);

	  int status = response.getStatusLine().getStatusCode();

   .. code-block:: ruby

      # The tags API is not currently supported by the Ruby library.


Delete Tag
----------

This request deletes the tag ``pizza_yolo`` and removes it from all devices:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/tags/pizza_yolo \
         -X DELETE \
         -u "<AppKey>:<MasterSecret>"

   .. code-block:: python

      import urbanairship as ua

      airship = ua.Airship('app_key', 'master_secret')
      delete_tag = ua.DeleteTag(airship, 'pizza_yolo')
      delete_tag.send_delete()

   .. code-block:: java

      HttpResponse response = apiClient.deleteTag("pizza_yolo");

      int status = response.getStatusLine().getStatusCode();

   .. code-block:: ruby

      # The tags API is not currently supported by the Ruby library.


Batch Modification of Tags
--------------------------

The ``batch`` endpoint takes an array of device identifier and tag array pairs, like this:

.. code-block:: bash

   {
      "<Device_ID>": "...",
      "tags": ["tag_1", ..., "tag_n"]
   }

For each of these pairs, the API will verify that a list of tags is present and that the device ID is valid.
The set of tags for the given device ID will be set to the given list of tags:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/tags/batch \
        -X PUT \
        -u "<AppKey>:<MasterSecret>" \
        -H "Accept: application/vnd.urbanairship+json; version=3" \
        -H "Content-Type: application/json" \
        -d '[
               {
                  "ios_channel": "<iosChannel1>",
                  "tags": [
                     "birds",
                     "puppies"
                  ]
               },
               {
                  "ios_channel": "<iosChannel2>",
                  "tags": [
                     "san_francisco",
                     "shoes"
                  ]
               },
               {
                  "android_channel": "<androidChannel1>",
                  "tags": [
                     "world_news",
                     "sports"
                  ]
               }
            ]'

   .. code-block:: python

      import urbanairship as ua

      airship = ua.Airship('app_key', 'master_secret')
      send_batch = ua.BatchTag(airship)
      send_batch.add_ios_channel('ios_channel_1', ['birds', 'puppies'])
      send_batch.add_ios_channel('ios_channel_2', ['san_francisco', 'shoes'])
      send_batch.add_amazon_channel('android_channel_1', ['world_news', 'sports'])
      send_batch.send_request()

   .. code-block:: java

      BatchTagSet bts1 = BatchTagSet.newBuilder()
         .setDevice(BatchTagSet.DEVICEIDTYPES.IOS_CHANNEL, "<iosChannel1>")
         .addTag("birds")
         .addTag("puppies")
         .build();

      BatchTagSet bts2 = BatchTagSet.newBuilder()
         .setDevice(BatchTagSet.DEVICEIDTYPES.IOS_CHANNEL, "<iosChannel2>")
         .addTag("san_francisco")
         .addTag("shoes")
         .build();

      BatchTagSet bts3 = BatchTagSet.newBuilder()
         .setDevice(BatchTagSet.DEVICEIDTYPES.APID, "<APID1>")
         .addTag("birds")
         .addTag("puppies")
         .build();

      HttpResponse response1 = apiClient.batchModificationOfTags(BatchModificationPayload.newBuilder()
         .addBatchObject(bts1)
         .build()
      );

      HttpResponse response2 = apiClient.batchModificationOfTags(BatchModificationPayload.newBuilder()
         .addBatchObject(bts2)
         .build()
      );

      HttpResponse response3 = apiClient.batchModificationOfTags(BatchModificationPayload.newBuilder()
         .addBatchObject(bts3)
         .build()
      );

      int status1 = response.getStatusLine().getStatusCode();
      int status2 = response.getStatusLine().getStatusCode();
      int status3 = response.getStatusLine().getStatusCode();

   .. code-block:: ruby

      # The tags API is not currently supported by the Ruby library.


**************
Rich App Pages
**************

The process for sending a rich message is similar to sending a standard notification, except now
you must include a ``message`` object with the JSON payload, and the ``message`` object must contain
a ``title`` and ``body`` attribute. Together, these two attributes define your rich message. Additionally,
there are a number of optional attributes. Please see the :ref:`rich-push-api` documentation for a full
reference.

.. warning::

   You'll notice that ``device_types`` is set to one or more of iOS, Amazon, and Android for every example. Rich
   Push is not supported on WNS or Blackberry, so attempting to push to either of those platforms will result
   in an error message.

Standard Broadcast
==================

Send a rich push message to your entire audience:

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 10-14

      curl https://go.urbanairship.com/api/push \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "audience": "all",
                "notification": { "alert" : "You have a rich message omg!" },
                "device_types": ["ios", "android", "amazon"],
                "message": {
                   "title": "Message Title",
                   "body": "Here is the content of your message",
                   "content_type": "text/html"
                }
             }'

   .. code-block:: python
      :emphasize-lines: 11-15

      import urbanairship as ua

      airship = ua.Airship('app_key', 'master_secret')
      push = airship.create_push()
      push.audience = ua.all_
      push.device_types = ua.or_( ua.device_types('ios')
                                , ua.device_types('android')
                                , ua.device_types('amazon')
                                )

      push.message = ua.message(
         title = "New follower"
         body = "Justin Bieber is now following you!"
         content_type = text/html
      )
      push.notification = ua.notification(alert="Guess who's following you...")
      push.send()

   .. code-block:: java
      :emphasize-lines: 1-5, 10

      RichPushMessage message = RichPushMessage.newBuilder()
            .setTitle("New Follower")
            .setBody("Justin Bieber is now following you!")
            .setContentType("text/html")
            .build();

      // Set up a payload for the message you want to send
      PushPayload payload = PushPayload.newBuilder()
            .setAudience(Selectors.all())
            .setMessage(message)
            .setNotification(Notifications.alert("Guess who's following you..."))
            .setDeviceType(DeviceTypeData.of(DeviceType.IOS, DeviceType.ANDROID, DeviceType.AMAZON))
            .build();

   .. code-block:: ruby

      require 'urbanairship'

      UA = Urbanairship
      cl = UA::Client.new(key: 'app_key', secret:'master_secret')

      push = cl.create_push
      push.audience = UA.all
      push.device_types = UA.device_types(['ios', 'android', 'amazon'])
      push.message = UA.message(
         title: 'New follower',
         body: 'Justin Bieber is now following you!'
      )
      push.send_push

The ``content_type`` attribute simply specifies the MIME type of the data in ``body``. In fact,
``content_type`` defaults to ``text/html``, so we could have omitted it in this example.


Broadcast With Link
===================

In this example, we include a link in the body of our rich message:

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 10-14

      curl https://go.urbanairship.com/api/push \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "audience": "all",
                "notification": { "alert" : "The standard alert" },
                "device_types": "all",
                "message": {
                   "title": "Message Title",
                   "body": "<html><h1>Headline</h1><p>We can <a href=\"http://urbanairship.com\">insert a link!</a></p></html>",
                   "content_type": "text/html"
                }
             }'

   .. code-block:: python
      :emphasize-lines: 7-10

      import urbanairship as ua

      airship = ua.Airship('app_key', 'master_secret')
      push = airship.create_push()
      push.audience = ua.all_
      push.device_types = ua.all_
      push.message = ua.message(
         title = "Check this out!"
         body = "<html><h1>Headline</h1><p>We can <a href=\"http://urbanairship.com\">insert a link!</a></p></html>"
      )
      push.notification = ua.notification(alert="The standard alert")
      push.send()

   .. code-block:: java
      :emphasize-lines: 1-5, 10

      RichPushMessage message = RichPushMessage.newBuilder()
            .setTitle("Check this out!")
            .setBody("<html><h1>Headline</h1><p>We can <a href=\"http://urbanairship.com\">insert a link!</a></p></html>")
            .setContentType("text/html")
            .build();

      // Set up a payload for the message you want to send
      PushPayload payload = PushPayload.newBuilder()
            .setAudience(Selectors.all())
            .setMessage(message)
            .setNotification(Notifications.alert("The standard alert"))
            .setDeviceType(DeviceTypeData.of(DeviceType.IOS, DeviceType.ANDROID, DeviceType.AMAZON))
            .build();

   .. code-block:: ruby

      require 'urbanairship'

      UA = Urbanairship
      cl = UA::Client.new(key: 'app_key', secret:'master_secret')

      push = cl.create_push
      push.audience = UA.all
      push.device_types = UA.all
      push.message = UA.message(
         title: 'Check this out!',
         body: '<html><h1>Headline</h1><p>We can <a href=\"http://urbanairship.com\">insert a link!</a></p></html>'
      )
      push.send_push

Broadcast With Embedded YouTube Video
=====================================

This example includes an embedded YouTube video in the body:

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 10-14

      curl https://go.urbanairship.com/api/push \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "audience": "all",
                "notification": { "alert" : "A VIDEO in a rich message?! What will they think of next." },
                "device_types": ["ios","android","amazon"],
                "message": {
                   "title": "Message Title",
                   "body": "<html><h1>Headline</h1><iframe width=\"560\" height=\"315\" src=\"//www.youtube.com/embed/RGjGf-tBg_E\" frameborder=\"0\" allowfullscreen></iframe></html>",
                   "content_type": "text/html"
                }
             }'

   .. code-block:: python
      :emphasize-lines: 7-10

      import urbanairship as ua

      airship = ua.Airship('app_key', 'master_secret')
      push = airship.create_push()
      push.audience = ua.all_
      push.device_types = ua.all_
      push.message = ua.message(
         title = "Check this out!"
         body =  "<html><h1>Headline</h1><iframe width=\"560\" height=\"315\" src=\"//www.youtube.com/embed/RGjGf-tBg_E\" frameborder=\"0\" allowfullscreen></iframe></html>"
      )
      push.notification = ua.notification(alert="A VIDEO in a rich message?! What will they think of next.")
      push.send()

   .. code-block:: java
      :emphasize-lines: 1-5, 10

      RichPushMessage message = RichPushMessage.newBuilder()
            .setTitle("Check this out!")
            .setBody("<html><h1>Headline</h1><iframe width=\"560\" height=\"315\" src=\"//www.youtube.com/embed/RGjGf-tBg_E\" frameborder=\"0\" allowfullscreen></iframe></html>")
            .setContentType("text/html")
            .build();

      // Set up a payload for the message you want to send
      PushPayload payload = PushPayload.newBuilder()
            .setAudience(Selectors.all())
            .setMessage(message)
            .setNotification(Notifications.alert("A VIDEO in a rich message? What will they think of next."))
            .setDeviceType(DeviceTypeData.of(DeviceType.IOS, DeviceType.ANDROID, DeviceType.AMAZON))
            .build();

   .. code-block:: ruby

      require 'urbanairship'

      UA = Urbanairship
      cl = UA::Client.new(key: 'app_key', secret:'master_secret')

      push = cl.create_push
      push.audience = UA.all
      push.device_types = UA.all
      push.message = UA.message(
         title: 'Check this out!',
         body: '<html><h1>Headline</h1><iframe width=\"560\" height=\"315\" src=\"//www.youtube.com/embed/RGjGf-tBg_E\" frameborder=\"0\" allowfullscreen></iframe></html>'
      )
      push.send_push


*******
Actions
*******


Add or Remove Tags
==================

If a user taps on this notification, it will add the tags ``pizza`` and ``news`` to their device:

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 10

      curl https://go.urbanairship.com/api/push \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "audience": "all",
                "notification": {
                   "alert": "Mayor uses fork to eat pizza, public outraged.",
                   "actions": { "add_tag" : ["pizza", "news"] }
                },
                "device_types": ["android"]
             }'

   .. code-block:: python
      :emphasize-lines: 8-11

      import urbanairship as ua

      airship = ua.Airship('app_key', 'master_secret')
      push = airship.create_push()
      push.audience = ua.all_
      push.notification = ua.notification(
         alert="Mayor uses fork to eat pizza, public outraged."
         actions=ua.actions(
            add_tag="pizza",
            add_tag="news
         )
      )
      push.device_types = ua.all_
      push.send()

   .. code-block:: java
      :emphasize-lines: 1-9, 13, 20

      // Create the tag set
      Set<String> tags = new HashSet<String>();
      tags.add("mayor");
      tags.add("pizza");

      // Define the action
      Actions addTagAction = Actions.newBuilder()
            .addTags(new AddTagAction(TagActionData.set(tags)))
            .build();

      // Add addTagAction to your notification
      Notification addTagNotification = Notification.newBuilder()
            .setActions(addTagAction)
            .setAlert("Mayor uses fork to eat pizza, public outraged.")
            .build();

      // Set up a payload for the message you want to send
      PushPayload payload = PushPayload.newBuilder()
            .setAudience(Selectors.all())
            .setNotification(addTagNotification)
            .setDeviceType(DeviceTypeData.of(DeviceType.IOS, DeviceType.ANDROID))
            .build();

   .. code-block:: ruby

      require 'urbanairship'

      UA = Urbanairship
      cl = UA::Client.new(key: 'app_key', secret:'master_secret')

      push = cl.create_push
      push.audience = UA.all
      push.device_types = UA.all
      push.notification = UA.notification(
         alert: 'Mayor uses fork to eat pizza, public outraged.',
         actions: UA.actions(
            add_tag: 'pizza',
            add_tag: 'news'
         )
      )
      push.send_push

To remove tags, simply use the ``remove_tag`` attribute rather than the ``add_tag`` attribute.


Share Text
==========

The following API request will send a push containing the share action:

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 10

      curl https://go.urbanairship.com/api/push \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "audience": "all",
                "notification": {
                   "alert": "Thank you for using our app. Tell your friends about us!",
                   "actions": { "share": "BestApp9000 is the best app ever." }
                },
                "device_types": ["android"]
             }'

   .. code-block:: python
      :emphasize-lines: 8-10

      import urbanairship as ua

      airship = ua.Airship('app_key', 'master_secret')
      push = airship.create_push()
      push.audience = ua.all_
      push.notification = ua.notification(
         alert="Thank you for using our app. Tell your friends about us!"
         actions=ua.actions(
            share="BestApp9000 is the best app ever."
         )
      )
      push.device_types = ua.all_
      push.send()

   .. code-block:: java
      :emphasize-lines: 1-4, 8, 15

      // Define the action
      Actions shareText = Actions.newBuilder()
            .setShare(new ShareAction("BestApp9000 is the best app ever"))
            .build();

      // Build a notification w/ the above sharing action incorporated
      Notification shareNotification = Notification.newBuilder()
            .setActions(shareText)
            .setAlert("Thank you for using our app. Tell your friends about us!")
            .build();

      // Set up a payload for the message you want to send
      PushPayload payload = PushPayload.newBuilder()
            .setAudience(Selectors.all())
            .setNotification(shareNotification)
            .setDeviceType(DeviceTypeData.of(DeviceType.ANDROID))
            .build();

   .. code-block:: ruby

      require 'urbanairship'

      UA = Urbanairship
      cl = UA::Client.new(key: 'app_key', secret:'master_secret')

      push = cl.create_push
      push.audience = UA.all
      push.device_types = UA.all
      push.notification = UA.notification(
         alert: 'Thank you for using our app. Tell your friends about us!',
         actions: UA.actions(
            share: 'BestApp9000 is the best app ever.'
         )
      )
      push.send_push

In particular, this push will read "Thank you for using our app. Tell your friends about us!". If the user taps
on the notification, they will be brought into an app of their choice, where they will have the option to share
the text "BestApp9000 is the best app ever."


Open an External URL
====================

This example opens an external URL after the user taps the push:

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 10-15

      curl https://go.urbanairship.com/api/push \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "audience": "all",
                "notification": {
                   "alert": "Read some news or something.",
                   "actions": {
                      "open": {
                         "type": "url",
                         "content": "http://www.theatlantic.com"
                      }
                   }
                },
                "device_types": ["android", "ios"]
             }'

   .. code-block:: python
      :emphasize-lines: 8-13

      import urbanairship as ua

      airship = ua.Airship('app_key', 'master_secret')
      push = airship.create_push()
      push.audience = ua.all_
      push.notification = ua.notification(
         alert="Read some news or something"
         actions=ua.actions(
            open_={
               "type": "url",
               "content": "http://www.theatlantic.com"
            }
         )
      )
      push.device_types = ua.all_
      push.send()

   .. code-block:: java
      :emphasize-lines: 1-8, 10-12, 15, 21

      // Create a URI
      URI atlantic = null;
      try {
         atlantic = new URI("http://www.theatlantic.com");
      }
      catch {
         System.out.println("URI Syntax Error: " + e.getMessage());
      }

      Actions openURL = Actions.newBuilder()
            .setOpen(new OpenExternalURLAction(atlantic))
            .build();

      Notification actionNotification = Notification.newBuilder()
            .setActions(openURL)
            .setAlert("Read some news or something.")
            .build();

      PushPayload payload = PushPayload.newBuilder()
            .setAudience(Selectors.all())
            .setNotification(actionNotification)
            .setDeviceTypes(DeviceTypeData.of(DeviceType.ANDROID,DeviceType.IOS))
            .build();

   .. code-block:: ruby

      require 'urbanairship'

      UA = Urbanairship
      cl = UA::Client.new(key: 'app_key', secret:'master_secret')

      push = cl.create_push
      push.audience = UA.all
      push.device_types = UA.all
      push.notification = UA.notification(
         alert: 'Read some news or something',
         actions: UA.actions(
            open_: {
               type: 'url',
               content: 'http://www.theatlantic.com'
            }
         )
      )
      push.send_push


*************************
Interactive Notifications
*************************


Follow and Unfollow
===================

You can also send an interactive notification that gives the user the option to follow a story. To do so,
use the ``ua_follow`` interactive notification, and if a user selects the *Follow* button, add a tag that is
relevant to the current story:

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 10-17

      curl https://go.urbanairship.com/api/push \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                 "audience": "all",
                 "notification": {
                     "alert": "Portland expected to get 6 inches of snow tonight.",
                     "interactive": {
                         "type": "ua_follow",
                         "button_actions": {
                             "follow": {
                                 "add_tag": "pdx-snowstorm-2015"
                             }
                         }
                     }
                 },
                 "device_types": "all"
             }'

   .. code-block:: python
      :emphasize-lines: 10-15

      import urbanairship as ua

      airship = ua.Airship('app_key', 'master_secret')
      push = airship.create_push()
      push.audience = ua.all_
      push.device_types = ua.all_

      push.notification = ua.notification(
         alert = "Portland expected to get 6 inches of snow tonight.",
         interactive = ua.interactive(
            type = ua_follow,
            button_actions = {
               "follow": ua.actions(add_tag="pdx-snowstorm-2015")
            }
         )
      )

      push.send()

   .. code-block:: java
      :emphasize-lines: 1-13, 17

      Interactive interactive = Interactive.newBuilder()
            .setType("ua_follow")
            .setButtonActions(
               ImmutableMap.of(
                  "follow",
                  Actions.newBuilder()
                     .addTags(new AddTagAction(TagActionData.single("pdx-snowstorm-2015"))))
            .build();

      Notification interactiveNotification = Notification.newBuilder()
            .setInteractive(interactive)
            .setAlert("Portland expected to get 6 inches of snow tonight.")
            .build();

      PushPayload payload = PushPayload.newBuilder()
               .setAudience(Selectors.all())
               .setNotification(interactiveNotification)
               .setDeviceTypes(DeviceTypeData.all())
               .build();

   .. code-block:: ruby

      require 'urbanairship'

      UA = Urbanairship
      cl = UA::Client.new(key: 'app_key', secret:'master_secret')

      push = cl.create_push
      push.audience = UA.all
      push.device_types = UA.all
      push.notification = UA.notification(
         alert: 'Portland expected to get 6 inches of snow tonight.',
         interactive: UA.interactive(
            type: 'ua_follow',
            button_actions: {
               follow: { add_tag: 'pdx-snowstorm-2015' }
            }
         )
      )
      push.send_push

In the above example, users who want more information on the weather can choose *Follow*, and the
``pdx-snowstorm-2015`` tag will be added to their device.

Now, any follow-up notifications on this story should be pushed to the tag ``pdx-snowstorm-2015``. Moreover, you
can use the ``ua_unfollow`` built-in interactive notification to give users the option to unsubscribe from
updates at any time. If a user chooses ``unfollow``, the ``pdx-snowstorm-2015`` tag is *removed* from their
device:

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 10-17

      curl https://go.urbanairship.com/api/push \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "audience": { "tag": "pdx-snowstorm-2015" },
                "notification": {
                   "alert": "Minor snow storm reduces Portland to post-apocalyptic wasteland.",
                   "interactive": {
                      "type": "ua_unfollow",
                      "button_actions": {
                         "unfollow": {
                            "remove_tag": "pdx-snowstorm-2015"
                         }
                      }
                   }
                },
                "device_types": "all"
             }'

   .. code-block:: python
      :emphasize-lines: 10-15

      import urbanairship as ua

      airship = ua.Airship('app_key', 'master_secret')
      push = airship.create_push()
      push.audience = ua.tag("pdx-snowstorm-2015)
      push.device_types = ua.all_

      push.notification = ua.notification(
         alert = "Minor snow storm reduces Portland to post-apocalyptic wasteland.",
         interactive = ua.interactive(
            type = ua_unfollow,
            button_actions = {
               "unfollow": ua.actions(remove_tag="pdx-snowstorm-2015")
            }
         )
      )

      push.send()

   .. code-block:: java
      :emphasize-lines: 1-13, 17

      Interactive interactive = Interactive.newBuilder()
            .setType("ua_unfollow")
            .setButtonActions(
               ImmutableMap.of(
                  "unfollow",
                  Actions.newBuilder()
                     .removeTags(new AddTagAction(TagActionData.single("pdx-snowstorm-2015"))))
            .build();

      Notification interactiveNotification = Notification.newBuilder()
            .setInteractive(interactive)
            .setAlert("Minor snow storm reduces Portland to post-apocalyptic wasteland.")
            .build();

      PushPayload payload = PushPayload.newBuilder()
               .setAudience(Selectors.tag("pdx-snowstorm-2015"))
               .setNotification(interactiveNotification)
               .setDeviceTypes(DeviceTypeData.all())
               .build();

   .. code-block:: ruby

      require 'urbanairship'

      UA = Urbanairship
      cl = UA::Client.new(key: 'app_key', secret:'master_secret')

      push = cl.create_push
      push.audience = UA.tag('pdx-snowstorm-2015')
      push.device_types = UA.all
      push.notification = UA.notification(
         alert: 'Minor snow storm reduces Portland to post-apocalyptic wasteland.',
         interactive: UA.interactive(
            type: 'ua_unfollow',
            button_actions: {
               follow: { remove_tag: 'pdx-snowstorm-2015' }
            }
         )
      )
      push.send_push


Remind Me Later
===============

There are two steps to creating an Interactive Notification with reminder functionality:

#. Create an automated message containing your story reminder. This message should be :ref:`triggered with a tag
   <automated-message-with-a-tag-trigger>`.

#. Create an interactive notification that uses the ``ua_remind_me_later`` type, and have the *Remind me later*
   button set a tag that triggers the automated message.

Beginning with step 1, this request creates an automated message that's triggered once the
``pizza-deal-reminder`` tag is added to a user's device.

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/pipelines \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "name": "pizza deal reminder",
                "enabled": true,
                "immediate_trigger": { "tag_added": "pizza-deal-reminder" },
                "outcome": {
                   "delay": 86400
                   "push": {
                      "audience": "triggered",
                      "notification": { "alert": "have a slice on us! (terms and conditions apply)" },
                      "device_types": "all"
                   }
                }
             }'

   .. code-block:: python

      # This example requires use of the Automation API, which is currently unsupported by the Python
      # library.

   .. code-block:: java

      // This example requires use of the Automation API, which is currently unsupported by the Java
      // library

   .. code-block:: ruby

      # This example requires use of the Automation API, which is currently unsupported by
      # the Ruby library.

The ``delay`` is critical here. If you don't include a delay, the reminder notification will be sent immediately
after the user hits *Remind me later*. In this payload, the delay is set to 86,400 seconds, or 24 hours.

Once you have created the automated message, create an interactive notification that triggers the automated
message by tagging users with ``pizza-story-reminder`` if they press the *Remind me later* button:

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 10-17

      curl https://go.urbanairship.com/api/push \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "audience": "all",
                "notification": {
                   "alert": "buy 100 pizzas, get a slice free!",
        	   "interactive": {
            	      "type": "ua_remind_me_later",
            	      "button_actions": {
                         "remind": {
                    	    "add_tag": "pizza-deal-reminder"
                	 }
            	      }
        	   }
    	        },
                "device_types" : "all"
             }'

   .. code-block:: python

      # This example requires use of the Automation API, which is currently unsupported by the Python
      # library.

   .. code-block:: java

      // This example requires use of the Automation API, which is currently unsupported by the Java
      // library.

   .. code-block:: ruby

      # This example requires use of the Automation API, which is currently unsupported by
      # the Ruby library.


*******
Reports
*******


.. Message Response Report
   =======================

   This request retrieves the message response report for the given date range and precision:

   .. example-code::

      .. code-block:: bash

         curl "https://go.urbanairship.com/api/reports/responses/?start=2014-09-1%2010:00&end=2014-09-30%2020:00&precision=DAILY" \
            -u "<AppKey>:<MasterSecret>"

      .. code-block:: python

         # The Reports API is not currently supported by the Python library.

      .. code-block:: java

         // Coming soon

   .. code-block:: ruby

      # The Reports API is not currently supported by the Ruby library.


Response Listing
================

This request will list all pushes, plus associated basic information, in the given timeframe:

.. example-code::

   .. code-block:: bash

      curl "https://go.urbanairship.com/api/reports/responses/list?start=2014-05-05%2010:00&end=2014-05-15%2020:00" \
         -u "<AppKey>:<MasterSecret>"

   .. code-block:: python

      # The Reports API is not currently supported by the Python library.

   .. code-block:: java

      DateTime start = new DateTime(2014, 10, 1, 12, 0, 0, 0);
      DateTime end = start.plus(Period.hours(48));

      // Start and end date times are required parameters
      // Optional parameter: limit of 5
      // Optional parameter: begin with the id of "start_push"
      APIClientResponse<APIReportsListingResponse> response =
          client.listReportsResponseListing(start, end, Optional.of(5), Optional.of("start_push"));

      APIReportsListingResponse obj = response.getApiResponse();

      // Next page of responses, if available.
      String nextPage = obj.getNextPage();

      // List of detailed information about specific push notifications.
      List<SinglePushInfoResponse> listPushes = obj.getSinglePushInfoResponseObjects();

   .. code-block:: ruby

      # The Reports API is not currently supported by the Ruby library.


.. Push Sends Report
   =================

   This request retrieves the :ref:`push-sends-report` for the first two weeks of December 2014, with a daily
   precision:

   .. example-code::

      .. code-block:: bash

         curl "https://go.urbanairship.com/api/reports/sends/?start=2014-12-1&end=2014-12-14&precision=DAILY \
            -u "<AppKey>:<MasterSecret>"

      .. code-block:: python

         # The Reports API is not currently supported by the Python library.

      .. code-block:: java

         // Coming soon.

      .. code-block:: ruby

         # The Reports API is not currently supported by the Ruby library.


App Opens Report
================

This request retrieves the :ref:`app-opens-report` for the first two weeks of December 2014, with an hourly
precision:

.. example-code::

   .. code-block:: bash

      curl "https://go.urbanairship.com/api/reports/opens/?start=2014-12-1%2010:00&end=2014-12-14%2020:00&precision=HOURLY" \
         -u "<AppKey>:<MasterSecret>"

   .. code-block:: python

      # The Reports API is not currently supported by the Python library.

   .. code-block:: java

      DateTime start = new DateTime(2014, 12, 1, 20, 10, 0, 0);
      DateTime end = start.plus(Period.days(14));

      // Gets app opens from start to end by month.
      // Other possible values for precision are hourly and daily.
      APIClientResponse<ReportsAPIOpensResponse> response = client.listAppsOpenReport(start, end, "monthly");

      ReportsAPIOpensResponse obj = response.getApiResponse();

      // Returns a list of Open objects
      List<Opens> listOpens = obj.getObject();

      // Get first open object
      Open openObj = listOpens.get(0);

      // Get number of Android opens
      long android = openObj.getAndroid();

      // Get number of IOS opens
      long ios = openObj.getIos();

      // Get time corresponding to the result
      DateTime time = openObj.getDate();

   .. code-block:: ruby

      # The Reports API is not currently supported by the Ruby library.


Time in App Report
==================

This request retrieves the :ref:`time-in-app-report` for the first two weeks of December 2014, with a daily
precision:

.. example-code::

   .. code-block:: bash

      curl "https://go.urbanairship.com/api/reports/timeinapp/?start=2014-12-1&end=2014-12-14&precision=DAILY" \
         -u "<AppKey>:<MasterSecret>"

   .. code-block:: python

      # The Reports API is not currently supported by the Python library.

   .. code-block:: java

      DateTime start = new DateTime(2014, 12, 1, 0, 0, 0, 0);
      DateTime end = start.plus(Period.days(14));

      // Gets time in app report from start to end by month.
      // Other possible values for precision are hourly and daily.
      APIClientResponse<ReportsAPITimeInAppResponse> response = client.listTimeInAppReport(start, end, "monthly");

      ReportsAPITimeInAppResponse obj = response.getApiResponse();

      // Returns a list of TimeInApp objects
      List<TimeInApp> listTimeInApp = obj.getObject();

      // Get first TimeInApp object
      TimeInApp timeInAppObj = listTimeInApp.get(0);

      // Get amount of time in app for Android
      float android = timeInAppObj.getAndroid();

      // Get amount of time in app for iOS
      float ios = timeInAppObj.getIos();

      // Get time corresponding to the result.
      DateTime time = timeInAppObj.getDate();

   .. code-block:: ruby

      # The Reports API is not currently supported by the Ruby library.


.. Unique App Opens Report
   =======================

   This request retrieves the Unique App Opens Report for the first two weeks of December 2014, with a daily
   precision.

   .. example-code::

      .. code-block:: bash

         curl "https://go.urbanairship.com/api/reports/opens/?start=2014-12-1&end=2014-12-14&precision=DAILY" \
            -u "<AppKey>:<MasterSecret>"

      .. code-block:: python

         # The Reports API is not currently supported by the Python library.

      .. code-block:: java

         // todo (?)

      .. code-block:: ruby

         # The Reports API is not currently supported by the Ruby library.


.. Push Response Report
   ====================

   The following request will retrieve the :ref:`push response report <api-push-response>` for the first two
   weeks of December 2014, with a daily precision:

   .. example-code::

      .. code-block:: bash

         curl "https://go.urbanairship.com/api/reports/responses/?start=2014-12-1&end=2014-12-14&precision=DAILY" \
            -u "<AppKey>:<MasterSecret>"

      .. code-block:: python

         # The Reports API is not currently supported by the Python library.

      .. code-block:: java

         // todo (?)

      .. code-block:: ruby

         # The Reports API is not currently supported by the Ruby library.

.. Devices Report
   ==============

   The following request will retrieve the :ref:`devices report <device-counts-api>` up to August 29th:

   .. example-code::

      .. code-block:: bash

         curl "https://go.urbanairship.com/api/reports/devices/?date=2014-08-29" \
            -u "<AppKey>:<MasterSecret>"

      .. code-block:: python

         # The Reports API is not currently supported by the Python library.

      .. code-block:: java

         // todo (?)

      .. code-block:: ruby

         # The Reports API is not currently supported by the Ruby library.


Statistics
==========

The following request will retrieve :ref:`push statistics <statistics-api>` for the first 12 hours of
December 1, 2014:

.. example-code::

   .. code-block:: bash

      curl "https://go.urbanairship.com/api/push/stats/?start=2014-12-01&end=2014-12-01+12:00" \
         -u "<AppKey>:<MasterSecret>"

   .. code-block:: python

      # The Reports API is not currently supported by the Python library.

   .. code-block:: java

      DateTime start = new DateTime(2014, 12, 1, 0, 0, 0, 0);
      DateTime end = start.plus(Period.hours(12));

      // JSON result is deserialized to a list of AppStats objects
      APIClientResponse<List<AppStats>> response = client.listPushStatistics(start, end);

      // Get list of AppStat objects
      List<AppStats> listStats = response.getApiResponse();

      // Retrieve first object in list
      AppStats as = listStats.get(0);

      // Get the start date corresponding to this set of hourly counts
      DateTime start = as.getStart();

      // Get IOS counts
      int ios = as.getiOSCount();

      // Get BlackBerry counts
      int blackberry = as.getBlackBerryCount();

      // Get C2DM counts
      int c2dm = as.getC2DMCount();

      // Get GCM counts
      int gcm = as.getGCMCount();

      // Get Windows 8 counts
      int windows8 = as.getWindows8Count();

      // Get Windows Phone 8 counts
      int windowsPhone8 = as.getWindowsPhone8Count();

   .. code-block:: ruby

      # The Reports API is not currently supported by the Ruby library.


********
Segments
********


Retrieve Segment List
=====================

This request returns a list of all segments associated with the given app key:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/segments \
         -u "<AppKey>:<MasterSecret>" \
         -H "Content-Type: application/json" \
         -X GET

   .. code-block:: python

      import urbanairship as ua
      airship = ua.Airship("app_key", "master_secret")
      segment_list = ua.SegmentList(airship)

      for segment in segment_list:
         print(segment.display_name)

   .. code-block:: java

      APIClientResponse<APIListAllSegmentsResponse> response = apiClient.listAllSegments();

      // Get URL of next page of results, if available
      String nextPage = response.getApiResponse().getNextPage();

      // Get a list of SegmentInformation objects, each representing a separate segment
      List<SegmentInformation> segmentInformations = response.getApiResponse().getSegments();

   .. code-block:: ruby

      # The Segments API is not currently supported by the Ruby library.


Get Segment Info
================

This request will give the information associated with a given ``<SegmentID>``:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/segments/<SegmentID> \
         -u "<AppKey>:<MasterSecret>" \
         -H "Content-Type: application/json" \
         -X GET

   .. code-block:: python

      import urbanairship as ua

      airship = ua.Airship("app_key", "master_secret")
      segment = ua.Segment()
      segment.from_id(airship, "segment_id")

   .. code-block:: java

      // Request to fetch information about a particular segment by segment id
      APIClientResponse<AudienceSegment> response = apiClient.listSegment("<SegmentID>");

      // Get AudienceSegment object
      AudienceSegment obj = response.getApiResponse();

      // Get display name
      String displayName = obj.getDisplayName();

      // Get Operator
      Operator operator = obj.getRootOperator();

      // Get Predicate
      Predicate predicate = obj.getRootPredicate();

      // Get count
      long count = obj.getCount();

   .. code-block:: ruby

      # The Segments API is not currently supported by the Ruby library.

In particular, this request will return a JSON object with the segment criteria and display name.

Create a Segment
================

This request creates a segment with the display name "Green", and it consists of users with both the tag
"Yellow" and the tag "Blue":

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 7-12

      curl https://go.urbanairship.com/api/segments \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Content-Type: application/json" \
         -d '{
                "display_name": "Green",
                "criteria": {
                   "and": [
                      {"tag": "Yellow"},
                      {"tag": "Blue"}
                   ]
                }
             }'

   .. code-block:: python

      import urbanairship as ua

      airship = ua.Airship("app_key", "master_secret")
      segment = ua.Segment()
      segment.display_name = "Green"
      segment.criteria = ua.and_(
         ua.tag("Yellow"),
         ua.tag("Blue")
      )

   .. code-block:: java

      private TagPredicate buildTagPredicate(String tag) {
         return TagPredicateBuilder.newInstance().setTag(tag).build();
      }

      private TagPredicate buildTagPredicate(String tag, String tagClass) {
         return TagPredicateBuilder.newInstance().setTag(tag).setTagClass(tagClass).build();
      }

      public static void main(String[] args) {

         Operator op = Operator.newBuilder(OperatorType.AND)
            .addPredicate(buildTagPredicate("Green"))
            .addPredicate(buildTagPredicate("Blue"))
            .build();

         AudienceSegment segment = AudienceSegment.newBuilder()
            .setDisplayName(DateTime.now().toString())
            .setRootOperator(op)
            .build();

         HttpResponse response = apiClient.createSegment(segment);

         // Returns 201 on success
         int status = response.getStatusLine().getStatusCode();
      }

   .. code-block:: ruby

      # The Segments API is not currently supported by the Ruby library.

|

Create a Location-Based Segment
-------------------------------

The following request creates a segment that consists of devices that:

* Have been in San Francisco at some point over the past 3 months
* Have the tag ``dancer``

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 10-17

      curl https://go.urbanairship.com/api/segments \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Content-Type: application/json" \
         -d '{
                "display_name": "san_francisco_dancers"
                "criteria": {
                   "and": [
                      {
                         "location": {
                            "id": "4oFkxX7RcUdirjtaenEQIV"
                            "date": {
                               "recent": {
                                  "months": 3
                               }
                            }
                         },
                         { "tag": "dancer" }
                      }
                   ]
                }
             }'

   .. code-block:: python

      # The Location API is not currently supported by the Python Library

   .. code-block:: java

      DateTime end = new DateTime(new Date());
      String endString = DateTimeFormats.DAYS_FORMAT.print(end);
      DateTime start = end.minusDays(90);
      String startString = DateTimeFormats.DAYS_FORMAT.print(start);


      Operator op = Operator.newBuilder(OperatorType.AND)
         .addPredicate(new LocationPredicate(new com.urbanairship.api.segments.model.LocationIdentifier(LocationAlias.newBuilder()
            .setAliasType("city")
            .setAliasValue("san_francisco")
            .build()),
            new com.urbanairship.api.segments.model.DateRange(DateRangeUnit.DAYS, startString, endString), PresenceTimeframe.ANYTIME))
         // See the 'Create Segment' section, under the 'Segments' section, for a definition of `buildTagPredicate`
         .addPredicate(buildTagPredicate("dancer"))
         .build(),

      AudienceSegment segment = AudienceSegment.newBuilder()
         .setDisplayName(DateTime.now().toString())
         .setRootOperator(op)
         .build();

      HttpResponse response = apiClient.createSegment(segment);

      // Returns 201 on success
      int status = response.getStatusLine().getStatusCode();

   .. code-block:: ruby

      # The Segments API is not currently supported by the Ruby library.


.. _tg-example-segment-audience-lists:

Create a Segment with Audience Lists
------------------------------------

While the Segment Builder does not currently work with Audience Lists, you can create segments
that incorporate lists via the API. The following example pushes to devices on an :ref:`uploaded
<ug-uploaded-lists>` weekly circular list with the tag ``"pizza"``:

**Example (Uploaded):**

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 10-17

      curl https://go.urbanairship.com/api/segments \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Content-Type: application/json" \
         -d '{
                "display_name": "weekly_circular_pizza"
                "criteria": {
                   "and": [
                      { "tag": "pizza" },
                      { "static_list": "weekly_circular" }
                   ]
                }
             }'

   .. code-block:: python

      # The Static List API is not currently supported by the Python library.

   .. code-block:: java

      # The Static List API is not currently supported by the Java library.

   .. code-block:: ruby

      # The Segments API is not currently supported by the Ruby library.

Segments can also contain :ref:`Lifecycle Lists <ug-lifecycle-lists>`. In this case, the ``static_list``
key should have one of our :ref:`Lifecycle Lists <api-lifecycle-list-names>` as a value. The following
example pushes to all devices that:

* Have the tag ``"pizza"``
* Have opened the app in the past 7 days

**Example (Lifecycle):**

.. example-code::

   .. code-block:: bash
      :emphasize-lines: 10-17

      curl https://go.urbanairship.com/api/segments \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Content-Type: application/json" \
         -d '{
                "display_name": "last_app_open_7_pizza"
                "criteria": {
                   "and": [
                      { "tag": "pizza" },
                      { "static_list": "ua_app_open_last_7_days" }
                   ]
                }
             }'

   .. code-block:: python

      # The Static List API is not currently supported by the Python library.

   .. code-block:: java

      # The Static List API is not currently supported by the Java library.

   .. code-block:: ruby

      # The Segments API is not currently supported by the Ruby library.


Delete a Segment
================

This request will delete the segment associated with the given ``<SegmentID>``:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/segments/<SegmentID> \
         -u "<AppKey>:<MasterSecret>" \
         -X DELETE

   .. code-block:: python

      import urbanairship as ua

      airship = ua.Airship("app_key", "master_secret")
      segment = ua.Segment()
      segment.from_id(airship, "segment_id")
      segment.delete(airship)

   .. code-block:: java

      String id = "<SegmentID>";

      HttpResponse response = apiClient.deleteSegment(id);

      // Returns 204 on success
      int status = response.getStatusLine().getStatusCode();

   .. code-block:: ruby

      # The Segments API is not currently supported by the Ruby library.


********
Location
********

Get Location Boundary Information
=================================

There are several ways to get location boundary information.

**By name**:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/location/?q=Chicago \
         -X GET \
         -u "<AppKey>:<MasterSecret>" \
         -H "Content-Type: application/json"

   .. code-block:: python

      # The Location API is not currently supported by the Python library.

   .. code-block:: java

      APIClientResponse<APILocationResponse> response = apiClient.queryLocationInformation("Chicago");

   .. code-block:: ruby

      # The Location API is not currently supported by the Ruby library.

|

**By latitude and longitude** (note that the numbers are in the order *latitude, longitude*):

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/location/45.52,-122681944?type=city \
         -X GET \
         -u "<AppKey>:<MasterSecret>" \
         -H "Content-Type: application/json"

   .. code-block:: python

      # The Location API is not currently supported by the Python library.

   .. code-block:: java

      Point portland = Point.newBuilder()
         .setLatitude(45.52)
         .setLongitude(-122.681944)
         .build();

      APIClientResponse<APILocationResponse> response = client.queryLocationInformation(portland);

   .. code-block:: ruby

      # The Location API is not currently supported by the Ruby library.

|

**By bounding box**:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/location/32.5343,-124.4096,42.0095,-114.1308&type=province
         -X GET \
         -u "<AppKey>:<MasterSecret>" \
         -H "Content-Type: application/json"

   .. code-block:: python

       # The Location API is not currently supported by the Python library.

   .. code-block:: java

      BoundedBox california = new BoundedBox(Point.newBuilder()
         .setLatitude(32.5343)
         .setLongitude(-124.4096)
         .build(), Point.newBuilder()
            .setLatitude(42.0095)
            .setLongitude(-114.1308)
            .build());

      APIClientResponse<APILocationResponse> response = client.queryLocationInformation(california);

   .. code-block:: ruby

      # The Location API is not currently supported by the Ruby library.


***********
Named Users
***********


Association
===========

This example associates the given channel with the named user id, ``"user-id-1234"``:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/named_users/associate \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "channel_id": "89s3892b-0234-9023-d9a2-9023ad802a9s",
                "device_type": "ios",
                "named_user_id": "user-id-1234"
             }'

   .. code-block:: python

      import urbanairship as ua
      airship = ua.Airship('app_key', 'master_secret')

      named_user = ua.NamedUser(airship, 'user-id-1234')
      named_user.associate('89s3892b-0234-9023-d9a2-9023ad802a9s', 'ios')

   .. code-block:: java

      // The Named Users API is not currently supported by the Java library

   .. code-block:: ruby

      # The Named Users API is not currently supported by the Ruby library.


Disassociation
==============

This example disassociates a channel the the named user id, ``"user-id-1234"``:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/named_users/disassociate \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "channel_id": "89s3892b-0234-9023-d9a2-9023ad802a9s",
                "device_type": "ios",
                "named_user_id": "user-id-1234"
             }'

   .. code-block:: python

      import urbanairship as ua
      airship = ua.Airship('app_key', 'master_secret')

      named_user = ua.NamedUser(airship, 'user-id-1234')
      named_user.disassociate('89s3892b-0234-9023-d9a2-9023ad802a9s', 'ios')

   .. code-block:: java

      // The Named Users API is not currently supported by the Java library

   .. code-block:: ruby

      # The Named Users API is not currently supported by the Ruby library.


Lookup
======

This example looks up information on the single named user id, ``"user-id-1234"``:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/named_users/?id=user-id-1234 \
         -X GET \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -u "<AppKey>:<MasterSecret>"

   .. code-block:: python

      import urbanairship as ua
      airship = ua.Airship('app_key', 'master_secret')

      named_user = ua.NamedUser(airship, 'user-id-1234')
      user = named_user.lookup()

   .. code-block:: java

      // The Named Users API is not currently supported by the Java library

   .. code-block:: ruby

      # The Named Users API is not currently supported by the Ruby library.


Listing
=======

The following example lists *all* named users associated with an app:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/named_users \
         -X GET \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -u "<AppKey>:<MasterSecret>"

   .. code-block:: python

      import urbanairship as ua
      airship = ua.Airship('app_key', 'master_secret')
      named_user_list = ua.NamedUserList(airship)

      for user in named_user_list:
         print(user.named_user_id)

   .. code-block:: java

      // The Named Users API is not currently supported by the Java library

   .. code-block:: ruby

      # The Named Users API is not currently supported by the Ruby library.


Tags
====

In the example below, we add tags to a named user:

.. example-code::

   .. code-block:: bash

      curl https://go.urbanairship.com/api/named_users/tags \
         -X POST \
         -u "<AppKey>:<MasterSecret>" \
         -H "Accept: application/vnd.urbanairship+json; version=3" \
         -H "Content-Type: application/json" \
         -d '{
                "audience": {
                   "named_user_id": "user-id-1234"
                },
                "add": {
                   "crm": "business",
                   "other-group": ["puppies","kittens"]
                }
             }'

   .. code-block:: python

      import urbanairship as ua
      airship = ua.Airship('app_key', 'master_secret')
      named_user = ua.NamedUser(airship, 'named_user_id')

      named_user.tag('crm', add=['business'])
      named_user.tag('other-group', add=['puppies', 'kittens'])

   .. code-block:: java

      // The Named Users API is not currently supported by the Java library

   .. code-block:: ruby

      # The Named Users API is not currently supported by the Ruby library.

.. note::

   To remove tags, replace the ``"add"`` key with the ``"remove"`` key. To set tags, use
   the ``"set"`` key. A single request may contain an ``"add"`` key, a ``"remove"`` key,
   both an ``"add"`` and ``"remove"`` key, or a single ``"set"`` key.


.. Counts
   ======

   In the example below, we retrieve the number of named users registered to an application:

   .. warning::

      Large audiences show an error of ~1%, so counts above 1000 will be rounded to reflect this innacuracy.

   .. example-code::

      .. code-block:: bash

         curl https://go.urbanairship.com/api/named_users/tags \
            -X GET \
            -u "<AppKey>:<MasterSecret>"

      .. code-block:: python

         # The Named Users API is not currently supported by the Python library.

      .. code-block:: java

         // The Named Users API is not currently supported by the Java library
