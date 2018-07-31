{
  title: "Action Network",

  methods: {
    format_api_input_field_names: lambda do |input|
      if input.is_a?(Array)
        input.map do |array_value|
          call("format_api_input_field_names", array_value)
        end
      elsif input.is_a?(Hash)
        input.map do |key, value|
          value = call("format_api_input_field_names", value)
          { key.gsub("_colon_", ":") => value }
        end.inject(:merge)
      else
        input
      end
    end,

    format_api_output_field_names: lambda do |input|
      if input.is_a?(Array)
        input.map do |array_value|
          call("format_api_output_field_names",  array_value)
        end
      elsif input.is_a?(Hash)
        input.map do |key, value|
          value = call("format_api_output_field_names", value)
          { key.gsub(":", "_colon_") => value }
        end.inject(:merge)
      else
        input
      end
    end,

    format_schema_field_names: lambda do |input|
      input.map do |field|
        if field[:properties].present?
          field[:properties] = call("format_schema_field_names",
                                    field[:properties])
        end
        field[:name] = field[:name].gsub(":", "_colon_")
        field
      end
    end
  },

  connection: {
    fields: [{ name: "api_key", control_type: "password" }],

    authorization: {
      type: "api_key",

      apply: lambda do |connection|
        headers("OSDI-API-Token" => connection["api_key"])
      end
    },

    base_uri: ->(_connection) { "https://actionnetwork.org" }
  },

  test: ->(_connection) { get("/api/v2/forms") },

  object_definitions: {
    signature: {
      fields: lambda do |_connection, _config_fields|
        signature_fields = [
          { name: "identifiers", type: "array", of: "string" },
          { name: "created_date", type: "date_time" },
          { name: "modified_date", type: "date_time" },
          {
            name: "action_network:person_id",
            label: "Action network:person ID"
          },
          {
            name: "action_network:petition_id",
            label: "Action network:petition ID"
          },
          {
            name: "_links",
            type: "object",
            properties: [
              {
                name: "self",
                type: "object",
                properties: [{ name: "href", label: "href" }]
              },
              {
                name: "osdi:petition",
                label: "Osdi:petition",
                type: "object",
                properties: [{ name: "href", label: "href" }]

              },
              {
                name: "osdi:person",
                label: "Osdi:person",
                type: "object",
                properties: [{ name: "href", label: "href" }]
              }
            ]
          }
        ]

        call("format_schema_field_names", signature_fields)
      end
    },

    petition: {
      fields: lambda do |_connection, _config_fields|
        petition_fields = [
          { name: "identifiers", type: "array", of: "string" },
          { name: "origin_system" },
          { name: "created_date", type: "date_time" },
          { name: "modified_date", type: "date_time" },
          { name: "title" },
          { name: "description" },
          { name: "petition_text" },
          { name: "browser_url", label: "Browser URL" },
          { name: "featured_image_url", label: "Featured Image URL" },
          { name: "total_signatures", control_type: "number", type: "number" },
          {
            name: "target",
            type: "array",
            of: "object",
            properties: [{ name: "name" }]
          },
          {
            name: "action_network:hidden",
            label: "Action network:hidden",
            type: "boolean",
            toggle_hint: "Select from option list",
            toggle_field: {
              name: "action_network:hidden",
              label: "Action network:hidden",
              toggle_hint: "Use custom value",
              type: "string",
              control_type: "text"
            }
          },
          {
            name: "_embedded",
            type: "object",
            properties: [{
              name: "osdi:creator",
              label: "Osdi:creator",
              type: "object",
              properties: [
                { name: "given_name" },
                { name: "family_name" },
                { name: "identifiers", type: "array", of: "string" },
                { name: "created_date", type: "date_time" },
                { name: "modified_date", type: "date_time" },
                {
                  name: "email_addresses",
                  type: "array",
                  of: "object",
                  properties: [
                    {
                      name: "primary",
                      type: "boolean",
                      toggle_hint: "Select from option list",
                      toggle_field: {
                        name: "primary",
                        toggle_hint: "Use custom value",
                        type: "string",
                        control_type: "text"
                      }
                    },
                    { name: "address" },
                    { name: "status" }
                  ]
                },
                {
                  name: "postal_addresses",
                  type: "array",
                  of: "object",
                  properties: [
                    {
                      name: "primary",
                      type: "boolean",
                      toggle_hint: "Select from option list",
                      toggle_field: {
                        name: "primary",
                        toggle_hint: "Use custom value",
                        type: "string",
                        control_type: "text"
                      }
                    },
                    { name: "address_lines", type: "array", of: "string" },
                    { name: "locality" },
                    { name: "region" },
                    { name: "postal_code" },
                    { name: "country" },
                    { name: "language" },
                    {
                      name: "location",
                      type: "object",
                      properties: [
                        {
                          name: "latitude",
                          parse_output: "float_conversion",
                          type: "number",
                          control_type: "number"
                        },
                        {
                          name: "longitude",
                          parse_output: "float_conversion",
                          type: "number",
                          control_type: "number"
                        },
                        { name: "accuracy" }
                      ]
                    }
                  ]
                },
                { name: "languages_spoken", type: "array", of: "string" },
                {
                  name: "_links",
                  type: "object",
                  properties: [
                    {
                      name: "self",
                      type: "object",
                      properties: [{ name: "href", label: "href" }]
                    },
                    {
                      name: "osdi:attendances",
                      label: "Osdi:attendances",
                      type: "object",
                      properties: [{ name: "href", label: "href" }]
                    },
                    {
                      name: "osdi:signatures",
                      label: "Osdi:signatures",
                      type: "object",
                      properties: [{ name: "href", label: "href" }]
                    },
                    {
                      name: "osdi:submissions",
                      label: "Osdi:submissions",
                      type: "object",
                      properties: [{ name: "href", label: "href" }]
                    },
                    {
                      name: "osdi:donations",
                      label: "Osdi:donations",
                      type: "object",
                      properties: [{ name: "href", label: "href" }]
                    },
                    {
                      name: "osdi:outreaches",
                      label: "Osdi:outreaches",
                      type: "object",
                      properties: [{ name: "href", label: "href" }]
                    },
                    {
                      name: "osdi:taggings",
                      label: "Osdi:taggings",
                      type: "object",
                      properties: [{ name: "href", label: "href" }]
                    }
                  ]
                }
              ]
            }]
          },
          {
            name: "_links",
            type: "object",
            properties: [
              {
                name: "self",
                type: "object",
                properties: [{ name: "href", label: "href" }]
              },
              {
                name: "osdi:signatures",
                label: "Osdi:signatures",
                type: "object",
                properties: [{ name: "href", label: "href" }]
              },
              {
                name: "osdi:record_signature_helper",
                label: "Osdi:record signature helper",
                type: "object",
                properties: [{ name: "href", label: "href" }]
              },
              {
                name: "osdi:creator",
                label: "Osdi:creator",
                type: "object",
                properties: [{ name: "href", label: "href" }]
              },
              {
                name: "action_network:embed",
                label: "Action network:embed",
                type: "object",
                properties: [{ name: "href", label: "href" }]
              }
            ]
          }
        ]

        call("format_schema_field_names", petition_fields)
      end
    },

    submission: {
      fields: lambda do |_connection, _config_fields|
        submission_fields = [
          { name: "identifiers", type: "array", of: "string" },
          { name: "created_date", type: "date_time" },
          { name: "modified_date", type: "date_time" },
          { name: "action_network:person_id",
            label: "Action network:person ID" },
          { name: "action_network:form_id", label: "Action network:form ID" },
          {
            name: "_links",
            type: "object",
            properties: [
              {
                name: "self",
                type: "object",
                properties: [{ name: "href", label: "href" }]
              },
              {
                name: "osdi:form",
                label: "Osdi:form",
                type: "object",
                properties: [{ name: "href", label: "href" }]
              },
              {
                name: "osdi:person",
                label: "Osdi:person",
                type: "object",
                properties: [{ name: "href", label: "href" }]
              }
            ]
          }
        ]

        call("format_schema_field_names", submission_fields)
      end
    },

    form: {
      fields: lambda do |_connection, _config_fields|
        form_fields = [
          { name: "identifiers", type: "array", of: "string" },
          { name: "origin_system", label: "system" },
          { name: "created_date", type: "date_time" },
          { name: "modified_date", type: "date_time" },
          { name: "title" },
          {
            name: "total_submissions",
            control_type: "number",
            type: "number"
          },
          {
            name: "action_network:hidden",
            label: "Action network:hidden",
            type: "boolean",
            toggle_hint: "Select from option list",
            toggle_field: {
              name: "action_network:hidden",
              label: "Action network:hidden",
              toggle_hint: "Use custom value",
              type: "string",
              control_type: "text"
            }
          },
          {
            name: "_embedded",
            type: "object",
            properties: [{
              name: "osdi:creator",
              label: "Osdi:creator",
              type: "object",
              properties: [
                { name: "given_name" },
                { name: "family_name" },
                { name: "identifiers", type: "array", of: "string" },
                { name: "created_date", type: "date_time" },
                { name: "modified_date", type: "date_time" },
                {
                  name: "email_addresses",
                  type: "array",
                  of: "object",
                  properties: [
                    {
                      name: "primary",
                      type: "boolean",
                      toggle_hint: "Select from option list",
                      toggle_field: {
                        name: "primary",
                        toggle_hint: "Use custom value",
                        type: "string",
                        control_type: "text"
                      }
                    },
                    { name: "address" },
                    { name: "status" }
                  ]
                },
                {
                  name: "postal_addresses",
                  type: "array",
                  of: "object",
                  properties: [
                    {
                      name: "primary",
                      type: "boolean",
                      toggle_hint: "Select from option list",
                      toggle_field: {
                        name: "primary",
                        toggle_hint: "Use custom value",
                        type: "string",
                        control_type: "text"
                      }
                    },
                    {
                      name: "address_lines",
                      type: "array",
                      of: "string"
                    },
                    { name: "locality" },
                    { name: "region" },
                    { name: "postal_code" },
                    { name: "country" },
                    { name: "language" }
                  ]
                },
                { name: "languages_spoken", type: "array", of: "string" },
                {
                  name: "_links",
                  type: "object",
                  properties: [
                    {
                      name: "self",
                      type: "object",
                      properties: [{ name: "href", label: "href" }]
                    },
                    {
                      name: "osdi:attendances",
                      label: "Osdi:attendances",
                      type: "object",
                      properties: [{ name: "href", label: "href" }]
                    },
                    {
                      name: "osdi:signatures",
                      label: "Osdi:signatures",
                      type: "object",
                      properties: [{ name: "href", label: "href" }]
                    },
                    {
                      name: "osdi:submissions",
                      label: "Osdi:submissions",
                      type: "object",
                      properties: [{ name: "href", label: "href" }]
                    },
                    {
                      name: "osdi:donations",
                      label: "Osdi:donations",
                      type: "object",
                      properties: [{ name: "href", label: "href" }]
                    },
                    {
                      name: "osdi:outreaches",
                      label: "Osdi:outreaches",
                      type: "object",
                      properties: [{ name: "href", label: "href" }]
                    },
                    {
                      name: "osdi:taggings",
                      label: "Osdi:taggings",
                      type: "object",
                      properties: [{ name: "href", label: "href" }]
                    }
                  ]
                }
              ]
            }]
          },
          {
            name: "_links",
            type: "object",
            properties: [
              {
                name: "self",
                type: "object",
                properties: [{ name: "href", label: "href" }]
              },
              {
                name: "osdi:submissions",
                label: "Osdi:submissions",
                type: "object",
                properties: [{ name: "href", label: "href" }]
              },
              {
                name: "osdi:record_submissions_helper",
                label: "Osdi:record submissions helper",
                type: "object",
                properties: [{ name: "href", label: "href" }]
              },
              {
                name: "osdi:creator",
                label: "Osdi:creator",
                type: "object",
                properties: [{ name: "href", label: "href" }]
              },
              {
                name: "action_network:embed",
                label: "Action network:embed",
                type: "object",
                properties: [{ name: "href", label: "href" }]
              }
            ]
          }
        ]

        call("format_schema_field_names", form_fields)
      end
    }
  },

  triggers: {
    new_updated_form: {
      title: "New/updated form",
      description: "New or updated <span class='provider'>form</span> in "\
        "<span class='provider'>Action Network</span>",

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get forms created or updated since given date/time. "\
            "Leave empty to get forms created or updated one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, page|
        page ||= 1
        since = (input["since"].presence || 1.hour.ago).utc.iso8601
        response = call("format_api_output_field_names",
                        get("/api/v2/forms",
                            page: page,
                            filter: "modified_date gt '#{since}'")&.compact)
        {
          events: response.dig("_embedded", "osdi_colon_forms"),
          next_poll: response["total_pages"] > page ? page + 1 : nil,
          can_poll_more: response["total_pages"] > page
        }
      end,

      dedup: lambda do |form|
        form.dig("identifiers", 0) + "@" + form["modified_date"]
      end,

      output_fields: ->(object_definitions) { object_definitions["form"] },

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/v2/forms", per_page: 1, page: 1)&.compact)&.
          dig("_embedded", "osdi_colon_forms", 0) || {}
      end
    },

    new_updated_petition: {
      title: "New/updated petition",
      description: "New or updated <span class='provider'>petition</span> in "\
        "<span class='provider'>Action Network</span>",

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get petitions created or updated since given date/time. "\
            "Leave empty to get petitions created or updated one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, page|
        page ||= 1
        since = (input["since"].presence || 1.hour.ago).utc.iso8601
        response = call("format_api_output_field_names",
                        get("/api/v2/petitions",
                            page: page,
                            filter: "modified_date gt '#{since}'")&.compact)

        {
          events: response.dig("_embedded", "osdi_colon_petitions"),
          next_poll: response["total_pages"] > page ? page + 1 : nil,
          can_poll_more: response["total_pages"] > page
        }
      end,

      dedup: lambda do |petition|
        petition.dig("identifiers", 0) + "@" + petition["modified_date"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["petition"]
      end,

      sample_output: lambda do |_connection, _input|
        call("format_api_output_field_names",
             get("/api/v2/petitions", per_page: 1, page: 1)&.compact).
          dig("_embedded", "osdi_colon_petitions", 0) || {}
      end
    },

    new_updated_signature: {
      title: "New/updated signature",
      description: "New or updated <span class='provider'>signature"\
        "</span> in <span class='provider'>Action Network</span>",

      input_fields: lambda do |_object_definitions|
        [
          {
            name: "petition_id",
            label: "Petition title",
            hint: "Select the Petition",
            control_type: "select",
            pick_list: "petitions",
            optional: false,
            toggle_hint: "Petition Title",
            toggle_field: {
              name: "petition_id",
              label: "Petition ID",
              type: "string",
              control_type: "string",
              optional: false,
              toggle_hint: "Petition ID",
              hint: "Enter the Petition ID"
            }
          },
          {
            name: "since",
            label: "From",
            type: "timestamp",
            optional: true,
            sticky: true,
            hint: "Get signatures created or updated since given date/time. "\
              "Leave empty to get signatures created or updated one hour ago"
          }
        ]
      end,

      poll: lambda do |_connection, input, page|
        page ||= 1
        since = (input["since"].presence || 1.hour.ago).utc.iso8601
        response = call("format_api_output_field_names",
                        get("/api/v2/petitions/#{input['petition_id']}"\
                          "/signatures",
                            page: page,
                            filter: "modified_date gt '#{since}'")&.compact)

        {
          events: response.dig("_embedded", "osdi_colon_signatures"),
          next_poll: response["total_pages"] > page ? page + 1 : nil,
          can_poll_more: response["total_pages"] > page
        }
      end,

      dedup: lambda do |signature|
        signature.dig("identifiers", 0) + "@" + signature["modified_date"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["signature"]
      end,

      sample_output: lambda do |_connection, _input|
        petition_id = call("format_api_output_field_names",
                           get("/api/v2/petitions", per_page: 1, page: 1)
                           &.compact)&.
                      dig("_embedded", "osdi_colon_petitions", 0,
                           "identifiers", 0)&.
                      split(":")&.second
        if petition_id.present?
          call("format_api_output_field_names",
               get("/api/v2/petitions/#{petition_id}/signatures",
                   per_page: 1,
                   page: 1)&.compact)&.
            dig("_embedded", "osdi_colon_signatures", 0) || {}
        else
          {}
        end
      end
    },

    new_updated_submission: {
      title: "New/updated submission",
      description: "New or updated <span class='provider'>submission"\
        "</span> in <span class='provider'>Action Network</span>",

      input_fields: lambda do |_object_definitions|
        [
          {
            name: "form_id",
            label: "Form title",
            hint: "Select the Form",
            control_type: "select",
            pick_list: "forms",
            optional: false,
            toggle_hint: "Form Title",
            toggle_field: {
              name: "form_id",
              label: "Form ID",
              type: "string",
              control_type: "string",
              optional: false,
              toggle_hint: "Form ID",
              hint: "Enter the Form ID"
            }
          },
          {
            name: "since",
            label: "From",
            type: "timestamp",
            optional: true,
            sticky: true,
            hint: "Get submissions created or updated since given date/time. "\
              "Leave empty to get submissions created or updated one hour ago"
          }
        ]
      end,

      poll: lambda do |_connection, input, page|
        page ||= 1
        since = (input["since"].presence || 1.hour.ago).utc.iso8601
        response = call("format_api_output_field_names",
                        get("/api/v2/forms/#{input['form_id']}/submissions",
                            page: page,
                            filter: "modified_date gt '#{since}'")&.compact)

        {
          events: response.dig("_embedded", "osdi_colon_submissions"),
          next_poll: response["total_pages"] > page ? page + 1 : nil,
          can_poll_more: response["total_pages"] > page
        }
      end,

      dedup: lambda do |submission|
        submission.dig("identifiers", 0) + "@" + submission["modified_date"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["submission"]
      end,

      sample_output: lambda do |_connection, _input|
        form_id = call("format_api_output_field_names",
                       get("/api/v2/forms", per_page: 1, page: 1)&.compact).
                  dig("_embedded", "osdi_colon_forms", 0, "identifiers", 0).
                  split(":").second
        if form_id.present?
          call("format_api_output_field_names",
               get("/api/v2/forms/#{form_id}/submissions",
                   per_page: 1,
                   page: 1)&.compact).
            dig("_embedded", "osdi_colon_submissions", 0) || {}
        else
          {}
        end
      end
    }
  },

  pick_lists: {
    forms: lambda do |_connection|
      get("/api/v2/forms").
        dig("_embedded", "osdi:forms").
        map do |form|
          [form["title"], form.dig("identifiers", 0)&.split(":")&.second]
        end
    end,

    petitions: lambda do |_connection|
      get("/api/v2/petitions").
        dig("_embedded", "osdi:petitions").
        map do |petition|
          [petition["title"],
           petition.dig("identifiers", 0)&.split(":")&.second]
        end
    end
  }
}
