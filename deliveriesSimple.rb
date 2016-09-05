# test.rb

require 'sinatra'
require 'json'

class DeliveryMatcher
  attr_reader :drivers, :orders, :deliveries

  #total number of small orders allowed (only single large order allowed)
  MAX_ORDERS = 3

  # initialize driver/order lists
  def initialize
    @drivers = Hash.new
    @orders = Array.new
  end

  # returns hash of all driver
  def get_drivers
    drivers
  end

  # returns array of all orders
  def get_orders
    orders
  end

  # add a single driver to driver hash
  def add_driver id, location
    #return false unless null == @drivers[id]

    @drivers.merge!Hash[id, Integer(location)]
    puts("Added Driver #{id}, #{location}")
    true
  end

  # given a hash of drivers, adds each to driver hash
  def add_drivers params
    @driver_hash = JSON.parse(params)

    @driver_hash['drivers'].each do |driver|
       add_driver(driver["id"],driver["location"])
    end
    true
  end

  # add an order to the order array
  def add_order origin, destination, size
    # check for duplicates

    order = {
       origin: Integer(origin),
       destination: destination,
       size: size
    }

    @orders.push order 

    puts("Added Order #{origin}, #{destination}, #{size}")
    true
  end

  # given a hash of orders, adds each to order array
  def add_orders params
    @orders_hash = JSON.parse(params)

    @orders_hash['orders'].each do |order|
       add_order(order["origin"],order["destination"],order["size"])
    end
    true
  end

  # assign orders to drivers
  # uses simple algorithm, non-full driver with location closest to origin gets the order
  def get_deliveries
    @deliveries = Hash.new
    @dup_drivers = @drivers.clone

    # iterate through the orders
    @orders.each do |order|
        # generate a distance metric for each driver
        @distance = Hash.new

        # iterate through the drivers calculating the distance to the order
        @dup_drivers.each do |id, location|
            @distance.merge!Hash[id, (location - order[:origin]).abs]
            puts ("#{order[:origin]}, #{id}, #{location}, #{(order[:origin] - location).abs}")
        end

        # sort the drivers by distance and start trying to assign orders
        @distance.sort_by{|id, distance| distance}.to_h.each do |id, distance|
            puts("SORTED #{id}, #{distance}")
            # handle a large order
            if order[:size] == "large" 
              # ignore if the driver is not already busy
              if !@deliveries.key?(id)
                # add the delivery to the hash
                @deliveries.merge!Hash[id, [order]]
                puts ("Assigning #{id} this order #{order}")

                # this driver is full
                puts ("REMOVING driver #{id}")
                @dup_drivers.delete(id)

                # order filled
                break
              end
            elsif order[:size] == "small"
              # if the driver isn't busy, add the delivery
              if !@deliveries.key?(id)
                @deliveries.merge!Hash[id, [order]]
                puts ("Assigning #{id} this order #{order}")
                break
              else # add the order to the end of the delivery list
                puts ("Assigning #{id} this order #{order}")
                @deliveries[id].push(order)

                # check if the driver is full
                if MAX_ORDERS <= @deliveries[id].length
                  puts ("REMOVING driver #{id}")
                  @dup_drivers.delete(id)
                end
                break
              end
            else
                puts("Unrecognized order size #{order[:size]}")
            end
        end
    end

    @deliveries
  end
  
end

deliveryMatcher = DeliveryMatcher.new

# list all drivers
get '/drivers' do
  deliveryMatcher.get_drivers.to_json
end

# list particular driver
get '/drivers/:id' do
  'TODO implement single driver'
end

# create drivers
post '/drivers' do
  deliveryMatcher.add_drivers(request.body.read)
end

# list all orders
get '/orders' do
  deliveryMatcher.get_orders.to_json
end

# list particular order
get '/orders/:id' do
  'TODO implement single order'
end

# create orders
post '/orders' do
  deliveryMatcher.add_orders(request.body.read)
end

# list the driver orders
get '/deliveries' do
  deliveryMatcher.get_deliveries().to_json
end
