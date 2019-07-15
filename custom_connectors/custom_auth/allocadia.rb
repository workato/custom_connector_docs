{
  title: 'Allocadia',

  methods: {
    make_schema_builder_fields_sticky: lambda do |input|
      input.map do |field|
        if field[:properties].present?
          field[:properties] = call('make_schema_builder_fields_sticky',
                                    field[:properties])
        elsif field['properties'].present?
          field['properties'] = call('make_schema_builder_fields_sticky',
                                     field['properties'])
        end
        field[:sticky] = true
        field
      end
    end,

    # convert a cells object from a line item to the readable format
    format_item_cells: lambda do |input|
      columns = input[:columns]
      cells = input[:cells]

      new_cells = {}
    
      cells&.each do |id,cell|
        col = columns[id]
        
        unless col == nil || cell['value'] == nil || cell['value'] == ""
          new_cells[cell['columnName']] = call(:format_cell_value, { column: col, value: cell['value'] })
          # Need to use name rather than ID for YoY support, etc.
          #new_cells["f_#{id}"] = call(:format_cell_value, { column: col, value: cell['value'] })
        end
      end
         
      Hash[ new_cells.sort_by { |key, val| key } ]
    end,

    # convert cell values from the Allocadia API into a readable format
    format_cell_value: lambda do |input|
      col = input[:column]
      value = input[:value]
      
      case col['type']
      when 'DROPDOWN'
        value = col['choices'].select {|choice| choice['id'] == value}[0]['label']
            
      when 'MULTISELECT'
        msStr = ""
        value&.each do |id,pcnt|
          choiceName = col['choices'].select {|choice| choice['id'] == id}[0]['label']
          msStr = msStr + choiceName + "::" + pcnt + ","
        end
        value = msStr[0...-1] # trims the trailing , from the end
            
      when 'LINK'
        # if it's a link format value as either "label", "url", or "label (url)" depending on what's present
        label = value['label']
        url = value['url']
        if (label && url) 
          value = label + " (" + url + ")"
        elsif (label)
          value = label
        else
          value = url
        end
      end
      value
    end,

    # convert an input cell into the format the Allocadia API expects
    format_cell_to_allocadia: lambda do |input|
      col = input[:column]
      value = input[:value]
      
      value = (value == "") ? nil : value # treat empty string the same as nil
      
      if (value == nil && col['required'])
        error("[#{col['name']}] is a required field. Cannot clear value.")
      end
      
      unless value == nil
      case col['type']
      when 'DROPDOWN'
        value = col['choices'].select {|choice| choice['label'] == value}[0]['id']
            
      when 'MULTISELECT'
        msObj = {}
        value&.split(",").each do |msVal|
          choiceName = msVal.split("::")[0]
          pcnt = msVal.split("::")[1]
          choiceId = col['choices'].select {|choice| choice['label'] == choiceName}[0]['id']
          msObj[choiceId] = pcnt.to_f
        end
        value = msObj
            
      when 'LINK'
        url = nil
        label = value
        # if the string ends in parentheses and the start inside parentheses is http then assume it's in label (url) format
        if (value[-1] == ")")
          urlStart = value&.rindex("(")
          if (urlStart && value[urlStart+1..urlStart+4].casecmp("http") == 0)
            url = value[urlStart+1...-1]
            label = value[0...urlStart-1]
          end
        end
        
        # if it's not in label (url) format but appears to be a url then treat it as a url with no label
        if (!url && label[0...4].casecmp("http") == 0)
          url = label
          label = nil
        end
        value = {}
        value['label'] = label
        value['url'] = url
      end
      end
      value
    end,
    
    # recursively check if the item is part of the hierarchy by following the parentId up the hierarchy
    item_in_hierarchy: lambda do |input|
      root_id = input[:root_id]
      item = input[:item]
      all_items = input[:all_items]

      if item['parentId'] == nil
        item['id'] == root_id
      elsif item['parentId'] == root_id
        true
      elsif
        parent = all_items.select {|find_item| find_item['id'] == item['parentId']}[0]
        call(:item_in_hierarchy, { root_id: root_id, all_items: all_items, item: parent })
      end
    end,

    # retrieve all of the columns that are applicable to line items - "filter" input optional 
    get_line_item_columns_raw: lambda do |input|
      get("/v1/budgets/#{input[:budgetId]}/columns?$filter=location ne \"ACTUAL\" and location ne \"PO\" and location ne \"ROLLUP\" and location ne \"BUDGET\" and location ne \"OTHER\"#{input[:filter]}")
    end,
    
    # retrieve all of the columns that are applicable to line items, in a hash key'd by id
    get_line_item_columns_key_id: lambda do |input|
      cols = {}
      call(:get_line_item_columns_raw, { budgetId: input[:budgetId], filter: input[:filter] } ).each do |col|
        cols[col['id']] = col
      end
      cols
    end,
 
    # retrieve all of the columns that are applicable to line items, in a hash key'd by name
    get_line_item_columns_key_name: lambda do |input|
      cols = {}
      call(:get_line_item_columns_raw, { budgetId: input[:budgetId], filter: input[:filter] } ).each do |col|
        cols[col['name']] = col
      end
      cols
    end,
  },

  connection: {
    fields: [
      {
        name: 'username',
        hint: 'Allocadia app login username',
        optional: false
      },
      {
        name: 'password',
        hint: 'Allocadia app login password',
        optional: false,
        control_type: 'password'
      },
      {
        name: 'environment',
        default: 'api-staging',
        control_type: 'select',
        pick_list: [
          %w[North\ America api-na],
          %w[Europe api-eu],
          %w[Staging api-staging],
          %w[Europe\ Staging api-eu-staging],
          %w[Dev api-dev]
        ],
        optional: false
      }
    ],

    base_uri: lambda { |connection|
      domain = (connection['environment'].include? 'dev') ? 'allocadia.technology' : 'allocadia.com'
      "https://#{connection['environment']}.#{domain}"
    },

    authorization: {
      type: 'custom_auth',

      acquire: lambda do |connection|
        domain = (connection['environment'].include? 'dev') ? 'allocadia.technology' : 'allocadia.com'
        post("https://#{connection['environment']}.#{domain}/v1/token",
             username: connection['username'],
             password: connection['password']).compact
      end,

      refresh_on: [401],

      apply: lambda { |connection|
        headers('Authorization' => "token #{connection['token']}")
      }
    }
  },

  test: ->(_connection) { get('/v1/budgets') }, # TODO can we access users with a viewer? or maybe just do a post to get a token?

  object_definitions: {

    simple_choice: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id' }
        ]
      end
    },
    
    full_choice: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id' },
          { name: 'label' },
          { name: 'createdDate' },
          { name: 'updatedDate' },
          { name: 'externalAssociations',
            type: 'array',
            of: 'object',
            properties: 
             [
               { name: 'externalId' },
               { name: 'type' },
               { name: 'createdDate' },
               { name: 'updatedDate' } 
             ]
          }
        ]
      end
    },

    choice: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            control_type: 'text',
            label: 'Choice ID',
            type: 'string',
            name: 'choiceId',
            optional: false
          },
          {
            control_type: 'text',
            label: 'Label',
            type: 'string',
            name: 'label',
            optional: false
          },
          {
            control_type: 'text',
            label: 'External ID',
            type: 'string',
            name: 'externalId',
            optional: true
          }
        ]
      end
    },

    column: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            control_type: 'text',
            label: 'Column ID',
            type: 'string',
            name: 'columnId',
            optional: false
          },
          {
            control_type: 'text',
            label: 'Name',
            type: 'string',
            name: 'name',
            optional: false
          },
          {
            control_type: 'text',
            label: 'Type',
            type: 'string',
            name: 'type',
            optional: false
          },
          {
            control_type: 'select',
            pick_list: 'column_locations',
            label: 'Location',
            type: 'string',
            name: 'location'
          },
          {
            label: 'Choices',
            type: 'array',
            of: 'object',
            name: 'choices',
            properties:  #TODO - can we reuse the choice object definition here?
             [
               {
                 control_type: 'text',
                 label: 'Choice ID',
                 type: 'string',
                 name: 'choiceId'
               },
               {
                 control_type: 'text',
                 label: 'Label',
                 type: 'string',
                 name: 'label'
               },
               {
                 control_type: 'text',
                 label: 'External ID',
                 type: 'string',
                 name: 'externalId'
               }
             ]
          }
        ]
      end
    },

   budget: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            sticky: true,
            control_type: 'text',
            label: 'Folder/Budget ID',
            type: 'string',
            name: 'budgetId',
            optional: false
          },
          {
            control_type: 'text',
            label: 'Folder/Budget Name',
            type: 'string',
            name: 'name',
            optional: false
          },
          {
            control_type: 'text',
            label: 'Parent ID',
            type: 'string',
            name: 'parentId'
          },
          {
            control_type: 'text',
            label: 'Currency',
            type: 'string',
            name: 'currency'
          },
          {
            control_type: 'text',
            label: 'Notes',
            type: 'string',
            name: 'notes'
          },
          {
            control_type: 'checkbox',
            label: 'Folder',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Folder',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'folder'
            },
            type: 'boolean',
            name: 'folder'
          },
          {
            control_type: 'date_time',
            label: 'Created date',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time',
            name: 'createdDate'
          },
          {
            control_type: 'date_time',
            label: 'Updated date',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time',
            name: 'updatedDate'
          },
        ]
      end
    },

    line_item: {
      fields: lambda do |_connection, config_fields|
        budget_id = config_fields['budgetId'] ? config_fields['budgetId'] : config_fields['updateBudgetId']
        read_only_filter = config_fields['updateBudgetId'] ? " and readOnly eq false" : ""  # if this an update, only get non-readOnly columns
        
        cells_prop =
          if (budget_id) && (budget_id&.to_i) != 0
            line_item_columns = call(:get_line_item_columns_raw, { budgetId: budget_id, filter: read_only_filter })
            line_item_columns&.map do |field|
              case field['type'] 
              when 'CURRENCY', 'NUMBER' 
                {
                  name: "#{field['name']}",
                  #name: "f_#{field['id']}",
                  label: "#{field['name']}",
                  sticky: true,
                  control_type: 'number',
                  render_input: 'float_conversion',
                  parse_output: 'float_conversion',
                  type: 'number'
                }.compact
                else 
                {
                  name: "#{field['name']}",
                  #name: "f_#{field['id']}",
                  label: "#{field['name']}",
                  sticky: true,
                  control_type: 'text',
                  type: 'string'
                }.compact
              end
            end
          end || []
        [
          {
            name: 'itemId',
            label: 'Item ID',
            control_type: 'text',
            type: 'string'
          },
          {
            name: 'name',
            label: 'Name',
            control_type: 'text',
            type: 'string'
          },
          {
            name: 'type',
            label: 'Type',
            default: 'LINE_ITEM',
            control_type: 'select',
            pick_list: 'line_item_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'type',
              label: 'Type',
              hint: 'Allowed values are: LINE_ITEM, CATEGORY, PLACEHOLDER',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            control_type: 'text',
            label: 'Budget ID',
            type: 'string',
            name: 'budgetId'
          },
          {
            control_type: 'text',
            label: 'Parent ID',
            type: 'string',
            name: 'parentId'
          },
          {
            control_type: 'text',
            label: 'Path',
            type: 'string',
            name: 'path'
          },
          {
            name: 'createdDate',
            label: 'Created date',
            control_type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time'
          },
          {
            name: 'updatedDate',
            label: 'Updated date',
            control_type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time'
          },
          {
            name: 'cells',
            sticky: true,
            type: cells_prop.size > 0 ? 'object' : 'string',
            properties: cells_prop
          },

        ]
      end
    },
    
    filter: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'filter',
            label: 'Filter using custom criteria',
            sticky: true,
            hint: 'Data can be filtered based upon property and ' \
              'sub-property values. Strings must be double quoted and ' \
              'all expressions must evaluate to a boolean value. <br>' \
              'Supported operators: <b>eq</b> (Equal), <b>ne</b> (Not ' \
              'equal), <b>gt</b> (Greater than), <b>ge</b> (Greater ' \
              'than or equal), <b>lt</b> (Less than), <b>le</b> ' \
              '(Less than or equal), <b>and</b>, and  <b>or</b>.<br/>' \
              'For example: <b>updatedDate ge "2017-03-10T00:00:00.000Z" and ' \
              'updatedDate lt "2017-03-11T00:00:00.000Z"</b>'
          }
        ]
      end
    },

  },

  actions: {

    get_choices_by_column_id: {
      description: "Get <span class='provider'>choices by column ID</span> " \
        "in <span class='provider'>Allocadia</span>",

     execute: lambda do |_connection, input|
       
       raw_choices = get("/v1/budgets/#{input['budgetId']}/columns/#{input['columnId']}/choices")
       { 
         choices: raw_choices&.map do |field|
           {
             choiceId: "#{field['id']}",
             label: "#{field['label']}",
             externalId: "#{field['externalAssociations'].size > 0 ? field['externalAssociations'][0]['externalId'] : nil}"
           }
         end
       }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['budget'].only('budgetId').concat(object_definitions['column'].only('columnId')).required('budgetId','columnId')
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'choices',
          type: 'array',
          of: 'object',
          properties: object_definitions['choice']
        }]
      end,

    },

    get_choices_by_column_name: {
      description: "Get <span class='provider'>choices by column name</span> " \
        "in <span class='provider'>Allocadia</span>",

      execute: lambda do |_connection, input|
       
        allColumnsObj = []
        
        locationFilter = input['location'] ? "location eq \"#{input['location']}\" and " : ""
        
        column_names = input['columnNames']&.map { |item| item['columnName'] } || []
        column_names.each do |columnName|
          columnObj = get("/v1/budgets/#{input['budgetId']}/columns?$filter=#{locationFilter}name eq \"#{columnName}\"").first || error("Column #{columnName} not found")
        
          raw_choices = get("/v1/budgets/#{input['budgetId']}/columns/#{columnObj['id']}/choices")
          choices = raw_choices&.map do |choice|
            {
              choiceId: "#{choice['id']}",
              label: "#{choice['label']}",
              externalId: "#{choice['externalAssociations'].size > 0 ? choice['externalAssociations'][0]['externalId'] : nil}"
            }
            end
     
          columnObj['choices'] = choices
          allColumnsObj << columnObj
        end 
        
        {
          columns: allColumnsObj
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['budget'].only('budgetId').
          concat([
            {
              name: 'columnNames',
              type: :array,
              of: :object,
              properties: [{ name: 'columnName' }]
            }
          ]).concat(object_definitions['column'].only('location'))
      end,

      output_fields: lambda do |object_definitions|
        [{
           name: 'columns',
           type: 'array',
           of: 'object',
           properties: object_definitions['column']
        }]
      end,

    },
  
    add_choice: {
      description: "Add <span class='provider'>column choice</span> " \
        "in <span class='provider'>Allocadia</span>",

      execute: lambda do |_connection, input|

        param = '{ "label":"' + input['label'] + '", "externalAssociations": [{ "externalId": "' + input['externalId'] + '", "type": "CAMPAIGN" } ] }'

        post("/v1/budgets/#{input['budgetId']}/columns/#{input['columnId']}/choices", parse_json(param))
          .after_response do |code, body, headers|
          # if /3\d{2} | 4\d{2} | 5\d{2}/.match?(code)
          if code.to_s.match?(/[3-5]\d{2}/)
            error("#{code}: #{body}")
          else
            { choiceId: headers['location'].split('/').last }
          end
        end

      end,

      input_fields: lambda do |object_definitions|
        object_definitions['budget'].only('budgetId').concat(object_definitions['column'].only('columnId')).concat(object_definitions['choice'].ignored('choiceId'))
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'choiceId',
        }]
      end,

    },

    get_item_by_id: {
      description: "Get <span class='provider'>item by ID</span> " \
        "in <span class='provider'>Allocadia</span>",

     execute: lambda do |_connection, input|
       
        item = get("/v1/lineitems/#{input['itemId']}")
        columns = call(:get_line_item_columns_raw, { budgetId: item['budgetId'] })

        if input['primaryExternalColumnName']
          primaryColId = columns.select {|col| col['name'] == input['primaryExternalColumnName'] }[0]['id']
          choices = get("/v1/budgets/#{item['budgetId']}/columns/#{primaryColId}/choices")
          if (item['cells'][primaryColId])
            choiceId = item['cells'][primaryColId]['value']
            choice = choices.select {|ch| ch['id'] == choiceId }[0]
            externalId = choice['externalAssociations'].size > 0 ? choice['externalAssociations'][0]['externalId'] : nil
            item['primaryExternalId'] = externalId
          end
        end
        
        cols = {}
        columns.each do |col|
          cols[col['id']] = col
        end
        item['cells'] = call(:format_item_cells, { columns: cols, cells: item['cells'] })
       
        item.except('_links')
      end,

     config_fields: [{
        name: 'budgetId',
        label: 'Budget',
        optional: false,
        control_type: 'select',
        type: 'text',
        pick_list: 'budgets',
        toggle_hint: 'Select from list',
        toggle_field: {
          name: 'budgetId',
          label: 'Budget ID',
          toggle_hint: 'Use custom value',
          hint: 'Enter N/A if budget ID not known',
          control_type: 'text',
          type: 'string'
        }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['line_item'].only('itemId').required('itemId').concat([{ name: 'primaryExternalColumnName' }])

      end,

      output_fields: lambda do |object_definitions|
        object_definitions['line_item'].concat([{ name: 'primaryExternalId' }])
      end,

    },
    
    get_budget_by_id: {
      description: "Get <span class='provider'>budget by ID</span> " \
        "in <span class='provider'>Allocadia</span>",

      execute: lambda do |_connection, input|
        budget = get("/v1/budgets/#{input['budgetId']}")
        budget['budgetId'] = budget.delete('id')
        budget.except('_links')
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['budget'].only('budgetId')

      end,

      output_fields: lambda do |object_definitions|
        object_definitions['budget']
      end,

    },

    get_all_budgets: {
      description: "Get <span class='provider'>all budgets by folder ID</span> " \
        "in <span class='provider'>Allocadia</span>",

      execute: lambda do |_connection, input|
        budget_filter = input['filter'] ? "?$filter=#{input['filter']}" : ""    
        all_budgets = get("/v1/budgets#{budget_filter}")
        budgets_in_hierarchy = input['folderId'].blank? ? all_budgets : all_budgets.select {|item| call(:item_in_hierarchy, { root_id: input['folderId'], all_items: all_budgets, item: item }) }
              
        budgets_in_hierarchy.each do |budget|
          budget['budgetId'] = budget.delete 'id'
          budget.delete '_links'
        end

        { budgets: budgets_in_hierarchy }
      end,

      input_fields: lambda do |object_definitions|
        [{
          name: 'folderId',
          label: 'Folder ID',
        }].concat(object_definitions['filter'])
      end,


      output_fields: lambda do |object_definitions|
        [{
          name: 'budgets',
          type: 'array',
          of: 'object',
          properties: object_definitions['budget']
        }]
      end,

    },
    
    get_line_items_by_budget: {
      description: "Get <span class='provider'>all line items in budget</span> " \
        "in <span class='provider'>Allocadia</span>",

      execute: lambda do |_connection, input|
        filter = input['filter'] ? "?$filter=#{input['filter']}" : ""
        columns = call(:get_line_item_columns_key_id, { budgetId: input['budgetId'] })
        budget_items = get("/v1/budgets/#{input['budgetId']}/lineitems#{filter}")
        
        budget_items&.delete_if { |item| item['parentId'] == nil } # filter out grand total row
        
        budget_items.each do |item|
          item['itemId'] = item.delete 'id'
          item.delete '_links'
          item['cells'] = call(:format_item_cells, { columns: columns, cells: item['cells'] })
        end

        { items: budget_items }
      end,

      # reduces output to the first 100 items plus the last one?
      summarize_output: 'items',

      config_fields: [{
        name: 'budgetId',
        label: 'Budget',
        optional: false,
        control_type: 'select',
        type: 'text',
        pick_list: 'budgets',
        toggle_hint: 'Select from list',
        toggle_field: {
          name: 'budgetId',
          label: 'Budget ID',
          toggle_hint: 'Use custom value',
          control_type: 'text',
          type: 'string'
        }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['filter']
      end,
      
      output_fields: lambda do |object_definitions|
        [{
          name: 'items',
          type: 'array',
          of: 'object',
          properties: object_definitions['line_item']
        }]
      end,
    },

    search_line_items: {
      description: "Search <span class='provider'>line items in folder</span> " \
        "in <span class='provider'>Allocadia</span>",

      execute: lambda do |_connection, input|
        item_filter = input['filter'] ? "?$filter=#{input['filter']}" : ""
        all_budgets = get("/v1/budgets")
        budgets_in_hierarchy = all_budgets.select {|budget| call(:item_in_hierarchy, { root_id: input['folderId'], all_items: all_budgets, item: budget }) }
        budgets_in_hierarchy = budgets_in_hierarchy.select {|budget| budget['folder'] == false }  # include budgets, not folders
        columns = call(:get_line_item_columns_key_id, { budgetId: input['folderId'] })

        all_items = []
        
        budgets_in_hierarchy.each do |budget|
          budget_items = get("/v1/budgets/#{budget['id']}/lineitems#{item_filter}")
              
          budget_items.each do |item|
            unless item['parentId'] == nil # filter out grand total row
              item['itemId'] = item.delete 'id'
              item.delete '_links'
              item['cells'] = call(:format_item_cells, { columns: columns, cells: item['cells'] })
              all_items << item
            end
          end
        end

        { items: all_items }
      end,

      config_fields: [{
        name: 'folderId',
        label: 'Folder',
        optional: false,
        control_type: 'select',
        type: 'text',
        pick_list: 'folders',
        toggle_hint: 'Select from folder list',
        toggle_field: {
          name: 'folderId',
          label: 'Folder ID',
          toggle_hint: 'Use custom value',
          control_type: 'text',
          type: 'string'
        }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['filter']
      end,
      
      output_fields: lambda do |object_definitions|
        [{
          name: 'items',
          type: 'array',
          of: 'object',
          properties: object_definitions['line_item']
        }]
      end,
    },

    # TODO - this is incomplete - waiting on a "wait" function to be available
    search_line_items_large_hierarchy: {
      description: "Search <span class='provider'>line items in folder for large hierarchy</span> " \
        "in <span class='provider'>Allocadia</span>",

      execute: lambda do |_connection, input|
        itemfilter = input['filter'] ? "?$filter=#{input['filter']}" : ""
        #columns = call(:get_line_item_columns_key_id, { budgetId: input['budgetId'] })

        budget_items = get("/v1/lineitems/#{itemfilter}").after_response do |code, body, headers|
         location = headers['location']
          job_id = location&.split('/')[-1]
         job = get("/v1/jobs/lineitems/#{job_id}")
         error(job)
        end
        
        all_items = []
        
        budget_items.each do |item|
            unless item['parentId'] == nil # filter out grand total row
              item['itemId'] = item.delete 'id'
              item.delete '_links'
 #             item['cells'] = call(:format_item_cells, { columns: columns, cells: item['cells'] })
              all_items << item
            end
        end

        { items: all_items }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['filter']
      end,
      
      output_fields: lambda do |object_definitions|
        [{
          name: 'items',
          type: 'array',
          of: 'object',
          properties: object_definitions['line_item']
        }]
      end,
    },

    update_line_item: {
      description: "Update <span class='provider'>line item" \
        "</span> in <span class='provider'>Allocadia</span>",

      execute: lambda do |_connection, input|
        columns = call(:get_line_item_columns_key_name, { budgetId: input.delete('updateBudgetId') })
        
        # handle case where it could be a cells object coming in as a string
        if (input['cells']&.is_a?(String))
          input['cells'] = parse_json(input['cells'])
        end
        
        input['cells'] = input['cells']&.
          compact&.
          map { |key, value| { columns[key]['id'] => { 'value' => call(:format_cell_to_allocadia, { value: value, column: columns[key] } ) } } }&.
          inject(:merge)
        
        put("/v1/lineitems" \
          "/#{input.delete('itemId')}", input.compact)
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end || {}
      end,

      config_fields: [{
        name: 'updateBudgetId',
        label: 'Budget',
        optional: false,
        control_type: 'select',
        type: 'text',
        pick_list: 'budgets',
        toggle_hint: 'Select from list',
        toggle_field: {
          name: 'updateBudgetId',
          label: 'Budget ID',
          toggle_hint: 'Use custom value',
          control_type: 'text',
          type: 'string'
        }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['line_item'].only('itemId','name','cells').required('itemId')
      end
    },    

    add_line_item: {
      description: "Add <span class='provider'>line item" \
        "</span> in <span class='provider'>Allocadia</span>",

      execute: lambda do |_connection, input|
        columns = call(:get_line_item_columns_key_name, { budgetId: input['updateBudgetId'] })
        
        # handle case where it could be a cells object coming in as a string
        if (input['cells']&.is_a?(String))
          input['cells'] = parse_json(input['cells'])
        end
        
        input['cells'] = input['cells']&.
          compact&.
          map { |key, value| { columns[key]['id'] => { 'value' => call(:format_cell_to_allocadia, { value: value, column: columns[key] } ) } } }&.
          inject(:merge)
 
        post("/v1/budgets/#{input.delete('updateBudgetId')}/lineitems", input.compact)
         .after_response do |code, body, headers|
          if code.to_s.match?(/[3-5]\d{2}/)
            error("#{code}: #{body}")
          else
            { itemId: headers['location'].split('/').last }
          end
        end
      end,

      config_fields: [{
        name: 'updateBudgetId',
        label: 'Budget',
        optional: false,
        control_type: 'select',
        type: 'text',
        pick_list: 'budgets',
        toggle_hint: 'Select from list',
        toggle_field: {
          name: 'updateBudgetId',
          label: 'Budget ID',
          toggle_hint: 'Use custom value',
          control_type: 'text',
          type: 'string'
        }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['line_item'].only('name','type','parentId','cells').required('name','type')
      end,
      
      output_fields: lambda do |object_definitions|
        object_definitions['line_item'].only('itemId')
      end,
    },    
    
  },

  pick_lists: {
    foldersbudgets: ->(_connection) { get('/v1/budgets')&.pluck('name', 'id') || [] },
    budgets: ->(_connection) { get('/v1/budgets?$filter=folder eq false')&.pluck('name', 'id') || [] },
    folders: ->(_connection) { get('/v1/budgets?$filter=folder eq true')&.pluck('name', 'id') || [] },

    line_item_types: lambda do |_connection|
      [%w[Line\ item LINE_ITEM],
       %w[Category CATEGORY],
       %w[Placeholder PLACEHOLDER]]
    end,
    
    column_locations: lambda do |_connection|
      [
        ["ACTUAL","ACTUAL"],
        ["BUDGET","BUDGET"],
        ["DETAILS","DETAILS"],
        ["GRID","GRID"],
        ["OTHER","OTHER"],
        ["PO","PO"],
        ["ROLLUP","ROLLUP"]
      ]
    end
  }
}
