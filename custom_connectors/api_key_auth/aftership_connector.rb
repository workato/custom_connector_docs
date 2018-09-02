{
  title: "Aftership",

  connection: {
    fields: [
      {
        name: "api_key",
        control_type: "password",
        optional: false,
        label: "API key",
        hint: "Get your API key <a href='https://secure.aftership.com/" \
          "apps/api' target='blank'>here</a>"
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
    tracking_input: {
      fields: lambda do |_connection|
        [
          { name: "tracking_number", type: :string, optional: false,
            hint: "Duplicate tracking numbers, or tracking number with " \
              "invalid tracking number format will not be accepted." },
          { name: "slug", type: :string,
            hint: "If you do not specify a slug, Aftership will " \
              "automatically detect the courier based on the tracking number " \
              "format and your selected couriers." },
          { name: "tracking_postal_code", type: :string,
            hint: "The postal code of receiver's address. " \
              "Required by some couriers, such as deutsch-post" },
          { name: "tracking_ship_date", type: :string,
            hint: "Shipping date in YYYYMMDD format. Required by some " \
              "couriers, such as deutsch-post" },
          { name: "tracking_account_number", type: :string,
            hint: "Account number of the shipper for a specific courier. " \
              "Required by some couriers, such as dynamic-logistics" },
          { name: "tracking_key", type: :string,
            hint: "Key of the shipment for a specific courier. " \
              "Required by some couriers, such assic-teliway" },
          { name: "tracking_origin_country", type: :string,
            hint: "Origin Country of the shipment for a specific courier. " \
              "Required by some couriers, such as dhl" },
          { name: "tracking_destination_country", type: :string,
            hint: "Destination Country of the shipment for a specific courier" \
              ". Required by some couriers, such as postnl-3s" },
          { name: "tracking_state", type: :string,
            hint: "Located state of the shipment for a specific courier. " \
              "Required by some couriers, such asstar-track-courier" },
          { name: "android", type: :string,
            hint: "Google cloud message comma separated registration IDs to " \
              "receive the push notifications" },
          { name: "ios", type: :string,
            hint: "Apple iOS comma separated device IDs to receive the " \
              "push notifications" },
          { name: "emails", type: :string, label: "E-mails",
            hint: "Comma separated email address(es) to receive email " \
              "notifications" },
          { name: "smses", type: :string, label: "SMSes",
            hint: "Comma separated phone number(s) to receive SMS " \
              "notifications. Note: Enter + and area code before number." },
          { name: "title", type: :string,
            hint: "Title of the tracking. Default value astracking_number" },
          { name: "customer_name", type: :string },
          { name: "origin_country_iso3", type: :string,
            label: "Origin Country ISO3",
            hint: "Enter <a href='https://unstats.un.org/unsd/tradekb/" \
              "knowledgebase/country-code' target='_blank'>ISO Alpha-3</a> " \
              "country code to specify the origin of the shipment" },
          { name: "destination_country_iso3", type: :string,
            label: "Destination Country ISO3",
            hint: "Enter <a href='https://unstats.un.org/unsd/tradekb/" \
              "knowledgebase/country-code' target='_blank'>ISO Alpha-3</a> " \
              "country code to specify the destination of the shipment" \
              "If you use postal service to send international shipments, " \
              "AfterShip will automatically get tracking results at " \
              "destination courier as well." },
          { name: "order_id", type: :string, label: "Order ID" },
          { name: "order_id_path", type: :string, label: "Order ID Path" },
          { name: "note", type: :string },
          { name: "language", type: :string,
            hint: "Enter <a href='https://help.aftership.com/hc/en-us/" \
              "articles/360001623287-Supported-Language-Parameters' " \
              "target='_blank'>ISO 639-1</a> Language Code to specify the " \
              "store, customer or order language" }
        ]
      end
    },

    tracking_output: {
      fields: lambda do |_connection|
        [
          { name: "id", type: :string, control_type: :text },
          { name: "created_at", type: :date_time, control_type: :date_time },
          { name: "updated_at", type: :date_time, control_type: :date_time },
          { name: "tracking_number", type: :string, control_type: :text },
          { name: "tracking_account_number", type: :string,
            control_type: :text },
          { name: "tracking_postal_code", type: :string, control_type: :text },
          { name: "tracking_ship_date", type: :date_time,
            control_type: :date_time },
          { name: "tracking_origin_country", type: :string },
          { name: "tracking_destination_country", type: :string },
          { name: "tracking_state", type: :string },
          { name: "tracking_key", type: :string },
          { name: "slug", type: :string, control_type: :text },
          { name: "active", type: :boolean },
          { name: "android", type: :string },
          { name: "custom_fields", type: :object },
          { name: "customer_name", type: :string, control_type: :text },
          { name: "delivery_time", type: :string },
          { name: "destination_country_iso3", type: :string,
            control_type: :text },
          { name: "courier_destination_country_iso3", type: :string,
            control_type: :text },
          { name: "emails", type: :array, of: :string },
          { name: "expected_delivery", type: :date_time,
            control_type: :date_time },
          { name: "ios", type: :string },
          { name: "note", type: :string, control_type: :text },
          { name: "order_id", type: :string, control_type: :text },
          { name: "order_id_path", type: :string, control_type: :url },
          { name: "origin_country_iso3", type: :string, control_type: :text },
          { name: "unique_token", type: :string, control_type: :password },
          { name: "shipment_package_count", type: :integer,
            control_type: :number },
          { name: "shipment_type", type: :string, control_type: :text },
          { name: "shipment_weight", type: :string, control_type: :text },
          { name: "shipment_weight_unit", type: :string, control_type: :text },
          { name: "signed_by", type: :string, control_type: :text },
          { name: "smses", type: :array, of: :string },
          { name: "source", type: :string, control_type: :text },
          { name: "tag", type: :string, control_type: :text },
          { name: "title", type: :string, control_type: :text },
          { name: "tracked_count", type: :integer, control_type: :number },
          { name: "last_mile_tracking_supported", type: :boolean,
            control_type: :checkbox },
          { name: "language", type: :string, control_type: :text },
          { name: "return_to_sender", type: :boolean, control_type: :checkbox },
          { name: "checkpoints", type: :array, of: :object, properties: [
            { name: "slug", type: :string, control_type: :text },
            { name: "location", type: :string, control_type: :text },
            { name: "city", type: :string, control_type: :text },
            { name: "created_at", type: :date_time,
              control_type: :date_time },
            { name: "country_name", type: :string, control_type: :text },
            { name: "message", type: :string, control_type: :text },
            { name: "country_iso3", type: :string, control_type: :text },
            { name: "tag", type: :string, control_type: :text },
            { name: "checkpoint_time", type: :date_time,
              control_type: :date_time },
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
        object_definitions["tracking_input"].required("tracking_number")
      end,

      execute: lambda do |_connection, input|
        post("/v4/trackings", tracking: input).dig("data", "tracking")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["tracking_output"]
      end,

      sample_output: lambda do |_connection|
        get("/v4/trackings", limit: 1).dig("data", "trackings", 0)
      end
    },

    search_tracking: {
      description: "Search <span class='provider'>tracking</span> in " \
        "<span class='provider'>Aftership</span>",

      input_fields: lambda do |object_definitions|
        object_definitions["tracking_input"].
          only("tracking_number").
          required("tracking_number")
      end,

      execute: lambda do |_connection, input|
        {
          trackings: get("/v4/trackings", keyword: input["tracking_number"]).
                       []("data") || []
        }
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["tracking_output"]
      end,

      sample_output: lambda do |_connection|
        get("/v4/trackings", limit: 1).dig("data", "trackings", 0)
      end
    }
  }
}
