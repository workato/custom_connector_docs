{
  title: "Marketo",

  connection: {
    fields: [
      { name: "domain",
        control_type: "subdomain",
        url: ".mktorest.com/rest",
        optional: false,
        hint: "Base URL can be found in Admin > Integration > Web Services" },
      { name: "client_id",
        optional: false,
        hint: "Client ID can be found in Admin > Integration > LaunchPoint" },
      { name: "client_secret",
        control_type: "password",
        optional: false,
        hint: "Client Secret can be found in Admin > Integration > LaunchPoint" }
    ],

    authorization: {
      type: "custom_auth",

      acquire: lambda do |connection|
        {
          access_token: get("https://#{connection['domain']}.mktorest.com/identity/oauth/token").
                        params(client_id: connection["client_id"],
                               client_secret: connection["client_secret"],
                               grant_type: "client_credentials")["access_token"]
        }
      end,

      detect_on: [
        401,
        /.+("success":false).+/
      ],

      apply: lambda do |connection|
        headers("Authorization": "Bearer " + connection["access_token"].to_s)
      end
    },

    base_uri: lambda do |connection|
      "https://#{connection['domain']}.mktorest.com"
    end
  },

  object_definitions: {
    lead: {
      fields: lambda do |_connection|
        get("/rest/v1/leads/describe.json")["result"].
          map { |field|
            {
              name: field.dig("rest", "name"),
              label: field.dig("displayName"),
              type: (
                if ["integer", "boolean", "date"].include? (field.dig("dataType"))
                  field.dig("dataType")
                elsif field.dig("dataType") == "datetime"
                  "date_time"
                elsif field.dig("dataType") == "float"
                  "number"
                else
                  "string"
                end
              ),
              control_type: (
                if ["integer", "date", "url", "email", "phone"].
                  include?(field.dig("dataType"))
                  field.dig("dataType")
                elsif field.dig("dataType") == "datetime"
                  "date_time"
                elsif field.dig("dataType") == "float"
                  "number"
                else
                  "text"
                end
              )
            }
          }
      end
    },
    bulk_lead: {
      fields: lambda do |_object_definitions|
        [
          { name: "requestId" },
          { name: "success", type: "boolean" },
          {
            name: "result", type: "array", of: "object", properties: [
              { name: "batchId" },
              { name: "importId" },
              { name: "message" },
              { name: "status" },
              {
                name: "numOfLeadsProcessed",
                label: "Leads processed",
                type: "integer",
                control_type: "integer"
              },
              {
                name: "numOfRowsFailed",
                label: "Rows failed",
                type: "integer",
                control_type: "integer"
              },
              {
                name: "numOfRowsWithWarning",
                label: "Rows with warning",
                type: "integer",
                control_type: "integer"
              }
            ]
          },
          {
            name: "warnings", type: "array", of: "object", properties: [
              { name: "code", type: "integer", control_type: "integer" },
              { name: "message" }
            ]
          },
          {
            name: "errors", type: "array", of: "object", properties: [
              { name: "code", type: "integer", control_type: "integer" },
              { name: "message" }
            ]
          }
        ]
      end
    },
    programs: {
      fields: lambda do |_object_definitions|
        [
          { name: "name" },
          { name: "id"},
          { name: "description" },
          { name: "createdAt"},
          { name: "updatedAt" },
          { name: "url" },
          { name: "type"},
          { name: "channle"},
          { name: "folder",
              type: :object,
              properties: [
                {
                  name: "type"
                },
                {
                  name: "value"
                },
                {
                  name: "folderName",
                }
        	]
          },
          { name: "status" },
          { name: "Workspace"},
          { name: "tags" },
          { name: "costs",
              	type: :array,
          		of: :object,
              properties: [
                {
                  name: "startDate"
                },
                {
                  name: "cost"
                }
        	]
          },
        ]
      end
    },
    response: {
      fields: lambda do |_object_definitions|
        [
          { name: "requestId" },
          { name: "success",
            type: :boolean
          },
          { name: "result",
              type: :object,
              properties: [
                {
                  name: "id",
                  type: :integer
                },
                {
                  name: "status"
                }
        	]
          }
        ]
      end
    }
  },

  test: lambda do |connection|
    get("https://#{connection['domain']}.mktorest.com" \
      "/rest/v1/lead.json?batchSize=1")
  end,

  actions: {
    bulk_import_leads: {
      description: "Bulk import <span class='provider'>leads</span> into " \
        "<span class='provider'>Marketo</span>",
      help: "Bulk import a list of leads in CSV format. " \
        "Max file size is 10MB.",

      input_fields: lambda do
        [
          {
            name: "lookupField",
            label: "Lookup using",
            control_type: "select",
            pick_list: "lookup_types",
            optional: false,
            hint: "Field to use for deduplication. Default is email. " \
              "Note: You can use ID for update only operations."
          },
          {
            name: "file",
            label: "CSV contents",
            optional: false,
            hint: "Place contents of CSV including header here. " \
              "CSV header name must be aligned with REST API name. " \
              "Find out more <a href='https://developers.marketo.com/" \
              "rest-api/lead-database/fields/' target='_blank'>here</a>"
          }
        ]
      end,

      execute: lambda do |_connection, input|
        post("/bulk/v1/leads.json?format=csv").
          params(format: "csv",
                 lookupField: input["lookupField"]).
          request_format_multipart_form.
          payload(file: [input["file"], "text/csv"])
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["bulk_lead"]
      end
    },

    get_bulk_job_status: {
      input_fields: lambda do
        { name: "batchId", label: "Batch ID", optional: false }
      end,

      execute: lambda do |_connection, input|
        get("/bulk/v1/leads/batch/#{input['batchId']}.json")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["bulk_lead"]
      end
    },
    create_program: {
      description: "Create <span class='provider'>programs</span> in " \
        "<span class='provider'>Marketo</span>",
      help: "Create events, emails etc. in marketo" \
        "Max file size is 10MB.",

      input_fields: lambda do
        [
          {
            name: "name",
            label: "Event Name",
            control_type: "string",
            optional: false,
            hint: "Event Name"
          },
          {
            name: "folder",
            label: "Folder",
            type: "object",
            optional: false,
            properties: [
              { name: "id", type: "integer", control_type: "number" },
              { name: "type" }
            ]
          },
          {
            name: "description",
            label: "Description",
            optional: false
          },
          {
            name: "type",
            label: "Folder Type",
            optional: false,
            hint: "Folder"
          },
          {
            name: "channel",
            label: "Channel",
            optional: false
          },
          {
            name: "costs",
            label: "Costs",
            type: "array",
            of: "object",
            optional: false,
            properties: [
              { name: "startDate", type: "date", control_type: "date" },
              { name: "cost", type: "number", control_type: "number" }
            ]
          }
        ]
      end,

      execute: lambda do |_connection, input|
        post("/rest/asset/v1/programs.json")
          .payload(input)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["programs"]
      end
    },
    batch_create_leads: {
      description: "Batch create / update <span class='provider'>leads</span>" \
        " into <span class='provider'>Marketo</span>",
      help: "Batch create or update a list of leads",

      input_fields: lambda do|object_definitions|
        [
          {
            name: "action",
            label: "Operation type of the request",
            control_type: "select",
            pick_list: "action_types",
            optional: true,
            hint: "If it is omitted, the action defaults to createOrUpdate"
          },
          {
            name: "lookupField",
            label: "Lookup using",
            control_type: "select",
            pick_list: "lookup_types",
            optional: true,
            hint: "Field to use for deduplication. Default is email. " \
              "Note: You can use ID for update only operations."
          },
          {
            name: "leads",
            label: "Leads list",
            type: "array",
            of: "object",
            properties: object_definitions["lead"],
            hint: "List of Lead objects"
          }
        ]
      end,

      execute: lambda do |_connection, input|
        post("/rest/v1/leads.json")
          .payload(action: input["action"],
                   lookupField: input["lookupField"],
                   input: input["leads"])
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["response"]
      end
    }
  },

  triggers: {
    new_lead_in_program: {
      description: "New <span class='provider'>lead</span> in " \
        "<span class='provider'>Marketo</span> program",

      input_fields: lambda do
        [
          { name: "program",
            label: "Program",
            type: "string",
            control_type: "select",
            pick_list: "programs",
            optional: false }
        ]
      end,

      poll: lambda do |_connection, input, next_poll|
        next_token = next_poll

        if next_token.present?
          response = get("/rest/v1/leads/programs/#{input['program']}.json").
                     params(batchSize: 300, nextPageToken: next_token)
        else
          response = get("/rest/v1/leads/programs/#{input['program']}.json").
                     params(batchSize: 300)
        end
        {
          events: response["result"],
          can_poll_more: response["nextPageToken"].present?,
          next_poll: (response["nextPageToken"] || nil)
        }
      end,

      dedup: lambda do |item|
        item["id"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["lead"].
          only("id", "firstName", "lastName",
               "email", "createdAt", "updatedAt").
          concat(
            [
              {
                name: "membership", type: "object", properties: [
                  { name: "progressionStatus", label: "Program status" },
                  { name: "isExhausted", type: "boolean" },
                  { name: "acquiredBy", type: "boolean" },
                  { name: "reachedSuccess", type: "boolean" },
                  {
                    name: "membershipDate",
                    type: "timestamp",
                    control_type: "date_time",
                    render_input: "date_time_conversion",
                    parse_output: "date_time_conversion"
                  },
                  { name: "nurtureCadence" },
                  { name: "stream" }
                ]
              }
            ]
          )
      end
    }
  },

  pick_lists: {
    programs: lambda do |_connection|
      get("/rest/asset/v1/programs.json").
        params(maxReturn: 200)["result"].pluck("name", "id")
    end,

    lookup_types: lambda do
      [
        %w[ID id],
        %w[Email email],
        %w[Salesforce\ Account\ ID sfdcAccountId],
        %w[Salesforce\ Contact\ ID sfdcContactId],
        %w[Salesforce\ Lead\ ID sfdcLeadId],
        %w[Salesforce\ Opportunity\ ID sfdcOpptyId],
        %w[Salesforce\ Lead\ Owner\ ID sfdcLeadOwnerId]
      ]
    end,

    action_types: lambda do
      [
        %w[Create\ or\ Update createOrUpdate],
        %w[Create createOnly],
        %w[Update updateOnly],
        %w[Create\ Duplicate createDuplicate]
      ]
    end
  }
}
