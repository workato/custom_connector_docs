{
  title: 'JumpCloud',

  connection: {
    fields: [
      {
        name: 'api_key',
        label: 'API key',
        optional: false,
        type: 'string',
        control_type: 'password',
        hint: "Click <a href='https://docs.jumpcloud.com/2.0/authentication" \
        '-and-authorization/authentication-and-authorization-overview#' \
        "access-your-api-key'>here</a> to get API key."
      },
      {
        name: 'org_id',
        label: 'Organization ID',
        type: 'string',
        control_type: 'text',
        hint: "<span class='provider'>Organization ID </span> is a required" \
        ' header for all multi-tenant admins'\
        "Click <a href='https://docs.jumpcloud.com/2.0/authentication" \
        '-and-authorization/multi-tenant-organization-api-headers#to-obtain-' \
        "an-individual-organization-id-via-the-ui' target='_blank'>here<a>" \
        'to get Organization ID'
      }
    ],

    authorization: {
      type: 'api_key',
      apply: lambda do |connection|
        if connection['org_id'].present?
          headers(
            "x-api-key": connection['api_key'],
            "x-org-id": connection['org_id']
          )
        else
          headers("x-api-key": connection['api_key'])
        end
      end
    },
    base_uri: lambda do
      'https://console.jumpcloud.com'
    end
  },

  test: lambda do
    get('api/v2/systemgroups?limit=1')
  end,

  object_definitions: {
    admin: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'email', type: 'string' },
          { name: 'role', type: 'string' },
          { name: 'enableMultiFactor', type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'enableMultiFactor',
                  label: 'Enable multifactor',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'enableWhatsNew', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'enableWhatsNew',
                  label: 'Enable whats new',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: '_id', type: 'string', label: 'ID' },
          { name: 'roleName', type: 'string' }
        ]
      end
    },
    command: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'name', hint: 'Name of the command' },
          { name: 'command', hint: 'The command to execute on the server' },
          { name: 'commandType', hint: 'The command OS' },
          { name: 'commandRunners', type: 'string',
            hint: 'Comma seprated values of IDs of the Command Runner Users ' \
            ' that can execute this command.' },
          { name: 'user' },
          { name: 'sudo', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'sudo',
                  label: 'Sudo',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'systems', type: 'string',
            hint: 'Comma separated values of system IDs to run the command.' \
            ' Not available if you are using Groups.' },
          { name: 'launchType', hint: 'How the command will execute' },
          { name: 'listensTo' },
          { name: 'scheduleRepeatType' },
          { name: 'schedule', hint: 'A crontab that consists of: [ (seconds)' \
            ' (minutes) (hours)(days of month) (months) (weekdays) ]' \
            ' or [ immediate ]' },
          { name: 'files', type: 'string',
            hint: 'Comma separated values of file IDs to include with the' \
            ' command.' },
          { name: 'timeout', hint: 'The time in seconds to' \
            'allow the command to run for' },
          { name: 'organization', hint: 'The ID of the organization' }
        ]
      end
    },
    commands_list: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'totalCount', type: 'integer' },
          { name: 'results', type: 'array', of: 'object', properties: [
            { name: 'name' },
            { name: 'command' },
            { name: 'commandType' },
            { name: 'launchType' },
            { name: 'listensTo' },
            { name: 'schedule' },
            { name: 'trigger' },
            { name: 'scheduleRepeatType' },
            { name: 'organization' },
            { name: '_id', label: 'ID' }
          ] }
        ]
      end
    },
    commandresult: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'command' },
          { name: 'name' },
          { name: 'system' },
          { name: 'systemId' },
          { name: 'organization' },
          { name: 'workflowId' },
          { name: 'workflowInstanceId' },
          { name: 'user' },
          { name: 'sudo', type: 'boolean' },
          { name: 'files', type: 'array', of: 'string' },
          { name: 'requestTime' },
          { name: 'responseTime' },
          { name: 'response', type: 'object', properties: [
            { name: 'id' },
            { name: 'error' },
            { name: 'data', type: 'object', properties: [
              { name: 'output' },
              { name: 'exitCode', type: 'integer' }
            ] }
          ] },
          { name: '_id', label: 'ID' }
        ]
      end
    },
    fdekey: {
      fields: lambda do |_connection, _config_fields|
        [{ name: 'key' }]
      end
    },
    system: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'systemToken', type: 'string' },
          { name: 'organization', type: 'string' },
          { name: 'created', type: 'datetime' },
          { name: 'lastContact', type: 'datetime' },
          { name: 'os', label: 'Operating system', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'arch', type: 'string' },
          { name: 'networkInterfaces', type: 'array', of: 'object', properties:
            [
              { name: 'address', type: 'string' },
              { name: 'family', type: 'string' },
              { name: 'internal', type: 'boolean',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                control_type: 'checkbox',
                toggle_hint: 'Select from list',
                toggle_field:
                    { name: 'internal',
                      label: 'Internal',
                      type: :boolean,
                      control_type: 'text',
                      render_input: 'boolean_conversion',
                      parse_output: 'boolean_conversion',
                      toggle_hint: 'Use custom value',
                      hint: 'Allowed values are true or false' } },
              { name: 'name', type: 'string' }
            ] },
          { name: 'hostname', type: 'string' },
          { name: 'displayName', type: 'string' },
          { name: 'systemTimezone', type: 'integer' },
          { name: 'templateName', type: 'string' },
          { name: 'remoteIP', type: 'string' },
          { name: 'active', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'active',
                  label: 'Active',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'allowSshPasswordAuthentication', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'allowSshPasswordAuthentication',
                label: 'Allow SSH password authentication',
                type: :boolean,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are true or false' } },
          { name: 'allowSshRootLogin', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'allowSshRootLogin',
                label: 'Allow SSH root login',
                type: :boolean,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are true or false' } },
          { name: 'allowMultiFactorAuthentication', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'allowMultiFactorAuthentication',
                label: 'Allow multifactor authentication',
                type: :boolean,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are true or false' } },
          { name: 'allowPublicKeyAuthentication', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'allowPublicKeyAuthentication',
                label: 'Allow public key authentication',
                type: :boolean,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are true or false' } },
          { name: 'modifySSHDConfig', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'modifySSHDConfig',
                label: 'Modify SSHD config',
                type: :boolean,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are true or false' } },
          { name: 'agentVersion', type: 'string' },
          { name: 'serialNumber', type: 'string' },
          { name: '_id', type: 'string', label: 'ID' },
          { name: 'fde', type: 'object', properties:
            [
              { name: 'keyPresent', type: 'boolean',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                control_type: 'checkbox',
                toggle_hint: 'Select from list',
                toggle_field:
                  { name: 'keyPresent',
                    label: 'Key present',
                    type: :boolean,
                    control_type: 'text',
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Use custom value',
                    hint: 'Allowed values are true or false' } },
              { name: 'active', type: 'boolean',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                control_type: 'checkbox',
                toggle_hint: 'Select from list',
                toggle_field:
                  { name: 'active',
                    label: 'Active',
                    type: :boolean,
                    control_type: 'text',
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Use custom value',
                    hint: 'Allowed values are true or false' } }
            ] }
        ]
      end
    },
    systemgroup: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'attributes', type: 'object' },
          { name: 'id', type: 'string' },
          { name: 'name', type: 'string' },
          { name: 'type', type: 'string' }
        ]
      end
    },
    system_user: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'email', type: 'string' },
          { name: 'username', type: 'string' },
          { name: 'allow_public_key', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'allow_public_key',
                  label: 'Allow public key',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'public_key', type: 'string' },
          { name: 'sudo', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'sudo',
                  label: 'Sudo',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'enable_managed_uid', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'enable_managed_uid',
                  label: 'Enable Managed UID',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'unix_uid', type: 'integer' },
          { name: 'unix_guid', type: 'integer' },
          { name: 'activated', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'activated',
                  label: 'Activated',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'tags', hint: 'Comma separated list of values' },
          { name: 'account_locked', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'account_locked',
                  label: 'Account locked',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'passwordless_sudo', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'passwordless_sudo',
                  label: 'Passwordless sudo',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'externally_managed', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'externally_managed',
                label: 'Externally managed',
                type: :boolean,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are true or false' } },
          { name: 'external_dn', type: 'string' },
          { name: 'external_source_type', type: 'string' },
          { name: 'firstname', type: 'string' },
          { name: 'lastname', type: 'string' },
          { name: 'ldap_binding_user', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'ldap_binding_user',
                  label: 'LDAP binding user',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'enable_user_portal_multifactor', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'enable_user_portal_multifactor',
                  label: 'Enable user portal multifactor',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'attributes', type: 'array', of: 'object', properties:
            [
              { name: 'name', type: 'string' },
              { name: 'value', type: 'string' },
              { name: '_id', type: 'string', label: 'ID' }
            ] },
          { name: 'samba_service_user', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'samba_service_user',
                  label: 'Samba service user',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'addresses', type: 'array', of: 'object', properties:
            [
              { name: 'type' },
              { name: 'poBox' },
              { name: 'extendedAddress' },
              { name: 'streetAddress' },
              { name: 'locality' },
              { name: 'region' },
              { name: 'postalCode' },
              { name: 'country' }
            ] },
          { name: 'jobTitle', type: 'string' },
          { name: 'department', type: 'string' },
          { name: 'phoneNumbers', type: 'array', of: 'object', properties:
            [
              { name: 'type' },
              { name: 'number' }
            ] },
          { name: 'relationships', type: 'array', of: 'object' },
          { name: 'password', type: 'string' },
          { name: 'password_never_expires', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'password_never_expires',
                  label: 'Password never expires',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'middlename', type: 'string' },
          { name: 'displayname', type: 'string' },
          { name: 'description', type: 'string' },
          { name: 'location', type: 'string' },
          { name: 'costCenter', type: 'string' },
          { name: 'employeeType', type: 'string' },
          { name: 'company', type: 'string' },
          { name: 'employeeIdentifier', type: 'string' }
        ]
      end
    },
    system_user_return: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'email', type: 'string' },
          { name: 'username', type: 'string' },
          { name: 'allow_public_key', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'allow_public_key',
                  label: 'Allow public key',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'public_key', type: 'string' },
          { name: 'ssh_keys', type: 'array', of: 'object',
            properties: [
              { name: 'create_date' },
              { name: '_id', label: 'ID' },
              { name: 'public_key' },
              { name: 'name' }
            ] },
          { name: 'sudo', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'sudo',
                  label: 'Sudo',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'enable_managed_uid', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'enable_managed_uid',
                  label: 'Enable managed UID',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'unix_uid', type: 'integer' },
          { name: 'unix_guid', type: 'integer' },
          { name: 'activated', type: 'boolean' },
          { name: 'tags', hint: 'Comma separated list of values' },
          { name: 'password_expired', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'password_expired',
                  label: 'Password expired',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'account_locked', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'account_locked',
                  label: 'Account locked',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'passwordless_sudo', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'passwordless_sudo',
                  label: 'Paswordless sudo',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'externally_managed', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'externally_managed',
                  label: 'Externally managed',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'external_dn', type: 'string' },
          { name: 'external_source_type', type: 'string' },
          { name: 'firstname', type: 'string' },
          { name: 'lastname', type: 'string' },
          { name: 'ldap_binding_user', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'ldap_binding_user',
                  label: 'LDAP binding user',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'enable_user_portal_multifactor', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'enable_user_portal_multifactor',
                  label: 'Enable user portal multifactor',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'totp_enabled', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'totp_enabled',
                  label: 'TOTP enabled',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'attributes', type: 'array', of: 'object', properties:
            [
              { name: 'name', type: 'string' },
              { name: 'value', type: 'string' },
              { name: '_id', type: 'string', label: 'ID' }
            ] },
          { name: 'created', type: 'datetime' },
          { name: 'samba_service_user', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'samba_service_user',
                  label: 'Samba service user',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: '_id', type: 'string', label: 'ID' },
          { name: 'organization', type: 'string' },
          { name: 'addresses', type: 'array', of: 'object', properties:
              [
                { name: 'type' },
                { name: 'poBox' },
                { name: 'extendedAddress' },
                { name: 'streetAddress' },
                { name: 'locality' },
                { name: 'region' },
                { name: 'postalCode' },
                { name: 'country' }
              ] },
          { name: 'jobTitle', type: 'string' },
          { name: 'department', type: 'string' },
          { name: 'phoneNumbers', type: 'array', of: 'object', properties:
            [
              { name: 'type' },
              { name: 'number' }
            ] },
          { name: 'relationships', type: 'array', of: 'object' },
          { name: 'badLoginAttempts', type: 'integer' },
          { name: 'password_never_expires', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'password_never_expires',
                  label: 'Password never expires',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'middlename', type: 'string' },
          { name: 'displayname', type: 'string' },
          { name: 'description', type: 'string' },
          { name: 'location', type: 'string' },
          { name: 'costCenter', type: 'string' },
          { name: 'employeeType', type: 'string' },
          { name: 'company', type: 'string' },
          { name: 'employeeIdentifier', type: 'string' }
        ]
      end
    },
    search_user: { fields: lambda do |_connection, config_fields|
      [
        { name: 'search_type', control_type: 'select', optional: false,
          pick_list: [
            %w[Equals eq],
            %w[Contains search]
          ] },
        (
          if %w[username].include?(config_fields['search_by'])
            { name: 'username', optional: false }
          else
            { name: 'email', optional: false }
          end
        )
      ]
    end },
    user: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'username', hint: 'Max length 1024 characters' },
          { name: 'email', hint: 'Max length 1024 characters' },
          { name: 'firstname', hint: 'Max length 1024 characters' },
          { name: 'lastname', hint: 'Max length 1024 characters' },
          { name: 'middlename', hint: 'Max length 1024 characters' },
          { name: 'displayname', hint: 'Max length 1024 characters' },
          { name: 'description', hint: 'Max length 1024 characters' },
          { name: 'location', hint: 'Max length 1024 characters' },
          { name: 'costCenter', hint: 'Max length 1024 characters' },
          { name: 'employeeType', hint: 'Max length 1024 characters' },
          { name: 'company', hint: 'Max length 1024 characters' },
          { name: 'employeeIdentifier', hint: 'Max length 256 characters' },
          { name: 'password' },
          { name: 'allow_public_key',
            type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'allow_public_key',
              label: 'Allow public keys',
              type: :string,
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'public_key' },
          { name: 'ssh_keys', type: 'array', of: 'object',
            properties: [
              { name: '_id', label: 'ID' },
              { name: 'public_key' },
              { name: 'name' },
              { name: 'create_date' }
            ] },
          { name: 'sudo', type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'sudo',
              label: 'Sudo',
              type: :string,
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'enable_managed_uid', type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'enable_managed_uid',
              label: 'Enable managed uid',
              type: :string,
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'unix_uid', type: 'integer' },
          { name: 'unix_guid', type: 'integer' },
          { name: 'activated', type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'activated',
              label: 'Activated',
              type: :string,
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'tags', hint: 'Comma separated list of values' },
          { name: 'password_expired', type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'password_expired',
              label: 'Password expired',
              type: :string,
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'account_locked', type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'account_locked',
              label: 'Account locked',
              type: :string,
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'passwordless_sudo', type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'passwordless_sudo',
              label: 'Passwordless sudo',
              type: :string,
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'externally_managed', type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'externally_managed',
              label: 'Externally managed',
              type: :string,
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'external_dn' },
          { name: 'external_source_type' },
          { name: 'ldap_binding_user', type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'ldap_binding_user',
              label: 'Ldap binding user',
              type: :string,
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'enable_user_portal_multifactor', type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'enable_user_portal_multifactor',
              label: 'Enable user portal multifactor',
              type: :string,
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'totp_enabled', type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'totp_enabled',
              label: 'Totp enabled',
              type: :string,
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'created' },
          { name: '_id', label: 'ID' },
          { name: 'organization' },
          { name: 'addresses', type: 'array', of: 'object', properties: [
            { name: 'id' },
            { name: 'type', hint: 'Max length 1024 characters' },
            { name: 'poBox', hint: 'Max length 1024 characters' },
            { name: 'extendedAddress', hint: 'Max length 1024 characters' },
            { name: 'streetAddress', hint: 'Max length 1024 characters' },
            { name: 'locality', hint: 'Max length 1024 characters ' },
            { name: 'region', hint: 'Max length 1024 characters' },
            { name: 'postalCode', hint: 'Max length 1024 characters' },
            { name: 'country', hint: 'Max length 1024 characters' }
          ] },
          { name: 'jobTitle', hint: 'Max length 1024 characters' },
          { name: 'department', hint: 'Max length 1024 characters' },
          { name: 'phoneNumbers', type: 'array', of: 'object', properties: [
            { name: 'id' },
            { name: 'type', hint: 'Max length 1024 characters' },
            { name: 'number', hint: 'Max length 1024 characters' }
          ] },
          { name: 'relationships', type: 'array', of: 'object' },
          { name: 'badLoginAttempts', type: 'integer' },
          { name: 'password_never_expires', type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'password_never_expires',
              label: 'Password never expires',
              type: :string,
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } }
        ]
      end
    },
    usergroup: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'attributes', type: 'object' },
          { name: 'id', type: 'string' },
          { name: 'name', type: 'string' },
          { name: 'type', type: 'string' }
        ]
      end
    },
    system_graph_management_req: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'id', label: 'Object ID',
            hint: 'The Object ID of graph object being added or removed' \
            ' as an association.'
          },
          {
            name: 'op',
            label: 'Operation',
            control_type: 'select',
            pick_list: [
              %w[Add add],
              %w[Remove remove],
              %w[Update update]
            ],
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'op',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'User custom value',
              hint: 'Allowed values are add, remove or update'
            }
          },
          {
            name: 'type', control_type: 'select', hint: 'Select type with' \
            ' respect to the Object ID',
            pick_list: [
              %w[Active\ directory active_directory],
              %w[Application application],
              %w[Command command],
              %w[G\ suite g_suite],
              %w[Ldap\ server ldap_server],
              %w[Office\ 365 office_365],
              %w[Policy policy],
              %w[Radius\ server radius_server],
              %w[System\ group system_group],
              %w[System system],
              %w[User user],
              %w[User\ group user_group]

            ],
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'type',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'User custom value',
              hint: 'Select type with respect to the Object ID'
            }

          },
          { name: 'attributes', type: 'object', properties: [
            { name: 'sudo', type: 'object', properties: [
              { name: 'enabled', type: 'boolean',
                control_type: 'checkbox',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Select from list',
                toggle_field:
                    { name: 'enableMultiFactor',
                      label: 'Enable multifactor',
                      type: :boolean,
                      control_type: 'text',
                      render_input: 'boolean_conversion',
                      parse_output: 'boolean_conversion',
                      toggle_hint: 'Use custom value',
                      hint: 'Allowed values are true or false' } },
              { name: 'withoutPassword', type: 'boolean',
                control_type: 'checkbox',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Select from list',
                toggle_field:
                    { name: 'withoutPassword',
                      label: 'Without password',
                      type: :boolean,
                      control_type: 'text',
                      render_input: 'boolean_conversion',
                      parse_output: 'boolean_conversion',
                      toggle_hint: 'Use custom value',
                      hint: 'Allowed values are true or false' } }
            ] }
          ] }
        ]
      end
    },
    policy_with_details: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id' },
          { name: 'template', type: 'object', properties: [
            { name: 'id' },
            { name: 'name' },
            { name: 'description' },
            { name: 'displayName' },
            { name: 'osMetaFamily',
              hint: 'Allowed Values: linux, darwin, windows' },
            { name: 'activation' },
            { name: 'behavior' },
            { name: 'state' }
          ] },
          { name: 'configFields', type: 'object', properties: [
            { name: 'id' },
            { name: 'defaultValue' },
            { name: 'displayType' },
            { name: 'displayOptions' },
            { name: 'label' },
            { name: 'name' },
            { name: 'position' },
            { name: 'readOnly', type: 'boolean' },
            { name: 'required', type: 'boolean' },
            { name: 'tooltip', type: 'object', properties: [
              { name: 'template' },
              { name: 'variables', type: 'object', properties: [
                { name: 'icon' },
                { name: 'message' }
              ] }
            ] }
          ] },
          { name: 'name' },
          { name: 'values', type: 'array', of: 'object', properties: [
            { name: 'configFieldID' },
            { name: 'value' }
          ] }
        ]
      end
    },
    system_user_put: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'email', type: 'string' },
          { name: 'username', type: 'string' },
          { name: 'allow_public_key', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'allow_public_key',
                  label: 'Allow public key',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'public_key', type: 'string' },
          { name: 'sudo', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'sudo',
                  label: 'Sudo',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'enable_managed_uid', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'enable_managed_uid',
                  label: 'Enable Managed UID',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'unix_uid', type: 'integer' },
          { name: 'unix_guid', type: 'integer' },
          { name: 'tags' },
          { name: 'account_locked', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'account_locked',
                  label: 'Account locked',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'externally_managed', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'externally_managed',
                label: 'Externally managed',
                type: :boolean,
                control_type: 'text',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are true or false' } },
          { name: 'external_dn', type: 'string' },
          { name: 'external_source_type', type: 'string' },
          { name: 'firstname', type: 'string' },
          { name: 'lastname', type: 'string' },
          { name: 'ldap_binding_user', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'ldap_binding_user',
                  label: 'LDAP binding user',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'enable_user_portal_multifactor', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'enable_user_portal_multifactor',
                  label: 'Enable user portal multifactor',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'attributes', type: 'array', of: 'object', properties:
            [
              { name: 'name', type: 'string' },
              { name: 'value', type: 'string' },
              { name: '_id', type: 'string', label: 'ID' }
            ] },
          { name: 'samba_service_user', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'samba_service_user',
                  label: 'Samba service user',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'addresses', type: 'array', of: 'object', properties:
            [
              { name: 'type' },
              { name: 'poBox' },
              { name: 'extendedAddress' },
              { name: 'streetAddress' },
              { name: 'locality' },
              { name: 'region' },
              { name: 'postalCode' },
              { name: 'country' }
            ] },
          { name: 'jobTitle', type: 'string' },
          { name: 'department', type: 'string' },
          { name: 'phoneNumbers', type: 'array', of: 'object', properties:
            [
              { name: 'type' },
              { name: 'number' }
            ] },
          { name: 'relationships', type: 'array', of: 'object' },
          { name: 'password', type: 'string' },
          { name: 'password_never_expires', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'password_never_expires',
                  label: 'Password never expires',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } },
          { name: 'middlename', type: 'string' },
          { name: 'displayname', type: 'string' },
          { name: 'description', type: 'string' },
          { name: 'location', type: 'string' },
          { name: 'costCenter', type: 'string' },
          { name: 'employeeType', type: 'string' },
          { name: 'company', type: 'string' },
          { name: 'employeeIdentifier', type: 'string' }
        ]
      end
    },
    custom_action_input: {
      fields: lambda do |_connection, config_fields|
        input_schema = parse_json(config_fields.dig('input', 'schema') || '[]')

        [
          {
            name: 'path',
            optional: false
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
    custom_action: {
      description: "<span class='provider'>Custom action</span> " \
        " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'Build your own JumpCloud action for any JumpCloud ' \
        'REST endpoint.',
        learn_more_url: 'https://docs.jumpcloud.com/2.0/api-overview/v2-api',
        learn_more_text: 'The JumpCloud API documentation'
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
          patch(input['path'], data).
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
    },
    add_user_to_system: {
      description: "Add <span class='provider'>user</span> " \
      " to <span class='provider'>system</span> in <span " \
      "class='provider'>JumpCloud</span>",
      help: {
        body: 'The action allows you to manage the <b>direct</b> associations' \
        " of a System. It uses the <a href='https://docs.jumpcloud.com/2.0/" \
        "systems/manage-associations-of-a-system' target='_blank'>
        Manage associations of a System API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/2.0/systems/' \
        'manage-associations-of-a-system',
        learn_more_text: 'Manage associations of a System API'
      },
      input_fields: lambda do |object_definitions|
        [{ name: 'system_id', optional: false }].
          concat(object_definitions['system_graph_management_req'].
          required('id', 'type', 'op'))
      end,
      execute: lambda do |_connection, input|
        {
          status: post("/api/v2/systems/#{input.delete('system_id')}/" \
                       'associations', input).
            after_error_response(/.*/) do |_code, body, _header, _message|
              error(body[/(?<=message\"\:\").*(?=\"\})/])
            end&.presence || 'success'
        }
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'status' }]
      end,
      sample_output: lambda do |_connection, _input|
        { status: 'success' }
      end
    },
    add_system_user_to_group: {
      description: "Add <span class='provider'>system user</span> " \
      "to <span class='provider'>group</span> " \
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: "The action uses the <a href='https://docs.jumpcloud.com/2.0/" \
        "user-group-members-and-membership/manage-members-of-a-user-group'" \
        " target='_blank'>Manage the members of a User Group</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/2.0/user-group-members-' \
        'and-membership/manage-members-of-a-user-group',
        learn_more_text: 'Manage the members of a User Group API'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'group_id', optional: false, hint: 'Usergroup ID' },
          { name: 'id', label: 'Graph object ID',
            hint: 'The Object ID of graph object being added or removed' \
            ' as an association.' },
          { name: 'op',
            label: 'Operation',
            control_type: 'select',
            pick_list: [
              %w[Add add],
              %w[Remove remove]
            ],
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'op',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'User custom value',
              hint: 'Allowed values are add, remove'
            } },
          { name: 'type',
            label: 'Type',
            control_type: 'select',
            pick_list: [%w[User user]],
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'op',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'User custom value',
              hint: 'Allowed values: user'
            } }
        ]
      end,
      execute: lambda do |_connection, input|
        { status:
          post("/api/v2/usergroups/#{input.delete('group_id')}/members", input).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end&.presence || 'success' }
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'status' }]
      end,
      sample_output: lambda do |_connection, _input|
        { status: 'success' }
      end
    },
    add_system_to_group: {
      description: "Add <span class='provider'>system</span> " \
      "to <span class='provider'>group of system</span>" \
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: "The action uses the <a href='https://docs.jumpcloud.com/2.0/' \
        'system-group-members-and-membership/" \
        "manage-members-of-a-system-group target='_blank> Manage the members" \
        ' of a System Group API</a>.',
        learn_more_url: 'https://docs.jumpcloud.com/2.0/' \
        'system-group-members-and-membership/manage-members-of-a-system-group',
        learn_more_text: 'Manage the members of a System Group API'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'group_id', optional: false, hint: 'Systemgroup ID' },
          { name: 'id', label: 'System ID',
            hint: 'The ObjectID of member being added or removed' \
            ' as an association.' },
          { name: 'op',
            label: 'Operation',
            control_type: 'select',
            pick_list: [%w[Add add], %w[Remove remove]],
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'op',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'User custom value',
              hint: 'Allowed values are add, remove'
            } },
          { name: 'type',
            label: 'Type',
            control_type: 'select',
            pick_list: [%w[System system]],
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'op',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'User custom value',
              hint: 'Allowed values: system'
            } }
        ]
      end,
      execute: lambda do |_connection, input|
        { status:
            post("/api/v2/systemgroups/#{input.delete('group_id')}/members",
                 input).
              after_error_response(/.*/) do |_code, body, _header, message|
                error("#{message}: #{body}")
              end&.presence || 'success' }
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'status' }]
      end,
      sample_output: lambda do |_connection, _input|
        { status: 'success' }
      end
    },
    add_system_to_command: {
      description: "Add <span class='provider'>system</span> " \
      "to a <span class='provider'>command</span>" \
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: "The action uses the <a href='https://docs.jumpcloud.com/2.0/" \
        "commands/manage-associations-of-a-command' target='_blank'> " \
        'Manage the associations of a Command API</a>.',
        learn_more_url: 'https://docs.jumpcloud.com/2.0/commands/' \
        'manage-associations-of-a-command',
        learn_more_text: 'Manage the associations of a Command API'
      },
      input_fields: lambda do |object_definitions|
        [{ name: 'command_id', optional: false }].
          concat(object_definitions['system_graph_management_req'].
          required('id', 'type', 'op'))
      end,
      execute: lambda do |_connection, input|
        { status:
            post("/api/v2/commands/#{input.delete('command_id')}/" \
                'associations').payload(input).
              after_error_response(/.*/) do |_code, body, _header, message|
                error("#{message}: #{body}")
              end&.presence || 'success' }
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'status' }]
      end,
      sample_output: lambda do |_connection, _input|
        { status: 'success' }
      end
    },
    create_user: {
      description: "Create <span class='provider'>system user</span> " \
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action creates a new system user. It uses the' \
        " <a href='https://docs.jumpcloud.com/1.0/systemusers/" \
        "create-a-system-user' target='_blank'>Create a system user API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/1.0/systemusers/' \
        'create-a-system-user',
        learn_more_text: 'Create a system user API'
      },
      input_fields: lambda do |object_definitions|
        object_definitions['system_user']
      end,
      execute: lambda do |_connection, input|
        post('/api/systemusers', input).
          after_error_response(/.*/) do |_code, body, _header, _message|
            error(body[/(?<=message\"\:\").*(?=\"\})/])
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['system_user_return']
      end,
      sample_output: lambda do |_connection, _input|
        get('/api/systemusers?limit=1').dig('results', 0) || {}
      end
    },
    create_command: {
      description: "Create <span class='provider'>command</span> " \
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action allows you to create a command. it ' \
          "uses the <a href='https://docs.jumpcloud.com/1.0/commands/" \
          "create-a-command' target='_blank'>Create A Command API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/1.0/commands/' \
        'create-a-command',
        learn_more_text: 'Create A Command API'
      },
      input_fields: lambda do |object_definitions|
        object_definitions['command'].required('command', 'user')
      end,
      execute: lambda do |_connection, input|
        payload = input.map do |key, value|
          if %w[commandRunners systems files].include?(key)
            { key => value.split(',') }
          else
            { key => value }
          end
        end.inject(:merge)
        post('/api/commands', payload)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['command']
      end,
      sample_output: lambda do |_connection, _input|
        get('api/commands?limit=1').dig('results', 0) || {}
      end
    },
    delete_user: {
      description: "Delete <span class='provider'>system user</span> " \
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action allows you to delete a system user. ' \
          "It uses the <a href='https://docs.jumpcloud.com/1.0/" \
          "systemusers/delete-a-system-user' target='_blank'>Delete a system" \
          ' user API</a>.',
        learn_more_url: 'https://docs.jumpcloud.com/1.0/systemusers/' \
        'delete-a-system-user',
        learn_more_text: 'Delete a system user API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'user_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        delete("/api/systemusers/#{input['user_id']}")
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['system_user_return']
      end,
      sample_output: lambda do |_connection, _input|
        get('/api/systemusers').dig('results', 0) || {}
      end
    },
    delete_system: {
      description: "Delete <span class='provider'>system</span> " \
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action allows you to delete a system. ' \
          "Uses the <a href='https://docs.jumpcloud.com/1.0/systems/" \
          "delete-a-system' target='_blank'>Delete a System API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/1.0/systems/delete-a-system',
        learn_more_text: 'Delete a System API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'system_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        delete("/api/systems/#{input['system_id']}")
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['system']
      end,
      sample_output: lambda do |_connection, _input|
        get('/api/systems?limit=1').dig('results', 0) || {}
      end
    },
    delete_system_from_group: {
      description: "Delete <span class='provider'>system</span> " \
      " from <span class='provider'>group</span>" \
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action allows you to delete a system to a systemgroup.' \
          "Uses the <a href='https://docs.jumpcloud.com/2.0/" \
          'system-group-members-and-membership/' \
          "manage-members-of-a-system-group' target='_blank'>
          Manage the members of a System Group API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/2.0/' \
        'system-group-members-and-membership/manage-members-of-a-system-group',
        learn_more_text: 'Manage the members of a System Group API'
      },
      input_fields: lambda do |object_definitions|
        [{ name: 'group_id', optional: false, hint: 'systemgroup ID' }].
          concat(object_definitions['system_graph_management_req'].
          required('id', 'type', 'op'))
      end,
      execute: lambda do |_connection, input|
        { status:
          post("/api/v2/systemgroups/#{input.delete('group_id')}/members").
            payload(input).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end&.presence || 'success' }
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'status' }]
      end,
      sample_output: lambda do |_connection, _input|
        { status: 'success' }
      end
    },
    delete_user_from_group: {
      description: "Delete <span class='provider'>user</span> " \
      " from usergroup in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action allows you to delete a user from a usergroup. ' \
          "Uses the <a href='https://docs.jumpcloud.com/2.0/" \
          'user-group-members-and-membership/' \
          "manage-members-of-a-user-group' target='_blank'>
          Manage the members of a User Group API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/2.0/user-group-' \
        'members-and-membership/manage-members-of-a-user-group',
        learn_more_text: 'Manage the members of a User Group API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'group_id', optional: false, hint: 'Usergroup ID' },
         { name: 'user_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        payload =
          {
            op: 'remove',
            type: 'user',
            id: input['user_id']
          }
        { status: post("/api/v2/usergroups/#{input['group_id']}/members").
          payload(payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.presence || 'success' }
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'status' }]
      end,
      sample_output: lambda do |_connection, _input|
        { status: 'success' }
      end
    },
    delete_user_from_system: {
      description: "Delete <span class='provider'>user</span> " \
      " from <span class='provider'>system</span>" \
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action allows you to delete a user from the system. ' \
          "Uses the <a href='https://docs.jumpcloud.com/2.0/systems/" \
          "manage-associations-of-a-system' target='_blank'>
          Manage associations of a System API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/2.0/' \
        'systems/manage-associations-of-a-system',
        learn_more_text: 'Manage associations of a System API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'system_id', optional: false },
         { name: 'user_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        payload = { attributes:
                    { sudo: { enabled: false,
                              withoutPassword: false } },
                    op: 'remove',
                    type: 'user',
                    id: input['user_id'] }
        { status: post("/api/v2/systems/#{input['system_id']}/associations").
          payload(payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.presence || 'success' }
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'status' }]
      end,
      sample_output: lambda do |_connection, _input|
        { status: 'success' }
      end
    },
    delete_commandresult_by_id: {
      description: "Delete <span class='provider'>commandresult</span> " \
      " by <span class='provider'>ID</span>" \
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action allows you to delete a command result by ID. ' \
          "It uses the <a href='https://docs.jumpcloud.com/1.0/command-" \
          "results/delete-a-command' target='_blank'>Delete a Command" \
          ' result API</a>.',
        learn_more_url: 'https://docs.jumpcloud.com/1.0/' \
        'command-results/delete-a-command',
        learn_more_text: 'Delete a Command result API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'commandresult_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        delete("/api/commandresults/#{input['commandresult_id']}")
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['commandresult']
      end,
      sample_output: lambda do |_connection, _input|
        get('/api/commandresults').dig('results', 0) || {}
      end
    },
    delete_system_from_command: {
      description: "Delete <span class='provider'>system</span> " \
      " from <span class='provider'>command</span>" \
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action allows you to delete a system from a command. ' \
          "It uses the <a href='https://docs.jumpcloud.com/2.0/commands/" \
          "manage-associations-of-a-command' target='_blank'>
          Manage the associations of a Command API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/2.0/commands/' \
        'manage-associations-of-a-command',
        learn_more_text: 'Manage the associations of a Command API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'command_id', optional: false },
         { name: 'system_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        payload =
          {
            op: 'remove',
            type: 'system',
            id: input['system_id']
          }
        { status: post("/api/v2/commands/#{input['command_id']}" \
          '/associations').payload(payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.presence || 'success' }
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'status' }]
      end,
      sample_output: lambda do |_connection, _input|
        { status: 'success' }
      end
    },
    delete_command_by_id: {
      description: "Delete <span class='provider'>command</span> " \
      " by <span class='provider'>ID</span>"\
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action allows you to delete a command. ' \
          "It uses the <a href='https://docs.jumpcloud.com/1.0/commands/" \
          "delete-a-command-1' target='_blank'>Delete a Command API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/1.0/commands/' \
          'delete-a-command-1',
        learn_more_text: 'Delete a Command API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'command_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        delete("/api/commands/#{input['command_id']}")
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['command']
      end,
      sample_output: lambda do |_connection, _input|
        get('/api/commands?limit=1')&.dig('results', 0) || {}
      end
    },
    get_system_user_by_id: {
      description: "Get <span class='provider'>system user</span> " \
      " by <span class='provider'>user ID</span>" \
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action allows you to get a system user by user ID. ' \
          "It uses the <a href='https://docs.jumpcloud.com/1.0/systemusers/" \
          "list-a-system-user' target='_blank'>List a system user API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/1.0/systemusers/' \
        'list-a-system-user',
        learn_more_text: 'List a system user API'
      },
      input_fields: lambda do
        [{ name: 'user_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        get("/api/systemusers/#{input['user_id']}")
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['system_user_return']
      end,
      sample_output: lambda do |_connection, _input|
        get('/api/systemusers?limit=1').dig('results', 0) || {}
      end
    },
    get_system_by_id: {
      description: "Get <span class='provider'>system</span> by ID " \
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action allows you to get a system by ID. ' \
          "It uses the <a href='https://docs.jumpcloud.com/1.0/systems/" \
          "list-an-individual-system' target='_blank'>List an individual" \
          ' system API</a>.',
        learn_more_url: 'https://docs.jumpcloud.com/1.0/systems/' \
        'list-an-individual-system',
        learn_more_text: 'List an individual system API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'system_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        get("/api/systems/#{input['system_id']}")
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['system']
      end,
      sample_output: lambda do |_connection, _input|
        get('/api/systems?limit=1').dig('results', 0) || {}
      end
    },
    get_systemgroup_by_id: {
      description: "Get <span class='provider'>systemgroup</span> " \
      " by <span class='provider'>ID</span>"\
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action allows you to get a systemgroup by ID. ' \
          "It uses the <a href='https://docs.jumpcloud.com/2.0/" \
          "system-groups/view-a-system-group-details' target='_blank'>" \
          'View an individual System Group details API</a>.',
        learn_more_url: 'https://docs.jumpcloud.com/2.0/system-groups/' \
        'view-a-system-group-details',
        learn_more_text: 'View an individual System Group details API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'group_id', optional: false, hint: 'Systemgroup ID' }]
      end,
      execute: lambda do |_connection, input|
        get("/api/v2/systemgroups/#{input['group_id']}")
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['systemgroup']
      end,
      sample_output: lambda do |_connection|
        get('/api/v2/systemgroups?limit=1')[0] || {}
      end
    },
    get_usergroup_by_id: {
      description: "Get <span class='provider'>usergroup</span> " \
      " by <span class='provider'>ID</span>" \
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action allows you to get usergroup by ID. ' \
          "It uses the <a href='https://docs.jumpcloud.com/2.0/user-groups/" \
          "view-a-user-group-details' target='_blank'>" \
          'View an individual User Group details API</a>.',
        learn_more_url: 'https://docs.jumpcloud.com/2.0/user-groups/' \
        'view-a-user-group-details',
        learn_more_text: 'View an individual User Group details API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'usergroup_id', optional: false, label: 'Usergroup ID' }]
      end,
      execute: lambda do |_connection, input|
        get("/api/v2/usergroups/#{input['usergroup_id']}")
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['usergroup']
      end,
      sample_output: lambda do |_connection, _input|
        get('/api/v2/usergroups?limit=1')[0] || {}
      end
    },
    get_fde_key_by_system_id: {
      description: "Get <span class='provider'>FDE key</span> " \
      " by system ID in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action return the current (latest) FDE key saved for a ' \
        "system. The action uses the <a href='https://docs.jumpcloud.com/2.0/" \
        "systems/get-system-fde-key' target='_blank'>" \
        'Get system FDE key API</a>.',
        learn_more_url: 'https://docs.jumpcloud.com/2.0/systems/' \
        'get-system-fde-key',
        learn_more_text: 'Get system FDE key API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'system_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        get("/api/v2/systems/#{input['system_id']}/fdekey").
          after_error_response(/.*/) do |_code, body, _header, _message|
            error(body[/(?<=message\"\:\").*(?=\"\})/])
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['fdekey']
      end,
      sample_output: lambda do |_connection, _input|
        { key: 'cupidatat consequat occaecat proident' }
      end
    },
    get_commandresult_by_command_id: {
      description: "Get <span class='provider'>commandresult</span> " \
      " by <span class='provider'>command ID</span>" \
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action gets the command result by command ID. ' \
          "It uses the <a href='https://docs.jumpcloud.com/1.0/" \
          "command-results/list-an-individual-command' target='_blank'>" \
          'List an individual Command result API</a>.',
        learn_more_url: 'https://docs.jumpcloud.com/1.0/command-results/' \
        'list-an-individual-command',
        learn_more_text: 'List an individual Command result API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'command_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        get("/api/commandresults/#{input['command_id']}")
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['commandresult']
      end,
      sample_output: lambda do |_connection, _input|
        get('/api/commandresults?limit=1').dig('results', 0) || {}
      end
    },
    get_policy_by_id: {
      description: "Get <span class='provider'>policy details</span> " \
      " by <span class='provider'>ID</span>" \
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action alows you to get a policy details by ID. ' \
        "It uses the <a href='https://docs.jumpcloud.com/2.0/policies/" \
        "gets-a-specific-policy' target='_blank'>" \
        'Gets a specific Policy API</a>.',
        learn_more_url: 'https://docs.jumpcloud.com/2.0/policies/' \
        'gets-a-specific-policy',
        learn_more_text: 'Gets a specific Policy API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'policy_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        get("/api/v2/policies/#{input['policy_id']}")
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['policy_with_details']
      end,
      sample_output: lambda do |_connection, _input|
        get('/api/v2/policies?limit=1')[0] || {}
      end
    },
    list_admins: {
      description: "List <span class='provider'>admins</span> " \
      " in <span class='provider'>JumpCloud</span> ",
      hint: 'the list admins action returns maximum of 100 records',
      execute: lambda do |_connection, _input|
        { admins: get('/api/users?limit=100')['results'] }
      end,
      output_fields: lambda do |object_definitions|
        [{ name: 'admins', type: 'array', of: 'object',
           properties: object_definitions['admin'] }]
      end,
      sample_output: lambda do |_connection, _input|
        { admins: get('/api/users?limit=1')['results'] || {} }
      end
    },
    list_system_users: {
      description: "List <span class='provider'>system users</span> " \
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action will list all the system users. ' \
          "It uses the <a href='https://docs.jumpcloud.com/1.0/systemusers/" \
          "list-all-system-users' target='_blank'>
          List all system users API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/1.0/systemusers/' \
        'list-all-system-users',
        learn_more_text: 'List all system users API'
      },
      input_fields: lambda do |object_definitions|
        [
          { name: 'filter', type: 'array', of: 'object',
            hint: 'If you provide more than one filter criteria, ' \
            'it returns records which satisfy all conditions',
            properties: object_definitions['system_user'].
              only('email', 'username', 'firstname', 'lastname', '_id',
                   'organization', 'department', 'location', 'costCenter',
                   'employeeType', 'company', 'employeeIdentifier') },
          { name: 'fields',
            hint: 'The comma separated fields included in the returned ' \
            'records. If omitted the default list of fields will be' \
            ' returned.' },
          { name: 'sort',
            hint: 'The comma separated fields used to sort the collection.' \
            ' Default sort is ascending, prefix with <b>-</b> to ' \
            'sort descending.' },
          { name: 'limit', type: 'integer', hint: 'Default value is 10' },
          { name: 'skip', label: 'Offset', hint: 'Default value is 0' }
        ]
      end,
      execute: lambda do |_connection, input|
        { users: get('/api/systemusers', input)['results'] }
      end,
      output_fields: lambda do |object_definitions|
        [{ name: 'users', type: 'array', of: 'object',
           properties: object_definitions['system_user'] }]
      end,
      sample_output: lambda do |_connection, _input|
        { users: get('/api/systemusers?limit=1').dig('results', 0) || {} }
      end
    },
    list_system_users_by_system_id: {
      description: "List <span class='provider'>system users</span> " \
      " by <span class='provider'>system ID</span>" \
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action lists all the user in a system using a system ID. ' \
          "It uses the <a href='https://docs.jumpcloud.com/2.0/systems/" \
          "list-the-users-bound-to-a-system' target='_blank'>
          List the Users bound to a System API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/2.0/systems/' \
        'list-the-users-bound-to-a-system',
        learn_more_text: 'List the Users bound to a System API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'system_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        { users: get("/api/v2/systems/#{input['system_id']}/users") }
      end,
      output_fields: lambda do |_object_definitions|
        [
          { name: 'users', type: 'array', of: 'object', properties: [
            { name: 'id', type: 'string' },
            { name: 'type', type: 'string' },
            { name: 'compiledAttributes',
              type: 'object', properties: [
                { name: 'sudo', type: 'object', properties: [
                  { name: 'enabled', type: 'boolean' },
                  { name: 'withoutPassword', type: 'boolean' }
                ] }
              ] }
          ] }
        ]
      end,
      sample_output: lambda do |_connection, _input|
        system_id = get('/api/systems')&.dig('results', 0, 'id')
        { users: get("/api/v2/systems/#{system_id}/users").
          params(limit: 1) || {} }
      end
    },
    lock_user: {
      description: "Lock <span class='provider'>user</span> " \
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action locks a specific user. ' \
          "Uses the <a href='https://docs.jumpcloud.com/1.0/systemusers/" \
          "update-a-system-user' target='_blank'>Update a system user API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/1.0/systemusers/' \
        'update-a-system-user',
        learn_more_text: 'Update a system user API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'user_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        payload = { account_locked: true }
        put("/api/systemusers/#{input['user_id']}", payload).
          after_error_response(/.*/) do |_code, body, _header, _message|
            error(body[/(?<=error\"\:\").*(?=\"\})/])
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['system_user_return']
      end,
      sample_output: lambda do |_connection, _input|
        get('/api/systemusers').dig('results', 0) || {}
      end
    },
    list_commands: {
      description: "List <span class='provider'>command</span> " \
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: "It uses the <a href='https://docs.jumpcloud.com/1.0/commands/" \
          "list-all-commands' target='_blank'>List All Commands API</a>." \
          'the number of records to return is limited to 100',
        learn_more_url: 'https://docs.jumpcloud.com/1.0/commands/' \
          'list-all-commands',
        learn_more_text: 'List All Commands API'
      },
      execute: lambda do |_connection, _input|
        get('/api/commands?limit=100')
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['commands_list']
      end,
      sample_output: lambda do |_connection, _input|
        get('/api/commands?limit=1')
      end
    },
    list_commandresults: {
      description: "List <span class='provider'>command results</span> " \
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action lists all the command results and it returns ' \
          'maximum of 100 records. ' \
          "Uses the <a href='https://docs.jumpcloud.com/1.0/command-results/" \
          "list-all-command-results' target='_blank'> List all Command" \
          ' Results API</a>.',
        learn_more_url: 'https://docs.jumpcloud.com/1.0/' \
        'command-results/list-all-command-results',
        learn_more_text: 'List all Command Results API'
      },
      execute: lambda do |_connection, _input|
        { commandresults: get('/api/commandresults?limit=100')['results'] }
      end,
      output_fields: lambda do |object_definitions|
        [{ name: 'commandresults', type: 'array', of: 'object',
           properties: object_definitions['commandresult'] }]
      end,
      sample_output: lambda do |_connection, _input|
        { commandresults: get('/api/commandresults').
          params(limit: 1)&.dig('results', 0) || {} }
      end
    },
    list_systems: {
      description: "List <span class='provider'>systems</span> " \
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action lists all the system inside JumpCloud. ' \
          "It uses the <a href='https://docs.jumpcloud.com/" \
          "1.0/systems/list-all-systems' target='_blank'>
          List All Systems API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/1.0/systems/' \
          'list-all-systems',
        learn_more_text: 'List All Systems API'
      },
      execute: lambda do |_connection, _input|
        { systems: get('/api/systems?limit=100')['results'] }
      end,
      output_fields: lambda do |object_definitions|
        [{ name: 'systems', type: 'array', of: 'object',
           properties: object_definitions['system'] }]
      end,
      sample_output: lambda do |_connection, _input|
        { systems: get('/api/systems').params(limit: 1).
          dig('results', 0) || {} }
      end
    },
    list_systemgroups_by_system_id: {
      description: "List <span class='provider'>systemgroup's</span> " \
      " by <span class='provider'>system ID</span>"\
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action lists all the systemgroups of a system. ' \
          "It uses the <a href='https://docs.jumpcloud.com/2.0/systems/" \
          "list-a-systems-group-membership' target='_blank'>
          List the parent Groups of a System API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/2.0/systems/' \
        'list-a-systems-group-membership',
        learn_more_text: 'List the parent Groups of a System API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'system_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        { system_groups: get('/api/v2/systems/' \
          "#{input['system_id']}/memberof?limit=100") }
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'system_groups', type: 'array', of: 'object',
           properties: [{ name: 'id', type: 'string' },
                        { name: 'type', type: 'string' }] }]
      end,
      sample_output: lambda do |_connection, _input|
        system_id = get('/api/systems')&.dig('results', 0, 'id')
        { system_groups: get("/api/v2/systems/#{system_id}/memberof?" \
          'limit=100') || {} }
      end
    },
    list_systemgroup_policy_by_id: {
      description: "List <span class='provider'>systemgroup's policy</span> " \
      " by <span class='provider'>ID</span>"\
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action lists all the policies of a systemgroup. ' \
          "It uses the <a href='https://docs.jumpcloud.com/2.0/" \
          "system-group-associations/list-associations-of-a-system-group' " \
          "target='_blank'>List the associations of a System Group API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/2.0/system-group-' \
        'associations/list-associations-of-a-system-group',
        learn_more_text: 'List the associations of a system group API'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'systemgroup_id', optional: false },
          { name: 'targets', control_type: 'select', pick_list:
            [
              %w[Active\ directory active_directory],
              %w[Application application],
              %w[Command command],
              %w[G\ suite g_suite],
              %w[Ldap\ server ldap_server],
              %w[Office\ 365 office_365],
              %w[Policy policy],
              %w[Radius\ server radius_server],
              %w[System\ group system_group],
              %w[System system],
              %w[User user],
              %w[User\ group user_group]
            ] },
          { name: 'limit', type: 'integer', hint: 'Default value is 10' },
          { name: 'skip', label: 'Offset', hint: 'Default value is 0' }
        ]
      end,
      execute: lambda do |_connection, input|
        {
          systemgroups: get("/api/v2/systemgroups/#{input['systemgroup_id']}/" \
            'associations?targets=policy')
        }
      end,
      output_fields: lambda do |_object_definitions|
        [
          { name: 'systemgroups', type: 'array', of: 'object', properties:
            [
              { name: 'from', type: 'object', properties:
                [
                  { name: 'attributes', type: 'object' },
                  { name: 'type' },
                  { name: 'id' }
                ] },
              { name: 'to', type: 'object', properties:
                [
                  { name: 'attributes', type: 'object' },
                  { name: 'type' },
                  { name: 'id' }
                ] }
            ] }
        ]
      end,
      sample_output: lambda do |_connection, _input|
        systemgroups = get('/api/v2/systemgroups?limit=1').dig(0, 'id') || 0
        { systemgroups: get("/api/v2/systemgroups/#{systemgroups}/" \
            'associations?targets=policy&limit=1') || {} }
      end
    },
    list_usergroups_by_user_id: {
      description: "List <span class='provider'>usergroups</span> " \
      " by <span class='provider'>user ID</span>"\
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action lists all the usergroups of a system user. It ' \
          "returns maximum of 100 records. Uses the <a href='https://docs." \
          "jumpcloud.com/2.0/users/list-a-users-group-membership' " \
          "target='_blank'>List the parent Groups of a User API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/2.0/users/' \
          'list-a-users-group-membership',
        learn_more_text: 'List the parent Groups of a User API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'user_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        { user_groups: get("/api/v2/users/#{input['user_id']}/" \
          'memberof?limit=100') }
      end,
      output_fields: lambda do |_object_definitions|
        [
          { name: 'user_groups', type: 'array', of: 'object', properties:
            [
              { name: 'id', type: 'string' },
              { name: 'type', type: 'string' },
              { name: 'compiledAttributes', type: 'object', properties:
                [{ name: 'sudo', type: 'object', properties:
                    [
                      { name: 'enabled', type: 'boolean' },
                      { name: 'withoutPassword', type: 'boolean' }
                    ] }] },
              { name: 'paths', type: 'array', of: 'object', properties:
                [
                  { name: 'attributes', type: 'object' },
                  { name: 'to', type: 'object', properties:
                  [
                    { name: 'attributes', type: 'object' },
                    { name: 'type' },
                    { name: 'id' }
                  ] }
                ] }
            ] }
        ]
      end,
      sample_output: lambda do |_connection, _input|
        user_id = get('/api/systemusers?limit=1').dig('results', 0, 'id') || 0
        { user_groups: get("/api/v2/users/#{user_id}/" \
          'memberof?limit=1') || {} }
      end
    },
    list_usergroup_members: {
      description: "List <span class='provider'>usergroup members</span> " \
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action lists all the members of a usergroup and returns' \
          ' maximum of 100 records. ' \
          "It uses the <a href='https://docs.jumpcloud.com/2.0/" \
          'user-group-members-and-membership/' \
          "list-members-of-a-user-group' target='_blank'>
          List the members of a User Group API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/2.0/user-group-members-' \
        'and-membership/list-members-of-a-user-group',
        learn_more_text: 'List the members of a User Group API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'group_id', optional: false, hint: 'User group ID' }]
      end,
      execute: lambda do |_connection, _input|
        group_id = get('/api/v2/usergroups?limit=1')&.dig(0, 'id')
        { members: get("/api/v2/usergroups/#{group_id}/" \
          'members?limit=100') }
      end,
      output_fields: lambda do |_object_definitions|
        [
          { name: 'members', type: 'array', of: 'object', properties:
            [
              { name: 'from', type: 'object', properties:
                [
                  { name: 'attributes', type: 'object' },
                  { name: 'type' },
                  { name: 'id' }
                ] },
              { name: 'to', type: 'object', properties:
                [
                  { name: 'attributes', type: 'object' },
                  { name: 'type' },
                  { name: 'id' }
                ] }
            ] }
        ]
      end,
      sample_output: lambda do |_connection, _input|
        group_id = get('/api/v2/usergroups?limit=1')&.dig(0, 'id')
        { members: get("/api/v2/usergroups/#{group_id}/" \
          'members?limit=100') || {} }
      end
    },
    reset_user_mfa: {
      description: "Reset <span class='provider'>MFA TOTP token</span> " \
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action allows you to reset Multifactor Authentication. ' \
          "It uses the <a href='https://docs.jumpcloud.com/1.0/systemusers/" \
          "reset-systemuser-mfa' target='_blank'>
          Reset a system user's MFA token API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/1.0/' \
        'systemusers/reset-systemuser-mfa',
        learn_more_text: "Reset a system user's MFA token API"
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'user_id', optional: false },
         { name: 'exclusionUntil', type: 'date_time', optional: false }]
      end,
      execute: lambda do |_connection, input|
        post("/api/systemusers/#{input['user_id']}/resetmfa").payload(input).
          after_error_response(/.*/) do |_code, body, _header, _message|
            error(body[/(?<=error\"\:\").*(?=\"\})/])
          end
      end
    },
    search_user: {
      description: "Search <span class='provider'>user</span> " \
      " by <span class='provider'>username or email</span>" \
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action searches a user by username or email and ' \
          'returns maximum of 100 records. ' \
          "Uses the <a href='https://docs.jumpcloud.com/1.0/search/" \
          "list-system-users' target='_blank'>Search System Users API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/1.0/search/' \
          'list-system-users',
        learn_more_text: 'Search System Users API'
      },
      config_fields: [
        {
          name: 'search_by',
          label: 'Search by',
          control_type: 'select',
          pick_list: [%w[User\ name username], %w[Email email]],
          optional: false
        }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['search_user']
      end,
      execute: lambda do |_connection, input|
        payload = { filter: [username:
          if input.delete('search_type') == 'eq'
            input['username']
          else
            { '$regex': input['username'] }
          end],
                    limit: 100 }
        { users: post('/api/search/systemusers', payload)['results'] }
      end,
      output_fields: lambda do |object_definitions|
        [{ name: 'users', type: 'array', of: 'object',
           properties: object_definitions['system_user'] }]
      end,
      sample_output: lambda do |_connection, _input|
        { users: get('/api/systemusers?limit=1').dig('results', 0) || {} }
      end
    },
    search_user_by_employee_id: {
      description: "Search <span class='provider'>user</span> " \
      " by <span class='provider'>employee ID</span>" \
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action searches a user by employee ID and it returns a ' \
          " maximum of 100 records. It uses the <a href='https://" \
          "docs.jumpcloud.com/1.0/search/list-system-users' " \
          "target='_blank'>Search System Users API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/1.0/search/list-system-users',
        learn_more_text: 'Search System Users API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'employee_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        payload = { filter: [employeeIdentifier: input['employee_id']],
                    limit: 100 }
        { users: post('/api/search/systemusers', payload)['results'] }
      end,
      output_fields: lambda do |object_definitions|
        [{ name: 'users', type: 'array', of: 'object', properties:
            object_definitions['system_user'] }]
      end,
      sample_output: lambda do |_connection, _input|
        { users: get('/api/systemusers?limit=1').dig('results', 0) || {} }
      end
    },
    search_system_by_hostname: {
      description: "Search <span class='provider'>system</span> " \
      " by <span class='provider'>hostname</span>" \
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action searches a system by hostname and it returns a ' \
          "maximum of 100 records. It uses the <a href='https://docs." \
          "jumpcloud.com/1.0/search/search-systems' target='_blank'>" \
          'Search Systems API</a>.',
        learn_more_url: 'https://docs.jumpcloud.com/1.0/search/search-systems',
        learn_more_text: 'Search Systems API'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'hostname', optional: false },
          { name: 'search_type', control_type: 'select', optional: false,
            pick_list: [%w[Equals eq], %w[Contains search]] }
        ]
      end,
      execute: lambda do |_connection, input|
        payload = { filter: [hostname:
          if input.delete('search_type') == 'eq'
            input['hostname']
          else
            { '$regex': input['hostname'] }
          end],
                    limit: 100 }
        { systems: post('/api/search/systems', payload)['results'] }
      end,
      output_fields: lambda do |object_definitions|
        [{ name: 'systems', type: 'array', of: 'object',
           properties: object_definitions['system'] }]
      end,
      sample_output: lambda do |_connection, _input|
        { systems: get('/api/systems?limit=1').dig('results', 0) || {} }
      end
    },
    search_usergroup_by_name: {
      description: "Search <span class='provider'>usergroup</span> " \
      " by <span class='provider'>name</span>" \
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action searches a usergroup by name. ' \
          "It uses the <a href='https://docs.jumpcloud.com/2.0/" \
          "user-groups/list-all-users-groups' target='_blank'>" \
          'List all User Groups API</a>.',
        learn_more_url: 'https://docs.jumpcloud.com/2.0/user-groups/' \
        'list-all-users-groups',
        learn_more_text: 'List all User Groups API'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'search_type', control_type: 'select', optional: false,
            pick_list: [%w[Equals eq], %w[Contains search]] },
          { name: 'group_name', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        { groups: get('/api/v2/usergroups?filter=name:'\
          "#{input['search_type']}:#{input['group_name']}") }
      end,
      output_fields: lambda do |object_definitions|
        [{ name: 'groups', type: 'array', of: 'object',
           properties: object_definitions['usergroup'] }]
      end,
      sample_output: lambda do |_connection, _input|
        { groups: get('/api/v2/usergroups?limit=1')[0] || {} }
      end
    },
    run_trigger_command: {
      description: "Trigger <span class='provider'>command</span> " \
      " in <span class='provider'>JumpCloud</span> ",
      help: {
        body: 'This action triggers a command by command name. ' \
          "It uses the <a href='https://docs.jumpcloud.com/1.0/command-" \
          "triggers/runs-a-command-assigned-to-a-webhook' target='_blank'>
          Launch a command via a Trigger</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/1.0/command-triggers/' \
        'runs-a-command-assigned-to-a-webhook',
        learn_more_text: 'Launch a command via a Trigger API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'command_trigger_name', optional: false }]
      end,
      execute: lambda do |_connection, input|
        { triggered:
          post('/api/command/trigger' \
            "/#{input['command_trigger_name']}")['triggered'] }
      end
    },
    unlock_user: {
      description: "Unlock <span class='provider'>user</span> " \
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action unlocks a system user. ' \
          "It uses the <a href='https://docs.jumpcloud.com/1.0/systemusers/" \
          "update-a-system-user' target='_blank'>Update a system user API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/1.0/systemusers/' \
        'update-a-system-user',
        learn_more_text: 'Update a system user API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'user_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        payload = { account_locked: false }
        put("/api/systemusers/#{input['user_id']}", payload).
          after_error_response(/.*/) do |_code, body, _header, _message|
            error(body[/(?<=error\"\:\").*(?=\"\})/])
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['system_user_return']
      end,
      sample_output: lambda do |_connection, _input|
        get('/api/systemusers').dig('results', 0) || {}
      end
    },
    update_user: {
      description: "Update <span class='provider'>user</span> " \
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action updates a user' \
          "It uses the <a href='https://docs.jumpcloud.com/1.0/systemusers/" \
          "update-a-system-user' target='_blank'>Update a system user API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/1.0/systemusers/' \
        'update-a-system-user',
        learn_more_text: 'Update a system user API'
      },
      input_fields: lambda do |object_definitions|
        [{ name: 'user_id', optional: false }].
          concat(object_definitions['system_user_put'].
            required('email', 'username'))
      end,
      execute: lambda do |_connection, input|
        put("/api/systemusers/#{input.delete('user_id')}").payload(input).
          after_error_response(/.*/) do |_code, body, _header, _message|
            error(body[/(?<=error\"\:\").*(?=\"\})/])
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['system_user_return']
      end,
      sample_output: lambda do |_connection, _input|
        get('/api/systemusers').dig('results', 0) || {}
      end
    },
    update_user_type_on_system: {
      description: "Update <span class='provider'>user type</span> " \
      " on <span class='provider'>system</span>" \
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action updates user type. ' \
          "It uses the <a href='https://docs.jumpcloud.com/2.0/users/" \
          "manage-associations-of-a-user' target='_blank'>
          Manage the associations of a User API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/2.0/users/' \
          'manage-associations-of-a-user',
        learn_more_text: 'Manage the associations of a User API'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'user_id', optional: false },
          { name: 'system_id', optional: false },
          { name: 'sudo_enabled', type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'sudo_enabled',
                  label: 'Sudo enabled',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false' } }
        ]
      end,
      execute: lambda do |_connection, input|
        payload = { attributes: { sudo: { enabled:
                    input['sudo_enabled'], withoutPassword: false } },
                    op: 'update',
                    type: 'system',
                    id: input['system_id'] }
        post("/api/v2/users/#{input['user_id']}/associations", payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end
    },
    update_user_to_sudo_user_on_system: {
      description: "Update <span class='provider'>user</span> " \
      " to <span class='provider'>sudo user</span>" \
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action updates standard user to sudo user. ' \
          "It uses the <a href='https://docs.jumpcloud.com/2.0/users/" \
          "manage-associations-of-a-user' target='_blank'>
          Manage the associations of a User API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/2.0/users/' \
        'manage-associations-of-a-user',
        learn_more_text: 'Manage the associations of a User API'
      },
      input_fields: lambda do |_object_definitions|
        [{ name: 'user_id', optional: false },
         { name: 'system_id', optional: false }]
      end,
      execute: lambda do |_connection, input|
        payload = { attributes: { sudo: { enabled: true,
                                          withoutPassword: false } },
                    op: 'update',
                    type: 'system',
                    id: input['system_id'] }
        post("/api/v2/users/#{input['user_id']}/associations", payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end
    },
    update_user_to_standard_user_on_system: {
      description: "Update <span class='provider'>user</span> " \
      " to <span class='provider'>standard user</span>" \
      " in <span class='provider'>JumpCloud</span>",
      help: {
        body: 'This action updates a sudo user to standard user. ' \
          "It uses the <a href='https://docs.jumpcloud.com/2.0/users/" \
          "manage-associations-of-a-user' target='_blank'>
          Manage the associations of a User API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/2.0/users/' \
          'manage-associations-of-a-user',
        learn_more_text: 'Manage the associations of a User API'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'user_id', optional: false },
          { name: 'system_id', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        payload = { attributes: { sudo: { enabled: false,
                                          withoutPassword: false } },
                    op: 'update',
                    type: 'system',
                    id: input['system_id'] }
        post("/api/v2/users/#{input['user_id']}/associations", payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end
    }
  },

  triggers: {
    new_user: {
      description: "New <span class='provider'>user</span> " \
        "in <span class='provider'>JumpCloud</span>",
      type: :paging_desc,
      help: {
        body: 'The trigger will fetch new system users from JumpCloud. ' \
          "It uses the <a href='https://docs.jumpcloud.com/1.0/systemusers/" \
          "list-all-system-users' target='_blank'>
          List all system users API</a>.",
        learn_more_url: 'https://docs.jumpcloud.com/1.0/systemusers/' \
        'list-all-system-users',
        learn_more_text: 'List all system users API'
      },
      poll: lambda do |_connection, _input, page|
        limit = 100
        page ||= 0
        offset = (limit * page)
        response = get('/api/systemusers',
                       sort: '-created',
                       limit: limit,
                       skip: offset).dig('results') || []

        {
          events: response,
          next_page: response.length >= limit ? page + 1 : nil
        }
      end,
      document_id: lambda do |user|
        user['_id']
      end,
      sort_by: lambda do |user|
        user['created']
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['system_user_return']
      end,
      sample_output: lambda do |_connection, _input|
        get('/api/systemusers?limit=1').dig('results', 0) || {}
      end
    }
  }
}
