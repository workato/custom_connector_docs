{
  title: "Intercom (Custom)",

  connection: {
    fields: [
      {
        name: "client_id",
        label: "Client ID",
        hint: "You can find your client ID in the settings page.",
        optional: false
      },
      {
        name: "client_secret",
        control_type: "password",
        hint: "You can find your client ID in the settings page.",
        optional: false
      }
    ],

    authorization: {
      type: "oauth2",

      authorization_url: lambda { |connection|
        "https://app.intercom.io/oauth?client_id=#{connection['client_id']}"
      },

      token_url: lambda { |connection|
        "https://api.intercom.io/auth/eagle/token?" \
          "client_id=#{connection['client_id']}&" \
          "client_secret=#{connection['client_secret']}"
      },

      apply: lambda { |_connection, access_token|
        headers("Authorization": "Bearer #{access_token}")
      }
    },

    base_uri: lambda do
      "https://api.intercom.io"
    end
  },

  test: ->(_connection) { get("/users/") },

  object_definitions: {
    user: {
      fields: lambda do
        [
          { name: "type" },
          { name: "id" },
          { name: "user_id" },
          { name: "email", control_type: "email" },
          { name: "name" },
          { name: "app_id" },
          { name: "last_seen_ip" },
          { name: "unsubscribed_from_emails", type: "boolean",
            controL_type: "checkbox" },
          { name: "created_at", type: "integer" },
          { name: "last_request_at", type: "integer" },
          { name: "remote_created_at", type: "integer" },
          { name: "signed_up_at", type: "integer" },
          { name: "updated_at", type: "integer" },
          { name: "session_count", type: "integer" },
          { name: "user_agent_data" },
          { name: "referrer", control_type: "url" },
          { name: "utm_campaign", label: "UTM Campaign" },
          { name: "utm_source", label: "UTM Source" },
          { name: "utm_content", label: "UTM Content" },
          { name: "utm_term", label: "UTM Term" },
          { name: "utm_medium", label: "UTM Medium" },
          {
            name: "custom_attributes", type: "object", properties: [
              { name: "phone", type: "number", control_type: "phone" },
              { name: "job_role" },
              { name: "company_size" },
              { name: "mixpanel_id" },
              { name: "precreated_app_id" },
              { name: "invitation_id", type: "integer" },
              { name: "account_id", type: "integer" },
              { name: "mobile_app_signup", type: "boolean",
                controL_type: "checkbox" },
              { name: "type" },
              { name: "confirmed_at", type: "integer" },
              { name: "sign_in_count", type: "integer" },
              { name: "handle" },
              { name: "time_zone" },
              { name: "company_name" },
              { name: "twitter_url" },
              { name: "linkedin_url" },
              { name: "website_url" },
              { name: "applications" },
              { name: "connectors_names" },
              { name: "apps_connected" },
              { name: "connectors_count", type: "integer" },
              { name: "connectors_used", type: "integer" },
              { name: "app_ids" },
              { name: "recipe_tour_completed", type: "boolean",
                controL_type: "checkbox" },
              { name: "plan" },
              { name: "in_trial", type: "boolean",
                controL_type: "checkbox" },
              { name: "stripe_id" },
              { name: "stripe_plan" },
              { name: "stripe_plan_price", type: "integer" },
              { name: "stripe_delinquent", type: "boolean",
                controL_type: "checkbox" },
              { name: "stripe_account_balance", type: "integer" },
              { name: "stripe_plan_interval" },
              { name: "stripe_subscription_status" },
              { name: "stripe_card_brand" },
              { name: "stripe_subscription_period_start_at", type: "integer" },
              { name: "stripe_card_expires_at", type: "integer" },
              { name: "stripe_last_charge_amount", type: "integer" },
              { name: "stripe_last_charge_at", type: "integer" },
              { name: "recipe_count", type: "integer" },
              { name: "active_recipe_count", type: "integer" },
              { name: "start_failed_count", type: "integer" },
              { name: "start_succeeded_count", type: "integer" },
              { name: "jobs_all_success_count", type: "integer" },
              { name: "jobs_all_failure_count", type: "integer" },
              { name: "jobs_month_success_count", type: "integer" },
              { name: "jobs_month_failure_count", type: "integer" },
              { name: "jobs_month_total_count", type: "integer" },
              { name: "total_unread_count", type: "integer" },
              { name: "xapp_0_instance_id", type: "integer" },
              { name: "xapp_0_name" },
              { name: "xapp_0_installed_at", type: "integer" },
              { name: "xapp_1_instance_id", type: "integer" },
              { name: "xapp_1_name" },
              { name: "xapp_1_installed_at", type: "integer" },
              { name: "utm_source" },
              { name: "nps_sent" },
              { name: "nps_latest_sent_date_at" },
              { name: "nps_complete" },
              { name: "salesforce_record_id" }
            ]
          },
          {
            name: "avatar", type: "object", properties: [
              { name: "type" },
              { name: "image_url", control_type: "url" }
            ]
          },
          {
            name: "location_data", type: "object", properties: [
              { name: "type" },
              { name: "city_name" },
              { name: "continent_code" },
              { name: "country_code" },
              { name: "country_name" },
              { name: "latitude", type: "number" },
              { name: "longitude", type: "number" },
              { name: "postal_code" },
              { name: "region_name" },
              { name: "timezone" }
            ]
          },
          {
            name: "social_profiles", type: "object", properties: [
              { name: "type" },
              {
                name: "social_profiles",
                type: :array,
                of: :object,
                properties: [
                  { name: "name" },
                  { name: "id" },
                  { name: "username" },
                  { name: "url", control_type: "url" }
                ]
              }
            ]
          },
          {
            name: "companies", type: "object", properties: [
              { name: "type" },
              {
                name: "companies", type: :array, of: :object, properties: [
                  { name: "id" },
                  { name: "company_id" },
                  { name: "name" }
                ]
              }
            ]
          },
          {
            name: "segments", type: "object", properties: [
              { name: "type" },
              {
                name: "segments", type: "array", of: "object", properties: [
                  { name: "type" },
                  { name: "id" }
                ]
              }
            ]
          },
          {
            name: "tags", type: "object", properties: [
              { name: "type" },
              {
                name: "tags", type: "array", of: "object", properties: [
                  { name: "type" },
                  { name: "name" },
                  { name: "id" }
                ]
              }
            ]
          }
        ]
      end
    },

    company: {
      fields: lambda do
        [
          { name: "id" },
          { name: "company_id" },
          { name: "created_at", type: "integer" },
          { name: "updated_at", type: "integer" },
          { name: "monthly_spend", type: "integer" },
          { name: "name" },
          { name: "plan", type: "object", properties:
            [{ name: "id" }, { name: "name" }] },
          { name: "type" },
          { name: "app_id" }
        ]
      end
    },

    admin: {
      fields: lambda do
        [
          { name: "id" },
          { name: "type" },
          { name: "email", control_type: "email" },
          { name: "name" }
        ]
      end
    },

    admin_action: {
      fields: lambda do
        [
          { name: "id" },
          { name: "topic" },
          { name: "type" },
          { name: "app_id" },
          { name: "data", type: "object", properties:
            [
              { name: "type" },
              { name: "item", type: "object", properties:
                [
                  { name: "type" },
                  { name: "id" },
                  { name: "created_at", type: "integer" },
                  { name: "updated_at", type: "integer" },
                  { name: "user", type: "object", properties:
                    [
                      { name: "type" },
                      { name: "id" },
                      { name: "user_id" },
                      { name: "name" },
                      { name: "email" }
                    ] },
                  { name: "assignee", type: "object", properties:
                    [
                      { name: "type" },
                      { name: "id" },
                      { name: "name" },
                      { name: "email" }
                    ] },
                  { name: "open" },
                  { name: "read" },
                  { name: "links", type: "object", properties:
                    [{ name: "conversation_web" }] }
                ] }
            ] },
          { name: "delivery_status" },
          { name: "delivery_attempts", type: "integer" },
          { name: "delivered_at", type: "integer" },
          { name: "first_sent_at", type: "integer" },
          { name: "created_at", type: "integer" }
        ]
      end
    },

    conversation: {
      fields: lambda do
        [
          { name: "id" },
          { name: "created_at", type: "integer" },
          { name: "updated_at", type: "integer" },
          {
            name: "conversation_message", type: "object", properties: [
              { name: "id" },
              { name: "subject" },
              { name: "body" },
              {
                name: "author", type: "object", properties: [
                  { name: "type" },
                  { name: "id" }
                ]
              }
            ]
          },
          {
            name: "user", type: "object", properties: [
              { name: "id" }
            ]
          },
          {
            name: "assignee", type: "object", properties: [
              { name: "id" }
            ]
          },
          { name: "open", type: "boolean", controL_type: "checkbox" },
          { name: "read", type: "boolean", controL_type: "checkbox" }
        ]
      end
    },

    event: {
      fields: lambda do
        [
          {
            control_type: "text",
            label: "Type",
            name: "type"
          },
          {
            control_type: "text",
            label: "ID",
            name: "id"
          },
          {
            control_type: "text",
            label: "Intercom ID",
            name: "intercom_user_id"
          },
          {
            control_type: "email",
            label: "Email",
            type: "string",
            name: "email"
          },
          {
            control_type: "text",
            label: "Event name",
            type: "string",
            name: "event_name"
          },
          {
            control_type: "integer",
            label: "Created at",
            parse_output: "integer_conversion",
            type: "integer",
            name: "created_at"
          },
          {
            control_type: "text",
            label: "User ID",
            name: "user_id"
          },
          {
            controL_type: "text",
            label: "Metadata",
            name: "metadata"
          }
        ]
      end
    }
  },

  actions: {
    get_admin_by_id: {
      description: "Get <span class='provider'>admin</span> by ID in " \
        "<span class='provider'>Intercom (Custom)</span>",
      subtitle: "Get admin by ID in Intercom (Custom)",
      help: "Retrieves an admin in Intercom using the internal admin ID.",

      input_fields: lambda do |_object_definitions|
        [{ name: "admin_id", optional: false }]
      end,

      execute: lambda do |_connection, input|
        get("/admins/#{input['admin_id']}")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["admin"]
      end
    },

    reply_to_conversation_as_admin: {
      description: "Reply to <span class='provider'>conversation</span> as " \
        "admin in <span class='provider'>Intercom (Custom)</span>",

      input_fields: lambda do
        [
          { name: "conversation_id", type: "integer" },
          {
            name: "admin_id", optional: false,
            label: "Admin", hint: "Select an admin in Intercom",
            control_type: "select", pick_list: "admins",
            toggle_hint: "Select from list",
            toggle_field: {
              name: "admin_id",
              label: "Admin ID",
              type: "string",
              control_type: "text",
              toggle_hint: "Use custom value",
              hint: "Enter an admin ID from Intercom"
            }
          },
          { name: "body" }
        ]
      end,

      execute: lambda do |_connection, input|
        payload = { "type": "admin",
                    "message_type": "comment",
                    "admin_id": input["admin_id"],
                    "body": input["body"] }
        post("/conversations/#{input['conversation_id']}/reply", payload)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["conversation"]
      end
    },

    search_company: {
      description: "Search <span class='provider'>companies</span> " \
        "<span class='provider'>Intercom (Custom)</span>",
      help: "Returns up to 50 records.",

      input_fields: lambda do |_object_definitions|
        [
          {
            name: "name", optional: false,
            control_type: "text",
            label: "Company Name",
            hint: "Enter an company name to search for",
            toggle_hint: "Search by company name",
            toggle_field: {
              name: "company_id",
              label: "Company ID",
              type: "string",
              control_type: "text",
              toggle_hint: "Search by company ID",
              hint: "Enter a company ID"
            }
          }
        ]
      end,

      execute: lambda do |_connection, input|
        if input["name"].present?
          get("/companies").
            params(name: input["name"])
        elsif input["company_id"].present?
          get("/companies").
            params(company_id: input["company_id"])
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["company"]
      end
    },

    create_or_update_company: {
      title: "Create/Update company",
      description: "Creates/Updates a <span class='provider'>company" \
        "</span> in <span class='provider'>Intercom (Custom)</span>",
      help: "Creates a company if Company ID doesn't exist in Intercom, " \
        "and updates if it does.",

      input_fields: lambda do |_object_definitions|
        [
          { name: "company_id", optional: false },
          { name: "name", optional: false },
          { name: "monthly_spend", label: "Monthly spend" },
          { name: "plan" }
        ]
      end,

      execute: lambda do |_connection, input|
        data = input.reject { |_k, v| v.blank? }
        post("/companies").
          payload(data)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["company"]
      end
    },

    get_admins: {
      description: "Get <span class='provider'>admins</span> in " \
        "<span class='provider'>Intercom (Custom)</span>",
      help: "Returns up to 50 records.",

      execute: lambda do |_connection|
        {
          admins: get("/admins")["admins"]
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: "admins",
            type: "array",
            of: "object",
            properties: object_definitions["admin"] }
        ]
      end
    }
  },

  triggers: {
    admin_assigned_conversation: {
      title: "New assigned conversation to user",
      description: "New <span class='provider'>assigned conversation</span> " \
        "by admin in <span class='provider'>Intercom (Custom)</span>",
      help: "Triggers when a conversation is assigned/unassigned in Intercom.",
      subtitle: "New assigned conversation by admin in Intercom (Custom)",

      webhook_subscribe: lambda do |webhook_url, _connection|
        post("/subscriptions").
          payload(topics: ["conversation.admin.assigned"],
                  url: webhook_url)
      end,

      webhook_notification: lambda do |_input, payload|
        if payload["topic"].present? && payload["topic"] == "ping"
          nil
        else
          payload
        end
      end,

      webhook_unsubscribe: lambda do |webhook|
        delete("/subscriptions/#{webhook['id']}")
      end,

      dedup: lambda do |message|
        message["id"] + "@" + message["created_at"].to_s
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["admin_action"]
      end
    },

    conversation_closed: {
      title: "New closed conversation",
      description: "New <span class='provider'>closed conversation</span> in" \
        " <span class='provider'>Intercom (Custom)</span>",
      help: "Triggers when a conversation is marked as closed in Intercom",
      subtitle: "Admin closed a conversation in Intercom (Custom)",

      webhook_subscribe: lambda do |webhook_url, _connection|
        post("/subscriptions").
          payload(topics: ["conversation.admin.closed"],
                  url: webhook_url)
      end,

      webhook_notification: lambda do |_input, payload|
        if payload["topic"].present? && payload["topic"] == "ping"
          nil
        else
          payload
        end
      end,

      webhook_unsubscribe: lambda do |webhook|
        delete("/subscriptions/#{webhook['id']}")
      end,

      dedup: lambda do |message|
        message["id"] + "@" + message["created_at"].to_s
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["admin_action"]
      end
    },

    conversation_opened: {
      title: "New opened conversation",
      description: "New <span class='provider'>opened conversation</span> " \
        "in <span class='provider'>Intercom (Custom)</span>",
      help: "Triggers when a conversation is opened in Intercom",
      subtitle: "Admin opened a conversation in Intercom (Custom)",

      webhook_subscribe: lambda do |webhook_url, _connection|
        post("/subscriptions").
          payload(topics: ["conversation.admin.opened"],
                  url: webhook_url)
      end,

      webhook_notification: lambda do |_input, payload|
        if payload["topic"].present? && payload["topic"] == "ping"
          nil
        else
          payload
        end
      end,

      webhook_unsubscribe: lambda do |webhook|
        delete("/subscriptions/#{webhook['id']}")
      end,

      dedup: lambda do |message|
        message["id"] + "@" + message["created_at"].to_s
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["conversation"]
      end
    }
  },

  pick_lists: {
    admins: lambda do |_connection|
      get("/admins")["admins"].pluck("name", "id")
    end
  }
}
