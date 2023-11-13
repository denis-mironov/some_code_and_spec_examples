# frozen_string_literal: true

# This service is used to search for properties within a 5 km radius of given coordinates.
class Properties::FindClosestPropertiesService
  attr_reader :lat, :lng, :property_type, :marketing_type, :radius

  def initialize(params={})
    @lat = params[:lat]
    @lng = params[:lng]
    @property_type = params[:property_type]
    @marketing_type = params[:marketing_type]
    @radius = Property::SEARCH_RADIUS
  end

  def call
    Property.where("
      properties.property_type = ? AND properties.offer_type = ?
      AND earth_box(ll_to_earth(properties.lat, properties.lng), #{radius}) @> ll_to_earth(#{lat}, #{lng})
      AND earth_distance(ll_to_earth(properties.lat, properties.lng), ll_to_earth(#{lat}, #{lng})) < #{radius}
    ", property_type, marketing_type)
  end
end
