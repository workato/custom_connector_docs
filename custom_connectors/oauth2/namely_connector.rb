{
  title: "Namely (Custom)",

  connection: {
    fields: [
      { name: "company", control_type: :subdomain, url: ".namely.com",
        optional: false, hint: "If your Namely URL is https://acme.namely.com
        then use acme as value." },
      { name: "client_id", label: "Client ID", control_type: :password,
        optional: false },
      { name: "client_secret", control_type: :password, optional: false }
    ],

    authorization: {
      type: "oauth2",

      authorization_url: lambda do |connection|
        params = {
          response_type: "code",
          client_id: connection["client_id"],
          redirect_uri: "https://www.workato.com/oauth/callback",
        }.to_param
        "https://#{connection['company']}.namely.com/api/v1/oauth2/authorize?" + params
      end,

      acquire: lambda do |connection, auth_code|
        response = post("https://#{connection['company']}" +
          ".namely.com/api/v1/oauth2/token").
                     payload(
                       grant_type: "authorization_code",
                       client_id: connection["client_id"],
                       client_secret: connection["client_secret"],
                       code: auth_code
                     ).request_format_www_form_urlencoded
        [response, nil, nil]
      end,

      refresh_on: [401, 403],

      refresh: lambda do |connection, refresh_token|
        post("https://#{connection['company']}.namely.com/api/v1/oauth2/token").
          payload(
            grant_type: "refresh_token",
            client_id: connection["client_id"],
            client_secret: connection["client_secret"],
            refresh_token: refresh_token,
            redirect_uri: "https://www.workato.com/oauth/callback"
          ).request_format_www_form_urlencoded
      end,

      apply: lambda do |_connection, access_token|
        headers("Authorization": "Bearer #{access_token}")
      end
    },

    base_uri: lambda do |connection|
      "https://#{connection['company']}.namely.com"
    end
  },

  object_definitions: {
    profile_input: {
      fields: ->(_connection) {
        custom_fields =
          get("/api/v1/profiles/fields")["fields"].
            select { |e| e["default"] == false && e["deletable"] == true }.
            map do |field|
            type = field["type"]
            case type
            when "text"
              { name: field["name"].downcase, type: "string", control_type: "text",
                label: field["label"], optional: true,
                hint: if field["valid_format_info"] != "generic text"
                        field["valid_format_info"]
                      else []
                      end }
            when "longtext"
              { name: field["name"].downcase, type: "string",
                control_type: "text-area", label: field["label"],
                optional: true, hint: if field["valid_format_info"] != "generic text"
                                        field["valid_format_info"]
                                      else []
                                      end  }
            when "date"
              { name: field["name"].downcase, type: "date", control_type: "date",
                label: field["label"], optional: true,
                hint: if field["valid_format_info"] != "generic text"
                        field["valid_format_info"]
                      else []
                      end  }
            when "number"
              { name: field["name"].downcase, type: "number", control_type: "number",
                label: field["label"], optional: true,
                hint: if field["valid_format_info"] != "generic text"
                        field["valid_format_info"]
                      else []
                      end  }
            when "file"
              { name: field["name"].downcase, type: "string", control_type: "text",
                label: field["label"], optional: true,
                hint: if field["valid_format_info"] != "generic text"
                        field["valid_format_info"]
                      else []
                      end  }
            else
              { name: field["name"], type: "string", control_type: "text",
                label: field["label"], optional: true,
                hint: if field["valid_format_info"] != "generic text"
                        field["valid_format_info"]
                      else []
                      end }
            end
          end

        standard_fields = [
          { name: "email", label: "Email address" },
          { name: "first_name", label: "First name" },
          { name: "last_name", label: "Last name" },
          { name: "access_role", label: "Access role",
            control_type: :select, pick_list: "access_role",
            toggle_hint: "Select from list" },
          { name: "ethnicity", label: "Ethnicity" },
          { name: "user_status", label: "User status", optional: true,
            control_type: :select, pick_list: "employee_status",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "user_status", type: :string, control_type: :text,
              label: "User status (Custom)", toggle_hint: "Use custom value"
            },
            hint: "One of 'active', 'inactive' or 'pending'. "\
            "Must be 'pending' if onboarding session is enabled" },
          { name: "preferred_name", label: "Preferred name" },
          { name: "full_name", label: "Full name" },
          { name: "home_phone", control_type: :phone },
          { name: "mobile_phone", control_type: :phone },
          { name: "middle_name", label: "Middle name" },
          { name: "job_change_reason", label: "Job change reason" },
          { name: "start_date", label: "Start date",
            hint: "Format in YYYY-MM-DD", control_type: "date" },
          { name: "departure_date", label: "Departure date",
            control_type: "date", hint: "Format in YYYY-MM-DD" },
          { name: "employee_id", label: "Employee ID" },
          { name: "personal_email", label: "Personal email",
            hint: "Required if Namely profile user status is pending,"\
            " or if onboarding session is enabled" },
          { name: "dob", label: "Date of birth", control_type: "date",
            hint: "Format in YYYY-MM-DD" },
          { name: "ssn", label: "SSN" },
          { name: "bio", label: "Profile bio" },
          { name: "asset_management", label: "Assets list", type: "array" },
          { name: "laptop_asset_number", label: "Laptop asset number",
            control_type: "number" },
          { name: "corporate_card_number", label: "Corporate card number",
            control_type: "number" },
          { name: "key_tag_number", label: "Key tag number",
            control_type: "number" },
          { name: "linkedin_url", label: "Linkedin URL", control_type: "url" },
          { name: "office_main_number", label: "Office main number",
            control_type: "number" },
          { name: "office_direct_dial", label: "Office direct dial" },
          { name: "office_phone", label: "Office phone number",
            control_type: "number" },
          { name: "office_fax", label: "Office fax" },
          { name: "office_company_mobile", label: "Office company mobile number",
            control_type: "number" },
          { name: "emergency_contact", label: "Emergency contact" },
          { name: "emergency_contact_phone", label: "Emergency contact number",
            control_type: "number" },
          { name: "resume", label: "Resume", hint: "Valid file ID" },
          { name: "current_job_description", label: "Current job description",
            control_type: "text-area" },
          { name: "healthcare_info", label: "Healthcare info",
            control_type: "text-area" },
          { name: "dental_info", label: "Dental info",
            control_type: "text-area" },
          { name: "vision_plan_info", label: "Vision plan info",
            control_type: "text-area" },
          { name: "life_insurance_info", label: "Life insurance info",
            control_type: "text-area" },
          { name: "namely_time_employee_role", label: "Namely time employee role" },
          { name: "namely_time_manager_role", label: "Namely time manager role" },
          { name: "image", label: "Image", hint: "Enter valid image ID" },
          { name: "healthcare", type: :object, properties: [
            { name: "beneficiary" },
            { name: "amount" },
            { name: "currency_type", hint: "Default is USD" }
          ] },
          { name: "employee_type", label: "Employee type",
            control_type: :select, pick_list: "employee_type",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "employee_type", type: :string, control_type: :text,
              label: "Employee Type (Custom)", toggle_hint: "Use custom value"
            } },
          { name: "salary", type: :object, properties: [
            { name: "id", hint: "If present, will find and update an existing salary" },
            { name: "yearly_amount" },
            { name: "rate", hint: "One of 'annually', 'weekly', 'biweekly'. "\
                "Refer to platform documentation for more examples" },
            { name: "currency_type", control_type: :select, pick_list: "currencies",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "currency_type", type: :string, control_type: :text,
                label: "Currency type (Custom)", toggle_hint: "Use custom value",
                hint: "Must be a valid ISO currency code"
              } },
            { name: "date", label: "Start date", type: :date }
          ] },
          { name: "home", type: :object, properties: [
            { name: "address1" },
            { name: "address2" },
            { name: "city" },
            { name: "country_id", label: "Country",
              control_type: :select, pick_list: "countries",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "country_id", type: :string, control_type: :text,
                label: "Country (Custom)", toggle_hint: "Use custom value",
                hint: "Must be a valid 2-digit ISO country code"
              } },
            { name: "state_id", hint: "US state only" },
            { name: "zip" }
          ] },
          { name: "office", type: :object, properties: [
            { name: "address1" },
            { name: "address2" },
            { name: "city" },
            { name: "country_id", label: "Country",
              control_type: :select, pick_list: "countries",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "country_id", type: :string, control_type: :text,
                label: "Country (Custom)", toggle_hint: "Use custom value",
                hint: "Must be a valid 2-digit ISO country code"
              } },
            { name: "state_id", hint: "US state only" },
            { name: "zip" }
          ] },
          { name: "dental", type: :object, properties: [
            { name: "beneficiary" },
            { name: "amount" },
            { name: "currency_type", hint: "Default is USD" }
          ] },
          { name: "reports_to", type: "string", control_type: "text",
            hint: "ID of employee profile whom employee reports to" },
          { name: "job_title", control_type: :select, pick_list: "jobs",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "job_title", type: :string, control_type: :text,
              label: "Job title (Custom)", toggle_hint: "Use custom value",
              hint: "Enter either exact case sensitive job title or job ID"
            } },
          { name: "gender", control_type: :select, pick_list: "gender",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "gender", type: :string, control_type: :text,
              label: "Gender(Custom)", toggle_hint: "Use custom value",
              hint: "Valid values are Male, Female, Not specified"
            } },
          { name: "marital_status", control_type: :select,
            pick_list: "marital_status",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "marital_status", type: :string, control_type: :text,
              label: "Marital status(Custom)", toggle_hint: "Use custom value",
              hint: "Valid values are Single, Married, Civil Partnership, Separated, Divorced"
            } },
          { name: "custom_fields", type: "object", properties: custom_fields }
        ]
        standard_fields
      }
    },
    profile_output: {
      fields: ->(_connection) {
        custom_fields =
          get("/api/v1/profiles/fields")["fields"].
            select { |e| e["default"] == false && e["deletable"] == true }.
            map do |field|
            type = field["type"]
            case type
            when "text"
              { name: field["name"].downcase, type: "string", control_type: "text",
                label: field["label"], optional: true,
                hint: if field["valid_format_info"] != "generic text"
                        field["valid_format_info"]
                      else []
                      end }
            when "longtext"
              { name: field["name"].downcase, type: "string",
                control_type: "text-area", label: field["label"],
                optional: true, hint: if field["valid_format_info"] != "generic text"
                                        field["valid_format_info"]
                                      else []
                                      end  }
            when "date"
              { name: field["name"].downcase, type: "date", control_type: "date",
                label: field["label"], optional: true,
                hint: if field["valid_format_info"] != "generic text"
                        field["valid_format_info"]
                      else []
                      end  }
            when "number"
              { name: field["name"].downcase, type: "number", control_type: "number",
                label: field["label"], optional: true,
                hint: if field["valid_format_info"] != "generic text"
                        field["valid_format_info"]
                      else []
                      end  }
            when "file"
              { name: field["name"].downcase, type: "string", control_type: "text",
                label: field["label"], optional: true,
                hint: if field["valid_format_info"] != "generic text"
                        field["valid_format_info"]
                      else []
                      end  }
            else
              { name: field["name"], type: "string", control_type: "text",
                label: field["label"], optional: true,
                hint: if field["valid_format_info"] != "generic text"
                        field["valid_format_info"]
                      else []
                      end }
            end
          end

        standard_fields = [
          { name: "id", label: "ID" },
          { name: "email", label: "Email address" },
          { name: "first_name", label: "First name" },
          { name: "last_name", label: "Last name" },
          { name: "access_role", label: "Access role" },
          { name: "ethnicity", label: "Ethnicity" },
          { name: "user_status", label: "User status" },
          { name: "updated_at", label: "Updated at" },
          { name: "created_at", label: "Created at" },
          { name: "preferred_name", label: "Preferred name" },
          { name: "full_name", label: "Full name" },
          { name: "home_phone", control_type: :phone },
          { name: "mobile_phone", control_type: :phone },
          { name: "middle_name", label: "Middle name" },
          { name: "gender", label: "Gender" },
          { name: "job_change_reason", label: "Job change reason" },
          { name: "start_date", label: "Start date" },
          { name: "departure_date", label: "Departure date" },
          { name: "employee_id", label: "Employee ID" },
          { name: "personal_email", label: "Personal email" },
          { name: "dob", label: "Date of birth" },
          { name: "ssn", label: "SSN" },
          { name: "marital_status", label: "Marital status" },
          { name: "bio", label: "Profile bio" },
          { name: "asset_management", label: "Assets list", type: "array" },
          { name: "laptop_asset_number", label: "Laptop asset number" },
          { name: "corporate_card_number", label: "Corporate card number" },
          { name: "key_tag_number", label: "Key tag number" },
          { name: "linkedin_url", label: "Linkedin URL" },
          { name: "office_main_number", label: "Office main number" },
          { name: "office_direct_dial", label: "Office direct dial" },
          { name: "office_phone", label: "Office phone number" },
          { name: "office_fax", label: "Office fax" },
          { name: "office_company_mobile", label: "Office company mobile number" },
          { name: "emergency_contact", label: "Emergency contact" },
          { name: "emergency_contact_phone", label: "Emergency contact number" },
          { name: "resume", label: "Resume" },
          { name: "current_job_description", label: "Current job description",
            control_type: "text-area" },
          { name: "healthcare_info", label: "Healthcare info" },
          { name: "dental_info", label: "Dental info" },
          { name: "vision_plan_info", label: "Vision plan info" },
          { name: "life_insurance_info", label: "Life insurance info" },
          { name: "namely_time_employee_role", label: "Namely time employee role" },
          { name: "namely_time_manager_role", label: "Namely time manager role" },
          { name: "image", type: :object, properties: [
            { name: "id" },
            { name: "filename" },
            { name: "mime_type" },
            { name: "original" }
          ] },
          { name: "healthcare", type: :object, properties: [
            { name: "beneficiary" },
            { name: "amount" },
            { name: "currency_type" }
          ] },
          { name: "job_title", type: :object, properties: [
            { name: "id", label: "Job title ID" },
            { name: "title", label: "Title" }
          ] },
          { name: "employee_type", type: :object, properties: [
            { name: "title", label: "Title" }
          ] },
          { name: "salary", type: :object, properties: [
            { name: "id" },
            { name: "yearly_amount" },
            { name: "rate" },
            { name: "currency_type", label: "Currency type" },
            { name: "date", label: "Start date", type: :date }
          ] },
          { name: "home", type: :object, properties: [
            { name: "address1" },
            { name: "address2" },
            { name: "city" },
            { name: "country_id", label: "Country ID" },
            { name: "state_id", label: "State ID" },
            { name: "zip" }
          ] },
          { name: "office", type: :object, properties: [
            { name: "address1" },
            { name: "address2" },
            { name: "city" },
            { name: "country_id", label: "Country", control_type: :select,
              pick_list: "countries",
              toggle_hint: "Select from list",
              toggle_field: {
                name: "country_id", type: :string, control_type: :text,
                label: "Country (Custom)", toggle_hint: "Use custom value",
                hint: "Must be a valid 2-digit ISO country code"
              } },
            { name: "state_id", hint: "US state only" },
            { name: "zip" }
          ] },
          { name: "dental", type: :object, properties: [
            { name: "beneficiary" },
            { name: "amount" },
            { name: "currency_type", hint: "Default is USD" }
          ] },
          { name: "links", type: :object, properties: [
            { name: "job_title", label: "Job title", type: :object,
              properties: [name: "title", label: "Title"] },
            { name: "groups", type: :array, of: :object,
              properties: [name: "name", label: "Group name"] },
            { name: "teams", type: :array, of: :object,
              properties: [name: "name", label: "Team name"] }
          ] },
          { name: "reports_to", type: :array, of: :object, properties: [
            { name: "id", label: "Profile ID" },
            { name: "first_name:", label: "First name" },
            { name: "last_name", label: "Last name" },
            { name: "preferred_name", label: "Preferred name" },
            { name: "email", label: "Email address" }
          ] },
          { name: "team_positions", label: "Team positions" },
          { name: "custom_fields", type: "object", properties: custom_fields }
        ]
        standard_fields
      }
    },

    event: {
      fields: lambda do
        [
          { name: "id", label: "ID" },
          { name: "href", label: "URL" },
          { name: "type" },
          { name: "time", type: :integer },
          { name: "utc_offset", label: "UTC offset", type: :integer },
          { name: "content" },
          { name: "html_content" },
          { name: "years_at_company", type: :integer },
          { name: "use_comments", label: "Use comments?", type: :boolean,
            control_type: :checkbox },
          { name: "can_comment", label: "Can comment?", type: :boolean,
            control_type: :checkbox },
          { name: "can_destroy", label: "Can destroy?", type: :boolean,
            control_type: :checkbox },
          { name: "links", type: :object, properties: [
            { name: "profile" },
            { name: "comments", type: :array, of: :string },
            { name: "file" },
            { name: "appreciations", type: :array, of: :string },
          ] },
          { name: "can_like", label: "Can like?", type: :boolean,
            control_type: :checkbox },
          { name: "likes_count", type: :integer },
          { name: "liked_by_current_profile", type: :boolean,
            control_type: :checkbox }
        ]
      end
    },

    comment: {
      fields: lambda do
        [
          { name: "id", label: "ID" },
          { name: "content" },
          { name: "html_content" },
          { name: "created_at", type: :integer },
          { name: "can_destroy", label: "Can destroy?", type: :boolean,
            control_type: :checkbox },
          { name: "links", type: :object, properties: [
            { name: "profile" },
          ] },
          { name: "utc_offset", label: "UTC offset", type: :boolean,
            control_type: :checkbox },
          { name: "likes_count", type: :integer },
          { name: "liked_by_current_profile", type: :boolean,
            control_type: :checkbox },
        ]
      end
    }
  },

  test: lambda do |_connection|
    get("/api/v1/profiles/me")
  end,

  actions: {
    create_announcement: {
      description: 'Create <span class="provider">announcement</span> '\
        'in <span class="provider">Namely</span>',
      subtitle: "Create announcement in Namely",

      input_fields: lambda do
        [
          { name: "content", label: "Announcement text", optional: false,
            hint: "Format in Markdown. Use syntax "\
                  "[full_name](/people/profile_id) to mention a profile" },
          { name: "is_appreciation", type: :boolean, control_type: :checkbox,
            label: "Is appreciation?", optional: true, toggle_hint: "Select from list",
            hint: "If true, any @mentioned profile will be appreciated",
            toggle_field: {
              name: "is_appreciation", type: :string, control_type: :text,
              label: "Is appreciation? (Custom)", toggle_hint: "Use custom value",
            } },
          { name: "email_all", type: :boolean, control_type: :checkbox,
            label: "Email all employees?", optional: true, toggle_hint: "Select from list",
            hint: "if true, will send an email to all active profiles",
            toggle_field: {
              name: "email_all", type: :string, control_type: :text,
              label: "Email all employees? (Custom)", toggle_hint: "Use custom value",
            } },
          { name: "file_id", optional: true,
            hint: "File ID of previously uploaded file" }
        ]
      end,

      execute: lambda do |_connection, input|
        post("/api/v1/events").payload(events: [input])["events"].first
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["event"]
      end,

      sample_output: lambda do |_connection|
        get("/api/v1/events.json?type=announcement").
          params(page: 1, per_page: 1)["events"]
      end
    },

    create_event_comment: {
      description: 'Create <span class="provider">event comment</span> '\
        'in <span class="provider">Namely</span>',
      subtitle: "Create an event comment in Namely",

      input_fields: lambda do
        [
          { name: "event_id", label: "Event ID", optional: false },
          { name: "content", label: "Comment", optional: false,
            hint: "Format in Markdown. Use syntax "\
                  "[full_name](/people/profile_id) to mention a profile" }
        ]
      end,

      execute: lambda do |_connection, input|
        post("/api/v1/events/#{input['event_id']}/comments").
          payload(comments: [input])["comments"].first
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["comment"]
      end,

      sample_output: lambda do |_connection|
        get("/api/v1/events.json").
          params(page: 1, per_page: 1)["events"]
      end
    },

    like_event_by_id: {
      description: 'Like an <span class="provider">event</span> '\
        'in <span class="provider">Namely</span>',
      subtitle: "Like an event in Namely",
      hint: "Like functionality must be enabled in your Namely instance",

      input_fields: lambda do
        [
          { name: "id", label: "Event ID", optional: false }
        ]
      end,

      execute: lambda do |_connection, input|
        post("/api/v1/likes/event/#{input['id']}")["message"]
      end,

      output_fields: lambda do
        [
          { name: "likes_count", type: :integer },
          { name: "liked_by_current_profile", type: :boolean }
        ]
      end,

      sample_output: lambda do
        {
          "likes_count": 10,
          "liked_by_current_profile": true
        }
      end
    },

    like_comment_by_id: {
      description: 'Like an event or announcement\'s
        <span class="provider">comment</span> '\
        'in <span class="provider">Namely</span>',
      subtitle: "Like an event or announcement's comment in Namely",
      hint: "Like functionality must be enabled in your Namely instance",

      input_fields: lambda do
        [
          { name: "id", label: "Comment ID", optional: false }
        ]
      end,

      execute: lambda do |_connection, input|
        post("/api/v1/likes/event_comment/#{input['id']}")["message"]
      end,

      output_fields: lambda do
        [
          { name: "likes_count", type: :integer },
          { name: "liked_by_current_profile", type: :boolean }
        ]
      end,

      sample_output: lambda do
        {
          "likes_count": 10,
          "liked_by_current_profile": true
        }
      end
    },

    create_employee_profile: {
      description: 'Create <span class="provider">employee profile</span> '\
        'in <span class="provider">Namely</span>',
      subtitle: "Create employee profile in Namely",

      input_fields: lambda do |object_definitions|
        object_definitions["profile_input"].required(
          "email",
          "first_name",
          "last_name",
          "user_status",
          "start_date"
        )
      end,

      execute: lambda do |_connection, input|
        post("/api/v1/profiles").
          payload(profiles: input)["profiles"].first
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["profile_output"]
      end,

      sample_output: lambda do |_connection|
        get("/api/v1/profiles.json").
          params(page: 1, per_page: 1)["profiles"]
      end
    },

    update_employee_profile: {
      description: 'Update <span class="provider">employee profile</span> '\
        'in <span class="provider">Namely</span>',
      subtitle: "Update employee profile in Namely",

      input_fields: lambda do |object_definitions|
        [
          { name: "profile_id", label: "Profile ID", optional: false },
          { name: "profile", optional: false, type: :object,
            properties: object_definitions["profile_input"] }
        ]
      end,

      execute: lambda do |_connection, input|
        put("/api/v1/profiles/#{input['profile_id']}").
          payload(profiles: input["profile"])["profiles"].first
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["profile_output"]
      end,

      sample_output: lambda do |_connection|
        get("/api/v1/profiles.json").
          params(page: 1, per_page: 1)["profiles"]
      end
    },

    get_employee_profile_by_id: {
      description: 'Get <span class="provider">employee profile</span> '\
        'by ID in <span class="provider">Namely</span>',
      subtitle: "Get employee profile by ID in Namely",

      input_fields: lambda do
        [
          { name: "id", optional: false }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/api/v1/profiles/#{input['id']}")["profiles"].first
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["profile_output"]
      end,

      sample_output: lambda do |_connection|
        get("/api/v1/profiles.json").
          params(page: 1, per_page: 1)["profiles"].first
      end
    },

    search_employee_profiles: {
      description: 'Search <span class="provider">employee profiles</span> '\
        'in <span class="provider">Namely</span>',
      subtitle: "Search employee profiles in Namely",
      help: "Use the input fields to add filters to employee profile results. "\
        "Leave input fields blank to return all employee profiles.",

      input_fields: lambda do
        [
          { name: "first_name", optional: true, sticky: true },
          { name: "last_name", optional: true, sticky: true },
          { name: "email", label: "Company email", optional: true, sticky: true },
          { name: "personal_email", optional: true },
          { name: "job_title", optional: true,
            hint: "ID of job title, or the name of the title as defined
            in your Namely instance" },
          { name: "reports_to", optional: true,
            hint: "ID of employee profile whom employee reports to" },
          { name: "user_status", optional: true, control_type: :select,
            pick_list: "employee_status", toggle_hint: "Select from list",
            toggle_field: {
              name: "user_status", type: :string, control_type: :text,
              label: "User status (Custom)", toggle_hint: "Use custom value"
            }, hint: "Inactive user status also returns pending profiles" },
          { name: "start_date", type: :date, optional: true }
        ]
      end,

      execute: lambda do |_connection, input|
        params = if input["first_name"].present?
                   "&filter[first_name]=#{input['first_name']}"
                 else ""
                 end +
                 if input["last_name"].present?
                   "&filter[last_name]=#{input['last_name']}"
                 else ""
                 end +
                 if input["email"].present?
                   "&filter[email]=#{input['email']}"
                 else ""
                 end +
                 if input["personal_email"].present?
                   "&filter[personal_email]=#{input['personal_email']}"
                 else ""
                 end +
                 if input["job_title"].present?
                   "&filter[job_title]=#{input['job_title']}"
                 else ""
                 end +
                 if input["reports_to"].present?
                   "&filter[reports_to]=#{input['reports_to']}"
                 else ""
                 end +
                 if input["user_status"].present?
                   "&filter[user_status]=#{input['user_status']}"
                 else ""
                 end
        employees = []
        page = 1
        count = 1
        while count != 0
          response =
            get("/api/v1/profiles.json?" +
              params.gsub(/\s+/, ""), page: page, per_page: 50)
          count = response["meta"]["count"]
          employees.concat(response["profiles"])
          page = page + 1
        end
        employees = employees.to_a
        if input["start_date"].present?
          employees = employees.where("start_date" => input["start_date"].to_s)
        end
        { "profiles": employees }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: "profiles",
            type: :array,
            of: :object,
            properties: object_definitions["profile_output"] }
        ]
      end,

      sample_output: lambda do |_connection|
        {
          "profiles": get("/api/v1/profiles.json").
                        params(page: 1, per_page: 1)["profiles"]
        }
      end
    },
    search_events: {
      description: 'Search <span class="provider">events</span> '\
        'in <span class="provider">Namely</span>',
      subtitle: "Search Events in Namely",
      help: "Use the input fields to add filters to Events results. "\
        "Leave input fields blank to return all Events.",
      input_fields: lambda do
        [
          { name: "after", optional: true, hint: "ID of the first record BEFORE
            the events you want to retrieve", sticky: true },
          { name: "event_type", label: "Event type", optional: true, sticky: true,
            toggle_hint: "Select from list", control_type: :select, pick_list: "event_type",
            toggle_field: {
              name: "event_type", type: :string, control_type: :text,
              label: "Event Type (Custom)", toggle_hint: "Use custom value",
              hint: "The type of event you want to retrieve"
            } },
          { name: "profile_id", label: "Profile ID",
            hint: "ID of the profile that you wish to pull all associated events from",
            optional: true, sticky: true }
        ]
      end,
      execute: lambda do |_connection, input|
        params = if input["after"].present?
                   "&after=#{input['after']}"
                 else ""
                 end +
                 if input["event_type"].present?
                   "&filter[type]=#{input['event_type']}"
                 else ""
                 end +
                 if input["profile_id"].present?
                   "&profile_id=#{input['profile_id']}"
                 else ""
                 end
        events = get("/api/v1/events.json?" + params.gsub(/\s+/, ""))["events"]
        { "events": events }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: "events",
            type: :array,
            of: :object,
            properties: object_definitions["event"] }
        ]
      end,
      sample_output: lambda do |_connection|
        {
          "events": get("/api/v1/events.json").
                      params(page: 1, per_page: 1)["events"]
        }
      end
    },
    search_events_by_id: {
      description: 'Search <span class="provider">Events</span> '\
        'by ID in <span class="provider">Namely</span>',
      subtitle: "Search Events by ID in Namely",

      input_fields: lambda do
        [
          { name: "id", label: "Event ID", optional: false }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/api/v1/events/#{input['id']}")["events"].first
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["event"]
      end,

      sample_output: lambda do |_connection|
        get("/api/v1/events.json").
          params(page: 1, per_page: 1)["events"].first
      end
    },
  },

  triggers: {},

  pick_lists: {
    jobs: lambda do |_connection|
      get("/api/v1/job_titles.json").
        dig("job_titles").
        map { |c| [c["title"], c["id"]] }
    end,

    countries: lambda do |_connection|
      get("/api/v1/countries.json").
        dig("countries").
        map { |c| [c["name"], c["id"]] }
    end,

    currencies: lambda do |_connection|
      get("/api/v1/currency_types.json").
        dig("currency_types").
        map { |c| [c["name"], c["iso"]] }
    end,

    employee_status: lambda do
      [
        %w(Active active),
        %w(Inactive inactive),
        %w(Pending pending)
      ]
    end,

    gender: lambda do
      [
        %w(Male Male),
        %w(Female Female)
      ]
    end,

    access_role: lambda do
      [
        %w(Administrator Administrator),
        %w(HR\ Admin HR\ Admin),
        %w(Executive\ Admin Executive\ Admin),
        %w(Manager Manager),
        %w(Employee Employee)
      ]
    end,
    marital_status: lambda do
      [
        %w(Single Single),
        %w(Married Married),
        %w(Civil\ Partnership Civil\ Partnership),
        %w(Separated Separated),
        %w(Divorced Divorced)
      ]
    end,
    employee_type: lambda do
      [
        %w(Full\ Time Full\ Time),
        %w(Part\ Time Part\ Time),
        %w(Contractor Contractor),
        %w(Intern Intern),
        %w(Freelance Freelance)
      ]
    end,
    event_type: lambda do
      [
        %w(Birthday birthday),
        %w(Announcement announcement),
        %w(Recent\ Arrival recent_arrival),
        %w(Anniversary anniversary)
      ]
    end
  }
}
