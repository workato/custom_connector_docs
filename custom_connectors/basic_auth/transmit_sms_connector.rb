{
  title: "TransmitSMS",

  connection: {
    fields: [
      {
        name: "api_key",
        label: "API Key",
        hint: "Found in the <a href='https://usa.transmitsms.com/profile'>" \
          "SETTINGS</a> section of your transmitsms.com account.",
        optional: false
      },
      {
        name: "secret",
        control_type: "password",
        label: "API Secret",
        hint: "Found in the <a href='https://usa.transmitsms.com/profile'>" \
          "SETTINGS</a> section of your transmitsms.com account. If blank " \
          "enter a secret and click UPDATE PROFILE at the bottom of the page",
        optional: false
      }
    ],

    authorization: {
      type: "basic_auth",

      credentials: lambda do |connection|
        user(connection["api_key"])
        password(connection["secret"])
      end
    },

    base_uri: lambda do
      "https://api.transmitsms.com"
    end
  },

  test: lambda do |_connection|
    get("/get-balance.json")
  end,

  object_definitions: {
    # https://support.burstsms.com/hc/en-us/articles/202500828-send-sms
    format_number_request: {
      fields: lambda do |_connection|
        [
          {
            name: "to",
            type: "integer",
            control_type: "phone",
            label: "Recipient Mobile Number",
            optional: false
          },
          {
            name: "countrycode",
            control_type: "select",
            label: "Format number",
            hint: "Formats number given to international format. E.g. in " \
              "Australia, 0422222222 will become 6142222222",
            optional: false,
            pick_list: "countryList",
            toggle_hint: "Select country",
            toggle_field: {
              name: "countrycode",
              label: "Format number",
              type: "string",
              control_type: "text",
              optional: false,
              toggle_hint: "Use variable",
              hint: "Formats number given to international format. E.g. in " \
                "Australia, 0422222222 will become 6142222222"
            }
          }
        ]
      end
    },

    # https://support.burstsms.com/hc/en-us/articles/203098949-format-number
    format_number_response: {
      fields: lambda do |_connection|
        [
          {
            name: "error",
            type: "object",
            properties: [
              { name: "code", type: "string" },
              { name: "description", type: "string" }
            ]
          },
          {
            name: "number",
            type: "object",
            properties: [
              { name: "international", type: "integer" },
              { name: "countrycode", type: "integer" },
              { name: "isValid", type: "boolean" },
              { name: "national_leading_zeroes", type: "integer" },
              { name: "nationalnumber", type: "integer" },
              { name: "rawinput", type: "string" },
              { name: "type", type: "integer" }
            ]
          }
        ]
      end
    },

    # https://support.burstsms.com/hc/en-us/articles/202500828-send-sms
    send_sms_request: {
      fields: lambda do |_connection|
        [
          {
            name: "message",
            label: "Message body",
            type: "string",
            control_type: "text-area",
            optional: false
          },
          {
            name: "tracked_link_url",
            label: "Tracked link",
            type: "string",
            control_type: "url",
            optional: true,
            hint: "Add variable <b>[tracked-link]</b> to your <b>Message body</b> "\
              "to shorten and insert this link. Hits to this link can be tracked and also passed "\
              "via the 'Link Hit' trigger. Should be in the format `https://www.mydomain.com/`."
          },
          {
            name: "to",
            type: "integer",
            control_type: "phone",
            label: "Recipient mobile number",
            optional: false
          },
          {
            name: "countrycode",
            control_type: "select",
            label: "Format number",
            hint: "Formats number given to international format. E.g. in " \
              "Australia, 0422222222 will become 6142222222",
            optional: true,
            pick_list: "countryList",
            toggle_hint: "Select country",
            toggle_field: {
              name: "countrycode",
              label: "Format number",
              type: "string",
              control_type: "text",
              optional: true,
              toggle_hint: "Use variable",
              hint: "Formats number given to international format. E.g. in " \
              "Australia, 0422222222 will become 6142222222"
            }
          },
          {
            name: "virtual_number",
            control_type: "select",
            pick_list: "numbers",
            label: "Sender ID",
            hint: "Static mobile number as sender or alphanumeric if <a href" \
              "='https://support.burstsms.com/hc/en-us/articles/213656066-" \
              "Global-SMS-Delivery-List'>supported</a>. If left blank, " \
              "defaults to using shared number",
            optional: true,
            toggle_hint: "Select virtual number",
            toggle_field: {
              name: "sender_id",
              label: "Sender ID",
              type: "string",
              control_type: "text",
              optional: true,
              toggle_hint: "Use custom sender ID or variable",
              hint: "Static mobile number as sender or alphanumeric if <a " \
                "href='https://support.burstsms.com/hc/en-us/articles/" \
                "213656066-Global-SMS-Delivery-List'>supported</a>. If left " \
                "blank, defaults to using shared number"
            }
          }
        ]
      end
    },

    # https://support.burstsms.com/hc/en-us/articles/202500828-send-sms
    send_sms_response: {
      fields: lambda do |_connection|
        [
          {
            name: "results",
            type: "object",
            properties: [
              { name: "message_id", type: "integer" },
              { name: "send_at", type: "string" },
              { name: "recipients", type: "integer" },
              { name: "mobile", type: "integer" },
              { name: "cost", type: "number" },
              {
                name: "error",
                type: "object",
                properties: [
                  { name: "code", type: "string" },
                  { name: "description", type: "string" }
                ]
              },
              {
                name: "delivery_stats",
                type: "object",
                properties: [
                  { name: "delivered", type: "integer" },
                  { name: "pending", type: "integer" },
                  { name: "bounced", type: "integer" },
                  { name: "responses", type: "integer" },
                  { name: "optouts", type: "integer" }
                ]
              }
            ]
          }
        ]
      end
    },

    # https://support.burstsms.com/hc/en-us/articles/202500828-send-sms
    send_sms_list_request: {
      fields: lambda do |_connection|
        [
          {
            name: "list_id",
            control_type: "select",
            pick_list: "contactList",
            label: "Recipient list",
            optional: false
          },
          {
            name: "message",
            label: "Message body",
            type: "string",
            control_type: "text-area",
            optional: false
          },
          {
            name: "virtual_number",
            control_type: "select",
            pick_list: "numbers",
            label: "Sender ID",
            hint: "Static mobile number as sender or alphanumeric if <a " \
              "href='https://support.burstsms.com/hc/en-us/articles/" \
              "213656066-Global-SMS-Delivery-List'>supported</a>. If left " \
              "blank, defaults to using shared number",
            optional: true,
            toggle_hint: "Select virtual number",
            toggle_field: {
              name: "sender_id",
              label: "Sender ID",
              type: "string",
              control_type: "text",
              optional: true,
              toggle_hint: "Use custom sender ID or variable",
              hint: "Static mobile number as sender or alphanumeric if <a " \
                "href='https://support.burstsms.com/hc/en-us/articles/" \
                "213656066-Global-SMS-Delivery-List'>supported</a>. If left " \
                "blank, defaults to using shared number"
            }
          }
        ]
      end
    },

    # https://support.burstsms.com/hc/en-us/articles/203116337-HTTP-Callbacks
    sms_notification: {
      fields: lambda do |_connection|
        [
          {
            name: "message_id",
            type: "string",
            hint: "message unique identifier",
            optional: false
          },
          {
            name: "mobile",
            type: "string",
            hint: "Senders mobile"
          },
          {
            name: "response_id",
            type: "string",
            hint: "response unique identifier"
          },
          {
            name: "longcode",
            type: "string",
            hint: "The number message was delivered to"
          },
          {
            name: "datetime_entry",
            type: "string",
            hint: "Date/time of delivery. UTC."
          },
          {
            name: "response",
            hint: "Message text"
          },
          {
            name: "is_optout",
            hint: "Opt-out flag. yes or no"
          }
        ]
      end
    },

    # https://support.burstsms.com/hc/en-us/articles/203139007-add-to-list
    add_contact_to_list_request: {
      fields: lambda do |_connection, config_fields|
        if config_fields.blank?
          fields = []
        else
          fields = get("/get-list.json").
                   params("list_id": config_fields["list_id"])["fields"].
                   map do |key, value|
                     {
                       name: key,
                       type: "string",
                       label: value
                     }
                   end
        end

        fields << {
          name: "first_name",
          type: "string",
          label: "First name"
        }

        fields << {
          name: "last_name",
          type: "string",
          label: "Last name"
        }

        fields << {
          name: "to",
          type: "integer",
          control_type: "phone",
          label: "Recipient mobile number",
          optional: false
        }

        fields << {
          name: "countrycode",
          control_type: "select",
          label: "Country code",
          hint: "Formats number given to international format. E.g. in " \
            "Australia, 0422222222 will become 6142222222",
          optional: false,
          pick_list: "countryList",
          toggle_hint: "Select country",
          toggle_field: {
            name: "countrycode",
            label: "Format number",
            type: "string",
            control_type: "text",
            optional: false,
            toggle_hint: "Use variable",
            hint: "Formats number given to international format. E.g. in " \
              "Australia, 0422222222 will become 6142222222"
          }
        }
      end
    },

    # https://support.burstsms.com/hc/en-us/articles/203139007-add-to-list
    add_contact_to_list_response: {
      fields: lambda do |_connection, config_fields|
        if config_fields.blank?
          fields = []
        else
          fields = get("/get-list.json").
                   params("list_id": config_fields["list_id"])["fields"].
                   map do |_key, value|
                     { name: value, type: "string" }
                   end
        end

        fields << { name: "first_name", type: "string" }
        fields << { name: "last_name", type: "string" }
        fields << { name: "msisdn", label: "Mobile", type: "string" }
        fields << { name: "list_id", type: "string" }
      end
    },

    new_contact_notification: {
      fields: lambda do |_connection, config_fields|
        if config_fields.blank?
          fields = []
        else
          fields = get("/get-list.json").
                   params("list_id": config_fields["list_id"])["fields"].
                   map do |_key, value|
                     { name: value, type: "string" }
                   end
        end

        fields << { name: "type", type: "string" }
        fields << { name: "firstname", type: "string" }
        fields << { name: "lastname", type: "string" }
        fields << { name: "mobile", type: "string" }
        fields << { name: "list_id", type: "string" }
        fields << { name: "datetime_entry", type: "string" }
      end
    },

    # https://support.burstsms.com/hc/en-us/articles/202064463-delete-from-list
    delete_contact_to_list_request: {
      fields: lambda do |_connection|
        [
          {
            name: "list_id",
            control_type: "select",
            pick_list: "contactList",
            label: "Contact list",
            optional: false,
            hint: "List that contact is in"
          },
          {
            name: "to",
            type: "integer",
            control_type: "phone",
            label: "Contact number",
            optional: false
          },
          {
            name: "countrycode",
            control_type: "select",
            label: "Country code",
            hint: "Formats number given to international format. E.g. in " \
              "Australia, 0422222222 will become 6142222222",
            optional: false,
            pick_list: "countryList",
            toggle_hint: "Select country",
            toggle_field: {
              name: "countrycode",
              label: "Format number",
              type: "string",
              control_type: "text",
              optional: false,
              toggle_hint: "Use variable",
              hint: "Formats number given to international format. E.g. in " \
                "Australia, 0422222222 will become 6142222222"
            }
          }
        ]
      end
    },

    # https://support.burstsms.com/hc/en-us/articles/202064463-delete-from-list
    delete_contact_to_list_response: {
      fields: lambda do |_connection|
        [
          {
            name: "list_ids",
            type: "array", of: "integer",
            properties: []
          }
        ]
      end
    },

    # https://support.burstsms.com/hc/en-us/articles/360000158136-get-contact
    get_contact_response: {
      fields: lambda do |_connection, config_fields|
        if config_fields.blank?
          fields = []
        else
          fields = get("/get-list.json").
                   params("list_id": config_fields["list_id"])["fields"].
                   map do |key, _value|
                     { name: key, type: "string" }
                   end
        end

        fields << { name: "first_name", type: "string" }
        fields << { name: "last_name", type: "string" }
        fields << { name: "msisdn", label: "Mobile", type: "string" }
        fields << { name: "list_id", type: "string" }
        fields << { name: "created_at", type: "string" }
        fields << { name: "status", type: "string" }
        fields << {
          name: "error",
          type: "object",
          properties: [
            { name: "code", type: "string" },
            { name: "description", type: "string" }
          ]
        }
      end
    },

    # https://support.burstsms.com/hc/en-us/articles/202064243-get-responses
    get_sms_response: {
      fields: lambda do |_connection|
        [
          { name: "id", type: "integer" },
          { name: "message_id", type: "integer" },
          { name: "received_at", type: "string" },
          { name: "first_name", type: "string" },
          { name: "last_name", type: "string" },
          { name: "msisdn", label: "Mobile", type: "integer" },
          { name: "response", type: "string" },
          { name: "longcode", type: "integer" }
        ]
      end
    }
  },

  actions: {
    FormatNumber: {
      title: "Format number",
      description: "<span class='provider'>Formats</span> a single mobile " \
        "number in <span class='provider'>transmitsms.com</span>",
      help: "Automatically formats number to international format.",

      input_fields: lambda do |object_definitions|
        object_definitions["format_number_request"]
      end,

      execute: lambda do |_connection, input|
        format_number_input = {
          "msisdn" => input["to"]
        }
        if input["countrycode"].present?
          format_number_input["countrycode"] = input["countrycode"].
                                               to_country_alpha2
        end
        get("/format-number.json", format_number_input)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["format_number_response"]
      end
    },

    SendSMS: {
      title: "Send SMS",
      subtitle: "Send a single SMS message",
      description: "Sends a <span class='provider'>SMS</span> to a single " \
        "mobile number in <span class='provider'>transmitsms.com</span>",
      help: "Sends a SMS to a single number.",

      input_fields: lambda do |object_definitions|
        object_definitions["send_sms_request"]
      end,

      execute: lambda do |_connection, input|
        format_number_input = {
          "msisdn" => input["to"]
        }
        if input["countrycode"].present?
          format_number_input["countrycode"] = input["countrycode"].
                                               to_country_alpha2
        end
        number = get("/format-number.json", format_number_input)
        if number["number"].include?("isValid")
          from = input["virtual_number"] || input["sender_id"]
          results = get("/send-sms.json").
                    params(message: input["message"],
                           to: number["number"]["international"],
                           tracked_link_url: input["tracked_link_url"],
                           from: from)
          results["mobile"] = number["number"]["international"]
          { results: results }
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["send_sms_response"]
      end
    },

    SendSMSToList: {
      title: "Send SMS to list",
      subtitle: "Sends a SMS message to a list of contact",
      description: "Sends a <span class='provider'>SMS</span> to a list " \
        "of contacts in <span class='provider'>transmitsms.com</span>",
      help: "Sends a SMS to a list of contacts.",

      input_fields: lambda do |object_definitions|
        object_definitions["send_sms_list_request"]
      end,

      execute: lambda do |_connection, input|
        from = input["virtual_number"] || input["sender_id"]
        results = get("/send-sms.json").
                  params(message: input["message"],
                         list_id: input["list_id"],
                         from: from)
        { results: results }
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["send_sms_response"]
      end
    },

    AddContact: {
      title: "Add/Update contact",
      subtitle: "Add or update a contact",
      description: "Add or update a <span class='provider'>contact</span> " \
        "in <span class='provider'>transmitsms.com</span> list",

      config_fields: [
        {
          name: "list_id",
          control_type: "select",
          pick_list: "contactList",
          label: "Contact list",
          optional: false,
          hint: "List to add/update to"
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions["add_contact_to_list_request"]
      end,

      execute: lambda do |_connection, input|
        number = get("/format-number.json").
                 params(msisdn: input["to"],
                        countrycode: input["countrycode"].to_country_alpha2)
        if number["number"].include?("isValid")
          input["msisdn"] = number["number"]["international"]
          put("https://frontapi.transmitsms.com/zapier/add-to-list.json",
              input)
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["add_contact_to_list_response"]
      end
    },

    DeleteContact: {
      title: "Delete contact",
      subtitle: "Delete a contact from a list",
      description: "Delete a <span class='provider'>contact</span> " \
        "in <span class='provider'>transmitsms.com</span> list",

      input_fields: lambda do |object_definitions|
        object_definitions["delete_contact_to_list_request"]
      end,

      execute: lambda do |_connection, input|
        number = get("/format-number.json").
                 params(msisdn: input["to"],
                        countrycode: input["countrycode"].to_country_alpha2)

        if number["number"].include?("isValid")
          params = {
            "list_id" => input["list_id"],
            "msisdn" => number["number"]["international"]
          }
          put("https://frontapi.transmitsms.com/zapier/" \
            "delete-from-list.json", params)
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["delete_contact_to_list_response"]
      end
    },

    GetContact: {
      title: "Get contact",
      subtitle: "Get contact information from a list",
      description: "Gets <span class='provider'>contact</span> information " \
        "in <span class='provider'>transmitsms.com</span> list",

      config_fields: [
        {
          name: "list_id",
          control_type: "select",
          pick_list: "contactList",
          label: "Contact list",
          optional: false,
          hint: "List that the contact is in"
        }
      ],

      input_fields: lambda do |_object_definitions|
        [
          {
            name: "msisdn",
            type: "integer",
            control_type: "phone",
            label: "Recipient mobile number",
            optional: false
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/get-contact.json").
          params(msisdn: input["msisdn"],
                 list_id: input["list_id"])
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["get_contact_response"]
      end
    }
  },

  triggers: {
    new_message: {
      title: "New SMS received to virtual number",
      subtitle: "New SMS received to a specified virtual number",
      description: "New <span class='provider'>SMS</span> received to " \
        "virtual number <span class='provider'>transmitsms.com</span>",
      help: "Fetches new incoming SMS to a specified virtual number.",

      input_fields: lambda do |_object_definitions|
        [
          {
            name: "virtual_number",
            control_type: "select",
            pick_list: "numbers",
            label: "Virtual number",
            optional: false,
            hint: "Can be purchased in the NUMBERS section of your " \
              "transmitsms.com account"
          }
        ]
      end,

      type: :paging_desc,
      webhook_subscribe: lambda do |webhook_url, _connection, input|
        results = get("/edit-number-options.json").
                  params(number: input["virtual_number"],
                         forward_url: webhook_url)

        {
          id: results["id"],
          virtual_number: input["virtual_number"],
          secret: results["secret"]
        }
      end,

      webhook_notification: lambda do |_input, payload|
        payload
      end,

      webhook_unsubscribe: lambda do |webhook|
        get("/edit-number-options.json").
          params(number: webhook["virtual_number"],
                 forward_url: "")
      end,

      dedup: lambda do |messages|
        messages["response_id"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["sms_notification"]
      end
    },

    new_contact: {
      title: "New contact",
      subtitle: "New contact added to list",
      description: "New <span class='provider'>contact</span> added to " \
        "<span class='provider'>transmitsms.com</span> list",

      config_fields: [
        {
          name: "list_id",
          control_type: "select",
          pick_list: "contactList",
          label: "Contact list",
          optional: false,
          hint: "Choose the contact list to pick up new contacts from"
        }
      ],

      type: :paging_desc,
      webhook_subscribe: lambda do |webhook_url, _connection, input|
        results = get("/set-list-callback.json").
                  params(list_id: input["list_id"],
                         url: webhook_url)

        {
          id: results["id"],
          list_id: input["list_id"],
          secret: results["secret"]
        }
      end,

      webhook_notification: lambda do |_input, payload|
        if payload["type"] == "add"
          payload
        end
      end,

      webhook_unsubscribe: lambda do |webhook|
        get("/set-list-callback.json").
          params(list_id: webhook["list_id"],
                 url: "")
      end,

      dedup: lambda do |contact|
        contact["mobile"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["new_contact_notification"]
      end
    },

    GetSMSResponse: {
      title: "New SMS received to inbox",
      subtitle: "New SMS received in inbox",
      description: "New <span class='provider'>SMS</span> received in " \
        "inbox in <span class='provider'>transmitsms.com</span>",
      help: "Fetches new incoming messages from all virtual numbers under " \
        "user's account.",

      poll: lambda do |_connection, _input, page|
        page ||= 1
        response = get("https://frontapi.transmitsms.com/zapier/" \
                     "get-responses.json").
                   params(page: page,
                          max: 10)
        {
          events: response["responses"],
          next_page: page + 1,
          can_poll_more: response.dig("page", "count") <= page
        }
      end,

      dedup: lambda do |response|
        response["id"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["get_sms_response"]
      end
    }
  },

  pick_lists: {
    numbers: lambda do |_connection|
      vn = get("/get-numbers.json").
           params("page": 1,
                  "max": 100)
      if vn["numbers"].present?
        vn["numbers"].
          pluck("number", "number")
      end
    end,

    contactList: lambda do |_connection|
      cl = get("/get-lists.json").
           params("page": 1,
                  "max": 100)
      if cl["lists"].present?
        cl["lists"].
          pluck("name", "id")
      end
    end,

    countryList: lambda do |_connection|
      [
        %w[Australia AU],
        %w[New\ Zealand NZ],
        %w[United\ Kingdom GB],
        %w[United\ States US],
        %w[Singapore SG]
      ]
    end
  }
}
