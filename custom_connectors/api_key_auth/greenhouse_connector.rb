{
  title: "Greenhouse",

  connection: {
    fields: [
      {
        name: "api_key",
        control_type: "password",
        optional: false,
        label: "API key",
        hint: "Find your API key <a href='https://app2.greenhouse.io/" \
          "configure/dev_center/credentials'>here</a>"
      },
      {
        name: "usermail",
        control_type: "text",
        optional: false,
        label: "User Email",
        hint: "User email the API Key is generated from"
      }
    ],

    authorization: {
      type: "api_key",

      credentials: lambda do |connection|
        user(connection['api_key'])
        password("")
      end
    },

    base_uri: lambda do
      "https://harvest.greenhouse.io"
    end
  },

  object_definitions: {
    candidate: {
      # https://developers.greenhouse.io/harvest.html#the-candidate-object
      fields: lambda do |_|
        custom_fields = get("/v1/custom_fields").
                        params(field_type: "candidate").
                        select { |e|
                          e["field_type"] == "candidate" &&
                            e["private"] == false &&
                            e["active"] == true
                        }.
                        map do |field|
          type = field["value_type"]
          case type
          when "short_text"
            { name: field["name_key"], type: "string", control_type: "text",
              label: field["name"], optional: !field["required"] }
          when "long_text"
            { name: field["name_key"], type: "string",
              control_type: "text-area", label: field["name"],
              optional: !field["required"] }
          when "yes_no"
            { name: field["name_key"], type: "boolean",
              control_type: "checkbox", label: field["name"],
              optional: !field["required"] }
          when "date"
            { name: field["name_key"], type: "date", control_type: "date",
              label: field["name"], optional: !field["required"] }
          when "url"
            { name: field["name_key"], type: "string", control_type: "url",
              label: field["name"], optional: !field["required"] }
          when "user"
            { name: field["name_key"], type: "string", control_type: "text",
              label: field["name"], optional: !field["required"] }
          when "single_select"
            select_values = field["custom_field_options"].
                            map do |ob|
                              [ob["name"], ob["name"]]
                            end
            { name: field["name_key"], control_type: "select",
              label: field["name"], optional: !field["required"],
              pick_list: select_values,
              toggle_hint: field["name"],
              toggle_field: {
                name: field["name_key"],
                label: field["name"],
                type: :string,
                control_type: "text",
                optional: false,
                toggle_hint: "Use custom value"
              } }
          when "multi_select"
            multiselect_values = field["custom_field_options"].
                                 map do |ob|
                                   [ob["name"], ob["name"]]
                                 end
            { name: field["name_key"], control_type: "multiselect",
              label: field["name"], optional: !field["required"],
              pick_list: multiselect_values,
              pick_list_params: {},
              delimiter: ",",
              toggle_hint: field["name"],
              toggle_field: {
                name: field["name_key"],
                label: field["name"],
                type: :string,
                control_type: "text",
                optional: !field["required"],
                toggle_hint: "Use custom value"
              } }
          else
            { name: field["name_key"], type: "string", control_type: "text",
              label: field["name"], optional: !field["required"] }
          end
        end

        standard_fields = [
          { name: "id", type: "integer", control_type: "number",
            label: "Candidate id" },
          { name: "first_name" },
          { name: "last_name" },
          { name: "company",
            hint: "The company at which the candidate currently works" },
          { name: "title", hint: "The candidate’s current title" },
          { name: "created_at", type: "date_time", control_type: "date_time" },
          { name: "updated_at", type: "date_time", control_type: "date_time" },
          { name: "last_activity", type: "date_time",
            control_type: "date_time" },
          { name: "is_private", type: "boolean", control_type: "checkbox",
            hint: "Yes if candidate is private, No if not" },
          { name: "photo_url", control_type: "url" },
          { name: "attachments", type: "array", of: "object", properties: [
            { name: "filename" },
            { name: "url" },
            { name: "type",
              control_type: "select",
              pick_list: "attachments_type",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "type",
                label: "type",
                type: "string",
                control_type: "text",
                toggle_hint: "Use custom value"
              } }
          ] },
          { name: "application_ids", type: "array", of: "integer",
            properties: [],
            hint: "Array of application IDs associated with this candidate" },
          { name: "phone_numbers", type: "array", of: "object", properties: [
            { name: "value" },
            { name: "type",
              control_type: "select",
              pick_list: "phone_type",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "type",
                label: "type",
                type: "string",
                control_type: "text",
                toggle_hint: "Use custom value"
              } }
          ] },
          { name: "addresses", type: "array", of: "object", properties: [
            { name: "value" },
            { name: "type",
              control_type: "select",
              pick_list: "address_type",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "type",
                label: "type",
                type: "string",
                control_type: "text",
                toggle_hint: "Use custom value"
              } }
          ] },
          { name: "email_addresses", type: "array", of: "object", properties: [
            { name: "value" },
            { name: "type",
              control_type: "select",
              pick_list: "email_type",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "type",
                label: "type",
                type: "string",
                control_type: "text",
                toggle_hint: "Use custom value"
              } }
          ] },
          { name: "website_addresses", type: "array", of: "object",
            properties: [
              { name: "value" },
              { name: "type",
                control_type: "select",
                pick_list: "website_type",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "type",
                  label: "type",
                  type: "string",
                  control_type: "text",
                  toggle_hint: "Use custom value"
                } }
            ] },
          { name: "social_media_addresses", type: "object", properties: [
            { name: "value" }
          ] },
          { name: "recruiter", type: "object", properties: [
            { name: "id", type: "integer", control_type: "number" },
            { name: "first_name" },
            { name: "last_name" },
            { name: "name" },
            { name: "employee_id" }
          ] },
          { name: "coordinator", type: "object", properties: [
            { name: "id", type: "integer", control_type: "number" },
            { name: "first_name" },
            { name: "last_name" },
            { name: "name" },
            { name: "employee_id" }
          ] },
          { name: "tags", type: "array", of: "string", properties: [] },
          { name: "applications", type: "array", of: "object", properties: [
            { name: "id", type: "integer", control_type: "number" },
            { name: "candidate_id", type: "integer", control_type: "number" },
            { name: "prospect", type: "boolean", control_type: "checkbox" },
            { name: "applied_at", type: "date_time",
              control_type: "date_time" },
            { name: "rejected_at", type: "date_time",
              control_type: "date_time" },
            { name: "last_activity_at", type: "date_time",
              control_type: "date_time" },
            { name: "location", type: "object", properties: [
              { name: "address" }
            ] },
            { name: "source", type: "object", properties: [
              { name: "id", type: "integer", control_type: "number" },
              { name: "public_name" }
            ] },
            { name: "credited_to", type: "object", properties: [
              { name: "id", type: "integer", control_type: "number" },
              { name: "first_name" },
              { name: "last_name" },
              { name: "name" },
              { name: "employee_id" }
            ] },
            { name: "rejection_reason", type: "object", properties: [
              { name: "id", type: "integer", control_type: "number" },
              { name: "name" },
              { name: "type", type: "object", properties: [
                { name: "id", type: "integer", control_type: "number" },
                { name: "name" }
              ] }
            ] },
            # Rejection details
            { name: "jobs", type: "array", of: "object", properties: [
              { name: "id", type: "integer", control_type: "number" },
              { name: "name" }
            ] },
            { name: "status" },
            { name: "current_stage", type: "object", properties: [
              { name: "id", type: "integer", control_type: "number" },
              { name: "name" }
            ] },
            { name: "answers", type: "array", of: "object", properties: [
              { name: "question" },
              { name: "answer" }
            ] },
            { name: "prospect_detail", type: "object", properties: [
              { name: "prospect_pool", type: "object", properties: [
                { name: "id", type: "integer", control_type: "number" },
                { name: "name" }
              ] },
              { name: "prospect_stage", type: "object", properties: [
                { name: "id", type: "integer", control_type: "number" },
                { name: "name" }
              ] },
              { name: "prospect_owner", type: "object", properties: [
                { name: "id", type: "integer", control_type: "number" },
                { name: "name" }
              ] }
              # Custom_fields, keyed custom fields (prospect endpoint) missing.
            ] }
          ] },
          { name: "educations", type: "array", of: "object", properties: [
            { name: "id", type: "integer", control_type: "number" },
            { name: "school_name" },
            { name: "degree" },
            { name: "discipline" },
            { name: "start_date", type: "date_time",
              control_type: "date_time" },
            { name: "end_date", type: "date_time",
              control_type: "date_time" }
          ] },
          { name: "employments", type: "array", of: "object", properties: [
            { name: "id", type: "integer", control_type: "number" },
            { name: "company_name" },
            { name: "title" },
            { name: "start_date", type: "date_time",
              control_type: "date_time" },
            { name: "end_date", type: "date_time", control_type: "date_time" }
          ] },
          { name: "custom_fields", type: "object", properties: custom_fields }
          # Keyed custom fields
        ]
        standard_fields
      end
    },

    add_prospect: {
      # https://developers.greenhouse.io/harvest.html#post-add-prospect
      fields: lambda do |_|
        custom_fields = get("/v1/custom_fields").
                        params(field_type: "candidate").
                        select { |e|
                          e["field_type"] == "candidate" &&
                            e["private"] == false &&
                            e["active"] == true
                        }.
                        map do |field|
          type = field["value_type"]
          case type
          when "short_text"
            { name: field["name_key"], type: "string",
              control_type: "text", label: field["name"],
              optional: !field["required"] }
          when "long_text"
            { name: field["name_key"], type: "string",
              control_type: "text-area", label: field["name"],
              optional: !field["required"] }
          when "yes_no"
            { name: field["name_key"], type: "boolean",
              control_type: "checkbox", label: field["name"],
              optional: !field["required"] }
          when "date"
            { name: field["name_key"], type: "date",
              control_type: "date", label: field["name"],
              optional: !field["required"] }
          when "url"
            { name: field["name_key"], type: "string",
              control_type: "url", label: field["name"],
              optional: !field["required"] }
          when "user"
            { name: field["name_key"], type: "string",
              control_type: "text", label: field["name"],
              optional: !field["required"] }
          when "single_select"
            select_values = field["custom_field_options"].
                            map do |ob|
                              [ob["name"], ob["name"]]
                            end
            { name: field["name_key"], control_type: "select",
              label: field["name"], optional: !field["required"],
              pick_list: select_values,
              toggle_hint: field["name"],
              toggle_field: {
                name: field["name_key"],
                label: field["name"],
                type: :string,
                control_type: "text",
                optional: false,
                toggle_hint: "Use custom value"
              } }
          when "multi_select"
            multiselect_values = field["custom_field_options"].
                                 map do |ob|
                                   [ob["name"], ob["name"]]
                                 end
            { name: field["name_key"], control_type: "multiselect",
              label: field["name"], optional: !field["required"],
              pick_list: multiselect_values,
              pick_list_params: {},
              delimiter: ",",
              toggle_hint: field["name"],
              toggle_field: {
                name: field["name_key"],
                label: field["name"],
                type: :string,
                control_type: "text",
                optional: !field["required"],
                toggle_hint: "Use custom value"
              } }
          else
            { name: field["name_key"], type: "string", control_type: "text",
              label: field["name"], optional: !field["required"] }
          end
        end

        standard_fields = [
          { name: "first_name", optional: false },
          { name: "last_name", optional: false },
          { name: "company",
            hint: "The company at which the candidate currently works" },
          { name: "title", hint: "The candidate’s current title" },
          { name: "is_private", type: "boolean", control_type: "checkbox" },
          { name: "phone_numbers", type: "array", of: "object", properties: [
            { name: "value" },
            { name: "type",
              control_type: "select",
              pick_list: "phone_type",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "type",
                label: "type",
                type: "string",
                control_type: "text",
                toggle_hint: "Use custom value"
              } }
          ] },
          { name: "addresses", type: "array", of: "object", properties: [
            { name: "value" },
            { name: "type",
              control_type: "select",
              pick_list: "address_type",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "type",
                label: "type",
                type: "string",
                control_type: "text",
                toggle_hint: "Use custom value"
              } }
          ] },
          { name: "email_addresses", type: "array", of: "object", properties: [
            { name: "value", control_type: "email" },
            { name: "type",
              control_type: "select",
              pick_list: "email_type",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "type",
                label: "type",
                type: "string",
                control_type: "text",
                toggle_hint: "Use custom value"
              } }
          ] },
          { name: "website_addresses", type: "array", of: "object",
            properties: [
              { name: "value" },
              { name: "type",
                control_type: "select",
                pick_list: "website_type",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "type",
                  label: "type",
                  type: "string",
                  control_type: "text",
                  toggle_hint: "Use custom value"
                } }
            ] },
          { name: "social_media_addresses", type: "object", properties: [
            { name: "value" }
          ] },
          { name: "source", type: "object", properties: [
            { name: "id", type: "integer", control_type: "number" },
            { name: "public_name" }
          ] },
          { name: "educations", type: "array", of: "object", properties: [
            { name: "school_id", type: "integer", control_type: "number" },
            { name: "discipline_id", type: "integer", control_type: "number" },
            { name: "degree_id", type: "integer", control_type: "number" },
            { name: "start_date", type: "date_time",
              control_type: "date_time" },
            { name: "end_date", type: "date_time", control_type: "date_time" }
          ] },
          { name: "employments", type: "array", of: "object", properties: [
            { name: "id", type: "integer", control_type: "number" },
            { name: "company_name" },
            { name: "title" },
            { name: "start_date", type: "date_time",
              control_type: "date_time" },
            { name: "end_date", type: "date_time", control_type: "date_time" }
          ] },
          { name: "tags", type: "array", of: "string", properties: [] },
          { name: "application", type: "object", properties: [
            { name: "job_ids", type: "array", of: "integer",
              control_type: "number" },
            { name: "source_id", type: "integer", control_type: "number" },
            { name: "referrer", type: "object", properties: [
              { name: "type" },
              { name: "value", type: "integer", control_type: "number" }
            ] }
          ] },
          { name: "custom_fields", type: "object", properties: custom_fields },
          { name: "recruiter", type: "object", properties: [
            { name: "id", label: "ID", type: "integer", control_type: "number",
              hint: "Either ID or email must be present" },
            { name: "email", type: "string", control_type: "email",
              hint: "Either ID or email must be present" }
          ] },
          { name: "coordinator", type: "object", properties: [
            { name: "id", label: "ID", type: "integer", control_type: "number",
              hint: "Either ID or email must be present" },
            { name: "email", type: "string", control_type: "email",
              hint: "Either ID or email must be present" }
          ] },
          { name: "activity_feed_notes", type: "array", of: "object",
            properties: [
              { name: "notes", type: "array", of: "object", properties: [
                { name: "id", label: "Note Id" },
                { name: "created_at", type: "date_time",
                  control_type: "date_time" },
                { name: "body", type: "string", control_type: "text-area" },
                { name: "user", type: "object", properties: [
                  { name: "id", type: "integer", control_type: "number" },
                  { name: "first_name" },
                  { name: "last_name" },
                  { name: "name" },
                  { name: "employee_id" }
                ] },
                { name: "private", type: "boolean", control_type: "checkbox" },
                { name: "visibility" }
              ] }
            ] }
        ]
        standard_fields
      end
    },

    create_candidate: {
      # https://developers.greenhouse.io/harvest.html#post-add-candidate
      fields: lambda do |_|
        custom_fields = get("/v1/custom_fields/candidate").
                        select { |e|
                          e["field_type"] == "candidate" &&
                            e["private"] == false &&
                            e["active"] == true
                        }.
                        map do |field|
          type = field["value_type"]
          case type
          when "short_text"
            { name: field["name_key"], type: "string", control_type: "text",
              label: field["name"], optional: !field["required"] }
          when "long_text"
            { name: field["name_key"], type: "string",
              control_type: "text-area",
              label: field["name"], optional: !field["required"] }
          when "yes_no"
            { name: field["name_key"], type: "boolean",
              control_type: "checkbox", label: field["name"],
              optional: !field["required"], toggle_hint: field["name"],
              toggle_field: {
                name: field["name_key"],
                label: field["name"],
                type: :string,
                control_type: "text",
                optional: !field["required"],
                toggle_hint: "Use custom value"
              } }
          when "date"
            { name: field["name_key"], type: "date", control_type: "date",
              label: field["name"], optional: !field["required"] }
          when "url"
            { name: field["name_key"], type: "string", control_type: "url",
              label: field["name"], optional: !field["required"] }
          when "user"
            { name: field["name_key"], type: "string", control_type: "text",
              label: field["name"], optional: !field["required"] }
          when "single_select"
            select_values = field["custom_field_options"].
                            map do |ob|
                              [ob["name"], ob["name"]]
                            end
            { name: field["name_key"], control_type: "select",
              label: field["name"], optional: !field["required"],
              pick_list: select_values,
              toggle_hint: field["name"],
              toggle_field: {
                name: field["name_key"],
                label: field["name"],
                type: :string,
                control_type: "text",
                optional: !field["required"],
                toggle_hint: "Use custom value"
              } }
          when "multi_select"
            multiselect_values = field["custom_field_options"].
                                 map do |ob|
                                   [ob["name"], ob["name"]]
                                 end
            puts multiselect_values
            { name: field["name_key"], control_type: "multiselect",
              label: field["name"], optional: !field["required"],
              pick_list: multiselect_values,
              pick_list_params: {},
              delimiter: ",",
              toggle_hint: field["name"],
              toggle_field: {
                name: field["name_key"],
                label: field["name"],
                type: :string,
                control_type: "text",
                optional: !field["required"],
                toggle_hint: "Use custom value"
              } }
          else
            { name: field["name_key"], type: "string", control_type: "text",
              label: field["name"], optional: !field["required"] }
          end
        end

        standard_fields = [
          { name: "first_name" },
          { name: "last_name" },
          { name: "company",
            hint: "The company at which the candidate currently works" },
          { name: "title", hint: "The candidate’s current title" },
          { name: "is_private",
            type: "boolean",
            control_type: "checkbox",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "is_private",
              label: "type",
              type: "string",
              control_type: "text",
              toggle_hint: "Use custom value",
              hint: "Possible values: <code>true</code> / <code>false</code> "
            } },
          { name: "phone_numbers", type: "array", of: "object", properties: [
            { name: "value" },
            { name: "type",
              control_type: "select",
              pick_list: "phone_type",
              hint: "Type is required when you pass value",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "type",
                label: "type",
                type: "string",
                control_type: "text",
                hint: "Type is required when you pass value",
                toggle_hint: "Use custom value"
              } }
          ] },
          { name: "addresses", type: "array", of: "object", properties: [
            { name: "value" },
            { name: "type",
              control_type: "select",
              pick_list: "address_type",
              hint: "Type is required when you pass value",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "type",
                label: "type",
                type: "string",
                control_type: "text",
                hint: "Type is required when you pass value",
                toggle_hint: "Use custom value"
              } }
          ] },
          { name: "email_addresses", type: "array", of: "object", properties: [
            { name: "value" },
            { name: "type",
              control_type: "select",
              pick_list: "email_type",
              hint: "Type is required when you pass value",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "type",
                label: "type",
                type: "string",
                control_type: "text",
                hint: "Type is required when you pass value",
                toggle_hint: "Use custom value"
              } }
          ] },
          { name: "website_addresses", type: "array", of: "object",
            properties: [
              { name: "value" },
              { name: "type",
                control_type: "select",
                pick_list: "website_type",
                hint: "Type is required when you pass value",
                toggle_hint: "Select from list",
                toggle_field: {
                  name: "type",
                  label: "type",
                  type: "string",
                  control_type: "text",
                  hint: "Type is required when you pass value",
                  toggle_hint: "Use custom value"
                } }
            ] },
          { name: "social_media_addresses", type: "array", of: "object",
            properties: [
              { name: "value" }
            ] },
          { name: "educations", type: "array", of: "object", properties: [
            { name: "school_id", type: "integer", control_type: "number" },
            { name: "discipline_id", type: "integer", control_type: "number" },
            { name: "degree_id", type: "integer", control_type: "number" },
            { name: "start_date", type: "date_time",
              control_type: "date_time" },
            { name: "end_date", type: "date_time", control_type: "date_time" }
          ] },
          { name: "employments", type: "array", of: "object", properties: [
            { name: "id", type: "integer", control_type: "number" },
            { name: "company_name" },
            { name: "title" },
            { name: "start_date", type: "date_time",
              control_type: "date_time" },
            { name: "end_date", type: "date_time", control_type: "date_time" }
          ] },
          { name: "tags", type: "array", of: "string",
            hint: "provide comma separated list of tags" },
          { name: "recruiter", type: "object", properties: [
            { name: "id", type: "integer", control_type: "number",
              hint: "Either ID or email must be present" },
            { name: "email",
              hint: "Either ID or email must be present" }
          ] },
          { name: "coordinator", type: "object", properties: [
            { name: "id", type: "integer", control_type: "number" },
            { name: "email" }
          ] },
          { name: "applications", optional: false, type: "array", of: "object",
            properties: [
              { name: "job_id", optional: false, type: "integer",
                control_type: "number" }
            ] },
          { name: "custom_fields", type: "object", properties: custom_fields }
          # Custom_fields[]
        ]
        standard_fields
      end
    },

    application: {
      fields: lambda do |_|
        standard_fields = [
          { name: "id", label: "Application ID" },
          { name: "candidate_id", type: "integer", control_type: "number" },
          { name: "prospect", type: "boolean", control_type: "checkbox",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "prospect",
              label: "Prospect",
              type: :string,
              control_type: "text",
              optional: true,
              toggle_hint: "Use custom value"
            } },
          { name: "applied_at", type: "date_time", control_type: "date_time" },
          { name: "rejected_at", type: "date_time",
            control_type: "date_time" },
          { name: "last_activity_at", type: "date_time",
            control_type: "date_time" },
          { name: "location", type: "object", properties: [
            { name: "address" }
          ] },
          { name: "source", type: "object", properties: [
            { name: "id", type: "integer", control_type: "number" },
            { name: "public_name" }
          ] },
          { name: "credited_to", type: "object", properties: [
            { name: "id", label: "User ID", type: "integer",
              control_type: "number" },
            { name: "first_name" },
            { name: "last_name" },
            { name: "name" },
            { name: "employee_id" }
          ] },
          { name: "rejection_reason", type: "object", properties: [
            { name: "id", type: "integer", control_type: "number" },
            { name: "name" },
            { name: "type", type: "object", properties: [
              { name: "id", type: "integer", control_type: "number" },
              { name: "name" }
            ] }
          ] },
          # Rejection details
          { name: "jobs", type: "array", of: "object", properties: [
            { name: "id", type: "integer", control_type: "number" },
            { name: "name" }
          ] },
          { name: "status", control_type: "select",
            pick_list: [
              %w[Active active],
              %w[Rejected rejected],
              %w[Hired hired]
            ],
            toggle_hint: "Select from list",
            toggle_field: {
              name: "status",
              label: "Status",
              type: :string,
              control_type: "text",
              optional: true,
              toggle_hint: "Use custom value"
            } },
          { name: "current_stage", type: "object", properties: [
            { name: "id", type: "integer", control_type: "number" },
            { name: "name" }
          ] },
          { name: "answers", type: "array", of: "object", properties: [
            { name: "question" },
            { name: "answer" }
          ] },
          { name: "prospect_detail", type: "object", properties: [
            { name: "prospect_pool", type: "object", properties: [
              { name: "id", type: "integer", control_type: "number" },
              { name: "name" }
            ] },
            { name: "prospect_stage", type: "object", properties: [
              { name: "id", type: "integer", control_type: "number" },
              { name: "name" }
            ] },
            { name: "prospect_owner", type: "object", properties: [
              { name: "id", type: "integer", control_type: "number" },
              { name: "name" }
            ] }
          ] }
          # Custom Field
          # Keyed_custom_fields
        ]

        custom_fields = get("/v1/custom_fields/application").
                        select { |e|
                          e["field_type"] == "application" &&
                            e["private"] == false &&
                            e["active"] == true
                        }.
                        map do |field|
          type = field["value_type"]
          case type
          when "short_text"
            { name: field["name_key"], type: "string", control_type: "text",
              label: field["name"], optional: !field["required"] }
          when "long_text"
            { name: field["name_key"], type: "string", label: field["name"],
              control_type: "text-area", optional: !field["required"] }
          when "yes_no"
            { name: field["name_key"], type: "boolean",
              control_type: "checkbox",
              label: field["name"], optional: !field["required"],
              toggle_hint: field["name"],
              toggle_field: {
                name: field["name_key"],
                label: field["name"],
                type: :string,
                control_type: "text",
                optional: !field["required"],
                toggle_hint: "Use custom value"
              } }
          when "date"
            { name: field["name_key"], type: "date", control_type: "date",
              label: field["name"], optional: !field["required"] }
          when "url"
            { name: field["name_key"], type: "string", control_type: "url",
              label: field["name"], optional: !field["required"] }
          when "user"
            { name: field["name_key"], type: "string", control_type: "text",
              label: field["name"], optional: !field["required"] }
          when "single_select"
            select_values = field["custom_field_options"].
                            map do |ob|
                              [ob["name"], ob["name"]]
                            end
            { name: field["name_key"], control_type: "select",
              label: field["name"], optional: !field["required"],
              pick_list: select_values,
              toggle_hint: field["name"],
              toggle_field: {
                name: field["name_key"],
                label: field["name"],
                type: :string,
                control_type: "text",
                optional: !field["required"],
                toggle_hint: "Use custom value"
              } }
          when "multi_select"
            multiselect_values = field["custom_field_options"].
                                 map do |ob|
                                   [ob["name"], ob["name"]]
                                 end
            { name: field["name_key"], control_type: "multiselect",
              label: field["name"], optional: !field["required"],
              pick_list: multiselect_values,
              pick_list_params: {},
              delimiter: ",",
              toggle_hint: field["name"],
              toggle_field: {
                name: field["name_key"],
                label: field["name"],
                type: :string,
                control_type: "text",
                optional: !field["required"],
                toggle_hint: "Use custom value"
              } }
          else
            { name: field["name_key"], type: "string", control_type: "text",
              label: field["name"], optional: !field["required"] }
          end
        end

        standard_fields.concat(custom_fields || []).compact
      end
    },

    user: {
      fields: lambda do
        [
          { name: "id", type: "integer", control_type: "number" },
          { name: "name" },
          { name: "first_name" },
          { name: "last_name" },
          { name: "updated_at", type: "date_time", control_type: "date_time" },
          { name: "created_at", type: "date_time", control_type: "date_time" },
          { name: "disabled", type: "boolean", control_type: "checkbox" },
          { name: "site_admin", type: "boolean", control_type: "checkbox" },
          { name: "emails", type: "array", of: "string",
            control_type: "email" },
          { name: "employee_id" }
        ]
      end
    },

    add_education: {
      fields: lambda do
        [
          { name: "school_id", type: "integer", control_type: "number",
            optional: false },
          { name: "discipline_id", type: "integer", control_type: "number",
            optional: false },
          { name: "degree_id", type: "integer", control_type: "number",
            optional: false },
          { name: "start_date", type: "date_time", control_type: "date_time",
            optional: false,
            hint: "Timestamp must be in in ISO-8601 format." },
          { name: "end_date", type: "date_time", control_type: "date_time",
            hint: "Timestamp must be in in ISO-8601 format." }
        ]
      end
    },

    education_response: {
      fields: lambda do
        [
          { name: "id", type: "integer" },
          { name: "school_name" },
          { name: "discipline" },
          { name: "degree" },
          { name: "start_date", type: "date_time" },
          { name: "end_date", type: "date_time" }
        ]
      end
    },

    employment: {
      fields: lambda do
        [
          { name: "id", type: "integer", control_type: "number" },
          { name: "company_name", optional: false },
          { name: "title", optional: false },
          { name: "start_date", type: "date_time", control_type: "date_time",
            optional: false, hint: "Timestamp must be in in ISO-8601 format" },
          { name: "end_date", type: "date_time", control_type: "date_time",
            hint: "Timestamp must be in in ISO-8601 format" }
        ]
      end
    },

    activity_feed: {
      fields: lambda do
        [
          { name: "notes", type: "array", of: "object", properties: [
            { name: "id", label: "Note Id" },
            { name: "created_at", type: "date_time",
              control_type: "date_time" },
            { name: "body", type: "string", control_type: "text-area" },
            { name: "user", type: "object", properties: [
              { name: "id", type: "integer", control_type: "number" },
              { name: "first_name" },
              { name: "last_name" },
              { name: "name" },
              { name: "employee_id" }
            ] },
            { name: "private", type: "boolean", control_type: "checkbox" },
            { name: "visibility" }
          ] },
          { name: "emails", type: "array", of: "object",
            properties: [
              { name: "id", type: "integer", control_type: "number" },
              { name: "created_at", type: "date_time",
                control_type: "date_time" },
              { name: "to" },
              { name: "from" },
              { name: "cc" },
              { name: "subject" },
              { name: "body" },
              { name: "user", type: "object", properties: [
                { name: "id" },
                { name: "first_name" },
                { name: "last_name" },
                { name: "name" },
                { name: "employee_id" }
              ] }
            ] },
          { name: "activities", type: "array", of: "object", properties: [
            { name: "id", type: "integer", control_type: "number" },
            { name: "created_at", type: "date_time",
              control_type: "date_time" },
            { name: "subject" },
            { name: "body" },
            { name: "user", type: "object", properties: [
              { name: "id" },
              { name: "first_name" },
              { name: "last_name" },
              { name: "name" },
              { name: "employee_id" }
            ] }
          ] }
        ]
      end
    }
  },

  test: lambda do |_connection|
    get("/v1/users").params(per_page: 1)
  end,

  methods: {
    on_behalf_of: lambda { |input|
      (get("/v1/users").
        params(per_page: 1,
               email: input) || {}) ["id"]
    }
  },

  actions: {
    search_candidate: {
      description: "Search <span class='provider'>candidates</span> in " \
        "<span class='provider'>Greenhouse</span>",
      title: "Search candidates",
      help: "Fetches a list of candidates that matches the search criteria." \
        "Returns a maximum of 100 records.",

      input_fields: lambda do |_object_definitions|
        [
          # Check job id?
          { name: "job_id", type: "integer", control_type: "number",
            hint: "If supplied, returns only candidates that have applied " \
              "to this job. Returns both when a candidate has applied to " \
              "a job and when they're a prospect of a job" },
          { name: "email", control_type: "email" },
          { name: "candidate_ids",
            hint: "If supplied, returns only the candidates with the given " \
              "ids. When combined with job ID, only candidates with an " \
              "application on the job will be returned. " \
              "Returns a maximum of 50 records" },
          { name: "created_before",
            type: "date_time", control_type: "date_time",
            hint: "Timestamp must be in in ISO-8601 format" },
          { name: "created_after",
            type: "date_time", control_type: "date_time",
            hint: "Timestamp must be in in ISO-8601 format" },
          { name: "updated_before",
            type: "date_time", control_type: "date_time",
            hint: "Timestamp must be in in ISO-8601 format" },
          { name: "updated_after",
            type: "date_time", control_type: "date_time",
            hint: "Timestamp must be in in ISO-8601 format" }
        ]
      end,

      execute: lambda do |_connection, input|
        error("Provide at least one search criteria") if input.blank?
        {
          candidates: get("/v1/candidates", input)
        }
      end,

      output_fields: lambda do |object_definitions|
        { name: "candidates", type: "array", of: "object",
          properties: object_definitions["candidate"] }
      end,

      sample_output: lambda do |_connection, _input|
        {
          candidates: get("/v1/candidates", per_page: 1)
        }
      end
    },

    get_candidate: {
      title: "Get candidate by ID",
      description: "Get <span class='provider'>candidate</span> by " \
        "ID in <span class='provider'>Greenhouse</span>",
      subtitle: "Get candidate details by ID",
      help: "Returns information about a candidate.",

      input_fields: lambda do |_object_definitions|
        [
          { name: "id", optional: false, type: "integer",
            control_type: "number", label: "Candidate ID" }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/v1/candidates/" + input["id"])
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["candidate"]
      end,

      sample_output: lambda do |_connection, _input|
        get("/v1/candidates", per_page: 1).first
      end
    },

    create_candidate: {
      description: "Create <span class='provider'>candidate</span> in " \
        "<span class='provider'>Greenhouse</span>",
      title: "Create candidate",

      input_fields: lambda do |object_definitions|
        object_definitions["create_candidate"].
          required("first_name", "last_name", "applications")
      end,

      execute: lambda do |connection, input|
        on_behalf_of = (get("/v1/users").
            params(per_page: 1, email: connection["usermail"]) || {})["id"]

        params = input.map do |key, value|
          if key.include?("custom_fields")
            custom_field = value.map do |k, v|
              {
                "name_key" => k,
                "value" => v
              }
            end
            { key => custom_field }
          else
            { key => value }
          end
        end.inject(:merge)

        post("/v1/candidates").
          headers("On-Behalf-Of": on_behalf_of).payload(params)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["candidate"]
      end,

      sample_output: lambda do |_connection, _input|
        get("/v1/candidates", per_page: 1).first
      end
    },

    update_candidate: {
      description: "Update <span class='provider'>Candidate</span> in " \
      "<span class='provider'> Greenhouse</span>",
      title: "Update candidate",

      input_fields: lambda do |object_definitions|
        [
          { name: "id", type: "integer", control_type: "number",
            optional: false,
            label: "Candidate ID" }
        ].concat(object_definitions["create_candidate"])
      end,

      execute: lambda do |connection, input|
        patch("/v1/candidates/" + input.delete("id")).
          headers(
            "On-Behalf-Of": call("on_behalf_of", connection["usermail"])
          ).payload(input)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["candidate"]
      end,

      sample_output: lambda do |_connection, _input|
        get("/v1/candidates", per_page: 1).first
      end
    },

    add_candidate_application: {
      description: "Create a new <span class='provider'>application</span> " \
        "for candidate / prospect in <span class='provider'>Greenhouse</span>",
      title: "Create new application",
      help: "If candidate is a prospect, a new candidate application will be" \
        " added to their profile. It will not convert their existing " \
        "prospect application into candidate application.",

      input_fields: lambda do |_object_definitions|
        [
          { name: "id", type: "integer", control_type: "number",
            optional: false, label: "Candidate ID" },
          { name: "job_id", type: "integer", control_type: "number",
            optional: false, label: "Job ID" },
          { name: "source_id", type: "integer", control_type: "number" },
          { name: "initial_stage_id", type: "integer",
            control_type: "number" },
          { name: "referrer", type: "object", properties: [
            { name: "type", label: "Type", control_type: :select, pick_list:
              [
                %w[ID id],
                %w[Email email],
                %w[Outside outside]
              ],
              optional: true, toggle_hint: "Select from list",
              toggle_field: {
                name: "referrer",
                label: "referrer",
                type: :string,
                control_type: "text",
                optional: true,
                toggle_hint: "Use custom value"
              } },
            { name: "value" }
          ] },
          { name: "attachments", type: "array", of: "object", properties: [
            { name: "filename", optional: false,
              hint: "Full name of file including its extension, " \
                "e.g. resume.pdf" },
            { name: "type", label: "Type", control_type: :select, pick_list:
              [
                %w[Resume resume],
                %w[Cover\ letter cover_letter],
                %w[Admin\ only admin_only]
              ],
              optional: false, toggle_hint: "Select from list",
              toggle_field: {
                name: "referrer",
                label: "referrer",
                type: :string,
                control_type: "text",
                optional: false,
                toggle_hint: "Use custom value",
                hint: "Possible values: resume, cover_letter, or admin_only"
              } },
            { name: "content", hint: "Base64 encoded contents of attachment" },
            { name: "content_type",
              hint: "Recommended to specify. Find out more <a href='https://" \
                "developers.greenhouse.io/harvest.html#post-add-attachment'>" \
                "here</a>" }
          ] }
        ]
      end,

      execute: lambda do |connection, input|
        post("/v1/candidates/" + input.delete("id") + "/applications").
          headers(
            "On-Behalf-Of": call("on_behalf_of", connection["usermail"])
          ).
          payload(input)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["candidate"]
      end,

      sample_output: lambda do |_connection, _input|
        get("/v1/candidates", per_page: 1).first
      end
    },

    search_applications: {
      description: "Search <span class='provider'>applications</span> in " \
        "<span class='provider'>Greenhouse</span>",
      title: "Search applications",
      help: "Fetches a list of applications that matches the search criteria" \
        ". Returns a maximum of 100 records.",

      input_fields: lambda do |_object_definitions|
        [
          { name: "job_id",
            hint: "If supplied, only applications that involve this job " \
              "will be returned. Returns both candidates and prospects." },
          { name: "created_before",
            type: "date_time", control_type: "date_time",
            hint: "Timestamp must be in in ISO-8601 format" },
          { name: "created_after",
            type: "date_time", control_type: "date_time",
            hint: "Timestamp must be in in ISO-8601 format" },
          { name: "last_activity_after",
            type: "date_time", control_type: "date_time",
            hint: "Timestamp must be in in ISO-8601 format" },
          { name: "status", control_type: "select", picklist:
            [
              %w[Active active],
              %w[Converted converted],
              %w[Rejected rejected],
              %w[Hired hired]
            ],
            toggle_hint: "Select from list",
            toggle_field: {
              name: "status",
              label: "Status",
              type: :string,
              control_type: "text",
              optional: true,
              toggle_hint: "Use custom value",
              hint: "Possible values: active, converted, hired, and " \
                "rejected. If anything else is used, an empty response" \
                " will be returned rather than an error."
            } }
        ]
      end,

      execute: lambda do |_connection, input|
        error("Provide at least one search criteria") if input.blank?
        applications = get("/v1/applications", input)
        {
          applications: applications
        }
      end,

      output_fields: lambda do |object_definitions|
        [{ name: "applications", type: "array", of: "object",
           properties: object_definitions["application"] }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          applications: get("/v1/applications", per_page: 1)
        }
      end
    },

    search_users: {
      description: "Search <span class='provider'>users</span> in " \
      "<span class='provider'>Greenhouse</span>",
      title: "Search users",
      help: "Fetches a list of users that matches the search criteria." \
        "Returns a maximum of 100 records.",

      input_fields: lambda do |_object_definitions|
        [
          { name: "email",
            sticky: false,
            hint: "Return only the user who has this e-mail address as " \
              "their primary e-mail or a secondary e-mail." },
          { name: "employee_id",
            sticky: false,
            type: "integer", control_type: "number",
            hint: "Return a single user that matches this employee id." },
          { name: "created_before",
            type: "date_time", control_type: "date_time" },
          { name: "created_after",
            type: "date_time", control_type: "date_time" },
          { name: "updated_before",
            type: "date_time", control_type: "date_time" },
          { name: "updated_after",
            type: "date_time", control_type: "date_time" }
        ]
      end,

      execute: lambda do |_connection, input|
        error("Provide at least one search criteria") if input.blank?
        users = get("/v1/users", input)
        {
          users: users
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: "users", type: "array", of: "object",
            properties: object_definitions["user"] }
        ]
      end,

      sample_output: lambda do |_connection, _input|
        {
          users: get("/v1/users", per_page: 1)
        }
      end
    },

    create_user: {
      description: "Create <span class='provider'>user</span> in " \
        "<span class='provider'>Greenhouse</span>",
      title: "Create user",

      input_fields: lambda do |_object_definitions|
        [
          { name: "first_name", optional: false },
          { name: "last_name", optional: false },
          { name: "email", type: "string", control_type: "email",
            optional: false },
          { name: "send_email_invite", type: "boolean",
            control_type: "checkbox" },
          { name: "employee_id", hint: "User's external employee ID. " \
              "Employee ID should be enabled for the organization" }
        ]
      end,

      execute: lambda do |connection, input|
        on_behalf_of = (get("/v1/users").
                       params(per_page: 1,
                              email: connection["usermail"]) || {})["id"]
        post("/v1/users").
          headers("On-Behalf-Of": on_behalf_of).payload(input)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["user"]
      end,

      sample_output: lambda do |_connection, _input|
        get("/v1/users", per_page: 1).first
      end
    },

    add_candidate_note: {
      description: "Add <span class='provider'>note</span> to candidate in " \
        "<span class='provider'>Greenhouse</span>",
      title: "Add note to candidate",

      input_fields: lambda do
        [
          { name: "id", label: "Candidate ID", type: "integer",
            optional: false,
            control_type: "number" },
          { name: "user_id", type: "integer", control_type: "number",
            optional: false,
            hint: "The ID of the user creating the note" },
          { name: "body", type: "string", control_type: "text-area",
            optional: false,
            hint: "Note body" },
          { name: "visibility", control_type: "select", pick_list:
            [
              %w[Admin\ only admin_only],
              %w[Private private],
              %w[Public public]
            ],
            optional: false,
            toggle_hint: "Select from list",
            toggle_field: {
              name: "visibility",
              label: "Visibility",
              type: :string,
              control_type: "text",
              optional: false,
              toggle_hint: "Enter custom value",
              hint: "Possible values: admin_only, private, public"
            } }
        ]
      end,

      execute: lambda do |connection, input|
        post("/v1/candidates/" + input.delete("id") + "/activity_feed/notes").
          headers(
            "On-Behalf-Of": call("on_behalf_of", connection["usermail"])
          ).
          payload(input)
      end,

      output_fields: lambda do
        [
          { name: "id", label: "Candidate ID", type: "integer" },
          { name: "created_at", type: "date_time" },
          { name: "body" },
          { name: "user", type: "object", properties: [
            { name: "id", type: "integer", control_type: "number",
              label: "User ID" },
            { name: "first_name" },
            { name: "last_name" },
            { name: "name" },
            # Check employee ID
            { name: "employee_id" }
          ] },
          { name: "private", type: "boolean" },
          { name: "visiblity" }
        ]
      end,

      sample_output: lambda do |_object_definitions|
        {
          "id": 226_809_052,
          "created_at": "2015-07-17T16:29:31Z",
          "body": "John Locke was moved into Recruiter Phone Screen for " \
            "Accounting Manager on 03/27/2014 by Boone Carlyle",
          "user": {
            "id": 214,
            "first_name": "Boone",
            "last_name": "Carlyle",
            "name": "Boone Carlyle",
            "employee_id": "null"
          },
          "private": "false",
          "visiblity": "admin_only",
          "visibility": "admin_only"
        }
      end
    },

    add_email_note: {
      description: "Add email <span class='provider'>note</span> to " \
        "candidate in <span class='provider'>Greenhouse</span>",
      title: "Add email note to candidate",

      input_fields: lambda do
        [
          { name: "id", label: "Candidate ID", type: "integer",
            optional: false,
            control_type: "number" },
          { name: "user_id", type: "integer", control_type: "number",
            optional: false,
            hint: "The ID of the user creating the note" },
          { name: "to", optional: false, label: "To email",
            hint: "Free text field (E-mail format will not be validated)." },
          { name: "from", label: "From", optional: false,
            hint: "Free text field (E-mail format will not be validated)." },
          { name: "cc", type: "array", of: "string",
            hint: "Free text field (E-mail format will not be validated)." },
          { name: "subject", optional: false,
            hint: "The subject line of the e-mail." },
          { name: "body", type: "string", control_type: "text-area",
            optional: false,
            hint: "The body of the e-mail." }
        ]
      end,

      execute: lambda do |connection, input|
        post("/v1/candidates/" + input.delete("id") + "/activity_feed/emails").
          headers(
            "On-Behalf-Of": call("on_behalf_of", connection["usermail"])
          ).
          payload(input)
      end,

      output_fields: lambda do
        [
          { name: "id", type: "integer" },
          { name: "created_at", type: "date_time" },
          { name: "subject" },
          { name: "body" },
          { name: "to" },
          { name: "from" },
          { name: "cc", type: "array", of: "string" },
          { name: "user", type: "object", properties: [
            { name: "id", label: "User ID", type: "integer" },
            { name: "first_name" },
            { name: "last_name" },
            { name: "name" },
            { name: "employee_id" }
          ] }
        ]
      end,

      sample_output: lambda do |_connection, _input|
        {
          "id": 226_809_053,
          "created_at": "2015-07-17T16:29:31Z",
          "subject": "Interview Scheduled",
          "body": "An interview has been scheduled for tomorrow.",
          "to": "candidate@example.com",
          "from": "recruiter@example.com",
          "cc": [
            "manager@example.com"
          ],
          "user": {
            "id": 214,
            "first_name": "Donald",
            "last_name": "Johnson",
            "name": "Donald Johnson",
            "employee_id": "12345"
          }
        }
      end
    },

    add_education: {
      description: "Add <span class='provider'>education</span> to candidate" \
        " in <span class='provider'>Greenhouse</span>",
      title: "Add education to candidate",

      input_fields: lambda do |object_definitions|
        [
          { name: "id", label: "Candidate ID", type: "integer",
            optional: false,
            control_type: "number" }
        ].concat(object_definitions["add_education"].
        required("school_id", "discipline_id", "degree_id",
                 "start_date", "end_date"))
      end,

      execute: lambda do |connection, input|
        post("/v1/candidates/" + input.delete("id") + "/educations").
          headers(
            "On-Behalf-Of": call("on_behalf_of", connection["usermail"])
          ).
          payload(input)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["education_response"]
      end,

      sample_output: lambda do |_connection, _input|
        {
          "id": 5_690_098,
          "school_name": "Siena College",
          "discipline": "Computer Science",
          "degree": "Bachelor's Degree",
          "start_date": "2001-09-15T00:00:00.000Z",
          "end_date": "2004-05-15T00:00:00.000Z"
        }
      end
    },

    add_employment_candidate: {
      description: "Add <span class='provider'>employment</span> to " \
        "candidate in <span class='provider'>Greenhouse</span>",
      title: "Add employment to candidate",
      help: "Creates a new employment record.",

      input_fields: lambda do |object_definitions|
        [
          { name: "id", label: "Candidate ID", type: "integer",
            optional: false,
            control_type: "number" }
        ].concat(object_definitions["employment"].
        required("company_name", "title", "start_date").ignored("id"))
      end,

      execute: lambda do |connection, input|
        post("/v1/candidates/" + input.delete("id") + "/employments").
          headers(
            "On-Behalf-Of": call("on_behalf_of", connection["usermail"])
          ).
          payload(input)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["employment"]
      end,

      sample_output: lambda do |_connection, _input|
        {
          "id": 5_690_098,
          "company_name": "Greenhouse",
          "title": "Engineer",
          "start_date": "2001-09-15T00:00:00.000Z",
          "end_date": "2004-05-15T00:00:00.000Z"
        }
      end
    },

    add_prospect: {
      description: "Add <span class='provider'>prospect</span> in " \
        "<span class='provider'>Greenhouse</span>",
      title: "Add prospect",
      help: "Creates a new prospect. Prospect can be on no jobs or many jobs" \
        ", unlike candidate. Prospect cannot be added to a job stage " \
        "without converting to a candidate.",

      input_fields: lambda do |object_definitions|
        object_definitions["add_prospect"]
      end,

      execute: lambda do |connection, input|
        post("/v1/prospects").
          headers(
            "On-Behalf-Of": call("on_behalf_of", connection["usermail"])
          ).
          payload(input)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["candidate"]
      end,

      sample_output: lambda do |_connection, _input|
        get("/v1/candidates", per_page: 1).first
      end
    },

    list_degrees: {
      description: "List <span class='provider'>degrees</span> in " \
        "<span class='provider'>Greenhouse</span>",
      title: "List degrees",
      help: "Returns a list of degrees and/or education levels for this " \
        "organization, sorted by priority.",

      execute: lambda do
        {
          degrees: get("/v1/degrees")
        }
      end,

      output_fields: lambda do
        [
          { name: "degrees", type: "array", of: "object", properties: [
            { name: "id", type: "integer" },
            { name: "name" },
            { name: "priority", type: "integer" }
          ] }
        ]
      end,

      sample_output: lambda do |_connection, _input|
        {
          degrees: get("/v1/degrees").first
        }
      end
    },

    list_disciplines: {
      description: "List <span class='provider'>disciplines</span> in " \
        "<span class='provider'>Greenhouse</span>",
      title: "List disciplines",
      help: "Returns a list of disciplines for this " \
        "organization, sorted by priority.",

      execute: lambda do
        {
          disciplines: get("/v1/disciplines")
        }
      end,

      output_fields: lambda do
        [
          { name: "disciplines", type: "array", of: "object", properties: [
            { name: "id", type: "integer" },
            { name: "name" },
            { name: "priority", type: "integer" }
          ] }
        ]
      end,

      sample_output: lambda do |_connection, _input|
        {
          disciplines: get("/v1/disciplines").first
        }
      end
    },

    list_schools: {
      description: "List <span class='provider'>schools</span> in " \
        "<span class='provider'>Greenhouse</span>",
      title: "List schools",
      help: "Returns a list of schools for this " \
        "organization, sorted by priority.",

      execute: lambda do
        {
          schools: get("/v1/schools")
        }
      end,

      output_fields: lambda do
        [
          { name: "schools", type: "array", of: "object", properties: [
            { name: "id", type: "integer" },
            { name: "name" },
            { name: "priority", type: "integer" }
          ] }
        ]
      end,

      sample_output: lambda do |_connection, _input|
        {
          schools: get("/v1/schools").first
        }
      end
    },

    get_candidate_activity_feed: {
      description: "Get candidate <span class='provider'>activity " \
        "feed</span> in <span class='provider'>Greenhouse</span>",
      title: "Get candidate activity feed",
      help: "Returns activity feed about a candidate.",

      input_fields: lambda do
        [
          { name: "id", type: "integer", control_type: "number",
            label: "Candidate ID", optional: false }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/v1/candidates/" + input["id"] + "/activity_feed")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["activity_feed"]
      end,

      sample_output: lambda do |_connection, _input|
        {
          "notes": [
            {
              "id": 12345,
              "created_at": "2014-03-26T20:11:40Z",
              "body": "Very mysterious.",
              "user": {
                "id": 512,
                "first_name": "Sayid",
                "last_name": "Jarrah",
                "name": "Sayid Jarrah",
                "employee_id": "12345"
              },
              "private": "false",
              "visiblity": "public",
              "visibility": "public"
            }
          ],
          "emails": [
            {
              "id": 234675,
              "created_at": "2014-04-01T15:55:06Z",
              "subject": "Regarding your application",
              "body": "Hey John,  just wanted to touch base!",
              "to": "john.locke@example.com",
              "from": "boone.carlyle@example.com",
              "cc": "sam.smith@example.com",
              "user": {
                "id": 214,
                "first_name": "Boone",
                "last_name": "Carlyle",
                "name": "Boone Carlyle",
                "employee_id": "67890"
              }
            }
          ],
          "activities": [
            {
              "id": 6756789,
              "created_at": "2014-04-01T15:55:29Z",
              "subject": "Candidate Rejected",
              "body": "Reason: Lacking hustle. This candidate turned out to be problematic for us...",
              "user": {
                "id": 214,
                "first_name": "Boone",
                "last_name": "Carlyle",
                "name": "Boone Carlyle",
                "employee_id": "67890"
              }
            },
            {
              "id": 6757869,
              "created_at": "2014-03-26T20:26:38Z",
              "subject": "Candidate Stage Change",
              "body": "John Locke was moved into Recruiter Phone Screen for Accounting Manager on 03/27/2014 by Boone Carlyle",
              "user": {
                "id": 214,
                "first_name": "Boone",
                "last_name": "Carlyle",
                "name": "Boone Carlyle",
                "employee_id": "67890"
              }
            }
          ]
        }
      end
    }
  },

  triggers: {
    new_updated_candidate: {
      description: "New or updated <span class='provider'>candidate</span> " \
        "in <span class='provider'>Greenhouse</span>",
      title: "New or updated candidate",
      help: "Triggers when candidates is created/updated.",

      input_fields: lambda do |_object_definitions|
        [
          {
            name: "since", type: :date_time,
            label: "From", optional: true,
            sticky: true,
            hint: "Defaults to 1 hour ago if left blank"
          }
        ]
      end,

      poll: lambda do |_connection, input, last_updated_at|
        last_updated_at = last_updated_at || (input["since"] || 1.hour.ago).
                                             to_time.utc.iso8601
        candidates = get("/v1/candidates").
                     params(per_page: 100,
                            updated_after: last_updated_at)
        sorted_candidates = candidates.sort_by { |obj|
          obj["updated_at"] } unless candidates.blank?
        last_updated_at =
          if sorted_candidates.blank?
            last_updated_at
          else
            sorted_candidates.last["updated_at"]
          end

        {
          events: sorted_candidates,
          next_poll:  last_updated_at,
          can_poll_more: candidates.size > 100
        }
      end,

      dedup: lambda do |candidate|
        candidate["id"].to_s + "@" + candidate["updated_at"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["candidate"]
      end,

      sample_output: lambda do |_connection, _input|
        get("/v1/candidates", per_page: 1).first
      end
    }
  },

  pick_lists: {
    phone_type: lambda do
      [
        %w[Home home],
        %w[Work work],
        %w[Mobile mobile],
        %w[Skype skype],
        %w[Other other]
      ]
    end,

    address_type: lambda do
      [
        %w[Home home],
        %w[Work work],
        %w[Other other]
      ]
    end,

    email_type: lambda do
      [
        %w[Personal personal],
        %w[Work work],
        %w[Other other]
      ]
    end,

    website_type: lambda do
      [
        %w[Personal personal],
        %w[Company company],
        %w[Portfolio portfolio],
        %w[Blog blog],
        %w[Other other]
      ]
    end,

    attachments_type: lambda do
      [
        %w[Admin\ only admin_only],
        %w[Public public],
        %w[Cover\ letter cover_letter],
        %w[Offer\ packet offer_packet],
        %w[Resume resume],
        %w[Take\ home\ test take_home_test]
      ]
    end,

    referrer_type: lambda do
      [
        %w[ID id],
        %w[Email email],
        %w[Outside outside]
      ]
    end
  }
}
