{
  title: 'WorkflowMax',

  connection: {
    fields: [
      { name: 'client_id', optional: false,
        hint: 'To create client id, you need to register an application in ' \
              "<a href='https://developer.xero.com/myapps' target='_blank'> " \
              'developer portal</a>. Create an app with ' \
              "'OAuth 2.0 grant type' and use client ID." },
      { name: 'client_secret', control_type: 'password', optional: false,
        hint: 'To create client secret, you need to register an application in ' \
              "<a href='https://developer.xero.com/myapps' target='_blank'> " \
              'developer portal</a>. Create an app with ' \
              "'OAuth 2.0 grant type' and use client secret." }
    ],

    authorization: {
      type: 'oauth2',

      authorization_url: lambda do |connection|
        params = {
          response_type: 'code',
          client_id: connection['client_id'],
          redirect_uri: 'https://www.workato.com/oauth/callback',
          scope: 'workflowmax offline_access'
        }.to_param

        'https://login.xero.com/identity/connect/authorize?' + params
      end,

      acquire: lambda do |connection, auth_code|
        header = "#{connection['client_id']}:#{connection['client_secret']}"
        response = post('https://identity.xero.com/connect/token').
                   payload(
                     grant_type: 'authorization_code',
                     redirect_uri: 'https://www.workato.com/oauth/callback',
                     code: auth_code
                   ).request_format_www_form_urlencoded.
                   headers(authorization: "Basic #{header.encode_base64}")
        tenent_info = get('https://api.xero.com/connections').
                      headers(authorization: "Bearer #{response['access_token']}").
                      select { |item| item['tenantType'] == 'WORKFLOWMAX' }
        [
          {
            access_token: response['access_token'],
            refresh_token: response['refresh_token']
          },
          nil,
          { tenent_id: tenent_info.dig(0, 'tenantId') }
        ]
      end,

      refresh_on: [401, 403],

      refresh: lambda do |connection, refresh_token|
        header = "#{connection['client_id']}:#{connection['client_secret']}"
        response = post('https://identity.xero.com/connect/token').
                   payload(
                     grant_type: 'refresh_token',
                     refresh_token: refresh_token,
                     redirect_uri: 'https://www.workato.com/oauth/callback'
                   ).request_format_www_form_urlencoded.
                   headers(authorization: "Basic #{header.encode_base64}")
        tenent_info = get('https://api.xero.com/connections').
                      headers(authorization: "Bearer #{response['access_token']}").
                      select { |item| item['tenantType'] == 'WORKFLOWMAX' }
        [
          {
            access_token: response['access_token'],
            refresh_token: response['refresh_token']
          },
          { tenent_id: tenent_info.dig(0, 'tenantId') }
        ]
      end,

      apply: lambda do |connection, access_token|
        headers('authorization': "Bearer #{access_token}",
                'xero-tenant-id': connection['tenent_id'])
      end
    },
    base_uri: -> { 'https://api.xero.com/workflowmax/3.0/' }
  },

  test: lambda { |_connection|
    get('staff.api/list').response_format_xml['status']
  },

  methods: {

    parse_xml_to_hash: lambda do |xml_obj|
      xml_obj['xml']&.
        reject { |key, _value| key[/^@/] }&.
        inject({}) do |hash, (key, value)|
        if value.is_a?(Array)
          hash.merge(
            if (array_fields = xml_obj['array_fields'])&.include?(key)
              {
                key => value.map do |inner_hash|
                  call('parse_xml_to_hash',
                       'xml' => inner_hash,
                       'array_fields' => array_fields)
                end
              }
            else
              {
                key => call('parse_xml_to_hash',
                            'xml' => value[0],
                            'array_fields' => array_fields)
              }
            end
          )
        else
          value
        end
      end&.presence
    end

  },

  object_definitions: {

    invoice: {
      fields: lambda do |_connection|
        [
          { name: 'ID',
            label: 'Invoice ID' },
          { name: 'UUID', label: 'Invoice UUID' },
          { name: 'Type' },
          { name: 'Status',
            control_type: 'select',
            pick_list: 'invoice_status',
            label: 'Invoice status',
            toggle_hint: 'Select from list',
            toggle_field:
            { name: 'Status',
              type: 'string',
              control_type: 'text',
              label: 'Invoice status',
              toggle_hint: 'User custom value',
              hint: 'Status can be one of <code>Paid, ' \
              'Draft, Cancelled</code>' } },
          { name: 'JobText' },
          { name: 'Date', type: 'date_time', control_type: 'date_time' },
          { name: 'DueDate', type: 'date_time', control_type: 'date_time' },
          { name: 'Amount', type: 'number', control_type: 'number' },
          { name: 'AmountTax', type: 'number', control_type: 'number' },
          { name: 'AmountIncludingTax', type: 'number',
            control_type: 'number' },
          { name: 'AmountPaid', type: 'number', control_type: 'number' },
          { name: 'AmountOutstanding', type: 'number', control_type: 'number' },
          { name: 'Client', type: 'object', properties: [
            { name: 'UUID', type: 'integer', control_type: 'number' },
            { name: 'Name' }
          ] },
          { name: 'Contact', type: 'object', properties: [
            { name: 'UUID', type: 'integer', control_type: 'number' },
            { name: 'Name' }
          ] },
          { name: 'Jobs', type: 'object', properties: [
            { name: 'Job', type: 'array', of: 'object', properties: [
              { name: 'ID', type: 'integer', control_type: 'number' },
              { name: 'Name' },
              { name: 'Description' },
              { name: 'ClientOrderNumber' },
              { name: 'Tasks', type: 'object', properties: [
                { name: 'Task', type: 'array', of: 'object', properties: [
                  { name: 'UUID' },
                  { name: 'Name' },
                  { name: 'Description' },
                  { name: 'Minutes', type: 'integer',
                    control_type: 'number' },
                  { name: 'BillableRate', type: 'integer',
                    control_type: 'number' },
                  { name: 'Billable', type: 'boolean',
                    control_type: 'checkbox',
                    toggle_hint: 'Select from list',
                    toggle_field:
                          { name: 'Billable',
                            type: 'string',
                            control_type: 'text',
                            label: 'Billable',
                            toggle_hint: 'User custom value' } },
                  { name: 'Amount', type: 'number', control_type: 'number' },
                  { name: 'AmountTax', type: 'number',
                    control_type: 'number' },
                  { name: 'AmountIncludingTax', type: 'number',
                    control_type: 'number' }
                ] }
              ] },
              { name: 'Costs', type: 'object', properties: [
                { name: 'Cost', type: 'array', of: 'object', properties: [
                  { name: 'Description' },
                  { name: 'Code' },
                  { name: 'Billable', type: 'boolean',
                    control_type: 'checkbox',
                    toggle_hint: 'Select from list',
                    toggle_field:
                        { name: 'Billable', type: 'string',
                          control_type: 'text', label: 'Billable',
                          toggle_hint: 'User custom value' } },
                  { name: 'Quantity', type: 'number',
                    control_type: 'number' },
                  { name: 'UnitCost', type: 'number',
                    control_type: 'number' },
                  { name: 'UnitPrice', type: 'number',
                    control_type: 'number' },
                  { name: 'Amount', type: 'number', control_type: 'number' },
                  { name: 'AmountTax', type: 'number',
                    control_type: 'number' },
                  { name: 'AmountIncludingTax', type: 'number',
                    control_type: 'number' }
                ] }
              ] }
            ] }
          ] }
        ]
      end
    },

    client: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'UUID' },
          { name: 'Name' },
          { name: 'Email' },
          { name: 'DateOfBirth', type: 'date', control_type: 'date' },
          { name: 'Address' },
          { name: 'City' },
          { name: 'Region' },
          { name: 'PostCode' },
          { name: 'Country' },
          { name: 'PostalAddress' },
          { name: 'PostalCity' },
          { name: 'PostalRegion' },
          { name: 'PostalPostCode' },
          { name: 'PostalCountry' },
          { name: 'Phone' },
          { name: 'Fax' },
          { name: 'Website' },
          { name: 'ReferralSource' },
          { name: 'ExportCode' },
          { name: 'IsProspect' },
          { name: 'AccountManager', type: :object, properties: [
            { name: 'ID', type: 'integer', control_type: 'integer' },
            { name: 'Name' }
          ] },
          { name: 'Type', type: :object, properties: [
            { name: 'Name' },
            { name: 'CostMarkup', type: 'number', control_type: 'number' },
            { name: 'PaymentTerm' },
            { name: 'PaymentDay', type: 'integer', control_type: 'number' }
          ] },
          { name: 'Contacts', type: 'object', properties: [
            { name: 'Contact', type: :array, of: :object, properties: [
              { name: 'ID' },
              { name: 'IsPrimary', type: 'boolean', control_type: 'checkbox' },
              { name: 'Name' },
              { name: 'Salutation' },
              { name: 'Addressee' },
              { name: 'Mobile' },
              { name: 'Email' },
              { name: 'Phone' },
              { name: 'Position' }
            ] }
          ] },
          { name: 'Notes', type: 'object', properties: [
            { name: 'Note', type: 'array', of: 'object', properties: [
              { name: 'Title' },
              { name: 'Text' },
              { name: 'Folder' },
              { name: 'Date', type: 'date_time', control_type: 'date_time' },
              { name: 'CreatedBy' }
            ] }
          ] }

        ]
      end
    },

    quote: {
      fields: lambda do |_connection, _config|
        [
          { name: 'ID' },
          { name: 'Type' },
          { name: 'State' },
          { name: 'Name' },
          { name: 'Description' },
          { name: 'Budget', type: 'number', control_type: 'number' },
          { name: 'OptionExplanation', type: 'string',
            control_type: 'text-area' },
          { name: 'Date', type: 'date_time', control_type: 'date_time' },
          { name: 'ValidDate', type: 'date_time', control_type: 'date_time',
            label: 'Valid to' },
          { name: 'EstimatedCost', type: 'number', control_type: 'number' },
          { name: 'EstimatedCostTax', type: 'number',
            control_type: 'number' },
          { name: 'EstimatedCostIncludingTax', type: 'number',
            control_type: 'number' },
          { name: 'Amount', type: 'number', control_type: 'number' },
          { name: 'AmountTax', type: 'number', control_type: 'number' },
          { name: 'AmountIncludingTax', type: 'number',
            control_type: 'number' },
          { name: 'Client', type: 'object', properties: [
            { name: 'ID', type: 'integer', control_type: 'number' },
            { name: 'Name' }
          ] },
          { name: 'Contact', type: 'object', properties: [
            { name: 'ID', type: 'integer', control_type: 'number' },
            { name: 'Name' }
          ] },
          { name: 'Tasks', type: 'object', properties: [
            { name: 'Task', type: 'array', of: 'object', properties: [
              { name: 'Name' },
              { name: 'Description' },
              { name: 'EstimatedMinutes', type: 'integer',
                control_type: 'number' },
              { name: 'BillableRate', type: 'number',
                control_type: 'number' },
              { name: 'Billable' },
              { name: 'Amount', type: 'number', control_type: 'number' },
              { name: 'AmountTax', type: 'number', control_type: 'number' },
              { name: 'AmountIncludingTax', type: 'number',
                control_type: 'number' }
            ] }
          ] },
          { name: 'Options', type: 'object', properties: [
            { name: 'Option', type: 'array', of: 'object', properties: [
              { name: 'Note' },
              { name: 'Code' },
              { name: 'Quantity', type: 'number', control_type: 'number' },
              { name: 'UnitCost', type: 'number', control_type: 'number' },
              { name: 'UnitPrice', type: 'number', control_type: 'number' },
              { name: 'Amount', type: 'number', control_type: 'number' },
              { name: 'AmountTax', type: 'number', control_type: 'number' },
              { name: 'AmountIncludingTax', type: 'number',
                control_type: 'number' },
              { name: 'Description' }
            ] }
          ] },
          { name: 'Costs', type: 'object', properties: [
            { name: 'Cost', type: 'array', of: 'object', properties: [
              { name: 'Note' },
              { name: 'Code' },
              { name: 'Billable' },
              { name: 'Quantity', type: 'number', control_type: 'number' },
              { name: 'UnitCost', type: 'number', control_type: 'number' },
              { name: 'UnitPrice', type: 'number', control_type: 'number' },
              { name: 'Amount', type: 'number', control_type: 'number' },
              { name: 'AmountTax', type: 'number', control_type: 'number' },
              { name: 'AmountIncludingTax', type: 'number',
                control_type: 'number' },
              { name: 'Description' }
            ] }
          ] }
        ]
      end
    },

    supplier: {
      fields: lambda do |_variable|
        [
          { name: 'UUID' },
          { name: 'Name' },
          { name: 'Address', type: 'string', control_type: 'text-area' },
          { name: 'City' },
          { name: 'Region' },
          { name: 'PostCode' },
          { name: 'PostalAddress', type: 'string', control_type: 'text-area' },
          { name: 'PostalCity' },
          { name: 'PostalRegion' },
          { name: 'PostalPostCode' },
          { name: 'PostalCountry' },
          { name: 'Phone', type: 'string', control_type: 'phone' },
          { name: 'Fax' },
          { name: 'Website' },
          { name: 'Contacts', type: 'object', properties: [
            { name: 'Contact', type: 'array', of: 'object', properties: [
              { name: 'ID' },
              { name: 'Name' },
              { name: 'Mobile' },
              { name: 'Email' },
              { name: 'Phone' },
              { name: 'Position' }
            ] }
          ] },
          { name: 'Notes', type: 'object', properties: [
            { name: 'Note', type: 'array', of: 'object', properties: [
              { name: 'Title' },
              { name: 'Text' },
              { name: 'Folder' },
              { name: 'Date', type: 'date_time', control_type: 'date_time' },
              { name: 'CreatedBy' }
            ] }
          ] }
        ]
      end
    },

    contact: {
      fields: lambda do |_|
        [
          { name: 'UUID' },
          { name: 'Name' },
          { name: 'Mobile' },
          { name: 'Email' },
          { name: 'Phone' },
          { name: 'Position' }
        ]
      end
    },

    payment: {
      fields: lambda do |_|
        [
          { name: 'Date', type: 'date_time', control_type: 'date_time' },
          { name: 'Amount', type: 'number', control_type: 'number' },
          { name: 'Reference' }
        ]
      end
    }

  },

  actions: {
    search_clients: {
      title: 'Search clients',
      subtitle: 'Search clients in Workflowmax by query',
      description: "Search <span class='provider'>clients</span> in " \
      "<span class='provider'>WorkflowMax</span>",
      input_fields: lambda do |_object_definitions|
        [
          { name: 'query',
            label: 'Client name',
            optional: false,
            hint: 'Search based on client name' }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('client.api/search', input).
                   format_xml('response').dig('Response', 0) || [{}]
        {
          clients: call('parse_xml_to_hash',
                        'xml' => response,
                        'array_fields' => %w[Client Contact Note]).
            dig('Clients', 'Client') || []
        }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'clients', type: 'array', of: 'object',
            properties: object_definitions['client'] }
        ]
      end,
      sample_output: lambda do |_object_definitions|
        response = get('client.api/list?detailed=true').
                   format_xml('response').dig('Response', 0) || [{}]
        {
          clients: call('parse_xml_to_hash',
                        'xml' => response,
                        'array_fields' => %w[Client Contact Note]).
            dig('Clients', 'Client', 0) || []
        }
      end
    },

    get_client_details_by_uuid: {
      title: 'Get client details by UUID',
      subtitle: 'Get client details in WorkflowMax by UUID',
      description: "Get <span class='provider'>client</span> details by UUID " \
      "in <span class='provider'>WorkflowMax</span>",
      input_fields: lambda do |_|
        [
          { name: 'uuid', label: 'Client UUID',
            optional: false,
            hint: 'e.g. c8f691b8-c26c-475d-9da4-fd3837d2bbaf' }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('client.api/get/' + input['uuid']).
                   format_xml('response').dig('Response', 0) || {}

        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => %w[Client Contact Note]).
          dig('Client', 0) || {}
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['client']
      end,
      sample_output: lambda do |_connection|
        response = get('client.api/list?detailed=true').
                   format_xml('response').dig('Response', 0) || {}

        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => %w[Client Contact Note']).
          dig('Clients', 'Client', 0) || {}
      end
    },

    get_all_suppliers: {
      title: 'Get all suppliers',
      subtitle: 'Get all suppliers details in WorkflowMax',
      description: "Get all <span class='provider'>suppliers</span> in " \
      "<span class='provider'>WorkflowMax</span>",
      execute: lambda do |_connection, _input|
        response = get('supplier.api/list?detailed=true').
                   format_xml('response').dig('Response', 0) || [{}]
        {
          suppliers: call('parse_xml_to_hash',
                          'xml' => response,
                          'array_fields' => %w[Supplier Contact Note]).
            dig('Suppliers', 'Supplier') || []
        }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'suppliers', type: 'array', of: 'object',
            properties: object_definitions['supplier'] }
        ]
      end,
      sample_output: lambda do |_connection|
        response = get('supplier.api/list?detailed=true').
                   format_xml('response').dig('Response', 0) || [{}]
        {
          suppliers: call('parse_xml_to_hash',
                          'xml' => response,
                          'array_fields' => %w[Supplier Contact Note]).
            dig('Suppliers', 'Supplier', 0) || []
        }
      end
    },

    get_supplier_details_by_uuid: {
      title: 'Get supplier details by UUID',
      subtitle: 'Get supplier details in WorkflowMax by UUID',
      description: "Get <span class='provider'>supplier</span> by UUID in " \
      "<span class='provider'>WorkflowMax</span>",
      input_fields: lambda do |_|
        [
          { name: 'uuid', label: 'Supplier UUID',
            optional: false,
            hint: 'e.g. c8f691b8-c26c-475d-9da4-fd3837d2bbaf' }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('supplier.api/get/' + input['uuid']).
                   format_xml('response').dig('Response', 0) || {}

        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => %w[Supplier Contact Note]).
          dig('Supplier', 0) || {}
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['supplier']
      end,
      sample_output: lambda do |_connection|
        response = get('supplier.api/list?detailed=true').
                   format_xml('response').dig('Response', 0) || {}

        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => %w[Supplier Contact Note]).
          dig('Suppliers', 'Supplier', 0) || {}
      end
    },

    get_supplier_contact_by_uuid: {
      title: 'Get supplier contact by UUID',
      subtitle: 'Get supplier contact details in WorkflowMax by UUID',
      description: "Get supplier <span class='provider'>contact</span> " \
      "by UUID in <span class='provider'>WorkflowMax</span>",
      input_fields: lambda do |_|
        [
          { name: 'uuid', label: 'Contact UUID',
            optional: false,
            hint: 'e.g. c8f691b8-c26c-475d-9da4-fd3837d2bbaf' }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('supplier.api/contact/' + input['uuid']).
                   format_xml('response').dig('Response', 0) || {}

        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => []).dig('Contact') || {}
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['contact']
      end,
      sample_output: lambda do |_connections|
        response = get('supplier.api/list?detailed=true').
                   format_xml('response').dig('Response', 0) || {}

        call('parse_xml_to_hash',
             'xml' => response, 'array_fields' => []).
          dig('Suppliers', 'Supplier', 'Contacts', 'Contact') || {}
      end
    },

    search_quotes: {
      title: 'Search quotes',
      subtitle: 'Search quotes in WorkflowMax',
      description: "Search <span class='provider'>issued quotes</span> " \
      "for given date range in<span class='provider'>WorkflowMax</span>",
      input_fields: lambda do |_object_definitions|
        [
          { name: 'from',
            type: 'date',
            control_type: 'date',
            optional: false,
            hint: 'Return quotes created on or after this date.' },
          { name: 'to',
            type: 'date',
            control_type: 'date',
            optional: false,
            hint: 'Return quote created on or before this date.' }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('quote.api/list').
                   params(from: input['from'].strftime('%Y%m%d'),
                          to: input['to'].strftime('%Y%m%d'),
                          detailed: 'true').format_xml('response').
                   dig('Response', 0) || [{}]
        {
          quotes: call('parse_xml_to_hash',
                       'xml' => response,
                       'array_fields' => %w[Quote Task Option Cost]).
            dig('Quotes', 'Quote') || []
        }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'quotes', type: 'array', of: 'object',
            properties: object_definitions['quote'] }
        ]
      end,
      sample_output: lambda do |_connections|
        response = get('quote.api/current?detailed=true').
                   format_xml('response').dig('Response', 0) || [{}]
        {
          quotes: call('parse_xml_to_hash',
                       'xml' => response,
                       'array_fields' => %w[Quote Task Option Cost]).
            dig('Quotes', 'Quote', 0) || []
        }
      end
    },

    get_quote_by_number: {
      title: 'Get quote by number',
      subtitle: 'Get quote details in WorkflowMax by quote number',
      description: "Get <span class='provider'>quote details</span> by quote" \
      " number in <span class='provider'>WorkflowMax</span>",
      input_fields: lambda do |_object_definitions|
        [
          { name: 'quote_number',
            optional: false,
            hint: 'e.g. Q000123' }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('quote.api/get/' + input['quote_number']).
                   format_xml('response').dig('Response', 0) || {}
        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => %w[Task Cost Option]).dig('Quote') || {}
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['quote']
      end,
      sample_output: lambda do |_connection|
        response = get('quote.api/current?detailed=true').
                   format_xml('response').dig('Response', 0) || {}
        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => %w[Quote Task Cost Option]).
          dig('Quotes', 'Quote', 0) || {}
      end
    },

    get_current_quotes: {
      title: 'Get current quotes',
      subtitle: 'Get current quote details in WorkflowMax',
      description: "Get <span class='provider'>current quotes</span> in " \
      "<span class='provider'>WorkflowMax</span>",
      help: 'Return a list of current quotes(issued) in WorkflowMax',
      execute: lambda do |_connection, _input|
        response = get('quote.api/current?detailed=true').
                   format_xml('response').dig('Response', 0) || [{}]
        {
          quotes: call('parse_xml_to_hash',
                       'xml' => response,
                       'array_fields' => %w[Quote Task Cost Option]).
            dig('Quotes', 'Quote') || [{}]
        }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'quotes', type: 'array', of: 'object',
            properties: object_definitions['quote'] }
        ]
      end,
      sample_output: lambda do |_connection|
        response = get('quote.api/current?detailed=true').
                   format_xml('response').dig('Response', 0) || [{}]

        {
          quotes: call('parse_xml_to_hash',
                       'xml' => response,
                       'array_fields' => %w[Quote Task Option Cost]).
            dig('Quotes', 'Quote', 0) || []
        }
      end
    },

    search_invoices: {
      title: 'Search invoices',
      subtitle: 'Search invoices in WorkflowMax',
      description: "Search <span class='provider'>invoices</span> for given " \
      "date range in <span class='provider'>WorkflowMax</span>",
      input_fields: lambda do |_object_definitions|
        [
          { name: 'from',
            type: 'date',
            control_type: 'date',
            optional: false,
            hint: 'Return invoices created on or after this date.' },
          { name: 'to',
            type: 'date',
            control_type: 'date',
            optional: false,
            hint: 'Return invoices created on or before this date.' }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('invoice.api/list').
                   params(from: input['from'].strftime('%Y%m%d'),
                          to: input['to'].strftime('%Y%m%d'),
                          detailed: 'true').format_xml('response').
                   dig('Response', 0) || [{}]

        {
          invoices: call('parse_xml_to_hash',
                         'xml' => response,
                         'array_fields' => %w[Invoice Job Task Cost]).
            dig('Invoices', 'Invoice') || []
        }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'invoices', type: 'array', of: 'object',
            properties: object_definitions['invoice'] }
        ]
      end,
      sample_output: lambda do |_connection|
        response = get('invoice.api/current?detailed=true').
                   format_xml('response').dig('Response', 0) || [{}]
        {
          invoices: call('parse_xml_to_hash',
                         'xml' => response,
                         'array_fields' => %w[Invoice Task Cost Job]).
            dig('Invoices', 'Invoice', 0) || [{}]
        }
      end
    },

    get_invoice_by_number: {
      title: 'Get invoice by number',
      subtitle: 'Get invoice details in WorkflowMax by invoice number',
      description: "Get <span class='provider'>invoice details</span> by " \
      "invoice number in <span class='provider'>WorkflowMax</span>",
      input_fields: lambda do |_object_definitions|
        [
          { name: 'invoice_number',
            optional: false,
            hint: 'e.g. I000123' }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('invoice.api/get/' + input['invoice_number']).
                   format_xml('response').dig('Response', 0) || {}
        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => %w[Job Task Cost]).dig('Invoice') || {}
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['invoice']
      end,
      sample_output: lambda do |_connections|
        response = get('invoice.api/current?detailed=true').
                   format_xml('response').dig('Response', 0) || {}
        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => %w[Invoice Task Cost Job]).
          dig('Invoices', 'Invoice', 0) || {}
      end
    },

    get_job_invoices: {
      title: 'Get job invoices',
      subtitle: 'Get invoices details in WorkflowMax for specific job',
      description: "Get list of <span class='provider'>invoices</span> " \
      "<span class='provider'>for a specific job in WorkflowMax</span>",
      input_fields: lambda do |_object_definitions|
        [
          { name: 'job_number',
            optional: false,
            hint: 'e.g. J000123' }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('invoice.api/job/' + input['job_number']).
                   format_xml('response').dig('Response', 0) || [{}]
        {
          invoices: call('parse_xml_to_hash',
                         'xml' => response,
                         'array_fields' => %w[Invoice Job Task Cost]).
            dig('Invoices', 'Invoice') || []
        }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'invoices', type: 'array', of: 'object',
            properties: object_definitions['invoice'] }
        ]
      end,
      sample_output: lambda do
        response = get('invoice.api/current?detailed=true').
                   format_xml('response').dig('Response', 0) || [{}]

        {
          invoices: call('parse_xml_to_hash',
                         'xml' => response,
                         'array_fields' => %w[Invoice Job Task Cost]).
            dig('Invoices', 'Invoice', 0) || []
        }
      end
    },

    get_current_invoices: {
      title: 'Get current invoices',
      subtitle: 'Get current invoice in WorkflowMax',
      description: "Get <span class='provider'>current invoices</span> in " \
      "<span class='provider'>WorkflowMax</span>",
      help: 'Get current invoices (Approved) in WorkflowMax',
      execute: lambda do |_connection, _input|
        response = get('invoice.api/current?detailed=true').
                   format_xml('response').dig('Response', 0) || [{}]
        {
          invoices: call('parse_xml_to_hash',
                         'xml' => response,
                         'array_fields' => %w[Invoice Task Cost Job]).
            dig('Invoices', 'Invoice') || [{}]
        }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'invoices', type: 'array',
            of: 'object', properties: object_definitions['invoice'] }
        ]
      end,
      sample_output: lambda do |_connection|
        response = get('invoice.api/current?detailed=true').
                   format_xml('response').dig('Response', 0) || [{}]
        {
          invoices: call('parse_xml_to_hash',
                         'xml' => response,
                         'array_fields' => %w[Invoice Task Cost Job]).
            dig('Invoices', 'Invoice', 0) || [{}]
        }
      end
    },

    get_invoice_payments: {
      title: 'Get inovice payments',
      subtitle: 'Get inovice payments in WorkflowMax',
      description: "Get <span class='provider'>payments of invoice</span>" \
      " in <span class='provider'>WorkflowMax</span>",
      input_fields: lambda do |_object_definitions|
        [
          { name: 'invoice_number', optional: false,
            hint: 'e.g. I000123' }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('invoice.api/payments/' + input['invoice_number']).
                   format_xml('response').dig('Response', 0) || [{}]
        {
          payments: call('parse_xml_to_hash',
                         'xml' => response,
                         'array_fields' => ['Payment']).
            dig('Payments', 'Payment') || [{}]
        }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'payments', type: 'array', of: 'object',
            properties: object_definitions['payment'] }
        ]
      end
    }
  },

  pick_lists: {
    invoice_status: lambda do |_connection|
      [
        %w[Approved Approved],
        %w[Paid Paid],
        %w[Draft Draft],
        %w[Cancelled Cancelled]
      ]
    end
  }

}
