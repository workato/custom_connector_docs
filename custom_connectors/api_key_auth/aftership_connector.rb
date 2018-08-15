{
  title: "Aftership",

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
        headers("aftership-api-key": connection["api_key"])
      end
    },

    base_uri: lambda do
      "https://api.aftership.com"
    end
  },

  object_definitions: {
    tracking: {
      fields: lambda do |_connection|
        [
          { name: "tracking_number", type: :string, optional: false },
          { name: "slug", type: :string },
          { name: "tracking_postal_code", type: :string },
          { name: "tracking_ship_date", type: :string },
          { name: "tracking_account_number", type: :string },
          { name: "tracking_key", type: :string },
          { name: "tracking_destination_country", type: :string },
          { name: "android", type: :string },
          { name: "ios", type: :string },
          { name: "emails", type: :string, label: "E-mails" },
          { name: "smses", type: :string, label: "Smses" },
          { name: "title", type: :string },
          { name: "customer_name", type: :string },
          { name: "destination_country_iso3", type: :string,
            label: "Destination Country ISO3" },
          { name: "order_id", type: :string, label: "Order ID" },
          { name: "order_id_path", type: :string, label: "Order ID Path" },
          { name: "note", type: :string }
        ]
      end
    },

    trackings: {
      fields: lambda do |_connection|
        [
          { name: "id", type: :string, control_type: :text },
          { name: "created_at", type: :datetime, control_type: :timestamp },
          { name: "updated_at", type: :datetime, control_type: :timestamp },
          { name: "tracking_number", type: :string, control_type: :text },
          { name: "tracking_account_number", type: :string,
            control_type: :text },
          { name: "tracking_postal_code", type: :string, control_type: :text },
          { name: "tracking_ship_date", type: :datetime,
            control_type: :timestamp },
          { name: "slug", type: :string, control_type: :text },
          { name: "active", type: :boolean },
          { name: "custom_fields", type: :object },
          { name: "customer_name", type: :string, control_type: :text },
          { name: "destination_country_iso3", type: :string,
            control_type: :text },
          { name: "emails", type: :array, of: :string },
          { name: "expected_delivery", type: :datetime,
            control_type: :timestamp },
          { name: "note", type: :string, control_type: :text },
          { name: "order_id", type: :string, control_type: :text },
          { name: "order_id_path", type: :string, control_type: :url },
          { name: "origin_country_iso3", type: :string, control_type: :text },
          { name: "shipment_package_count", type: :integer,
            control_type: :number },
          { name: "shipment_type", type: :string, control_type: :text },
          { name: "signed_by", type: :string, control_type: :text },
          { name: "smses", type: :array, of: :string },
          { name: "source", type: :string, control_type: :text },
          { name: "tag", type: :string, control_type: :text },
          { name: "title", type: :string, control_type: :text },
          { name: "tracked_count", type: :integer, control_type: :number },
          { name: "unique_token", type: :string, control_type: :password },
          { name: "checkpoints", type: :array, of: :object, properties: [
            { name: "slug", type: :string, control_type: :text },
            { name: "city", type: :string, control_type: :text },
            { name: "created_at", type: :datetime,
              control_type: :timestamp },
            { name: "country_name", type: :string, control_type: :text },
            { name: "message", type: :string, control_type: :text },
            { name: "country_iso3", type: :string, control_type: :text },
            { name: "tag", type: :string, control_type: :text },
            { name: "checkpoint_time", type: :datetime,
              control_type: :timestamp },
            { name: "coordinates", type: :array, of: :integer,
              control_type: :number },
            { name: "state", type: :string, control_type: :text },
            { name: "zip", type: :string, control_type: :text }
          ] }
        ]
      end
    }
  },

  test: lambda do |_connection|
    get("/v4/trackings")
  end,

  actions: {
    create_tracking: {
      description: "Create a <span class='provider'>tracking</span> in " \
        "<span class='provider'>Aftership</span>",

      input_fields: lambda do |object_definitions|
        object_definitions["tracking"].required("tracking_number")
      end,

      execute: lambda do |_connection, input|
        post("/v4/trackings", tracking: input)["tracking"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["tracking"]
      end
    },

    search_tracking: {
      description: "Search <span class='provider'>tracking</span> in " \
        "<span class='provider'>Aftership</span>",

      input_fields: lambda do |_object_definitions|
        {
          name: "tracking_number",
          type: "string",
          optional: false,
          label: "Tracking Number"
        }
      end,

      execute: lambda do |_connection, input|
        result = get("/v4/trackings").
                   params(keyword: input["tracking_number"]) ["data"]

        {
          trackings: result["trackings"].presence || []
        }
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["trackings"]
      end
    }
  }
}
