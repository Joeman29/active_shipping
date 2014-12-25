require 'test_helper'
require 'unit/carriers/fedex_account'

class FedExTest < MiniTest::Unit::TestCase
  include FedexAccount

  def setup
    @packages = TestFixtures.packages
    @locations = TestFixtures.locations
    @carrier = account
    @tracking_response = xml_fixture('fedex/tracking_response')
  end

  def test_build_shipment_request
    options = {
        shipping_options: {
            service_type: 'FEDEX_GROUND'
        },
        # payment_options:{
        #
        # }
        test: true
    }
    puts @carrier.create_shipment(@locations[:new_york_with_name], @locations[:annapolis], [@packages[:wii]], options)
  end

  def test_build_shipment_request_with_hold_at_location
    options = {
        shipping_options: {
            service_type: 'FEDEX_GROUND',
            hold_at_location: {
                      :hold_at_location => {
            phone_number: info[:contact][:phone_number].gsub(/\(/, '').gsub(') ', '-'),
            address: address_fields(info[:address]),
            contact: {
                phone_number: info[:contact][:phone_number].gsub(/\(/, '').gsub(') ', '-')
            }
        }
            }
        },
        # payment_options:{
        #
        # }
        test: true
    }
    puts @carrier.create_shipment(@locations[:new_york_with_name], @locations[:annapolis], [@packages[:wii]], options)
  end

end