{
  title: "Google Analytics",

  connection: {
    fields: [
      {
        name: "client_id",
        optional: false,
        hint: "Find your client ID <a href='https://console.developers." \
          "google.com/' target='_blank'>here</a>"
      },
      {
        name: "client_secret",
        control_type: "password",
        optional: false,
        hint: "Find your client secret <a href='https://console.developers." \
          "google.com/' target='_blank'>here</a>"
      }
    ],

    authorization: {
      type: "oauth2",

      authorization_url: lambda do |connection|
        scopes = ["https://www.googleapis.com/auth/analytics.readonly",
                  "https://www.googleapis.com/auth/analytics.edit",
                  "https://www.googleapis.com/auth/analytics"].join(" ")
        "https://accounts.google.com/o/oauth2/auth?client_id=" \
         "#{connection['client_id']}&response_type=code&scope=#{scopes}" \
         "&access_type=offline&include_granted_scopes=true&prompt=consent"
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
        response = post("https://accounts.google.com/o/oauth2/token").
                     payload(client_id: connection["client_id"],
                           client_secret: connection["client_secret"],
                           grant_type: "authorization_code",
                           code: auth_code,
                           redirect_uri: redirect_uri).
                     request_format_www_form_urlencoded

        [response, nil, nil]
      end,

      refresh: lambda do |connection, refresh_token|
        post("https://accounts.google.com/o/oauth2/token").
          payload(client_id: connection["client_id"],
                  client_secret: connection["client_secret"],
                  grant_type: "refresh_token",
                  refresh_token: refresh_token).
          request_format_www_form_urlencoded
      end,

      refresh_on: [401],

      detect_on: [/"errors"\:\s*\[/],

      apply: lambda do |_connection, access_token|
        headers("Authorization" => "Bearer #{access_token}")
      end
    },

    base_uri: lambda do
      "https://www.googleapis.com"
    end
  },

  test: lambda do |_connection|
    get("/analytics/v3/management/accounts")
  end,

  object_definitions: {
    filters: {
      fields: lambda do |_, config_fields|
        filters = [
          {
            name: "start_date",
            label: "Start Date",
            control_type: "date",
            optional: false,
            hint: "Select a start date for the report"
          },
          {
            name: "end_date",
            label: "End Date",
            control_type: "date",
            optional: false,
            hint: "Select a end date for the report"
          }
        ]
        if config_fields["dimension_filter_fields"].present?
          dimension_filter_fields =
            config_fields["dimension_filter_fields"].
              split("\n").
              map do |field_name|
                {
                  name: field_name.gsub("ga:", ""),
                  label: field_name.gsub("ga:", "").titleize,
                  optional: false
                }
              end
          filters =
            filters.concat(
              [
                { name: "dimension_filters",
                  type: :object,
                  properties: dimension_filter_fields }
              ]
            )
        end

        if config_fields["metric_filter_fields"].present?
          metric_filter_fields =
            config_fields["metric_filter_fields"].
              split("\n").
              map do |field_name|
                {
                  name: field_name.gsub("ga:", ""),
                  label: field_name.gsub("ga:", "").titleize,
                  optional: false
                }
              end

          filters =
            filters.concat(
              [
                { name: "metric_filters",
                  type: :object,
                  properties: metric_filter_fields }
              ]
            )
        end
        filters
      end
    },

    report_output: {
      fields: lambda do |_, config_fields|
        dimension_properties = (config_fields["dimensions"] || "").
                                 split("\n").
                                 map { |field| { name: field } }
        metric_properties = (config_fields["metrics"] || "").
                              split("\n").
                              map { |field| { name: field } }

        [
          {
            name: "rows",
            type: :array, of: :object,
            properties: [
              { name: "dimensions", type: :object,
                properties: dimension_properties },
              { name: "metrics", type: :object, properties: metric_properties }
            ]
          },
          { name: "rowCount", type: :integer }
        ]
      end
    }
  },

  actions: {
    get_report: {
      description: "Get <span class='provider'>report</span> in " \
        "<span class='provider'>Google Analytics</span>",
      subtitle: "Get report data",

      config_fields: [
        {
          name: "account",
          control_type: "select",
          pick_list: "accounts",
          optional: false
        },
        {
          name: "property",
          control_type: "select",
          pick_list: "properties",
          pick_list_params: { account_id: "account" },
          optional: false,
          hint: "Select an account to view list of properties"
        },
        {
          name: "view",
          control_type: "select",
          pick_list: "profiles",
          pick_list_params: { account_id: "account", property_id: "property" },
          optional: false,
          hint: "Select a property to view list of profiles"
        },
        {
          name: "dimensions",
          control_type: "multiselect",
          pick_list: "dimensions",
          pick_list_params: { account_id: "account", property_id: "property" },
          delimiter: "\n",
          optional: false,
          hint: "Select a property to view list of dimensions"
        },
        {
          name: "metrics",
          control_type: "multiselect",
          pick_list: "metrics",
          pick_list_params: { account_id: "account", property_id: "property" },
          delimiter: "\n",
          optional: false,
          hint: "Select a property to view list of metrics"
        },
        {
          name: "dimension_filter_fields",
          control_type: "multiselect",
          pick_list: "dimensions",
          pick_list_params: { account_id: "account", property_id: "property" },
          delimiter: "\n",
          hint: "Select a property to view list of dimensions to filter by"
        },
        {
          name: "metric_filter_fields",
          control_type: "multiselect",
          pick_list: "metrics",
          pick_list_params: { account_id: "account", property_id: "property" },
          delimiter: "\n",
          hint: "Select a property to view list of metrics to filter by"
        },
        {
          name: "start_date", type: "date", control_type: "date",
          hint: "Starting start to pick up events from"
        },
        {
          name: "end_date", type: "date", control_type: "date",
          hint: "Starting start to pick up events from"
        },
      ],

      input_fields: lambda do |object_definitions|
        object_definitions["filters"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["report_output"]
      end,

      execute: lambda do |_connection, input|
        dimensions = input["dimensions"].split("\n")
        metrics = input["metrics"].split("\n")

        dimension_filter_clauses =
          if input["dimension_filters"].blank?
            []
          else
            [{
              "operator" => "AND",
              "filters" => [
                             (input["dimension_filters"] || {}).
                               map do |k, v|
                                 if v.present?
                                   {
                                     "dimensionName" => "ga:#{k}",
                                     "operator" => "EXACT",
                                     "expressions" => ["#{v}"]
                                   }
                                 else
                                   nil
                                 end
                               end
                           ]
            }]
          end

        metric_filter_clauses =
          if input["metric_filters"].blank?
            []
          else
            [{
              "operator" => "AND",
              "filters" => [
                             (input["metric_filters"] || {}).
                               map do |k, v|
                                 if v.present?
                                   {
                                     "metricName" => "ga:#{k}",
                                     "operator" => "EQUAL",
                                     "comparisonValue" => "#{v}"
                                   }
                                 else
                                   nil
                                 end
                               end
                           ]
            }]
          end

        payload = {
          "reportRequests" => [
            {
              "viewId" => input["view"],
              "dateRanges" => [
                {
                  "startDate": input["start_date"].to_date.iso8601,
                  "endDate": input["end_date"].to_date.iso8601
                }
              ],
              "dimensions" => dimensions.
                                map { |dimension| { name: dimension } },
              "metrics" => metrics.map { |metric| { expression: metric } },
              "dimensionFilterClauses" => dimension_filter_clauses,
              "metricFilterClauses" => metric_filter_clauses,
            }
          ]
        }

        response =
          post("https://analyticsreporting.googleapis.com/v4/reports:batchGet",
               payload)&.[]("reports")&.first
        headers = response&.[]("columnHeader")
        dimension_headers = headers["dimensions"]
        metric_headers = (headers["metricHeader"]["metricHeaderEntries"] || []).
                           map { |h| h["name"] }
        data = response["data"]
        data["rows"] =
          (data&.[]("rows") || []).
            map do |row|
              {
                "dimensions": Hash[dimension_headers.
                                     zip(row&.[]("dimensions"))],
                "metrics": Hash[metric_headers.
                                  zip(row&.[]("metrics")&.first&.[]("values"))]
              }
            end
        data
      end
    }
  },

  pick_lists: {
    accounts: lambda do |_connection|
      get("/analytics/v3/management/accounts")["items"].
        pluck("name", "id")
    end,

    properties: lambda do |_connection, account_id:|
      get(
        "/analytics/v3/management/accounts/#{account_id}/webproperties"
      )["items"].
        pluck("name", "id")
    end,

    profiles: lambda do |_connection, account_id:, property_id:|
      get(
        "/analytics/v3/management/accounts/#{account_id}/webproperties/" \
        "#{property_id}/profiles"
      )["items"].
        pluck("name", "id")
    end,

    dimensions: lambda do |_connection, account_id:, property_id:|
      custom_dimensions =
        get(
          "/analytics/v3/management/accounts/#{account_id}/webproperties/" \
          "#{property_id}/customDimensions"
        )["items"].
          pluck("name", "id")
      [
        %w[User\ Type ga:userType],
        %w[Count\ of\ Sessions ga:sessionCount],
        %w[Days\ Since\ Last\ Session ga:daysSinceLastSession],
        %w[User\ Defined\ Value ga:userDefinedValue],
        %w[User\ Bucket ga:userBucket],
        %w[BucketSession\ Duration ga:sessionDuration],
        %w[PathReferral\ Path ga:referral],
        %w[Full\ Referrer ga:fullReferrer],
        %w[Campaign ga:campaign],
        %w[Source ga:source],
        %w[Medium ga:medium],
        %w[Source\ /\ Medium ga:sourceMedium],
        %w[Keyword ga:keyword],
        %w[Ad\ Content ga:adContent],
        %w[Social\ Network ga:socialNetwork],
        %w[Social\ Source\ Referral ga:hasSocialSourceReferral],
        %w[Campaign\ Code ga:campaignCode],
        %w[Ad\ Group ga:adGroup],
        %w[Ad\ Slot ga:adSlot],
        %w[Ad\ Distribution\ Network ga:adDistributionNetwork],
        %w[Query\ Match\ Type ga:adMatchType],
        %w[Keyword\ Match\ Type ga:adKeywordMatchType],
        %w[Search\ Query ga:adMatchedQuery],
        %w[Placement\ Domain ga:adPlacementDomain],
        %w[Placement\ URL ga:adPlacementUrl],
        %w[Ad\ Format ga:adFormat],
        %w[Targeting\ Type ga:adTargetingType],
        %w[Placement\ Type ga:adTargetingOption],
        %w[Display\ URL ga:adDisplayUrl],
        %w[Destination\ URL ga:adDestinationUrl],
        %w[AdWords\ Customer\ ID ga:adwordsCustomerID],
        %w[AdWords\ Campaign\ ID ga:adwordsCampaignID],
        %w[AdWords\ Ad\ Group\ ID ga:adwordsAdGroupID],
        %w[AdWords\ Creative\ ID ga:adwordsCreativeID],
        %w[AdWords\ Criteria\ ID ga:adwordsCriteriaID],
        %w[Query\ Word\ Count ga:adQueryWordCount],
        %w[TrueView\ Video\ Ad ga:isTrueViewVideoAd],
        %w[Goal\ Completion\ Location ga:goalCompletionLocation],
        %w[1Goal\ Previous\ Step\ -\ 1 ga:goalPreviousStep],
        %w[2Goal\ Previous\ Step\ -\ 2 ga:goalPreviousStep],
        %w[3Goal\ Previous\ Step\ -\ 3 ga:goalPreviousStep],
        %w[Browser ga:browser],
        %w[Browser\ Version ga:browserVersion],
        %w[Operating\ System ga:operatingSystem],
        %w[Operating\ System\ Version ga:operatingSystemVersion],
        %w[Mobile\ Device\ Branding ga:mobileDeviceBranding],
        %w[Mobile\ Device\ Model ga:mobileDeviceModel],
        %w[Mobile\ Input\ Selector ga:mobileInputSelector],
        %w[Mobile\ Device\ Info ga:mobileDeviceInfo],
        %w[Mobile\ Device\ Marketing\ Name ga:mobileDeviceMarketingName],
        %w[Device\ Category ga:deviceCategory],
        %w[Browser\ Size ga:browserSize],
        %w[Data\ Source ga:dataSource],
        %w[Continent ga:continent],
        %w[Sub\ Continent ga:subContinent],
        %w[Country ga:country],
        %w[Region ga:region],
        %w[Metro ga:metro],
        %w[City ga:city],
        %w[Latitude ga:latitude],
        %w[Longitude ga:longitude],
        %w[Network\ Domain ga:networkDomain],
        %w[Service\ Provider ga:networkLocation],
        %w[City\ ID ga:cityId],
        %w[Continent\ ID ga:continentId],
        %w[Country\ ISO\ Code ga:countryIsoCode],
        %w[Metro\ Id ga:metroId],
        %w[Region\ ID ga:regionId],
        %w[Region\ ISO\ Code ga:regionIsoCode],
        %w[Sub\ Continent\ Code ga:subContinentCode],
        %w[Flash\ Version ga:flashVersion],
        %w[Java\ Support ga:javaEnabled],
        %w[Language ga:language],
        %w[Screen\ Colors ga:screenColors],
        %w[Source\ Property\ Display\ Name ga:sourcePropertyDisplayName],
        %w[Source\ Property\ Tracking\ ID ga:sourcePropertyTrackingId],
        %w[Screen\ Resolution ga:screenResolution],
        %w[Hostname ga:hostname],
        %w[Page ga:pagePath],
        %w[Page\ path\ level\ 1 ga:pagePathLevel1],
        %w[Page\ path\ level\ 2 ga:pagePathLevel2],
        %w[Page\ path\ level\ 3 ga:pagePathLevel3],
        %w[Page\ path\ level\ 4 ga:pagePathLevel4],
        %w[Page\ Title ga:pageTitle],
        %w[Landing\ Page ga:landingPagePath],
        %w[Second\ Page ga:secondPagePath],
        %w[Exit\ Page ga:exitPagePath],
        %w[Previous\ Page\ Path ga:previousPagePath],
        %w[Page\ Depth ga:pageDepth],
        %w[Landing\ Page\ Group\ XX ga:landingContentGroupXX],
        %w[Previous\ Page\ Group\ XX ga:previousContentGroupXX],
        %w[Page\ Group\ XX ga:contentGroupXX],
        %w[Site\ Search\ Status ga:searchUsed],
        %w[Search\ Term ga:searchKeyword],
        %w[Refined\ Keyword ga:searchKeywordRefinement],
        %w[Site\ Search\ Category ga:searchCategory],
        %w[Start\ Page ga:searchStartPage],
        %w[Destination\ Page ga:searchDestinationPage],
        %w[Search\ Destination\ Page ga:searchAfterDestinationPage],
        %w[App\ Installer\ ID ga:appInstallerId],
        %w[App\ Version ga:appVersion],
        %w[App\ Name ga:appName],
        %w[App\ ID ga:appId],
        %w[Screen\ Name ga:screenName],
        %w[Screen\ Depth ga:screenDepth],
        %w[Landing\ Screen ga:landingScreenName],
        %w[Exit\ Screen ga:exitScreenName],
        %w[Event\ Category ga:eventCategory],
        %w[Event\ Action ga:eventAction],
        %w[Event\ Label ga:eventLabel],
        %w[Transaction\ ID ga:transactionId],
        %w[Affiliation ga:affiliation],
        %w[Sessions\ to\ Transaction ga:sessionsToTransaction],
        %w[Days\ to\ Transaction ga:daysToTransaction],
        %w[Product\ SKU ga:productSku],
        %w[Product ga:productName],
        %w[Product\ Category ga:productCategory],
        %w[Currency\ Code ga:currencyCode],
        %w[Checkout\ Options ga:checkoutOptions],
        %w[Internal\ Promotion\ Creative ga:internalPromotionCreative],
        %w[Internal\ Promotion\ ID ga:internalPromotionId],
        %w[Internal\ Promotion\ Name ga:internalPromotionName],
        %w[Internal\ Promotion\ Position ga:internalPromotionPosition],
        %w[Order\ Coupon\ Code ga:orderCouponCode],
        %w[Product\ Brand ga:productBrand],
        %w[Product\ Category\ (Enhanced\ Ecommerce) \
           ga:productCategoryHierarchy],
        %w[Product\ Category\ Level\ XX ga:productCategoryLevelXX],
        %w[Product\ Coupon\ Code ga:productCouponCode],
        %w[Product\ List\ Name ga:productListName],
        %w[Product\ List\ Position ga:productListPosition],
        %w[Product\ Variant ga:productVariant],
        %w[Shopping\ Stage ga:shoppingStage],
        %w[Social\ Network ga:socialInteractionNetwork],
        %w[Social\ Action ga:socialInteractionAction],
        %w[Social\ Network\ and\ Action ga:socialInteractionNetworkAction],
        %w[Social\ Entity ga:socialInteractionTarget],
        %w[Social\ Type ga:socialEngagementType],
        %w[Timing\ Category ga:userTimingCategory],
        %w[Timing\ Label ga:userTimingLabel],
        %w[Timing\ Variable ga:userTimingVariable],
        %w[Exception\ Description ga:exceptionDescription],
        %w[Experiment\ ID ga:experimentId],
        %w[Variant ga:experimentVariant],
        %w[Custom\ Dimension\ XX ga:dimensionXX],
        %w[Custom\ Variable\ (Key\ XX) ga:customVarNameXX],
        %w[Custom\ Variable\ (Value\ XX)\  ga:customVarValueXX],
        %w[Date ga:date],
        %w[Year ga:year],
        %w[Month\ of\ the\ year ga:month],
        %w[Week\ of\ the\ Year ga:week],
        %w[Day\ of\ the\ month ga:day],
        %w[Hour ga:hour],
        %w[Minute ga:minute],
        %w[Month\ Index ga:nthMonth],
        %w[Week\ Index ga:nthWeek],
        %w[Day\ Index ga:nthDay],
        %w[Minute\ Index ga:nthMinute],
        %w[Day\ of\ Week ga:dayOfWeek],
        %w[eDay\ of\ Week\ Name ga:dayOfWeekNam],
        %w[Hour\ of\ Day ga:dateHour],
        %w[Date\ Hour\ and\ Minute.\ Example:\ 201704011200 ga:dateHourMinute],
        %w[Month\ of\ Year ga:yearMonth],
        %w[Week\ of\ Year ga:yearWeek],
        %w[ISO\ Week\ of\ the\ Year ga:isoWeek],
        %w[ISO\ Year ga:isoYear],
        %w[ISO\ Week\ of\ ISO\ Year ga:isoYearIsoWeek],
        %w[Hour\ Index ga:nthHour],
        %w[DCM\ Ad\ (GA\ Model) ga:dcmClickAd],
        %w[DCM\ Ad\ ID\ (GA\ Model) ga:dcmClickAdId],
        %w[DCM\ Ad\ Type\ (GA\ Model) ga:dcmClickAdType],
        %w[DCM\ Ad\ Type\ ID ga:dcmClickAdTypeId],
        %w[DCM\ Advertiser\ (GA\ Model) ga:dcmClickAdvertiser],
        %w[DCM\ Advertiser\ ID\ (GA\ Model) ga:dcmClickAdvertiserId],
        %w[DCM\ Campaign\ (GA\ Model) ga:dcmClickCampaign],
        %w[DCM\ Campaign\ ID\ (GA\ Model) ga:dcmClickCampaignId],
        %w[DCM\ Creative\ ID\ (GA\ Model) ga:dcmClickCreativeId],
        %w[DCM\ Creative\ (GA\ Model) ga:dcmClickCreative],
        %w[DCM\ Rendering\ ID\ (GA\ Model) ga:dcmClickRenderingId],
        %w[DCM\ Creative\ Type\ (GA\ Model) ga:dcmClickCreativeType],
        %w[DCM\ Creative\ Type\ ID\ (GA\ Model) ga:dcmClickCreativeTypeId],
        %w[DCM\ Creative\ Version\ (GA\ Model) ga:dcmClickCreativeVersion],
        %w[DCM\ Site\ (GA\ Model) ga:dcmClickSite],
        %w[DCM\ Site\ ID\ (GA\ Model) ga:dcmClickSiteId],
        %w[DCM\ Placement\ (GA\ Model) ga:dcmClickSitePlacement],
        %w[DCM\ Placement\ ID\ (GA\ Model) ga:dcmClickSitePlacementId],
        %w[DCM\ Floodlight\ Configuration\ ID\ (GA\ Model) ga:dcmClickSpotId],
        %w[DCM\ Activity ga:dcmFloodlightActivity],
        %w[DCM\ Activity\ and\ Group ga:dcmFloodlightActivityAndGroup],
        %w[DCM\ Activity\ Group ga:dcmFloodlightActivityGroup],
        %w[DCM\ Activity\ Group\ ID ga:dcmFloodlightActivityGroupId],
        %w[DCM\ Activity\ ID ga:dcmFloodlightActivityId],
        %w[DCM\ Advertiser\ ID ga:dcmFloodlightAdvertiserId],
        %w[DCM\ Floodlight\ Configuration\ ID ga:dcmFloodlightSpotId],
        %w[DCM\ Ad ga:dcmLastEventAd],
        %w[DCM\ Ad\ ID\ (DCM\ Model) ga:dcmLastEventAdId],
        %w[DCM\ Ad\ Type\ (DCM\ Model) ga:dcmLastEventAdType],
        %w[DCM\ Ad\ Type\ ID\ (DCM\ Model) ga:dcmLastEventAdTypeId],
        %w[DCM\ Advertiser\ (DCM\ Model) ga:dcmLastEventAdvertiser],
        %w[DCM\ Advertiser\ ID\ (DCM\ Model) ga:dcmLastEventAdvertiserId],
        %w[DCM\ Attribution\ Type\ (DCM\ Model) ga:dcmLastEventAttributionType],
        %w[DCM\ Campaign\ (DCM\ Model) ga:dcmLastEventCampaign],
        %w[DCM\ Campaign\ ID\ (DCM\ Model) ga:dcmLastEventCampaignId],
        %w[DCM\ Creative\ ID\ (DCM\ Model) ga:dcmLastEventCreativeId],
        %w[DCM\ Creative\ (DCM\ Model) ga:dcmLastEventCreative],
        %w[DCM\ Rendering\ ID\ (DCM\ Model) ga:dcmLastEventRenderingId],
        %w[DCM\ Creative\ Type\ (DCM\ Model) ga:dcmLastEventCreativeType],
        %w[DCM\ Creative\ Type\ ID\ (DCM\ Model) ga:dcmLastEventCreativeTypeId],
        %w[DCM\ Creative\ Version\ (DCM\ Model) ga:dcmLastEventCreativeVersion],
        %w[DCM\ Site\ (DCM\ Model) ga:dcmLastEventSite],
        %w[DCM\ Site\ ID\ (DCM\ Model) ga:dcmLastEventSiteId],
        %w[DCM\ Placement\ (DCM\ Model) ga:dcmLastEventSitePlacement],
        %w[DCM\ Placement\ ID\ (DCM\ Model) ga:dcmLastEventSitePlacementId],
        %w[DCM\ Floodlight\ Configuration\ ID\ (DCM\ Model) \
           ga:dcmLastEventSpotId],
        %w[Age ga:userAgeBracket],
        %w[Gender ga:userGender],
        %w[Other\ Category ga:interestOtherCategory],
        %w[Affinity\ Category\ (reach) ga:interestAffinityCategory],
        %w[In-Market\ Segment ga:interestInMarketCategory],
        %w[Acquisition\ Campaign ga:acquisitionCampaign],
        %w[Acquisition\ Medium ga:acquisitionMedium],
        %w[Acquisition\ Source ga:acquisitionSource],
        %w[Acquisition\ Source\ /\ Medium ga:acquisitionSourceMedium],
        %w[Acquisition\ Channel ga:acquisitionTrafficChannel],
        %w[Cohort ga:cohort],
        %w[Cohort\ Day ga:cohortNthDay],
        %w[Cohort\ Month ga:cohortNthMonth],
        %w[Cohort\ Week ga:cohortNthWeek],
        %w[Default\ Channel\ Grouping ga:channelGrouping],
        %w[DBM\ Advertiser\ (GA\ Model) ga:dbmClickAdvertiser],
        %w[DBM\ Advertiser\ ID\ (GA\ Model) ga:dbmClickAdvertiserId],
        %w[DBM\ Creative\ ID\ (GA\ Model) ga:dbmClickCreativeId],
        %w[DBM\ Exchange\ (GA\ Model) ga:dbmClickExchange],
        %w[DBM\ Exchange\ ID\ (GA\ Model) ga:dbmClickExchangeId],
        %w[DBM\ Insertion\ Order\ (GA\ Model) ga:dbmClickInsertionOrder],
        %w[DBM\ Insertion\ Order\ ID\ (GA\ Model) ga:dbmClickInsertionOrderId],
        %w[DBM\ Line\ Item\ NAME\ (GA\ Model) ga:dbmClickLineItem],
        %w[DBM\ Line\ Item\ ID\ (GA\ Model) ga:dbmClickLineItemId],
        %w[DBM\ Site\ (GA\ Model) ga:dbmClickSite],
        %w[DBM\ Site\ ID\ (GA\ Model) ga:dbmClickSiteId],
        %w[DBM\ Advertiser\ (DCM\ Model) ga:dbmLastEventAdvertiser],
        %w[DBM\ Advertiser\ ID\ (DCM\ Model) ga:dbmLastEventAdvertiserId],
        %w[DBM\ Creative\ ID\ (DCM\ Model) ga:dbmLastEventCreativeId],
        %w[DBM\ Exchange\ (DCM\ Model) ga:dbmLastEventExchange],
        %w[DBM\ Exchange\ ID\ (DCM\ Model) ga:dbmLastEventExchangeId],
        %w[DBM\ Insertion\ Order\ (DCM\ Model) ga:dbmLastEventInsertionOrder],
        %w[DBM\ Insertion\ Order\ ID\ (DCM\ Model) \
           ga:dbmLastEventInsertionOrderId],
        %w[DBM\ Line\ Item\ (DCM\ Model) ga:dbmLastEventLineItem],
        %w[DBM\ Line\ Item\ ID\ (DCM\ Model) ga:dbmLastEventLineItemId],
        %w[DBM\ Site\ (DCM\ Model) ga:dbmLastEventSite],
        %w[DBM\ Site\ ID\ (DCM\ Model) ga:dbmLastEventSiteId],
        %w[DS\ Ad\ Group ga:dsAdGroup],
        %w[DS\ Ad\ Group\ ID ga:dsAdGroupId],
        %w[DS\ Advertiser ga:dsAdvertiser],
        %w[DS\ Advertiser\ ID ga:dsAdvertiserId],
        %w[DS\ Agency ga:dsAgency],
        %w[DS\ Agency\ ID ga:dsAgencyId],
        %w[DS\ Campaign ga:dsCampaign],
        %w[DS\ Campaign\ ID ga:dsCampaignId],
        %w[DS\ Engine\ Account ga:dsEngineAccount],
        %w[DS\ Engine\ Account\ ID ga:dsEngineAccountId],
        %w[DS\ Keyword ga:dsKeyword],
        %w[DS\ Keyword\ ID ga:dsKeywordId]
      ].concat(custom_dimensions)
    end,

    metrics: lambda do |_connection, account_id:, property_id:|
      custom_metrics =
        get("/analytics/v3/management/accounts/#{account_id}/webproperties/" \
          "#{property_id}/customMetrics")["items"].
          pluck("name", "id")
      [
        %w[Users ga:users],
        %w[New\ Users ga:newUsers],
        ["% New Sessions", "ga:percentNewSessions"],
        %w[1\ Day\ Active\ Users ga:1dayUsers],
        %w[7\ Day\ Active\ Users ga:7dayUsers],
        %w[14\ Day\ Active\ Users ga:14dayUsers],
        %w[30\ Day\ Active\ Users ga:30dayUsers],
        %w[Number\ of\ Sessions\ per\ User ga:sessionsPerUser],
        %w[Sessions ga:sessions],
        %w[Bounces ga:bounces],
        %w[Bounce\ Rate ga:bounceRate],
        %w[Session\ Duration ga:sessionDuration],
        %w[Avg.\ Session\ Duration ga:avgSessionDuration],
        %w[Unique\ Dimension\ Combinations ga:uniqueDimensionCombinations],
        %w[Hits\  ga:hits],
        %w[Organic\ Searches ga:organicSearches],
        %w[Impressions ga:impressions],
        %w[Clicks ga:adClicks],
        %w[Cost ga:adCost],
        %w[CPM ga:CPM],
        %w[CPC ga:CPC],
        %w[CTR ga:CTR],
        %w[Cost\ per\ Transaction ga:costPerTransaction],
        %w[Cost\ per\ Goal\ Conversion ga:costPerGoalConversion],
        %w[Cost\ per\ Conversion ga:costPerConversion],
        %w[RPC ga:RPC],
        %w[ROAS ga:ROAS],
        %w[Goal\ XX\ Starts ga:goalXXStarts],
        %w[Goal\ Starts ga:goalStartsAll],
        %w[Goal\ XX\ Completions ga:goalXXCompletions],
        %w[Goal\ Completions ga:goalCompletionsAll],
        %w[Goal\ XX\ Value ga:goalXXValue],
        %w[Goal\ Value ga:goalValueAll],
        %w[Per\ Session\ Goal\ Value ga:goalValuePerSession],
        %w[Goal\ XX\ Conversion\ Rate ga:goalXXConversionRate],
        %w[Goal\ Conversion\ Rate ga:goalConversionRateAll],
        %w[Goal\ XX\ Abandoned\ Funnels ga:goalXXAbandons],
        %w[Abandoned\ Funnels ga:goalAbandonsAll],
        %w[Goal\ XX\ Abandonment\ Rate ga:goalXXAbandonRate],
        %w[Total\ Abandonment\ Rate ga:goalAbandonRateAll],
        %w[Page\ Value ga:pageValue],
        %w[Entrances ga:entrances],
        %w[Entrances\ /\ Pageviews ga:entranceRate],
        %w[Pageviews ga:pageviews],
        %w[Pages\ /\ Session ga:pageviewsPerSession],
        %w[Unique\ Pageviews ga:uniquePageviews],
        %w[Time\ on\ Page ga:timeOnPage],
        %w[Avg.\ Time\ on\ Page ga:avgTimeOnPage],
        %w[Exits ga:exits],
        ["% Exit", "ga:exitRate"],
        %w[Unique\ Views\ XX ga:contentGroupUniqueViewsXX],
        %w[Results\ Pageviews ga:searchResultViews],
        %w[Total\ Unique\ Searches ga:searchUniques],
        %w[Results\ Pageviews\ /\ Search ga:avgSearchResultViews],
        %w[Sessions\ with\ Search ga:searchSessions],
        ["% Sessions with Search", "ga:percentSessionsWithSearch"],
        %w[Search\ Depth ga:searchDepth],
        %w[Avg.\ Search\ Depth ga:avgSearchDepth],
        %w[Search\ Refinements ga:searchRefinements],
        ["% Search Refinements", "ga:percentSearchRefinements"],
        %w[Time\ after\ Search ga:searchDuration],
        %w[Time\ after\ Search ga:avgSearchDuration],
        %w[Search\ Exits ga:searchExits],
        ["% Search Exits", "ga:searchExitRate"],
        %w[Site\ Search\ Goal\ XX\ Conversion\ Rate \
           ga:searchGoalXXConversionRate],
        %w[Site\ Search\ Goal\ Conversion\ Rate ga:searchGoalConversionRateAll],
        %w[Per\ Search\ Goal\ Value ga:goalValueAllPerSearch],
        %w[Page\ Load\ Time\ (ms) ga:pageLoadTime],
        %w[Page\ Load\ Sample ga:pageLoadSample],
        %w[Avg.\ Page\ Load\ Time\ (sec) ga:avgPageLoadTime],
        %w[Domain\ Lookup\ Time\ (ms) ga:domainLookupTime],
        %w[Avg.\ Domain\ Lookup\ Time\ (sec) ga:avgDomainLookupTime],
        %w[Page\ Download\ Time\ (ms) ga:pageDownloadTime],
        %w[Avg.\ Page\ Download\ Time\ (sec) ga:avgPageDownloadTime],
        %w[Redirection\ Time\ (ms) ga:redirectionTime],
        %w[Avg.\ Redirection\ Time\ (sec) ga:avgRedirectionTime],
        %w[Server\ Connection\ Time\ (ms) ga:serverConnectionTime],
        %w[Avg.\ Server\ Connection\ Time\ (sec) ga:avgServerConnectionTime],
        %w[Server\ Response\ Time\ (ms) ga:serverResponseTime],
        %w[Avg.\ Server\ Response\ Time\ (sec) ga:avgServerResponseTime],
        %w[Speed\ Metrics\ Sample ga:speedMetricsSample],
        %w[Document\ Interactive\ Time\ (ms) ga:domInteractiveTime],
        %w[Avg.\ Document\ Interactive\ Time\ (sec) ga:avgDomInteractiveTime],
        %w[Document\ Content\ Loaded\ Time\ (ms) ga:domContentLoadedTime],
        %w[Avg.\ Document\ Content\ Loaded\ Time\ (sec) \
           ga:avgDomContentLoadedTime],
        %w[SampleDOM\ Latency\ Metrics\ Sample ga:domLatencyMetrics],
        %w[Screen\ Views ga:screenviews],
        %w[Unique\ Screen\ Views ga:uniqueScreenviews],
        %w[Screens\ /\ Session ga:screenviewsPerSession],
        %w[Time\ on\ Screen ga:timeOnScreen],
        %w[Avg.\ Time\ on\ Screen ga:avgScreenviewDuration],
        %w[Total\ Events ga:totalEvents],
        %w[Unique\ Events ga:uniqueEvents],
        %w[Event\ Value ga:eventValue],
        %w[Avg.\ Value ga:avgEventValue],
        %w[Sessions\ with\ Event ga:sessionsWithEvent],
        %w[Events\ /\ Session\ with\ Event ga:eventsPerSessionWithEvent],
        %w[Transactions ga:transactions],
        %w[Ecommerce\ Conversion\ Rate ga:transactionsPerSession],
        %w[Revenue ga:transactionRevenue],
        %w[Avg.\ Order\ Value ga:revenuePerTransaction],
        %w[Per\ Session\ Value ga:transactionRevenuePerSession],
        %w[Shipping ga:transactionShipping],
        %w[Tax ga:transactionTax],
        %w[Total\ Value ga:totalValue],
        %w[Quantity ga:itemQuantity],
        %w[Unique\ Purchases ga:uniquePurchases],
        %w[Avg.\ Price ga:revenuePerItem],
        %w[Product\ Revenue ga:itemRevenue],
        %w[Avg.\ QTY ga:itemsPerPurchase],
        %w[Local\ Revenue ga:localTransactionRevenue],
        %w[Local\ Shipping ga:localTransactionShipping],
        %w[Local\ Tax ga:localTransactionTax],
        %w[Local\ Product\ Revenue ga:localItemRevenue],
        %w[Buy-to-Detail\ Rate ga:buyToDetailRate],
        %w[Cart-to-Detail\ Rate ga:cartToDetailRate],
        %w[Internal\ Promotion\ CTR ga:internalPromotionCTR],
        %w[Internal\ Promotion\ Clicks ga:internalPromotionClicks],
        %w[Internal\ Promotion\ Views ga:internalPromotionViews],
        %w[Local\ Product\ Refund\ Amount ga:localProductRefundAmount],
        %w[Local\ Refund\ Amount ga:localRefundAmount],
        %w[Product\ Adds\ To\ Cart ga:productAddsToCart],
        %w[Product\ Checkouts ga:productCheckouts],
        %w[Product\ Detail\ Views ga:productDetailViews],
        %w[Product\ List\ CTR ga:productListCTR],
        %w[Product\ List\ Clicks ga:productListClicks],
        %w[Product\ List\ Views ga:productListViews],
        %w[Product\ Refund\ Amount ga:productRefundAmount],
        %w[Product\ Refunds ga:productRefunds],
        %w[Product\ Removes\ From\ Cart ga:productRemovesFromCart],
        %w[Product\ Revenue\ per\ Purchase ga:productRevenuePerPurchase],
        %w[Quantity\ Added\ To\ Cart ga:quantityAddedToCart],
        %w[Quantity\ Checked\ Out ga:quantityCheckedOut],
        %w[Quantity\ Refunded ga:quantityRefunded],
        %w[Quantity\ Removed\ From\ Cart ga:quantityRemovedFromCart],
        %w[Refund\ Amount ga:refundAmount],
        %w[Revenue\ per\ User ga:revenuePerUser],
        %w[Refunds ga:totalRefunds],
        %w[Transactions\ per\ User ga:transactionsPerUser],
        %w[Social\ Actions ga:socialInteractions],
        %w[Unique\ Social\ Actions ga:uniqueSocialInteractions],
        %w[Actions\ Per\ Social\ Session ga:socialInteractionsPerSession],
        %w[User\ Timing\ (ms) ga:userTimingValue],
        %w[User\ Timing\ Sample ga:userTimingSample],
        %w[Avg.\ User\ Timing\ (sec) ga:avgUserTimingValue],
        %w[Exceptions ga:exceptions],
        %w[Exceptions\ /\ Screen ga:exceptionsPerScreenview],
        %w[Crashes ga:fatalExceptions],
        %w[Crashes\ /\ Screen ga:fatalExceptionsPerScreenview],
        %w[Custom\ Metric\ XX\ Value ga:metricXX],
        %w[Calculated\ Metric ga:calcMetric_],
        %w[DCM\ Conversions ga:dcmFloodlightQuantity],
        %w[DCM\ Revenue ga:dcmFloodlightRevenue],
        %w[DCM\ CPC ga:dcmCPC],
        %w[DCM\ CTR ga:dcmCTR],
        %w[DCM\ Clicks ga:dcmClicks],
        %w[DCM\ Cost ga:dcmCost],
        %w[DCM\ Impressions ga:dcmImpressions],
        %w[DCM\ ROAS ga:dcmROAS],
        %w[DCM\ RPC ga:dcmRPC],
        %w[AdSense\ Revenue ga:adsenseRevenue],
        %w[AdSense\ Ad\ Units\ Viewed ga:adsenseAdUnitsViewed],
        %w[AdSense\ Impressions ga:adsenseAdsViewed],
        %w[AdSense\ Ads\ Clicked ga:adsenseAdsClicks],
        %w[AdSense\ Page\ Impressions ga:adsensePageImpressions],
        %w[AdSense\ CTR ga:adsenseCTR],
        %w[AdSense\ eCPM ga:adsenseECPM],
        %w[AdSense\ Exits ga:adsenseExits],
        %w[AdSense\ Viewable\ Impression\ % \
           ga:adsenseViewableImpressionPercent],
        %w[AdSense\ Coverage ga:adsenseCoverage],
        %w[AdX\ Impressions ga:adxImpressions],
        %w[AdX\ Coverage ga:adxCoverage],
        %w[AdX\ Monetized\ Pageviews ga:adxMonetizedPageviews],
        %w[AdX\ Impressions\ /\ Session ga:adxImpressionsPerSession],
        %w[AdX\ Viewable\ Impressions\ % ga:adxViewableImpressionsPercent],
        %w[AdX\ Clicks ga:adxClicks],
        %w[AdX\ CTR ga:adxCTR],
        %w[AdX\ Revenue ga:adxRevenue],
        %w[AdX\ Revenue\ /\ 1000\ Sessions ga:adxRevenuePer1000Sessions],
        %w[AdX\ eCPM ga:adxECPM],
        %w[DFP\ Impressions ga:dfpImpressions],
        %w[DFP\ Coverage ga:dfpCoverage],
        %w[DFP\ Monetized\ Pageviews ga:dfpMonetizedPageviews],
        %w[DFP\ Impressions\ /\ Session ga:dfpImpressionsPerSession],
        %w[DFP\ Viewable\ Impressions\ % ga:dfpViewableImpressionsPercent],
        %w[DFP\ Clicks ga:dfpClicks],
        %w[DFP\ CTR ga:dfpCTR],
        %w[DFP\ Revenue ga:dfpRevenue],
        %w[DFP\ Revenue\ /\ 1000\ Sessions ga:dfpRevenuePer1000Sessions],
        %w[DFP\ eCPM ga:dfpECPM],
        %w[DFP\ Backfill\ Impressions ga:backfillImpressions],
        %w[DFP\ Backfill\ Coverage ga:backfillCoverage],
        %w[DFP\ Backfill\ Monetized\ Pageviews ga:backfillMonetizedPageviews],
        %w[DFP\ Backfill\ Impressions\ /\ Session \
           ga:backfillImpressionsPerSession],
        %w[DFP\ Backfill\ Viewable\ Impressions\ % \
           ga:backfillViewableImpressionsPercent],
        %w[DFP\ Backfill\ Clicks ga:backfillClicks],
        %w[DFP\ Backfill\ CTR ga:backfillCTR],
        %w[DFP\ Backfill\ Revenue ga:backfillRevenue],
        %w[DFP\ Backfill\ Revenue\ /\ 1000\ Sessions \
           ga:backfillRevenuePer1000Sessions],
        %w[DFP\ Backfill\ eCPM ga:backfillECPM],
        %w[Users ga:cohortActiveUsers],
        %w[Appviews\ per\ User ga:cohortAppviewsPerUser],
        %w[Appviews\ Per\ User\ (LTV) \
           ga:cohortAppviewsPerUserWithLifetimeCriteria],
        %w[Goal\ Completions\ per\ User ga:cohortGoalCompletionsPerUser],
        %w[Goal\ Completions\ Per\ User\ (LTV) \
           ga:cohortGoalCompletionsPerUserWithLifetimeCriteria],
        %w[Pageviews\ per\ User ga:cohortPageviewsPerUser],
        %w[Pageviews\ Per\ User\ (LTV) \
           ga:cohortPageviewsPerUserWithLifetimeCriteria],
        %w[User\ Retention ga:cohortRetentionRate],
        %w[Revenue\ per\ User ga:cohortRevenuePerUser],
        %w[Revenue\ Per\ User\ (LTV) \
           ga:cohortRevenuePerUserWithLifetimeCriteria],
        %w[Session\ Duration\ per\ User ga:cohortSessionDurationPerUser],
        %w[Session\ Duration\ Per\ User\ (LTV) \
           ga:cohortSessionDurationPerUserWithLifetimeCriteria],
        %w[Sessions\ per\ User ga:cohortSessionsPerUser],
        %w[Sessions\ Per\ User\ (LTV) \
           ga:cohortSessionsPerUserWithLifetimeCriteria],
        %w[Total\ Users ga:cohortTotalUsers],
        %w[Cohort\ Users ga:cohortTotalUsersWithLifetimeCriteria],
        %w[DBM\ eCPA ga:dbmCPA],
        %w[DBM\ eCPC ga:dbmCPC],
        %w[DBM\ eCPM ga:dbmCPM],
        %w[DBM\ CTR ga:dbmCTR],
        %w[DBM\ Clicks ga:dbmClicks],
        %w[DBM\ Conversions ga:dbmConversions],
        %w[DBM\ Cost ga:dbmCost],
        %w[DBM\ Impressions ga:dbmImpressions],
        %w[DBM\ ROAS ga:dbmROAS],
        %w[DS\ CPC ga:dsCPC],
        %w[DS\ CTR ga:dsCTR],
        %w[DS\ Clicks ga:dsClicks],
        %w[DS\ Cost ga:dsCost],
        %w[DS\ Impressions ga:dsImpressions],
        %w[DS\ Profit ga:dsProfit],
        %w[DS\ ROAS ga:dsReturnOnAdSpend],
        %w[DS\ RPC ga:dsRevenuePerClick]
      ].concat(custom_metrics)
    end
  }
}
