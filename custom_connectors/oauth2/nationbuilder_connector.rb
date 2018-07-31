# Adds operations missing from the standard adapter.
{
  title: "NationBuilder (custom)",
  connection: {
    fields: [
      {
        name: "subdomain",
        label: "Nation slug",
        control_type: "subdomain",
        url: ".nationbuilder.com",
        optional: false,
        hint: "Your nation slug as found in your NationBuilder URL, e.g. " \
          "<b>votefornation</b>.nationbuilder.com"
      },
      {
        name: "client_id",
        hint: "Find client ID " \
          "<a href='https://workato.nationbuilder.com/admin/apps'>" \
          "here</a>",
        optional: false
      },
      {
        name: "client_secret",
        hint: "Find client secret " \
          "<a href='https://workato.nationbuilder.com/admin/apps'>" \
          "here</a>",
        optional: false,
        control_type: "password"
      }
    ],

    authorization: {
      type: "oauth2",

      authorization_url: lambda { |connection|
        "https://#{connection['subdomain']}.nationbuilder.com/" \
          "oauth/authorize?response_type=code&client_id=" \
          "#{connection['client_id']}"
      },

      token_url: lambda { |connection|
        "https://#{connection['subdomain']}" \
          ".nationbuilder.com/oauth/token?client_id=" \
          "#{connection['client_id']}&client_secret=" \
          "#{connection['client_secret']}"
      },

      apply: lambda { |_connection, access_token|
        headers("Authorization": "Bearer #{access_token}")
      }
    },

    base_uri: lambda { |connection|
      "https://#{connection['subdomain']}.nationbuilder.com"
    }
  },

  object_definitions: {
    person: {
      fields: lambda {
        [
          { name: "birth_date", type: "date" },
          { name: "city_district" },
          { name: "civicrm_id" },
          { name: "county_district" },
          { name: "county_file_id" },
          { name: "created_at", type: "date_time" },
          { name: "do_not_call", control_type: "checkbox", type: "boolean" },
          { name: "do_not_contact", control_type: "checkbox", type: "boolean" },
          { name: "dw_id" },
          { name: "email_opt_in", control_type: "checkbox", type: "boolean" },
          { name: "email", control_type: "email" },
          { name: "employer" },
          { name: "external_id" },
          { name: "federal_district" },
          { name: "fire_district" },
          { name: "first_name" },
          { name: "has_facebook", control_type: "checkbox", type: "boolean" },
          { name: "id" },
          {
            name: "is_twitter_follower",
            control_type: "checkbox",
            type: "boolean"
          },
          { name: "is_volunteer", control_type: "checkbox", type: "boolean" },
          { name: "judicial_district" },
          { name: "labour_region" },
          { name: "last_name" },
          { name: "linkedin_id" },
          { name: "mobile_opt_in", control_type: "checkbox", type: "boolean" },
          { name: "mobile", control_type: "phone" },
          { name: "nbec_guid" },
          { name: "ngp_id" },
          { name: "note" },
          { name: "occupation" },
          { name: "party" },
          { name: "pf_strat_id" },
          { name: "phone", control_type: "phone" },
          { name: "precinct_id" },
          {
            name: "primary_address",
            type: "object",
            properties: [
              { name: "address1" },
              { name: "address2" },
              { name: "address3" },
              { name: "city" },
              { name: "state" },
              { name: "zip" },
              { name: "country_code" },
              { name: "lat" },
              { name: "long" }
            ]
          },
          { name: "recruiter_id" },
          { name: "rnc_id" },
          { name: "rnc_regid" },
          { name: "school_district" },
          { name: "school_sub_district" },
          { name: "sex", control_type: "select", pick_list: "genders" },
          { name: "state_file_id" },
          { name: "state_lower_district" },
          { name: "state_upper_district" },
          { name: "support_level", type: "integer" },
          { name: "supranational_district" },
          { name: "tags", type: "array", properties: [] },
          { name: "twitter_id" },
          { name: "twitter_name" },
          { name: "updated_at", type: "date_time" },
          { name: "van_id" },
          { name: "village_district" }
        ]
      }
    },

    survey_response: {
      fields: lambda {
        [
          { name: "id", type: "integer" },
          { name: "survey_id", type: "integer" },
          { name: "person_id", type: "integer" },
          { name: "created_at", type: "date_time" },
          { name: "updated_at", type: "date_time" },
          {
            name: "question_responses",
            type: "array",
            of: "object",
            properties: [
              { name: "id", type: "integer" },
              { name: "response" },
              { name: "question_id", type: "integer" }
            ]
          }
        ]
      }
    }
  },

  test: ->(_connection) { get("/api/v1/people/count") },

  actions: {
    search_people: {
      subtitle: "Search people",
      description: "Search <span class='provider'>people</span> in " \
        "<span class='provider'>NationBuilder</span>",
      help: "Returns a list of people that matches the search criteria. ",

      input_fields: lambda { |object_definitions|
        object_definitions["person"].
          only("first_name", "last_name", "email", "city", "state", "sex",
               "birthdate", "updated_since", "with_mobile", "salesforce_id",
               "external_id")
      },

      execute: lambda { |_connection, input|
        {
          people: get("/api/v1/people/search", input).
            params(per_page: 100)["results"] || []
        }
      },

      output_fields: lambda { |object_definitions|
        [{
          name: "people",
          type: "array",
          of: "object",
          properties: object_definitions["person"]
        }]
      },

      sample_output: lambda { |_connection|
        {
          people: get("/api/v1/people/search").
            params(per_page: 1)["results"] || []
        }
      }
    },

    get_person_by_id: {
      subtitle: "Get person by ID",
      description: "Get <span class='provider'>person</span> by ID in " \
        "<span class='provider'>NationBuilder</span>",
      help: "Retrieve the data of a person by ID or external ID. ",

      input_fields: lambda { |object_definitions|
        object_definitions["person"].only("id", "external_id")
      },

      execute: lambda { |_connection, input|
        get(if input["external_id"].present?
              "/api/v1/people/#{input['external_id']}?id_type=external"
            else
              "/api/v1/people/#{input['id']}"
            end)["person"] || {}
      },

      output_fields: ->(object_definitions) { object_definitions["person"] },

      sample_output: lambda { |_connection|
        get("/api/v1/people/search").params(per_page: 1).dig("results", 0) || {}
      }
    },

    match_person: {
      subtitle: "Match person",
      description: "Match <span class='provider'>person</span> in " \
        "<span class='provider'>NationBuilder</span>",
      help: "Use this match to find a person that have certain attributes. " \
        "A single person must match the given criteria for a successful job. ",

      input_fields: lambda { |object_definitions|
        object_definitions["person"].
          only("first_name", "last_name", "email", "phone", "mobile")
      },

      execute: lambda { |_connection, input|
        get("/api/v1/people/match").params(input)["person"] || {}
      },

      output_fields: ->(object_definitions) { object_definitions["person"] },

      sample_output: lambda { |_connection|
        get("/api/v1/people/search").params(per_page: 1).dig("results", 0) || {}
      }
    }
  },

  triggers: {
    new_or_updated_person: {
      subtitle: "New or updated person",
      description: "New or updated <span class='provider'>person</span> in " \
        "<span class='provider'>NationBuilder</span>",

      input_fields: lambda { |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          sticky: true,
          hint: "Fetch trigger events from specified time. " \
            "Leave empty to get person created or updated one hour ago"
        }]
      },

      poll: lambda { |_connection, input, closure|
        closure ||= [nil, nil]
        uri = closure[0]
        response = if uri.present?
                     get(uri)
                   else
                     get("/api/v1/people/search").
                       params(per_page: 100,
                              updated_since: (closure[1] || input["since"] ||
                                1.hour.ago).to_time.utc.iso8601)
                   end
        next_uri = response["next"]
        closure = (next_uri ? [next_uri, nil] : [nil, now])

        {
          events: response["results"] || [],
          next_poll: closure,
          can_poll_more: next_uri.present?
        }
      },

      dedup: ->(person) { person["id"].to_s + "@" + person["updated_at"] },

      output_fields: ->(object_definitions) { object_definitions["person"] },

      sample_output: lambda { |_connection|
        get("/api/v1/people/search").params(per_page: 1).dig("results", 0) || {}
      }
    },

    new_survey_response: {
      subtitle: "New survey response",
      description: "New <span class='provider'>survey response" \
        "</span> in <span class='provider'>NationBuilder</span>",
      type: "paging_desc",

      input_fields: lambda { |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          sticky: true,
          hint: "Fetch trigger events from specified time. Leave empty " \
            "to get survey response created one hour ago"
        }]
      },

      poll: lambda { |_connection, input, next_uri|
        response = if next_uri.present?
                     get(next_uri)
                   else
                     get("/api/v1/survey_responses").
                       params(per_page: 100,
                              start_time: (input["since"] ||
                                1.hour.ago).to_time.to_i)
                   end

        { events: response["results"] || [], next_page: response["next"] }
      },

      document_id: ->(survey_response) { survey_response["id"] },

      sort_by: ->(survey_response) { survey_response["created_at"] },

      output_fields: lambda { |object_definitions|
        object_definitions["survey_response"]
      },

      sample_output: lambda { |_connection|
        get("/api/v1/survey_responses").
          params(per_page: 1).
          dig("results", 0) || {}
      }
    }
  },

  pick_lists: {
    genders: ->(_connection) { [%w[Male M], %w[Female F], %w[Other O]] }
  }
}
