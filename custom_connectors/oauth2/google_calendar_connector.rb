{
  title: "Google Calendar",

  connection: {
    fields: [
      {
        name: "client_id",
        hint: "Find client ID " \
          "<a href='https://console.cloud.google.com/apis/credentials' " \
          "target='_blank'>here</a>",
        optional: false
      },
      {
        name: "client_secret",
        hint: "Find client secret " \
          "<a href='https://console.cloud.google.com/apis/credentials' " \
          "target='_blank'>here</a>",
        optional: false,
        control_type: "password"
      }
    ],

    authorization: {
      type: "oauth2",

      authorization_url: lambda do |connection|
        scopes = [
          "https://www.googleapis.com/auth/calendar",
          "https://www.googleapis.com/auth/calendar.readonly"
        ].join(" ")

        "https://accounts.google.com/o/oauth2/auth?client_id=" \
        "#{connection['client_id']}&response_type=code&scope=#{scopes}" \
        "&access_type=offline&include_granted_scopes=true&prompt=consent"
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
        response = post("https://accounts.google.com/o/oauth2/token").
                     payload(client_id: connection["client_id"],
                             client_secret: connection["client_secret"],
                             grant_type: "authorization_code",
                             code: auth_code,
                             redirect_uri: redirect_uri).
                     request_format_www_form_urlencoded
        [response, nil, nil]
      end,

      refresh: lambda do |connection, refresh_token|
        post("https://accounts.google.com/o/oauth2/token").
          payload(client_id: connection["client_id"],
                  client_secret: connection["client_secret"],
                  grant_type: "refresh_token",
                  refresh_token: refresh_token).
          request_format_www_form_urlencoded
      end,

      refresh_on: [401],

      detect_on: [/"errors"\:\s*\[/],

      apply: lambda do |_connection, access_token|
        headers("Authorization" => "Bearer #{access_token}")
      end
    },

    base_uri: lambda do |_connection|
      "https://www.googleapis.com"
    end
  },

  object_definitions: {
    event: {
      fields: lambda do
        [
          { name: "id" },
          { name: "status" },
          { name: "htmlLink", type: "string", control_type: "url" },
          { name: "created", type: "date_time", control_type: "date_time" },
          { name: "updated", type: "date_time", control_type: "date_time" },
          { name: "summary" },
          { name: "description" },
          { name: "location" },
          {
            name: "creator", type: "object", properties: [
              { name: "id" },
              { name: "email" },
              { name: "displayName" },
              { name: "self", type: "boolean" }
            ]
          },
          {
            name: "organizer", type: "object", properties: [
              { name: "id" },
              { name: "email" },
              { name: "displayName" },
              { name: "self", type: "boolean" }
            ]
          },
          {
            name: "start", type: "object", properties: [
              { name: "dateTime", type: "date_time", control_type: "date_time" }
            ]
          },
          {
            name: "end", type: "object", properties: [
              { name: "dateTime", type: "date_time", control_type: "date_time" }
            ]
          },
          { name: "endTimeUnspecified", type: "boolean" },
          { name: "recurrence", type: "array", properties: [] },
          { name: "recurringEventId" },
          {
            name: "originalStartTime", type: "object", properties: [
              { name: "dateTime", type: "date_time", control_type: "date_time" }
            ]
          },
          {
            name: "attendees", type: "array", of: "object", properties: [
              { name: "id" },
              { name: "email" },
              { name: "displayName" },
              { name: "self", type: "boolean" },
              { name: "organizer", type: "boolean" },
              { name: "resource", type: "boolean" },
              { name: "optional", type: "boolean" },
              { name: "responseStatus" },
              { name: "comment" },
              { name: "additionalGuests", type: "integer" }
            ]
          }
        ]
      end
    }
  },

  test: lambda do |_connection|
    get("/calendar/v3/users/me/settings?maxResults=1")
  end,

  triggers: {
    new_past_calendar_event: {
      description: "New past calendar <span class='provider'>event</span> in " \
        "<span class='provider'>Google Calendar</span>",
      help: "Trigger will pick up events that has ended within the specified " \
        "date range, if provided.",

      input_fields: lambda do
        [
          {
            name: "calendarId",
            label: "Calendar",
            hint: "Choose a calendar",
            type: "string",
            control_type: "select",
            pick_list: "calendars",
            optional: false,
            toggle_hint: "Select from list",
            toggle_field: {
              name: "calendarId",
              label: "Calendar ID",
              hint: "Input ID of calendar to monitor for events",
              type: "string",
              control_type: "text",
              toggle_hint: "Enter custom value",
              optional: false
            }
          },
          {
            name: "timeMin",
            label: "Ending after",
            type: "date_time",
            control_type: "date_time",
            hint: "Fetch events ending on or after this datetime. "\
                  "Defaults to recipe start if not entered."
          }
        ]
      end,

      poll: lambda do |_connection, input, next_page|
        input["timeMin"] = (input["timeMin"] || Time.now).utc.iso8601

        page = next_page || nil

        response =
          if page.present?
            get("/calendar/v3/calendars/#{input['calendarId']}/events").
              params(singleEvents: true,
                     orderBy: "startTime",
                     pageToken: page,
                     maxResults: 50,
                     timeMin: input["timeMin"],
                     timeMax: Time.now.utc.iso8601)
          else
            get("/calendar/v3/calendars/#{input['calendarId']}/events").
              params(singleEvents: true,
                     orderBy: "startTime",
                     maxResults: 50,
                     timeMin: input["timeMin"],
                     timeMax: Time.now.utc.iso8601)
          end

        events = []

        response["items"].each do |event|
          if event["end"].present? &&
             event["end"]["dateTime"].present? &&
             event["end"]["dateTime"].to_time <= Time.now.utc
            events << event
          end
        end

        {
          events: events,
          next_poll: response["nextPageToken"] || nil,
          can_poll_more: response["nextPageToken"].present?
        }
      end,

      dedup: lambda do |event|
        event["id"] + "@" + event.dig("end", "dateTime")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["event"]
      end,

      sample_output: lambda do
        calendar_id = get("/calendar/v3/users/me/calendarList").
                        dig("items", 0, "id")
        get("/calendar/v3/calendars/#{calendar_id}/events").dig("items", 0)
      end
    },

    new_cancelled_event: {
      # Undocumented restriction of updatedMin to the past 28 days.
      # Any date beyond this will return at 410 Gone error.
      description: "New cancelled <span class='provider'>event</span> in " \
        "<span class='provider'>Google Calendar</span>",
      help: "Trigger will pick up events that has been cancelled since the " \
        "specified time, if provided. Last updated date has to be within " \
        "reasonable range (past 4 weeks)",

      input_fields: lambda do
        [
          {
            name: "calendarId",
            label: "Calendar",
            hint: "Choose a calendar",
            type: "string",
            control_type: "select",
            pick_list: "calendars",
            optional: false,
            toggle_hint: "Select from list",
            toggle_field: {
              name: "calendarId",
              label: "Calendar ID",
              hint: "Input ID of calendar to monitor for events",
              type: "string",
              control_type: "text",
              toggle_hint: "Enter custom value",
              optional: false
            }
          },
          {
            name: "updatedMin",
            label: "Last Updated",
            type: "date_time",
            control_type: "date_time",
            hint: "Fetch events last updated on or after this datetime. " \
              "Defaults to recipe start if not entered.",
          }
        ]
      end,

      poll: lambda do |_connection, input, next_page|
        input["updatedMin"] = (input["updatedMin"] || Time.now).utc.iso8601

        page = next_page || nil

        response =
          if page.present?
            get("/calendar/v3/calendars/#{input['calendarId']}/events").
              params(showDeleted: true,
                     orderBy: "updated",
                     updatedMin: input["updatedMin"],
                     pageToken: page)
          else
            get("/calendar/v3/calendars/#{input['calendarId']}/events").
              params(showDeleted: true,
                     orderBy: "updated",
                     updatedMin: input["updatedMin"])
          end

        events = response["items"].
                   select { |event| event["status"] == "cancelled" }

        {
          events: events,
          next_poll: response["nextPageToken"] || nil,
          can_poll_more: response["nextPageToken"].present?
        }
      end,

      dedup: lambda do |event|
        event["id"] + "@" + event["updated"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["event"]
      end,

      sample_output: lambda do
        calendar_id = get("/calendar/v3/users/me/calendarList").
                        dig("items", 0, "id")
        get("/calendar/v3/calendars/#{calendar_id}/events").dig("items", 0)
      end
    }
  },

  pick_lists: {
    calendars: lambda do |_connection|
      get("/calendar/v3/users/me/calendarList")["items"].
        pluck("summary", "id")
    end
  }
}
