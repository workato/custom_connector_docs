{
  title: "RightSignature",

  connection: {
    fields: [{
      name: "api_key",
      label: "Secure token",
      hint: "You may find the secure token <a href=" \
        "'https://rightsignature.com/oauth_clients' target='_blank'>here</a>",
      control_type: "password",
      optional: false
    }],

    authorization: {
      type: "api_key",

      apply: ->(connection) { headers(api_token: connection["api_key"]) }
    },

    base_uri: ->(_connection) { "https://rightsignature.com" }
  },

  object_definitions: {
    document: {
      fields: lambda {
        [
          { name: "guid", label: "Document ID" },
          { name: "created_at", type: "timestamp" },
          { name: "completed_at", type: "timestamp" },
          { name: "last_activity_at", type: "timestamp" },
          { name: "expires_on", type: "timestamp" },
          { name: "is_trashed", control_type: "checkbox", type: "boolean" },
          { name: "size", type: "integer" },
          { name: "content_type" },
          { name: "original_filename" },
          { name: "signed_pdf_checksum" },
          { name: "subject" },
          { name: "message" },
          { name: "processing_state" },
          { name: "merge_state" },
          { name: "state" },
          { name: "callback_location" },
          { name: "tags" },
          {
            name: "recipients",
            type: "array",
            of: "object",
            properties: [
              { name: "name" },
              { name: "email", control_type: "email" },
              { name: "must_sign", control_type: "checkbox", type: "boolean" },
              { name: "document_role_id" },
              { name: "role_id" },
              { name: "state" },
              { name: "is_sender", control_type: "checkbox", type: "boolean" },
              { name: "viewed_at", type: "timestamp" },
              { name: "completed_at", type: "timestamp" }
            ]
          },
          {
            name: "audit_trails",
            type: "array",
            of: "object",
            properties: [
              { name: "timestamp", type: "timestamp" },
              { name: "keyword" },
              { name: "message" }
            ]
          },
          {
            name: "pages",
            type: "array",
            of: "object",
            properties: [
              { name: "page_number" },
              { name: "original_template_guid" },
              { name: "original_template_filename" }
            ]
          },
          { name: "original_url" },
          { name: "pdf_url" },
          { name: "thumbnail_url" },
          { name: "large_url" },
          { name: "signed_pdf_url" }
        ]
      }
    }
  },

  test: ->(_connection) { get("/api/documents.json") },

  actions: {
    get_document_details: {
      subtitle: "Get document details by ID",
      description: "Get <span class='provider'>document details</span> " \
        "by ID in <span class='provider'>RightSignature</span>",

      input_fields: lambda { |object_definitions|
        object_definitions["document"].only("guid").required("guid")
      },

      execute: lambda { |_connection, input|
        get("/api/documents/#{input['guid']}.json")["document"] || {}
      },

      output_fields: ->(object_definitions) { object_definitions["document"] },

      sample_output: lambda { |_connection|
        get("/api/documents.json").dig("page", "documents", 0) || {}
      }
    }
  }
}
