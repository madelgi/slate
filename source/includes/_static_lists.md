# Static Lists

With the *Static List* API endpoint, you can easily target and manage lists of devices that are
defined in your systems outside of Urban Airship. Any list or grouping of devices for which the
canonical source of data about the members is *elsewhere* is a good candidate for Static Lists,
e.g., members of a customer loyalty program.

Getting started with Static Lists is easy. Simply:

1. Create your list in the Urban Airship system
2. Populate, update, view, delete lists
3. Push to lists using :ref:`audience-selectors`

Read below for the Static List API reference and see our :doc:`Static List
API Topic Guide </topic-guides/static-lists-api>` for further use-cases and examples.


## The List Object

```json
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
```

The list object contains eight attributes:

Parameter | Description
--------- | -----------
ok | (Bool) -
name | (String) The user-provided name of the list. Maximum length of 64 characters
description | (String) An optional user-provided description of the list. Maximum length of 00 characters
extra | (Object) An optional user-provided JSON map of string values associated with a list. A key has a maximum length of 64 characters, while a value can be up to 1024 characters. You may add up to 100 key-value pairs.
created | (String) The time the list was initially created, in UTC Timestamp form
last_updated | (String) The time the identifiers of the list were last updated successfully, in UTC timestamp form
channel_count | (Int) A count of resolved channel identifiers for the last uploaded and successfully processed identifier list.
status | (String) One of ``"ready"``, ``"processing"``, or ``"failure"``:

    *  ``"ready"`` - The list was processed successfully and ready for sending
    *  ``"processing"`` - The list is being processed
    *  ``"failure"`` - There was an error processing the last uploaded list


## Lifecycle List Names

Aside from uploading custom lists, you can send to one of Urban Airship's built-in Lifecycle
Lists.

<aside class="notice">
Before using Lifecycle Lists, you must activate them through the Dashboard. See the :ref:`User
Guide documentation <ug-lifecycle-lists>` for more information.
</aside>

The table below details the various Lifecycle Lists and the names used to refer to them within
the API:


List Type | Time Interval | List API Name
--------- | ------------- | -------------
First App Open | Last 7 days | ``ua_first_app_open_last_7_days``
First App Open | Last 30 days | ``ua_first_app_open_last_30_days``
Opened App | Yesterday | ``ua_app_open_last_1_day``
Opened App | Last 7 days | ``ua_app_open_last_7_days``
Opened App | Last 30 days | ``ua_app_open_last_30_days``
Sent Notification | Yesterday | ``ua_message_sent_last_1_day``
Sent Notification | Last 7 days | ``ua_message_sent_last_7_days``
Sent Notification | Last 30 days | ``ua_message_sent_last_30_days``
Direct Open | Yesterday | ``ua_direct_open_last_1_day``
Direct Open | Last 7 days | ``ua_direct_open_last_7_days``
Direct Open | Last 30 days | ``ua_direct_open_last_30_days``
Dormant | Yesterday | ``ua_has_not_opened_last_1_day``
Dormant | Last 7 days | ``ua_has_not_opened_last_7_days``
Dormant | Last 30 days | ``ua_has_not_opened_last_30_days``
Uninstalls | Yesterday | ``ua_uninstalls_last_1_day``
Uninstalls | Last 7 days | ``ua_uninstalls_last_7_days``
Rich Page Sent | Last 7 days | ``ua_message_center_sent_last_7_days``
Rich Page Sent | Last 30 days | ``ua_message_center_sent_last_30_days``
Rich Page View | Last 7 days | ``ua_message_center_view_last_7_days``
Rich Page View | Last 30 days | ``ua_message_center_view_last_30_days``



[id]: api-create-list:

## Create List

```http
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
```

