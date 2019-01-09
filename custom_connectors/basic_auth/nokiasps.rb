# frozen_string_literal: true

{
  title: 'Nokia SPS',

  connection: {
    fields: [
      { name: 'username', optional: false },
      { name: 'password', control_type: 'password', optional: false },
      {
        name: 'instance_url',
        label: 'Instance URL',
        hint: 'Your Nokia SPS instance URL. ' \
          'eg: <b>http://YourSubDomain.labdemos.com</b>',
        optional: false
      }
    ],

    base_uri: ->(connection) { connection['instance_url'] },

    authorization: {
      type: 'basic_auth',

      detect_on: [/"errorMessage"\:/],

      apply: lambda { |connection|
        user(connection['username'])
        password(connection['password'])
      }
    }
  },

  test: lambda { |_connection|
    get('/services/ServiceManager/getRefData/Session',
        'processParams' => '{"findSessionCount":"true"}')
  },

  methods: {
    account_sample_output: lambda do
      {
        'modifiedBy' => 'smadmin',
        'modifiedDate' => 1_542_621_534_515,
        'lifeCycleNames' => {
          'entry' => [
            {
              'key' => 'PERIOD',
              'value' => 'DefaultAccountBillingCycle'
            },
            {
              'key' => 'ENTITY',
              'value' => 'DefaultAccountLifeCycle'
            }
          ]
        },
        'states' => {
          'entry' => [
            {
              'key' => 'PERIOD',
              'value' => {
                'barring' => false,
                'id' => 'DefaultAccountBillingCycle_Start',
                'initial' => true,
                'name' => 'Start',
                'final' => false
              }
            },
            {
              'key' => 'ENTITY',
              'value' => {
                'barring' => false,
                'id' => 'DefaultAccountLifeCycle_Active',
                'initial' => true,
                'name' => 'Active',
                'final' => false
              }
            }
          ]
        },
        'endTime' => 1_544_590_800_000,
        'startTime' => 1_542_621_536_049,
        'id' => '123',
        'hourOfDay' => 0,
        'dayOfWeek' => 'SUNDAY',
        'dayOfMonth' => 12,
        'timeZoneId' => 'America/Toronto',
        'creationTime' => 1_542_621_535_997,
        'overageLimit' => 9_999_999_999,
        'meName' => 'sps-me',
        'customData' => {
          'entry' => []
        },
        'accountType' => 'PRE_PAID',
        'detailedQuery' => false,
        'adjustBalance' => false,
        'resetBalance' => false,
        'addAdministrator' => false,
        'removeAdministrator' => false
      }
    end,

    bundle_sample_output: lambda do
      {
        'modifiedBy' => 'smadmin',
        'modifiedDate' => 1_542_622_261_379,
        'distributionList' => [],
        'smProvState' => 'NEW',
        'name' => 'TEST_bundle',
        'fee' => 20,
        'lifeCycleNames' => {
          'modifiedBy' => null,
          'modifiedDate' => null,
          'distributionList' => [],
          'smProvState' => 'NEW',
          'entry' => [
            {
              'modifiedBy' => null,
              'modifiedDate' => null,
              'distributionList' => [],
              'smProvState' => 'NEW',
              'key' => 'ENTITY',
              'value' => 'DefaultSubscriptionLifeCycle'
            }
          ]
        },
        'chargingServiceList' => [
          'CS_SPS_30G_DATA_POOL'
        ],
        'usageControlServiceList' => [],
        'customDataProfileList' => [],
        'maxRenewals' => null,
        'feePerDevice' => null
      }
    end,

    chargingservice_sample_output: lambda do
      {
        'modifiedBy' => 'smadmin',
        'modifiedDate' => 1_542_768_535_152,
        'distributionList' => [
          {
            'meName' => 'sps-me',
            'provState' => 'PROVISIONED',
            'statusInfo' => 'Successfully distributed',
            'existOnME' => true
          }
        ],
        'smProvState' => 'PROVISIONED',
        'passes' => [
          {
            'modifiedBy' => null,
            'modifiedDate' => null,
            'distributionList' => [
              {
                'meName' => 'sps-me',
                'provState' => 'PROVISIONED',
                'statusInfo' => 'Successfully distributed',
                'existOnME' => true
              }
            ],
            'smProvState' => 'PROVISIONED',
            'tariff' => {
              'id' => 'CS_50G_Data_Pool_Charge_from_bucket',
              'rules' => [
                {
                  'description' => '',
                  'conditionContainer' => {
                    'subContainers' => [],
                    'conditions' => [
                      {
                        'criteria' => {
                          'name' => 'Service-Context-Id',
                          'sourceContext' => 'CALL_COMMON'
                        },
                        'criteriaArguments' => [],
                        'criteriaAdjustOperator' => null,
                        'criteriaAdjustValue' => [],
                        'operator' => 'EQUAL',
                        'value' => {
                          'type' => 'STRING',
                          'value' => '32274@3gpp.org'
                        },
                        'valueArguments' => [],
                        'adjustOperator' => null,
                        'adjustValue' => []
                      }
                    ],
                    'operator' => 'AND'
                  },
                  'actions' => [
                    {
                      'attributeInfo' => {
                        'name' => 'Bucket-Selection',
                        'resultContext' => 'RATING'
                      },
                      'parameters' => [
                        {
                          'name' => 'Data',
                          'value' => {
                            'data' => {
                              'type' => 'STRING',
                              'value' => 'Bkt_1000_SMS_Pool'
                            },
                            'dataArguments' => [],
                            'adjustOperator' => null,
                            'adjustData' => []
                          }
                        }
                      ],
                      'resultContext' => 'RATING',
                      'name' => 'Bucket-Selection'
                    }
                  ],
                  'name' => 'charge_from_bucket'
                },
                {
                  'description' => '',
                  'conditionContainer' => {
                    'subContainers' => [],
                    'conditions' => [
                      {
                        'criteria' => {
                          'name' => 'Service-Context-Id',
                          'sourceContext' => 'CALL_COMMON'
                        },
                        'criteriaArguments' => [],
                        'criteriaAdjustOperator' => null,
                        'criteriaAdjustValue' => [],
                        'operator' => 'EQUAL',
                        'value' => {
                          'type' => 'STRING',
                          'value' => '32251@3gpp.org'
                        },
                        'valueArguments' => [],
                        'adjustOperator' => null,
                        'adjustValue' => []
                      }
                    ],
                    'operator' => 'AND'
                  },
                  'actions' => [
                    {
                      'attributeInfo' => {
                        'name' => 'Bucket-Selection',
                        'resultContext' => 'RATING'
                      },
                      'parameters' => [
                        {
                          'name' => 'Data',
                          'value' => {
                            'data' => {
                              'type' => 'STRING',
                              'value' => 'Bkt_50G_Data_Pool'
                            },
                            'dataArguments' => [],
                            'adjustOperator' => null,
                            'adjustData' => []
                          }
                        }
                      ],
                      'resultContext' => 'RATING',
                      'name' => 'Bucket-Selection'
                    }
                  ],
                  'name' => 'charging from data pool'
                }
              ],
              'name' => 'Charge_from_bucket'
            }
          },
          {
            'modifiedBy' => null,
            'modifiedDate' => null,
            'distributionList' => [
              {
                'meName' => 'sps-me',
                'provState' => 'PROVISIONED',
                'statusInfo' => 'Successfully distributed',
                'existOnME' => true
              }
            ],
            'smProvState' => 'PROVISIONED',
            'tariff' => {
              'id' => 'CS_50G_Data_Pool_Charge_from_balance',
              'rules' => [
                {
                  'description' => '',
                  'conditionContainer' => null,
                  'actions' => [
                    {
                      'attributeInfo' => {
                        'name' => 'Rate',
                        'resultContext' => 'RATING'
                      },
                      'parameters' => [
                        {
                          'name' => 'Rate',
                          'value' => {
                            'data' => {
                              'type' => 'STRING',
                              'value' => 'ApttusDataRate'
                            },
                            'dataArguments' => [],
                            'adjustOperator' => null,
                            'adjustData' => []
                          }
                        },
                        {
                          'name' => 'Target',
                          'value' => {
                            'data' => {
                              'type' => 'STRING',
                              'value' => 'Main Balance'
                            },
                            'dataArguments' => [],
                            'adjustOperator' => null,
                            'adjustData' => []
                          }
                        }
                      ],
                      'resultContext' => 'RATING',
                      'name' => 'Rate'
                    }
                  ],
                  'name' => 'charge_from_balance'
                }
              ],
              'name' => 'Charge_from_balance'
            }
          }
        ],
        'name' => 'CS_50G_Data_Pool',
        'applicabilityCondition' => null,
        'priority' => 123_458,
        'bucketDefinition' => [
          {
            'modifiedBy' => null,
            'modifiedDate' => null,
            'distributionList' => [
              {
                'meName' => 'sps-me',
                'provState' => 'PROVISIONED',
                'statusInfo' => 'Successfully distributed',
                'existOnME' => true
              }
            ],
            'smProvState' => 'PROVISIONED',
            'name' => 'Bkt_50G_Data_Pool',
            'unitType' => {
              'modifiedBy' => null,
              'modifiedDate' => 1_542_866_782_015,
              'distributionList' => [
                {
                  'meName' => 'sps-me',
                  'provState' => 'PROVISIONED',
                  'statusInfo' => 'Successfully distributed',
                  'existOnME' => true
                }
              ],
              'smProvState' => 'PROVISIONED',
              'unitTypeName' => 'GByte',
              'kindOfUnit' => 'VOLUME',
              'shortName' => 'GB',
              'defaultUnit' => false,
              'defaultSMUnit' => false,
              'typeConverter' => {
                'modifiedBy' => null,
                'modifiedDate' => null,
                'distributionList' => [
                  {
                    'meName' => 'sps-me',
                    'provState' => 'PROVISIONED',
                    'statusInfo' => 'Successfully distributed',
                    'existOnME' => true
                  }
                ],
                'smProvState' => 'PROVISIONED',
                'rightSideUnit' => 'Byte',
                'leftSideValue' => 1,
                'rightSideValue' => 1_073_741_824
              }
            },
            'initialValue' => 50,
            'maxCarryOverValueOption' => null,
            'maxCarryOverValue' => null,
            'thresholdProfileGroupIdList' => [
              'ApttusTPG'
            ],
            'carryOverValue' => null,
            'renewalPeriod' => null,
            'consumptionPriority' => null,
            'isCarryOver' => null
          },
          {
            'modifiedBy' => null,
            'modifiedDate' => null,
            'distributionList' => [
              {
                'meName' => 'sps-me',
                'provState' => 'PROVISIONED',
                'statusInfo' => 'Successfully distributed',
                'existOnME' => true
              }
            ],
            'smProvState' => 'PROVISIONED',
            'name' => 'Bkt_1000_SMS_Pool',
            'unitType' => {
              'modifiedBy' => null,
              'modifiedDate' => 1_542_866_781_965,
              'distributionList' => [
                {
                  'meName' => 'sps-me',
                  'provState' => 'PROVISIONED',
                  'statusInfo' => 'Successfully distributed',
                  'existOnME' => true
                }
              ],
              'smProvState' => 'PROVISIONED',
              'unitTypeName' => 'Unit',
              'kindOfUnit' => 'UNIT',
              'shortName' => 'unit',
              'defaultUnit' => true,
              'defaultSMUnit' => false,
              'typeConverter' => null
            },
            'initialValue' => 1000,
            'maxCarryOverValueOption' => 'ABSOLUTEVALUE',
            'maxCarryOverValue' => null,
            'thresholdProfileGroupIdList' => [],
            'carryOverValue' => null,
            'renewalPeriod' => null,
            'consumptionPriority' => null,
            'isCarryOver' => null
          }
        ],
        'counterDefinition' => [],
        'description' => null,
        'category' => 'DefaultCategory'
      }
    end,

    device_sample_output: lambda do
      {
        'modifiedBy' => 'smadmin',
        'modifiedDate' => 1_542_623_100_940,
        'lifeCycleNames' => {
          'entry' => [
            {
              'key' => 'ENTITY',
              'value' => 'DefaultDeviceLifeCycle'
            }
          ]
        },
        'states' => {
          'entry' => [
            {
              'key' => 'ENTITY',
              'value' => {
                'barring' => false,
                'id' => 'DefaultDeviceLifeCycle_Active',
                'initial' => true,
                'name' => 'Active',
                'final' => false
              }
            }
          ]
        },
        'categoryList' => [
          'DefaultCategory'
        ],
        'password' => null,
        'pwdEncrypted' => false,
        'syOCSEnabled' => false,
        'allowOverage' => true,
        'doNotDisconnect' => false,
        'ocsHost' => null,
        'ocsRealm' => null,
        'owningRealm' => null,
        'reports' => [],
        'timeOfDay' => null,
        'deviceType' => 'NORMAL',
        'identities' => [
          {
            'identityType' => 'PRIVATE',
            'value' => '123'
          }
        ],
        'aggregateViewIdList' => [],
        'aggregateViewInstancesList' => [],
        'id' => '191969627677889',
        'creationTime' => 1_542_623_102_452,
        'lastUpdateTime' => 1_542_624_800_793,
        'owner' => null,
        'groups' => [
          {
            'modifiedBy' => null,
            'modifiedDate' => 1_542_879_230_009,
            'lifeCycleNames' => {
              'entry' => []
            },
            'states' => {
              'entry' => []
            },
            'activeDeviceGroupReports' => [],
            'activeGroupReports' => [],
            'id' => '300853793665008',
            'name' => null,
            'creationTime' => null,
            'lastUpdateTime' => null,
            'administrators' => [],
            'customData' => {
              'entry' => []
            },
            'devices' => [],
            'parent' => null,
            'childDeviceIds' => null,
            'childGroupIds' => null,
            'deviceCounterIds' => [],
            'groupCounterIds' => [],
            'traversalOrder' => null,
            'reportActivationRequired' => false,
            'groupReportActivation' => false,
            'deviceGroupReportActivation' => false,
            'meName' => null,
            'subscriptions' => [],
            'detailedQuery' => false,
            'bucketInstancesList' => [],
            'counterInstancesList' => null,
            'bucketDefinitionMap' => null,
            'aggregateViewIdList' => null,
            'aggregateViewInstancesList' => [],
            'notificationProfile' => null
          }
        ],
        'customData' => {
          'entry' => []
        },
        'subscriptions' => [],
        'subscriptionIndex' => 0,
        'notificationProfile' => null,
        'meName' => 'sps-me',
        'counterIds' => [],
        'sessonContainer' => null,
        'reportActivationRequired' => false,
        'offLineTimeStamp' => 0,
        'detailedQuery' => false,
        'counterInstancesList' => null,
        'bucketDefinitionMap' => null,
        'bucketInstanceList' => []
      }
    end,

    group_sample_output: lambda do
      {
        'modifiedBy' => 'smadmin',
        'modifiedDate' => 1_542_624_610_326,
        'lifeCycleNames' => {
          'entry' => [
            {
              'key' => 'ENTITY',
              'value' => 'DefaultGroupLifeCycle'
            }
          ]
        },
        'states' => {
          'entry' => [
            {
              'key' => 'ENTITY',
              'value' => {
                'barring' => false,
                'id' => 'DefaultGroupLifeCycle_Active',
                'initial' => true,
                'name' => 'Active',
                'final' => false
              }
            }
          ]
        },
        'activeDeviceGroupReports' => [],
        'activeGroupReports' => [],
        'id' => '300853793665008',
        'name' => 'TEST_group',
        'creationTime' => 1_542_624_612_125,
        'lastUpdateTime' => 1_542_624_611_537,
        'administrators' => [],
        'customData' => {
          'entry' => []
        },
        'devices' => [],
        'parent' => null,
        'childDeviceIds' => [
          '191969627677889'
        ],
        'childGroupIds' => null,
        'deviceCounterIds' => [],
        'groupCounterIds' => [],
        'traversalOrder' => 'TOP_DOWN',
        'reportActivationRequired' => false,
        'groupReportActivation' => false,
        'deviceGroupReportActivation' => false,
        'meName' => 'sps-me',
        'subscriptions' => [],
        'detailedQuery' => false,
        'bucketInstancesList' => [],
        'counterInstancesList' => [],
        'bucketDefinitionMap' => null,
        'aggregateViewIdList' => [],
        'aggregateViewInstancesList' => [],
        'notificationProfile' => null
      }
    end,

    user_sample_output: lambda do
      {
        'modifiedBy' => 'smadmin',
        'modifiedDate' => 1_542_625_352_161,
        'lifeCycleNames' => {
          'entry' => [
            {
              'key' => 'ENTITY',
              'value' => 'DefaultUserLifeCycle'
            }
          ]
        },
        'states' => {
          'entry' => [
            {
              'key' => 'ENTITY',
              'value' => {
                'barring' => false,
                'id' => 'DefaultUserLifeCycle_Active',
                'initial' => true,
                'name' => 'Active',
                'final' => false
              }
            }
          ]
        },
        'administeredGroups' => [],
        'notificationProfile' => 'defaultNotificationProfile',
        'accountUsers' => [],
        'id' => '123456789',
        'surname' => 'Navarro',
        'givenName' => 'Joshua Aaron ',
        'corporationName' => null,
        'phoneNumbers' => [
          '639353995683'
        ],
        'emails' => [
          'joshua.navarro@workato.com'
        ],
        'facebookId' => null,
        'creationTime' => 1_542_625_353_724,
        'lastUpdateTime' => null,
        'customData' => {
          'entry' => []
        },
        'devices' => [],
        'accountId' => null,
        'meName' => 'sps-me'
      }
    end
  },

  object_definitions: {
    account: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            control_type: 'text',
            label: 'Modified by',
            type: 'string',
            name: 'modifiedBy'
          },
          {
            control_type: 'number',
            label: 'Modified date',
            type: 'number',
            name: 'modifiedDate'
          },
          {
            control_type: 'text',
            label: 'Security domain',
            type: 'string',
            name: 'securityDomain'
          },
          {
            properties: [
              {
                name: 'entry',
                type: 'array',
                of: 'object',
                label: 'Entry',
                properties: [
                  {
                    control_type: 'text',
                    label: 'Key',
                    type: 'string',
                    name: 'key'
                  },
                  {
                    control_type: 'text',
                    label: 'Value',
                    type: 'string',
                    name: 'value'
                  }
                ]
              }
            ],
            label: 'Life cycle names',
            type: 'object',
            name: 'lifeCycleNames'
          },
          {
            properties: [
              {
                name: 'entry',
                type: 'array',
                of: 'object',
                label: 'Entry',
                properties: [
                  {
                    control_type: 'text',
                    label: 'Key',
                    type: 'string',
                    name: 'key'
                  },
                  {
                    properties: [
                      {
                        control_type: 'text',
                        label: 'Barring',
                        type: 'string',
                        name: 'barring'
                      },
                      {
                        control_type: 'text',
                        label: 'ID',
                        type: 'string',
                        name: 'id'
                      },
                      {
                        control_type: 'checkbox',
                        label: 'Initial',
                        toggle_hint: 'Select from option list',
                        toggle_field: {
                          label: 'Initial',
                          control_type: 'text',
                          toggle_hint: 'Use custom value',
                          type: 'boolean',
                          name: 'initial'
                        },
                        type: 'boolean',
                        name: 'initial'
                      },
                      {
                        control_type: 'text',
                        label: 'Name',
                        type: 'string',
                        name: 'name'
                      },
                      {
                        control_type: 'checkbox',
                        label: 'Final',
                        toggle_hint: 'Select from option list',
                        toggle_field: {
                          label: 'Final',
                          control_type: 'text',
                          toggle_hint: 'Use custom value',
                          type: 'boolean',
                          name: 'final'
                        },
                        type: 'boolean',
                        name: 'final'
                      }
                    ],
                    label: 'Value',
                    type: 'object',
                    name: 'value'
                  }
                ]
              }
            ],
            label: 'States',
            type: 'object',
            name: 'states'
          },
          {
            control_type: 'number',
            label: 'End time',
            type: 'number',
            name: 'endTime'
          },
          {
            control_type: 'number',
            label: 'Start time',
            type: 'number',
            name: 'startTime'
          },
          {
            control_type: 'text',
            label: 'ID',
            type: 'string',
            name: 'id'
          },
          {
            control_type: 'number',
            label: 'Hour of day',
            type: 'number',
            name: 'hourOfDay'
          },
          {
            control_type: 'text',
            label: 'Day of week',
            type: 'string',
            name: 'dayOfWeek'
          },
          {
            control_type: 'number',
            label: 'Day of month',
            type: 'number',
            name: 'dayOfMonth'
          },
          {
            control_type: 'text',
            label: 'Time zone ID',
            type: 'string',
            name: 'timeZoneId'
          },
          {
            control_type: 'number',
            label: 'Creation time',
            type: 'number',
            name: 'creationTime'
          },
          {
            control_type: 'text',
            label: 'Last update time',
            type: 'string',
            name: 'lastUpdateTime'
          },
          {
            control_type: 'number',
            label: 'Overage limit',
            type: 'number',
            name: 'overageLimit'
          },
          {
            control_type: 'text',
            label: 'Me name',
            type: 'string',
            name: 'meName'
          },
          {
            properties: [],
            label: 'Custom data',
            type: 'object',
            name: 'customData'
          },
          {
            name: 'accountType',
            control_type: 'select',
            pick_list: 'account_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'accountType',
              label: 'Account type',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            control_type: 'text',
            label: 'Administrators',
            type: 'string',
            name: 'administrators'
          },
          {
            control_type: 'text',
            label: 'Devices',
            type: 'string',
            name: 'devices'
          },
          {
            control_type: 'text',
            label: 'Groups',
            type: 'string',
            name: 'groups'
          },
          {
            control_type: 'checkbox',
            label: 'Detailed query',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Detailed query',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'detailedQuery'
            },
            type: 'boolean',
            name: 'detailedQuery'
          },
          {
            control_type: 'number',
            label: 'Account balance',
            type: 'number',
            name: 'accountBalance'
          },
          {
            control_type: 'text',
            label: 'Subscriptions',
            type: 'string',
            name: 'subscriptions'
          },
          {
            control_type: 'text',
            label: 'Bucket instance map',
            type: 'string',
            name: 'bucketInstanceMap'
          },
          {
            control_type: 'text',
            label: 'Bucket definition map',
            type: 'string',
            name: 'bucketDefinitionMap'
          },
          {
            control_type: 'text',
            label: 'User par map',
            type: 'string',
            name: 'userParMap'
          },
          {
            control_type: 'text',
            label: 'Device',
            type: 'string',
            name: 'device'
          },
          {
            control_type: 'text',
            label: 'Group',
            type: 'string',
            name: 'group'
          },
          {
            control_type: 'text',
            label: 'Entity counter instances',
            type: 'string',
            name: 'entityCounterInstances'
          }
        ]
      end
    },

    bundle: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            control_type: 'text',
            label: 'Modified by',
            type: 'string',
            name: 'modifiedBy'
          },
          {
            control_type: 'number',
            label: 'Modified date',
            parse_output: 'float_conversion',
            type: 'number',
            name: 'modifiedDate'
          },
          {
            control_type: 'text',
            label: 'Security domain',
            type: 'string',
            name: 'securityDomain'
          },
          {
            control_type: 'text',
            label: 'Sm prov state',
            type: 'string',
            name: 'smProvState'
          },
          {
            control_type: 'text',
            label: 'Name',
            type: 'string',
            name: 'name'
          },
          {
            control_type: 'number',
            label: 'Fee',
            parse_output: 'float_conversion',
            type: 'number',
            name: 'fee'
          },
          {
            properties: [
              {
                control_type: 'text',
                label: 'Modified by',
                type: 'string',
                name: 'modifiedBy'
              },
              {
                control_type: 'text',
                label: 'Modified date',
                type: 'number',
                name: 'modifiedDate'
              },
              {
                control_type: 'text',
                label: 'Security domain',
                type: 'string',
                name: 'securityDomain'
              },
              {
                control_type: 'text',
                label: 'Sm prov state',
                type: 'string',
                name: 'smProvState'
              },
              {
                name: 'entry',
                type: 'array',
                of: 'object',
                label: 'Entry',
                properties: [
                  {
                    control_type: 'text',
                    label: 'Modified by',
                    type: 'string',
                    name: 'modifiedBy'
                  },
                  {
                    control_type: 'text',
                    label: 'Modified date',
                    type: 'number',
                    name: 'modifiedDate'
                  },
                  {
                    control_type: 'text',
                    label: 'Security domain',
                    type: 'string',
                    name: 'securityDomain'
                  },
                  {
                    control_type: 'text',
                    label: 'Sm prov state',
                    type: 'string',
                    name: 'smProvState'
                  },
                  {
                    control_type: 'text',
                    label: 'Key',
                    type: 'string',
                    name: 'key'
                  },
                  {
                    control_type: 'text',
                    label: 'Value',
                    type: 'string',
                    name: 'value'
                  }
                ]
              }
            ],
            label: 'Life cycle names',
            type: 'object',
            name: 'lifeCycleNames'
          },
          {
            name: 'chargingServiceList',
            type: 'array',
            of: 'string',
            control_type: 'text',
            label: 'Charging service list'
          },
          {
            name: 'customDataProfileList',
            type: 'array',
            of: 'string',
            control_type: 'text',
            label: 'Custom data profile list'
          },
          {
            control_type: 'number',
            label: 'Max renewals',
            parse_output: 'float_conversion',
            type: 'number',
            name: 'maxRenewals'
          },
          {
            control_type: 'number',
            label: 'Fee per device',
            parse_output: 'float_conversion',
            type: 'number',
            name: 'feePerDevice'
          }
        ]
      end
    },

    charging_service: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            control_type: 'text',
            label: 'Modified by',
            type: 'string',
            name: 'modifiedBy'
          },
          {
            control_type: 'number',
            label: 'Modified date',
            parse_output: 'float_conversion',
            type: 'number',
            name: 'modifiedDate'
          },
          {
            control_type: 'text',
            label: 'Sm prov state',
            type: 'string',
            name: 'smProvState'
          },
          {
            control_type: 'text',
            label: 'Name',
            type: 'string',
            name: 'name'
          },
          {
            control_type: 'text',
            label: 'Category',
            type: 'string',
            name: 'category'
          },
          {
            name: 'distributionList',
            type: 'array',
            of: 'object',
            label: 'Distribution list',
            properties: [
              {
                control_type: 'text',
                label: 'meName',
                type: 'string',
                name: 'meName'
              },
              {
                control_type: 'text',
                label: 'Provision state',
                type: 'string',
                name: 'provState'
              },
              {
                control_type: 'text',
                label: 'Status info',
                type: 'string',
                name: 'statusInfo'
              },
              {
                control_type: 'checkbox',
                label: 'Exists on ME',
                type: 'boolean',
                name: 'existOnME'
              }

            ]
          },
          {
            name: 'bucketDefinition',
            type: 'array',
            of: 'object',
            label: 'Bucket definition',
            properties: [
              {
                control_type: 'text',
                label: 'Name',
                type: 'string',
                name: 'name'
              },
              {
                properties: [
                  {
                    control_type: 'text',
                    label: 'Unit type name',
                    type: 'string',
                    name: 'unitTypeName'
                  },
                  {
                    control_type: 'text',
                    label: 'Short name',
                    type: 'string',
                    name: 'shortName'
                  },
                  {
                    control_type: 'text',
                    label: 'Kind of unit',
                    type: 'string',
                    name: 'kindOfUnit'
                  }
                ],
                label: 'Unit type',
                type: 'object',
                name: 'unitType'
              },
              {
                control_type: 'text',
                label: 'Initial value',
                type: 'string',
                name: 'initialValue'
              },
              {
                control_type: 'text',
                label: 'Max carry over value option',
                type: 'string',
                name: 'maxCarryOverValueOption'
              },
              {
                name: 'thresholdProfileGroupIdList',
                type: 'array',
                of: 'string',
                control_type: 'text',
                label: 'Threshold profile group ID list'
              }
            ]
          },
          {
            name: 'passes',
            type: 'array',
            of: 'object',
            label: 'Passes',
            properties: [
              {
                properties: [
                  {
                    control_type: 'text',
                    label: 'Name',
                    type: 'string',
                    name: 'name'
                  },
                  {
                    control_type: 'text',
                    label: 'ID',
                    type: 'string',
                    name: 'id'
                  },
                  {
                    name: 'rules',
                    type: 'array',
                    of: 'object',
                    label: 'Rules',
                    properties: [
                      {
                        control_type: 'text',
                        label: 'Name',
                        type: 'string',
                        name: 'name'
                      },
                      {
                        control_type: 'text',
                        label: 'Description',
                        type: 'string',
                        name: 'description'
                      },
                      {
                        control_type: 'text',
                        label: 'Condition container',
                        type: 'string',
                        name: 'conditionContainer'
                      },
                      {
                        name: 'actions',
                        type: 'array',
                        of: 'object',
                        label: 'Actions',
                        properties: [
                          {
                            properties: [
                              {
                                control_type: 'text',
                                label: 'Result context',
                                type: 'string',
                                name: 'resultContext'
                              },
                              {
                                control_type: 'text',
                                label: 'Name',
                                type: 'string',
                                name: 'name'
                              }
                            ],
                            label: 'Attribute info',
                            type: 'object',
                            name: 'attributeInfo'
                          },
                          {
                            name: 'parameters',
                            type: 'array',
                            of: 'object',
                            label: 'Parameters',
                            properties: [
                              {
                                control_type: 'text',
                                label: 'Name',
                                type: 'string',
                                name: 'name'
                              },
                              {
                                properties: [
                                  {
                                    control_type: 'text',
                                    label: 'Adjust operator',
                                    type: 'string',
                                    name: 'adjustOperator'
                                  },
                                  {
                                    properties: [
                                      {
                                        control_type: 'text',
                                        label: 'Type',
                                        type: 'string',
                                        name: 'type'
                                      },
                                      {
                                        control_type: 'text',
                                        label: 'Value',
                                        type: 'string',
                                        name: 'value'
                                      }
                                    ],
                                    label: 'Data',
                                    type: 'object',
                                    name: 'data'
                                  }
                                ],
                                label: 'Value',
                                type: 'object',
                                name: 'value'
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  }
                ],
                label: 'Tariff',
                type: 'object',
                name: 'tariff'
              }
            ]
          }
        ]
      end
    },

    device: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            control_type: 'text',
            label: 'Modified by',
            type: 'string',
            name: 'modifiedBy'
          },
          {
            control_type: 'number',
            label: 'Modified date',
            type: 'number',
            name: 'modifiedDate'
          },
          {
            control_type: 'text',
            label: 'Security domain',
            type: 'string',
            name: 'securityDomain'
          },
          {
            properties: [
              {
                name: 'entry',
                type: 'array',
                of: 'object',
                label: 'Entry',
                properties: [
                  {
                    control_type: 'text',
                    label: 'Key',
                    type: 'string',
                    name: 'key'
                  },
                  {
                    control_type: 'text',
                    label: 'Value',
                    type: 'string',
                    name: 'value'
                  }
                ]
              }
            ],
            label: 'Life cycle names',
            type: 'object',
            name: 'lifeCycleNames'
          },
          {
            properties: [
              {
                name: 'entry',
                type: 'array',
                of: 'object',
                label: 'Entry',
                properties: [
                  {
                    control_type: 'text',
                    label: 'Key',
                    type: 'string',
                    name: 'key'
                  },
                  {
                    properties: [
                      {
                        control_type: 'checkbox',
                        label: 'Barring',
                        toggle_hint: 'Select from option list',
                        toggle_field: {
                          label: 'Barring',
                          control_type: 'text',
                          toggle_hint: 'Use custom value',
                          type: 'boolean',
                          name: 'barring'
                        },
                        type: 'boolean',
                        name: 'barring'
                      },
                      {
                        control_type: 'text',
                        label: 'ID',
                        type: 'string',
                        name: 'id'
                      },
                      {
                        control_type: 'checkbox',
                        label: 'Initial',
                        toggle_hint: 'Select from option list',
                        toggle_field: {
                          label: 'Initial',
                          control_type: 'text',
                          toggle_hint: 'Use custom value',
                          type: 'boolean',
                          name: 'initial'
                        },
                        type: 'boolean',
                        name: 'initial'
                      },
                      {
                        control_type: 'text',
                        label: 'Name',
                        type: 'string',
                        name: 'name'
                      },
                      {
                        control_type: 'checkbox',
                        label: 'Final',
                        toggle_hint: 'Select from option list',
                        toggle_field: {
                          label: 'Final',
                          control_type: 'text',
                          toggle_hint: 'Use custom value',
                          type: 'boolean',
                          name: 'final'
                        },
                        type: 'boolean',
                        name: 'final'
                      }
                    ],
                    label: 'Value',
                    type: 'object',
                    name: 'value'
                  }
                ]
              }
            ],
            label: 'States',
            type: 'object',
            name: 'states'
          },
          {
            name: 'categoryList',
            type: 'array',
            of: 'string',
            control_type: 'text',
            label: 'Category list'
          },
          {
            control_type: 'text',
            label: 'Password',
            type: 'string',
            name: 'password'
          },
          {
            control_type: 'checkbox',
            label: 'Pwd encrypted',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Pwd encrypted',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'pwdEncrypted'
            },
            type: 'boolean',
            name: 'pwdEncrypted'
          },
          {
            control_type: 'checkbox',
            label: 'Sy OCS enabled',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Sy OCS enabled',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'syOCSEnabled'
            },
            type: 'boolean',
            name: 'syOCSEnabled'
          },
          {
            control_type: 'text',
            label: 'Allow overage',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Allow overage',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'allowOverage'
            },
            type: 'boolean',
            name: 'allowOverage'
          },
          {
            control_type: 'checkbox',
            label: 'Do not disconnect',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Do not disconnect',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'doNotDisconnect'
            },
            type: 'boolean',
            name: 'doNotDisconnect'
          },
          {
            control_type: 'text',
            label: 'Ocs host',
            type: 'string',
            name: 'ocsHost'
          },
          {
            control_type: 'text',
            label: 'Ocs realm',
            type: 'string',
            name: 'ocsRealm'
          },
          {
            control_type: 'text',
            label: 'Owning realm',
            type: 'string',
            name: 'owningRealm'
          },
          {
            control_type: 'text',
            label: 'Time of day',
            type: 'string',
            name: 'timeOfDay'
          },
          {
            control_type: 'text',
            label: 'Device type',
            type: 'string',
            name: 'deviceType'
          },
          {
            name: 'identities',
            type: 'array',
            of: 'object',
            label: 'Identities',
            properties: [
              {
                control_type: 'text',
                label: 'Identity type',
                type: 'string',
                name: 'identityType',
                optional: false
              },
              {
                control_type: 'text',
                label: 'Value',
                type: 'string',
                name: 'value',
                optional: false
              }
            ]
          },
          {
            control_type: 'text',
            label: 'ID',
            type: 'string',
            name: 'id'
          },
          {
            control_type: 'number',
            label: 'Creation time',
            type: 'number',
            name: 'creationTime'
          },
          {
            control_type: 'number',
            label: 'Last update time',
            type: 'number',
            name: 'lastUpdateTime'
          },
          {
            name: 'owner',
            label: 'owner',
            type: 'object',
            properties: [{
              name: 'id',
              label: 'ID'
            }]
          },
          {
            name: 'customData',
            label: 'Custom data',
            type: 'object',
            properties: [
              {
                name: 'entry',
                type: 'array',
                of: 'object',
                label: 'Entry',
                properties: [
                  {
                    control_type: 'text',
                    label: 'Key',
                    type: 'string',
                    name: 'key'
                  },
                  {
                    properties: [
                      {
                        control_type: 'text',
                        label: 'Type',
                        type: 'string',
                        name: 'type'
                      },
                      {
                        control_type: 'text',
                        label: 'Value',
                        type: 'string',
                        name: 'value'
                      }
                    ],
                    label: 'Value',
                    type: 'object',
                    name: 'value'
                  }
                ]
              }
            ]
          },
          {
            control_type: 'number',
            label: 'Subscription index',
            type: 'number',
            name: 'subscriptionIndex'
          },
          {
            control_type: 'text',
            label: 'Notification profile',
            type: 'string',
            name: 'notificationProfile'
          },
          {
            control_type: 'text',
            label: 'Me name',
            type: 'string',
            name: 'meName'
          },
          {
            properties: [
              {
                name: 'sessionSummaries',
                type: 'array',
                of: 'object',
                label: 'Session summaries',
                properties: [
                  {
                    control_type: 'text',
                    label: 'Site name',
                    type: 'string',
                    name: 'siteName'
                  },
                  {
                    control_type: 'number',
                    label: 'All session count',
                    type: 'number',
                    name: 'allSessionCount'
                  },
                  {
                    control_type: 'number',
                    label: 'Af session count',
                    type: 'number',
                    name: 'afSessionCount'
                  },
                  {
                    control_type: 'number',
                    label: 'Ip can session count',
                    type: 'number',
                    name: 'ipCanSessionCount'
                  },
                  {
                    control_type: 'number',
                    label: 'Sy session count',
                    type: 'number',
                    name: 'sySessionCount'
                  },
                  {
                    control_type: 'number',
                    label: 'Sd session count',
                    type: 'number',
                    name: 'sdSessionCount'
                  },
                  {
                    control_type: 'number',
                    label: 'Gy session count',
                    type: 'number',
                    name: 'gySessionCount'
                  },
                  {
                    control_type: 'number',
                    label: 'S 9 session count',
                    type: 'number',
                    name: 's9SessionCount'
                  },
                  {
                    control_type: 'number',
                    label: 'Nas REQ sessioncount',
                    type: 'number',
                    name: 'nasREQSessioncount'
                  }
                ]
              }
            ],
            label: 'Sesson container',
            type: 'object',
            name: 'sessonContainer'
          },
          {
            control_type: 'checkbox',
            label: 'Report activation required',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Report activation required',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'reportActivationRequired'
            },
            type: 'boolean',
            name: 'reportActivationRequired'
          },
          {
            control_type: 'number',
            label: 'Off line time stamp',
            type: 'number',
            name: 'offLineTimeStamp'
          },
          {
            control_type: 'checkbox',
            label: 'Detailed query',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Detailed query',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'detailedQuery'
            },
            type: 'boolean',
            name: 'detailedQuery'
          },
          {
            control_type: 'text',
            label: 'Counter instances list',
            type: 'string',
            name: 'counterInstancesList'
          },
          {
            control_type: 'text',
            label: 'Bucket definition map',
            type: 'string',
            name: 'bucketDefinitionMap'
          }
        ]
      end
    },

    group: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            control_type: 'text',
            label: 'Modified by',
            type: 'string',
            name: 'modifiedBy'
          },
          {
            control_type: 'number',
            label: 'Modified date',
            type: 'number',
            name: 'modifiedDate'
          },
          {
            control_type: 'text',
            label: 'Security domain',
            type: 'string',
            name: 'securityDomain'
          },

          {
            properties: [
              {
                name: 'entry',
                type: 'array',
                of: 'object',
                label: 'Entry',
                properties: [
                  {
                    control_type: 'text',
                    label: 'Key',
                    type: 'string',
                    name: 'key'
                  },
                  {
                    control_type: 'text',
                    label: 'Value',
                    type: 'string',
                    name: 'value'
                  }
                ]
              }
            ],
            label: 'Life cycle names',
            type: 'object',
            name: 'lifeCycleNames'
          },
          {
            properties: [
              {
                name: 'entry',
                type: 'array',
                of: 'object',
                label: 'Entry',
                properties: [
                  {
                    control_type: 'text',
                    label: 'Key',
                    type: 'string',
                    name: 'key'
                  },
                  {
                    properties: [
                      {
                        control_type: 'checkbox',
                        label: 'Barring',
                        toggle_hint: 'Select from option list',
                        toggle_field: {
                          label: 'Barring',
                          control_type: 'text',
                          toggle_hint: 'Use custom value',
                          type: 'boolean',
                          name: 'barring'
                        },
                        type: 'boolean',
                        name: 'barring'
                      },
                      {
                        control_type: 'text',
                        label: 'ID',
                        type: 'string',
                        name: 'id'
                      },
                      {
                        control_type: 'checkbox',
                        label: 'Initial',
                        toggle_hint: 'Select from option list',
                        toggle_field: {
                          label: 'Initial',
                          control_type: 'text',
                          toggle_hint: 'Use custom value',
                          type: 'boolean',
                          name: 'initial'
                        },
                        type: 'boolean',
                        name: 'initial'
                      },
                      {
                        control_type: 'text',
                        label: 'Name',
                        type: 'string',
                        name: 'name'
                      },
                      {
                        control_type: 'checkbox',
                        label: 'Final',
                        toggle_hint: 'Select from option list',
                        toggle_field: {
                          label: 'Final',
                          control_type: 'text',
                          toggle_hint: 'Use custom value',
                          type: 'boolean',
                          name: 'final'
                        },
                        type: 'boolean',
                        name: 'final'
                      }
                    ],
                    label: 'Value',
                    type: 'object',
                    name: 'value'
                  }
                ]
              }
            ],
            label: 'States',
            type: 'object',
            name: 'states'
          },
          {
            control_type: 'text',
            label: 'ID',
            type: 'string',
            name: 'id'
          },
          {
            control_type: 'text',
            label: 'Name',
            type: 'string',
            name: 'name'
          },
          {
            control_type: 'text',
            label: 'Administrators',
            type: 'array',
            of: 'object',
            properties: [{ name: 'id' }],
            name: 'administrators'
          },
          {
            control_type: 'text',
            label: 'notificationProfile',
            type: 'string',
            name: 'notificationProfile'
          },
          {
            control_type: 'number',
            label: 'Creation time',
            type: 'number',
            name: 'creationTime'
          },
          {
            control_type: 'number',
            label: 'Last update time',
            type: 'number',
            name: 'lastUpdateTime'
          },
          {
            properties: [],
            label: 'Custom data',
            type: 'object',
            name: 'customData'
          },
          {
            name: 'devices',
            label: 'Devices',
            type: 'array',
            of: 'object',
            properties: [{ name: 'id', optional: false }]
          },
          {
            control_type: 'text',
            label: 'Parent',
            type: 'string',
            name: 'parent'
          },
          {
            control_type: 'text',
            label: 'Child device ids',
            type: 'string',
            name: 'childDeviceIds'
          },
          {
            control_type: 'text',
            label: 'Child group ids',
            type: 'string',
            name: 'childGroupIds'
          },
          {
            control_type: 'text',
            label: 'Traversal order',
            type: 'string',
            name: 'traversalOrder'
          },
          {
            control_type: 'checkbox',
            label: 'Report activation required',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Report activation required',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'reportActivationRequired'
            },
            type: 'boolean',
            name: 'reportActivationRequired'
          },
          {
            control_type: 'checkbox',
            label: 'Group report activation',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Group report activation',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'groupReportActivation'
            },
            type: 'boolean',
            name: 'groupReportActivation'
          },
          {
            control_type: 'checkbox',
            label: 'Device group report activation',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Device group report activation',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'deviceGroupReportActivation'
            },
            type: 'boolean',
            name: 'deviceGroupReportActivation'
          },
          {
            control_type: 'text',
            label: 'Me name',
            type: 'string',
            name: 'meName'
          },
          {
            name: 'subscriptions',
            type: 'array',
            of: 'object',
            label: 'Subscriptions',
            properties: [
              {
                control_type: 'text',
                label: 'Modified by',
                type: 'string',
                name: 'modifiedBy'
              },
              {
                control_type: 'number',
                label: 'Modified date',
                type: 'number',
                name: 'modifiedDate'
              },
              {
                control_type: 'text',
                label: 'Security domain',
                type: 'string',
                name: 'securityDomain'
              },
              {
                properties: [
                  {
                    name: 'entry',
                    type: 'array',
                    of: 'object',
                    label: 'Entry',
                    properties: [
                      {
                        control_type: 'text',
                        label: 'Key',
                        type: 'string',
                        name: 'key'
                      },
                      {
                        control_type: 'text',
                        label: 'Value',
                        type: 'string',
                        name: 'value'
                      }
                    ]
                  }
                ],
                label: 'Life cycle names',
                type: 'object',
                name: 'lifeCycleNames'
              },
              {
                properties: [
                  {
                    name: 'entry',
                    type: 'array',
                    of: 'object',
                    label: 'Entry',
                    properties: [
                      {
                        control_type: 'text',
                        label: 'Key',
                        type: 'string',
                        name: 'key'
                      },
                      {
                        properties: [
                          {
                            control_type: 'checkbox',
                            label: 'Barring',
                            toggle_hint: 'Select from option list',
                            toggle_field: {
                              label: 'Barring',
                              control_type: 'text',
                              toggle_hint: 'Use custom value',
                              type: 'boolean',
                              name: 'barring'
                            },
                            type: 'boolean',
                            name: 'barring'
                          },
                          {
                            control_type: 'text',
                            label: 'ID',
                            type: 'string',
                            name: 'id'
                          },
                          {
                            control_type: 'checkbox',
                            label: 'Initial',
                            toggle_hint: 'Select from option list',
                            toggle_field: {
                              label: 'Initial',
                              control_type: 'text',
                              toggle_hint: 'Use custom value',
                              type: 'boolean',
                              name: 'initial'
                            },
                            type: 'boolean',
                            name: 'initial'
                          },
                          {
                            control_type: 'text',
                            label: 'Name',
                            type: 'string',
                            name: 'name'
                          },
                          {
                            control_type: 'checkbox',
                            label: 'Final',
                            toggle_hint: 'Select from option list',
                            toggle_field: {
                              label: 'Final',
                              control_type: 'text',
                              toggle_hint: 'Use custom value',
                              type: 'boolean',
                              name: 'final'
                            },
                            type: 'boolean',
                            name: 'final'
                          }
                        ],
                        label: 'Value',
                        type: 'object',
                        name: 'value'
                      }
                    ]
                  }
                ],
                label: 'States',
                type: 'object',
                name: 'states'
              },
              {
                control_type: 'text',
                label: 'End time',
                type: 'string',
                name: 'endTime'
              },
              {
                control_type: 'text',
                label: 'Start time',
                type: 'number',
                name: 'startTime'
              },
              {
                control_type: 'text',
                label: 'ID',
                type: 'string',
                name: 'id'
              },
              {
                properties: [
                  {
                    control_type: 'text',
                    label: 'Modified by',
                    type: 'string',
                    name: 'modifiedBy'
                  },
                  {
                    control_type: 'number',
                    label: 'Modified date',
                    type: 'number',
                    name: 'modifiedDate'
                  },
                  {
                    control_type: 'text',
                    label: 'Security domain',
                    type: 'string',
                    name: 'securityDomain'
                  },
                  {
                    control_type: 'text',
                    label: 'Sm prov state',
                    type: 'string',
                    name: 'smProvState'
                  },
                  {
                    control_type: 'text',
                    label: 'Name',
                    type: 'string',
                    name: 'name'
                  },
                  {
                    control_type: 'text',
                    label: 'Fee',
                    type: 'string',
                    name: 'fee'
                  },
                  {
                    control_type: 'text',
                    label: 'Life cycle names',
                    type: 'string',
                    name: 'lifeCycleNames'
                  },
                  {
                    control_type: 'text',
                    label: 'Max renewals',
                    type: 'string',
                    name: 'maxRenewals'
                  },
                  {
                    control_type: 'text',
                    label: 'Fee per device',
                    type: 'string',
                    name: 'feePerDevice'
                  }
                ],
                label: 'Bundle',
                type: 'object',
                name: 'bundle'
              },
              {
                properties: [
                  {
                    control_type: 'text',
                    label: 'Modified by',
                    type: 'string',
                    name: 'modifiedBy'
                  },
                  {
                    control_type: 'number',
                    label: 'Modified date',
                    type: 'number',
                    name: 'modifiedDate'
                  },
                  {
                    control_type: 'text',
                    label: 'Security domain',
                    type: 'string',
                    name: 'securityDomain'
                  },
                  {
                    label: 'Life cycle names',
                    type: 'object',
                    name: 'lifeCycleNames'
                  },
                  {
                    label: 'States',
                    type: 'object',
                    name: 'states'
                  },
                  {
                    control_type: 'text',
                    label: 'End time',
                    type: 'string',
                    name: 'endTime'
                  },
                  {
                    control_type: 'text',
                    label: 'Start time',
                    type: 'number',
                    name: 'startTime'
                  },
                  {
                    control_type: 'text',
                    label: 'ID',
                    type: 'string',
                    name: 'id'
                  },
                  {
                    control_type: 'number',
                    label: 'Hour of day',
                    type: 'number',
                    name: 'hourOfDay'
                  },
                  {
                    control_type: 'text',
                    label: 'Day of week',
                    type: 'string',
                    name: 'dayOfWeek'
                  },
                  {
                    control_type: 'number',
                    label: 'Day of month',
                    type: 'number',
                    name: 'dayOfMonth'
                  },
                  {
                    control_type: 'text',
                    label: 'Time zone ID',
                    type: 'string',
                    name: 'timeZoneId'
                  },
                  {
                    control_type: 'text',
                    label: 'Creation time',
                    type: 'string',
                    name: 'creationTime'
                  },
                  {
                    control_type: 'text',
                    label: 'Last update time',
                    type: 'string',
                    name: 'lastUpdateTime'
                  },
                  {
                    control_type: 'number',
                    label: 'Overage limit',
                    type: 'number',
                    name: 'overageLimit'
                  },
                  {
                    control_type: 'text',
                    label: 'Me name',
                    type: 'string',
                    name: 'meName'
                  },
                  {
                    properties: [],
                    label: 'Custom data',
                    type: 'object',
                    name: 'customData'
                  },
                  {
                    control_type: 'text',
                    label: 'Account type',
                    type: 'string',
                    name: 'accountType'
                  },
                  {
                    control_type: 'text',
                    label: 'Administrators',
                    type: 'string',
                    name: 'administrators'
                  },
                  {
                    name: 'devices',
                    label: 'Devices',
                    type: 'array',
                    of: 'object',
                    properties: [{ name: 'id' }]
                  },
                  {
                    control_type: 'text',
                    label: 'Groups',
                    type: 'string',
                    name: 'groups'
                  },
                  {
                    control_type: 'checkbox',
                    label: 'Detailed query',
                    toggle_hint: 'Select from option list',
                    toggle_field: {
                      label: 'Detailed query',
                      control_type: 'text',
                      toggle_hint: 'Use custom value',
                      type: 'boolean',
                      name: 'detailedQuery'
                    },
                    type: 'boolean',
                    name: 'detailedQuery'
                  },
                  {
                    control_type: 'number',
                    label: 'Account balance',
                    type: 'number',
                    name: 'accountBalance'
                  },
                  {
                    control_type: 'text',
                    label: 'Subscriptions',
                    type: 'string',
                    name: 'subscriptions'
                  },
                  {
                    control_type: 'text',
                    label: 'Bucket instance map',
                    type: 'string',
                    name: 'bucketInstanceMap'
                  },
                  {
                    control_type: 'text',
                    label: 'Bucket definition map',
                    type: 'string',
                    name: 'bucketDefinitionMap'
                  },
                  {
                    control_type: 'text',
                    label: 'User par map',
                    type: 'string',
                    name: 'userParMap'
                  },
                  {
                    control_type: 'text',
                    label: 'Device',
                    type: 'string',
                    name: 'device'
                  },
                  {
                    control_type: 'text',
                    label: 'Group',
                    type: 'string',
                    name: 'group'
                  },
                  {
                    control_type: 'text',
                    label: 'Entity counter instances',
                    type: 'string',
                    name: 'entityCounterInstances'
                  }
                ],
                label: 'Account',
                type: 'object',
                name: 'account'
              },
              {
                name: 'chargingServiceInstanceList',
                type: 'array',
                of: 'object',
                label: 'Charging service instance list',
                properties: [
                  {
                    name: 'bucketInfoList',
                    type: 'array',
                    of: 'object',
                    label: 'Bucket info list',
                    properties: [
                      {
                        control_type: 'text',
                        label: 'Bkt def name',
                        type: 'string',
                        name: 'bktDefName'
                      },
                      {
                        control_type: 'text',
                        label: 'Bkt inst ID',
                        type: 'string',
                        name: 'bktInstId'
                      },
                      {
                        properties: [
                          {
                            control_type: 'text',
                            label: 'Modified by',
                            type: 'string',
                            name: 'modifiedBy'
                          },
                          {
                            control_type: 'number',
                            label: 'Modified date',
                            type: 'number',
                            name: 'modifiedDate'
                          },
                          {
                            control_type: 'text',
                            label: 'Security domain',
                            type: 'string',
                            name: 'securityDomain'
                          },
                          {
                            control_type: 'text',
                            label: 'Sm prov state',
                            type: 'string',
                            name: 'smProvState'
                          },
                          {
                            control_type: 'text',
                            label: 'Unit type name',
                            type: 'string',
                            name: 'unitTypeName'
                          },
                          {
                            control_type: 'text',
                            label: 'Kind of unit',
                            type: 'string',
                            name: 'kindOfUnit'
                          },
                          {
                            control_type: 'text',
                            label: 'Short name',
                            type: 'string',
                            name: 'shortName'
                          },
                          {
                            control_type: 'checkbox',
                            label: 'Default unit',
                            toggle_hint: 'Select from option list',
                            toggle_field: {
                              label: 'Default unit',
                              control_type: 'text',
                              toggle_hint: 'Use custom value',
                              type: 'boolean',
                              name: 'defaultUnit'
                            },
                            type: 'boolean',
                            name: 'defaultUnit'
                          },
                          {
                            control_type: 'checkbox',
                            label: 'Default SM unit',
                            toggle_hint: 'Select from option list',
                            toggle_field: {
                              label: 'Default SM unit',
                              control_type: 'text',
                              toggle_hint: 'Use custom value',
                              type: 'boolean',
                              name: 'defaultSMUnit'
                            },
                            type: 'boolean',
                            name: 'defaultSMUnit'
                          },
                          {
                            control_type: 'text',
                            label: 'Type converter',
                            type: 'string',
                            name: 'typeConverter'
                          }
                        ],
                        label: 'Bkt unit type',
                        type: 'object',
                        name: 'bktUnitType'
                      }
                    ]
                  },
                  {
                    control_type: 'text',
                    label: 'Charging service def ref',
                    type: 'string',
                    name: 'chargingServiceDefRef'
                  }
                ]
              },
              {
                control_type: 'number',
                label: 'Creation time',
                type: 'number',
                name: 'creationTime'
              },
              {
                control_type: 'text',
                label: 'Fee override',
                type: 'string',
                name: 'feeOverride'
              },
              {
                name: 'groups',
                type: 'array',
                of: 'object',
                label: 'Groups',
                properties: [
                  {
                    control_type: 'text',
                    label: 'Modified by',
                    type: 'string',
                    name: 'modifiedBy'
                  },
                  {
                    control_type: 'number',
                    label: 'Modified date',
                    type: 'number',
                    name: 'modifiedDate'
                  },
                  {
                    control_type: 'text',
                    label: 'Security domain',
                    type: 'string',
                    name: 'securityDomain'
                  },
                  {
                    properties: [],
                    label: 'Life cycle names',
                    type: 'object',
                    name: 'lifeCycleNames'
                  },
                  {
                    properties: [],
                    label: 'States',
                    type: 'object',
                    name: 'states'
                  },
                  {
                    control_type: 'text',
                    label: 'ID',
                    type: 'string',
                    name: 'id'
                  },
                  {
                    control_type: 'text',
                    label: 'Name',
                    type: 'string',
                    name: 'name'
                  },
                  {
                    control_type: 'text',
                    label: 'Creation time',
                    type: 'string',
                    name: 'creationTime'
                  },
                  {
                    control_type: 'text',
                    label: 'Last update time',
                    type: 'string',
                    name: 'lastUpdateTime'
                  },
                  {
                    properties: [],
                    label: 'Custom data',
                    type: 'object',
                    name: 'customData'
                  },
                  {
                    control_type: 'text',
                    label: 'Parent',
                    type: 'string',
                    name: 'parent'
                  },
                  {
                    control_type: 'text',
                    label: 'Child device ids',
                    type: 'string',
                    name: 'childDeviceIds'
                  },
                  {
                    control_type: 'text',
                    label: 'Child group ids',
                    type: 'string',
                    name: 'childGroupIds'
                  },
                  {
                    control_type: 'text',
                    label: 'Traversal order',
                    type: 'string',
                    name: 'traversalOrder'
                  },
                  {
                    control_type: 'checkbox',
                    label: 'Report activation required',
                    toggle_hint: 'Select from option list',
                    toggle_field: {
                      label: 'Report activation required',
                      control_type: 'text',
                      toggle_hint: 'Use custom value',
                      type: 'boolean',
                      name: 'reportActivationRequired'
                    },
                    type: 'boolean',
                    name: 'reportActivationRequired'
                  },
                  {
                    control_type: 'checkbox',
                    label: 'Group report activation',
                    toggle_hint: 'Select from option list',
                    toggle_field: {
                      label: 'Group report activation',
                      control_type: 'text',
                      toggle_hint: 'Use custom value',
                      type: 'boolean',
                      name: 'groupReportActivation'
                    },
                    type: 'boolean',
                    name: 'groupReportActivation'
                  },
                  {
                    control_type: 'checkbox',
                    label: 'Device group report activation',
                    toggle_hint: 'Select from option list',
                    toggle_field: {
                      label: 'Device group report activation',
                      control_type: 'text',
                      toggle_hint: 'Use custom value',
                      type: 'boolean',
                      name: 'deviceGroupReportActivation'
                    },
                    type: 'boolean',
                    name: 'deviceGroupReportActivation'
                  },
                  {
                    control_type: 'text',
                    label: 'Me name',
                    type: 'string',
                    name: 'meName'
                  },
                  {
                    control_type: 'checkbox',
                    label: 'Detailed query',
                    toggle_hint: 'Select from option list',
                    toggle_field: {
                      label: 'Detailed query',
                      control_type: 'text',
                      toggle_hint: 'Use custom value',
                      type: 'boolean',
                      name: 'detailedQuery'
                    },
                    type: 'boolean',
                    name: 'detailedQuery'
                  },
                  {
                    control_type: 'text',
                    label: 'Counter instances list',
                    type: 'string',
                    name: 'counterInstancesList'
                  },
                  {
                    control_type: 'text',
                    label: 'Bucket definition map',
                    type: 'string',
                    name: 'bucketDefinitionMap'
                  }
                ]
              },
              {
                control_type: 'checkbox',
                label: 'Ignore barred account',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  label: 'Ignore barred account',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean',
                  name: 'ignoreBarredAccount'
                },
                type: 'boolean',
                name: 'ignoreBarredAccount'
              },
              {
                control_type: 'text',
                label: 'Invoked by',
                type: 'string',
                name: 'invokedBy'
              },
              {
                control_type: 'text',
                label: 'Remaining renewals',
                type: 'string',
                name: 'remainingRenewals'
              },
              {
                control_type: 'text',
                label: 'Renewal mode',
                type: 'string',
                name: 'renewalMode'
              },
              {
                control_type: 'text',
                label: 'Subscription type',
                type: 'string',
                name: 'subscriptionType'
              },
              {
                control_type: 'text',
                label: 'Transition name',
                type: 'string',
                name: 'transitionName'
              }
            ]
          },
          {
            control_type: 'checkbox',
            label: 'Detailed query',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Detailed query',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'detailedQuery'
            },
            type: 'boolean',
            name: 'detailedQuery'
          },
          {
            control_type: 'text',
            label: 'Counter instances list',
            type: 'string',
            name: 'counterInstancesList'
          },
          {
            control_type: 'text',
            label: 'Bucket definition map',
            type: 'string',
            name: 'bucketDefinitionMap'
          },
          {
            name: 'bucketInstancesList',
            type: 'array',
            of: 'object',
            properties: [
              { name: 'id' },
              { name: 'bucketDefId' },
              {
                control_type: 'number',
                type: 'number',
                name: 'initialValue'
              },
              {
                control_type: 'number',
                type: 'number',
                name: 'currentValue'
              }
            ]
          }
        ]
      end
    },

    user: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            control_type: 'text',
            label: 'Modified by',
            type: 'string',
            name: 'modifiedBy'
          },
          {
            control_type: 'number',
            label: 'Modified date',
            type: 'number',
            name: 'modifiedDate'
          },
          {
            control_type: 'text',
            label: 'Security domain',
            type: 'string',
            name: 'securityDomain'
          },
          {
            properties: [
              {
                name: 'entry',
                type: 'array',
                of: 'object',
                label: 'Entry',
                properties: [
                  {
                    control_type: 'text',
                    label: 'Key',
                    type: 'string',
                    name: 'key'
                  },
                  {
                    control_type: 'text',
                    label: 'Value',
                    type: 'string',
                    name: 'value'
                  }
                ]
              }
            ],
            label: 'Life cycle names',
            type: 'object',
            name: 'lifeCycleNames'
          },
          {
            properties: [
              {
                name: 'entry',
                type: 'array',
                of: 'object',
                label: 'Entry',
                properties: [
                  {
                    control_type: 'text',
                    label: 'Key',
                    type: 'string',
                    name: 'key'
                  },
                  {
                    properties: [
                      {
                        control_type: 'checkbox',
                        label: 'Barring',
                        toggle_hint: 'Select from option list',
                        toggle_field: {
                          label: 'Barring',
                          control_type: 'text',
                          toggle_hint: 'Use custom value',
                          type: 'boolean',
                          name: 'barring'
                        },
                        type: 'boolean',
                        name: 'barring'
                      },
                      {
                        control_type: 'text',
                        label: 'ID',
                        type: 'string',
                        name: 'id'
                      },
                      {
                        control_type: 'checkbox',
                        label: 'Initial',
                        toggle_hint: 'Select from option list',
                        toggle_field: {
                          label: 'Initial',
                          control_type: 'text',
                          toggle_hint: 'Use custom value',
                          type: 'boolean',
                          name: 'initial'
                        },
                        type: 'boolean',
                        name: 'initial'
                      },
                      {
                        control_type: 'text',
                        label: 'Name',
                        type: 'string',
                        name: 'name'
                      },
                      {
                        control_type: 'checkbox',
                        label: 'Final',
                        toggle_hint: 'Select from option list',
                        toggle_field: {
                          label: 'Final',
                          control_type: 'text',
                          toggle_hint: 'Use custom value',
                          type: 'boolean',
                          name: 'final'
                        },
                        type: 'boolean',
                        name: 'final'
                      }
                    ],
                    label: 'Value',
                    type: 'object',
                    name: 'value'
                  }
                ]
              }
            ],
            label: 'States',
            type: 'object',
            name: 'states'
          },
          {
            control_type: 'text',
            label: 'Notification profile',
            type: 'string',
            name: 'notificationProfile'
          },
          {
            control_type: 'text',
            label: 'ID',
            type: 'string',
            name: 'id'
          },
          {
            control_type: 'text',
            label: 'Surname',
            type: 'string',
            name: 'surname'
          },
          {
            control_type: 'text',
            label: 'Given name',
            type: 'string',
            name: 'givenName'
          },
          {
            control_type: 'text',
            label: 'Corporation name',
            type: 'string',
            name: 'corporationName'
          },
          {
            name: 'phoneNumbers',
            type: 'array',
            of: 'string',
            control_type: 'text',
            label: 'Phone numbers'
          },
          {
            name: 'emails',
            type: 'array',
            of: 'string',
            control_type: 'text',
            label: 'Emails'
          },
          {
            control_type: 'text',
            label: 'Facebook ID',
            type: 'string',
            name: 'facebookId'
          },
          {
            control_type: 'number',
            label: 'Creation time',
            type: 'integer',
            name: 'creationTime'
          },
          {
            control_type: 'text',
            label: 'Last update time',
            type: 'string',
            name: 'lastUpdateTime'
          },
          {
            properties: [],
            label: 'Custom data',
            type: 'object',
            name: 'customData'
          },
          {
            control_type: 'text',
            label: 'Account ID',
            type: 'string',
            name: 'accountId'
          },
          {
            control_type: 'text',
            label: 'Me name',
            type: 'string',
            name: 'meName'
          }
        ]
      end
    }
  },

  actions: {
    create_account: {
      description: 'Create <span class="provider">account</span> ' \
        'in <span class="provider">Nokia SPS</span>',

      execute: lambda do |_connection, input|
        post('/services/ServiceManager/subscriber/create/Account', input)
          .dig('responseStatus', 'data', 0)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['account']
          .ignored('modifiedBy', 'modifiedDate', 'creationTime',
                   'lastUpdateTime')
          .required('id', 'dayOfMonth', 'accountType')
      end,

      output_fields: ->(object_definitions) { object_definitions['account'] },

      sample_output: ->(_connection) { call('account_sample_output') }
    },

    get_account_by_id: {
      subtitle: 'Get account by ID',
      description: "Get <span class='provider'>account</span> " \
        "by ID in <span class='provider'>Nokia SPS</span>",
      help: 'Fetches the account, that matches the given ID. <br> ' \
            'Use "Error" data pill from the output to check the error ' \
            '(the record does not exist) message ',

      execute: lambda do |_connection, input|
        process_params = "{\"id\": \"#{input['id']}\", \"detailedQuery\": " \
                           "\"#{input['detailed_query']}\"}"
        get('/services/ServiceManager/subscriber/getData/Account',
            'processParams' => process_params)
          .after_error_response(404) do |_code, body, _header, message|
          if body.include? 'Record does not exist'
            [{ 'error' => body }]
          else
            error("#{message}: #{body}")
          end
        end[0]
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['account'].only('id').required('id') + [{
          control_type: 'checkbox',
          label: 'Detailed query',
          toggle_hint: 'Select from option list',
          toggle_field: {
            label: 'Detailed query',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            type: 'boolean',
            name: 'detailed_query'
          },
          sticky: true,
          type: 'boolean',
          name: 'detailed_query'
        }]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['account'] + [{ name: 'error' }]
      end,

      sample_output: ->(_connection) { call('account_sample_output') }
    },

    create_bundle: {
      description: 'Create <span class="provider">bundle</span> ' \
        'in <span class="provider">Nokia SPS</span>',

      execute: lambda do |_connection, input|
        input['chargingServiceList'] = [input['chargingServiceList']]
        post('/services/ServiceManager/create/Bundle',
             input)['responseStatus']
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['bundle']
          .ignored('modifiedBy', 'modifiedDate', 'creationTime',
                   'lastUpdateTime', 'chargingServiceList')
          .required('name', 'fee')
          .concat([{
                    name: 'chargingServiceList',
                    optional: false
                  }])
      end,

      output_fields: ->(_object_definitions) { [{ name: 'message' }] },

      sample_output: ->(_connection) { { 'message' => 'Success' } }
    },

    get_bundle_by_name: {
      subtitle: 'Get bundle by name',
      description: "Get <span class='provider'>bundle</span> " \
        "by name in <span class='provider'>Nokia SPS</span>",
      help: 'Fetches the account, that matches the given bundle name. <br> ' \
            'Use "Error" data pill from the output to check the error ' \
            '(the record does not exist) message ',

      execute: lambda do |_connection, input|
        process_params = "{\"name\":\"#{input['name']}\"}"
        get('/services/ServiceManager/getData/Bundle',
            'processParams' => process_params)
          .after_error_response(404) do |_code, body, _header, message|
          if body.include? 'Record does not exist'
            [{ 'error' => body }]
          else
            error("#{message}: #{body}")
          end
        end[0]
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['bundle'].only('name').required('name')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['bundle'] + [{ name: 'error' }]
      end,

      sample_output: ->(_connection) { call('bundle_sample_output') }
    },

    create_charging_service: {
      description: 'Create <span class="provider">charging service</span> ' \
        'in <span class="provider">Nokia SPS</span>',

      execute: lambda do |_connection, input|
        post('/services/ServiceManager/v18_7/create/ChargingService', input)
          .dig('responseStatus', 'data', 0)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['charging_service']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['charging_service']
      end,

      sample_output: lambda do |_connection|
        call('chargingservice_sample_output')
      end
    },

    create_device: {
      description: 'Create <span class="provider">device</span> ' \
        'in <span class="provider">Nokia SPS</span>',

      execute: lambda do |_connection, input|
        post('/services/ServiceManager/subscriber/create/Device', input)
          .dig('responseStatus', 'data', 0)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['device']
          .ignored('modifiedBy', 'modifiedDate', 'creationTime',
                   'lastUpdateTime')
          .required('id', 'identities')
      end,

      output_fields: ->(object_definitions) { object_definitions['device'] },

      sample_output: ->(_connection) { call('device_sample_output') }
    },

    get_device_by_id: {
      subtitle: 'Get device by ID',
      description: "Get <span class='provider'>device</span> " \
        "by ID in <span class='provider'>Nokia SPS</span>",
      help: 'Fetches the account, that matches the given ID. <br> ' \
            'Use "Error" data pill from the output to check the error ' \
            '(the record does not exist) message ',

      execute: lambda do |_connection, input|
        process_params = "{\"id\":\"#{input['id']}\"}"
        get('/services/ServiceManager/subscriber/getData/Device',
            'processParams' => process_params)
          .after_error_response(404) do |_code, body, _header, message|
          if body.include? 'Could not fetch record'
            [{ 'error' => body }]
          else
            error("#{message}: #{body}")
          end
        end[0]
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['device'].only('id').required('id')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['device'] + [{ name: 'error' }]
      end,

      sample_output: ->(_connection) { call('device_sample_output') }
    },

    create_group: {
      description: 'Create <span class="provider">group</span> ' \
        'in <span class="provider">Nokia SPS</span>',

      execute: lambda do |_connection, input|
        post('/services/ServiceManager/subscriber/create/Group', input)
          .dig('responseStatus', 'data', 0)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['group']
          .ignored('modifiedBy', 'modifiedDate', 'creationTime',
                   'lastUpdateTime')
          .required('id', 'name', 'devices')
      end,

      output_fields: ->(object_definitions) {  object_definitions['group'] },

      sample_output: ->(_connection) { call('group_sample_output') }
    },

    get_group_by_id: {
      subtitle: 'Get group by ID',
      description: "Get <span class='provider'>group</span> " \
        "by ID in <span class='provider'>Nokia SPS</span>",
      help: 'Fetches the account, that matches the given ID. <br> ' \
            'Use "Error" data pill from the output to check the error ' \
            '(the record does not exist) message ',

      execute: lambda do |_connection, input|
        process_params = "{\"id\": \"#{input['id']}\", \"detailedQuery\": " \
                           "\"#{input['detailed_query']}\"}"
        get('/services/ServiceManager/subscriber/getData/Group',
            'processParams' => process_params)
          .after_error_response(404) do |_code, body, _header, message|
          if body.include? 'Record does not exist'
            [{ 'error' => body }]
          else
            error("#{message}: #{body}")
          end
        end[0]
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['group'].only('id').required('id') + [{
          control_type: 'checkbox',
          label: 'Detailed query',
          toggle_hint: 'Select from option list',
          toggle_field: {
            label: 'Detailed query',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            type: 'boolean',
            name: 'detailed_query'
          },
          sticky: true,
          type: 'boolean',
          name: 'detailed_query'
        }]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['group'] + [{ name: 'error' }]
      end,

      sample_output: ->(_connection) { call('group_sample_output') }
    },

    update_group: {
      description: 'Update <span class="provider">group</span> ' \
        'in <span class="provider">Nokia SPS</span>',

      execute: lambda do |_connection, input|
        put('/services/ServiceManager/subscriber/update/Group', input)
          .dig('responseStatus', 'data', 0)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['group']
          .ignored('modifiedBy', 'modifiedDate', 'creationTime',
                   'lastUpdateTime', 'devices')
          .required('id')
          .concat([{
                    name: 'devices',
                    label: 'Devices',
                    type: 'array',
                    of: 'object',
                    properties: [{ name: 'id' }]
                  }])
      end,

      output_fields: ->(object_definitions) {  object_definitions['group'] },

      sample_output: ->(_connection) { call('group_sample_output') }
    },

    create_user: {
      description: 'Create <span class="provider">user</span> ' \
        'in <span class="provider">Nokia SPS</span>',

      execute: lambda do |_connection, input|
        input['phoneNumbers'] = [input['phoneNumbers']]
        input['emails'] = [input['emails']]
        post('/services/ServiceManager/subscriber/create/User', input)
          .dig('responseStatus', 'data', 0)
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['user']
          .ignored('modifiedBy', 'modifiedDate', 'creationTime',
                   'lastUpdateTime', 'phoneNumbers', 'emails')
          .required('id', 'accountId', 'surname', 'givenName', 'meName')
          .concat([
                    { name: 'phoneNumbers', optional: false },
                    { name: 'emails', control_type: 'email', optional: false }
                  ])
      end,

      output_fields: ->(object_definitions) { object_definitions['user'] },

      sample_output: ->(_connection) { call('user_sample_output') }
    },

    get_user_by_id: {
      subtitle: 'Get user by ID',
      description: "Get <span class='provider'>user</span> " \
        "by ID in <span class='provider'>Nokia SPS</span>",
      help: 'Fetches the account, that matches the given ID. <br> ' \
            'Use "Error" data pill from the output to check the error ' \
            '(the record does not exist) message ',

      execute: lambda do |_connection, input|
        process_params = "{\"id\":\"#{input['id']}\"}"
        get('/services/ServiceManager/subscriber/getData/User',
            'processParams' => process_params)
          .after_error_response(404) do |_code, body, _header, message|
          if body.include? 'Record does not exist'
            [{ 'error' => body }]
          else
            error("#{message}: #{body}")
          end
        end[0]
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['user'].only('id').required('id')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['user'] + [{ name: 'error' }]
      end,

      sample_output: ->(_connection) { call('user_sample_output') }
    }
  },

  pick_lists: {
    account_types: lambda do |_connection|
      [%w[Pre-Paid PRE_PAID], %w[Post-Paid POST_PAID]]
    end
  }
}
