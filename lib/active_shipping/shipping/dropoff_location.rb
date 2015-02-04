module ActiveMerchant #:nodoc:
  module Shipping #:nodoc:
    class DropoffLocation
      attr_accessor :id, :address, :city, :postal_code, :country_code, :state, :residential, :coordinates, :fedex_attributes, :phone_number, :type, :name, :email

      def initialize(params=nil, options=nil)
        if params
          @id = params['LocationId']
          addr = params['LocationContactAndAddress']['Address']
          @address = addr['StreetLines']
          @city = addr['City']
          @postal_code =addr['PostalCode']
          @country_code =addr['CountryCode']
          @state = addr['StateOrProvinceCode']
          @residential = (addr['Residential']=='true')
          @coordinates = params['GeographicCoordinates']
          @fedex_attributes = params['Attributes']
          @type = params['LocationType']
          contact = params['LocationContactAndAddress']['Contact']
          if contact
            @phone_number = contact['PhoneNumber']
            @name = contact['CompanyName']
            @email = contact['EMailAddress']
          end
        end
      end
    end
  end
end


# <DistanceAndLocationDetails>
#       <Distance>
#         <Value>0.22218984639969544</Value>
#         <Units>MI</Units>
#       </Distance>
#       <LocationDetail>
#         <LocationId>70634</LocationId>
#         <StoreNumber>0</StoreNumber>
#         <LocationContactAndAddress>
#           <Address>
#             <StreetLines>520 Westfield Ave</StreetLines>
#             <City>Elizabeth</City>
#             <StateOrProvinceCode>NJ</StateOrProvinceCode>
#             <PostalCode>07208</PostalCode>
#             <CountryCode>US</CountryCode>
#             <Residential>false</Residential>
#           </Address>
#           <AddressAncillaryDetail>
#             <LocationInCity>Central</LocationInCity>
#             <LocationInProperty>Front/tracker Dropbx</LocationInProperty>
#             <Accessibility>OUTSIDE</Accessibility>
#             <AdditionalDescriptions>Proffessional Center - Outside</AdditionalDescriptions>
#             <AdditionalDescriptions>FedEx Express Drop Box</AdditionalDescriptions>
#           </AddressAncillaryDetail>
#         </LocationContactAndAddress>
#         <GeographicCoordinates>+40.665702-74.232837/</GeographicCoordinates>
#         <LocationType>FEDEX_SELF_SERVICE_LOCATION</LocationType>
#         <Attributes>ALREADY_OPEN</Attributes>
#         <Attributes>DROP_BOX</Attributes>
#         <Attributes>EXPRESS_PARCEL_DROPOFFS</Attributes>
#         <MapUrl>https://maps.googleapis.com/maps/api/staticmap?size=350x350&amp;center=+40.665702,-74.232837&amp;zoom=15&amp;markers=color:blue%7Clabel:A%7C520+Westfield+Ave%2CElizabeth%2CNJ%2C07208&amp;maptype=roadmap&amp;sensor=false</MapUrl>
#         <NormalHours>
#           <DayofWeek>MON</DayofWeek>
#           <OperationalHours>CLOSED_ALL_DAY</OperationalHours>
#         </NormalHours>
#         <NormalHours>
#           <DayofWeek>TUE</DayofWeek>
#           <OperationalHours>CLOSED_ALL_DAY</OperationalHours>
#         </NormalHours>
#         <NormalHours>
#           <DayofWeek>WED</DayofWeek>
#           <OperationalHours>CLOSED_ALL_DAY</OperationalHours>
#         </NormalHours>
#         <NormalHours>
#           <DayofWeek>THU</DayofWeek>
#           <OperationalHours>CLOSED_ALL_DAY</OperationalHours>
#         </NormalHours>
#         <NormalHours>
#           <DayofWeek>FRI</DayofWeek>
#           <OperationalHours>CLOSED_ALL_DAY</OperationalHours>
#         </NormalHours>
#         <NormalHours>
#           <DayofWeek>SAT</DayofWeek>
#           <OperationalHours>CLOSED_ALL_DAY</OperationalHours>
#         </NormalHours>
#         <NormalHours>
#           <DayofWeek>SUN</DayofWeek>
#           <OperationalHours>CLOSED_ALL_DAY</OperationalHours>
#         </NormalHours>
#         <HoursForEffectiveDate>
#           <DayofWeek>MON</DayofWeek>
#           <OperationalHours>CLOSED_ALL_DAY</OperationalHours>
#         </HoursForEffectiveDate>
#         <HoursForEffectiveDate>
#           <DayofWeek>TUE</DayofWeek>
#           <OperationalHours>CLOSED_ALL_DAY</OperationalHours>
#         </HoursForEffectiveDate>
#         <HoursForEffectiveDate>
#           <DayofWeek>WED</DayofWeek>
#           <OperationalHours>CLOSED_ALL_DAY</OperationalHours>
#         </HoursForEffectiveDate>
#         <HoursForEffectiveDate>
#           <DayofWeek>THU</DayofWeek>
#           <OperationalHours>CLOSED_ALL_DAY</OperationalHours>
#         </HoursForEffectiveDate>
#         <HoursForEffectiveDate>
#           <DayofWeek>FRI</DayofWeek>
#           <OperationalHours>CLOSED_ALL_DAY</OperationalHours>
#         </HoursForEffectiveDate>
#         <HoursForEffectiveDate>
#           <DayofWeek>SAT</DayofWeek>
#           <OperationalHours>CLOSED_ALL_DAY</OperationalHours>
#         </HoursForEffectiveDate>
#         <HoursForEffectiveDate>
#           <DayofWeek>SUN</DayofWeek>
#           <OperationalHours>CLOSED_ALL_DAY</OperationalHours>
#         </HoursForEffectiveDate>
#         <CarrierDetails>
#           <Carrier>FDXE</Carrier>
#           <NormalLatestDropOffDetails>
#             <DayOfWeek>MON</DayOfWeek>
#             <Time>20:00:00</Time>
#           </NormalLatestDropOffDetails>
#           <NormalLatestDropOffDetails>
#             <DayOfWeek>TUE</DayOfWeek>
#             <Time>20:00:00</Time>
#           </NormalLatestDropOffDetails>
#           <NormalLatestDropOffDetails>
#             <DayOfWeek>WED</DayOfWeek>
#             <Time>20:00:00</Time>
#           </NormalLatestDropOffDetails>
#           <NormalLatestDropOffDetails>
#             <DayOfWeek>FRI</DayOfWeek>
#             <Time>20:00:00</Time>
#           </NormalLatestDropOffDetails>
#           <ExceptionalLatestDropOffDetails>
#             <DayOfWeek>WED</DayOfWeek>
#             <Time>16:00:00</Time>
#           </ExceptionalLatestDropOffDetails>
#           <EffectiveLatestDropOffDetails>
#             <DayOfWeek>TUE</DayOfWeek>
#             <Time>20:00:00</Time>
#           </EffectiveLatestDropOffDetails>
#         </CarrierDetails>
#         <CarrierDetails>
#           <Carrier>FDXE</Carrier>
#           <ServiceCategory>EXPRESS_PARCEL</ServiceCategory>
#           <NormalLatestDropOffDetails>
#             <DayOfWeek>MON</DayOfWeek>
#             <Time>20:00:00</Time>
#           </NormalLatestDropOffDetails>
#           <NormalLatestDropOffDetails>
#             <DayOfWeek>TUE</DayOfWeek>
#             <Time>20:00:00</Time>
#           </NormalLatestDropOffDetails>
#           <NormalLatestDropOffDetails>
#             <DayOfWeek>WED</DayOfWeek>
#             <Time>20:00:00</Time>
#           </NormalLatestDropOffDetails>
#           <NormalLatestDropOffDetails>
#             <DayOfWeek>FRI</DayOfWeek>
#             <Time>20:00:00</Time>
#           </NormalLatestDropOffDetails>
#           <ExceptionalLatestDropOffDetails>
#             <DayOfWeek>WED</DayOfWeek>
#             <Time>16:00:00</Time>
#           </ExceptionalLatestDropOffDetails>
#           <EffectiveLatestDropOffDetails>
#             <DayOfWeek>TUE</DayOfWeek>
#             <Time>20:00:00</Time>
#           </EffectiveLatestDropOffDetails>
#         </CarrierDetails>
#       </LocationDetail>
#     </DistanceAndLocationDetails>