Create a static list. The body of the request will contain several of the [list object]
(#the-list-object) parameters, but the actual list content will be provided by a second call
to the [upload endpoint](#upload-list).


### HTTP Request

``POST /api/lists/``

### Parameters

Parameter | Description
--------- | -----------
name | (Required) User-provided name of the list, consists of up to 64 URL-safe characters.
description | (Optional) User-provided description of the list.
extra | (Optional) A dictionary of string keys to arbitrary JSON values.


### Returns

```http
HTTP/1.1 200 OK
Content-Type: application/json
Location: https://go.urbanairship.com/api/lists/platinum_members

{
 "ok" : true
}
```


## Upload List

```http
PUT /api/lists/platinum_members/csv HTTP/1.1
Authorization: Basic <application authorization string>
Accept: application/vnd.urbanairship+json; version=3;
Content-Type: text/csv

alias,stevenh
alias,marianb
ios_channel,5i4c91s5-9tg2-k5zc-m592150z5634
named_user,SDo09sczvJkoiu
named_user,"gates,bill"
```

List target identifiers are specified or replaced with an upload to this endpoint. Uploads must
be newline delimited identifiers (text/CSV) as described in [RFC 4180]
(https://tools.ietf.org/html/rfc4180>), with commas as the delimiter. The CSV format is two
columns, ``identifier_type,identifier``:

* **identifier_type**: must be one of ``alias``, ``named_user``, ``ios_channel``,
  ``android_channel``, or ``amazon_channel``
* **identifier**: the associated identifier you wish to send to

The maximum number of ``identifier_type,identifier`` pairs that may be uploaded to a list is
10 million.

<aside class="notice">
"Content-Encoding: gzip" is supported (and recommended) on this endpoint to reduce network
traffic.
</aside>

### HTTP Request

``PUT /api/lists/(name)/csv``

### Returns

```http
HTTP/1.1 202 Accepted
Content-Type: application/json

{
 "ok" : true
}
```

Status Code | Description
----------- | -----------
202 Accepted | The list was uploaded successfully, and is now being processed.
400 Bad Request | This could mean one of several things, depending on the error code:

* **error_code 40002**: CSV contains too many identifiers.
* **error_code 40003**: CSV contains an entry with a column count other than 2.
* **error_code 40004**: CSV contains an invalid ``identifier_type``.
* **error_code 40005**: CSV contains a channel identifier that is not a valid UUID

**404 Not Found** – No list with the given name exists.


<aside class="warning">
If an attempt to upload a list times out due to a poor connection, you must re-upload the list
from scratch. Because we want to ensure that the entirety of a given list is successfully
uploaded, we do not support partial list uploads.
</aside>


## Update List


```http
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
```

Update the metadata of a static list. The body of the request will contain a [list
object](#the-list-object), though the ``name`` attribute could be omitted. If present, it must
match the ``name`` provided in the URL.

<aside class="notice">
If you are trying to update the list contents, please see the <a href="#upload-list">list
upload</a> endpoint. The ``update`` endpoint is used to update a list's metadata rather than
the actual list of device identifiers.
</aside>


### HTTP Request

``PUT /api/lists/(name)``


### Returns

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
 "ok" : true
}
```

Status Codes | Description
------------ | -----------
200 Created | The list metadata was updated successfully.
400 Bad Request | Malformed JSON payload.
400 Bad Request (error_code 40001) | Attempted list rename. List renaming is not allowed.
404 Not Found | No list with the given name exists.


## Individual List Lookup

```http
GET /api/lists/platinum_members/ HTTP/1.1
Authorization: Basic <master authorization string>
Accept: application/vnd.urbanairship+json; version=3;
```

Retrieve information about one static list, specified in the URL.

### HTTP Request

``GET /api/lists/(name)``


### Returns

```http
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
```

Return a [list object](#the-list-object).

<aside class="warning">
When looking up lists, the returned information may actually be a combination of values from
both the last uploaded list and the last successfully processed list. If you create a list
successfully, and then you update it and the processing step fails, then the list ``status``
will read ``"failed"``, but the ``channel_count`` and ``last_modified`` fields will contain
information on the last successfully processed list.
</aside>

## Lookup All Lists

```http
GET /api/lists HTTP/1.1
Authorization: Basic <master authorization string>
Accept: application/vnd.urbanairship+json; version=3;
Content-type: application/json
```

Retrieve information about all static lists. This call returns a paginated list of metadata
that will not contain the actual lists of users.

### HTTP Request

``GET /api/lists?start=(start of listing)&limit=(max number of elements)``

### Returns


```http
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
       "channel_count": 3145,
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
```

Returns a paginated array of list objects.


## Delete a List

```http
DELETE /api/lists/platinum_members/ HTTP/1.1
Authorization: Basic <master authorization string>
Accept: application/vnd.urbanairship+json; version=3;
```

> Responds with a ``204: No Content``.

```http
HTTP/1.1 204 No Content
```

Deletes a list.

<aside class="warning">
If you are attempting to update a current list by deleting it and then recreating it with
new data, stop and go to the <a href="#upload-list">upload endpoint</a>`. There is no need to
delete a list before uploading a new CSV file. Moreover, once you delete a list, you will
be unable to create a list with the same name as the deleted list.
</aside>


### HTTP Request

``POST /api/lists/(name)``
