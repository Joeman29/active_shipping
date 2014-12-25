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

  # def test_build_shipment_request
  #   options = {
  #       shipping_options: {
  #           service_type: 'FEDEX_GROUND'
  #       },
  #       # payment_options:{
  #       #
  #       # }
  #       test: true
  #   }
  #   puts @carrier.create_shipment(@locations[:new_york_with_name], @locations[:annapolis], [@packages[:wii]], options)
  # end

  # def test_build_shipment_request_with_hold_at_location
  #   options = {
  #       shipping_options: {
  #           service_type: 'FEDEX_GROUND',
  #           hold_at_location: {
  #               phone_number: '(973) 376-3966'.gsub(/\(/, '').gsub(') ', '-'),
  #               address: {
  #                   address1: '55 US Hwy 22',
  #                   city: 'Springfield',
  #                   state: 'NJ',
  #                   postal_code: '07081',
  #                   country_code: 'US',
  #                   country_name: 'USA'
  #               },
  #               contact: {
  #                   phone_number: '(973) 376-3966'.gsub(/\(/, '').gsub(') ', '-')
  #               }
  #           }
  #       },
  #       # payment_options:{
  #       #
  #       # }
  #       test: true
  #   }
  #   puts @carrier.create_shipment(@locations[:new_york_with_name], @locations[:annapolis], [@packages[:wii]], options)
  # end


end