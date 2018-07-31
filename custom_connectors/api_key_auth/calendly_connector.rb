{
  title: "Calendly",

  connection: {
    fields: [
      {
        name: "api_key",
        hint: "You can find your API key " \
          "<a href='https://calendly.com/integrations' " \
          "target='_blank'>here</a>"
      }
    ],

    authorization: {
      type: "custom_auth",

      # Calendly uses header auth (X-Token: <api key>)
      credentials: lambda do |connection|
        headers("X-Token": connection["api_key"])
      end
    },

    base_uri: lambda do
      "https://calendly.com"
    end
  },

  object_definitions: {
    user: {
      fields: lambda do
        [
          { name: "id" },
          {
            name: "attributes",
            type: "object",
            properties: [
              { name: "name" },
              { name: "slug" },
              { name: "email", control_type: "email" },
              { name: "url", control_type: "url" },
              {
                name: "avatar",
                type: "object",
                properties: [
                  { name: "url", control_type: "url" }
                ]
              },
              { name: "created_at", type: "date_time" },
              { name: "updated_at", type: "date_time" }
            ]
          }
        ]
      end
    },

    event: {
      fields: lambda do
        [
          { name: "event" },
          { name: "time", type: "date_time" },
          {
            name: "payload",
            type: "object",
            properties: [
              {
                name: "event_type", type: "object", properties: [
                  { name: "kind" },
                  { name: "slug" },
                  { name: "name" },
                  { name: "duration", type: "integer" }
                ]
              },
              {
                name: "event", type: "object", properties: [
                  { name: "uuid" },
                  { name: "assigned_to", type: "array" },
                  {
                    name: "extended_assigned_to", type: "array", properties: [
                      { name: "name" },
                      { name: "email" },
                      { name: "primary", type: "boolean" }
                    ]
                  },
                  { name: "start_time", type: "date_time" },
                  { name: "start_time_pretty" },
                  { name: "invitee_start_time", type: "date_time" },
                  { name: "invitee_start_time_pretty" },
                  { name: "end_time", type: "date_time" },
                  { name: "end_time_pretty" },
                  { name: "invitee_end_time", type: "date_time" },
                  { name: "invitee_end_time_pretty" },
                  { name: "created_at", type: "date_time" },
                  { name: "location" },
                  { name: "canceled", type: "boolean" },
                  { name: "canceler_name" },
                  { name: "cancel_reason" },
                  { name: "canceled_at", type: "date_time" }
                ]
              },
              {
                name: "invitee", type: "object", properties: [
                  { name: "uuid" },
                  { name: "first_name" },
                  { name: "last_name" },
                  { name: "name" },
                  { name: "email", control_type: "email" },
                  { name: "timezone" },
                  { name: "created_at", type: "date_time" },
                  { name: "location" },
                  { name: "canceled", type: "boolean" },
                  { name: "canceler_name" },
                  { name: "cancel_reason" },
                  { name: "canceled_at", type: "date_time" }
                ]
              },
              {
                name: "questions_and_answers", type: "array", properties: [
                  { name: "question" },
                  { name: "answer" }
                ]
              },
              {
                name: "questions_and_responses", type: "object", properties: [
                  { name: "1_question" },
                  { name: "1_response" },
                  { name: "2_question" },
                  { name: "2_response" },
                  { name: "3_question" },
                  { name: "3_response" },
                  { name: "4_question" },
                  { name: "4_response" }
                ]
              },
              {
                name: "tracking", type: "object", properties: [
                  { name: "utm_campaign" },
                  { name: "utm_source" },
                  { name: "utm_medium" },
                  { name: "utm_content" },
                  { name: "utm_term" },
                  { name: "salesforce_uuid" }
                ]
              }
            ]
          }
        ]
      end
    },

    event_types: {
      fields: lambda do
        [
          {
            name: "data",
            type: "array",
            of: "object",
            properties: [
              { name: "type" },
              { name: "id" },
              {
                name: "attributes",
                type: "object",
                properties: [
                  { name: "name" },
                  { name: "description" },
                  { name: "duration", type: "number" },
                  { name: "slug" },
                  { name: "color" },
                  { name: "active", type: "boolean" },
                  { name: "created_at", type: "date_time" },
                  { name: "updated_at", type: "date_time" },
                  { name: "url", control_type: "url" }
                ]
              },
              {
                name: "relationships",
                type: "object",
                properties: [
                  {
                    name: "owner",
                    type: "object",
                    properties: [
                      {
                        name: "data",
                        type: "object",
                        properties: [
                          { name: "type" },
                          { name: "id" }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          },
          {
            name: "included",
            type: "array",
            of: "object",
            properties: [
              { name: "type" },
              { name: "id" },
              {
                name: "attributes",
                type: "object",
                properties: [
                  { name: "slug" },
                  { name: "name" },
                  { name: "email" },
                  { name: "url" },
                  { name: "timezone" },
                  {
                    name: "avatar",
                    type: "object",
                    properties: [
                      { name: "url" }
                    ]
                  },
                  { name: "created_at", type: "date_time" },
                  { name: "updated_at", type: "date_time" }
                ]
              }
            ]
          }
        ]
      end
    }
  },

  test: lambda do |_connection|
    get("/api/v1/echo")
  end,

  actions: {
    get_event_types: {
      description: "Get <span class='provider'>event types</span> " \
        "in <span class='provider'>Calendly</span>",

      input_fields: lambda do |_object_definitions|
      end,

      execute: lambda do |_connection, _input|
        get("/api/v1/users/me/event_types?include=owner")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["event_types"]
      end,

      sample_output: lambda do |_connection, _input|
        get("/api/v1/users/me/event_types?include=owner").
          params(per_page: 1) || []
      end
    }
  },

  triggers: {
    new_event: {
      description: "New <span class='provider'>event</span> " \
        "in <span class='provider'>Calendly</span>",
      input_fields: lambda do |_object_definitions|
        {
          name: "event",
          control_type: "select",
          pick_list: "event_type",
          optional: false
        }
      end,

      webhook_subscribe: lambda do |webhook_url, _connection, input|
        event_type = case input["event_type"]
                     when "invitee.created"
                       ["invitee.created"]
                     when "invitee.canceled"
                       ["invitee.canceled"]
                     else
                       ["invitee.created", "invitee.canceled"]
                     end

        post("/api/v1/hooks").
          payload(url: webhook_url, events: event_type)
      end,

      webhook_notification: lambda do |_input, payload|
        payload
      end,

      webhook_unsubscribe: lambda do |webhook|
        delete("/api/v1/hooks/#{webhook['id']}")
      end,

      dedup: lambda do |event|
        event["event"] + "@" + event["payload"]["event"]["uuid"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["event"]
      end,

      sample_output: lambda do |_connection, _input|
        {
          "event": "invitee.created",
          "time": "2018-03-14T19:16:01Z",
          "payload": {
            "event_type": {
              "uuid": "CCCCCCCCCCCCCCCC",
              "kind": "One-on-One",
              "slug": "event_type_name",
              "name": "Event Type Name",
              "duration": 15,
              "owner": {
                "type": "users",
                "uuid": "DDDDDDDDDDDDDDDD"
              }
            },
            "event": {
              "uuid": "BBBBBBBBBBBBBBBB",
              "assigned_to": [
                "Jane Sample Data"
              ],
              "extended_assigned_to": [
                {
                  "name": "Jane Sample Data",
                  "email": "user@example.com",
                  "primary": false
                }
              ],
              "start_time": "2018-03-14T12:00:00Z",
              "start_time_pretty": "12:00pm - Wednesday, March 14, 2018",
              "invitee_start_time": "2018-03-14T12:00:00Z",
              "invitee_start_time_pretty": "12:00pm - Wednesday, " \
              "March 14, 2018",
              "end_time": "2018-03-14T12:15:00Z",
              "end_time_pretty": "12:15pm - Wednesday, March 14, 2018",
              "invitee_end_time": "2018-03-14T12:15:00Z",
              "invitee_end_time_pretty": "12:15pm - Wednesday, March 14, 2018",
              "created_at": "2018-03-14T00:00:00Z",
              "location": "The Coffee Shop",
              "canceled": false,
              "canceler_name": "",
              "cancel_reason": "",
              "canceled_at": ""
            },
            "invitee": {
              "uuid": "AAAAAAAAAAAAAAAA",
              "first_name": "Joe",
              "last_name": "Sample Data",
              "name": "Joe Sample Data",
              "email": "not.a.real.email@example.com",
              "timezone": "UTC",
              "created_at": "2018-03-14T00:00:00Z",
              "is_reschedule": false,
              "payments": [
                {
                  "id": "ch_AAAAAAAAAAAAAAAAAAAAAAAA",
                  "provider": "stripe",
                  "amount": 1234.56,
                  "currency": "USD",
                  "terms": "sample terms of payment (up to 1,024 characters)",
                  "successful": true
                }
              ],
              "canceled": false,
              "canceler_name": "",
              "cancel_reason": "",
              "canceled_at": ""
            },
            "questions_and_answers": [
              {
                "question": "Skype ID",
                "answer": "fake_skype_id"
              },
              {
                "question": "Facebook ID",
                "answer": "fake_facebook_id"
              },
              {
                "question": "Twitter ID",
                "answer": "fake_twitter_id"
              },
              {
                "question": "Google ID",
                "answer": "fake_google_id"
              }
            ],
            "questions_and_responses": {
              "1_question": "Skype ID",
              "1_response": "fake_skype_id",
              "2_question": "Facebook ID",
              "2_response": "fake_facebook_id",
              "3_question": "Twitter ID",
              "3_response": "fake_twitter_id",
              "4_question": "Google ID",
              "4_response": "fake_google_id"
            },
            "tracking": {
              "utm_campaign": "",
              "utm_source": "",
              "utm_medium": "",
              "utm_content": "",
              "utm_term": "",
              "salesforce_uuid": ""
            },
            "old_event": "",
            "old_invitee": "",
            "new_event": "",
            "new_invitee": ""
          }
        }
      end
    }
  },

  pick_lists: {
    event_type: lambda do
      [
        # Display name, value
        %W[Event\ Created invitee.created],
        %W[Event\ Canceled invitee.canceled],
        %W[All\ Events all]
      ]
    end
  }
}
