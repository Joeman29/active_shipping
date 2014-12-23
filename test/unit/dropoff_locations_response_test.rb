require 'test_helper'

class DropoffLocationsResponseTest < Test::Unit::TestCase
  include ActiveMerchant::Shipping

  def setup
    @locations = TestFixtures.locations.dup
  end

  def test_build_locations_from_xml_response
    str      = xml_fixture('fedex/dropoff_locations_response')
    mapping  = Hash.from_xml(str)
    response = DropoffLocationsResponse.new(true, nil, mapping)

    assert_equal '520 Westfield Ave', response.locations.first.address
    assert_equal 'Elizabeth', response.locations.first.city
    assert_equal '125 Springfield Rd', response.target_address[:address]
  end
end