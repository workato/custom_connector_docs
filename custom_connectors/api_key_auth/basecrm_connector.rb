{
  title: "BaseCRM",

  connection: {
    fields: [
      {
        name: "api_key",
        control_type: "password",
        optional: false,
        label: "API key"
      }
    ],
    authorization: {
      type: "api_key",

      credentials: lambda do |connection|
        headers("Authorization": "Bearer " + connection["api_key"])
      end
    },
    base_uri: lambda do
      "https://api.getbase.com"
    end
  },

  object_definitions: {
    lead: {
      fields: lambda do
        [
          { name: "id", type: :integer, label: "Lead ID",
            control_type: :number },
          { name: "creator_id", type: :integer, label: "Created by (User ID)",
            control_type: :number },
          { name: "owner_id", type: :integer, label: "Owner ID",
            control_type: :number },
          { name: "first_name" },
          { name: "last_name",
            hint: "Required only if a lead is an individual. "\
            "<code>Organisation name</code> should be left empty." },
          { name: "organization_name",
            hint: "Required only if a lead is an organization. "\
            "<code>Last name</code> should be left empty." },
          { name: "title" },
          { name: "description" },
          { name: "industry" },
          { name: "website", control_type: :url },
          { name: "email", control_type: :email },
          { name: "phone", control_type: :phone },
          { name: "mobile", control_type: :phone },
          { name: "fax", control_type: :phone },
          { name: "twitter" },
          { name: "facebook" },
          { name: "linkedin" },
          { name: "skype" },
          { name: "address", type: :object, properties: [
            { name: "line1" },
            { name: "city" },
            { name: "postal_code" },
            { name: "state" },
            { name: "country" }
          ] },
          { name: "created_at", type: :date_time, control_type: :timestamp },
          { name: "updated_at", type: :date_time, control_type: :timestamp }
        ]
      end
    },

  },

  test: ->(connection) {
    get("/v2/users/self")
  },

  actions: {
    search_leads: {
      description: "Search <span class='provider'>Leads</span> in
        <span class='provider'>Base CRM</span>",
      subtitle: "Search leads in Base CRM",
      help: "Search will only return leads matching all inputs." \
      " Returns all leads, if blank.",
      
      input_fields: lambda do |object_definitions|
        [
          { name: "ids", label: "ID",
            sticky: true,
            hint: "Comma-separated list of lead IDs." },
          { name: "address", type: :object, properties: [
            { name: "city", sticky: true,
              label: "City name" },
            { name: "postal_code", sticky: true,
              label: "Zip/postal code" },
            { name: "state", sticky: true,
              label: "State/region name" },
            { name: "country", sticky: true,
              label: "Country name" }
          ] }
        ].concat(object_definitions["lead"].
          only("creator_id", "owner_id", "status", "email", "phone", "mobile"))
      end,

      execute: lambda do |_connection, input|
        {
          leads: get("/v2/leads", input).dig("items")&.
            pluck("data") || []
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: "leads", type: :array, of: :object,
            properties: object_definitions["lead"] }
        ]
      end,

      sample_output: lambda do
        {
          leads: [get("/v2/leads").
            params(per_page: 1)["items"].dig(0, "data") || {}]
        }
      end
    },
    create_lead: {
      description:
      "Create <span>Lead</span> in <span class='provider'>Base CRM</span>",
      subtitle: "Create lead in Base CRM",
      help: "Either last name or organisation name is required " \
       "to create account for individuals/organisations respectively.",
      input_fields: lambda do |object_definitions|
        object_definitions["lead"].
          ignored("id", "creator_id", "created_at", "updated_at", "owner_id")
      end,

      execute: lambda do |_connection, input|
        post("/v2/leads").
          payload(data: input)["data"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["lead"]
      end,

      sample_output: lambda do
        get("/v2/leads", per_page: 1)["items"].
          dig(0, "data") || {}
      end
    }
  }
}
