{
  title: "Constant Contact",

  connection: {
    fields: [
      {
        name: "client_id",
        label: "API Key",
        optional: false,
        hint: "API key can be found <a href='https://constantcontact.mashery" \
          ".com/apps/mykeys' target='_blank'>here</a>"
      },
      {
        name: "client_secret",
        label: "Client Secret",
        control_type: "password",
        optional: false,
        hint: "Client secret can be found <a href='https://constantcontact." \
          "mashery.com/apps/mykeys' target='_blank'>here</a>"
      }
    ],

    authorization: {
      type: "oauth2",

      authorization_url: lambda do |connection|
        "https://oauth2.constantcontact.com/oauth2/oauth/siteowner/authorize?" \
          "redirect_url=https%3A%2F%2Fwww.workato.com%2Foauth%2Fcallback&" \
          "response_type=code&client_id=#{connection['client_id']}"
      end,

      acquire: lambda do |connection, auth_code|
        response =
          post("https://oauth2.constantcontact.com/oauth2/oauth/token").
            params(
              grant_type: "authorization_code",
              client_id: connection["api_key"],
              client_secret: connection["client_secret"],
              code: auth_code,
              redirect_uri: "https%3A%2F%2Fwww.workato.com%2Foauth%2Fcallback"
            )

          {
            access_token: response["access_token"],
          }
      end,

      apply: lambda do |connection, access_token|
        # Constant Contact passes API key as parameter and access token as header
        params(api_key: connection["api_key"])
        headers("Authorization": "Bearer #{access_token}")
      end
    },

    base_uri: lambda do
      "https://api.constantcontact.com"
    end
  },

  test: lambda do |_connection|
    get("/v2/account/info")
  end,

  object_definitions: {
    contact: {
      fields: lambda do |_connection|
        [
          { name: "id" },
          { name: "status" },
          { name: "confirmed", type: "boolean" },
          { name: "prefix_name" },
          { name: "first_name" },
          { name: "last_name" },
          { name: "work_phone" },
          { name: "home_phone" },
          { name: "cell_phone" },
          { name: "fax" },
          { name: "company_name" },
          { name: "job_title" },
          { name: "source" },
          { name: "source_details" },
          { name: "created_date", type: "date_time" },
          { name: "modified_date", type: "date_time" },
          { name: "addresses", type: "array", properties:
            [
              { name: "address_type" },
              { name: "city" },
              { name: "country_code" },
              { name: "id" },
              { name: "line1" },
              { name: "line2" },
              { name: "line3" },
              { name: "postal_code" },
              { name: "state" },
              { name: "state_code" },
              { name: "sub_postal_code" }
            ]
          },
          { name: "custom_fields", type: "array", properties:
            [
              { name: "label" },
              { name: "name" },
              { name: "value" }
            ]
          },
          { name: "email_addresses", type: "array", properties:
            [
              { name: "confirm_status" },
              { name: "email_address" },
              { name: "id" },
              { name: "opt_in_date", type: "date_time" },
              { name: "opt_in_source" },
              { name: "opt_out_date", type: "date_time" },
              { name: "opt_out_source" },
              { name: "status" }
            ]
          },
          { name: "lists", type: "array", properties:
            [
              { name: "id" },
              { name: "status" }
            ]
          },
          { name: "notes", type: "array", properties:
            [
              { name: "id" },
              { name: "created_date", type: "date_time" },
              { name: "modified_date", type: "date_time" },
              { name: "note" }
            ]
          }
        ]
      end
    },

    email_campaign: {
      fields: lambda do |_connection|
        [
          { name: "id" },
          { name: "name" },
          { name: "subject" },
          { name: "status" },
          { name: "from_name" },
          { name: "from_email" },
          { name: "reply_to_email" },
          { name: "created_date", type: "date_time" },
          { name: "modified_date", type: "date_time" },
          { name: "last_run_date", type: "date_time" },
          { name: "tracking_summary", type: "object", properties:
            [
              { name: "sends", type: "integer" },
              { name: "opens", type: "integer" },
              { name: "clicks", type: "integer" },
              { name: "forwards", type: "integer" },
              { name: "unsubscribes", type: "integer" },
              { name: "bounces", type: "integer" },
              { name: "spam_count", type: "integer" }
            ]
          },
          { name: "sent_to_contact_lists", type: "array", properties:
            [
              { name: "id" }
            ]
          },
          { name: "click_through_details", type: "array", properties:
            [
              { name: "url_uid" },
              { name: "url" },
              { name: "click_count", type: "integer" }
            ]
          }
        ]
      end
    },

    click_in_campaign: {
      fields: lambda do |_connection|
        [
          { name: "campaign_id" },
          { name: "click_date", type: "date_time" },
          { name: "contact_id" },
          { name: "email_address" },
          { name: "link_id" }
        ]
      end
    },

    bounce_in_campaign: {
      fields: lambda do |_connection|
        [
          { name: "campaign_id" },
          { name: "contact_id" },
          { name: "email_address" },
          { name: "bounce_date", type: "date_time" },
          { name: "bounce_code" },
          { name: "bounce_description" },
          { name: "bounce_message" }
        ]
      end
    },

    unsubscribe_from_campaign: {
      fields: lambda do |_connection|
        [
          { name: "campaign_id" },
          { name: "unsubscribe_date", type: "date_time" },
          { name: "contact_id" },
          { name: "email_address" },
          { name: "unsubscribe_source" },
          { name: "unsubscribe_reason" }
        ]
      end
    },

    open_in_campaign: {
      fields: lambda do |_connection|
        [
          { name: "campaign_id" },
          { name: "open_date", type: "date_time" },
          { name: "contact_id" },
          { name: "email_address" }
        ]
      end
    }
  },

  actions: {
    list_email_campaigns: {
      description: "List <span class='provider'>email campaigns</span> in " \
        "<span class='provider'>Constant Contact</span>",

      input_fields: lambda do
        [
          { name: "modified_since", control_type: "date_time",
            type: "date_time", hint: "Leave blank to get all campaigns" }
        ]
      end,

      execute: lambda do |_connection, input|
        if input["modified_since"].present? then
          params = {
            modified_since: input["modified_since"].to_time.utc.iso8601
          }
        end
        response = get("/v2/emailmarketing/campaigns?limit=30",params)
        campaigns = response["results"]
        next_link = response["meta"]["pagination"]["next_link"]
        while next_link.present?
          response = get(next_link)
          response["results"].each do |result|
            campaigns << result
          end
          next_link = response["meta"]["pagination"]["next_link"]
        end

        {
          results: campaigns
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: "results", type: "array",
            properties: object_definitions["email_campaign"].
                        only("id", "name", "status", "modified_date") }
        ]
      end,

      sample_output: lambda do |_connection|
        { results: get("/v2/emailmarketing/campaigns?limit=1")["results"] }
      end
    },

    get_email_campaign_details: {
      description: "Get <span class='provider'>email campaign</span> details " \
        "in <span class='provider'>Constant Contact</span>",

      input_fields: lambda do
        [
          { name: "campaign_id", label: "Campaign", control_type: "select",
            pick_list: "campaigns",
            hint:"Either Campaign or Campaign ID must be filled" },
          { name: "campaign_id_2", label: "Campaign ID",
            hint:"Either Campaign or Campaign ID must be filled" }
        ]
      end,

      execute: lambda do |_connection, input|
        input_id = input["campaign_id"] || input["campaign_id_2"]
        get("/v2/emailmarketing/campaigns/" + input_id)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["email_campaign"]
      end
    },

    get_campaign_tracking_summary: {
      description: "Get <span class='provider'>tracking summary</span> of " \
        "email campaign in <span class='provider'>Constant Contact</span>",

      input_fields: lambda do
        [
          { name: "campaign_id", label: "Campaign", control_type: "select",
            pick_list: "campaigns",
            hint:"Either Campaign or Campaign ID must be filled" },
          { name: "campaign_id_2", label: "Campaign ID",
            hint:"Either Campaign or Campaign ID must be filled" }
        ]
      end,

      execute: lambda do |_connection, input|
        input_id = input["campaign_id"] || input["campaign_id_2"]
        get("/v2/emailmarketing/campaigns/#{input_id}/tracking/reports/summary")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["email_campaign"].only("tracking_summary")
      end
    },

    search_contact: {
      description: "Search <span class='provider'>contact</span> in " \
        "<span class='provider'>Constant Contact</span>",

      input_fields: lambda do
        [
          { name: "contact_id" },
          { name: "email", control_type: "email" }
        ]
      end,

      execute: lambda do |_connection, input|
        if input["contact_id"].present?
          get("/v2/contacts/#{input["contact_id"]}")
        else
          get("/v2/contacts").params("email": input["email"])["results"].first
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["contact"]
      end
    },

    create_contact: {
      description: "Create <span class='provider'>contact</span> in " \
        "<span class='provider'>Constant Contact</span>",

      input_fields: lambda do |_object_definitions|
        [
          { name: "first_name" },
          { name: "last_name" },
          { name: "email_address", control_type: "email", optional: false },
          { name: "work_phone" },
          { name: "company_name" },
          { name: "job_title" },
          { name: "source" },
          { name: "list_id_1", label: "List 1", control_type: "select",
            pick_list: "contact_lists", optional: false },
          { name: "list_id_2", label: "List 2", control_type: "select",
            pick_list: "contact_lists" },
          { name: "lead_source" }
        ]
      end,

      execute: lambda do |_connection, input|
        email_hash = [
          "email_address" => input["email_address"]
        ]

        list_hash = [
          {"id" => input["list_id_1"]},
          {"id" => input["list_id_2"]},
        ]

        custom_hash = [
          "name" => "CustomField1",
          "value" => input["lead_source"]
        ]

        post("/v2/contacts").
          params(action_by: "ACTION_BY_OWNER").
          payload(
            first_name: input["first_name"],
            last_name: input["last_name"],
            work_phone: input["work_phone"],
            company_name: input["company_name"],
            job_title: input["job_title"],
            source: input["source"],
            email_addresses: email_hash,
            lists: list_hash,
            custom_fields: custom_hash
          )
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["contact"]
      end
    }
  },

  triggers: {
    contact_clicked_campaign: {
      title: "New email campaign click by contact",
      subtitle: "New email campaign click by contact",
      description: "New <span class='provider'>email campaign click</span> by" \
        " contact in <span class='provider'>Constant Contact</span>",
      help: "Retrieves a report showing each contact who clicked on a link, " \
        "for each link, in a sent email campaign.",

      type: "paging_desc",

      input_fields: lambda do
        [
          { name: "campaign_id", label: "Campaign", optional: false,
            control_type: "select", pick_list: "campaigns" },
          { name: "created_since", control_type: "date_time",
            type: "date_time" }
        ]
      end,

      poll: lambda do |_connection, input, next_page|
        if input["created_since"].present? then
          params = {
            created_since: input["created_since"].to_time.utc.iso8601
          }
        end
        if next_page.present? then
          response = get(next_page)
        else
          response =
            get("/v2/emailmarketing/campaigns/#{input["campaign_id"]}/" \
              "tracking/clicks?limit=500", params)
        end

      clickers = response["results"]

      {
        events: clickers,
        next_page: response["meta"]["pagination"]["next_link"]
      }
      end,

      document_id: lambda do |clicker|
        clicker["contact_id"]
      end,

      sort_by: lambda do |clicker|
        clicker["click_date"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["click_in_campaign"]
      end
    },

    contact_opened_campaign: {
      title: "New email campaign opens by contact",
      subtitle: "New email campaign opened by contact",
      description: "New <span class='provider'>email campaign opened</span> " \
        "by contact in <span class='provider'>Constant Contact</span>",
      help: "Retrieves a list of email addresses that opened a sent email " \
        "campaign.",

      type: "paging_desc",

      input_fields: lambda do
        [
          { name: "campaign_id", label: "Campaign", optional: false,
            control_type: "select", pick_list: "campaigns" },
          { name: "created_since", control_type: "date_time",
            type: "date_time" }
        ]
      end,

      poll: lambda do |_connection, input, next_page|
        if input["created_since"].present? then
          params = {
            created_since: input["created_since"].to_time.utc.iso8601
          }
        end
        if next_page.present? then
          response = get(next_page)
        else
          response =
            get("/v2/emailmarketing/campaigns/#{input["campaign_id"]}/" \
              "tracking/opens?limit=500", params)
        end

        openers = response["results"]
        {
          events: openers,
          next_page: response["meta"]["pagination"]["next_link"]
        }
      end,

      document_id: lambda do |opener|
        opener["contact_id"]
      end,

      sort_by: lambda do |opener|
        opener["open_date"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["open_in_campaign"]
      end
    },

    contact_bounced_from_campaign: {
      title: "New contact bounced from campaign",
      subtitle: "New contact bounced from a sent campaign",
      description: "New contact <span class='provider'>bounced</span> from " \
        "email campaign in <span class='provider'>Constant Contact</span>",
      help: "Retrieves a list of email addresses that bounced for a sent " \
        "email campaign.",

      type: "paging_desc",

      input_fields: lambda do
        [
          { name: "campaign_id", label: "Campaign", optional: false,
            control_type: "select", pick_list: "campaigns" },
          { name: "created_since", control_type: "date_time",
            type: "date_time" }
        ]
      end,

      poll: lambda do |_connection, input, next_page|
        if input["created_since"].present? then
          params = {
            created_since: input["created_since"].to_time.utc.iso8601
          }
        end
        if next_page.present? then
          response = get(next_page)
        else
          response =
            get("/v2/emailmarketing/campaigns/#{input["campaign_id"]}/" \
              "tracking/bounces?limit=500", params)
        end

        bouncers = response["results"]
        {
          events: bouncers,
          next_page: response["meta"]["pagination"]["next_link"]
        }
      end,

      document_id: lambda do |bouncer|
        bouncer["contact_id"]
      end,

      sort_by: lambda do |bouncer|
        bouncer["bounce_date"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["bounce_in_campaign"]
      end
    },

    contact_unsubscribed_from_campaign: {
      title: "New contact unsubscribed from campaign",
      subtitle: "New contact unsubscribed from a sent campaign",
      description: "New contact <span class='provider'>unsubscribed</span> " \
        "from email campaign in <span class='provider'>Constant Contact</span>",
      help: "Retrieves a list of contacts that unsubscribed from a sent " \
        "email campaign.",

      type: "paging_desc",

      input_fields: lambda do
        [
          { name: "campaign_id", label: "Campaign", optional: false,
            control_type: "select", pick_list: "campaigns" },
          { name: "created_since", control_type: "date_time",
            type: "date_time" }
        ]
      end,

      poll: lambda do |_connection, input, next_page|
        if input["created_since"].present? then
          params = {
            created_since: input["created_since"].to_time.utc.iso8601
          }
        end
        if next_page.present? then
          response = get(next_page)
        else
          response =
            get("/v2/emailmarketing/campaigns/#{input["campaign_id"]}/" \
              "tracking/unsubscribes?limit=500", params)
        end

        unsubs = response["results"]
        {
          events: unsubs,
          next_page: response["meta"]["pagination"]["next_link"]
        }
      end,

      document_id: lambda do |unsub|
        unsub["contact_id"]
      end,

      sort_by: lambda do |unsub|
        unsub["unsubscribe_date"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["unsubscribe_from_campaign"]
      end
    },

    campaign_sent: {
      title: "New campaign sent",
      subtitle: "New campaign sent in user's account",
      description: "New <span class='provider'>campaign sent</span> in a " \
        "user's account in <span class='provider'>Constant Contact</span>",
      help: "Retrieves only the email campaigns in a user's account with a " \
        "sent status.",

      type: "paging_desc",

      input_fields: lambda do
        [
          { name: "modified_since", control_type: "date_time",
            type: "date_time" }
        ]
      end,

      poll: lambda do |_connection, input, next_page|
        if input["modified_since"].present? then
          params = {
            modified_since: input["modified_since"].to_time.utc.iso8601
          }
        end
        if next_page.present? then
          response = get(next_page)
        else
          response =
            get("/v2/emailmarketing/campaigns?limit=50&status=SENT", params)
        end

        campaigns = response["results"]
        {
          events: campaigns,
          next_page: response["meta"]["pagination"]["next_link"]
        }
      end,

      document_id: lambda do |campaign|
        campaign["id"]
      end,

      sort_by: lambda do |campaign|
        campaign["modified_date"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["email_campaign"].
          only("id", "name", "status", "modified_date")
      end
    }
  },

  pick_lists: {
    contact_lists: lambda do |_connection|
      get("/v2/lists").pluck("name", "id")
    end,

    campaigns: lambda do |connection|
      response = get("/v2/emailmarketing/campaigns?limit=50")
      campaign_results = response["results"]
      next_link = response["meta"]["pagination"]["next_link"]
      while next_link.present?
        response = get(next_link)
        next_link = response["meta"]["pagination"]["next_link"]
        response["results"].each do |result|
          campaign_results << result
        end
      end
      campaign_results.map { |result| [result["name"], result["id"]] }
    end,

    statuses: lambda do
      [
        %w[All ALL],
        %w[Active ACTIVE],
        %w[Unconfirmed UNCONFIRMED],
        %w[Optout OPTOUT],
        %w[Removed REMOVED]
      ]
    end
  }
}
