{
  title: "Microsoft Office 365",

  connection: {
    fields: [
      {
        name: "client_id",
        optional: false,
        hint: "Find your client secret <a href='https://apps.dev.microsoft." \
          "com/' target='_blank'>here</a>"
      },
      {
        name: "client_secret",
        control_type: "password",
        optional: false,
        hint: "Find your client secret <a href='https://apps.dev.microsoft." \
          "com/' target='_blank'>here</a>"
      }
    ],

    authorization: {
      type: "oauth2",

      authorization_url: lambda do |_connection|
        scopes = ["offline_access",
                  "user.read.all",
                  "files.readwrite.all"].join(" ")

        "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?" \
          "response_type=code&scope=#{scopes}&prompt=login&" \
          "redirect_uri=https%3A%2F%2Fwww.workato.com%2Foauth%2Fcallback"
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
        response =
          post("https://login.microsoftonline.com/common/oauth2/v2.0/token").
            payload(client_id: connection["client_id"],
                    client_secret: connection["client_secret"],
                    grant_type: "authorization_code",
                    code: auth_code,
                    redirect_uri: redirect_uri).
            request_format_www_form_urlencoded

        [response, nil, nil]
      end,

      refresh_on: [401],

      apply: lambda do |_connection, access_token|
        headers("Authorization" => "Bearer #{access_token}")
      end
    },

    base_uri: lambda do
      "https://graph.microsoft.com"
    end
  },

  test: lambda do |_connection|
    get("/v1.0/me")
  end,

  object_definitions: {
    worksheet_output: {
      fields: lambda do |_connection, config|
        get(
          "/v1.0/me/drive/items/#{config['file']}/workbook/worksheets" \
          "('#{config['worksheet']}')/usedRange?$select=formulas"
        )["formulas"]&.first&.
          map do |f|
            { name: f, label: f }
          end
      end
    }
  },

  actions: {
    search_drive_item: {
      description: "Search <span class='provider'>item</span> in " \
        "<span class='provider'>Microsoft Office 365</span> drive",

      input_fields: lambda do |_object_definitions|
        { name: "name", type: :string, optional: false,
          label: "Folder/File Name" }
      end,

      execute: lambda do |_connection, input|
        {
          items:
            get("/v1.0/me/drive/root/search(q='#{input['name']}')")["value"]
        }
      end,

      output_fields: lambda do |_object_definitions|
        [
          { name: "items", type: :array, of: :object, properties: [
            { name: "id", type: :string, control_type: :text, label: "Id" },
            { name: "name", type: :string, control_type: :text, label: "Name" },
            { name: "webUrl", type: :string, control_type: :url },
            { name: "parentReference", type: :object, properties: [
              { name: "driveId", type: :string },
              { name: "id", type: :string }
            ] },
            { name: "file", type: :object, properties: [] },
            { name: "folder", type: :object, properties: [
              { name: "childCount", type: :number }
            ] },
            { name: "searchResult", type: :object, properties: [
              { name: "onClickTelemetryUrl", type: :string, control_type: :url }
            ] },
            { name: "createdDateTime", type: :datetime,
              control_type: :timestamp },
            { name: "lastModifiedDateTime", type: :datetime,
              control_type: :timestamp },
            { name: "createdBy", type: :object, properties: [
              { name: "user", type: :object, properties: [
                { name: "displayName", type: :string, control_type: :text }
              ] }
            ] },
            { name: "lastModifiedBy", type: :object, properties: [
              { name: "user", type: :object, properties: [
                { name: "displayName", type: :string, control_type: :text }
              ] }
            ] },
            { name: "size", type: :number }
          ] }
        ]
      end
    },

    get_workbook_sheets: {
      description: "Get workbook <span class='provider'>sheets</span> in " \
        "<span class='provider'>Microsoft Office 365</span> drive",

      input_fields: lambda do |_object_definitions|
        { name: "id", type: :string, control_type: :string, optional: false,
          label: "Workbook Id" }
      end,

      execute: lambda do |_connection, input|
        {
          worksheets:
            get("/v1.0/me/drive/items/#{input['id']}/workbook/worksheets")
        }
      end,

      output_fields: lambda do |_object_definitions|
        [
          { name: "id", type: :string, control_type: :text },
          { name: "name", type: :string, control_type: :text },
          { name: "position", type: :integer, control_type: :number },
          { name: "visibility", type: :string, control_type: :text }
        ]
      end
    },

    get_worksheet_content: {
      description: "Get worksheet <span class='provider'>content</span> in " \
        "<span class='provider'>Microsoft Office 365</span> drive",

      input_fields: lambda do |_object_definitions|
        [
          { name: "id", type: :string, control_type: :text,
            label: "Workbook Id", optional: false },
          { name: "sheet", type: :string, control_type: :text,
            label: "Sheet Name", optional: false },
          { name: "address", type: :string, control_type: :text,
            label: "Address", optional: false }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/v1.0/me/drive/items/#{input['id']}/workbook/worksheets" \
          "('#{input['sheet']}')/range(address='#{input['address']}')")
      end,

      output_fields: lambda do |_object_definitions|
        [
          { name: "address", type: :string, label: "Address Range" },
          { name: "cellCount", type: :integer, label: "Cell Count" },
          { name: "columnCount", type: :integer },
          { name: "columnIndex", type: :integer },
          { name: "rowCount", type: :integer },
          { name: "rowIndex", type: :integer },
          { name: "values", type: :array, of: :array, properties: [] }
        ]
      end,
    },

    add_row: {
      description: "Add <span class='provider'>row</span> in " \
        "<span class='provider'>Microsoft Office 365</span> excel sheet",
      help: "Adds a row in fffice 365 Excel Sheet",

      config_fields: [
        {
          name: "file",
          control_type: "select",
          pick_list: "xlsxfiles",
          optional: false,
          hint: "Select Workbook File"
        },
        {
          name: "worksheet",
          control_type: "select",
          pick_list: "worksheets",
          pick_list_params: { workbook_id: "file" },
          optional: false,
          hint: "Select Sheet"
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions["worksheet_output"]
      end,

      execute: lambda do |_connection, input|
        address =
          get("/v1.0/me/drive/items/#{input['file']}/workbook/worksheets(" \
            "'#{input['worksheet']}')/usedRange?$select=address,rowCount")
        file = input["file"]
        worksheet = input["worksheet"]
        input.delete("file")
        input.delete("worksheet")
        rownum = address["rowCount"].to_i + 1
        range = address["address"].split("!").last
        first = range.split(":").first.scan(/([A-Z]+)/).first.first
        last = range.split(":").last.scan(/([A-Z]+)/).first.first
        rangeaddress = first + rownum + ":" + last + rownum

        post("/v1.0/me/drive/items/#{file}/workbook/worksheets/#{worksheet}/" \
          "range(address='#{rangeaddress}')/insert").
          headers(shift: "Right").
          payload(values: [input.values])

        patch("/v1.0/me/drive/items/#{file}/workbook/worksheets/" \
          "#{worksheet}/range(address='#{rangeaddress}')").
          payload(values: [input.values])
      end,

      output_fields: lambda do |_object_definitions|
        [
          { name: "@odata.id", type: :string },
          { name: "address", type: :string },
          { name: "cellCount", type: :integer },
          { name: "columnCount", type: :integer },
          { name: "rowCount", type: :integer },
          { name: "rowIndex", type: :integer }
        ]
      end
    }
  },

  triggers: {
    new_row_in_sheet: {
      description: "New <span class='provider'>row</span> in <span class=" \
        "'provider'>Microsoft Office 365</span> excel sheet",

      config_fields: [
        {
          name: "file",
          control_type: "select",
          pick_list: "xlsxfiles",
          optional: false,
          hint: "Select Workbook File"
        },
        {
          name: "worksheet",
          control_type: "select",
          pick_list: "worksheets",
          pick_list_params: { workbook_id: "file" },
          optional: false,
          hint: "Select Sheet"
        }
      ],

      poll: lambda do |_connection, input, last_record_id|
        from_record_id = last_record_id || 2
        address =
          get("/v1.0/me/drive/items/#{input['file']}/workbook/worksheets" \
            "('#{input['worksheet']}')/usedRange?$select=address,formulas," \
            "rowCount")
        output_fields = address["formulas"]&.first&.
                          map do |f|
                            f
                          end

        startrow = from_record_id.to_i
        range = address["address"].split("!").last
        endrow = range.split(":").last.scan(/\d+/).first

        firstcolumn = range.split(":").first.scan(/([A-Z]+)/).first.first
        lastcolumn = range.split(":").last.scan(/([A-Z]+)/).first.first
        rangeaddress = firstcolumn + startrow + ":" + lastcolumn + endrow
        endrowint = endrow.to_i
        output = []
        if startrow <= endrowint
          result =
            get("/v1.0/me/drive/items/#{input['file']}/workbook/worksheets" \
              "('#{input['worksheet']}')/range(address='#{rangeaddress}')")
          data = result["values"]
          i = 0
          data.map do |item|
            record = { uniqueid: startrow + i }
            (0..(output_fields.length - 1)).each do |index|
              record[output_fields[index]] = item[index]
            end
            output << record
            i = i + 1
          end
          # set last record id
          newaddress = result["address"]
          if newaddress.present?
            newrange = newaddress.split("!").last
          end
          if newrange.present?
            last_record_id = newrange.split(":").last.scan(/\d+/).first
          end
        end

        # trigger output
        output.to_a

        {
          events: output,
          next_poll:
            output.size > 0 ? last_record_id.to_i + 1 : last_record_id.to_i,
          can_poll_more:  output.size != 0
        }
      end,

      dedup: lambda do |output|
        output["uniqueid"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["worksheet_output"]
      end
    }
  },

  pick_lists: {
    xlsxfiles: lambda do |_connection|
      get("/v1.0/me/drive/root/search(q='.xlsx')?select=name,id")["value"].
        pluck("name", "id")
    end,

    worksheets: lambda do |_, workbook_id:|
      get("/v1.0/me/drive/items/#{workbook_id}/workbook/worksheets")["value"].
        map { |sheet| [sheet["name"], sheet["name"]] }
    end
  }
}
