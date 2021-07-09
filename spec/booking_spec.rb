require "rails_helper"

class BookingConfirmed < RailsEventStore::Event
end

class Booking
  def initialize
    self.id = SecureRandom.hex
  end

  def confirm
    events = load_events_for_booking
    state = build_state(events)

    raise 'Booking is already confirmed' if state.confirmed?

    Rails.configuration.event_store.publish(BookingConfirmed.new(data: {}), stream_name: stream_name)
  end

  private

  attr_accessor :id

  def stream_name
    "booking-#{id}"
  end

  def load_events_for_booking
    client.read.stream(stream_name).to_a
  end

  def client
    @client ||= RailsEventStore::Client.new
  end
  
  def build_state(events)
    result = 'inquiry'

    events.each do |event|
      if event.is_a?(BookingConfirmed)
        result = 'confirmed'
      end
    end

    ActiveSupport::StringInquirer.new(result)
  end
end

RSpec.describe Booking do
  it "confirms the booking" do
    booking = Booking.new

    booking.confirm

    expect(event_store).to have_published(an_event(BookingConfirmed))
  end

  it "raises an error when booking is confirmed twice" do
    booking = Booking.new

    booking.confirm

    expect { booking.confirm }.to raise_error
  end

  def event_store
    Rails.configuration.event_store
  end
end
