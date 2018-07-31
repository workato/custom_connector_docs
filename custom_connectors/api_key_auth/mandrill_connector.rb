{
  title: "Mandrill",

  connection: {
    fields: [
      {
        name: "api_key",
        label: "API key",
        control_type: "password",
        hint: "You may find the API key <a href='https://mandrillapp.com" \
          "/settings' target='_blank'>here</a>",
        optional: false
      }
    ],

    authorization: {
      type: "api_key",

      acquire: ->(_connection) {},

      refresh_on: [/"name"\:\s*"Invalid_Key"/],

      detect_on: [
        /"status"\:\s*"error"/,
        /"reject_reason"\:"*"/,
        /"status"\:\s*"invalid"/
      ],

      apply: ->(connection) { payload(key: connection["api_key"]) }
    },

    base_uri: ->(_connection) { "https://mandrillapp.com" }
  },

  test: ->(_connection) { post("/api/1.0/users/ping.json") },

  object_definitions: {
    send_template: {
      fields: lambda { |_connection, config_fields|
        template_variables = if config_fields.blank?
                               []
                             else
                               post("/api/1.0/templates/info.json").
                                 payload(name: config_fields["template_name"]).
                                 dig("code").
                                 scan(/mc:edit=\"([^\"]*)\"/).
                                 map do |var|
                                   {
                                     name: var.first,
                                     hint: "Include html tags for better " \
                                      "formatting"
                                   }
                                 end
                             end

        if template_variables.blank?
          []
        else
          [{
            name: "template_content",
            type: "object",
            properties: template_variables
          }]
        end.concat([
                     {
                       name: "message",
                       optional: false,
                       type: "object",
                       properties: [
                         {
                           name: "from_email",
                           hint: "The sender email address",
                           optional: false
                         },
                         {
                           name: "from_name",
                           hint: "The sender name"
                         },
                         {
                           name: "to",
                           hint: "List of email recipients, one per line.",
                           optional: false
                         },
                         {
                           name: "important",
                           hint: "Whether or not this message is important, " \
                             "and should be delivered ahead of non-important " \
                             "messages.",
                           control_type: "checkbox",
                           type: "boolean"
                         },
                         {
                           name: "track_opens",
                           hint: "Whether or not to turn on open tracking " \
                             "for the message",
                           control_type: "checkbox",
                           type: "boolean"
                         },
                         {
                           name: "track_clicks",
                           hint: "Whether or not to turn on click tracking " \
                             "for the message",
                           control_type: "checkbox",
                           type: "boolean"
                         }
                       ]
                     },
                     {
                       name: "send_at",
                       hint: "When this message should be sent. If you " \
                         "specify a time in the past, the message will be " \
                         "sent immediately.",
                       type: "timestamp"
                     }
                   ])
      }
    }
  },

  actions: {
    send_message: {
      description: "Send <span class='provider'>message</span> using " \
        "template in <span class='provider'>Mandrill</span>",

      config_fields: [
        {
          name: "template_name",
          control_type: "select",
          pick_list: "templates",
          optional: false
        }
      ],

      input_fields: lambda { |object_definitions|
        object_definitions["send_template"]
      },

      execute: lambda { |_connection, input|
        input["template_content"] = (input["template_content"] || []).
                                    map do |key, val|
                                      { name: key, content: val }
                                    end
        input["message"]["to"] = (input["message"]["to"] || "").
                                 split("\n").
                                 map { |to| { email: to.strip } }
        if input["send_at"].present?
          input["send_at"] = input["send_at"].
                             to_time.
                             utc.
                             strftime("%Y-%m-%d %H:%M:%S.%6N")
        end

        post("/api/1.0/messages/send-template.json", input).dig(0) || {}
      },

      output_fields: lambda { |_object_definitions|
        [{ name: "email" },
         { name: "status" },
         { name: "_id" }]
      },

      sample_output: lambda {
        {
          email: "mail@workato.com",
          status: "send",
          _id: "abc123abc123abc123abc123abc123"
        }
      }
    }
  },

  pick_lists: {
    templates: lambda { |_connection|
      post("/api/1.0/templates/list.json").pluck("name", "slug")
    }
  }
}
