{
  title: 'Easy Projects',

  connection: {
    fields: [
      { name: 'base_url', optional: false, label: 'Sub domain',
        control_type: 'subdomain', url: '.go.easyrojects.net',
        hint: 'e.g. <b>workato</b> in your easy project URL ' \
        'https://workato.go.easyprojects.net' },
      { name: 'user_name', optional: false },
      { name: 'password', control_type: 'password', optional: false }
    ],
    authorization: {
      type: 'basic',
      credentials: lambda do |connection|
        user(connection['user_name'])
        password(connection['password'])
      end
    },
    base_uri: lambda do |connection|
      "https://#{connection['base_url']}.go.easyprojects.net"
    end
  },
  test: lambda do |_connection|
    get('/rest/v1/projects/count')
  end,
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
    end
  },
  object_definitions: {
    user: {
      fields: lambda do
        [
          { name: 'Enabled', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'Enabled',
                  label: 'Enabled',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'CanLogin', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanLogin',
                  label: 'Can login',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'ShowCompletedTasks', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'ShowCompletedTasks',
                  label: 'Show completed tasks',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'ShowCompletedProjects', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'ShowCompletedProjects',
                  label: 'Show completed projects',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'ShowCompletedPortfolios', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'ShowCompletedPortfolios',
                  label: 'Show completed portfolios',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'ShowAvatars', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'ShowAvatars',
                  label: 'Show avatars',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'IsAvatarEmpty', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'IsAvatarEmpty',
                  label: 'Is avatar empty',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          {
            name: 'EntityBaseID',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'UserID',
            type: 'number',
            control_type: 'number'
          },
          { name: 'Login' },
          {
            name: 'Name',
            label: 'Full Name'
          },
          {
            name: 'EMail',
            label: 'Email'
          },
          {
            name: 'HourlyRate',
            type: 'number',
            control_type: 'number',
            parse_output: 'float_conversion'
          },
          {
            name: 'HourlyRateInternal',
            type: 'number',
            control_type: 'number',
            parse_output: 'float_conversion'
          },
          { name: 'AvatarHash' },
          { name: 'DefaultPage' },
          {
            name: 'LastActivityDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          {
            name: 'LoginEnabledDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          {
            name: 'PasswordModifyDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          {
            name: 'InvalidPasswordAttemptsCount',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'LastModificationDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          { name: 'LastLockoutDate' },
          {
            name: 'PresetID',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'TimeZoneOffset',
            type: 'number',
            control_type: 'number',
            parse_output: 'integer_conversion'
          },
          {
            name: 'CreationDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          { name: 'IsDistributeHours', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'IsDistributeHours',
                label: 'Is distribute hours',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'IsExpandAssigneeWindow', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'IsExpandAssigneeWindow',
                label: 'Is expand assignee window',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'CustomerID' },
          { name: 'Customer' },
          {
            name: 'RoleID',
            label: 'Role',
            control_type: 'select',
            pick_list: 'role_id_status_list',
            toggle_hint: 'Use from Options list',
            toggle_field: {
              name: 'RoleID',
              label: 'Role ID',
              type: 'number',
              control_type: 'number',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 1 - Administrator,' \
              ' 2 - Project Manager, 3 - Collaborator, 4 - Participant ' \
              'and 5 - Supervisor'
            }
          },
          { name: 'Role' }
        ]
      end
    },
    project: {
      fields: lambda do
        [
          {
            name: 'EntityBaseID',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'ProjectID',
            type: 'number',
            control_type: 'number'
          },
          { name: 'Name' },
          { name: 'Description' },
          {
            name: 'Progress',
            type: 'number',
            control_type: 'number',
            hint: 'Current development of the project in percentage value'
          },
          {
            name: 'CreationDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          {
            name: 'StartDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          {
            name: 'EndDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          {
            name: 'ActCompletionDate',
            label: 'Act completion date'
          },
          {
            name: 'EstimatedHours',
            type: 'number',
            control_type: 'number',
            hint: 'Estimated amount of time to complete a task or a project.'
          },
          {
            name: 'BillingType',
            label: 'Billing type',
            control_type: 'select',
            pick_list: 'billing_type_list',
            toggle_hint: 'Use from Options list',
            toggle_field: {
              name: 'BillingType',
              label: 'Billing type ID',
              type: 'number',
              control_type: 'number',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 1 - Resource hourly rate,
              2 - Customer hourly rate, 3 - Activity rate, 4 - Project' \
              ' hourly rate, 5 - Project flat fee,
              6 - Not billable'
            }
          },
          {
            name: 'BillingAmount',
            type: 'number',
            control_type: 'number',
            parse_output: 'float_conversion'
          },
          {
            name: 'Budget',
            type: 'number',
            control_type: 'number',
            parse_output: 'float_conversion'
          },
          {
            name: 'LastModificationDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          {
            name: 'Duration',
            control_type: 'number',
            type: 'number',
            label: 'Duration (day/s)'
          },
          {
            name: 'DurationHours',
            type: 'number',
            control_type: 'number',
            label: 'Duration (hour/s)'
          },
          {
            name: 'StartDateLag',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'EndDateLag',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'ProjectStatusID',
            label: 'Project status',
            control_type: 'select',
            pick_list: 'project_status_list',
            toggle_hint: 'Use from Options list',
            toggle_field: {
              name: 'ProjectStatusID',
              label: 'Project status ID',
              type: 'number',
              control_type: 'number',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 1 - Open, 2 - In Progress, 3 - Hold,
              4 - Closed, 5 - Draft and 6 - Template'
            }
          },
          {
            name: 'PriorityID',
            label: 'Priority',
            control_type: 'select',
            pick_list: 'project_priority_list',
            toggle_hint: 'Use from Options list',
            toggle_field: {
              name: 'PriorityID',
              label: 'Priority ID',
              type: 'number',
              control_type: 'number',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 1 - HOT (Now), 2 - Urgent, 3 - High,
              4 - Medium, and 5 - Low'
            }
          },
          { name: 'CustomerID' },
          { name: 'Customer' },
          {
            name: 'CreatorID',
            type: 'number',
            control_type: 'number'
          },
          { name: 'Creator' },
          { name: 'PortfolioID' },
          { name: 'Portfolio' },
          {
            name: 'CurrencyID',
            label: 'Currency',
            control_type: 'select',
            pick_list: 'currency_list',
            toggle_hint: 'Use from Options list',
            toggle_field: {
              name: 'CurrencyID',
              label: 'Currency ID',
              type: 'number',
              control_type: 'number',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: (1- 65) - 1 - Dollar, 2 - Euro, ' \
              '13 - Indian Rupee '
            }
          },
          { name: 'Billed', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'Billed',
                  label: 'Billed',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'HasDescription', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'HasDescription',
                  label: 'Has description',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'CanCreateTasks', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanCreateTasks',
                  label: 'Can create tasks',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'CanViewMembersAndAssignees', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanViewMembersAndAssignees',
                  label: 'Can view members and assignees',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'CanAccessAllTimeEntries', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanAccessAllTimeEntries',
                  label: 'Can access all time entries',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'CanCreateTimeEntries', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanCreateTimeEntries',
                  label: 'Can create time entries',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'CanCreateTimeEntriesForOther', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanCreateTimeEntriesForOther',
                  label: 'Can create time entries for other',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'CanDeleteAllTasks', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanDeleteAllTasks',
                  label: 'Can delete all tasks',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'CanDeleteAllTimeEntries', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanDeleteAllTimeEntries',
                  label: 'Can delete all time entries',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'CanEditAssignedTasks', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanEditAssignedTasks',
                  label: 'Can edit assigned tasks',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'CanEditAllTasks', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanEditAllTasks',
                  label: 'Can edit all tasks',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'CanManageAssigneesTasks', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanManageAssigneesTasks',
                  label: 'Can manage assignees tasks',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'CanManageProjectMembers', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanManageProjectMembers',
                  label: 'Can manage project members',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'CanEdit', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanEdit',
                  label: 'Can edit',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'CanDelete', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanDelete',
                  label: 'Can delete',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } }
        ]
      end
    },
    project_activities: {
      fields: lambda do
        [
          {
            name: 'EntityBaseID',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'TaskID',
            type: 'number',
            control_type: 'number'
          },
          { name: 'Name' },
          { name: 'Description' },
          { name: 'ParentID' },
          {
            name: 'Progress',
            type: 'number',
            control_type: 'number',
            hint: 'Current development of the project in percentage value'
          },
          { name: 'ActualCompletionDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion' },
          {
            name: 'CreationDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          { name: 'StartDate' },
          { name: 'EndDate' },
          { name: 'Duration' },
          { name: 'DurationHours' },
          {
            name: 'StartDateLag',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'EndDateLag',
            type: 'number'
          },
          {
            name: 'EstimatedHours',
            type: 'number',
            control_type: 'number',
            hint: 'Estimated amount of time to complete a task or a project.'
          },
          {
            name: 'HoursLeft',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'BillingType',
            type: 'number',
            control_type: 'number'
          },
          { name: 'BillingAmount',
            type: 'number',
            control_type: 'number',
            parse_output: 'float_conversion' },
          {
            name: 'Cost',
            type: 'number',
            control_type: 'number',
            parse_output: 'float_conversion'
          },
          { name: 'IsMilestone', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'IsMilestone',
                label: 'Is milestone',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'HasChild', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'HasChild',
                label: 'Has child',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'Budget',
            type: 'number',
            control_type: 'number',
            parse_output: 'float_conversion' },
          {
            name: 'LastModificationDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          {
            name: 'WBSNumber',
            type: 'number',
            control_type: 'number'
          },
          { name: 'Approved', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'Approved',
              label: 'Approved',
              type: :boolean,
              control_type: 'text',
              optional: true,
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true or false'
            } },
          { name: 'Billed', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'Billed',
                label: 'Billed',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'HasDescription', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'HasDescription',
                label: 'Has description',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'StartDateForGantt' },
          { name: 'EndDateForGantt' },
          { name: 'LagForGantt' },
          {
            name: 'ProjectID',
            type: 'number',
            control_type: 'number'
          },
          { name: 'Project' },
          { name: 'CategoryID' },
          { name: 'Category' },
          {
            name: 'TaskTypeID',
            label: 'Task type',
            control_type: 'select',
            pick_list: 'task_type_list',
            toggle_hint: 'Use from Options list',
            toggle_field: {
              name: 'TaskTypeID',
              label: 'Task type ID',
              type: 'number',
              control_type: 'number',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 1 - Task, 2 - Issue, 3 - Request'
            }
          },
          { name: 'TaskType' },
          {
            name: 'TaskStatusID',
            label: 'Task status',
            control_type: 'select',
            pick_list: 'task_status_list',
            toggle_hint: 'Use from Options list',
            toggle_field: {
              name: 'TaskStatusID',
              label: 'Task status ID',
              type: 'number',
              control_type: 'number',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 1 - Open, 2 - Hold, 3 - In Progress,
              4 - Closed'
            }
          },
          { name: 'TaskStatus' },
          {
            name: 'PriorityID',
            type: 'number',
            control_type: 'number'
          },
          { name: 'CanManageAssigneesTasks', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanManageAssigneesTasks',
                  label: 'Can manage assignees tasks',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'Priority' },
          { name: 'CanCreateTimeEntriesForOther', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanCreateTimeEntriesForOther',
                  label: 'Can create time entries for other',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          {
            name: 'CreatorID',
            type: 'number',
            control_type: 'number'
          },
          { name: 'CanCreateTimeEntries', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanCreateTimeEntries',
                  label: 'Can create time entries',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'Creator' },
          { name: 'CanCreateTasks', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'CanCreateTasks',
                  label: 'Can create tasks',
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true or false' } },
          { name: 'CanViewMembersAndAssignees', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'CanViewMembersAndAssignees',
                label: 'Can view members and assignees',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'CanEditAllTasks', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'CanEditAllTasks',
                label: 'Can edit all tasks',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'CanEditAssignedTasks', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'CanEditAssignedTasks',
              label: 'Can edit assigned tasks',
              type: :boolean,
              control_type: 'text',
              optional: true,
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true or false'
            } },
          { name: 'IsProjectMember', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'IsProjectMember',
                label: 'Is project member',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'CanManageProjectMembers', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'CanManageProjectMembers',
                label: 'Can manage project members',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'CanAccessAllTimeEntries', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'CanAccessAllTimeEntries',
                label: 'Can access all time entries',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'CanEdit', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'CanEdit',
                label: 'Can edit',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'CanDelete', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'CanDelete',
                label: 'Can delete',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } }
        ]
      end
    },
    project_members: {
      fields: lambda do
        [
          {
            name: 'EntityBaseID',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'ProjectMemberID',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'ProjectID',
            type: 'number',
            control_type: 'number'
          },
          { name: 'Project' },
          {
            name: 'UserID',
            type: 'number',
            control_type: 'number'
          },
          { name: 'User' },
          {
            name: 'MemberPermissionID',
            type: 'number',
            control_type: 'number'
          },
          { name: 'MemberPermission' },
          {
            name: 'RoleID',
            label: 'Role',
            control_type: 'select',
            pick_list: 'role_id_status_list',
            toggle_hint: 'Use from Options list',
            toggle_field: {
              name: 'RoleID',
              label: 'Role ID',
              type: 'number',
              control_type: 'number',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 1 - Administrator,' \
              ' 2 - Project Manager, 3 - Collaborator, 4 - Participant ' \
              'and 5 - Supervisor'
            }
          },
          { name: 'Role' }
        ]
      end
    },
    activities: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'EntityBaseID',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'TaskID',
            type: 'number',
            control_type: 'number'
          },
          { name: 'Name' },
          { name: 'Description' },
          { name: 'ParentID' },
          {
            name: 'Progress',
            type: 'number',
            control_type: 'number',
            hint: 'Current development of the project in percentage value'
          },
          { name: 'ActualCompletionDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion' },
          {
            name: 'CreationDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          {
            name: 'StartDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          {
            name: 'EndDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          {
            name: 'Duration',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'DurationHours',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'StartDateLag',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'EndDateLag',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'EstimatedHours',
            type: 'number',
            control_type: 'number',
            hint: 'Estimated amount of time to complete a task or a project.'
          },
          {
            name: 'HoursLeft',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'BillingType',
            label: 'Billing type',
            control_type: 'select',
            pick_list: 'billing_type_list',
            toggle_hint: 'Use from Options list',
            toggle_field: {
              name: 'BillingType',
              label: 'Billing type ID',
              type: 'number',
              control_type: 'number',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 1 - Resource hourly rate,
              2 - Customer hourly rate, 3 - Activity rate, 4 - Project' \
              ' hourly rate, 5 - Project flat fee,
              6 - Not billable'
            }
          },
          { name: 'BillingAmount',
            type: 'number',
            control_type: 'number',
            parse_output: 'float_conversion' },
          {
            name: 'Cost',
            type: 'number',
            control_type: 'number',
            parse_output: 'float_conversion'
          },
          { name: 'HasChild', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'HasChild',
                label: 'Has child',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'Budget',
            type: 'number',
            control_type: 'number',
            parse_output: 'float_conversion' },
          {
            name: 'LastModificationDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          {
            name: 'WBSNumber',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'StartDateForGantt'
          },
          { name: 'EndDateForGantt' },
          { name: 'LagForGantt' },
          {
            name: 'ProjectID',
            type: 'number',
            control_type: 'number'
          },
          { name: 'Project' },
          { name: 'Category' },
          {
            name: 'TaskTypeID',
            label: 'Task type',
            control_type: 'select',
            pick_list: 'task_type_list',
            toggle_hint: 'Use from Options list',
            toggle_field: {
              name: 'TaskTypeID',
              label: 'Task type ID',
              type: 'number',
              control_type: 'number',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 1 - Task, 2 - Issue, 3 - Request'
            }
          },
          { name: 'TaskType' },
          {
            name: 'TaskStatusID',
            label: 'Task status',
            control_type: 'select',
            pick_list: 'task_status_list',
            toggle_hint: 'Use from Options list',
            toggle_field: {
              name: 'TaskStatusID',
              label: 'Task status ID',
              type: 'number',
              control_type: 'number',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 1 - Open, 2 - Hold, 3 - In Progress,
              4 - Closed'
            }
          },
          { name: 'TaskStatus' },
          {
            name: 'PriorityID',
            label: 'Priority',
            control_type: 'select',
            pick_list: 'project_priority_list',
            toggle_hint: 'Use from Options list',
            toggle_field: {
              name: 'PriorityID',
              label: 'Priority ID',
              type: 'number',
              control_type: 'number',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 1 - HOT (Now), 2 - Urgent, 3 - High,
              4 - Medium, and 5 - Low'
            }
          },
          { name: 'Priority' },
          {
            name: 'CreatorID',
            type: 'number',
            control_type: 'number'
          },
          { name: 'Creator' },
          { name: 'CanCreateTimeEntries', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'CanCreateTimeEntries',
                label: 'Can create time entries',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'CanCreateTasks', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'CanCreateTasks',
              label: 'Can create tasks',
              type: :boolean,
              control_type: 'text',
              optional: true,
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true or false'
            } },
          { name: 'CanCreateTimeEntriesForOther', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'CanCreateTimeEntriesForOther',
              label: 'Can create time entries for other',
              type: :boolean,
              control_type: 'text',
              optional: true,
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true or false'
            } },
          { name: 'CanManageAssigneesTasks', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'CanManageAssigneesTasks',
                label: 'Can manage assignees tasks',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'CanViewMembersAndAssignees', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'CanViewMembersAndAssignees',
                label: 'Can view members and assignees',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'CanEditAllTasks', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'CanEditAllTasks',
                label: 'Can edit all tasks',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'CanEditAssignedTasks', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'CanEditAssignedTasks',
              label: 'Can edit assigned tasks',
              type: :boolean,
              control_type: 'text',
              optional: true,
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true or false'
            } },
          { name: 'IsProjectMember', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'IsProjectMember',
                label: 'Is project member',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'CanManageProjectMembers', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'CanManageProjectMembers',
                label: 'Can manage project members',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'CanAccessAllTimeEntries', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'CanAccessAllTimeEntries',
                label: 'Can access all time entries',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'IsMilestone', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'IsMilestone',
                label: 'Is milestone',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'Approved', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'Approved',
              label: 'Approved',
              type: :boolean,
              control_type: 'text',
              optional: true,
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true or false'
            } },
          { name: 'Billed', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'Billed',
                label: 'Billed',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'CanEdit', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'CanEdit',
                label: 'Can edit',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'HasDescription', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'HasDescription',
                label: 'Has description',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } }
        ]
      end
    },
    time_logs: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'EntityBaseID',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'TimeEntryID',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'EntryDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          { name: 'Description' },
          { name: 'Billable', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'Billable',
                label: 'Billable',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          {
            name: 'Duration',
            type: 'number',
            control_type: 'number'
          },
          {
            name: 'LastModificationDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          { name: 'Billed', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'Billed',
                label: 'Billed',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          {
            name: 'Rate',
            type: 'number',
            control_type: 'number',
            parse_output: 'float_conversion'
          },
          {
            name: 'Approved', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'Approved',
                label: 'Approved',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' }
          },
          {
            name: 'InternalRate',
            type: 'number',
            control_type: 'number',
            parse_output: 'float_conversion'
          },
          {
            name: 'Cost',
            type: 'number',
            control_type: 'number',
            parse_output: 'float_conversion'
          },
          { name: 'Locked', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'Locked',
                label: 'Locked',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          {
            name: 'CreationDate',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          {
            name: 'TaskID',
            type: 'number',
            control_type: 'number'
          },
          { name: 'Task' },
          {
            name: 'UserID',
            type: 'number',
            control_type: 'number'
          },
          { name: 'User' },
          { name: 'CanDelete', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'CanDelete',
                label: 'Can delete',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          {
            name: 'CreatorId',
            type: 'number',
            control_type: 'number'
          },
          { name: 'CanEdit', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'CanEdit',
                label: 'Can edit',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } },
          { name: 'Creator' },
          { name: 'CanApprove', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'CanApprove',
                label: 'Can approve',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true or false' } }
        ]
      end
    },
    custom_action_input: {
      fields: lambda do |connection, config_fields|
        input_schema = parse_json(config_fields.dig('input', 'schema') || '[]')

        [
          {
            name: 'path',
            optional: false,
            hint: "Base URI is <b>https://#{connection['base_url']}." \
                  'go.easyprojects.net</b> - path will be appended to ' \
                  'this URI. Use absolute URI to override this base URI.'
          },
          (
            if %w[get delete].include?(config_fields['verb'])
              {
                name: 'input',
                type: 'object',
                control_type: 'form-schema-builder',
                sticky: input_schema.blank?,
                label: 'URL parameters',
                add_field_label: 'Add URL parameter',
                properties: [
                  {
                    name: 'schema',
                    extends_schema: true,
                    sticky: input_schema.blank?
                  },
                  (
                    if input_schema.present?
                      {
                        name: 'data',
                        type: 'object',
                        properties: call('make_schema_builder_fields_sticky',
                                         input_schema)
                      }
                    end
                  )
                ].compact
              }
            else
              {
                name: 'input',
                type: 'object',
                properties: [
                  {
                    name: 'schema',
                    extends_schema: true,
                    schema_neutral: true,
                    control_type: 'schema-designer',
                    sample_data_type: 'json_input',
                    sticky: input_schema.blank?,
                    label: 'Request body parameters',
                    add_field_label: 'Add request body parameter'
                  },
                  (
                    if input_schema.present?
                      {
                        name: 'data',
                        type: 'object',
                        properties: call('make_schema_builder_fields_sticky',
                                         input_schema)
                      }
                    end
                  )
                ].compact
              }
            end
          ),
          {
            name: 'output',
            control_type: 'schema-designer',
            sample_data_type: 'json_http',
            extends_schema: true,
            schema_neutral: true,
            sticky: true
          }
        ]
      end
    },
    custom_action_output: {
      fields: lambda do |_connection, config_fields|
        parse_json(config_fields['output'] || '[]')
      end
    }
  },
  actions: {
    list_users: {
      description: "List all <span class='provider'>users</span> " \
        " in <span class='provider'>Easy Projects</span>",
      help: {
        body: 'Retrieves all users from Easy Projects',
        learn_more_url: 'https://api.easyprojects.net/users',
        learn_more_text: 'The Users API documentation'
      },
      execute: lambda do |_connection, _input|
        { users: get('/rest/v1/users') }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'users', type: 'array', of: 'object',
            properties: object_definitions['user'] }
        ]
      end,
      sample_output: lambda do
        { users: get('/rest/v1/users')[0] || {} }
      end
    },
    get_user_by_id: {
      description: "Get a <span class='provider'>user</span> " \
      " by <span class='provider'>ID</span>" \
      " in <span class='provider'>Easy Projects</span> ",
      help: {
        body: 'Retrieves a user by ID from Easy Projects',
        learn_more_url: 'https://api.easyprojects.net/users',
        learn_more_text: 'The Users API documentation'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'UserID', label: 'User ID', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        get("rest/v1/users/#{input['UserID']}")
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['user']
      end,
      sample_output: lambda do
        get('/rest/v1/users')[0] || {}
      end
    },
    create_user: {
      description: "Create a <span class='provider'>user</span> " \
      " in <span class='provider'>Easy Projects</span>",
      help: {
        body: 'Creates a user in Easy Projects',
        learn_more_url: 'https://api.easyprojects.net/users',
        learn_more_text: 'The Users API documentation'
      },
      input_fields: lambda do |object_definitions|
        object_definitions['user'].only('Name', 'EMail', 'RoleID').
          required('Name', 'EMail', 'RoleID')
      end,
      execute: lambda do |_connection, input|
        post('/rest/v1/users').payload(input)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['user']
      end,
      sample_output: lambda do |_connection, _input|
        get('/rest/v1/users')[0] || {}
      end
    },
    update_user: {
      description: "Update <span class='provider'>user</span> " \
      " in <span class='provider'>Easy Projects</span>",
      help: {
        body: 'Updates a user in Easy Projects',
        learn_more_url: 'https://api.easyprojects.net/users',
        learn_more_text: 'The Users API documentation'
      },
      input_fields: lambda do |object_definitions|
        object_definitions['user'].required('UserID').
          ignored('IsAvatarEmpty', 'EntityBaseID', 'EMail',
                  'Login', 'AvatarHash', 'LastActivityDate',
                  'LoginEnabledDate', 'PasswordModifyDate',
                  'InvalidPasswordAttemptsCount', 'LastModificationDate',
                  'LastLockoutDate', 'PresetID', 'CreationDate', 'CustomerID',
                  'Customer', 'Role')
      end,
      execute: lambda do |_connection, input|
        put("/rest/v1/users/#{input['UserID']}").payload(input)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['user']
      end,
      sample_output: lambda do |_connection, _input|
        get('/rest/v1/users')[0] || {}
      end
    },
    delete_user: {
      description: "Deletes a <span class='provider'>user</span> " \
      " in <span class='provider'>Easy Projects</span>",
      help: {
        body: 'Deletes a user in Easy Projects',
        learn_more_url: 'https://api.Easy Projects.net/users',
        learn_more_text: 'The Users API documentation'
      },
      input_fields: lambda do |object_definitions|
        object_definitions['user'].required('UserID')
      end,
      execute: lambda do |_connection, input|
        { status: delete("/rest/v1/users/#{input['UserID']}")&.
          presence || 'success' }
      end,
      output_fields: lambda do |_object_definitions|
        [
          { name: 'status' }
        ]
      end,
      sample_output: lambda do |_connection, _input|
        {
          status: 'success'
        }
      end
    },
    list_projects: {
      description: "List all <span class='provider'>projects</span> " \
        " in <span class='provider'>Easy Projects</span>",
      help: {
        body: 'Retrieves all projects from Easy Projects',
        learn_more_url: 'https://api.easyprojects.net/projects',
        learn_more_text: 'The Projects API documentation'
      },
      execute: lambda do |_connection, _input|
        { projects: get('/rest/v1/projects') }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'projects', type: 'array', of: 'object',
            properties: object_definitions['project'] }
        ]
      end,
      sample_output: lambda do
        { projects: get('/rest/v1/projects')[0] || {} }
      end
    },
    get_project_by_id: {
      description: "Get <span class='provider'>project</span> " \
      " by <span class='provider'>project ID</span>" \
      " in <span class='provider'>Easy Projects</span> ",
      help: {
        body: 'Returns a project by ID from Easy Projects',
        learn_more_url: 'https://api.easyprojects.net/projects',
        learn_more_text: 'The Projects API documentation'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'ProjectID', label: 'Project ID', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        get("rest/v1/projects/#{input['ProjectID']}")
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['project']
      end,
      sample_output: lambda do
        get('/rest/v1/projects')[0] || {}
      end
    },
    create_project: {
      description: "Create <span class='provider'>project</span> " \
      " in <span class='provider'>Easy Projects</span>",
      help: {
        body: 'Creates a project in Easy Projects',
        learn_more_url: 'https://api.easyprojects.net/projects',
        learn_more_text: 'The Project API documentation'
      },
      input_fields: lambda do |object_definitions|
        object_definitions['project'].required('Name').
          only('Name', 'Description', 'Progress', 'StartDate', 'EndDate',
               'EstimatedHours', 'BillingType', 'BillingAmount', 'Budget',
               'ProjectStatusID', 'PriorityID', 'CurrencyID', 'Billed')
      end,
      execute: lambda do |_connection, input|
        post('/rest/v1/projects').payload(input)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['project']
      end,
      sample_output: lambda do
        get('/rest/v1/projects')[0] || {}
      end
    },
    update_project: {
      description: "Update <span class='provider'>project</span> in " \
      "<span class='provider'>Easy Projects</span>",
      help: {
        body: 'Creates a project in Easy Projects',
        learn_more_url: 'https://api.Easy Projects.net/projects',
        learn_more_text: 'The Project API documentation'
      },
      input_fields: lambda do |object_definitions|
        object_definitions['project'].
          required('ProjectID', 'BillingType').
          ignored('EntityBaseID', 'CreationDate',
                  'ActCompletionDate', 'LastModificationDate', 'StartDateLag',
                  'EndDateLag', 'ProjectStatus', 'Priority', 'Creator',
                  'Portfolio', 'Currency', 'HasDescription', 'CanCreateTasks',
                  'CanViewMembersAndAssignees', 'CanManageProjectMembers',
                  'CanManageAssigneesTasks', 'CanEditAllTasks',
                  'CanEditAssignedTasks', 'CanDeleteAllTimeEntries',
                  'CanDeleteAllTasks', 'CanCreateTimeEntriesForOther',
                  'CanCreateTimeEntries', 'CanAccessAllTimeEntries', 'CanEdit',
                  'CanDelete', 'Duration', 'DurationHours')
      end,
      execute: lambda do |_connection, input|
        put("rest/v1/projects/#{input['ProjectID']}").payload(input)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['project']
      end,
      sample_output: lambda do
        get('/rest/v1/projects')[0] || {}
      end
    },
    get_activities_by_project_id: {
      description: "Get all <span class='provider'>project activities</span> " \
      " by <span class='provider'>Project ID</span> " \
      " in <span class='provider'>Easy Projects</span> ",
      help: {
        body: 'Returns all activties of a project',
        learn_more_url: 'https://api.easyprojects.net/projects',
        learn_more_text: 'The Projects API documentation'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'ProjectID', label: 'Project ID', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        { project_activities: get("rest/v1/projects/#{input['ProjectID']}/" \
          'activities') }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'project_activities', type: 'array', of: 'object',
            properties: object_definitions['project_activities'] }
        ]
      end,
      sample_output: lambda do |_connection, _input|
        project_id = get('rest/v1/projects')&.dig(0, 'ProjectID')
        { project_activities: get("rest/v1/projects/#{project_id}/" \
          'activities')[0] || {} }
      end
    },
    get_members_by_project_id: {
      description: "Get <span class='provider'>members</span> " \
      " by <span class='provider'>Project ID</span> " \
      " in <span class='provider'>Easy Projects</span> ",
      help: {
        body: 'Returns all members of a project',
        learn_more_url: 'https://api.easyprojects.net/projects',
        learn_more_text: 'The Projects API documentation'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'ProjectID', label: 'Project ID', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        { members: get("rest/v1/projects/#{input['ProjectID']}/members") }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'members', type: 'array', of: 'object',
            properties: object_definitions['project_members'] }
        ]
      end,
      sample_output: lambda do |_connection, _input|
        project_id = get('rest/v1/projects')&.dig(0, 'ProjectID')
        { members: get("rest/v1/projects/#{project_id}/members")[0] || {} }
      end
    },
    list_timelogs: {
      description: "List all <span class='provider'>time logs</span> " \
        " in <span class='provider'>Easy Projects</span>",
      help: {
        body: 'Retrieves all timelogs from Easy Projects',
        learn_more_url: 'https://api.easyprojects.net/timelogs',
        learn_more_text: 'The Timelogs API documentation'
      },
      execute: lambda do |_connection, _input|
        { timelogs: get('/rest/v1/timelogs') }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'timelogs', type: 'array', of: 'object',
            properties: object_definitions['time_logs'] }
        ]
      end,
      sample_output: lambda do
        { timelogs: get('/rest/v1/timelogs')[0] || {} }
      end
    },
    get_timelogs_by_id: {
      description: "Get <span class='provider'>time logs</span> " \
      " by <span class='provider'>ID</span> " \
      " in <span class='provider'>Easy Projects</span>",
      help: {
        body: 'Get timelogs by ID in Easy Projects',
        learn_more_url: 'https://api.easyprojects.net/timelogs',
        learn_more_text: 'The Timelogs API documentation'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'TimeEntryID', label: 'Time entry ID', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        get("rest/v1/timelogs/#{input['TimeEntryID']}")
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['time_logs']
      end,
      sample_output: lambda do
        get('/rest/v1/timelogs')[0] || {}
      end
    },
    create_timelog: {
      description: "Create <span class='provider'>time log</span> " \
      " in <span class='provider'>Easy Projects</span>",
      help: {
        body: 'Creates a timelog in Easy Projects',
        learn_more_url: 'https://api.easyprojects.net/timelogs',
        learn_more_text: 'The Timelogs API documentation'
      },
      input_fields: lambda do |object_definitions|
        object_definitions['time_logs'].
          required('Description', 'Duration', 'UserID', 'EntryDate', 'TaskID').
          only('Description', 'Duration', 'UserID', 'EntryDate', 'TaskID')
      end,
      execute: lambda do |_connection, input|
        post('/rest/v1/timelogs/').payload(input)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['time_logs']
      end,
      sample_output: lambda do
        get('/rest/v1/timelogs')[0] || {}
      end
    },
    list_activities: {
      description: "List all <span class='provider'>activities</span> " \
        " in <span class='provider'>Easy Projects</span>",
      help: {
        body: 'Retrieves all activities from Easy Projects',
        learn_more_url: 'https://api.easyprojects.net/activities',
        learn_more_text: 'The Activities API documentation'
      },
      execute: lambda do |_connection, _input|
        { activities: get('/rest/v1/activities') }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'activities', type: 'array', of: 'object',
            properties: object_definitions['activities'] }
        ]
      end,
      sample_output: lambda do |_connection, _input|
        { activities: get('/rest/v1/activities')[0] || {} }
      end

    },
    get_activities_by_task_id: {
      description: "Get <span class='provider'>project activities</span> " \
      " by <span class='provider'>ID</span>" \
      " in <span class='provider'>Easy Projects</span> ",
      help: {
        body: 'Returns an activity by Task ID in Easy Projects',
        learn_more_url: 'https://api.easyprojects.net/activities',
        learn_more_text: 'The Activities API documentation'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'TaskID', label: 'Task ID', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        get("rest/v1/activities/#{input['TaskID']}")
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['activities']
      end,
      sample_output: lambda do |_connection, _input|
        get('/rest/v1/activities')[0] || {}
      end

    },
    create_activity: {
      description: "Create <span class='provider'>activity</span> " \
      " in <span class='provider'>Easy Projects</span>",
      help: {
        body: 'Creates an activity in Easy Projects',
        learn_more_url: 'https://api.easyprojects.net/activities',
        learn_more_text: 'The Activities API documentation'
      },
      input_fields: lambda do |object_definitions|
        object_definitions['activities'].required('Name', 'ProjectID').
          only('Name', 'ProjectID', 'Progress', 'StartDate', 'EndDate',
               'EstimatedHours', 'Budget', 'TaskTypeID', 'TaskStatusID',
               'PriorityID', 'HoursLeft', 'Budget')
      end,
      execute: lambda do |_connection, input|
        post('/rest/v1/activities').payload(input)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['activities']
      end,
      sample_output: lambda do |_connection, _input|
        get('/rest/v1/activities')[0] || {}
      end
    },
    custom_action: {
      description: "Custom <span class='provider'>action</span> " \
        "in <span class='provider'>Easy Projects</span>",
      help: {
        body: 'Build your own action for any Easy Projects ' \
        'REST endpoint.',
        learn_more_url: 'https://api.easyprojects.net',
        learn_more_text: 'The Easy Projects API documentation'
      },
      config_fields: [{
        name: 'verb',
        label: 'Request type',
        hint: 'Select HTTP method of the request',
        optional: false,
        control_type: 'select',
        pick_list: %w[get post put delete].map { |verb| [verb.upcase, verb] }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['custom_action_input']
      end,

      execute: lambda do |_connection, input|
        verb = input['verb']
        error("#{verb} not supported") if %w[get post put delete].exclude?(verb)
        data = input.dig('input', 'data').presence || {}
        case verb
        when 'get'
          response =
            get(input['path'], data).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact

          if response.is_a?(Array)
            array_name = parse_json(input['output'] || '[]').
                         dig(0, 'name') || 'array'
            { array_name.to_s => response }
          elsif response.is_a?(Hash)
            response
          else
            error('API response is not a JSON')
          end
        when 'post'
          post(input['path'], data).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact
        when 'put'
          put(input['path'], data).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact
        when 'delete'
          delete(input['path'], data).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact
        end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['custom_action_output']
      end
    }
  },
  triggers: {
    new_or_updated_project: {
      subtitle: 'New or updated project',
      description: "New or updated <span class='provider'>project</span> " \
       " in <span class='provider'>Easy Projects</span>",
      help: {
        body: 'The trigger will fetch new or updated project from EasyProjects',
        learn_more_url: 'https://api.easyprojects.net/projects',
        learn_more_text: 'The Projects API documentation'
      },
      input_fields: lambda do |_connection|
        [{
          name: 'since',
          type: 'timestamp',
          optional: true,
          sticky: true
        }]
      end,
      poll: lambda do |_connection, input, closure|
        offset = closure&.[](0) ||  0
        page_size = 50
        updated_since = (closure&.[](1) || input['since'] || 1.hour.ago).
                        to_time.utc.iso8601
        response = get('/rest/v1/projects',
                       'return_object': 'shallow',
                       'LastModificationDate': updated_since,
                       '$skip': offset,
                       '$top': page_size)&.compact
        more_pages = response.size >= page_size
        closure = if more_pages
                    [offset + response.size, updated_since]
                  else
                    [0, now]
                  end
        { events: response, next_poll: closure, can_poll_more: more_pages }
      end,

      dedup: lambda do |project|
        project['ProjectID'].to_s + '@' + project['LastModificationDate']
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['project']
      end,
      sample_output: lambda do
        get('/rest/v1/projects')[0] || {}
      end
    }
  },
  pick_lists: {
    role_id_status_list: lambda do
      [
        %w[Administrator 1],
        %w[Project\ Manager 2],
        %w[Collaborator 3],
        %w[Participant 4],
        %w[Supervisor 5]
      ]
    end,
    project_status_list: lambda do
      [
        %w[Open 1],
        %w[In\ Progress 2],
        %w[Hold 3],
        %w[Closed 4],
        %w[Draft 5],
        %w[Template 6]
      ]
    end,
    project_priority_list: lambda do
      [
        %w[Hot\ (NOW) 1],
        %w[Urgent 2],
        %w[High 3],
        %w[Medium 4],
        %w[Low 5]
      ]
    end,
    currency_list: lambda do
      [
        %w[$\ Dollar 1],
        %w[€\ Euro 2],
        %w[£\ Pound 3],
        %w[¥\ Japanese\ Yen 4],
        %w[G\ Gallons 5],
        %w[฿\ Thai\ Baht 6],
        %w[៛\ Khmer\ Riel 7],
        %w[₡\ Colon 8],
        %w[₢\ Cruzeiro 9],
        %w[₤\ Turkish\ Lira 10],
        %w[₥\ Mill 11],
        %w[₦\ Naira 12],
        %w[₨\ Indian\ Rupee 13],
        %w[₩\ Korean\ Won 14],
        %w[₪\ Israeli\ New\ Sheqel 15],
        %w[₫\ Dong 16],
        %w[₭\ Kip 17],
        %w[₮\ Tugrik 18],
        %w[₯\ Drachma 19],
        %w[﷼\ Omani\ Rial 20],
        %w[R\ Russian\ Ruble 21],
        %w[AR$\ Argentine\ Peso 22],
        %w[AUD\ Australian\ Dollar 23],
        %w[AZN\ Azerbaijani\ New\ Manats 24],
        %w[BHD\ Bahrain\ Dinar 25],
        %w[R$\ Brazilian\ Real 26],
        %w[BGN\ Bulgarian\ Lev 27],
        %w[CAD\ Canadian\ Dollar 28],
        %w[XOF\ CFA\ Franc\ BCEAO 29],
        %w[CL$\ Chilean\ Peso 30],
        %w[CNY\ Chinese\ Yuan 31],
        %w[COP\ Colombian\ Peso 32],
        %w[CZK\ Czech\ Koruna 33],
        %w[DKK\ Danish\ Krone 34],
        %w[EGP\ Egyptian\ Pound 35],
        %w[FJD\ Fijian\ Dollar 36],
        %w[GEL\ Georgian\ Lari 37],
        %w[HKD\ Hong\ Kong\ Dollar 38],
        %w[HUF\ Hungarian\ Forint 39],
        %w[IDR\ Indonesian\ Rupiah 40],
        %w[JOD\ Jordanian\ Dinar 41],
        %w[KZT\ Kazakhstani\ Tenge 42],
        %w[KWD\ Kuwaiti\ Dinar 43],
        %w[LVL\ Latvian\ Lat 44],
        %w[LTL\ Lithuanian\ Litas 45],
        %w[MYR\ Malaysian\ Ringgit 46],
        %w[MXN\ Mexican\ Peso 47],
        %w[MDL\ Moldovan\ Leu 48],
        %w[NAD\ Namibian\ Dollar 49],
        %w[TWD\ New\ Taiwan\ Dollar 50],
        %w[NZD\ New\ Zealand\ Dollar 51],
        %w[NOK\ Norwegian\ Krone 52],
        %w[PLN\ Polish\ Zloty 53],
        %w[QAR\ Qatari\ Riyal 54],
        %w[RON\ Romanian\ New\ Leu 55],
        %w[RUB\ Russian\ Ruble 56],
        %w[SAR\ Saudi\ Arabian\ Riyal 57],
        %w[SGD\ Singaporean\ Dollar 58],
        %w[ZAR\ South\ African\ Rand 59],
        %w[SEK\ Swedish\ Krona 60],
        %w[CHF\ Swiss\ Franc 61],
        %w[AED\ U.A.E.\ Dirham 62],
        %w[UAH\ Ukraine\ Hryvnia 63],
        %w[VEF\ Venezuelan\ Bol?var 64],
        %w[BYN\ Belarusian\ Ruble 65]
      ]
    end,
    billing_type_list: lambda do
      [
        %w[Resource\ hourly\ rate 1],
        %w[Customer\ hourly\ rate 2],
        %w[Activity\ rate 3],
        %w[Project\ hourly\ rate 4],
        %w[Project\ flat\ fee 5],
        %w[Not\ billable 6]
      ]
    end,
    task_type_list: lambda do
      [
        %w[Task 1],
        %w[Issue 2],
        %w[Request 3]
      ]
    end,
    task_status_list: lambda do
      [
        %w[Open 1],
        %w[Hold 2],
        %w[In\ Progress 3],
        %w[Closed 4]
      ]
    end
  }
}
