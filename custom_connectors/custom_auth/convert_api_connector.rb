{
  title: "ConvertAPI",

  connection: {
    fields: [{
      name: "secret",
      hint: "Secret can be found in ConvertAPI " \
        "<a href='https://www.convertapi.com/a'>Control Panel</a>.",
      optional: false
    }],

    base_uri: ->(_connection) { "https://v2.convertapi.com" },

    authorization: {
      type: "custom_auth",

      acquire: lambda do |connection|
        {
          token: post("/token/create").
            params("Secret" => connection["secret"],
                   "RequestCount" => 100,
                   "Lifetime" => 1000).
            dig("Tokens", 0, "Id")
        }
      end,

      refresh_on: [401, /"Code"\s*\:\s*4011/],

      apply: ->(connection) { params("Token" => connection["token"]) }
    }
  },

  test: ->(connection) { get("/user", "Secret" => connection["secret"]) },

  object_definitions: {
    file_input: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: "File",
            label: "File URL",
            control_type: "url"
          },
          { name: "StoreFile", control_type: "checkbox", type: "boolean" },
          {
            name: "FileName",
            hint: "Converted output file name without extension. " \
              "The extension will be added automatically."
          },
          {
            name: "Timeout",
            hint: "Default: 300. Valid value ranges from 10 to 1200",
            type: "integer"
          },
          {
            name: "PdfResolution",
            label: "PDF Resolution",
            hint: "Default: 300. Valid value ranges from 10 to 2400",
            type: "integer"
          }
        ]
      end
    },

    file_output: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: "FileName" },
          { name: "FileSize" },
          { name: "FileData" },
          { name: "Url", label: "URL" }
        ]
      end
    }
  },

  actions: {
    split_pdf_file: {
      title: "Split PDF file",
      description: "Split <span class='provider'>PDF file</span> in " \
        "<span class='provider'>ConvertAPI</span>",
      help: "Splits each page into a PDF file.",

      execute: lambda do |_connection, input|
        post("/pdf/to/split", input).request_format_www_form_urlencoded
      end,

      input_fields: lambda do |object_definitions|
        object_definitions["file_input"].required("File")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "Files",
          type: "array",
          of: "object",
          properties: object_definitions["file_output"]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          "Files" => [{
            "FileName" => "Workato.pdf",
            "FileSize" => 1234,
            "Url" => "https://v2.convertapi.com/d/ABCD/Workato.pdf"
          }]
        }
      end
    },

    merge_pdf_file: {
      title: "Merge PDF file",
      description: "Merge <span class='provider'>PDF files</span> in " \
        "<span class='provider'>ConvertAPI</span>",

      execute: lambda do |_connection, input|
        files_list = []
        index = 0
        input_files = input["Files"]&.pluck("File")
        input_files_size = input_files.size
        while index < input_files_size
          files_list.concat([{ index => input_files[index] }])
          index = index + 1
        end
        input["Files"] = files_list.inject(:merge)

        post("/pdf/to/merge", input).request_format_www_form_urlencoded
      end,

      input_fields: lambda do |object_definitions|
        [{
          name: "Files",
          optional: false,
          type: "array",
          of: "object",
          properties: object_definitions["file_input"].
            only("File").
            required("File")
        }] + object_definitions["file_input"].ignored("File")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: "Files",
          type: "array",
          of: "object",
          properties: object_definitions["file_output"]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          "Files" => [{
            "FileName" => "Workato.pdf",
            "FileSize" => 1234,
            "Url" => "https://v2.convertapi.com/d/ABCD/Workato.pdf"
          }]
        }
      end
    }
  }
}
