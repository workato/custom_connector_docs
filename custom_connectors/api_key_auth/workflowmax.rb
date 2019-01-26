{
  title: 'WorkflowMax',

  connection: {
    fields: [
      { name: 'api_key', control_type: 'password',
        label: 'API key', optional: false },
      { name: 'account_key',
        label: 'Account key', optional: false }
    ],

    authorization: {
      type: 'api_key',

      credentials: lambda { |connection|
        params(apikey: connection['api_key'],
               accountkey: connection['account_key'])
      }
    },
    base_uri: lambda { |_connection|
      'https://api.workflowmax.com'
    }

  },

  test: lambda { |_connection|
    get('/staff.api/list').response_format_xml['status']
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
          { name: 'ID', type: 'integer',
            control_type: 'number',
            label: 'Invoice ID' },
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
            { name: 'ID', type: 'integer', control_type: 'number' },
            { name: 'Name' }
          ] },
          { name: 'Contact', type: 'object', properties: [
            { name: 'ID', type: 'integer', control_type: 'number' },
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
          { name: 'ID', type: 'integer', control_type: 'number' },
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
          { name: 'ID', type: 'integer', control_type: 'number' },
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
          { name: 'ID', type: 'integer', control_type: 'number' },
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
      description: "Search <span class='provider'>clients</span> in " \
      "<span class='provider'> WorkflowMax</span>",
      input_fields: lambda do |_object_definitions|
        [
          { name: 'query',
            label: 'Client name',
            optional: false,
            hint: 'Search based on client name' }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('/client.api/search', input)
                   .format_xml('response').dig('Response', 0) || [{}]
        {
          clients: call('parse_xml_to_hash',
                        'xml' => response,
                        'array_fields' => %w[Client Contact Note])
            .dig('Clients', 'Client') || []
        }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'clients', type: 'array', of: 'object',
            properties: object_definitions['client'] }
        ]
      end,
      sample_output: lambda do |_object_definitions|
        response = get('/client.api/list?detailed=true')
                   .format_xml('response').dig('Response', 0) || [{}]
        {
          clients: call('parse_xml_to_hash',
                        'xml' => response,
                        'array_fields' => %w[Client Contact Note])
            .dig('Clients', 'Client', 0) || []
        }
      end
    },

    get_client_details_by_id: {
      description: "Get <span class='provider'>client</span> details by ID " \
      "in <span class='provider'> WorkflowMax</span>",
      input_fields: lambda do |_|
        [
          { name: 'id', label: 'Client ID',
            optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('/client.api/get/' + input['id'])
                   .format_xml('response').dig('Response', 0) || {}

        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => %w[Client Contact Note])
          .dig('Client', 0) || {}
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['client']
      end,
      sample_output: lambda do |_connection|
        response = get('/client.api/list?detailed=true')
                   .format_xml('response').dig('Response', 0) || {}

        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => %w[Client Contact Note'])
          .dig('Clients', 'Client', 0) || {}
      end
    },

    get_all_suppliers: {
      description: "Get all <span class='provider'>suppliers</span> in " \
      "<span class='provider'> WorkflowMax</span>",
      execute: lambda do |_connection, _input|
        response = get('/supplier.api/list?detailed=true')
                   .format_xml('response').dig('Response', 0) || [{}]
        {
          suppliers: call('parse_xml_to_hash',
                          'xml' => response,
                          'array_fields' => %w[Supplier Contact Note])
            .dig('Suppliers', 'Supplier') || []
        }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'suppliers', type: 'array', of: 'object',
            properties: object_definitions['supplier'] }
        ]
      end,
      sample_output: lambda do |_connection|
        response = get('/supplier.api/list?detailed=true')
                   .format_xml('response').dig('Response', 0) || [{}]
        {
          suppliers: call('parse_xml_to_hash',
                          'xml' => response,
                          'array_fields' => %w[Supplier Contact Note])
            .dig('Suppliers', 'Supplier', 0) || []
        }
      end
    },

    get_supplier_details_by_id: {
      description: "Get <span class='provider'>supplier </span> by ID in " \
      "<span class='provider'> WorkflowMax</span>",
      input_fields: lambda do |_|
        [
          { name: 'id', label: 'Supplier ID',
            optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('/supplier.api/get/' + input['id'])
                   .format_xml('response').dig('Response', 0) || {}

        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => %w[Supplier Contact Note])
          .dig('Supplier', 0) || {}
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['supplier']
      end,
      sample_output: lambda do |_connection|
        response = get('/supplier.api/list?detailed=true')
                   .format_xml('response').dig('Response', 0) || {}

        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => %w[Supplier Contact Note])
          .dig('Suppliers', 'Supplier', 0) || {}
      end
    },

    get_supplier_contact_by_id: {
      description: "Get supplier <span class='provider'>contact </span> " \
      "by ID in <span class='provider'> WorkflowMax</span>",
      input_fields: lambda do |_|
        [
          { name: 'id', label: 'Contact ID',
            optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('/supplier.api/contact/' + input['id'])
                   .format_xml('response').dig('Response', 0) || {}

        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => []).dig('Contact') || {}
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['contact']
      end,
      sample_output: lambda do |_connections|
        response = get('/supplier.api/list?detailed=true')
                   .format_xml('response').dig('Response', 0) || {}

        call('parse_xml_to_hash',
             'xml' => response, 'array_fields' => [])
          .dig('Suppliers', 'Supplier', 'Contacts', 'Contact') || {}
      end
    },

    search_quotes: {
      description: "Search <span class='provider'>issued quotes </span> " \
      "for given date range in<span class='provider'> WorkflowMax</span>",
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
        response = get('/quote.api/list')
                   .params(from: input['from'].strftime('%Y%m%d'),
                           to: input['to'].strftime('%Y%m%d'),
                           detailed: 'true').format_xml('response')
                   .dig('Response', 0) || [{}]
        {
          quotes: call('parse_xml_to_hash',
                       'xml' => response,
                       'array_fields' => %w[Quote Task Option Cost])
            .dig('Quotes', 'Quote') || []
        }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'quotes', type: 'array', of: 'object',
            properties: object_definitions['quote'] }
        ]
      end,
      sample_output: lambda do |_connections|
        response = get('/quote.api/current?detailed=true')
                   .format_xml('response').dig('Response', 0) || [{}]
        {
          quotes: call('parse_xml_to_hash',
                       'xml' => response,
                       'array_fields' => %w[Quote Task Option Cost])
            .dig('Quotes', 'Quote', 0) || []
        }
      end
    },

    get_quote_by_number: {
      description: "Get <span class='provider'>quote details</span> by quote" \
      " number in <span class='provider'> WorkflowMax</span>",
      input_fields: lambda do |_object_definitions|
        [
          { name: 'quote_number',
            optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('/quote.api/get/' + input['quote_number'])
                   .format_xml('response').dig('Response', 0) || {}
        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => %w[Task Cost Option]).dig('Quote') || {}
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['quote']
      end,
      sample_output: lambda do |_connection|
        response = get('/quote.api/current?detailed=true')
                   .format_xml('response').dig('Response', 0) || {}
        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => %w[Quote Task Cost Option])
          .dig('Quotes', 'Quote', 0) || {}
      end
    },

    get_current_quotes: {
      description: "Get <span class='provider'>current quotes </span> in " \
      "<span class='provider'> WorkflowMax</span>",
      help: 'Return a list of current quotes(issued) in WorkflowMax',
      execute: lambda do |_connection, _input|
        response = get('/quote.api/current?detailed=true')
                   .format_xml('response').dig('Response', 0) || [{}]
        {
          quotes: call('parse_xml_to_hash',
                       'xml' => response,
                       'array_fields' => %w[Quote Task Cost Option])
            .dig('Quotes', 'Quote') || [{}]
        }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'quotes', type: 'array', of: 'object',
            properties: object_definitions['quote'] }
        ]
      end,
      sample_output: lambda do |_connection|
        response = get('/quote.api/current?detailed=true')
                   .format_xml('response').dig('Response', 0) || [{}]

        {
          quotes: call('parse_xml_to_hash',
                       'xml' => response,
                       'array_fields' => %w[Quote Task Option Cost])
            .dig('Quotes', 'Quote', 0) || []
        }
      end
    },

    search_invoices: {
      description: "Search <span class='provider'>invoices</span> for given " \
      "date range in <span class='provider'> WorkflowMax</span>",
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
        response = get('/invoice.api/list')
                   .params(from: input['from'].strftime('%Y%m%d'),
                           to: input['to'].strftime('%Y%m%d'),
                           detailed: 'true').format_xml('response')
                   .dig('Response', 0) || [{}]

        {
          invoices: call('parse_xml_to_hash',
                         'xml' => response,
                         'array_fields' => %w[Invoice Job Task Cost])
            .dig('Invoices', 'Invoice') || []
        }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'invoices', type: 'array', of: 'object',
            properties: object_definitions['invoice'] }
        ]
      end,
      sample_output: lambda do |_connection|
        response = get('/invoice.api/current?detailed=true')
                   .format_xml('response').dig('Response', 0) || [{}]
        {
          invoices: call('parse_xml_to_hash',
                         'xml' => response,
                         'array_fields' => %w[Invoice Task Cost Job])
            .dig('Invoices', 'Invoice', 0) || [{}]
        }
      end
    },

    get_invoice_by_number: {
      description: "Get <span class='provider'>invoice details</span> by " \
      "invoice number in <span class='provider'> WorkflowMax</span>",
      input_fields: lambda do |_object_definitions|
        [
          { name: 'invoice_number',
            optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('/invoice.api/get/' + input['invoice_number'])
                   .format_xml('response').dig('Response', 0) || {}
        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => %w[Job Task Cost]).dig('Invoice') || {}
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['invoice']
      end,
      sample_output: lambda do |_connections|
        response = get('/invoice.api/current?detailed=true')
                   .format_xml('response').dig('Response', 0) || {}
        call('parse_xml_to_hash',
             'xml' => response,
             'array_fields' => %w[Invoice Task Cost Job])
          .dig('Invoices', 'Invoice', 0) || {}
      end
    },

    get_job_invoices: {
      description: "Get job <span class='provider'>invoices</span> in " \
      "<span class='provider'> WorkflowMax</span>",
      input_fields: lambda do |_object_definitions|
        [
          { name: 'job_number',
            optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('/invoice.api/job/' + input['job_number'])
                   .format_xml('response').dig('Response', 0) || [{}]
        {
          invoices: call('parse_xml_to_hash',
                         'xml' => response,
                         'array_fields' => %w[Invoice Job Task Cost])
            .dig('Invoices', 'Invoice') || []
        }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'invoices', type: 'array', of: 'object',
            properties: object_definitions['invoice'] }
        ]
      end,
      sample_output: lambda do
        response = get('/invoice.api/current?detailed=true')
                   .format_xml('response').dig('Response', 0) || [{}]

        {
          invoices: call('parse_xml_to_hash',
                         'xml' => response,
                         'array_fields' => %w[Invoice Job Task Cost])
            .dig('Invoices', 'Invoice', 0) || []
        }
      end
    },

    get_current_invoices: {
      description: "Get <span class='provider'>current invoices </span> in " \
      "<span class='provider'> WorkflowMax</span>",
      help: 'Get current invoices (Approved) in WorkflowMax',
      execute: lambda do |_connection, _input|
        response = get('/invoice.api/current?detailed=true')
                   .format_xml('response').dig('Response', 0) || [{}]
        {
          invoices: call('parse_xml_to_hash',
                         'xml' => response,
                         'array_fields' => %w[Invoice Task Cost Job])
            .dig('Invoices', 'Invoice') || [{}]
        }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'invoices', type: 'array',
            of: 'object', properties: object_definitions['invoice'] }
        ]
      end,
      sample_output: lambda do |_connection|
        response = get('/invoice.api/current?detailed=true')
                   .format_xml('response').dig('Response', 0) || [{}]
        {
          invoices: call('parse_xml_to_hash',
                         'xml' => response,
                         'array_fields' => %w[Invoice Task Cost Job])
            .dig('Invoices', 'Invoice', 0) || [{}]
        }
      end
    },

    get_invoice_payments: {
      description: "Get <span class='provider'>payments of invoice </span>" \
      " in <span class='provider'> WorkflowMax</span>",
      input_fields: lambda do |_object_definitions|
        [
          { name: 'invoice_number', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        response = get('/invoice.api/payments/' + input['invoice_number'])
                   .format_xml('response').dig('Response', 0) || [{}]
        {
          payments: call('parse_xml_to_hash',
                         'xml' => response,
                         'array_fields' => ['Payment'])
            .dig('Payments', 'Payment') || [{}]
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
