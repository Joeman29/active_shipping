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
        shipping_options:{
          service_type: 'FEDEX_GROUND'
        },
        # payment_options:{
        #
        # }
        test: true
    }
    puts @carrier.create_shipment(@locations[:new_york_with_name], @locations[:annapolis], [@packages[:wii]], options)
  end

end