# FedEx module by Jimmy Baker
# http://github.com/jimmyebaker

require 'date'
module ActiveMerchant
  module Shipping
    # :key is your developer API key
    # :password is your API password
    # :account is your FedEx account number
    # :login is your meter number
    class FedEx < Carrier
      self.retry_safe = true

      cattr_reader :name
      @@name = "FedEx"

      TEST_URL = 'https://gatewaybeta.fedex.com:443/xml'
      LIVE_URL = 'https://gateway.fedex.com:443/xml'

      CARRIER_CODES = {
          "fedex_ground" => "FDXG",
          "fedex_express" => "FDXE"
      }

      DELIVERY_ADDRESS_NODE_NAMES = %w(DestinationAddress ActualDeliveryAddress)
      SHIPPER_ADDRESS_NODE_NAMES = %w(ShipperAddress)

      SERVICE_TYPES = {
          "PRIORITY_OVERNIGHT" => "FedEx Priority Overnight",
          "PRIORITY_OVERNIGHT_SATURDAY_DELIVERY" => "FedEx Priority Overnight Saturday Delivery",
          "FEDEX_2_DAY" => "FedEx 2 Day",
          "FEDEX_2_DAY_SATURDAY_DELIVERY" => "FedEx 2 Day Saturday Delivery",
          "STANDARD_OVERNIGHT" => "FedEx Standard Overnight",
          "FIRST_OVERNIGHT" => "FedEx First Overnight",
          "FIRST_OVERNIGHT_SATURDAY_DELIVERY" => "FedEx First Overnight Saturday Delivery",
          "FEDEX_EXPRESS_SAVER" => "FedEx Express Saver",
          "FEDEX_1_DAY_FREIGHT" => "FedEx 1 Day Freight",
          "FEDEX_1_DAY_FREIGHT_SATURDAY_DELIVERY" => "FedEx 1 Day Freight Saturday Delivery",
          "FEDEX_2_DAY_FREIGHT" => "FedEx 2 Day Freight",
          "FEDEX_2_DAY_FREIGHT_SATURDAY_DELIVERY" => "FedEx 2 Day Freight Saturday Delivery",
          "FEDEX_3_DAY_FREIGHT" => "FedEx 3 Day Freight",
          "FEDEX_3_DAY_FREIGHT_SATURDAY_DELIVERY" => "FedEx 3 Day Freight Saturday Delivery",
          "INTERNATIONAL_PRIORITY" => "FedEx International Priority",
          "INTERNATIONAL_PRIORITY_SATURDAY_DELIVERY" => "FedEx International Priority Saturday Delivery",
          "INTERNATIONAL_ECONOMY" => "FedEx International Economy",
          "INTERNATIONAL_FIRST" => "FedEx International First",
          "INTERNATIONAL_PRIORITY_FREIGHT" => "FedEx International Priority Freight",
          "INTERNATIONAL_ECONOMY_FREIGHT" => "FedEx International Economy Freight",
          "GROUND_HOME_DELIVERY" => "FedEx Ground Home Delivery",
          "FEDEX_GROUND" => "FedEx Ground",
          "INTERNATIONAL_GROUND" => "FedEx International Ground",
          "SMART_POST" => "FedEx SmartPost",
          "FEDEX_FREIGHT_PRIORITY" => "FedEx Freight Priority",
          "FEDEX_FREIGHT_ECONOMY" => "FedEx Freight Economy"
      }

      PACKAGE_TYPES = {
          "fedex_envelope" => "FEDEX_ENVELOPE",
          "fedex_pak" => "FEDEX_PAK",
          "fedex_box" => "FEDEX_BOX",
          "fedex_tube" => "FEDEX_TUBE",
          "fedex_10_kg_box" => "FEDEX_10KG_BOX",
          "fedex_25_kg_box" => "FEDEX_25KG_BOX",
          "your_packaging" => "YOUR_PACKAGING"
      }

      DROPOFF_TYPES = {
          'regular_pickup' => 'REGULAR_PICKUP',
          'request_courier' => 'REQUEST_COURIER',
          'dropbox' => 'DROP_BOX',
          'business_service_center' => 'BUSINESS_SERVICE_CENTER',
          'station' => 'STATION'
      }

      PAYMENT_TYPES = {
          'sender' => 'SENDER',
          'recipient' => 'RECIPIENT',
          'third_party' => 'THIRDPARTY',
          'collect' => 'COLLECT'
      }

      PACKAGE_IDENTIFIER_TYPES = {
          'tracking_number' => 'TRACKING_NUMBER_OR_DOORTAG',
          'door_tag' => 'TRACKING_NUMBER_OR_DOORTAG',
          'rma' => 'RMA',
          'ground_shipment_id' => 'GROUND_SHIPMENT_ID',
          'ground_invoice_number' => 'GROUND_INVOICE_NUMBER',
          'ground_customer_reference' => 'GROUND_CUSTOMER_REFERENCE',
          'ground_po' => 'GROUND_PO',
          'express_reference' => 'EXPRESS_REFERENCE',
          'express_mps_master' => 'EXPRESS_MPS_MASTER'
      }

      TRANSIT_TIMES = %w(UNKNOWN ONE_DAY TWO_DAYS THREE_DAYS FOUR_DAYS FIVE_DAYS SIX_DAYS SEVEN_DAYS EIGHT_DAYS NINE_DAYS TEN_DAYS ELEVEN_DAYS TWELVE_DAYS THIRTEEN_DAYS FOURTEEN_DAYS FIFTEEN_DAYS SIXTEEN_DAYS SEVENTEEN_DAYS EIGHTEEN_DAYS)

      # FedEx tracking codes as described in the FedEx Tracking Service WSDL Guide
      # All delays also have been marked as exceptions
      TRACKING_STATUS_CODES = HashWithIndifferentAccess.new(
          'AA' => :at_airport,
          'AD' => :at_delivery,
          'AF' => :at_fedex_facility,
          'AR' => :at_fedex_facility,
          'AP' => :at_pickup,
          'CA' => :canceled,
          'CH' => :location_changed,
          'DE' => :exception,
          'DL' => :delivered,
          'DP' => :departed_fedex_location,
          'DR' => :vehicle_furnished_not_used,
          'DS' => :vehicle_dispatched,
          'DY' => :exception,
          'EA' => :exception,
          'ED' => :enroute_to_delivery,
          'EO' => :enroute_to_origin_airport,
          'EP' => :enroute_to_pickup,
          'FD' => :at_fedex_destination,
          'HL' => :held_at_location,
          'IT' => :in_transit,
          'LO' => :left_origin,
          'OC' => :order_created,
          'OD' => :out_for_delivery,
          'PF' => :plane_in_flight,
          'PL' => :plane_landed,
          'PU' => :picked_up,
          'RS' => :return_to_shipper,
          'SE' => :exception,
          'SF' => :at_sort_facility,
          'SP' => :split_status,
          'TR' => :transfer
      )

      def self.service_name_for_code(service_code)
        SERVICE_TYPES[service_code] || "FedEx #{service_code.titleize.sub(/Fedex /, '')}"
      end

      def requirements
        [:key, :password, :account, :login]
      end

      def find_rates(origin, destination, packages, options = {})
        @shipping_options = options[:shipping_options] || {}
        options = @options.update(options)
        packages = Array(packages)

        rate_request = build_rate_request(origin, destination, packages, options)

        xml = commit(save_request(rate_request), (options[:test] || false))
        response = remove_version_prefix(xml)

        parse_rate_response(origin, destination, packages, response, options)
      end

      def find_tracking_info(tracking_number, options = {})
        options = @options.update(options)

        tracking_request = build_tracking_request(tracking_number, options)
        xml = commit(save_request(tracking_request), (options[:test] || false))
        response = remove_version_prefix(xml)
        parse_tracking_response(response, options)
      end

      def find_locations(destination, options = {})
        options = @options.update(options)

        location_request = build_location_request(destination)
        xml = commit(save_request(location_request), (options[:test] || false))
        response = remove_version_prefix(xml)
        parse_locations_response(response, options)
      end

      def parse_locations_response(response='', options={})
        hash = Hash.from_xml(response)
        DropoffLocationsResponse.new(true, nil, hash)
      end

      def create_shipment(origin, destination, packages, options = {})
        @shipping_options = options[:shipping_options] || {}
        @payment_options = options[:payment_options] || {}
        @mps = @shipping_options[:mps] || {}
        shipment_request = build_shipment_request(origin, destination, packages)
        xml = commit(save_request(shipment_request), (options[:test] || false))
        response = remove_version_prefix(xml)
        parse_shipment_response(response, options)
      end

      def parse_shipment_response(response, options)
        # rate_estimates = []

        xml = build_document(response)
        root_node = xml.elements['ProcessShipmentReply']
        raise ActiveMerchant::Shipping::ResponseContentError.new(StandardError.new('Invalid document'), xml) unless root_node
        success = response_success?(xml)
        message = response_message(xml)
        raise message unless success
        hash = Hash.from_xml(response)
        options.merge!(
            tracking_number: hash['ProcessShipmentReply']['CompletedShipmentDetail']['CompletedPackageDetails']['TrackingIds']['TrackingNumber'],
            label: hash['ProcessShipmentReply']['CompletedShipmentDetail']['CompletedPackageDetails']['Label']['Parts']['Image']
        )
        FedexShippingResponse.new(success, message, hash, options)
      end

      protected

      def build_shipment_request(origin, destination, packages)
        xml_request = XmlNode.new('ProcessShipmentRequest', 'xmlns' => 'http://fedex.com/ws/ship/v13') do |root_node|
          root_node << build_request_header
          root_node << build_version_node('ship')
          root_node << XmlNode.new('RequestedShipment') do |shipment|
            shipment << XmlNode.new('ShipTimestamp', @shipping_options[:ship_timestamp] ||= Time.now.utc.iso8601(2))
            shipment << XmlNode.new('DropoffType', @shipping_options[:drop_off_type] ||= "REGULAR_PICKUP")
            shipment << XmlNode.new('ServiceType', @shipping_options[:service_type])
            shipment << XmlNode.new('PackagingType', @shipping_options[:packaging_type] ||= "YOUR_PACKAGING")
            add_total_weight(shipment) if @mps.has_key?(:total_weight)
            # shipment << build_location_node('Shipper', (@shipping_options[:shipper] || origin))
            # shipment << build_location_node('Recipient', destination)
            # if @shipping_options[:shipper] and @shipping_options[:shipper] != origin
            #   shipment << build_location_node('Origin', origin)
            # end
            add_shipper(shipment, origin)
            add_recipient(shipment, destination)
            add_shipping_charges_payment(shipment, origin)

            add_special_services(shipment) if @shipping_options[:return_reason]
            add_hold_at_location(shipment) if @shipping_options[:hold_at_location]
            shipment << XmlNode.new('LabelSpecification') do |label|
              label << XmlNode.new('LabelFormatType', "COMMON2D")
              label << XmlNode.new('ImageType', "PDF")
              label << XmlNode.new('LabelStockType', "PAPER_LETTER")
            end
            shipment << build_rate_request_types_node
            shipment << XmlNode.new('PackageCount', packages.size)
            # add_customs_clearance(xml) if @customs_clearance_detail
            # add_custom_components(xml)

            imperial = %w(US LR MM).include?(origin.country_code(:alpha2))


            shipment << build_packages_nodes(packages, imperial)
            # add_packages(shipment, packages)
          end
        end
        xml_request.to_s
      end

      def add_total_weight(shipment)
        if @mps.has_key?(:total_weight)
          shipment << XmlNode.new('TotalWeight') do |total_weight|
            total_weight << XmlNode.new('Units', @shipping_options[:mps][:total_weight][:units])
            total_weight << XmlNode.new('Value', @shipping_options[:mps][:total_weight][:value])
          end
        end
      end

      def add_shipper(shipment, origin)
        shipment << XmlNode.new('Shipper') do |shipper|
          shipper << XmlNode.new('Contact') do |contact|
            contact << XmlNode.new('PersonName', origin.name)
            contact << XmlNode.new('CompanyName', origin.company_name)
            contact << XmlNode.new('PhoneNumber', origin.phone)
          end
          shipper << XmlNode.new('Address') do |address|
            [:address1, :address2, :address3].each do |field|
              line = origin.send(field)
              address << XmlNode.new('StreetLines', line) if line
            end
            address << XmlNode.new('City', origin.city)
            address << XmlNode.new('StateOrProvinceCode', origin.province)
            address << XmlNode.new('PostalCode', origin.postal_code)
            address << XmlNode.new('CountryCode', origin.country_code)
            address << XmlNode.new('CountryName', origin.country)
          end
        end
      end

      def add_recipient(shipment, destination)
        shipment << XmlNode.new('Recipient') do |recipient|
          recipient << XmlNode.new('Contact') do |contact|
            contact << XmlNode.new('PersonName', destination.name)
            contact << XmlNode.new('CompanyName', destination.company_name)
            contact << XmlNode.new('PhoneNumber', destination.phone)
          end
          recipient << XmlNode.new('Address') do |address|
            [:address1, :address2, :address3].each do |field|
              line = destination.send(field)
              address << XmlNode.new('StreetLines', line) if line
            end
            address << XmlNode.new('City', destination.city)
            address << XmlNode.new('StateOrProvinceCode', destination.province)
            address << XmlNode.new('PostalCode', destination.postal_code)
            address << XmlNode.new('CountryCode', destination.country_code)
            address << XmlNode.new('CountryName', destination.country)
            address << XmlNode.new('Residential', destination.residential?)
          end
        end
      end

      def add_shipping_charges_payment(shipment, origin)
        shipment << XmlNode.new('ShippingChargesPayment') do |payment|
          payment << XmlNode.new('PaymentType', @payment_options[:type] || 'SENDER')
          payment << XmlNode.new('Payor') do |payor|
            payor << XmlNode.new('ResponsibleParty') do |rp|
              rp << XmlNode.new('AccountNumber', @payment_options[:account_number] || @options[:account])
              rp << XmlNode.new('Contact') do |contact|
                contact << XmlNode.new('PersonName', @payment_options[:name] || origin.name)
                contact << XmlNode.new('CompanyName', @payment_options[:company] || origin.company_name)
                contact << XmlNode.new('PhoneNumber', @payment_options[:phone] || origin.phone)
              end
            end
          end
        end
      end

      def add_special_services(xml)
        xml.SpecialServicesRequested {
          xml.SpecialServiceTypes "RETURN_SHIPMENT"
          xml.ReturnShipmentDetail {
            xml.ReturnType "PRINT_RETURN_LABEL"
            xml.Rma {
              xml.Reason "#{@shipping_options[:return_reason]}"
            }
          }
        }
      end

      def add_hold_at_location(shipment)
        active_location = @shipping_options[:hold_at_location]
        shipment << XmlNode.new('SpecialServicesRequested') do |ss|
          ss << XmlNode.new('SpecialServiceTypes', 'HOLD_AT_LOCATION')
          ss << XmlNode.new('HoldAtLocationDetail') do |hal|
            hal << XmlNode.new('PhoneNumber', active_location.phone_number.gsub(/\(/, '').gsub(') ', '-'))
            hal << XmlNode.new('LocationContactAndAddress') do |location|
              # if @shipping_options[:hold_at_location][:contact]
                location << XmlNode.new('Contact') do |contact|
                  # contact << XmlNode.new('PersonName', @shipping_options[:hold_at_location][:contact][:phone_number])
                  # contact << XmlNode.new('CompanyName', @shipping_options[:hold_at_location][:contact][:company_name])
                  contact << XmlNode.new('PhoneNumber', active_location.phone_number.gsub(/\(/, '').gsub(') ', '-'))
                end
              # end
              location << XmlNode.new('Address') do |address|
                # [:address1, :address2, :address3].each do |field|
                #   line = active_location.send(field)
                #   address << XmlNode.new('StreetLines', line) if line
                # end
                address << XmlNode.new('StreetLines', active_location.address)
                address << XmlNode.new('City', active_location.city)
                address << XmlNode.new('StateOrProvinceCode', active_location.state)
                address << XmlNode.new('PostalCode', active_location.postal_code)
                address << XmlNode.new('CountryCode', active_location.country_code)
                address << XmlNode.new('Residential', 'false')
              end
            end

          end
        end
      end

      # def add_packages(shipment, packages)
      #   add_master_tracking_id(shipment) if @mps.has_key? :master_tracking_id
      #   package_count = packages.size
      #   if @mps.has_key? :package_count
      #
      #     shipment << XmlNode.new('PackageCount', @mps[:package_count])
      #   else
      #     shipment << XmlNode.new('PackageCount', package_count)
      #   end
      #   packages.each do |package|
      #     shipment << XmlNode.new('RequestedPackageLineItems') do |pkg|
      #       if @mps.has_key? :sequence_number
      #         pkg << XmlNode.new('SequenceNumber', @mps[:sequence_number])
      #       else
      #         pkg << XmlNode.new('GroupPackageCount', 1)
      #       end
      #       if package.value
      #         pkg << XmlNode.new('InsuredValue') do |val|
      #           val << XmlNode.new('Currency', package.currency)
      #           val << XmlNode.new('Amount', package.value)
      #         end
      #       end
      #       pkg << XmlNode.new('Weight') do | weight |
      #         weight << XmlNode.new('Units', 'LB')
      #         weight << XmlNode.new('Value', package.pounds)
      #       end
      #       if package.inches
      #         pkg << XmlNode.new('Dimensions') do |dimensions|
      #           dimensions << XmlNode.new('Length', package.inches[0])
      #           dimensions << XmlNode.new('Width', package.inches[1])
      #           dimensions << XmlNode.new('Height', package.inches[2])
      #           dimensions << XmlNode.new('Units', 'IN')
      #         end
      #       end
      #     end
      #   end
      #
      #     #   add_customer_references(xml, package)
      #     #   if package[:special_services_requested] && package[:special_services_requested][:special_service_types]
      #     #     xml.SpecialServicesRequested {
      #     #       if package[:special_services_requested][:special_service_types].is_a? Array
      #     #         package[:special_services_requested][:special_service_types].each do |type|
      #     #           xml.SpecialServiceTypes type
      #     #         end
      #     #       else
      #     #         xml.SpecialServiceTypes package[:special_services_requested][:special_service_types]
      #     #       end
      #     #       # Handle COD Options
      #     #       if package[:special_services_requested][:cod_detail]
      #     #         xml.CodDetail {
      #     #           xml.CodCollectionAmount {
      #     #             xml.Currency package[:special_services_requested][:cod_detail][:cod_collection_amount][:currency]
      #     #             xml.Amount package[:special_services_requested][:cod_detail][:cod_collection_amount][:amount]
      #     #           }
      #     #           if package[:special_services_requested][:cod_detail][:add_transportation_charges]
      #     #             xml.AddTransportationCharges package[:special_services_requested][:cod_detail][:add_transportation_charges]
      #     #           end
      #     #           xml.CollectionType package[:special_services_requested][:cod_detail][:collection_type]
      #     #           xml.CodRecipient {
      #     #             add_shipper(xml)
      #     #           }
      #     #           if package[:special_services_requested][:cod_detail][:reference_indicator]
      #     #             xml.ReferenceIndicator package[:special_services_requested][:cod_detail][:reference_indicator]
      #     #           end
      #     #         }
      #     #       end
      #     #       # DangerousGoodsDetail goes here
      #     #       if package[:special_services_requested][:dry_ice_weight]
      #     #         xml.DryIceWeight {
      #     #           xml.Units package[:special_services_requested][:dry_ice_weight][:units]
      #     #           xml.Value package[:special_services_requested][:dry_ice_weight][:value]
      #     #         }
      #     #       end
      #     #       if package[:special_services_requested][:signature_option_detail]
      #     #         xml.SignatureOptionDetail {
      #     #           xml.OptionType package[:special_services_requested][:signature_option_detail][:signature_option_type]
      #     #         }
      #     #       end
      #     #       if package[:special_services_requested][:priority_alert_detail]
      #     #         xml.PriorityAlertDetail package[:special_services_requested][:priority_alert_detail]
      #     #       end
      #     #     }
      #     #   end
      #     #   }
      #     # end
      #   end

      def add_master_tracking_id(xml)
        if @mps.has_key? :master_tracking_id
          xml.MasterTrackingId {
            xml.TrackingIdType @mps[:master_tracking_id][:tracking_id_type]
            xml.TrackingNumber @mps[:master_tracking_id][:tracking_number]
          }
        end
      end

      def build_location_request(destination)
        xml_request = XmlNode.new('SearchLocationsRequest', 'xmlns' => 'http://fedex.com/ws/locs/v1') do |root_node|
          root_node << build_request_header
          root_node << build_location_version_node
          root_node << XmlNode.new('LocationsSearchCriterion', "ADDRESS")
          root_node << XmlNode.new('Address') do |address|
            address << XmlNode.new('StreetLines', destination.address1)
            address << XmlNode.new('City', destination.city)
            address << XmlNode.new('StateOrProvinceCode', destination.state)
            address << XmlNode.new('PostalCode', destination.postal_code)
            address << XmlNode.new('CountryCode', destination.country_code)
          end
          root_node << XmlNode.new('MultipleMatchesAction', 'RETURN_ALL')
          root_node << XmlNode.new('SortDetail') do |sort|
            sort << XmlNode.new('Criterion', 'DISTANCE')
            sort << XmlNode.new('Order', 'LOWEST_TO_HIGHEST')
          end
          if @options[:constraints]
            root_node << XmlNode.new('Constraints') do |constraints|
              constraints << XmlNode.new('RequiredLocationAttributes', @options[:constraints][:required_location_attributes].join(','))
            end
          end
        end
        xml_request.to_s
      end

      def build_location_version_node
        XmlNode.new('Version') do |version_node|
          version_node << XmlNode.new('ServiceId', 'locs')
          version_node << XmlNode.new('Major', '1')
          version_node << XmlNode.new('Intermediate', '0')
          version_node << XmlNode.new('Minor', '0')
        end
      end


      def build_rate_request(origin, destination, packages, options = {})
        imperial = %w(US LR MM).include?(origin.country_code(:alpha2))

        xml_request = XmlNode.new('RateRequest', 'xmlns' => 'http://fedex.com/ws/rate/v13') do |root_node|
          root_node << build_request_header
          root_node << build_version_node

          # Returns delivery dates
          root_node << XmlNode.new('ReturnTransitAndCommit', true)
          # Returns saturday delivery shipping options when available
          root_node << XmlNode.new('VariableOptions', 'SATURDAY_DELIVERY')

          root_node << XmlNode.new('RequestedShipment') do |rs|
            rs << XmlNode.new('ShipTimestamp', ship_timestamp(options[:turn_around_time]))

            freight = has_freight?(options)

            unless freight
              # fedex api wants this up here otherwise request returns an error
              rs << XmlNode.new('DropoffType', options[:dropoff_type] || 'REGULAR_PICKUP')
              rs << XmlNode.new('PackagingType', options[:packaging_type] || 'YOUR_PACKAGING')
            end

            rs << build_location_node('Shipper', (options[:shipper] || origin))
            rs << build_location_node('Recipient', destination)
            if options[:shipper] and options[:shipper] != origin
              rs << build_location_node('Origin', origin)
            end

            add_hold_at_location(rs) if @shipping_options[:hold_at_location]

            if freight
              # build xml for freight rate requests
              freight_options = options[:freight]
              rs << build_shipping_charges_payment_node(freight_options)
              rs << build_freight_shipment_detail_node(freight_options, packages, imperial)
              rs << build_rate_request_types_node
            else
              # build xml for non-freight rate requests
              rs << XmlNode.new('SmartPostDetail') do |spd|
                spd << XmlNode.new('Indicia', options[:smart_post_indicia] || 'PARCEL_SELECT')
                spd << XmlNode.new('HubId', options[:smart_post_hub_id] || 5902) # default to LA
              end

              rs << build_rate_request_types_node
              rs << XmlNode.new('PackageCount', packages.size)
              rs << build_packages_nodes(packages, imperial)

            end
          end

        end
        xml_request.to_s
      end

      def build_packages_nodes(packages, imperial)
        packages.map do |pkg|
          XmlNode.new('RequestedPackageLineItems') do |rps|
            rps << XmlNode.new('GroupPackageCount', 1)
            rps << build_package_weight_node(pkg, imperial)
            rps << build_package_dimensions_node(pkg, imperial)
          end
        end
      end

      def build_shipping_charges_payment_node(freight_options)
        XmlNode.new('ShippingChargesPayment') do |shipping_charges_payment|
          shipping_charges_payment << XmlNode.new('PaymentType', freight_options[:payment_type])
          shipping_charges_payment << XmlNode.new('Payor') do |payor|
            payor << XmlNode.new('ResponsibleParty') do |responsible_party|
              # TODO: case of different freight account numbers?
              responsible_party << XmlNode.new('AccountNumber', freight_options[:account])
            end
          end
        end
      end

      def build_freight_shipment_detail_node(freight_options, packages, imperial)
        XmlNode.new('FreightShipmentDetail') do |freight_shipment_detail|
          # TODO: case of different freight account numbers?
          freight_shipment_detail << XmlNode.new('FedExFreightAccountNumber', freight_options[:account])
          freight_shipment_detail << build_location_node('FedExFreightBillingContactAndAddress', freight_options[:billing_location])
          freight_shipment_detail << XmlNode.new('Role', freight_options[:role])

          packages.each do |pkg|
            freight_shipment_detail << XmlNode.new('LineItems') do |line_items|
              line_items << XmlNode.new('FreightClass', freight_options[:freight_class])
              line_items << XmlNode.new('Packaging', freight_options[:packaging])
              line_items << build_package_weight_node(pkg, imperial)
              line_items << build_package_dimensions_node(pkg, imperial)
            end
          end
        end
      end

      def has_freight?(options)
        options[:freight] && options[:freight].present?
      end

      def build_package_weight_node(pkg, imperial)
        XmlNode.new('Weight') do |tw|
          tw << XmlNode.new('Units', imperial ? 'LB' : 'KG')
          tw << XmlNode.new('Value', [((imperial ? pkg.lbs : pkg.kgs).to_f * 1000).round / 1000.0, 0.1].max)
        end
      end

      def build_version_node(service_id='crs')
        XmlNode.new('Version') do |version_node|
          version_node << XmlNode.new('ServiceId', service_id)
          version_node << XmlNode.new('Major', '13')
          version_node << XmlNode.new('Intermediate', '0')
          version_node << XmlNode.new('Minor', '0')
        end
      end

      def build_package_dimensions_node(pkg, imperial)
        XmlNode.new('Dimensions') do |dimensions|
          [:length, :width, :height].each do |axis|
            value = ((imperial ? pkg.inches(axis) : pkg.cm(axis)).to_f * 1000).round / 1000.0 # 3 decimals
            dimensions << XmlNode.new(axis.to_s.capitalize, value.ceil)
          end
          dimensions << XmlNode.new('Units', imperial ? 'IN' : 'CM')
        end
      end

      def build_rate_request_types_node(type = 'ACCOUNT')
        XmlNode.new('RateRequestTypes', type)
      end

      def build_tracking_request(tracking_number, options = {})
        xml_request = XmlNode.new('TrackRequest', 'xmlns' => 'http://fedex.com/ws/track/v3') do |root_node|
          root_node << build_request_header

          # Version
          root_node << XmlNode.new('Version') do |version_node|
            version_node << XmlNode.new('ServiceId', 'trck')
            version_node << XmlNode.new('Major', '3')
            version_node << XmlNode.new('Intermediate', '0')
            version_node << XmlNode.new('Minor', '0')
          end

          root_node << XmlNode.new('PackageIdentifier') do |package_node|
            package_node << XmlNode.new('Value', tracking_number)
            package_node << XmlNode.new('Type', PACKAGE_IDENTIFIER_TYPES[options['package_identifier_type'] || 'tracking_number'])
          end

          root_node << XmlNode.new('ShipDateRangeBegin', options['ship_date_range_begin']) if options['ship_date_range_begin']
          root_node << XmlNode.new('ShipDateRangeEnd', options['ship_date_range_end']) if options['ship_date_range_end']
          root_node << XmlNode.new('IncludeDetailedScans', 1)
        end
        xml_request.to_s
      end

      def build_request_header
        web_authentication_detail = XmlNode.new('WebAuthenticationDetail') do |wad|
          wad << XmlNode.new('UserCredential') do |uc|
            uc << XmlNode.new('Key', @options[:key])
            uc << XmlNode.new('Password', @options[:password])
          end
        end

        client_detail = XmlNode.new('ClientDetail') do |cd|
          cd << XmlNode.new('AccountNumber', @options[:account])
          cd << XmlNode.new('MeterNumber', @options[:login])
        end

        trasaction_detail = XmlNode.new('TransactionDetail') do |td|
          td << XmlNode.new('CustomerTransactionId', @options[:transaction_id] || 'ActiveShipping') # TODO: Need to do something better with this..
        end

        [web_authentication_detail, client_detail, trasaction_detail]
      end

      def build_location_node(name, location)
        XmlNode.new(name) do |xml_node|
          xml_node << XmlNode.new('Address') do |address_node|
            address_node << XmlNode.new('StreetLines', location.address1) if location.address1
            address_node << XmlNode.new('StreetLines', location.address2) if location.address2
            address_node << XmlNode.new('City', location.city) if location.city
            address_node << XmlNode.new('PostalCode', location.postal_code)
            address_node << XmlNode.new("CountryCode", location.country_code(:alpha2))

            address_node << XmlNode.new("Residential", true) unless location.commercial?
          end
        end
      end

      def parse_rate_response(origin, destination, packages, response, options)
        rate_estimates = []

        xml = build_document(response)
        root_node = xml.elements['RateReply']

        success = response_success?(xml)
        message = response_message(xml)

        raise ActiveMerchant::Shipping::ResponseContentError.new(StandardError.new('Invalid document'), xml) unless root_node

        root_node.elements.each('RateReplyDetails') do |rated_shipment|
          service_code = rated_shipment.get_text('ServiceType').to_s
          is_saturday_delivery = rated_shipment.get_text('AppliedOptions').to_s == 'SATURDAY_DELIVERY'
          service_type = is_saturday_delivery ? "#{service_code}_SATURDAY_DELIVERY" : service_code

          transit_time = rated_shipment.get_text('TransitTime').to_s if service_code == "FEDEX_GROUND"
          max_transit_time = rated_shipment.get_text('MaximumTransitTime').to_s if service_code == "FEDEX_GROUND"

          delivery_timestamp = rated_shipment.get_text('DeliveryTimestamp').to_s

          delivery_range = delivery_range_from(transit_time, max_transit_time, delivery_timestamp, options)

          currency = rated_shipment.get_text('RatedShipmentDetails/ShipmentRateDetail/TotalNetCharge/Currency').to_s
          rate_estimates << RateEstimate.new(origin, destination, @@name,
                                             self.class.service_name_for_code(service_type),
                                             :service_code => service_code,
                                             :total_price => rated_shipment.get_text('RatedShipmentDetails/ShipmentRateDetail/TotalNetCharge/Amount').to_s.to_f,
                                             :currency => currency,
                                             :packages => packages,
                                             :delivery_range => delivery_range)
        end

        if rate_estimates.empty?
          success = false
          message = "No shipping rates could be found for the destination address" if message.blank?
        end

        RateResponse.new(success, message, Hash.from_xml(response), :rates => rate_estimates, :xml => response, :request => last_request, :log_xml => options[:log_xml])
      end

      def delivery_range_from(transit_time, max_transit_time, delivery_timestamp, options)
        delivery_range = [delivery_timestamp, delivery_timestamp]

        # if there's no delivery timestamp but we do have a transit time, use it
        if delivery_timestamp.blank? && transit_time.present?
          transit_range = parse_transit_times([transit_time, max_transit_time.presence || transit_time])
          delivery_range = transit_range.map { |days| business_days_from(ship_date(options[:turn_around_time]), days) }
        end

        delivery_range
      end

      def business_days_from(date, days)
        future_date = date
        count = 0

        while count < days
          future_date += 1.day
          count += 1 if business_day?(future_date)
        end

        future_date
      end

      def business_day?(date)
        (1..5).include?(date.wday)
      end

      def parse_tracking_response(response, options)
        xml = build_document(response)
        root_node = xml.elements['TrackReply']

        success = response_success?(xml)
        message = response_message(xml)

        if success
          origin = nil
          delivery_signature = nil
          shipment_events = []

          tracking_details = root_node.elements['TrackDetails']
          tracking_number = tracking_details.get_text('TrackingNumber').to_s
          status_code = tracking_details.get_text('StatusCode').to_s
          status_description = tracking_details.get_text('StatusDescription').to_s
          status = TRACKING_STATUS_CODES[status_code]

          if status_code == 'DL' && tracking_details.get_text('SignatureProofOfDeliveryAvailable').to_s == 'true'
            delivery_signature = tracking_details.get_text('DeliverySignatureName').to_s
          end

          origin_node = tracking_details.elements['OriginLocationAddress']

          if origin_node
            origin = Location.new(
                :country => origin_node.get_text('CountryCode').to_s,
                :province => origin_node.get_text('StateOrProvinceCode').to_s,
                :city => origin_node.get_text('City').to_s
            )
          end

          destination = extract_address(tracking_details, DELIVERY_ADDRESS_NODE_NAMES)
          shipper_address = extract_address(tracking_details, SHIPPER_ADDRESS_NODE_NAMES)

          ship_time = extract_timestamp(tracking_details, 'ShipTimestamp')
          actual_delivery_time = extract_timestamp(tracking_details, 'ActualDeliveryTimestamp')
          scheduled_delivery_time = extract_timestamp(tracking_details, 'EstimatedDeliveryTimestamp')

          tracking_details.elements.each('Events') do |event|
            address = event.elements['Address']

            city = address.get_text('City').to_s
            state = address.get_text('StateOrProvinceCode').to_s
            zip_code = address.get_text('PostalCode').to_s
            country = address.get_text('CountryCode').to_s
            next if country.blank?

            location = Location.new(:city => city, :state => state, :postal_code => zip_code, :country => country)
            description = event.get_text('EventDescription').to_s

            time = Time.parse("#{event.get_text('Timestamp').to_s}")
            zoneless_time = time.utc

            shipment_events << ShipmentEvent.new(description, zoneless_time, location)
          end
          shipment_events = shipment_events.sort_by(&:time)

        end

        TrackingResponse.new(success, message, Hash.from_xml(response),
                             :carrier => @@name,
                             :xml => response,
                             :request => last_request,
                             :status => status,
                             :status_code => status_code,
                             :status_description => status_description,
                             :ship_time => ship_time,
                             :scheduled_delivery_date => scheduled_delivery_time,
                             :actual_delivery_date => actual_delivery_time,
                             :delivery_signature => delivery_signature,
                             :shipment_events => shipment_events,
                             :shipper_address => (shipper_address.nil? || shipper_address.unknown?) ? nil : shipper_address,
                             :origin => origin,
                             :destination => destination,
                             :tracking_number => tracking_number
        )
      end

      def ship_timestamp(delay_in_hours)
        delay_in_hours ||= 0
        Time.now + delay_in_hours.hours
      end

      def ship_date(delay_in_hours)
        delay_in_hours ||= 0
        (Time.now + delay_in_hours.hours).to_date
      end

      def response_status_node(document)
        document.elements['/*/Notifications/']
      end

      def response_success?(document)
        response_node = response_status_node(document)
        return false if response_node.nil?

        %w(SUCCESS WARNING NOTE).include? response_node.get_text('Severity').to_s
      end

      def response_message(document)
        response_node = response_status_node(document)
        return "" if response_node.nil?

        "#{response_node.get_text('Severity')} - #{response_node.get_text('Code')}: #{response_node.get_text('Message')}"
      end

      def commit(request, test = false)
        ssl_post(test ? TEST_URL : LIVE_URL, request.gsub("\n", ''))
      end

      def parse_transit_times(times)
        results = []
        times.each do |day_count|
          days = TRANSIT_TIMES.index(day_count.to_s.chomp)
          results << days.to_i
        end
        results
      end

      def extract_address(document, possible_node_names)
        node = nil
        possible_node_names.each do |name|
          node ||= document.elements[name]
          break if node
        end

        args = if node && node.elements['CountryCode']
                 {
                     :country => node.get_text('CountryCode').to_s,
                     :province => node.get_text('StateOrProvinceCode').to_s,
                     :city => node.get_text('City').to_s
                 }
               else
                 {
                     :country => ActiveMerchant::Country.new(:alpha2 => 'ZZ', :name => 'Unknown or Invalid Territory', :alpha3 => 'ZZZ', :numeric => '999'),
                     :province => 'unknown',
                     :city => 'unknown'
                 }
               end

        Location.new(args)
      end

      def extract_timestamp(document, node_name)
        if timestamp_node = document.elements[node_name]
          Time.parse(timestamp_node.to_s).utc
        end
      end

      def remove_version_prefix(xml)
        if xml =~ /xmlns:v[0-9]/
          xml.gsub(/<(\/)?.*?\:(.*?)>/, '<\1\2>')
        else
          xml
        end
      end

      def build_document(xml)
        REXML::Document.new(xml)
      rescue REXML::ParseException => e
        raise ActiveMerchant::Shipping::ResponseContentError.new(e, xml)
      end
    end

    class FedexShippingResponse < ShippingResponse
      attr_reader :label
      def initialize(success, message, params = {}, options = {})
        super
        @label = options[:label]
      end
    end
  end
end
