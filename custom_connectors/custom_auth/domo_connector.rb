{
  title: "Domo",

  connection: {
    fields: [
      {
        name: "client_id",
        optional: false
      },
      {
        name: "client_secret",
        control_type: "password",
        optional: false
      }
    ],

    authorization: {
      type: "custom_auth",

      acquire: lambda do |connection|
        {
          access_token: get("https://api.domo.com/oauth/token?" \
                        "grant_type=client_credentials&scope=data").
                          user(connection["client_id"]).
                          password(connection["client_secret"])["access_token"]
        }
      end,

      refresh_on: [401],

      apply: lambda do |connection|
        headers(Authorization: "bearer #{connection['access_token']}")
      end
    },

    base_uri: lambda do
      "https://api.domo.com"
    end
  },

  object_definitions: {
    dataset: {
      fields: lambda do |_connection, config_fields|
        column_headers =
          if config_fields.blank?
            []
          else
            get("/v1/datasets/#{config_fields['dataset_id']}")["schema"]
            ["columns"].map { |col|
                         { name: col["name"] }
                       }
          end

        {
          name: "data",
          type: "array",
          of: "object",
          properties: column_headers,
          optional: false,
          hint: "Map the Data source list and Data fields."
        }
      end
    },

    new_dataset: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: "name",
            optional: false,
            hint: "Enter a name for the dataset."
          },
          {
            name: "description",
            optional: true,
            hint: "Enter description for dataset."
          },
          {
            name: "schema",
            control_type: "textarea",
            optional: false,
            hint: "Enter column name and column type in the dataset schema " \
              "as comma separated value. Enter one schema information per " \
              "line.<br/><b>Example:</b> Name,STRING <br/> &nbsp;&nbsp;&nbsp" \
              ";&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" \
              "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;DOB,DATE."
          }
        ]
      end
    },

    new_dataset_dev: {
      fields: lambda do |_connection, config_fields|
        index = 0
        schema_fields =
          if config_fields.blank?
            []
          else
            while index < config_fields["schema"].to_i do
              index = index + 1
              schema_fields =
                [
                  { name: "name" },
                  { name: "type" }
                ]
            end
          end

        {
          name: "data",
          type: "array",
          of: "object",
          properties: schema_fields,
          optional: false,
          hint: "Map the data source list and data fields."
        }
      end
    }
  },

  actions: {
    list_datasets: {
      description: "List <span class='provider'>datasets</span> in " \
        "<span class='provider'>Domo</span>",

      execute: lambda do |_connection, _input|
        {
          datasets: get("/v1/datasets")
        }
      end
    },

    import_data: {
      description: "Import <span class='provider'>data</span> in " \
        "<span class='provider'>Domo</span>",

      config_fields: [
        {
          name: "dataset_id",
          control_type: "select",
          pick_list: "datasets",
          optional: false,
          help: "Select the appropriate dataset to import data."
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions["dataset"]
      end,

      execute: lambda do |_connection, input|
        payload =
          input["data"].map do |row|
            row.map do |_key, val|
              val
            end.join(",")
          end.join("\n")

        {
          data: put("/v1/datasets/#{input['dataset_id']}/data").
                  headers("Content-Type": "text/csv").
                  request_body("#{payload}").
                  request_format_www_form_urlencoded
        }
      end,
    },

    create_dataset: {
      description: "Create <span class='provider'>dataset</span> in " \
        "<span class='provider'>Domo</span>",

      input_fields: lambda do |object_definitions|
        object_definitions["new_dataset"]
      end,

      execute: lambda do |_connection, input|
        schema_obj = {
          "columns" => (input["schema"] || "").
                         split("\n").
                         map do |line|
                           line_columns = line.split(",")

                           if line_columns.length == 2
                             {
                               "type" => line_columns[1].gsub(/\s+/, ""),
                               "name" => line_columns[0].gsub(/\s+/, "")
                             }
                           else
                             {}
                           end
                        end
        }

        payload = {
          "name"	=>	input["name"],
          "description"	=>	input["description"],
          "schema"	=>	schema_obj
        }

        post("/v1/datasets/", payload)
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: "id" }
        ].concat(object_definitions["new_dataset"])
      end
    },

    delete_dataset: {
      description: "Delete <span class='provider'>dataset</span> in " \
        "<span class='provider'>Domo</span>",

      config_fields: [
        {
          name: "dataset_id",
          control_type: "select",
          pick_list: "datasets",
          optional: false,
          help: "Select the appropriate Dataset to import data."
        }
      ],

      execute: lambda do |_connection, input|
        delete("/v1/datasets/#{input['dataset_id']}")
      end
    }
  },

  pick_lists: {
    datasets: ->(_connection) {
      get("/v1/datasets").pluck("name", "id")
    }
  }
}
