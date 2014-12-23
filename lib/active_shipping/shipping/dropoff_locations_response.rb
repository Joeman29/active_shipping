module ActiveMerchant #:nodoc:
  module Shipping #:nodoc:
    class DropoffLocationsResponse < Response
      attr_accessor :target_address

      def initialize(success, message, params = {}, options = {})
        @root = params['SearchLocationsReply'] #['AddressToLocationRelationships']
        matched_address = @root['AddressToLocationRelationships'].delete('MatchedAddress')
        @target_address = {
            address: matched_address['StreetLines'],
            city: matched_address['City'],
            postal_code: matched_address['PostalCode'],
            state: matched_address['StateOrProvinceCode'],
            coordinates: @root['AddressToLocationRelationships'].delete('MatchedAddressGeographicCoordinates')
        }
        #['AddressToLocationRelationships']#['DistanceAndLocationDetails']
        super
      end

      def locations
        return @locations if @locations
        @locations = @root['AddressToLocationRelationships']['DistanceAndLocationDetails'].map do |loc|
            DropoffLocation.new(loc['LocationDetail'])
        end.compact
      end

    end
  end
end
