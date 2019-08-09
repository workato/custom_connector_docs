{
  title: "Zuora",

  methods: {
    build_schema_from_metadata: lambda do |input|
      type_map = {
        "boolean" => "boolean",
        "date" => "date",
        "datetime" => "timestamp",
        "decimal" => "number",
        "int" => "number",
        "integer" => "number",
        "picklist" => nil
      }
      control_type_map = {
        "boolean" => "checkbox",
        "decimal" => "number",
        "int" => "number",
        "integer" => "number",
        "picklist" => "select"
      }

      input["metadata"].map do |field|
        type = field.dig("type", 0, "content!")
        field_var = {
          name: (name = field.dig("name", 0, "content!")),
          label: (label = field.dig("label", 0, "content!")),
          optional: if field.dig("name", 0, "content!") == "PaymentMethodId" &&
                      input["operation"] == "create"
                      false
                    elsif field.dig("name", 0, "content!") == "AccountId" &&
                      input["operation"] == "create"
                      false
                    elsif input["operation"] == "create"
                      field.dig("required", 0, "content!").include?("false")
                    end,
          type: type_map[type],
          control_type: control_type_map[type]
        }.compact
        field_prop = if ["picklist"].include? type
                       {
                         pick_list: field.
                                      dig("options", 0, "option").
                                      pluck("content!", "content!"),
                         toggle_hint: "Select from list",
                         toggle_field: {
                           name: name,
                           label: label,
                           toggle_hint: "Use custom value",
                           type: "string",
                           control_type: "text"
                         }
                       }
                     end || {}
        field_var.merge(field_prop)
      end
    end,

    get_object_fields: lambda do |input|
      fields = get("/v1/describe/#{input}").
                 response_format_xml.
                 dig("object", 0, "fields", 0, "field").
                 map do |option|
                   if option.dig("selectable", 0, "content!") == "true"
                     option.dig("name", 0, "content!")
                   end
                 end.compact
      if input.casecmp("invoice") == 0
        fields = fields.reject { |field| %w[BillRunId Body].include? field }
      end
      fields.join(', ')
    end,

    make_schema_builder_fields_sticky: lambda do |input|
      input.map do |field|
        if field[:properties].present?
          field[:properties] = call("make_schema_builder_fields_sticky",
                                    field[:properties])
        elsif field["properties"].present?
          field["properties"] = call("make_schema_builder_fields_sticky",
                                     field["properties"])
        end
        field[:sticky] = true
        field
      end
    end,

    object_sample_output: lambda do |input|
      fields = call("get_object_fields", input)
      post("/v1/action/query").
        payload("queryString" => "select #{fields} from #{input}",
                "conf" => { "batchSize" => 1 }).
        dig("records", 0) || {}
    end
  },

  connection: {
    fields: [
      {
        name: "client_id",
        hint: "Find more information " \
          "<a href='https://knowledgecenter.zuora.com/" \
          "CF_Users_and_Administrators/A_Administrator_Settings/Manage_Users" \
          "#Create_an_OAuth_Client_for_a_User' target='_blank'>here</a>",
        optional: false
      },
      {
        name: "client_secret",
        hint: "Find more information " \
          "<a href='https://knowledgecenter.zuora.com/" \
          "CF_Users_and_Administrators/A_Administrator_Settings/Manage_Users" \
          "#Create_an_OAuth_Client_for_a_User' target='_blank'>here</a>",
        optional: false,
        control_type: "password"
      },
      {
        name: "environment",
        hint: "Find more information <a href='https://jp.zuora.com" \
          "/api-reference/#section/Introduction/Endpoints' " \
          "target='_blank'>here</a>",
        control_type: "select",
        pick_list: [
          ["US Production", "rest"],
          ["US Sandbox", "rest.apisandbox"],
          ["US Performance Test", "rest.pt1"],
          ["EU Production", "rest.eu"],
          ["EU Sandbox", "rest.sandbox.eu"]
        ],
        optional: false
      },
      {
        name: "version",
        label: "Zoura SOAP API Version",
        hint: "WSDL Service Version e.g. 91.0, find " \
          "<a href='https://knowledgecenter.zuora.com/DC_Developers/" \
          "G_SOAP_API/Zuora_SOAP_API_Version_History' target='_blank'>" \
          "latest version</a>",
        optional: false
      }
    ],

    base_uri: lambda { |connection|
      "https://#{connection['environment']}.zuora.com"
    },

    authorization: {
      type: "custom_auth",

      acquire: lambda { |connection|
        {
          auth_token: post("https://#{connection['environment']}.zuora.com" \
            "/oauth/token").
                        payload(client_id: connection["client_id"],
                                client_secret: connection["client_secret"],
                                grant_type: "client_credentials").
                        request_format_www_form_urlencoded.
                        dig("access_token")
        }
      },

      refresh_on: [401],

      detect_on: [/"Success"\S*\:\s*false/],

      apply: lambda { |connection|
        headers('x-zuora-wsdl-version' => connection["version"],
                "Authorization" => "Bearer #{connection['auth_token']}")
      }
    }
  },

  test: ->(_connection) { post("/v1/connections") },

  object_definitions: {
    custom_action_input: {
      fields: lambda do |connection, config_fields|
        input_schema = parse_json(config_fields.dig("input", "schema") || "[]")

        [
          {
            name: "path",
            optional: false,
            hint:
              if (host = connection["environment"]).present?
                "Base URI is <b>https://#{host}.zuora.com</b> - " \
                  "path will be appended to this URI. Use absolute URI to " \
                  "override this base URI."
              end
          },
          (
            if %w[get delete].include?(config_fields['verb'])
              {
                name: "input",
                type: "object",
                control_type: "form-schema-builder",
                sticky: input_schema.blank?,
                label: "URL parameters",
                add_field_label: "Add URL parameter",
                properties: [
                  {
                    name: "schema",
                    extends_schema: true,
                    sticky: input_schema.blank?
                  },
                  (
                    if input_schema.present?
                      {
                        name: "data",
                        type: "object",
                        properties: call("make_schema_builder_fields_sticky",
                                         input_schema)
                      }
                    end
                  )
                ].compact
              }
            else
              {
                name: "input",
                type: "object",
                properties: [
                  {
                    name: "schema",
                    extends_schema: true,
                    schema_neutral: true,
                    control_type: "schema-designer",
                    sample_data_type: "json_input",
                    sticky: input_schema.blank?,
                    label: "Request body parameters",
                    add_field_label: "Add request body parameter"
                  },
                  (
                    if input_schema.present?
                      {
                        name: "data",
                        type: "object",
                        properties: input_schema.
                          each { |field| field[:sticky] = true }
                      }
                    end
                  )
                ].compact
              }
            end
          ),
          {
            name: "output",
            control_type: "schema-designer",
            sample_data_type: "json_http",
            extends_schema: true,
            schema_neutral: true,
            sticky: true
          }
        ]
      end
    },

    custom_action_output: {
      fields: lambda do |_connection, config_fields|
        parse_json(config_fields["output"] || "[]")
      end
    },

    record_output: {
      fields: lambda do |_connection, config|
        metadata = get("/v1/describe/#{config['object']}").
                     response_format_xml.
                     dig("object", 0, "fields", 0, "field").
                     select do |field|
                       field.dig("selectable", 0, "content!") == "true"
                     end || []

        call("build_schema_from_metadata",
             "metadata" => metadata,
             "operation" => "read")
      end
    },

    create_record: {
      fields: lambda do |_connection, config|
        metadata = get("/v1/describe/#{config['object']}").
                     response_format_xml.
                     dig("object", 0, "fields", 0, "field").
                     select do |field|
                       field.dig("createable", 0, "content!") == "true"
                     end || []

        call("build_schema_from_metadata",
             "metadata" => metadata,
             "operation" => "create")
      end
    },

    update_record: {
      fields: lambda do |_connection, config|
        metadata = get("/v1/describe/#{config['object']}").
                     response_format_xml.
                     dig("object", 0, "fields", 0, "field").
                     select do |field|
                       field.dig("updateable", 0, "content!") == "true"
                     end || []

        call("build_schema_from_metadata",
             "metadata" => metadata,
             "operation" => "update")
      end
    },

    search_record: {
      fields: lambda do |_connection, config|
        metadata = get("/v1/describe/#{config['object']}").
                     response_format_xml.
                     dig("object", 0, "fields", 0, "field").
                     select do |field|
                       field.dig("filterable", 0, "content!") == "true"
                     end || []
        if config["object"] == "AccountingPeriod"
          metadata = metadata.reject do |field|
                                field.dig("name", 0, "content!") == "Name"
                              end
        end
        call("build_schema_from_metadata",
             "metadata" => metadata,
             "operation" => "search")
      end
    }
  },

  actions: {
    # Custom action for Zuora
    custom_action: {
      description: "Custom <span class='provider'>action</span> " \
        "in <span class='provider'>Zuora</span>",
      help: "Build your own Zuora action with a HTTP request. <br>" \
        " <br> <a href='https://www.zuora.com/developer/api-reference/'" \
        " target='_blank'>Zuora API Documentation</a> ",

      execute: lambda do |_connection, input|
        verb = input["verb"]
        if %w[get post put patch delete].exclude?(verb)
          error("#{verb} not supported")
        end
        data = input.dig("input", "data").presence || {}

        case verb
        when "get"
          get(input["path"], data).
            after_error_response(/[3-9]\d\d/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        when "post"
          post(input["path"], data).
            after_error_response(/[3-9]\d\d/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        when "put"
          put(input["path"], data).
            after_error_response(/[3-9]\d\d/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        when "delete"
          delete(input["path"], data).
            after_error_response(/[3-9]\d\d/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        end
      end,

      config_fields: [{
        name: "verb",
        label: 'Request type',
        hint: 'Select HTTP method of the request',
        optional: false,
        control_type: "select",
        pick_list: %w[get post put delete].map { |v| [v.upcase, v] }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['custom_action_input']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["custom_action_output"]
      end
    },

    create_record: {
      description: "Create <span class='provider'>record</span> " \
        "in <span class='provider'>Zuora</span>",

      config_fields: [{
        name: "object",
        label: "Select object",
        optional: false,
        control_type: "select",
        pick_list: "object_list"
      }],

      input_fields: lambda do |object_definitions|
        object_definitions["create_record"].
          ignored("CreatedById", "CreatedDate", "UpdatedById", "Id",
                  "UpdatedDate")
      end,

      execute: lambda do |_connection, input|
        object = input.delete("object")
        {
          response: post("/v1/action/create",
                         objects: [input],
                         type: object)[0] || {}
        }
      end,

      output_fields: lambda do |_object_definitions|
        [{
          name: "response",
          type: "object",
          properties: [
            { name: "success", type: "boolean", control_type: "checkbox" },
            { name: "Id" },
            {
              name: "Errors",
              type: "array",
              of: "object",
              properties: [{ name: "Code" }, { name: "Message" }]
            }
          ]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          response: {
            "success" => "true",
            "Id" => "107bb8280175668b1f47e51710214497"
          }
        }
      end
    },

    update_record: {
      description: "Update <span class='provider'>record</span> " \
        "in <span class='provider'>Zuora</span>",

      config_fields: [{
        name: "object",
        label: "Select object",
        optional: false,
        control_type: "select",
        pick_list: "object_list"
      }],

      input_fields: lambda do |object_definitions|
        object_definitions["update_record"].
          required("Id").
          ignored("CreatedById", "CreatedDate", "UpdatedById", "UpdatedDate",
                  "EffectiveDate")
      end,

      execute: lambda do |_connection, input|
        object = input.delete("object")
        {
          response: post("/v1/action/update",
                         objects: [input],
                         type: object)[0] || {}
        }
      end,

      output_fields: lambda do
        [{
          name: "response",
          type: "object",
          properties: [
            { name: "success", type: "boolean",
              control_type: "checkbox" },
            { name: "Id" },
            {
              name: "Errors",
              type: "array",
              of: "object",
              properties: [{ name: "Code" }, { name: "Message" }]
            }
          ]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          response: {
            "success" => "true",
            "Id" => "107bb8280175668b1f47e51710214497"
          }
        }
      end
    },

    search_records: {
      description: "Search <span class='provider'>records</span> " \
        "in <span class='provider'>Zuora</span>",
      help: "Search will return results that match all your search " \
        "criteria (max 50).",

      config_fields: [{
        name: "object",
        label: "Select object",
        optional: false,
        control_type: "select",
        pick_list: "object_list"
      }],

      input_fields: lambda do |object_definitions|
        object_definitions["search_record"]
      end,

      execute: lambda do |_connection, input|
        object = input.delete("object")
        fields = call("get_object_fields", object)
        query_params = (input || []).map do |key, value|
          if ["Name"].include?(key)
            "#{key} like '#{value}'"
          else
            "#{key} = '#{value}'"
          end
        end.join(" and ")
        query_params = (query_params.blank? ? "" : "where " + query_params)
        query_string = "select #{fields} from #{object} #{query_params}"

        post("/v1/action/query",
             "queryString" => query_string,
             "conf" => { "batchSize" => 50 })
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "records",
          type: "array",
          of: "object",
          properties: object_definitions["record_output"]
        }]
      end,

      sample_output: lambda do |_connection, input|
        { records: [call("object_sample_output", input["object"])] }
      end
    }
  },

  triggers: {
    new_updated_record: {
      title: 'New/updated record',
      description: "New or updated <span class='provider'>record</span> in "\
        "<span class='provider'>Zuora</span>",

      config_fields: [{
        name: "object",
        label: "Select object",
        hint: "Select any standard or custom object, e.g. Account",
        optional: false,
        control_type: "select",
        pick_list: "object_list"
      }],

      input_fields: lambda do
        [{
          name: "since",
          label: "From",
          hint: "Get records created or updated since given " \
            "date/time. Leave empty to get records " \
            "created or updated one hour ago",
          sticky: true,
          type: "timestamp"
        }]
      end,

      poll: lambda do |_connection, input, closure|
        batch_size = 100
        closure ||= []
        last_modified = (closure[0] || input["since"] || 1.hour.ago).
                          to_time.utc.iso8601
        response = if (query_locator = closure[1])
                     post("/v1/action/queryMore",
                          "queryLocator" => query_locator,
                          "conf" => { "batchSize" => batch_size })
                   else
                     fields = call("get_object_fields", input["object"])
                     query_string = "select #{fields} " \
                                    "from #{input['object']} " \
                                    "where UpdatedDate >= '#{last_modified}'"

                     post("/v1/action/query",
                          "queryString" => query_string,
                          "conf" => { "batchSize" => batch_size })
                   end

        closure = if (more_pages = (response["done"] == false))
                    [last_modified, response["queryLocator"]]
                  else
                    [now, nil]
                  end

        {
          events: response["records"],
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: ->(object) { "#{object['Id']}@#{object['UpdatedDate']}" },

      output_fields: lambda do |object_definitions|
        object_definitions["record_output"]
      end,

      sample_output: lambda do |_connection, input|
        call("object_sample_output", input["object"])
      end
    }
  },

  pick_lists: {
    object_list: lambda do |_connection|
      select = get("/v1/describe/").
               response_format_xml.
               dig("objects", 0, "object").
               map do |field|
                 [field.dig("label", 0, "content!"),
                  field.dig("name", 0, "content!")]
               end
      object = select.reject do |item|
                               ["Journal Run",
                                "Journal Entry",
                                "Journal Entry Item",
                                "Subscription"].
                                 include? item[0]
                      end

      object
    end
  }
}
