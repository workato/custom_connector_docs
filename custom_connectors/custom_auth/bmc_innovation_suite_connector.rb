{
  title: "BMC Innovation Suite",

  connection: {
    fields: [
      {
        name: "username",
        hint: "BMC app login username",
        optional: false
      },
      {
        name: "password",
        hint: "BMC app login password",
        optional: false,
        control_type: "password"
      },
      {
        name: "environment",
        hint: "Complete base url, eg: <b>http://mobility78-bis.trybmc.com</b>",
        optional: false
      }
    ],

    authorization: {
      type: "custom_auth",

      acquire: lambda do |connection|
        {
          authtoken: post("#{connection['environment']}" \
                            "/api/rx/application/command",
                          username: connection["username"],
                          password: connection["password"],
                          resourceType: "com.bmc.arsys.rx.application." \
                            "user.command.LoginCommand").
            headers("X-Requested-By" => "XMLHttpRequest").
            response_format_raw
        }
      end,

      refresh_on: [
        400,
        401,
        /Authentication failed. Please login again./
      ],

      detect_on: [/"messageType"\s*\:\s*"ERROR"/],

      apply: lambda do |connection|
        headers("Authorization" =>  "AR-JWT #{connection['authtoken']}",
                "X-Requested-By" => "XMLHttpRequest")
      end
    },

    base_uri: ->(connection) { connection["environment"] }
  },

  test: lambda do |_connection|
    get("/api/arsys/v1/entry/com.bmc.dsm.hrcm-lib:Case", limit: 1)
  end,

  object_definitions: {
    case_: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: "1", label: "Display ID" },
          { name: "2", label: "Created By" },
          { name: "3", label: "Created Date" },
          { name: "4", label: "Assignee" },
          { name: "5", label: "Modified By" },
          { name: "6", label: "Modified Date" },
          { name: "7", label: "Status" },
          { name: "8", label: "Summary" },
          { name: "16", label: "Notifier Listening" },
          { name: "179", label: "GUID" },
          { name: "379", label: "ID" },
          { name: "61001", label: "Application Bundle ID" },
          { name: "300865500", label: "Template Name" },
          { name: "301362200", label: "Notify" },
          { name: "304411211", label: "Origin" },
          { name: "450000010", label: "Ticket Status GUID" },
          { name: "450000021", label: "Ticket Status" },
          { name: "450000029", label: "Service Request Display ID" },
          { name: "450000041", label: "Service Request GUID" },
          { name: "450000111", label: "RLS Manual Update" },
          { name: "450000121", label: "Flowset" },
          { name: "1000000000", label: "Description" },
          { name: "1000000001", label: "Company" },
          { name: "1000000063", label: "Category Tier 1" },
          { name: "1000000064", label: "Category Tier 2" },
          { name: "1000000065", label: "Category Tier 3" },
          { name: "1000000164", label: "Priority" },
          { name: "1000000217", label: "Assigned Group" },
          { name: "1000000337", label: "Requester" },
          { name: "1000000881", label: "Status Reason" },
          { name: "1000001021", label: "Contact" },
          { name: "1000005261", label: "Target Date" }
        ]
      end
    },

    person: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: "createdBy" },
          { name: "createdDate", type: "timestamp" },
          { name: "modifiedBy" },
          { name: "modifiedDate", type: "timestamp" },
          { name: "id" },
          { name: "loginId" },
          {
            name: "personSelection",
            type: "object",
            properties: [{ name: "id" }, { name: "value" }]
          },
          { name: "personImage" },
          { name: "fullName" },
          { name: "primaryEmailAddress", control_type: "email" },
          { name: "primaryPhoneNumber", control_type: "phone" },
          {
            name: "primaryOrganization",
            type: "object",
            properties: [
              { name: "id" },
              {
                name: "organizationSelection",
                type: "object",
                properties: [{ name: "id" }, { name: "value" }]
              },
              { name: "organizationName" }
            ]
          },
          {
            name: "primarySite",
            type: "object",
            properties: [
              { name: "id" },
              { name: "locationName" },
              {
                name: "country",
                type: "object",
                properties: [{ name: "id" }, { name: "name" }]
              },
              {
                name: "stateProvinceDistrict",
                type: "object",
                properties: [{ name: "id" }, { name: "name" }]
              },
              {
                name: "city",
                type: "object",
                properties: [{ name: "id" }, { name: "name" }]
              },
              { name: "streetAddress" },
              { name: "zipPostalCode" },
              {
                name: "parentRegion",
                type: "object",
                properties: [{ name: "id" }, { name: "locationName" }]
              }
            ]
          },
          { name: "isManager", type: "boolean", control_type: "checkbox" },
          {
            name: "VIP",
            type: "object",
            properties: [{ name: "id" }, { name: "value" }]
          }
        ]
      end
    },

    question: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: "1", label: "Display ID" },
          { name: "2", label: "Created by" },
          { name: "3", label: "Created date", type: "timestamp" },
          { name: "4", label: "Assignee" },
          { name: "5", label: "Modified by" },
          { name: "6", label: "Modified date", type: "timestamp" },
          { name: "7", label: "Status" },
          { name: "8", label: "Summary" },
          { name: "16", label: "Status history" },
          { name: "179", label: "GUID" },
          { name: "379", label: "ID" },
          { name: "300979900", label: "Question" },
          { name: "303935200", label: "Answer" }
        ]
      end
    },

    ticket_status: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: "guid", label: "GUID" },
          { name: "statusValue" },
          { name: "statusLabel" }
        ]
      end
    },

    reason: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: "8", label: "Summary" },
          { name: "379", label: "ID" },
          { name: "302307031", label: "Application Status Label" }
        ]
      end
    }
  },

  actions: {
    search_case: {
      description: "Search <span class='provider'>case</span> in " \
        "<span class='provider'>BMC Innovation Suite</span>",

      execute: lambda do |_connection, input|
        params = {
          dataPageType: "com.bmc.arsys.rx.application." \
            "record.datapage.RecordInstanceDataPageQuery",
          pageSize: 50,
          recorddefinition: "com.bmc.dsm.hrcm-lib:Case",
          sortBy: "-6",
          startIndex: 0,
          propertySelection: "1,2,3,4,5,6,7,8,16,179,379,61001,300865500," \
            "301362200,304411211,450000010,450000021,450000029,450000041," \
            "1000000000,1000000001,1000000063," \
            "1000000064,1000000065,1000000164,1000000217,1000000337," \
            "1000000881,1000001021,1000005261",
          queryExpression: (input || []).
                 map { |key, value| "'#{key}' = \"#{value}\"" }.
                 join(" AND ")
        }

        {
          cases: get("/api/rx/application/datapage", params)["data"] || []
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["case_"].
          only("1", "2", "4", "5", "7", "8", "179", "379")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "cases",
          type: "array",
          of: "object",
          properties: object_definitions["case_"]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        params = {
          dataPageType: "com.bmc.arsys.rx.application." \
            "record.datapage.RecordInstanceDataPageQuery",
          pageSize: 1,
          recorddefinition: "com.bmc.dsm.hrcm-lib:Case",
          sortBy: "-6",
          startIndex: 0,
          propertySelection: "1,2,3,4,5,6,7,8,16,179,379,61001,300865500," \
            "301362200,304411211,450000010,450000021,450000029,450000041," \
            "1000000000,1000000001,1000000063," \
            "1000000064,1000000065,1000000164,1000000217,1000000337," \
            "1000000881,1000001021,1000005261"
        }

        {
          cases: get("/api/rx/application/datapage", params)["data"] || []
        }
      end
    },

    get_case_by_id: {
      description: "Get <span class='provider'>case</span> by ID in " \
        "<span class='provider'>BMC Innovation Suite</span>",

      execute: lambda do |_connection, input|
        (get("/api/rx/application/record/recordinstance/" \
          "com.bmc.dsm.hrcm-lib:Case/#{input['id']}")["fieldInstances"] || []).
          map { |_key, field| { field["id"].to_s => field["value"] } }.
          inject(:merge)
      end,

      input_fields: lambda do |_object_definitions|
        [{ name: "id", optional: false }]
      end,

      output_fields: ->(object_definitions) { object_definitions["case_"] },

      sample_output: lambda do |_connection, _input|
        params = {
          dataPageType: "com.bmc.arsys.rx.application." \
            "record.datapage.RecordInstanceDataPageQuery",
          pageSize: 1,
          recorddefinition: "com.bmc.dsm.hrcm-lib:Case",
          sortBy: "-6",
          startIndex: 0,
          propertySelection: "379"
        }
        latest_record = get("/api/rx/application/datapage", params).
                        dig("data", 0, "379") || ""

        (get("/api/rx/application/record/recordinstance/com.bmc.dsm.hrcm-lib:" \
          "Case/#{latest_record}")["fieldInstances"] || []).
          map { |_key, field| { field["id"].to_s => field["value"] } }.
          inject(:merge)
      end
    },

    update_case: {
      description: "Update <span class='provider'>case</span> in " \
        "<span class='provider'>BMC Innovation Suite</span>",

      input_fields: lambda do |object_definitions|
        object_definitions["case_"].ignored("2", "3", "5", "6").required("379")
      end,

      execute: lambda do |_connection, input|
        payload = {
          resourceType: "com.bmc.arsys.rx.services.record.domain." \
            "RecordInstance",
          id: input["379"],
          recordDefinitionName: "com.bmc.dsm.hrcm-lib:Case",
          fieldInstances: input.
                  map do |key, value|
                    {
                      key => {
                        "resourceType" => "com.bmc.arsys.rx.services." \
                        "record.domain.FieldInstance",
                        "id" => key,
                        "value" => value
                      }
                    }
                  end.
                  inject(:merge)
        }

        put("/api/rx/application/record/recordinstance" \
              "/com.bmc.dsm.hrcm-lib:Case/#{input['379']}", payload)
      end
    },

    get_questions_by_case_id: {
      description: "Get <span class='provider'>questions</span> by case " \
        "ID in <span class='provider'>BMC Innovation Suite</span>",

      input_fields: lambda do |_object_definitions|
        [{ name: "case_id", optional: false }]
      end,

      execute: lambda do |_connection, input|
        params = {
          dataPageType: "com.bmc.arsys.rx.application.association.datapage." \
            "AssociationInstanceDataPageQuery",
          pageSize: 50,
          associationDefinition: "com.bmc.dsm.hrcm-lib:Case_Question",
          associatedRecordInstanceId: input["case_id"],
          nodeToQuery: "nodeB",
          sortBy: "-6",
          startIndex: 0,
          propertySelection: "1,2,3,4,5,6,7,8,16,179,379,300979900,303935200"
        }

        {
          questions: get("/api/rx/application/datapage", params)["data"] || []
        }
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "questions",
          type: "array",
          of: "object",
          properties: object_definitions["question"]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        params = {
          dataPageType: "com.bmc.arsys.rx.application." \
            "record.datapage.RecordInstanceDataPageQuery",
          pageSize: 1,
          recorddefinition: "com.bmc.dsm.hrcm-lib:Case",
          sortBy: "-6",
          startIndex: 0,
          propertySelection: "379"
        }
        latest_record = get("/api/rx/application/datapage", params).
                        dig("data", 0, "379") || ""
        params = {
          dataPageType: "com.bmc.arsys.rx.application.association.datapage." \
            "AssociationInstanceDataPageQuery",
          pageSize: 1,
          associationDefinition: "com.bmc.dsm.hrcm-lib:Case_Question",
          associatedRecordInstanceId: latest_record,
          nodeToQuery: "nodeB",
          sortBy: "-6",
          startIndex: 0,
          propertySelection: "1,2,3,4,5,6,7,8,16,179,379,300979900,303935200"
        }

        {
          questions: get("/api/rx/application/datapage", params)["data"] || []
        }
      end
    },

    get_person_by_id: {
      description: "Get <span class='provider'>person</span> by ID in " \
        "<span class='provider'>BMC Innovation Suite</span>",

      input_fields: lambda do |object_definitions|
        object_definitions["person"].only("id").required("id")
      end,

      execute: lambda do |_connection, input|
        get("/api/com.bmc.arsys.rx.foundation/person/cards/#{input['id']}").
          params(include: "thumbnail,primarySite,primaryemail,primaryphone," \
            "department")
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["person"]
      end,

      sample_output: lambda do |_connection, _input|
        get("/api/com.bmc.arsys.rx.foundation/person/cards").
          params(include: "thumbnail,primarySite,primaryemail,primaryphone," \
            "department", pageSize: 1, sortBy: "-6").dig("data", 0)
      end
    },

    get_all_ticket_statuses: {
      description: "Get all <span class='provider'>ticket statuses</span> " \
        "in <span class='provider'>BMC Innovation Suite</span>",

      execute: lambda do |_connection, _input|
        params = {
          organizationId: "Global",
          recordDefinitionName: "com.bmc.dsm.hrcm-lib:Case",
          fromStatus: 1000
        }

        {
          ticket_statuses: get("api/com.bmc.dsm.shared-services-lib" \
            "/rx/application/statustransition/nextstatuslist", params) || []
        }
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "ticket_statuses",
          type: "array",
          of: "object",
          properties: object_definitions["ticket_status"]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        params = {
          organizationId: "Global",
          recordDefinitionName: "com.bmc.dsm.hrcm-lib:Case"
        }

        {
          ticket_statuses: get("api/com.bmc.dsm.shared-services-lib" \
            "/rx/application/statustransition/nextstatuslist", params) || []
        }
      end
    },

    get_reasons_by_ticket_status_id: {
      description: "Get <span class='provider'>reasons</span> by ticket " \
        "status ID in <span class='provider'>BMC Innovation Suite</span>",

      input_fields: lambda do |_object_definitions|
        [{ name: "status_id", optional: false }]
      end,

      execute: lambda do |_connection, input|
        params = {
          dataPageType: "com.bmc.arsys.rx.application.association." \
            "datapage.AssociationInstanceDataPageQuery",
          pageSize: "-1",
          associatedRecordInstanceId: input["status_id"],
          nodeToQuery: "nodeB",
          startIndex: 0,
          propertySelection: "379,302307031",
          associationDefinition:
            "com.bmc.dsm.shared-services-lib:Status to Status Reason"
        }

        {
          reasons: get("/api/rx/application/datapage", params)["data"] || []
        }
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "reasons",
          type: "array",
          of: "object",
          properties: object_definitions["reason"]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        sample_params = {
          organizationId: "Global",
          recordDefinitionName: "com.bmc.dsm.hrcm-lib:Case"
        }
        ticket_status_id = get("api/com.bmc.dsm.shared-services-lib" \
          "/rx/application/statustransition/nextstatuslist", sample_params).
                           dig(0, "guid") || ""
        params = {
          dataPageType: "com.bmc.arsys.rx.application.association." \
            "datapage.AssociationInstanceDataPageQuery",
          pageSize: "1",
          associatedRecordInstanceId: ticket_status_id,
          nodeToQuery: "nodeB",
          startIndex: 0,
          propertySelection: "379,302307031",
          associationDefinition:
            "com.bmc.dsm.shared-services-lib:Status to Status Reason"
        }

        {
          reasons: get("/api/rx/application/datapage", params)["data"] || []
        }
      end
    }
  },

  triggers: {
    new_or_updated_case: {
      subtitle: "New/updated case",
      description: "New or updated <span class='provider'>case</span> " \
        "in <span class='provider'>BMC Innovation Suite</span>",
      type: "paging_desc",

      input_fields: lambda do |_connection|
        [{
          name: "since",
          label: "From",
          type: "timestamp",
          optional: true,
          sticky: true,
          hint: "Get cases created or updated since given date/time. " \
              "Leave empty to get cases created or updated one hour ago"
        }]
      end,

      poll: lambda do |_connection, input, start_index|
        start_index ||= 0
        page_size = 50
        params = {
          dataPageType: "com.bmc.arsys.rx.application." \
            "record.datapage.RecordInstanceDataPageQuery",
          pageSize: page_size,
          recorddefinition: "com.bmc.dsm.hrcm-lib:Case",
          sortBy: "-6",
          startIndex: start_index,
          propertySelection: "1,2,3,4,5,6,7,8,16,179,379,61001,300865500," \
            "301362200,304411211,450000010,450000021,450000029,450000041," \
            "1000000000,1000000001,1000000063," \
            "1000000064,1000000065,1000000164,1000000217,1000000337," \
            "1000000881,1000001021,1000005261",
          queryExpression: "'6' >= " \
            "\"#{(input['since'].presence || 1.hour.ago).utc.iso8601}\""
        }
        response = get("/api/rx/application/datapage", params)
        next_index = page_size + start_index

        {
          events: response["data"] || [],
          next_page: response["totalSize"] >= next_index ? next_index : nil
        }
      end,

      document_id: ->(case_) { case_["1"] },

      sort_by: ->(case_) { case_["6"] },

      output_fields: ->(object_definitions) { object_definitions["case_"] },

      sample_output: lambda do |_connection, _input|
        params = {
          dataPageType: "com.bmc.arsys.rx.application." \
            "record.datapage.RecordInstanceDataPageQuery",
          pageSize: 1,
          recorddefinition: "com.bmc.dsm.hrcm-lib:Case",
          sortBy: "-6",
          startIndex: 0,
          propertySelection: "1,2,3,4,5,6,7,8,16,179,379,61001,300865500," \
            "301362200,304411211,450000010,450000021,450000029,450000041," \
            "1000000000,1000000001,1000000063," \
            "1000000064,1000000065,1000000164,1000000217,1000000337," \
            "1000000881,1000001021,1000005261"
        }

        get("/api/rx/application/datapage", params).dig("data", 0) || {}
      end
    }
  }
}
