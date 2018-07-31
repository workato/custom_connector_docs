{
  title: "Google BigQuery",

  connection: {
    fields: [
      {
        name: "client_id",
        hint: "Find client ID " \
          "<a href='https://console.cloud.google.com/apis/credentials' " \
          "target='_blank'>here</a>",
        optional: false
      },
      {
        name: "client_secret",
        hint: "Find client secret " \
          "<a href='https://console.cloud.google.com/apis/credentials' " \
          "target='_blank'>here</a>",
        optional: false,
        control_type: "password"
      }
    ],

    authorization: {
      type: "oauth2",

      authorization_url: lambda do |connection|
        scopes = [
          "https://www.googleapis.com/auth/bigquery",
          "https://www.googleapis.com/auth/bigquery.insertdata",
          "https://www.googleapis.com/auth/cloud-platform",
          "https://www.googleapis.com/auth/cloud-platform.read-only",
          "https://www.googleapis.com/auth/devstorage.full_control",
          "https://www.googleapis.com/auth/devstorage.read_only",
          "https://www.googleapis.com/auth/devstorage.read_write"
        ].join(" ")

        "https://accounts.google.com/o/oauth2/auth?client_id="            \
          "#{connection['client_id']}&response_type=code&scope=#{scopes}" \
          "&access_type=offline&include_granted_scopes=true&prompt=consent"
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
        response = post("https://accounts.google.com/o/oauth2/token").
                   payload(client_id: connection["client_id"],
                           client_secret: connection["client_secret"],
                           grant_type: "authorization_code",
                           code: auth_code,
                           redirect_uri: redirect_uri).
                   request_format_www_form_urlencoded

        [response, nil, nil]
      end,

      refresh: lambda do |connection, refresh_token|
        post("https://accounts.google.com/o/oauth2/token").
          payload(client_id: connection["client_id"],
                  client_secret: connection["client_secret"],
                  grant_type: "refresh_token",
                  refresh_token: refresh_token).
          request_format_www_form_urlencoded
      end,

      refresh_on: [401],

      detect_on: [/"errors"\:\s*\[/],

      apply: lambda do |_connection, access_token|
        headers("Authorization" => "Bearer #{access_token}")
      end
    },

    base_uri: ->(_connection) { "https://www.googleapis.com" }
  },

  test: ->(_connection) { get("/bigquery/v2/projects").params(maxResults: 1) },

  methods: {
    schema_for_table: lambda do |input|
      type_map = {
        "STRING"    => "string", "BYTES"    => "string",
        "INTEGER"   => "integer", "INT64"   => "integer",
        "FLOAT"     => "number", "FLOAT64"  => "number",
        "BOOLEAN"   => "boolean", "BOOL"    => "boolean",
        "TIMESTAMP" => "timestamp",
        "DATE"      => "date",
        "TIME"      => "string", "DATETIME" => "string",
        "RECORD"    => "object", "STRUCT"   => "object"
      }
      hint_map = {
        "TIME"     => "Represents a time, independent of a specific date. " \
          "Example: 11:16:00.000000",
        "DATETIME" => "Represents a year, month, day, hour, minute, " \
          "second, and subsecond. Example: 2017-09-13T11:16:00.000000"
      }

      (input["fields"] || []).map do |field|
        field_type = type_map[field["type"]]
        {
          name: field["name"],
          label: field["name"],
          hint: [field["description"], hint_map[field["type"]]].
            compact.join("<br/>"),
          optional: (field["mode"] != "REQUIRED"),
          control_type: (field_type == "boolean" ? "checkbox" : nil),
          type: field_type,
          properties: if field_type == "object"
                        call("schema_for_table", "fields" => field["fields"])
                      end
        }.compact
      end
    end
  },

  object_definitions: {
    table: {
      fields: lambda do |_connection, config_fields|
        table = config_fields["table"]
        if table.present?
          fields = get("/bigquery/v2/projects/#{config_fields['project']}" \
                     "/datasets/#{config_fields['dataset']}/tables/#{table}").
                   dig("schema", "fields")

          [
            name: "rows",
            optional: false,
            type: "array",
            of: "object",
            properties: [
              {
                name: "insertId",
                hint: "A unique ID for each row. More details <a " \
                 "href='https://cloud.google.com/bigquery/streaming-data-" \
                 "into-bigquery#dataconsistency' target='_blank'>here</a>."
              }
            ].concat(call("schema_for_table", "fields" => fields))
          ]
        else
          []
        end
      end
    }
  },

  actions: {
    add_rows: {
      subtitle: "Add data rows",
      description: "Add <span class='provider'>rows</span> to table " \
        "in <span class='provider'>Google BigQuery</span>",
      help: "Streams data into a table of Google BigQuery.",

      config_fields: [
        {
          name: "project",
          hint: "Select the appropriate project to insert data",
          optional: false,
          control_type: "select",
          pick_list: "projects"
        },
        {
          name: "dataset",
          hint: "Select a dataset to view list of tables",
          optional: false,
          control_type: "select",
          pick_list: "datasets",
          pick_list_params: { project_id: "project" }
        },
        {
          name: "table",
          hint: "Select a table to stream data",
          optional: false,
          control_type: "select",
          pick_list: "tables",
          pick_list_params: { project_id: "project", dataset_id: "dataset" }
        }
      ],

      input_fields: ->(object_definitions) { object_definitions["table"] },

      execute: lambda do |_connection, input|
        post("/bigquery/v2/projects/#{input['project']}/datasets/" \
          "#{input['dataset']}/tables/#{input['table']}/insertAll").
          params(fields: "kind,insertErrors").
          payload(rows: input["rows"].map do |row|
                          { insertId: row.delete("insertId") || "", json: row }
                        end)
      end,

      output_fields: ->(_object_definitions) { [{ name: "kind" }] },

      sample_output: -> { { kind: "bigquery#tableDataInsertAllResponse" } }
    }
  },

  pick_lists: {
    projects: lambda do |_connection|
      get("/bigquery/v2/projects")["projects"].pluck("friendlyName", "id")
    end,

    datasets: lambda do |_connection, project_id:|
      get("/bigquery/v2/projects/#{project_id}/datasets")["datasets"].
        map do |dataset|
          [dataset["datasetReference"]["datasetId"],
           dataset["datasetReference"]["datasetId"]]
        end
    end,

    tables: lambda do |_connection, project_id:, dataset_id:|
      get("/bigquery/v2/projects/#{project_id}/datasets/#{dataset_id}" \
        "/tables")["tables"].
        map do |table|
          [table["tableReference"]["tableId"],
           table["tableReference"]["tableId"]]
        end
    end
  }
}
